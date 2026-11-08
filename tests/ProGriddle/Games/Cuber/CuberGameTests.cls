/* The rules of Cuber, driven frame by frame with Advance. A scene is built with the public set up methods (SetLamp, PlacePip,
   SpawnEnemy, SetHalo and so on) so each test controls exactly what is on the pyramid. The random source is a ScriptedRandom that
   always says 1, so a ball always hops down and to the right and nothing is left to chance. A hop takes up to 14 frames from the
   key to the landing (Pip stands 2 frames after a landing, then one frame starts the hop and 12 are the flight). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberGameTests:

    VAR PRIVATE CuberGame mGame.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = CuberFactory:Create(NEW ScriptedRandom("1")).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        VAR INTEGER i.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* A game in play on level piLevel with no enemies and none coming, Pip on the apex, every lamp dark and the halos where the
       shuffle put them. */
    METHOD PRIVATE VOID Scene(INPUT piLevel AS INTEGER):
        mGame:StartGame().
        mGame:BeginRound(piLevel, 1).
        Frames(CuberRules:ReadyFrames()).
        mGame:ClearEnemies().
        mGame:StopSpawns().
        mGame:PlacePip(1, 0).
    END METHOD.

    /* Asks for a hop and lets it be made and land. */
    METHOD PRIVATE VOID Hop(INPUT poDir AS CuberDir):
        mGame:RequestHop(poDir).
        Frames(14).
    END METHOD.

    /* ---- starting ---- */

    @Test.
    METHOD PUBLIC VOID ANewGameShowsTheTitleAndWaitsForTheFireKey():
        Assert:Equals(STRING(CuberPhase:Title), STRING(mGame:Phase)).
        mGame:FireHeld = TRUE.
        Frames(1).
        Assert:Equals(STRING(CuberPhase:Title), STRING(mGame:Phase)).
        mGame:FireHeld = FALSE.
        Frames(1).
        mGame:FireHeld = TRUE.
        Frames(1).
        Assert:Equals(STRING(CuberPhase:Ready), STRING(mGame:Phase)).
        Assert:Equals(1, mGame:GamesStarted).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartGameGivesThreePipsLevelOneAndFourHalos():
        mGame:StartGame().
        Assert:Equals(STRING(CuberPhase:Ready), STRING(mGame:Phase)).
        Assert:Equals(2, mGame:Lives).
        Assert:Equals(1, mGame:LevelNo).
        Assert:Equals(1, mGame:RoundNo).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(4, mGame:HalosWaiting()).
        Assert:Equals(1, mGame:PipRow).
        Assert:Equals(0, mGame:PipCol).
        Assert:Equals(0, mGame:LampsDone).
        Assert:Equals(0, mGame:Tempo).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReadyLastsNinetyFramesThenPlayBegins():
        mGame:StartGame().
        Frames(89).
        Assert:Equals(STRING(CuberPhase:Ready), STRING(mGame:Phase)).
        Frames(1).
        Assert:Equals(STRING(CuberPhase:Playing), STRING(mGame:Phase)).
        Assert:Equals(0, mGame:PhaseFrames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BeginRoundSetsTheLevelAndRoundAndRefusesBadOnes():
        mGame:BeginRound(3, 2).
        Assert:Equals(3, mGame:LevelNo).
        Assert:Equals(2, mGame:RoundNo).
        Assert:Equals(3, mGame:HalosWaiting()).
        Assert:Equals(7, mGame:Tempo).
        mGame:BeginRound(5, 4).
        Assert:Equals(2, mGame:HalosWaiting()).
        Assert:Equals(12, mGame:Tempo).
        Assert:Equals(STRING(CuberPhase:Ready), STRING(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BeginRoundThrowsForALevelUnderOne():
        VAR LOGICAL thrown.
        DO ON ERROR UNDO, LEAVE:
            mGame:BeginRound(0, 1).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BeginRoundThrowsForARoundOutsideOneToFour():
        VAR LOGICAL thrown.
        DO ON ERROR UNDO, LEAVE:
            mGame:BeginRound(1, 5).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TickTurnsMillisecondsIntoFramesAtTheSpeed():
        mGame:SpeedPercent = 100.
        Assert:IsTrue(mGame:Tick(50)).
        Assert:Equals(3, mGame:Frames).
        mGame:SpeedPercent = 50.
        Assert:IsTrue(mGame:Tick(100)).
        Assert:Equals(6, mGame:Frames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TickDoesNothingWhilePausedOrForNoTime():
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:Tick(100)).
        mGame:Paused = FALSE.
        Assert:IsFalse(mGame:Tick(0)).
        Assert:IsFalse(mGame:Tick(?)).
        Assert:Equals(0, mGame:Frames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedStaysBetweenTwentyAndAHundredPercent():
        mGame:SpeedPercent = 5.
        Assert:Equals(20, mGame:SpeedPercent).
        mGame:SpeedPercent = 400.
        Assert:Equals(100, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TakeNoticeGivesTheWordsOnceAndClearsThem():
        mGame:AddScore(CuberRules:ExtraLifeEvery()).
        Assert:Equals("Extra Pip", mGame:TakeNotice()).
        Assert:Equals("", mGame:TakeNotice()).
    END METHOD.

    /* ---- the lamps ---- */

    @Test.
    METHOD PUBLIC VOID LampAtAndSetLampReadAndWriteAStateAndRefuseOthers():
        VAR LOGICAL thrown.
        mGame:SetLamp(3, 1, 2).
        Assert:Equals(2, mGame:LampAt(3, 1)).
        Assert:Equals(0, mGame:LampAt(3, 0)).
        DO ON ERROR UNDO, LEAVE:
            mGame:LampAt(3, 3).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
        thrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mGame:SetLamp(3, 1, 3).
            CATCH e2 AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LampsDoneCountsTheLitLamps():
        mGame:SetLamp(1, 0, 2).
        mGame:SetLamp(4, 2, 2).
        mGame:SetLamp(4, 1, 1).
        Assert:Equals(2, mGame:LampsDone).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PyramidVersionGoesUpWhenALampChanges():
        VAR INTEGER before.
        before = mGame:PyramidVersion.
        mGame:SetLamp(2, 0, 2).
        Assert:IsTrue(mGame:PyramidVersion > before).
    END METHOD.

    /* ---- hopping ---- */

    @Test.
    METHOD PUBLIC VOID APipHopsDownRightAndLightsTheLampItLandsOn():
        Scene(1).
        Hop(CuberDir:DownRight).
        Assert:Equals(2, mGame:PipRow).
        Assert:Equals(1, mGame:PipCol).
        Assert:Equals(STRING(CuberPipMode:Standing), STRING(mGame:PipMode)).
        Assert:Equals(2, mGame:LampAt(2, 1)).
        Assert:Equals(25, mGame:Score).
        Assert:Equals(1, mGame:LampsLit).
        Assert:Equals(1, mGame:Hops).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFourDirectionsGoToTheLampsOfTheirCorners():
        Scene(1).
        mGame:PlacePip(4, 2).
        Hop(CuberDir:UpLeft).
        Assert:Equals(3, mGame:PipRow).
        Assert:Equals(1, mGame:PipCol).
        Hop(CuberDir:DownLeft).
        Assert:Equals(4, mGame:PipRow).
        Assert:Equals(1, mGame:PipCol).
        Hop(CuberDir:UpRight).
        Assert:Equals(3, mGame:PipRow).
        Assert:Equals(1, mGame:PipCol).
        Hop(CuberDir:DownRight).
        Assert:Equals(4, mGame:PipRow).
        Assert:Equals(2, mGame:PipCol).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADirectionNameIsTheCornerItHopsTowards():
        Assert:Equals(5, CuberRules:HopRow(4, CuberDir:DownLeft)).
        Assert:Equals(2, CuberRules:HopCol(2, CuberDir:DownLeft)).
        Assert:Equals(3, CuberRules:HopRow(4, CuberDir:UpRight)).
        Assert:Equals(2, CuberRules:HopCol(2, CuberDir:UpRight)).
        Assert:Equals(1, CuberRules:HopCol(2, CuberDir:UpLeft)).
        Assert:Equals(3, CuberRules:HopCol(2, CuberDir:DownRight)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePipIsInTheAirDuringTheHopAndItsFeetFollowAnArc():
        VAR INTEGER y0.
        VAR INTEGER mid.
        Scene(1).
        y0 = mGame:PipY.
        mGame:RequestHop(CuberDir:DownRight).
        Frames(1 + 6).
        Assert:Equals(STRING(CuberPipMode:Hopping), STRING(mGame:PipMode)).
        Assert:Equals(6, mGame:PipHopFrame).
        mid = mGame:PipY.
        /* half way down to the next row (12 pixels) minus the lift of 12 */
        Assert:Equals(y0 + 12 - 12, mid).
        Assert:Equals(128 + 8, mGame:PipX).
        Frames(6).
        Assert:Equals(CuberRules:FootX(2, 1), mGame:PipX).
        Assert:Equals(CuberRules:FootY(2), mGame:PipY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWantedHopIsForgottenAfterFourteenFramesIfPipCannotHopMeanwhile():
        Scene(1).
        mGame:SetHalo(1, TRUE).
        mGame:PlacePip(4, 0).
        Hop(CuberDir:UpLeft).
        Assert:Equals(STRING(CuberPipMode:Riding), STRING(mGame:PipMode)).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(CuberRules:RideFrames() + 5).
        Assert:Equals(1, mGame:PipRow).
        Assert:Equals(STRING(CuberPipMode:Standing), STRING(mGame:PipMode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWantedHopMadeWhileHoppingIsDoneOnTheLanding():
        Scene(1).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(8).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(20).
        Assert:Equals(3, mGame:PipRow).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoldingAKeyKeepsPipHoppingBecauseEachRepeatAsksAgain():
        Scene(1).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(13).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(14).
        Assert:Equals(3, mGame:PipRow).
        Assert:Equals(0, mGame:PipCol).
        Assert:Equals(2, mGame:Hops).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RequestHopDoesNothingUnlessTheGameIsBeingPlayed():
        mGame:StartGame().
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(100).
        Assert:Equals(0, mGame:Hops).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlacePipPutsPipStandingOnALampAndRefusesOthers():
        VAR LOGICAL thrown.
        Scene(1).
        mGame:PlacePip(5, 3).
        Assert:Equals(5, mGame:PipRow).
        Assert:Equals(3, mGame:PipCol).
        Assert:Equals(5, mGame:PipDestRow).
        Assert:Equals(3, mGame:PipDestCol).
        DO ON ERROR UNDO, LEAVE:
            mGame:PlacePip(8, 0).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhileHoppingTheDestinationIsTheLampItIsHoppingTo():
        Scene(1).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(3).
        Assert:Equals(1, mGame:PipRow).
        Assert:Equals(2, mGame:PipDestRow).
        Assert:Equals(0, mGame:PipDestCol).
        Assert:Equals(CuberDir:DownLeft, mGame:PipDirection).
        Assert:IsFalse(mGame:PipDoomed).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PipStandFramesCountFromTheLanding():
        Scene(1).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(13).
        Assert:Equals(0, mGame:PipStandFrames).
        Frames(1).
        Assert:Equals(1, mGame:PipStandFrames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PipModeFramesCountTheFramesOfWhatPipIsDoing():
        Scene(1).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(5).
        Assert:Equals(4, mGame:PipModeFrames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APipThatHopsOffTheFrontOfThePyramidFallsAndLosesALife():
        Scene(1).
        mGame:PlacePip(7, 0).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(2).
        Assert:IsTrue(mGame:PipDoomed).
        Frames(11).
        Assert:Equals(STRING(CuberPhase:Dying), STRING(mGame:Phase)).
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
        Assert:IsTrue(mGame:PipFellInFront).
        Assert:Equals(1, mGame:Falls).
        Assert:Equals(2, mGame:Lives).
        Frames(CuberRules:FallFrames() - 1).
        Assert:Equals(STRING(CuberPhase:Dying), STRING(mGame:Phase)).
        Frames(1).
        Assert:Equals(STRING(CuberPhase:Ready), STRING(mGame:Phase)).
        Assert:Equals(1, mGame:Lives).
        Assert:Equals(1, mGame:Deaths).
        Assert:Equals(1, mGame:PipRow).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFallOffTheBackIsAnUpHopOffTheTop():
        Scene(1).
        Hop(CuberDir:UpRight).
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
        Assert:IsFalse(mGame:PipFellInFront).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhileFallingPipFeetDropFasterAndFasterBelowTheEdge():
        VAR INTEGER y1.
        VAR INTEGER y2.
        Scene(1).
        Hop(CuberDir:UpRight).
        Frames(10).
        y1 = mGame:PipY.
        Frames(10).
        y2 = mGame:PipY.
        Assert:IsTrue(y2 > y1).
        Assert:IsTrue(y1 > CuberRules:FootY(0)).
    END METHOD.

    /* ---- lamps lit ---- */

    @Test.
    METHOD PUBLIC VOID OnLevelThreeALampTakesTwoLandingsARingThenTheLight():
        Scene(3).
        Hop(CuberDir:DownLeft).
        Assert:Equals(1, mGame:LampAt(2, 0)).
        Assert:Equals(10, mGame:Score).
        Assert:Equals(1, mGame:LampsRinged).
        Hop(CuberDir:UpRight).
        Hop(CuberDir:DownLeft).
        Assert:Equals(2, mGame:LampAt(2, 0)).
        Assert:Equals(10 + 10 + 25, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnLevelFiveALandingOnALitLampPutsItBackAStep():
        Scene(5).
        mGame:SetLamp(2, 0, 2).
        Hop(CuberDir:DownLeft).
        Assert:Equals(1, mGame:LampAt(2, 0)).
        Assert:Equals(1, mGame:LampsPutOut).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnLevelOneALandingOnALitLampLeavesItLit():
        Scene(1).
        mGame:SetLamp(2, 0, 2).
        Hop(CuberDir:DownLeft).
        Assert:Equals(2, mGame:LampAt(2, 0)).
        Assert:Equals(0, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLastLitLampAndTheFrameAreKeptForTheGlint():
        Scene(1).
        Assert:Equals(-1, mGame:LastLitFrame).
        Hop(CuberDir:DownRight).
        Assert:Equals(2, mGame:LastLitRow).
        Assert:Equals(1, mGame:LastLitCol).
        Assert:IsTrue(mGame:LastLitFrame > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LightingALampShowsItsPointsOverItsFeet():
        VAR INTEGER i.
        Scene(1).
        Hop(CuberDir:DownLeft).
        DO i = 0 TO mGame:PopSlots - 1:
            IF mGame:PopValue(i) = 25 THEN LEAVE.
        END.
        Assert:IsTrue(i < mGame:PopSlots).
        Assert:Equals(CuberRules:FootX(2, 0), mGame:PopX(i)).
        Assert:Equals(CuberRules:FootY(2), mGame:PopY(i)).
        Assert:IsTrue(mGame:PopAge(i) >= 0).
        Assert:Equals(-1, mGame:PopAge((i + 1) MODULO mGame:PopSlots)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PopAccessorsRefuseAPlaceThatIsNotThere():
        VAR LOGICAL thrown.
        DO ON ERROR UNDO, LEAVE:
            mGame:PopValue(4).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LightingTheLastLampClearsTheRoundAndTheHalosLeftPay():
        VAR INTEGER r.
        VAR INTEGER c.
        Scene(1).
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                mGame:SetLamp(r, c, 2).
            END.
        END.
        mGame:SetLamp(2, 1, 0).
        Hop(CuberDir:DownRight).
        Assert:Equals(STRING(CuberPhase:Cleared), STRING(mGame:Phase)).
        Assert:Equals(STRING(CuberPipMode:Winning), STRING(mGame:PipMode)).
        Assert:Equals(25 + 4 * 50, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterTheClearTheNextRoundBeginsWithDarkLampsAndNewLight():
        VAR INTEGER r.
        VAR INTEGER c.
        Scene(1).
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                mGame:SetLamp(r, c, 2).
            END.
        END.
        mGame:SetLamp(2, 1, 0).
        Hop(CuberDir:DownRight).
        Frames(CuberRules:ClearFrames()).
        Assert:Equals(STRING(CuberPhase:Ready), STRING(mGame:Phase)).
        Assert:Equals(1, mGame:LevelNo).
        Assert:Equals(2, mGame:RoundNo).
        Assert:Equals(0, mGame:LampsDone).
        Assert:Equals(1, mGame:RoundsCleared).
        Assert:Equals("Round 2", mGame:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFourthRoundLeadsToTheNextLevel():
        VAR INTEGER r.
        VAR INTEGER c.
        mGame:StartGame().
        mGame:BeginRound(1, 4).
        Frames(CuberRules:ReadyFrames()).
        mGame:ClearEnemies().
        mGame:StopSpawns().
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                mGame:SetLamp(r, c, 2).
            END.
        END.
        mGame:SetLamp(2, 1, 0).
        Hop(CuberDir:DownRight).
        Frames(CuberRules:ClearFrames()).
        Assert:Equals(2, mGame:LevelNo).
        Assert:Equals(1, mGame:RoundNo).
        Assert:Equals(1, mGame:LevelsCleared).
    END METHOD.

    /* ---- halos ---- */

    @Test.
    METHOD PUBLIC VOID HaloPlacesAreSixAndSetHaloPutsOneInOrTakesItAway():
        VAR LOGICAL thrown.
        Scene(1).
        mGame:SetHalo(1, FALSE).
        Assert:Equals(0, mGame:HaloState(1)).
        mGame:SetHalo(1, TRUE).
        Assert:Equals(1, mGame:HaloState(1)).
        Assert:Equals(-1, mGame:HaloUsedFrame(1)).
        DO ON ERROR UNDO, LEAVE:
            mGame:HaloState(7).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoppingOntoAHaloLiftsPipToTheTopAndTheHaloIsUsed():
        Scene(1).
        mGame:SetHalo(1, TRUE).
        mGame:PlacePip(4, 0).
        Hop(CuberDir:UpLeft).
        Assert:Equals(STRING(CuberPipMode:Riding), STRING(mGame:PipMode)).
        Assert:Equals(2, mGame:HaloState(1)).
        Assert:Equals(1, mGame:Rides).
        Assert:IsTrue(mGame:HaloUsedFrame(1) > 0).
        Frames(CuberRules:RideFrames() - 2).
        Assert:Equals(STRING(CuberPipMode:Riding), STRING(mGame:PipMode)).
        Assert:IsTrue(mGame:PipY < CuberRules:FootY(3)).
        Frames(1).
        Assert:Equals(STRING(CuberPipMode:Standing), STRING(mGame:PipMode)).
        Assert:Equals(1, mGame:PipRow).
        Assert:Equals(0, mGame:PipCol).
        Assert:Equals(STRING(CuberPhase:Playing), STRING(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHuntingCoilFallsOffAndEverythingElseVanishesWhenPipRides():
        VAR INTEGER coil.
        Scene(1).
        mGame:SetHalo(2, TRUE).
        mGame:PlacePip(4, 3).
        coil = mGame:SpawnEnemy(CuberKind:Coil, 7, 3).
        mGame:SetEnemyRest(coil, 500).
        mGame:SpawnEnemy(CuberKind:Thorn, 6, 0).
        mGame:SetEnemyRest(1, 500).
        Hop(CuberDir:UpRight).
        Assert:Equals(STRING(CuberPipMode:Riding), STRING(mGame:PipMode)).
        Assert:Equals(1, mGame:CoilFalls).
        Assert:Equals(CuberRules:PointsCoil(), mGame:Score).
        Assert:IsTrue(mGame:EnemyOn(coil)).
        Assert:Equals(STRING(CuberEnemyMode:Falling), STRING(mGame:EnemyMode(coil))).
        Assert:IsFalse(mGame:EnemyOn(1)).
        Frames(40).
        Assert:IsFalse(mGame:EnemyOn(coil)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHaloThatIsUsedUpIsNotThereTheSecondTime():
        Scene(1).
        mGame:SetHalo(1, TRUE).
        mGame:PlacePip(4, 0).
        Hop(CuberDir:UpLeft).
        Frames(CuberRules:RideFrames()).
        mGame:PlacePip(4, 0).
        mGame:RequestHop(CuberDir:UpLeft).
        Frames(14).
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHaloSpotWithNoHaloIsAFallLikeAnyOtherSpace():
        Scene(1).
        mGame:SetHalo(1, FALSE).
        mGame:PlacePip(4, 0).
        Hop(CuberDir:UpLeft).
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
    END METHOD.

    /* ---- the enemies ---- */

    @Test.
    METHOD PUBLIC VOID SpawnEnemyPutsOneOnALampAndTheReadersDescribeIt():
        VAR INTEGER e.
        VAR LOGICAL thrown.
        Scene(1).
        e = mGame:SpawnEnemy(CuberKind:Thorn, 4, 2).
        mGame:SetEnemyRest(e, 500).
        Assert:IsTrue(mGame:EnemyOn(e)).
        Assert:Equals(1, mGame:EnemyCount).
        Assert:Equals(STRING(CuberKind:Thorn), STRING(mGame:EnemyKind(e))).
        Assert:Equals(4, mGame:EnemyRow(e)).
        Assert:Equals(2, mGame:EnemyCol(e)).
        Assert:Equals(4, mGame:EnemyDestRow(e)).
        Assert:Equals(2, mGame:EnemyDestCol(e)).
        Assert:Equals(STRING(CuberEnemyMode:Resting), STRING(mGame:EnemyMode(e))).
        Assert:Equals(CuberRules:FootX(4, 2), mGame:EnemyX(e)).
        Assert:Equals(CuberRules:FootY(4), mGame:EnemyY(e)).
        Assert:IsFalse(mGame:EnemyFrozen(e)).
        Assert:Equals(0, mGame:EnemyHopFrame(e)).
        Assert:Equals(8, mGame:EnemySlots).
        DO ON ERROR UNDO, LEAVE:
            mGame:EnemyKind(5).
            CATCH x AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEnemyFacesTheWayItLastHoppedAndMothsStartFacingUp():
        VAR INTEGER e.
        VAR INTEGER s.
        VAR INTEGER p.
        Scene(2).
        e = mGame:SpawnEnemy(CuberKind:Thorn, 4, 2).
        Assert:Equals(CuberDir:DownRight, mGame:EnemyDirection(e)).
        s = mGame:SpawnEnemy(CuberKind:Snuff, 7, 0).
        p = mGame:SpawnEnemy(CuberKind:Puff, 7, 6).
        mGame:SetEnemyRest(s, 500).
        mGame:SetEnemyRest(p, 500).
        Assert:Equals(CuberDir:UpRight, mGame:EnemyDirection(s)).
        Assert:Equals(CuberDir:UpLeft, mGame:EnemyDirection(p)).
        mGame:SetEnemyRest(e, 500).
        mGame:SpawnEnemy(CuberKind:Coil, 6, 3).
        mGame:SetEnemyRest(3, 1).
        Frames(1).
        /* the Coil goes for Pip on the apex, so it hops up */
        Assert:IsTrue(mGame:EnemyDirection(3) = CuberDir:UpLeft OR mGame:EnemyDirection(3) = CuberDir:UpRight).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnemyModeFramesCountTheFramesInTheCurrentMode():
        VAR INTEGER e.
        Scene(1).
        e = mGame:SpawnEnemy(CuberKind:Thorn, 2, 0).
        Frames(1 + 3).
        Assert:Equals(STRING(CuberEnemyMode:Hopping), STRING(mGame:EnemyMode(e))).
        Assert:Equals(3, mGame:EnemyModeFrames(e)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFreezeRemembersWhenAndWhereTheFrostWentOff():
        Scene(1).
        Assert:Equals(-1, mGame:FreezeFrame).
        mGame:PlacePip(4, 1).
        mGame:SpawnEnemy(CuberKind:Frost, 4, 1).
        Frames(1).
        Assert:IsTrue(mGame:FreezeFrame > 0).
        Assert:Equals(CuberRules:FootX(4, 1), mGame:FreezeX).
        Assert:Equals(CuberRules:FootY(4), mGame:FreezeY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearEnemiesTakesThemAllOff():
        Scene(1).
        mGame:SpawnEnemy(CuberKind:Thorn, 4, 2).
        mGame:SpawnEnemy(CuberKind:Frost, 5, 2).
        mGame:ClearEnemies().
        Assert:Equals(0, mGame:EnemyCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNinthEnemyIsRefused():
        VAR INTEGER i.
        VAR LOGICAL thrown.
        Scene(1).
        DO i = 1 TO 8:
            mGame:SpawnEnemy(CuberKind:Thorn, 4, 2).
        END.
        DO ON ERROR UNDO, LEAVE:
            mGame:SpawnEnemy(CuberKind:Thorn, 4, 2).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABallHopsDownAndRightWhenTheDiceSayOneAndLeavesFromTheBottomRow():
        VAR INTEGER e.
        Scene(1).
        e = mGame:SpawnEnemy(CuberKind:Thorn, 5, 1).
        Frames(1).
        Assert:Equals(STRING(CuberEnemyMode:Hopping), STRING(mGame:EnemyMode(e))).
        Assert:Equals(6, mGame:EnemyDestRow(e)).
        Assert:Equals(2, mGame:EnemyDestCol(e)).
        Frames(6).
        Assert:Equals(6, mGame:EnemyHopFrame(e)).
        Assert:IsTrue(mGame:EnemyY(e) < CuberRules:FootY(5) + 12).
        Frames(6).
        Assert:Equals(6, mGame:EnemyRow(e)).
        Assert:Equals(2, mGame:EnemyCol(e)).
        Assert:Equals(STRING(CuberEnemyMode:Resting), STRING(mGame:EnemyMode(e))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABallOnTheBottomRowHopsOffTheEdgeAndIsGone():
        VAR INTEGER e.
        Scene(1).
        e = mGame:SpawnEnemy(CuberKind:Thorn, 7, 3).
        Frames(1 + 12).
        Assert:Equals(STRING(CuberEnemyMode:Falling), STRING(mGame:EnemyMode(e))).
        Frames(1).
        Assert:IsTrue(mGame:EnemyY(e) > CuberRules:FootY(8)).
        Frames(40).
        Assert:IsFalse(mGame:EnemyOn(e)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASeedThatReachesTheBottomRowHatchesIntoACoil():
        VAR INTEGER e.
        Scene(1).
        e = mGame:SpawnEnemy(CuberKind:Seed, 6, 3).
        Frames(1 + 12).
        Assert:Equals(7, mGame:EnemyRow(e)).
        Assert:Equals(STRING(CuberEnemyMode:Hatching), STRING(mGame:EnemyMode(e))).
        Assert:Equals(STRING(CuberKind:Seed), STRING(mGame:EnemyKind(e))).
        Assert:Equals(1, mGame:Hatchings).
        Frames(CuberRules:HatchFrames()).
        Assert:Equals(STRING(CuberKind:Coil), STRING(mGame:EnemyKind(e))).
        Assert:Equals(STRING(CuberEnemyMode:Resting), STRING(mGame:EnemyMode(e))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCoilHopsTheWayThatBringsItNearestToPip():
        VAR INTEGER e.
        Scene(1).
        e = mGame:SpawnEnemy(CuberKind:Coil, 5, 2).
        Frames(1).
        /* Pip is on the apex: up and to the left (4, 1) or up and to the right (4, 2) both lead to it in 3 hops, the first found wins */
        Assert:IsTrue(mGame:EnemyDestRow(e) = 4).
        Frames(12).
        Assert:Equals(4, mGame:EnemyRow(e)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCoilKeepsOnThePyramidWhateverTheDice():
        VAR INTEGER e.
        VAR INTEGER i.
        Scene(1).
        mGame:PlacePip(1, 0).
        e = mGame:SpawnEnemy(CuberKind:Coil, 7, 6).
        DO i = 1 TO 20:
            Frames(40).
            IF mGame:Phase <> CuberPhase:Playing THEN LEAVE.
            Assert:IsTrue(mGame:EnemyOn(e)).
            Assert:IsTrue(CuberRules:IsLamp(mGame:EnemyRow(e), mGame:EnemyCol(e))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSeedDropsInAfterThePauseAndLandsOnRowTwoAfterEightFrames():
        VAR INTEGER i.
        VAR INTEGER seed = -1.
        Scene(1).
        mGame:BeginRound(1, 1).
        Frames(CuberRules:ReadyFrames() + CuberRules:SeedDelay() + 3).
        DO i = 0 TO mGame:EnemySlots - 1:
            IF mGame:EnemyOn(i) AND mGame:EnemyKind(i) = CuberKind:Seed THEN seed = i.
        END.
        Assert:IsTrue(seed >= 0).
        Assert:Equals(STRING(CuberEnemyMode:Dropping), STRING(mGame:EnemyMode(seed))).
        Assert:Equals(2, mGame:EnemyRow(seed)).
        Assert:IsTrue(mGame:EnemyY(seed) < CuberRules:FootY(2)).
        Frames(8).
        Assert:Equals(STRING(CuberEnemyMode:Resting), STRING(mGame:EnemyMode(seed))).
        Assert:Equals(CuberRules:FootY(2), mGame:EnemyY(seed)).
    END METHOD.

    /* ---- touching ---- */

    @Test.
    METHOD PUBLIC VOID ATouchOfAThornOnTheSameLampLosesALife():
        Scene(1).
        mGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
        Frames(1).
        Assert:Equals(STRING(CuberPhase:Dying), STRING(mGame:Phase)).
        Assert:Equals(STRING(CuberPipMode:Hit), STRING(mGame:PipMode)).
        Assert:Equals(1, mGame:Hits).
        Assert:Equals(1, mGame:Deaths).
        Frames(CuberRules:HitFrames()).
        Assert:Equals(STRING(CuberPhase:Ready), STRING(mGame:Phase)).
        Assert:Equals(1, mGame:Lives).
        Assert:Equals(0, mGame:EnemyCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHopOntoACoilIsTheSameAsTheCoilHoppingOntoPip():
        VAR INTEGER e.
        Scene(1).
        e = mGame:SpawnEnemy(CuberKind:Coil, 2, 1).
        mGame:SetEnemyRest(e, 500).
        Hop(CuberDir:DownRight).
        Assert:Equals(STRING(CuberPhase:Dying), STRING(mGame:Phase)).
    END METHOD.

    /* A Thorn put on Pip's lamp costs a life, and the death plays out. */
    METHOD PRIVATE VOID LoseAPip():
        mGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
        Frames(1 + CuberRules:HitFrames()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLastLifeLostEndsTheGame():
        Scene(1).
        LoseAPip().
        Assert:Equals(1, mGame:Lives).
        Frames(CuberRules:ReadyFrames()).
        LoseAPip().
        Assert:Equals(0, mGame:Lives).
        Frames(CuberRules:ReadyFrames()).
        LoseAPip().
        Assert:Equals(STRING(CuberPhase:GameOver), STRING(mGame:Phase)).
        Assert:Equals(0, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GameOverWaitsAMomentThenTheFireKeyReturnsToTheTitle():
        Scene(1).
        mGame:AddScore(100).
        LoseAPip().
        Frames(CuberRules:ReadyFrames()).
        LoseAPip().
        Frames(CuberRules:ReadyFrames()).
        LoseAPip().
        Assert:Equals(STRING(CuberPhase:GameOver), STRING(mGame:Phase)).
        mGame:FireHeld = FALSE.
        Frames(100).
        mGame:FireHeld = TRUE.
        Frames(1).
        Assert:Equals(STRING(CuberPhase:Title), STRING(mGame:Phase)).
        Assert:Equals(0, mGame:Score).
        Assert:IsTrue(mGame:HiScore >= 100).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFrostFreezesEveryEnemyAndPays():
        VAR INTEGER e.
        Scene(1).
        e = mGame:SpawnEnemy(CuberKind:Thorn, 5, 2).
        mGame:SetEnemyRest(e, 500).
        mGame:SpawnEnemy(CuberKind:Frost, 1, 0).
        Frames(1).
        Assert:Equals(STRING(CuberPhase:Playing), STRING(mGame:Phase)).
        Assert:Equals(1, mGame:FrostsTouched).
        Assert:Equals(CuberRules:PointsFrost(), mGame:Score).
        Assert:IsTrue(mGame:EnemyFrozen(e)).
        Assert:IsTrue(mGame:FreezeFrames > 0).
        Assert:Equals(1, mGame:EnemyCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFrozenEnemyIsHarmlessAndStandsStillUntilTheFreezeEnds():
        VAR INTEGER e.
        VAR INTEGER frames.
        Scene(1).
        mGame:SpawnEnemy(CuberKind:Frost, 1, 0).
        Frames(1).
        e = mGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
        Frames(5).
        Assert:Equals(STRING(CuberPhase:Playing), STRING(mGame:Phase)).
        Assert:Equals(STRING(CuberEnemyMode:Resting), STRING(mGame:EnemyMode(e))).
        frames = mGame:FreezeFrames.
        Frames(frames).
        Assert:Equals(0, mGame:FreezeFrames).
        Assert:IsFalse(mGame:EnemyFrozen(e)).
        /* the touch counts the moment the freeze is over */
        Assert:Equals(STRING(CuberPhase:Dying), STRING(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACaughtMothPaysThreeHundred():
        Scene(2).
        mGame:SpawnEnemy(CuberKind:Snuff, 1, 0).
        Frames(1).
        Assert:Equals(CuberRules:PointsMoth(), mGame:Score).
        Assert:Equals(1, mGame:MothsCaught).
        Assert:Equals(0, mGame:EnemyCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMothPutsOutTheLampItLandsOn():
        VAR INTEGER e.
        Scene(2).
        mGame:SetLamp(6, 0, 2).
        e = mGame:SpawnEnemy(CuberKind:Snuff, 7, 0).
        Frames(1 + 12).
        Assert:Equals(6, mGame:EnemyRow(e)).
        Assert:Equals(0, mGame:EnemyCol(e)).
        Assert:Equals(0, mGame:LampAt(6, 0)).
        Assert:Equals(1, mGame:LampsPutOut).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PuffClimbsTheRightEdgeAndSnuffTheLeftOne():
        VAR INTEGER s.
        VAR INTEGER p.
        Scene(2).
        s = mGame:SpawnEnemy(CuberKind:Snuff, 7, 0).
        p = mGame:SpawnEnemy(CuberKind:Puff, 7, 6).
        Frames(1 + 12).
        Assert:Equals(0, mGame:EnemyCol(s)).
        Assert:Equals(6, mGame:EnemyRow(s)).
        Assert:Equals(5, mGame:EnemyCol(p)).
        Assert:Equals(6, mGame:EnemyRow(p)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMothThatClimbsOffTheTopIsGone():
        VAR INTEGER e.
        Scene(2).
        e = mGame:SpawnEnemy(CuberKind:Puff, 1, 0).
        mGame:PlacePip(7, 3).
        Frames(1 + 12 + 40).
        Assert:IsFalse(mGame:EnemyOn(e)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MothsComeFromLevelTwoAndNotBefore():
        Scene(1).
        mGame:ClearEnemies().
        mGame:BeginRound(1, 1).
        Frames(CuberRules:ReadyFrames() + 500).
        Assert:IsFalse(HasMoth()).
    END METHOD.

    METHOD PRIVATE LOGICAL HasMoth():
        VAR INTEGER i.
        DO i = 0 TO mGame:EnemySlots - 1:
            IF mGame:EnemyOn(i) AND (mGame:EnemyKind(i) = CuberKind:Snuff OR mGame:EnemyKind(i) = CuberKind:Puff) THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* ---- score ---- */

    @Test.
    METHOD PUBLIC VOID AnExtraPipComesAtEightThousandAndAgainAtSixteenThousand():
        mGame:StartGame().
        mGame:AddScore(8000).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(1, mGame:ExtraLives).
        mGame:AddScore(8000).
        Assert:Equals(4, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AddScoreRefusesNegativePointsAndRaisesTheHiScore():
        VAR LOGICAL thrown.
        mGame:AddScore(50).
        Assert:Equals(50, mGame:HiScore).
        DO ON ERROR UNDO, LEAVE:
            mGame:AddScore(-1).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHiScoreSetterRefusesAnUnknownOrNegativeValue():
        VAR LOGICAL thrown.
        mGame:HiScore = 900.
        Assert:Equals(900, mGame:HiScore).
        DO ON ERROR UNDO, LEAVE:
            mGame:HiScore = -5.
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGridMustBeSevenBySevenWithOneLampLayer():
        VAR LOGICAL thrown.
        VAR CuberGame g.
        DO ON ERROR UNDO, LEAVE:
            g = NEW CuberGame(NEW Grid(NEW ArrayStore(5, 5, "lamp")), NEW ScriptedRandom("1")).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
        thrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            g = NEW CuberGame(NEW Grid(NEW ArrayStore(7, 7, "state")), NEW ScriptedRandom("1")).
            CATCH e2 AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedGameDoesNotMove():
        Scene(1).
        mGame:RequestHop(CuberDir:DownLeft).
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:Tick(100)).
        Assert:Equals(STRING(CuberPipMode:Standing), STRING(mGame:PipMode)).
    END METHOD.

END CLASS.
