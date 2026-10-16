/* The Blast Buddies game: its starting position, its phases and clocks, the turn order, the wind, and the winner or a draw. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BlastBuddiesGameTests:

    DEFINE PRIVATE VARIABLE mGame AS BlastBuddiesGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID Setup():
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID TearDown():
        mGame:Dispose().
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* runs to the start of the firstOne turn */
    METHOD PRIVATE VOID ToTheFirstTurn():
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameStartsInTheArrivalWithTheTeamsAndBuddiesOfTheSetup():
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        Assert:Equals("Blast Buddies", mGame:Name).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Arrival).
        Assert:IsFalse(mGame:IsOver).
        Assert:IsFalse(mGame:Paused).
        Assert:Equals(2, mGame:Plan:TeamCount()).
        Assert:IsFalse(mGame:Plan:TeamAt(1):IsComputer).
        Assert:IsTrue(mGame:Plan:TeamAt(2):IsComputer).
        DO t = 1 TO 2:
            Assert:Equals(3, mGame:Plan:TeamAt(t):Count()).
            DO b = 1 TO 3:
                Assert:Equals(t, mGame:Plan:TeamAt(t):BuddyAt(b):Team).
                Assert:IsTrue(mGame:Land:IsSolid(mGame:Plan:TeamAt(t):BuddyAt(b):X(), mGame:Plan:TeamAt(t):BuddyAt(b):Y())).
                Assert:IsTrue(mGame:Plan:TeamAt(t):BuddyAt(b):State = BuddyState:Standing).
            END.
        END.
        Assert:IsTrue(mGame:CurrentBuddy = ?).
        Assert:Equals(0, mGame:WinnerTeam).
        Assert:Equals(0, mGame:FrameCount).
        Assert:IsTrue(mGame:Setup:Teams = 2).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BuddiesHaveDifferentNamesAndFaceTowardsTheMiddle():
        DEFINE VARIABLE a AS Buddy NO-UNDO.
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DO i = 1 TO 6:
            a = mGame:Plan:TeamAt((i MODULO 2) + 1):BuddyAt(INTEGER(TRUNCATE((i - 1) / 2, 0)) + 1).
            Assert:Equals(IF a:X() < 192 THEN 1 ELSE -1, a:Facing).
            DO j = i + 1 TO 6:
                b = mGame:Plan:TeamAt((j MODULO 2) + 1):BuddyAt(INTEGER(TRUNCATE((j - 1) / 2, 0)) + 1).
                Assert:IsTrue(a:BuddyName <> b:BuddyName).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameNeedsAGridOfTheRightSizeARandomSourceAndASetup():
        DEFINE VARIABLE g       AS BlastBuddiesGame NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL          NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            g = NEW BlastBuddiesGame(NEW Grid(NEW ArrayStore(100, 100, "view,kind,back")), NEW SeededRandom(1), BuddySetup:Default()).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            g = NEW BlastBuddiesGame(BlastBuddiesFactory:CreateGrid(), ?, BuddySetup:Default()).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            g = NEW BlastBuddiesGame(BlastBuddiesFactory:CreateGrid(), NEW SeededRandom(1), ?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFactoryMakesAGridOfThreeLayers():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        g = BlastBuddiesFactory:CreateGrid().
        Assert:Equals(384, g:Width).
        Assert:Equals(240, g:Height).
        Assert:Equals("view,kind,back", BlastBuddiesFactory:Layers()).
        g:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheArrivalLastsFiveSecondsThenTheBannerShowsTheFirstBuddyAndTheWind():
        Frames(BuddyRules:ArrivalFrames() - 1).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Arrival).
        Assert:Equals(16, mGame:TimeLeftMs).
        Frames(1).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Banner).
        Assert:Equals(1, mGame:CurrentBuddy:Team).
        Assert:IsTrue(mGame:Wind >= -10 AND mGame:Wind <= 10).
        Assert:Equals(1, mGame:Generation).
        Assert:Equals(1500, mGame:TimeLeftMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBannerGivesWayToATurnOfFortyFiveSeconds():
        ToTheFirstTurn().
        Assert:IsTrue(mGame:Phase = BuddyPhase:Turn).
        Assert:Equals(45000, mGame:TimeLeftMs).
        Frames(60).
        Assert:Equals(44000, mGame:TimeLeftMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheTurnClockRunsOutTheGameResolvesThenTheNextTeamHasTheNextBanner():
        DEFINE VARIABLE firstOne AS Buddy NO-UNDO.
        ToTheFirstTurn().
        firstOne = mGame:CurrentBuddy.
        Frames(BuddyRules:TurnFrames()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Resolve).
        Frames(BuddyRules:SettleFrames()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Banner).
        Assert:Equals(2, mGame:CurrentBuddy:Team).
        Assert:Equals(2, mGame:Generation).
        Frames(BuddyRules:BannerFrames()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Turn).
        Frames(BuddyRules:TurnFrames() + BuddyRules:SettleFrames()).
        Assert:Equals(1, mGame:CurrentBuddy:Team).
        Assert:IsTrue(mGame:CurrentBuddy <> firstOne).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EndTurnWorksOnlyInATurnOrARetreat():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mGame:EndTurn().
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        ToTheFirstTurn().
        mGame:EndTurn().
        Assert:IsTrue(mGame:Phase = BuddyPhase:Resolve).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARetreatLastsThreeSecondsThenResolves():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mGame:BeginRetreat().
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        ToTheFirstTurn().
        mGame:BeginRetreat().
        Assert:IsTrue(mGame:Phase = BuddyPhase:Retreat).
        Assert:Equals(3000, mGame:TimeLeftMs).
        Frames(179).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Retreat).
        Frames(1).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Resolve).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ResolveWaitsWhileAnyBuddyIsInTheAir():
        ToTheFirstTurn().
        mGame:EndTurn().
        mGame:Plan:TeamAt(2):BuddyAt(1):State = BuddyState:Airborne.
        mGame:Land:FillRect(0, 0, 383, 239, FALSE).
        Frames(10).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Resolve).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BuddiesFallWhateverThePhase():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        b = mGame:Plan:TeamAt(1):BuddyAt(1).
        mGame:Land:FillRect(b:X() - 8, b:Y(), b:X() + 8, b:Y() + 30, FALSE).
        Frames(1).
        Assert:IsTrue(b:State = BuddyState:Airborne).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TickMakesFramesFromTheTimeItIsGivenAtMostFourAtATime():
        Assert:IsFalse(mGame:Tick(0)).
        Assert:IsFalse(mGame:Tick(5)).
        Assert:Equals(0, mGame:FrameCount).
        Assert:IsTrue(mGame:Tick(17)).
        Assert:Equals(1, mGame:FrameCount).
        Assert:IsTrue(mGame:Tick(1000)).
        Assert:Equals(5, mGame:FrameCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpeedPercentChangesHowManyFramesTimeMakes():
        mGame:SpeedPercent = 50.
        mGame:Tick(100).
        Assert:Equals(3, mGame:FrameCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedGameIgnoresTheClockAndAdvance():
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:Tick(100)).
        mGame:Advance().
        Assert:Equals(0, mGame:FrameCount).
        mGame:Paused = FALSE.
        mGame:Advance().
        Assert:Equals(1, mGame:FrameCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameSeedGivesTheSameWindAndFirstBuddy():
        DEFINE VARIABLE other AS BlastBuddiesGame NO-UNDO.
        other = BlastBuddiesFactory:Create(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow)).
        ToTheFirstTurn().
        Frames(0).
        other:Tick(0).
        DO WHILE other:FrameCount < BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames():
            other:Advance().
        END.
        Assert:Equals(mGame:Wind, other:Wind).
        Assert:Equals(mGame:CurrentBuddy:BuddyName, other:CurrentBuddy:BuddyName).
        Assert:Equals(mGame:CurrentBuddy:X(), other:CurrentBuddy:X()).
        other:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenOnlyOneTeamHasBuddiesLeftItWins():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ToTheFirstTurn().
        DO i = 1 TO 3:
            mGame:Plan:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        mGame:EndTurn().
        Frames(BuddyRules:SettleFrames()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Winner).
        Assert:Equals(1, mGame:WinnerTeam).
        Assert:IsTrue(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenEveryoneIsGoneItIsADraw():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ToTheFirstTurn().
        DO i = 1 TO 3:
            mGame:Plan:TeamAt(1):BuddyAt(i):Hurt(100).
            mGame:Plan:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        mGame:EndTurn().
        Frames(BuddyRules:SettleFrames()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Draw).
        Assert:Equals(0, mGame:WinnerTeam).
        Assert:IsTrue(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseStartsAFreshGameFromAnyPhase():
        ToTheFirstTurn().
        mGame:Plan:TeamAt(1):BuddyAt(1):Hurt(100).
        mGame:Initialise().
        Assert:IsTrue(mGame:Phase = BuddyPhase:Arrival).
        Assert:Equals(0, mGame:FrameCount).
        Assert:Equals(0, mGame:Generation).
        Assert:Equals(100, mGame:Plan:TeamAt(1):BuddyAt(1):Health).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    /* flat open ground 40 pixels either side of the buddy in turn, with clear air over it, so walking is not stopped by the random land */
    METHOD PRIVATE VOID Flatten(INPUT poBuddy AS Buddy):
        mGame:Land:FillRect(poBuddy:X() - 40, poBuddy:Y() - 30, poBuddy:X() + 40, poBuddy:Y() - 1, FALSE).
        mGame:Land:FillRect(poBuddy:X() - 40, poBuddy:Y(), poBuddy:X() + 40, poBuddy:Y() + 20, TRUE).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeldWalkMovesTheBuddyInTurnOnePixelEveryFortyMilliseconds():
        DEFINE VARIABLE x0 AS INTEGER NO-UNDO.
        ToTheFirstTurn().
        Flatten(mGame:CurrentBuddy).
        x0 = mGame:CurrentBuddy:X().
        mGame:SetWalk(1).
        Frames(12).
        Assert:Equals(x0 + 5, mGame:CurrentBuddy:X()).
        Assert:Equals(1, mGame:CurrentBuddy:Facing).
        mGame:SetWalk(-1).
        Frames(12).
        Assert:Equals(x0, mGame:CurrentBuddy:X()).
        Assert:Equals(-1, mGame:CurrentBuddy:Facing).
        mGame:SetWalk(0).
        Frames(12).
        Assert:Equals(x0, mGame:CurrentBuddy:X()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingStillWorksInTheRetreat():
        DEFINE VARIABLE x0 AS INTEGER NO-UNDO.
        ToTheFirstTurn().
        Flatten(mGame:CurrentBuddy).
        x0 = mGame:CurrentBuddy:X().
        mGame:BeginRetreat().
        mGame:SetWalk(1).
        Frames(12).
        Assert:Equals(x0 + 5, mGame:CurrentBuddy:X()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NobodyWalksInTheBannerOrAfterTheTurnHasChanged():
        DEFINE VARIABLE b  AS Buddy   NO-UNDO.
        DEFINE VARIABLE x0 AS INTEGER NO-UNDO.
        Frames(BuddyRules:ArrivalFrames()).
        b = mGame:CurrentBuddy.
        Flatten(b).
        x0 = b:X().
        mGame:SetWalk(1).
        Frames(12).
        Assert:Equals(x0, b:X()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Banner).
        Frames(BuddyRules:BannerFrames()).
        Assert:Equals(0, mGame:WalkDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWalkDirectionIsMinusOneZeroOrOne():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mGame:SetWalk(2).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mGame:SetAim(-2).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheAimMovesOneStepEveryThreeFramesAndStopsAtStraightUpAndStraightDown():
        ToTheFirstTurn().
        Assert:Equals(12, mGame:Aim).
        mGame:SetAim(-1).
        Frames(3).
        Assert:Equals(11, mGame:Aim).
        Frames(300).
        Assert:Equals(0, mGame:Aim).
        mGame:SetAim(1).
        Frames(300).
        Assert:Equals(32, mGame:Aim).
        mGame:SetAim(0).
        Frames(30).
        Assert:Equals(32, mGame:Aim).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheAimHeadingFollowsTheWayTheBuddyFaces():
        ToTheFirstTurn().
        mGame:CurrentBuddy:Facing = 1.
        Assert:Equals(12, mGame:AimHeading).
        mGame:CurrentBuddy:Facing = -1.
        Assert:Equals(52, mGame:AimHeading).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoldingFireBuildsPowerAndLettingGoFiresAndStartsTheRetreat():
        ToTheFirstTurn().
        mGame:StartCharge().
        Assert:IsTrue(mGame:Charging).
        Frames(45).
        Assert:Equals(50, mGame:PowerPercent).
        mGame:ReleaseCharge().
        Assert:Equals(1, mGame:ShotsFired).
        Assert:Equals(50, mGame:LastPower).
        Assert:IsFalse(mGame:Charging).
        Assert:Equals(0, mGame:PowerPercent).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Retreat).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FullPowerFiresByItself():
        ToTheFirstTurn().
        mGame:StartCharge().
        Frames(BuddyRules:ChargeFrames()).
        Assert:Equals(1, mGame:ShotsFired).
        Assert:Equals(100, mGame:LastPower).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Retreat).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoChargingOutsideATurnOrWhilePausedAndNoShotWithoutACharge():
        mGame:StartCharge().
        Assert:IsFalse(mGame:Charging).
        ToTheFirstTurn().
        mGame:ReleaseCharge().
        Assert:Equals(0, mGame:ShotsFired).
        mGame:Paused = TRUE.
        mGame:StartCharge().
        Assert:IsFalse(mGame:Charging).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHopLeavesTheGroundAndASecondJumpWithinAQuarterOfASecondIsABackflip():
        ToTheFirstTurn().
        Flatten(mGame:CurrentBuddy).
        mGame:CurrentBuddy:Facing = 1.
        mGame:Jump().
        Assert:IsTrue(mGame:CurrentBuddy:State = BuddyState:Airborne).
        Assert:IsTrue(mGame:CurrentBuddy:VX > 0).
        Frames(5).
        mGame:Jump().
        Assert:IsTrue(mGame:CurrentBuddy:VX < 0).
        Assert:IsTrue(mGame:CurrentBuddy:VY < 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASecondJumpLaterThanAQuarterOfASecondDoesNothing():
        ToTheFirstTurn().
        Flatten(mGame:CurrentBuddy).
        mGame:CurrentBuddy:Facing = 1.
        mGame:Jump().
        Frames(16).
        mGame:Jump().
        Assert:IsTrue(mGame:CurrentBuddy:VX > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheComputersTurnIsNotAHumanTurnAndTheNextTurnResetsTheAim():
        ToTheFirstTurn().
        Assert:IsTrue(mGame:HumanTurn).
        mGame:SetAim(1).
        Frames(30).
        mGame:SetAim(0).
        Assert:Equals(22, mGame:Aim).
        mGame:EndTurn().
        Frames(BuddyRules:SettleFrames()).
        Assert:Equals(12, mGame:Aim).
        Frames(BuddyRules:BannerFrames()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Turn).
        Assert:IsFalse(mGame:HumanTurn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnIdleHumanTurnIsNotHumanInTheBanner():
        Frames(BuddyRules:ArrivalFrames()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Banner).
        Assert:IsFalse(mGame:HumanTurn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNewAimPropertiesStartAtTheirDefaults():
        Assert:Equals(12, mGame:Aim).
        Assert:Equals(0, mGame:AimHeading).
        Assert:Equals(0, mGame:AimDirection).
        Assert:Equals(0, mGame:WalkDirection).
        Assert:Equals(0, mGame:Charge).
        Assert:IsFalse(mGame:Charging).
    END METHOD.

    /* the first turn, with the shooter on flat open ground facing right and aiming level, ready to charge */
    METHOD PRIVATE VOID ReadyToShoot():
        ToTheFirstTurn().
        mGame:CurrentBuddy:Facing = 1.
        Flatten(mGame:CurrentBuddy).
        mGame:SetAim(1).
        Frames(12).
        mGame:SetAim(0).
        Assert:Equals(16, mGame:Aim).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARocketLeavesTheMuzzleAtASpeedByThePowerAndFliesUnderGravityAndWind():
        DEFINE VARIABLE x0 AS INTEGER NO-UNDO.
        DEFINE VARIABLE y0 AS INTEGER NO-UNDO.
        ReadyToShoot().
        x0 = mGame:CurrentBuddy:X256 + 1536.
        y0 = mGame:CurrentBuddy:Y256 - 1536.
        mGame:StartCharge().
        Frames(30).
        mGame:ReleaseCharge().
        Assert:Equals(1, mGame:Shells:Count()).
        Assert:Equals(x0, mGame:Shells:X(1)).
        Assert:Equals(y0, mGame:Shells:Y(1)).
        Assert:Equals(592, mGame:Shells:VX(1)).
        Assert:Equals(0, mGame:Shells:VY(1)).
        Assert:Equals(1, mGame:Shells:Team(1)).
        Frames(1).
        Assert:Equals(x0 + 592 + mGame:Wind, mGame:Shells:X(1)).
        Assert:Equals(y0 + 38, mGame:Shells:Y(1)).
        Assert:Equals(592 + mGame:Wind, mGame:Shells:VX(1)).
        Assert:Equals(38, mGame:Shells:VY(1)).
        Assert:Equals(1, mGame:Shells:Age(1)).
        Frames(1).
        Assert:Equals(y0 + 38 + 76, mGame:Shells:Y(1)).
        Assert:Equals(592 + 2 * mGame:Wind, mGame:Shells:VX(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MorePowerIsAFasterRocketAndNoPowerIsAHalfPixelAFrame():
        ReadyToShoot().
        mGame:StartCharge().
        mGame:ReleaseCharge().
        Assert:Equals(128, mGame:Shells:VX(1)).
        mGame:Shells:Clear().
        mGame:Initialise().
        ReadyToShoot().
        mGame:StartCharge().
        Frames(89).
        mGame:ReleaseCharge().
        Assert:Equals(1, mGame:ShotsFired).
        Assert:Equals(1507, mGame:Shells:VX(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARocketAimedStraightUpGoesUpAndTheOneFacingLeftGoesLeft():
        ReadyToShoot().
        mGame:SetAim(-1).
        Frames(48).
        mGame:SetAim(0).
        Assert:Equals(0, mGame:Aim).
        mGame:StartCharge().
        Frames(30).
        mGame:ReleaseCharge().
        Assert:Equals(0, mGame:Shells:VX(1)).
        Assert:Equals(-592, mGame:Shells:VY(1)).
        mGame:Shells:Clear().
        mGame:Initialise().
        ToTheFirstTurn().
        mGame:CurrentBuddy:Facing = -1.
        Flatten(mGame:CurrentBuddy).
        mGame:SetAim(1).
        Frames(12).
        mGame:SetAim(0).
        mGame:StartCharge().
        Frames(30).
        mGame:ReleaseCharge().
        Assert:Equals(-592, mGame:Shells:VX(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARocketThatHitsAWallBlowsAHoleInItAndIsGone():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        ReadyToShoot().
        x = mGame:CurrentBuddy:X().
        y = mGame:CurrentBuddy:Y().
        mGame:Land:FillRect(x + 30, y - 40, x + 40, y + 5, TRUE).
        mGame:StartCharge().
        Frames(45).
        mGame:ReleaseCharge().
        Frames(40).
        Assert:Equals(0, mGame:Shells:Count()).
        Assert:Equals(1, mGame:BlastCount).
        Assert:Equals(20, mGame:LastBlastRadius).
        Assert:IsTrue(mGame:LastBlastX >= x + 28 AND mGame:LastBlastX <= x + 34, "blast at " + STRING(mGame:LastBlastX)).
        Assert:IsTrue(mGame:LastBlastY >= y - 12 AND mGame:LastBlastY <= y, "blast at row " + STRING(mGame:LastBlastY)).
        Assert:IsFalse(mGame:Land:IsSolid(x + 32, y - 5)).
        Assert:IsTrue(mGame:Land:HasDirty()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARocketThatHitsABuddyHurtsAndThrowsIt():
        DEFINE VARIABLE enemy AS Buddy NO-UNDO.
        ReadyToShoot().
        enemy = mGame:Plan:TeamAt(2):BuddyAt(1).
        enemy:PlaceAt(mGame:CurrentBuddy:X() + 36, mGame:CurrentBuddy:Y()).
        mGame:StartCharge().
        Frames(45).
        mGame:ReleaseCharge().
        Frames(20).
        Assert:Equals(1, mGame:BlastCount).
        Assert:IsTrue(enemy:Health < 100, "health " + STRING(enemy:Health)).
        Assert:IsTrue(mGame:LastBlast:HitCount() >= 1).
        Assert:Equals(100, mGame:CurrentBuddy:Health).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShellInTheWaterIsGoneWithASplashAndNoBlast():
        mGame:Land:FillRect(90, 200, 110, 239, FALSE).
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 100 * 256, 224 * 256, 0, 1024).
        Frames(1).
        Assert:Equals(0, mGame:Shells:Count()).
        Assert:Equals(1, mGame:WaterHits).
        Assert:Equals(0, mGame:BlastCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShellThatLeavesThroughTheSidesIsGone():
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 2 * 256, 50 * 256, -1024, 0).
        Frames(1).
        Assert:Equals(0, mGame:Shells:Count()).
        Assert:Equals(0, mGame:BlastCount).
        Assert:Equals(0, mGame:WaterHits).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShellAboveTheTopOfTheMapComesBackDown():
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 50 * 256, 5 * 256, 0, -3000).
        Frames(10).
        Assert:Equals(1, mGame:Shells:Count()).
        Assert:IsTrue(mGame:Shells:Y(1) < 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameDoesNotSettleWhileAShellIsStillFlying():
        ToTheFirstTurn().
        mGame:EndTurn().
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 50 * 256, 5 * 256, 0, -3000).
        Frames(BuddyRules:SettleFrames() + 20).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Resolve).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameClearsTheShellsAndTheBlastCounts():
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 50 * 256, 5 * 256, 0, -3000).
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 60 * 256, 50 * 256, 0, 0).
        mGame:Initialise().
        Assert:Equals(0, mGame:Shells:Count()).
        Assert:Equals(0, mGame:BlastCount).
        Assert:Equals(0, mGame:WaterHits).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThreeTeamsOfFourMakeTwelveBuddiesWithTheLastOnesPlayedByTheComputer():
        DEFINE VARIABLE g AS BlastBuddiesGame NO-UNDO.
        g = BlastBuddiesFactory:Create(NEW SeededRandom(9), NEW BuddySetup(3, 4, 2, Theme:Canyon)).
        Assert:Equals(3, g:Plan:TeamCount()).
        Assert:Equals(4, g:Plan:TeamAt(3):Count()).
        Assert:IsFalse(g:Plan:TeamAt(1):IsComputer).
        Assert:IsTrue(g:Plan:TeamAt(2):IsComputer).
        Assert:IsTrue(g:Plan:TeamAt(3):IsComputer).
        Assert:IsTrue(g:Land:MapTheme = Theme:Canyon).
        g:Dispose().
    END METHOD.

END CLASS.
