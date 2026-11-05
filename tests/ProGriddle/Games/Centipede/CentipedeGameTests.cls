/* The rules of Centipede, driven frame by frame with Advance. A scene is built with the public set up methods (PlaceMushroom,
   AddSegment, SpawnFlea and so on) so each test controls exactly what is on the field. The random source is a ScriptedRandom that
   always says 1, so the spider never changes row and nothing is left to chance. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeGameTests:

    DEFINE PRIVATE VARIABLE mGame AS CentipedeGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = CentipedeFactory:Create(NEW ScriptedRandom("1")).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* A game in play on an empty field with no centipede and no creatures, the shooter at 112, 224 (tile 14, row 28). */
    METHOD PRIVATE VOID Scene():
        mGame:StartGame().
        mGame:ClearField().
        mGame:ClearCentipede().
        mGame:ClearCreatures().
        mGame:PlacePlayer(112, 224).
    END METHOD.

    /* Something for the game to be about, so the wave is not over: a wall of mushrooms down column 26 keeps a segment in the three
       columns on the right, so it never gets near anything the tests do in the middle. */
    METHOD PRIVATE VOID KeepAlive():
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = 0 TO 23:
            mGame:PlaceMushroom(26, y, 4).
        END.
        mGame:AddSegment(28, 0, -1, TRUE).
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* The shooter is killed by a segment put on top of it, and the dying runs its 100 frames. */
    METHOD PRIVATE VOID KillShooter():
        mGame:PlacePlayer(112, 224).
        mGame:AddSegment(14, 28, -1, TRUE).
        mGame:Advance().
    END METHOD.

    /* ---- starting ---- */

    @Test.
    METHOD PUBLIC VOID ANewGameShowsTheTitleWithThreeShooters():
        Assert:Equals(-1, mGame:LastBonusFrame).
        Assert:IsTrue(mGame:Phase = GamePhase:Title).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(1, mGame:Wave).
        Assert:Equals("Centipede", mGame:Name).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFireKeyHasToBeLetGoAndPressedAgainToStartFromTheTitle():
        mGame:FireHeld = TRUE.
        mGame:Advance().
        Assert:IsTrue(mGame:Phase = GamePhase:Title).
        mGame:FireHeld = FALSE.
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        Assert:IsTrue(mGame:Phase = GamePhase:Playing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartGameMakesTwelveSegmentsAndMushroomsAboveThePlayerZone():
        mGame:StartGame().
        Assert:IsTrue(mGame:Phase = GamePhase:Playing).
        Assert:Equals(12, mGame:SegmentCount).
        Assert:IsTrue(mGame:SegmentIsHead(0)).
        Assert:IsFalse(mGame:SegmentIsHead(1)).
        Assert:IsTrue(mGame:MushroomCount > 0).
        Assert:IsTrue(mGame:MushroomCount <= 30).
        Assert:Equals(0, mGame:ZoneMushroomCount).
        Assert:Equals(3, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseGoesBackToTheTitleAndKeepsTheBestScore():
        mGame:StartGame().
        mGame:AddScore(500).
        mGame:Initialise().
        Assert:IsTrue(mGame:Phase = GamePhase:Title).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(500, mGame:HiScore).
        Assert:Equals(0, mGame:MushroomCount).
        Assert:Equals(0, mGame:SegmentCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGridMustHaveTheRightShapeAndALayerOfMushroomsAndPoison():
        DEFINE VARIABLE thrown AS INTEGER        NO-UNDO.
        DEFINE VARIABLE oOther AS CentipedeGame  NO-UNDO.
        DO ON ERROR UNDO, THROW:
            oOther = NEW CentipedeGame(NEW Grid(NEW ArrayStore(20, 30, "mushroom,poison")), NEW ScriptedRandom("1")).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW CentipedeGame(NEW Grid(NEW ArrayStore(30, 30, "state")), NEW ScriptedRandom("1")).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW CentipedeGame(CentipedeFactory:CreateGrid(), ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    /* ---- the clock ---- */

    @Test.
    METHOD PUBLIC VOID TickTurnsMillisecondsIntoFramesAtTheSpeed():
        mGame:SpeedPercent = 100.
        Assert:IsTrue(mGame:Tick(100)).
        Assert:Equals(6, mGame:Frames).
        mGame:SpeedPercent = 50.
        mGame:Tick(100).
        Assert:Equals(9, mGame:Frames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedStaysBetweenTwentyAndOneHundredPercent():
        mGame:SpeedPercent = 5.
        Assert:Equals(20, mGame:SpeedPercent).
        mGame:SpeedPercent = 500.
        Assert:Equals(100, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TickDoesNothingWhilePausedOrForNoTime():
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:Tick(100)).
        Assert:Equals(0, mGame:Frames).
        mGame:Paused = FALSE.
        Assert:IsFalse(mGame:Tick(0)).
        Assert:IsFalse(mGame:Tick(?)).
        Assert:Equals(0, mGame:Frames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALongStallIsCutToTheMostFramesAndNotCaughtUp():
        mGame:SpeedPercent = 100.
        mGame:Tick(5000).
        Assert:Equals(6, mGame:Frames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PhaseFramesCountTheFramesOfThePhase():
        Frames(5).
        Assert:Equals(5, mGame:PhaseFrames).
        mGame:StartGame().
        Assert:Equals(0, mGame:PhaseFrames).
        Frames(3).
        Assert:Equals(3, mGame:PhaseFrames).
        Assert:Equals(8, mGame:Frames).
    END METHOD.

    /* ---- the shooter ---- */

    @Test.
    METHOD PUBLIC VOID TheShooterMovesThreePixelsAFrame():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(100, 224).
        mGame:MoveX = 1.
        mGame:Advance().
        Assert:Equals(103, mGame:PlayerX).
        mGame:MoveX = -1.
        mGame:Advance().
        mGame:Advance().
        Assert:Equals(97, mGame:PlayerX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShooterStaysInThePlayerZoneAndOnTheBoard():
        Scene().
        KeepAlive().
        mGame:MoveY = -1.
        Frames(40).
        Assert:Equals(192, mGame:PlayerY).
        mGame:MoveY = 1.
        Frames(40).
        Assert:Equals(232, mGame:PlayerY).
        mGame:MoveX = -1.
        Frames(60).
        Assert:Equals(0, mGame:PlayerX).
        mGame:MoveX = 1.
        Frames(100).
        Assert:Equals(232, mGame:PlayerX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShooterCannotMoveIntoAMushroom():
        Scene().
        KeepAlive().
        mGame:PlaceMushroom(14, 28, 4).
        mGame:PlacePlayer(100, 224).
        mGame:MoveX = 1.
        Frames(20).
        Assert:Equals(103, mGame:PlayerX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlacePlayerBringsTheShooterInsideThePlayerZone():
        mGame:PlacePlayer(-50, 10).
        Assert:Equals(0, mGame:PlayerX).
        Assert:Equals(192, mGame:PlayerY).
        mGame:PlacePlayer(500, 500).
        Assert:Equals(232, mGame:PlayerX).
        Assert:Equals(232, mGame:PlayerY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MoveXAndMoveYAreKeptToMinusOneToOne():
        mGame:MoveX = 5.
        mGame:MoveY = -5.
        Assert:Equals(1, mGame:MoveX).
        Assert:Equals(-1, mGame:MoveY).
    END METHOD.

    /* ---- the shot ---- */

    @Test.
    METHOD PUBLIC VOID TheShooterFiresOneShotAtATime():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(100, 224).
        mGame:FireHeld = TRUE.
        mGame:Advance().
        Assert:IsTrue(mGame:ShotActive).
        Assert:Equals(1, mGame:ShotsFired).
        Assert:Equals(103, mGame:ShotX).
        Assert:Equals(216, mGame:ShotY).
        mGame:Advance().
        Assert:Equals(1, mGame:ShotsFired).
        Assert:Equals(208, mGame:ShotY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShotLeavesAtTheTopAndHoldingFireFiresAgain():
        Scene().
        KeepAlive().
        mGame:FireHeld = TRUE.
        Frames(40).
        Assert:IsTrue(mGame:ShotsFired >= 2).
        mGame:FireHeld = FALSE.
        Frames(40).
        Assert:IsFalse(mGame:ShotActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotTakesFourHitsToDestroyAMushroomAndScoresOneForIt():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(96, 224).
        mGame:PlaceMushroom(12, 20, 4).
        mGame:FireHeld = TRUE.
        Frames(6).
        mGame:FireHeld = FALSE.
        Frames(30).
        Assert:Equals(3, mGame:MushroomAt(12, 20)).
        Assert:Equals(0, mGame:MushroomsDestroyed).
        mGame:FireHeld = TRUE.
        Frames(150).
        Assert:Equals(0, mGame:MushroomAt(12, 20)).
        Assert:Equals(1, mGame:MushroomsDestroyed).
        Assert:Equals(1, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotThatKillsAMushroomTakesThePoisonWithIt():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(96, 224).
        mGame:PlaceMushroom(12, 20, 1).
        mGame:PoisonMushroom(12, 20).
        Assert:IsTrue(mGame:PoisonedAt(12, 20)).
        mGame:FireHeld = TRUE.
        Frames(30).
        Assert:Equals(0, mGame:MushroomAt(12, 20)).
        Assert:IsFalse(mGame:PoisonedAt(12, 20)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShotKillsABodySegmentForTenAndLeavesAMushroom():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(96, 224).
        mGame:AddSegment(12, 26, -1, FALSE).
        mGame:FireHeld = TRUE.
        Frames(2).
        Assert:Equals(10, mGame:Score).
        Assert:Equals(1, mGame:SegmentsKilled).
        Assert:Equals(0, mGame:HeadsKilled).
        Assert:Equals(4, mGame:MushroomAt(12, 26)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeadIsWorthOneHundredAndTheSegmentBehindItBecomesAHead():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(96, 224).
        mGame:AddSegment(12, 26, -1, TRUE).
        mGame:AddSegment(13, 26, -1, FALSE).
        Assert:Equals(3, mGame:SegmentCount).
        Assert:IsFalse(mGame:SegmentIsHead(2)).
        mGame:FireHeld = TRUE.
        Frames(2).
        Assert:Equals(100, mGame:Score).
        Assert:Equals(1, mGame:HeadsKilled).
        Assert:Equals(2, mGame:SegmentCount).
        Assert:IsTrue(mGame:SegmentIsHead(1)).
    END METHOD.

    /* ---- the centipede ---- */

    @Test.
    METHOD PUBLIC VOID ASegmentDropsARowAndTurnsRoundAtTheEdge():
        Scene().
        KeepAlive().
        mGame:AddSegment(1, 5, -1, TRUE).
        /* the segment added last is the last of the train, at index 1 */
        Frames(8).
        Assert:Equals(48, mGame:SegmentY(1)).
        Assert:Equals(1, mGame:SegmentDirection(1)).
        Assert:Equals(0, mGame:SegmentX(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASegmentDropsARowAndTurnsRoundAtAMushroom():
        Scene().
        KeepAlive().
        mGame:PlaceMushroom(3, 3, 4).
        mGame:AddSegment(5, 3, -1, TRUE).
        Frames(8).
        Assert:Equals(32, mGame:SegmentY(1)).
        Assert:Equals(1, mGame:SegmentDirection(1)).
        Assert:Equals(32, mGame:SegmentX(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASegmentFallingToTheNextRowSaysSo():
        Scene().
        KeepAlive().
        mGame:PlaceMushroom(3, 3, 4).
        mGame:AddSegment(5, 3, -1, TRUE).
        Frames(5).
        Assert:IsTrue(mGame:SegmentFalling(1)).
        Frames(4).
        Assert:IsFalse(mGame:SegmentFalling(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASegmentThatTouchesAPoisonedMushroomDivesToTheBottom():
        Scene().
        KeepAlive().
        mGame:PlaceMushroom(3, 3, 4).
        mGame:PoisonMushroom(3, 3).
        mGame:AddSegment(5, 3, -1, TRUE).
        Frames(120).
        Assert:Equals(232, mGame:SegmentY(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASegmentThatHasTouchedPoisonSaysItIsDiving():
        Scene().
        KeepAlive().
        mGame:PlaceMushroom(3, 3, 4).
        mGame:PoisonMushroom(3, 3).
        mGame:AddSegment(5, 3, -1, TRUE).
        Assert:IsFalse(mGame:SegmentDiving(1)).
        Frames(40).
        Assert:IsTrue(mGame:SegmentDiving(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AtTheBottomASegmentTurnsAndClimbsBackUp():
        Scene().
        KeepAlive().
        mGame:AddSegment(15, 29, -1, TRUE).
        Frames(64).
        Assert:Equals(224, mGame:SegmentY(1)).
        Assert:Equals(1, mGame:SegmentDirection(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SegmentsSpeedUpFromWaveFour():
        Assert:Equals(2, CentipedeRules:SegmentSpeed(1)).
        Assert:Equals(2, CentipedeRules:SegmentSpeed(3)).
        Assert:Equals(3, CentipedeRules:SegmentSpeed(4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSegmentReadersRefuseAnIndexThatIsNotASegment():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        Scene().
        mGame:AddSegment(5, 5, -1, TRUE).
        DO ON ERROR UNDO, THROW:
            mGame:SegmentX(1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:SegmentY(-1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:SegmentIsHead(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
        Assert:Equals(40, mGame:SegmentX(0)).
        Assert:Equals(40, mGame:SegmentY(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AddSegmentRefusesABadTileAndADirectionThatIsNotOneOrMinusOne():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:AddSegment(5, 30, -1, TRUE).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:AddSegment(5, 5, 0, TRUE).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearCentipedeTakesEverySegmentAway():
        mGame:StartGame().
        mGame:ClearCentipede().
        Assert:Equals(0, mGame:SegmentCount).
        Assert:Equals(0, mGame:HeadsToCome).
    END METHOD.

    /* ---- waves ---- */

    @Test.
    METHOD PUBLIC VOID WhenTheLastSegmentIsGoneTheWaveIsClearedAndTheNextOneStartsWithALooseHead():
        Scene().
        Frames(1).
        Assert:IsTrue(mGame:Phase = GamePhase:Cleared).
        Assert:Equals(1, mGame:WavesCleared).
        Frames(90).
        Assert:IsTrue(mGame:Phase = GamePhase:Playing).
        Assert:Equals(2, mGame:Wave).
        Assert:Equals(11, mGame:SegmentCount).
        Assert:Equals(1, mGame:HeadsToCome).
        Assert:Equals("Wave 2", mGame:TakeNotice()).
        Assert:Equals("", mGame:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLooseHeadsComeInFromTheLeftOfThePlayerZone():
        Scene().
        Frames(91).
        Assert:Equals(1, mGame:HeadsToCome).
        Frames(240).
        Assert:Equals(0, mGame:HeadsToCome).
        Assert:Equals(12, mGame:SegmentCount).
        Assert:IsTrue(mGame:SegmentIsHead(11)).
        Assert:Equals(192, mGame:SegmentY(11)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClearedPhaseHoldsForNinetyFramesAndCostsNoShooter():
        Scene().
        Frames(1).
        Frames(80).
        Assert:IsTrue(mGame:Phase = GamePhase:Cleared).
        Assert:Equals(3, mGame:Lives).
        Assert:IsTrue(mGame:PlayerAlive).
    END METHOD.

    /* ---- losing a shooter ---- */

    @Test.
    METHOD PUBLIC VOID ASegmentTouchingTheShooterKillsIt():
        Scene().
        KillShooter().
        Assert:IsTrue(mGame:Phase = GamePhase:Dying).
        Assert:Equals(2, mGame:Lives).
        Assert:Equals(1, mGame:Deaths).
        Assert:IsFalse(mGame:PlayerAlive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterTheDyingTheFieldIsMendedAndTheWaveStartsAgain():
        Scene().
        mGame:PlaceMushroom(5, 5, 2).
        mGame:PlaceMushroom(6, 5, 4).
        mGame:PoisonMushroom(6, 5).
        mGame:PlaceMushroom(7, 5, 4).
        KillShooter().
        Frames(99).
        Assert:IsTrue(mGame:Phase = GamePhase:Dying).
        Frames(1).
        Assert:IsTrue(mGame:Phase = GamePhase:Playing).
        Assert:Equals(4, mGame:MushroomAt(5, 5)).
        Assert:IsFalse(mGame:PoisonedAt(6, 5)).
        Assert:Equals(10, mGame:Score).
        Assert:Equals(12, mGame:SegmentCount).
        Assert:Equals(1, mGame:Wave).
        Assert:IsTrue(mGame:PlayerAlive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheThirdShooterLostEndsTheGameAndTheFireKeyReturnsToTheTitle():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Scene().
        DO i = 1 TO 3:
            KillShooter().
            Frames(100).
            mGame:ClearCentipede().
        END.
        Assert:IsTrue(mGame:Phase = GamePhase:GameOver).
        Assert:Equals(0, mGame:Lives).
        mGame:FireHeld = TRUE.
        Frames(100).
        Assert:IsTrue(mGame:Phase = GamePhase:GameOver).
        mGame:FireHeld = FALSE.
        Frames(1).
        mGame:FireHeld = TRUE.
        Frames(1).
        Assert:IsTrue(mGame:Phase = GamePhase:Title).
    END METHOD.

    /* ---- score ---- */

    @Test.
    METHOD PUBLIC VOID AnExtraShooterComesAtTwelveThousandAndAgainAtTwentyFourThousand():
        mGame:StartGame().
        mGame:AddScore(11999).
        Assert:Equals(3, mGame:Lives).
        mGame:AddScore(1).
        Assert:Equals(4, mGame:Lives).
        Assert:Equals(1, mGame:ExtraLives).
        Assert:Equals("Extra shooter", mGame:TakeNotice()).
        mGame:AddScore(12000).
        Assert:Equals(5, mGame:Lives).
        Assert:Equals(2, mGame:ExtraLives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBestScoreRisesWithTheScoreAndNeverFalls():
        mGame:HiScore = 300.
        mGame:StartGame().
        mGame:AddScore(100).
        Assert:Equals(300, mGame:HiScore).
        mGame:AddScore(250).
        Assert:Equals(350, mGame:HiScore).
        mGame:Initialise().
        Assert:Equals(350, mGame:HiScore).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APointsOrBestScoreBelowZeroIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:AddScore(-1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:HiScore = -5.
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    /* ---- mushrooms ---- */

    @Test.
    METHOD PUBLIC VOID MushroomsArePlacedPoisonedAndTakenAway():
        mGame:PlaceMushroom(3, 4, 2).
        Assert:Equals(2, mGame:MushroomAt(3, 4)).
        Assert:IsFalse(mGame:PoisonedAt(3, 4)).
        mGame:PoisonMushroom(3, 4).
        Assert:IsTrue(mGame:PoisonedAt(3, 4)).
        mGame:PlaceMushroom(3, 4, 4).
        Assert:IsFalse(mGame:PoisonedAt(3, 4)).
        mGame:PoisonMushroom(9, 9).
        Assert:IsFalse(mGame:PoisonedAt(9, 9)).
        mGame:PlaceMushroom(3, 4, 0).
        Assert:Equals(0, mGame:MushroomAt(3, 4)).
        Assert:Equals(0, mGame:MushroomCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearFieldTakesEveryMushroomAway():
        mGame:PlaceMushroom(3, 4, 2).
        mGame:PlaceMushroom(8, 27, 4).
        Assert:Equals(2, mGame:MushroomCount).
        Assert:Equals(1, mGame:ZoneMushroomCount).
        mGame:ClearField().
        Assert:Equals(0, mGame:MushroomCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFieldVersionGoesUpWhenAMushroomChanges():
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        v = mGame:FieldVersion.
        mGame:PlaceMushroom(3, 4, 4).
        Assert:IsTrue(mGame:FieldVersion > v).
        v = mGame:FieldVersion.
        mGame:PoisonMushroom(3, 4).
        Assert:IsTrue(mGame:FieldVersion > v).
        v = mGame:FieldVersion.
        mGame:PoisonMushroom(3, 4).
        Assert:Equals(v, mGame:FieldVersion).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MushroomsRefuseATileOffTheBoardAndBadHitPoints():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:PlaceMushroom(30, 0, 4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:PlaceMushroom(0, 0, 5).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:MushroomAt(-1, 0).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:PoisonedAt(0, 30).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:PoisonMushroom(0, ?).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(5, thrown).
    END METHOD.

    /* ---- the flea ---- */

    @Test.
    METHOD PUBLIC VOID TheFleaFallsDownItsColumn():
        Scene().
        KeepAlive().
        mGame:SpawnFlea(10).
        Assert:IsTrue(mGame:FleaActive).
        Assert:Equals(80, mGame:FleaX).
        Assert:Equals(0, mGame:FleaY).
        Assert:Equals(2, mGame:FleaHp).
        Frames(10).
        Assert:Equals(20, mGame:FleaY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFleaTakesTwoHitsAndIsWorthTwoHundred():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Scene().
        KeepAlive().
        mGame:PlacePlayer(96, 224).
        mGame:SpawnFlea(12).
        mGame:FireHeld = TRUE.
        DO i = 1 TO 200 WHILE mGame:FleaKills = 0:
            mGame:Advance().
        END.
        Assert:Equals(1, mGame:FleaKills).
        Assert:Equals(2, mGame:FleaHits).
        Assert:IsFalse(mGame:FleaActive).
        Assert:Equals(200, mGame:LastBonus).
        Assert:Equals(96, mGame:LastBonusX).
        Assert:IsTrue(mGame:LastBonusY >= 0 AND mGame:LastBonusY < 240).
        Assert:IsTrue(mGame:LastBonusFrame > 0 AND mGame:LastBonusFrame <= mGame:Frames).
        Assert:IsTrue(mGame:Score >= 200).
        Assert:IsTrue(mGame:Phase = GamePhase:Playing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFleaComesOnceThePlayerZoneIsNearlyEmptyOfMushrooms():
        Scene().
        KeepAlive().
        Frames(299).
        Assert:IsFalse(mGame:FleaActive).
        Frames(1).
        Assert:IsTrue(mGame:FleaActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFleaStaysAwayWhileThePlayerZoneHasMushrooms():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        Scene().
        KeepAlive().
        DO x = 0 TO 5:
            mGame:PlaceMushroom(x, 26, 4).
        END.
        Assert:Equals(6, mGame:ZoneMushroomCount).
        Frames(310).
        Assert:IsFalse(mGame:FleaActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFleaLeavesAtTheBottomWithoutHurtingAShooterOutOfItsWay():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(8, 224).
        mGame:SpawnFlea(20).
        Frames(130).
        Assert:IsFalse(mGame:FleaActive).
        Assert:IsTrue(mGame:Phase = GamePhase:Playing).
        Assert:Equals(3, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFleaTouchingTheShooterKillsIt():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(80, 232).
        mGame:SpawnFlea(10).
        Frames(130).
        Assert:IsTrue(mGame:Phase = GamePhase:Dying).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpawnFleaRefusesAColumnOffTheBoard():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:SpawnFlea(30).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    /* ---- the spider ---- */

    @Test.
    METHOD PUBLIC VOID TheSpiderCrawlsAcrossAndLeavesTheOtherSide():
        Scene().
        KeepAlive().
        mGame:SpawnSpider(TRUE, 25).
        Assert:IsTrue(mGame:SpiderActive).
        Assert:Equals(-16, mGame:SpiderX).
        Assert:Equals(200, mGame:SpiderY).
        Frames(10).
        Assert:Equals(4, mGame:SpiderX).
        Frames(120).
        Assert:IsFalse(mGame:SpiderActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpiderEatsTheMushroomsItCrawlsOver():
        Scene().
        KeepAlive().
        mGame:PlaceMushroom(5, 25, 4).
        mGame:SpawnSpider(TRUE, 25).
        Frames(40).
        Assert:Equals(0, mGame:MushroomAt(5, 25)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpiderTouchingTheShooterKillsIt():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(8, 224).
        mGame:SpawnSpider(TRUE, 28).
        Frames(10).
        Assert:IsTrue(mGame:Phase = GamePhase:Dying).
    END METHOD.

    /* The spider crosses the shot's lane in a few frames, so the shot is fired at the moment that puts it in the spider's row as the
       spider goes by: the spider moves 2 pixels a frame and the shot 8, and in a frame the shot moves before the spider does. */
    @Test.
    METHOD PUBLIC VOID ASpiderShotClosePaysNineHundred():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(120, 224).
        mGame:SpawnSpider(TRUE, 26).
        Frames(62).
        mGame:FireHeld = TRUE.
        Frames(5).
        Assert:Equals(1, mGame:SpiderKills).
        Assert:Equals(900, mGame:LastBonus).
        Assert:Equals(900, mGame:Score).
        Assert:IsFalse(mGame:SpiderActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpiderShotFarOffPaysThreeHundred():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(8, 224).
        mGame:SpawnSpider(FALSE, 20).
        Frames(110).
        mGame:FireHeld = TRUE.
        Frames(10).
        Assert:Equals(1, mGame:SpiderKills).
        Assert:Equals(300, mGame:LastBonus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpawnSpiderRefusesARowOutsideTheLowerRows():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:SpawnSpider(TRUE, 10).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:SpawnSpider(TRUE, 30).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    /* ---- the scorpion ---- */

    @Test.
    METHOD PUBLIC VOID TheScorpionPoisonsTheMushroomsInItsRow():
        Scene().
        KeepAlive().
        mGame:PlaceMushroom(4, 5, 4).
        mGame:PlaceMushroom(4, 6, 4).
        mGame:SpawnScorpion(5, TRUE).
        Assert:IsTrue(mGame:ScorpionActive).
        Assert:Equals(1, mGame:ScorpionDirection).
        Frames(70).
        Assert:IsTrue(mGame:PoisonedAt(4, 5)).
        Assert:IsFalse(mGame:PoisonedAt(4, 6)).
        Assert:Equals(40, mGame:ScorpionY).
        Assert:Equals(54, mGame:ScorpionX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScorpionGoesLeftWhenItComesFromTheRight():
        Scene().
        KeepAlive().
        mGame:SpawnScorpion(10, FALSE).
        Assert:Equals(-1, mGame:ScorpionDirection).
        Assert:Equals(240, mGame:ScorpionX).
        Frames(10).
        Assert:Equals(230, mGame:ScorpionX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScorpionShotPaysOneThousand():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(120, 224).
        mGame:SpawnScorpion(10, TRUE).
        Frames(112).
        mGame:FireHeld = TRUE.
        Frames(30).
        Assert:Equals(1, mGame:ScorpionKills).
        Assert:Equals(1000, mGame:LastBonus).
        Assert:Equals(1000, mGame:Score).
        Assert:IsFalse(mGame:ScorpionActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScorpionDoesNotHurtTheShooter():
        Scene().
        KeepAlive().
        mGame:PlacePlayer(8, 192).
        mGame:SpawnScorpion(22, TRUE).
        Frames(60).
        Assert:IsTrue(mGame:Phase = GamePhase:Playing).
        Assert:Equals(3, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScorpionOnlyComesFromWaveTwo():
        mGame:StartGame().
        mGame:ClearCreatures().
        Frames(1).
        Assert:IsFalse(mGame:ScorpionActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpawnScorpionRefusesARowThatIsNotInTheUpperBoard():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:SpawnScorpion(0, TRUE).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:SpawnScorpion(23, TRUE).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearCreaturesSendsEveryCreatureAway():
        Scene().
        mGame:SpawnFlea(3).
        mGame:SpawnSpider(TRUE, 25).
        mGame:SpawnScorpion(5, TRUE).
        mGame:ClearCreatures().
        Assert:IsFalse(mGame:FleaActive).
        Assert:IsFalse(mGame:SpiderActive).
        Assert:IsFalse(mGame:ScorpionActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedGameDoesNotMoveButAdvanceStillMakesAFrame():
        Scene().
        KeepAlive().
        mGame:Paused = TRUE.
        mGame:Tick(100).
        Assert:Equals(0, mGame:PhaseFrames).
        mGame:Advance().
        Assert:Equals(1, mGame:PhaseFrames).
    END METHOD.

END CLASS.
