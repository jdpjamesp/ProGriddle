/* The rules of Xevious, driven frame by frame with Advance. A scene is built with the public set up methods (PlaceGround, SpawnAir,
   PlacePlayer and so on) so each test controls exactly what is on the field. Waves of enemies are stopped in a scene, and the random
   source always says 1. The ship starts at 104, 208, so its sight is at 112, 128 (88 pixels above its middle). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousGameTests:

    DEFINE PRIVATE VARIABLE mGame AS XeviousGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = XeviousFactory:Create(NEW ScriptedRandom("1")).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* A game in play on an empty field: no waves, no ground targets, no enemies, the ship at 104, 208. */
    METHOD PRIVATE VOID Scene():
        mGame:StartGame().
        mGame:StopWaves().
        mGame:ClearGround().
        mGame:StopLand().
        mGame:ClearAir().
        mGame:ClearBullets().
        mGame:PlacePlayer(104, 208).
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* The ship is killed by an enemy put on top of it. */
    METHOD PRIVATE VOID KillShip():
        mGame:SpawnAir(XeviousAir:Toroid, mGame:PlayerX, mGame:PlayerY).
        mGame:Advance().
    END METHOD.

    /* Whether any slot of the effects holds an effect of a kind. */
    METHOD PRIVATE LOGICAL HasFx(INPUT poKind AS XeviousFx):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO mGame:FxSlots - 1:
            IF VALID-OBJECT(mGame:FxKindAt(i)) AND mGame:FxKindAt(i) = poKind THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* ---- starting ---- */

    @Test.
    METHOD PUBLIC VOID ANewGameShowsTheTitleWithNothingOnTheField():
        Assert:Equals(STRING(XeviousPhase:Title), STRING(mGame:Phase)).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(1, mGame:Stage).
        Assert:Equals(0, mGame:AirCount).
        Assert:IsFalse(mGame:IsOver).
        Assert:IsFalse(mGame:PlayerAlive).
        Assert:Equals("Xevious", mGame:Name).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleWaitsForAFireKeyThatHasBeenLetGoAndPressedAgain():
        mGame:ZapHeld = TRUE.
        Frames(5).
        Assert:Equals(STRING(XeviousPhase:Title), STRING(mGame:Phase)).
        mGame:ZapHeld = FALSE.
        Frames(2).
        mGame:BombHeld = TRUE.
        Frames(1).
        Assert:Equals(STRING(XeviousPhase:Playing), STRING(mGame:Phase)).
        Assert:IsTrue(mGame:PlayerAlive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingAGameGivesThreeShipsAndTheFirstStage():
        mGame:StartGame().
        Assert:Equals(STRING(XeviousPhase:Playing), STRING(mGame:Phase)).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(1, mGame:Stage).
        Assert:Equals(104, mGame:PlayerX).
        Assert:Equals(208, mGame:PlayerY).
        Assert:Equals(0, mGame:Protection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGridMustHaveTheRightShapeAndTheGroundLayer():
        DEFINE VARIABLE thrown AS INTEGER      NO-UNDO.
        DEFINE VARIABLE oOther AS XeviousGame  NO-UNDO.
        DO ON ERROR UNDO, THROW:
            oOther = NEW XeviousGame(NEW Grid(NEW ArrayStore(20, 16, "ground")), NEW ScriptedRandom("1")).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW XeviousGame(NEW Grid(NEW ArrayStore(14, 16, "state")), NEW ScriptedRandom("1")).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW XeviousGame(XeviousFactory:CreateGrid(), ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    /* ---- the clock ---- */

    @Test.
    METHOD PUBLIC VOID TickTurnsMillisecondsIntoFramesAtTheSpeedItIsSetTo():
        mGame:StartGame().
        mGame:SpeedPercent = 100.
        Assert:IsFalse(mGame:Tick(10)).
        Assert:IsTrue(mGame:Tick(10)).
        Assert:Equals(1, mGame:Frames).
        Assert:IsFalse(mGame:Tick(0)).
        Assert:IsFalse(mGame:Tick(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedIsKeptBetween20And100AndAPausedGameDoesNotMove():
        mGame:SpeedPercent = 5.
        Assert:Equals(20, mGame:SpeedPercent).
        mGame:SpeedPercent = 500.
        Assert:Equals(100, mGame:SpeedPercent).
        mGame:StartGame().
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:Tick(100)).
        Assert:Equals(0, mGame:Frames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStallIsCutToAHundredMilliseconds():
        mGame:StartGame().
        mGame:SpeedPercent = 100.
        mGame:Tick(5000).
        Assert:Equals(6, mGame:Frames).
    END METHOD.

    /* ---- the ship ---- */

    @Test.
    METHOD PUBLIC VOID TheShipMovesTwoPixelsAFrameInEightDirectionsAndStaysInTheField():
        Scene().
        mGame:MoveX = 1.
        mGame:MoveY = -1.
        Frames(5).
        Assert:Equals(114, mGame:PlayerX).
        Assert:Equals(198, mGame:PlayerY).
        mGame:MoveX = -1.
        mGame:MoveY = 1.
        Frames(200).
        Assert:Equals(0, mGame:PlayerX).
        Assert:Equals(240, mGame:PlayerY).
        mGame:MoveX = 1.
        mGame:MoveY = -1.
        Frames(200).
        Assert:Equals(208, mGame:PlayerX).
        Assert:Equals(0, mGame:PlayerY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSteeringIsKeptBetweenMinusOneAndOne():
        mGame:MoveX = 5.
        mGame:MoveY = -5.
        Assert:Equals(1, mGame:MoveX).
        Assert:Equals(-1, mGame:MoveY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlacingTheShipKeepsItInsideTheField():
        mGame:PlacePlayer(-50, 1000).
        Assert:Equals(0, mGame:PlayerX).
        Assert:Equals(240, mGame:PlayerY).
        mGame:PlacePlayer(500, -9).
        Assert:Equals(208, mGame:PlayerX).
        Assert:Equals(0, mGame:PlayerY).
    END METHOD.

    /* ---- the Zapper ---- */

    @Test.
    METHOD PUBLIC VOID HoldingTheZapperFiresAShotThatFliesUpSixPixelsAFrame():
        Scene().
        mGame:ZapHeld = TRUE.
        mGame:Advance().
        Assert:Equals(1, mGame:ZapsFired).
        Assert:Equals(1, mGame:ZapCount).
        Assert:IsTrue(mGame:ZapActive(0)).
        Assert:IsFalse(mGame:ZapActive(1)).
        Assert:Equals(110, mGame:ZapX(0)).
        Assert:Equals(196, mGame:ZapY(0)).
        mGame:ZapHeld = FALSE.
        mGame:Advance().
        Assert:Equals(190, mGame:ZapY(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAreAtMostTwoShotsInTheAirAndTheyHaveAGapBetweenThem():
        Scene().
        mGame:ZapHeld = TRUE.
        Frames(7).
        Assert:Equals(1, mGame:ZapCount).
        Frames(1).
        Assert:Equals(2, mGame:ZapCount).
        Frames(30).
        Assert:IsTrue(mGame:ZapCount <= 2).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotLeavesAtTheTopAndMakesRoomForAnother():
        Scene().
        mGame:PlacePlayer(104, 40).
        mGame:ZapHeld = TRUE.
        mGame:Advance().
        mGame:ZapHeld = FALSE.
        Frames(10).
        Assert:Equals(0, mGame:ZapCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotKillsAnAirEnemyAndScoresIt():
        Scene().
        mGame:SpawnAir(XeviousAir:Zakato, 104, 120).
        mGame:ZapHeld = TRUE.
        Frames(20).
        Assert:Equals(0, mGame:AirCount).
        Assert:Equals(1, mGame:AirKills).
        Assert:Equals(300, mGame:Score).
        Assert:IsTrue(HasFx(XeviousFx:AirBlast)).
        Assert:IsTrue(HasFx(XeviousFx:Points)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShotOnlyHitsWhatItTouches():
        Scene().
        mGame:SpawnAir(XeviousAir:Zakato, 20, 120).
        mGame:ZapHeld = TRUE.
        Frames(16).
        Assert:Equals(1, mGame:AirCount).
        Assert:Equals(0, mGame:AirKills).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheZapperDoesNothingToTheGround():
        Scene().
        mGame:PlaceGround(XeviousGround:Barra, 104, 120).
        mGame:ZapHeld = TRUE.
        Frames(20).
        Assert:Equals(0, mGame:GroundKills).
        Assert:Equals(1, mGame:GroundCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABacuraTakesShotsWithoutDyingAndIsPushedBack():
        Scene().
        mGame:SpawnAir(XeviousAir:Bacura, 104, 100).
        mGame:ZapHeld = TRUE.
        Frames(40).
        Assert:IsTrue(mGame:Clangs > 0).
        Assert:Equals(0, mGame:AirKills).
        Assert:Equals(1, mGame:AirCount).
        Assert:Equals(0, mGame:Score).
    END METHOD.

    /* ---- the Blaster ---- */

    @Test.
    METHOD PUBLIC VOID TheSightIsEightyEightPixelsAboveTheShipsMiddle():
        Scene().
        Assert:Equals(112, mGame:SightX).
        Assert:Equals(128, mGame:SightY).
        mGame:PlacePlayer(104, 40).
        Assert:Equals(4, mGame:SightY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSightKnowsWhenAVisibleTargetIsUnderItAndIgnoresHiddenOnes():
        Scene().
        Assert:IsFalse(mGame:SightOnTarget).
        mGame:PlaceGround(XeviousGround:Sol, 104, 120).
        Assert:IsFalse(mGame:SightOnTarget).
        mGame:PlaceGround(XeviousGround:Barra, 104, 120).
        Assert:IsTrue(mGame:SightOnTarget).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBombLandsOnTheSightAfterTwentySixFramesAndBurstsForFourteen():
        Scene().
        mGame:BombHeld = TRUE.
        mGame:Advance().
        mGame:BombHeld = FALSE.
        Assert:IsTrue(mGame:BombActive).
        Assert:Equals(1, mGame:BombsDropped).
        Assert:Equals(1, mGame:BombAge).
        Assert:IsTrue(mGame:BombY < 216).
        Frames(24).
        Assert:IsTrue(mGame:BombActive).
        Frames(1).
        Assert:IsFalse(mGame:BombActive).
        Assert:IsTrue(mGame:BurstActive).
        Assert:Equals(1, mGame:BombBursts).
        Assert:Equals(112, mGame:BurstX).
        Frames(14).
        Assert:IsFalse(mGame:BurstActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyOneBombIsInFlightAtATime():
        Scene().
        mGame:BombHeld = TRUE.
        Frames(10).
        Assert:Equals(1, mGame:BombsDropped).
        Frames(60).
        Assert:IsTrue(mGame:BombsDropped >= 2).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombDestroysTheGroundTargetUnderTheSightAndScoresIt():
        Scene().
        mGame:PlaceGround(XeviousGround:Barra, 104, 120).
        mGame:BombHeld = TRUE.
        Frames(27).
        Assert:Equals(1, mGame:GroundKills).
        Assert:Equals(10, mGame:Score).
        Assert:Equals(0, mGame:GroundCount).
        Assert:Equals(2, mGame:GroundState(0)).
        Assert:IsTrue(HasFx(XeviousFx:GroundBlast)).
        Assert:Equals(1, mGame:StageKilled).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombMissesATargetThatIsNotUnderTheSight():
        Scene().
        mGame:PlaceGround(XeviousGround:Barra, 20, 120).
        mGame:BombHeld = TRUE.
        Frames(27).
        Assert:Equals(0, mGame:GroundKills).
        Assert:Equals(1, mGame:GroundCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombDoesNothingToTheAir():
        Scene().
        mGame:SpawnAir(XeviousAir:Zakato, 104, 120).
        mGame:BombHeld = TRUE.
        Frames(26).
        Assert:Equals(1, mGame:AirCount).
        Assert:Equals(0, mGame:AirKills).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATougherTargetTakesTwoBombs():
        Scene().
        mGame:PlaceGround(XeviousGround:GaruBarra, 104, 120).
        mGame:BombHeld = TRUE.
        Frames(27).
        Assert:Equals(0, mGame:GroundKills).
        Assert:Equals(1, mGame:GroundCount).
        /* the burst is over, and the ship moves so that the sight is over the target: a bomb lands on the ground it was dropped on */
        mGame:BombHeld = FALSE.
        Frames(14).
        mGame:PlacePlayer(104, mGame:GroundY(0) + 88).
        mGame:BombHeld = TRUE.
        Frames(30).
        Assert:Equals(1, mGame:GroundKills).
        Assert:Equals(300, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombFindsAHiddenTowerAndItIsWorthTwoThousand():
        Scene().
        mGame:PlaceGround(XeviousGround:Sol, 104, 120).
        mGame:BombHeld = TRUE.
        Frames(27).
        Assert:Equals(1, mGame:SolsFound).
        Assert:Equals(1, mGame:StageSols).
        Assert:Equals(2000, mGame:Score).
        Assert:Equals(3, mGame:GroundState(0)).
        Frames(24).
        Assert:Equals(2, mGame:GroundState(0)).
        Assert:Equals(0, mGame:GroundKills).
        Assert:IsTrue(HasFx(XeviousFx:Reveal)).
        Assert:IsTrue(HasFx(XeviousFx:Points)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombFindsTheHiddenFlagAndItIsAnExtraShip():
        Scene().
        mGame:PlaceGround(XeviousGround:Flag, 104, 120).
        mGame:BombHeld = TRUE.
        Frames(27).
        Assert:Equals(1, mGame:FlagsFound).
        /* the pennant waits where it was found, and is an extra ship for the ship that flies over it */
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(4, mGame:GroundState(0)).
        mGame:PlacePlayer(mGame:GroundX(0), mGame:GroundY(0)).
        mGame:Advance().
        Assert:Equals(4, mGame:Lives).
        Assert:Equals(1, mGame:ExtraLives).
        Assert:Equals(0, mGame:GroundState(0)).
        Assert:Equals("EXTRA SHIP", mGame:TakeNotice()).
        Assert:Equals("", mGame:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGroundScrollsTwoPixelsInEveryThreeFramesAndTheBombMovesWithIt():
        Scene().
        mGame:PlaceGround(XeviousGround:Barra, 20, 100).
        Frames(30).
        Assert:Equals(120, mGame:GroundY(0)).
        Assert:Equals(20, mGame:Distance).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGroundTargetThatScrollsOffTheBottomIsGone():
        Scene().
        mGame:PlaceGround(XeviousGround:Barra, 20, 240).
        Frames(40).
        Assert:Equals(0, mGame:GroundCount).
        Assert:Equals(0, mGame:GroundState(0)).
    END METHOD.

    /* ---- the enemies ---- */

    @Test.
    METHOD PUBLIC VOID AnAirEnemyThatTouchesTheShipDestroysIt():
        Scene().
        KillShip().
        Assert:Equals(STRING(XeviousPhase:Dying), STRING(mGame:Phase)).
        Assert:Equals(2, mGame:Lives).
        Assert:Equals(1, mGame:Deaths).
        Assert:IsTrue(HasFx(XeviousFx:ShipBlast)).
        Assert:IsFalse(mGame:PlayerAlive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEnemyBulletThatTouchesTheShipDestroysIt():
        Scene().
        mGame:SpawnBoss().
        mGame:ClearBoss().
        mGame:SpawnAir(XeviousAir:Zakato, 100, 100).
        Frames(40).
        /* the Zakato burst into a ring: eight bullets, none near the ship */
        Assert:Equals(8, mGame:BulletCount).
        Assert:Equals(8, mGame:EnemyShots).
        Assert:Equals(STRING(XeviousPhase:Playing), STRING(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AZakatoBurstsIntoARingOfEightBulletsAfterFortyFrames():
        Scene().
        mGame:SpawnAir(XeviousAir:Zakato, 20, 100).
        Frames(39).
        Assert:Equals(1, mGame:AirCount).
        Assert:Equals(0, mGame:BulletCount).
        Frames(1).
        Assert:Equals(0, mGame:AirCount).
        Assert:Equals(8, mGame:BulletCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABulletOnTheShipKillsItAndTheBulletsReadBack():
        Scene().
        mGame:SpawnAir(XeviousAir:Zakato, 96, 140).
        Frames(40).
        Assert:IsTrue(mGame:BulletCount > 0).
        Assert:IsTrue(mGame:BulletActive(0) OR mGame:BulletActive(1)).
        Assert:IsTrue(mGame:BulletX(0) > 0).
        Assert:IsTrue(mGame:BulletY(0) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEnemyThatFliesOffTheFieldIsGone():
        Scene().
        mGame:SpawnAir(XeviousAir:Toroid, 20, 120).
        Frames(400).
        Assert:Equals(0, mGame:AirCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnemiesAreReadByTheirSlotNumber():
        Scene().
        mGame:SpawnAir(XeviousAir:Jara, 60, 30).
        Assert:IsTrue(mGame:AirActive(0)).
        Assert:IsFalse(mGame:AirActive(1)).
        Assert:Equals(STRING(XeviousAir:Jara), STRING(mGame:AirKindAt(0))).
        Assert:Equals(60, mGame:AirX(0)).
        Assert:Equals(30, mGame:AirY(0)).
        Assert:Equals(0, mGame:AirAge(0)).
        Frames(10).
        Assert:Equals(10, mGame:AirAge(0)).
        Assert:Equals(40, mGame:AirY(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGroundTurretFiresAtTheShip():
        Scene().
        mGame:PlaceGround(XeviousGround:Logram, 20, 40).
        Frames(146).
        Assert:IsTrue(mGame:EnemyShots >= 1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGroundLauncherSendsUpAZakato():
        Scene().
        mGame:PlaceGround(XeviousGround:GaruZakato, 20, 20).
        Frames(185).
        Assert:IsTrue(mGame:AirCount >= 1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGroundTankCrawlsAcrossTheGround():
        Scene().
        mGame:PlaceGround(XeviousGround:Grobda, 100, 20).
        Frames(30).
        Assert:IsTrue(mGame:GroundX(0) > 100).
        Assert:Equals(STRING(XeviousGround:Grobda), STRING(mGame:GroundKindAt(0))).
        Assert:Equals(30, mGame:GroundAge(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WavesOfEnemiesComeByThemselvesOnceTheyAreAllowed():
        mGame:StartGame().
        mGame:ClearGround().
        Frames(400).
        Assert:IsTrue(mGame:AirCount > 0 OR mGame:AirKills > 0 OR mGame:Phase <> XeviousPhase:Playing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSlotNumbersAreChecked():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            x = mGame:AirX(99).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            x = mGame:GroundX(-1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            x = mGame:BulletX(30).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            x = mGame:FxX(30).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            x = mGame:ZapX(2).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(5, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheEffectsHaveAnAgeAPlaceAndAValueAndEndAfterTheirLife():
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE found AS INTEGER NO-UNDO INITIAL -1.
        Scene().
        mGame:SpawnAir(XeviousAir:Zakato, 104, 120).
        mGame:ZapHeld = TRUE.
        Frames(20).
        DO i = 0 TO mGame:FxSlots - 1:
            IF VALID-OBJECT(mGame:FxKindAt(i)) AND mGame:FxKindAt(i) = XeviousFx:Points THEN found = i.
        END.
        Assert:IsTrue(found >= 0).
        Assert:Equals(300, mGame:FxValue(found)).
        Assert:IsTrue(mGame:FxX(found) > 0).
        Assert:IsTrue(mGame:FxY(found) > 0).
        Assert:IsTrue(mGame:FxAge(found) >= 0).
        mGame:ZapHeld = FALSE.
        Frames(80).
        Assert:IsFalse(VALID-OBJECT(mGame:FxKindAt(found))).
    END METHOD.

    /* ---- losing a ship ---- */

    @Test.
    METHOD PUBLIC VOID AfterTheShipBreaksUpItComesBackProtectedAndTheAirIsClear():
        Scene().
        KillShip().
        mGame:SpawnAir(XeviousAir:Toroid, 20, 20).
        Frames(89).
        Assert:Equals(STRING(XeviousPhase:Dying), STRING(mGame:Phase)).
        Frames(1).
        Assert:Equals(STRING(XeviousPhase:Playing), STRING(mGame:Phase)).
        Assert:Equals(150, mGame:Protection + 0).
        Assert:Equals(0, mGame:AirCount).
        Assert:Equals(104, mGame:PlayerX).
        Assert:Equals(208, mGame:PlayerY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AProtectedShipCannotBeHit():
        Scene().
        KillShip().
        Frames(90).
        mGame:StopWaves().
        mGame:SpawnAir(XeviousAir:Toroid, mGame:PlayerX, mGame:PlayerY).
        Frames(5).
        Assert:Equals(STRING(XeviousPhase:Playing), STRING(mGame:Phase)).
        Assert:Equals(2, mGame:Lives).
        Frames(160).
        mGame:ClearAir().
        mGame:SpawnAir(XeviousAir:Toroid, mGame:PlayerX, mGame:PlayerY).
        mGame:Advance().
        Assert:Equals(STRING(XeviousPhase:Dying), STRING(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStageGoesBackToTheLastCheckpointAfterADeath():
        Scene().
        Frames(800).
        Assert:Equals(533, mGame:Distance).
        KillShip().
        Frames(90).
        Assert:Equals(480, mGame:Distance).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameIsOverWhenTheLastShipIsLostAndWaitsForAFireKey():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Scene().
        DO i = 1 TO 3:
            mGame:StopWaves().
            mGame:ClearAir().
            mGame:ClearBullets().
            Frames(160).
            KillShip().
            Frames(90).
        END.
        Assert:Equals(STRING(XeviousPhase:GameOver), STRING(mGame:Phase)).
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(0, mGame:Lives).
        Assert:Equals(3, mGame:Deaths).
        mGame:ZapHeld = TRUE.
        Frames(100).
        Assert:Equals(STRING(XeviousPhase:GameOver), STRING(mGame:Phase)).
        mGame:ZapHeld = FALSE.
        Frames(2).
        mGame:ZapHeld = TRUE.
        Frames(1).
        Assert:Equals(STRING(XeviousPhase:Title), STRING(mGame:Phase)).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    /* ---- the score ---- */

    @Test.
    METHOD PUBLIC VOID TheScoreRaisesTheBestScoreAndAnExtraShipComesAtTwentyThousandAndSixtyThousand():
        Scene().
        mGame:AddScore(19990).
        Assert:Equals(3, mGame:Lives).
        mGame:AddScore(10).
        Assert:Equals(4, mGame:Lives).
        Assert:Equals(20000, mGame:HiScore).
        Assert:Equals("EXTRA SHIP", mGame:TakeNotice()).
        mGame:AddScore(39990).
        Assert:Equals(4, mGame:Lives).
        mGame:AddScore(10).
        Assert:Equals(5, mGame:Lives).
        mGame:AddScore(60000).
        Assert:Equals(6, mGame:Lives).
        Assert:Equals(3, mGame:ExtraLives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBestScoreCannotBeNegativeAndPointsCannotBeEither():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:HiScore = -1.
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:AddScore(-5).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
        mGame:HiScore = 500.
        Assert:Equals(500, mGame:HiScore).
    END METHOD.

    /* ---- the stages ---- */

    @Test.
    METHOD PUBLIC VOID AStageEndsWhenItsGroundHasGoneByAndThenAHigherOneBegins():
        mGame:StartGame().
        mGame:StopWaves().
        Frames(2880).
        Assert:Equals(STRING(XeviousPhase:StageClear), STRING(mGame:Phase)).
        Assert:Equals(1, mGame:StagesCleared).
        Assert:Equals(0, mGame:StagePercent).
        Assert:Equals(0, mGame:StageBonus).
        Assert:IsTrue(mGame:StageGround > 0).
        Frames(300).
        Assert:Equals(STRING(XeviousPhase:Playing), STRING(mGame:Phase)).
        Assert:Equals(2, mGame:Stage).
        Assert:Equals(0, mGame:Distance).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBonusIsThirtyPointsForEveryPercentOfTheGroundTargetsDestroyed():
        mGame:StartGame().
        mGame:StopWaves().
        Frames(1500).
        mGame:ClearGround().
        Frames(1500).
        Assert:Equals(STRING(XeviousPhase:StageClear), STRING(mGame:Phase)).
        Assert:Equals(mGame:StagePercent * 30, mGame:StageBonus).
        Assert:Equals(mGame:StageBonus, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BeginningAStageStartsItsLandAndClearsTheField():
        Scene().
        mGame:SpawnAir(XeviousAir:Toroid, 20, 20).
        mGame:BeginStage(7).
        Assert:Equals(7, mGame:Stage).
        Assert:Equals(0, mGame:Distance).
        Assert:Equals(0, mGame:AirCount).
        Assert:IsTrue(mGame:GroundCount > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStageUnderOneIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:BeginStage(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    /* ---- the mothership ---- */

    @Test.
    METHOD PUBLIC VOID EveryFourthStageBringsTheMothershipAtTheEnd():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Scene().
        mGame:BeginStage(4).
        mGame:StopWaves().
        DO i = 1 TO 4000:
            mGame:Advance().
            mGame:ClearBullets().
            mGame:ClearAir().
            IF mGame:BossActive THEN LEAVE.
        END.
        Assert:IsTrue(mGame:BossActive).
        Assert:Equals(STRING(XeviousPhase:Playing), STRING(mGame:Phase)).
        Assert:Equals(3, mGame:BossHpLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMothershipComesDownTheFieldAndTurnsShotsAway():
        Scene().
        mGame:SpawnBoss().
        Assert:IsTrue(mGame:BossActive).
        Assert:Equals(-32, mGame:BossY).
        Frames(60).
        Assert:IsTrue(mGame:BossY > -32).
        Assert:Equals(60, mGame:BossAge).
        mGame:ClearBoss().
        Assert:IsFalse(mGame:BossActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombOnTheCoreHurtsTheMothershipAndThreeDestroyItForFourThousand():
        DEFINE VARIABLE targetX AS INTEGER NO-UNDO.
        DEFINE VARIABLE hits    AS INTEGER NO-UNDO.
        Scene().
        mGame:SpawnBoss().
        Frames(180).
        DO WHILE mGame:BossActive AND hits < 3:
            mGame:ClearBullets().
            mGame:BombHeld = FALSE.
            targetX = 96 + XeviousMotion:Wave(mGame:BossAge + 27, 240, 70) + 16.
            mGame:PlacePlayer(targetX - 8, 135).
            mGame:BombHeld = TRUE.
            mGame:Advance().
            mGame:BombHeld = FALSE.
            Frames(27).
            hits = mGame:BossHits.
            IF mGame:Phase <> XeviousPhase:Playing THEN LEAVE.
            Frames(15).
        END.
        Assert:Equals(3, mGame:BossHits).
        Assert:IsFalse(mGame:BossActive).
        Assert:Equals(1, mGame:BossKills).
        Assert:IsTrue(mGame:Score >= 4000).
        Assert:IsTrue(HasFx(XeviousFx:BossBlast)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShotsDoNotHurtTheMothership():
        Scene().
        mGame:SpawnBoss().
        Frames(190).
        mGame:ClearBullets().
        mGame:PlacePlayer(mGame:BossX + 8, 140).
        mGame:ZapHeld = TRUE.
        Frames(20).
        Assert:IsTrue(mGame:Clangs > 0).
        Assert:Equals(3, mGame:BossHpLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSlotCountsAndTheStageAgeAreWhatTheFieldHoldsAndTheFramesSinceItBegan():
        Scene().
        Assert:Equals(24, mGame:AirSlots).
        Assert:Equals(28, mGame:GroundSlots).
        Assert:Equals(24, mGame:BulletSlots).
        Assert:Equals(24, mGame:FxSlots).
        mGame:BeginStage(2).
        Assert:Equals(0, mGame:StageAge).
        Frames(10).
        Assert:Equals(10, mGame:StageAge).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBurstKnowsItsAgeAndItsPlaceAndATankItsWay():
        Scene().
        mGame:PlaceGround(XeviousGround:Grobda, 100, 20).
        Assert:Equals(1, mGame:GroundWay(0)).
        mGame:BombHeld = TRUE.
        Frames(27).
        mGame:BombHeld = FALSE.
        Assert:IsTrue(mGame:BurstActive).
        Assert:Equals(1, mGame:BurstAge).
        Assert:Equals(112, mGame:BurstX).
        Assert:IsTrue(mGame:BurstY > 100).
    END METHOD.

END CLASS.