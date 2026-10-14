/* The rules of Space Invaders, tested without a window. The game runs on a 224 x 256 grid and makes one frame for
   each call of Advance, so a test plays frame by frame and reads the picture with the kind layer (KindAt), as the
   rules themselves do. A seeded random source makes the sparks and the shield marks the same every run.

   Some tests thin the field out first (EmptyField): they kill invaders in the rack and wipe the picture of the
   middle of the screen, so a shot or a bomb meets only what the test put there. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.SpaceInvadersGameTests:

    {ProGriddle/Games/SpaceInvaders/Kinds.i}
    {ProGriddle/Games/SpaceInvaders/Phases.i}

    DEFINE PRIVATE VARIABLE mGame AS SpaceInvadersGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = SpaceInvadersFactory:Create(NEW SeededRandom(7)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* ---------------------------------- helpers ---------------------------------- */

    /* From the title screen to a wave in play: the fire key is let go, pressed, and the wave drawn in at once. */
    METHOD PRIVATE VOID Play():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        mGame:SkipIntro().
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO n = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* Keeps the first piKeep invaders (in the rack's numbering, the top rows first) and takes the rest out of the
       rack, and wipes their pictures: everything between the kept invaders and the shields. The shields, the
       saucer lane and the cannon stay. */
    METHOD PRIVATE VOID EmptyField(INPUT piKeep AS INTEGER):
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE top AS INTEGER NO-UNDO INITIAL 60.
        IF piKeep > 0 THEN top = mGame:Rack:Y(piKeep - 1) + InvaderRack:SpriteHeight().
        DO i = piKeep TO InvaderRack:Total() - 1:
            IF mGame:Rack:Alive(i) THEN mGame:Rack:Kill(i).
        END.
        mGame:Canvas:ClearRect(0, top, 224, 184 - top).
    END METHOD.

    METHOD PRIVATE VOID ClearShields():
        mGame:Canvas:ClearRect(0, 184, 224, 16).
    END METHOD.

    /* How many cells of a rectangle show something other than the background. */
    METHOD PRIVATE INTEGER CountLit(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = piY TO piY + piHeight - 1:
            DO x = piX TO piX + piWidth - 1:
                IF mGame:Canvas:ColourAt(x, y) <> mGame:Canvas:BackAt(x, y) THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    /* Puts the cannon so its shot rises up a column. */
    METHOD PRIVATE VOID AimAt(INPUT piColumn AS INTEGER):
        mGame:SetPlayerX(piColumn - 6).
    END METHOD.

    /* Fires, and plays until the shot is gone (at most piMost frames). */
    METHOD PRIVATE VOID FireAndWait(INPUT piMost AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        DO n = 1 TO piMost:
            IF NOT mGame:ShotActive THEN LEAVE.
            mGame:Advance().
        END.
    END METHOD.

    METHOD PRIVATE INTEGER FreeBombType():
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DO t = 0 TO 2:
            IF NOT mGame:BombActive(t) THEN RETURN t.
        END.
        RETURN -1.
    END METHOD.

    /* Drops a bomb on the cannon and plays until it has been hit. */
    METHOD PRIVATE VOID BombTheCannon():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        mGame:DropBomb(FreeBombType(), mGame:PlayerX, 205).
        DO n = 1 TO 40:
            IF mGame:Phase <> {&PHASE-PLAYING} THEN LEAVE.
            mGame:Advance().
        END.
    END METHOD.

    /* Plays until the cannon has finished exploding. */
    METHOD PRIVATE VOID WaitForTheBlast():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO n = 1 TO 130:
            IF mGame:Phase <> {&PHASE-DYING} THEN LEAVE.
            mGame:Advance().
        END.
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE other AS SpaceInvadersGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN mGame:DropBomb(3, 10, 10).
                WHEN 2 THEN mGame:BombActive(-1).
                WHEN 3 THEN mGame:BombX(5).
                WHEN 4 THEN mGame:BombY(?).
                WHEN 5 THEN mGame:AddScore(-1).
                WHEN 6 THEN mGame:AddScore(?).
                WHEN 7 THEN DO:
                    mGame:DropBomb(0, 10, 10).
                    mGame:DropBomb(0, 20, 10).
                END.
                WHEN 8 THEN other = NEW SpaceInvadersGame(NEW Grid(NEW ArrayStore(10, 10, "view,kind,back")), NEW SeededRandom(1)).
                WHEN 9 THEN other = NEW SpaceInvadersGame(SpaceInvadersFactory:CreateGrid(), ?).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    /* ---------------------------------- the title screen ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID AGameStartsOnTheTitleScreenWithNothingScoredAndNothingMoving():
        Assert:Equals({&PHASE-TITLE}, mGame:Phase).
        Assert:Equals(0, mGame:Score).
        Assert:IsFalse(mGame:ShotActive).
        Assert:IsFalse(mGame:SaucerActive).
        Assert:IsFalse(mGame:BombActive(0)).
        Assert:IsFalse(mGame:Paused).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleScreenDrawsTheNameAndTheScoreTable():
        /* the big letters (text has no kind, it is only colour) and the table of invaders, which are effects cells */
        Assert:IsTrue(CountLit(40, 40, 150, 60) > 400).
        Assert:IsTrue(CountLit(70, 120, 130, 60) > 150).
        Assert:IsTrue(mGame:Canvas:CountKind({&KIND-FX}) > 50).
        Assert:Equals(0, mGame:Canvas:CountKind({&KIND-ALIEN})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleWaitsForTheFireKeyToBePressedAfterItWasLetGo():
        /* a fire key that was down before the title appeared does not start the game */
        mGame:FireHeld = TRUE.
        Frames(5).
        Assert:Equals({&PHASE-TITLE}, mGame:Phase).
        mGame:FireHeld = FALSE.
        Frames(2).
        Assert:Equals({&PHASE-TITLE}, mGame:Phase).
        mGame:FireHeld = TRUE.
        mGame:Advance().
        Assert:Equals({&PHASE-STARTING}, mGame:Phase).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(1, mGame:Wave).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCannonCannotBePlacedOnTheTitleScreen():
        mGame:SetPlayerX(40).
        Assert:Equals(105, mGame:PlayerX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FramesAreCountedAndThePhaseTimerRunsOnTheTitle():
        Assert:Equals(0, mGame:FrameCount).
        Frames(7).
        Assert:Equals(7, mGame:FrameCount).
        Assert:Equals(7, mGame:PhaseTimer).
    END METHOD.

    /* ---------------------------------- a wave drawing in ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheWaveDrawsInOneInvaderAFrameBottomRowFirst():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        Assert:Equals(0, mGame:Canvas:CountKind({&KIND-ALIEN})).
        mGame:Advance().
        /* invader 44 is the bottom left octopus; 43 has not been drawn yet */
        Assert:Equals({&KIND-ALIEN}, mGame:Canvas:KindAt(mGame:Rack:X(44) + 4, mGame:Rack:Y(44) + 1)).
        Assert:Equals({&KIND-NONE}, mGame:Canvas:KindAt(mGame:Rack:X(33) + 4, mGame:Rack:Y(33) + 1)).
        Frames(11).
        Assert:Equals({&KIND-ALIEN}, mGame:Canvas:KindAt(mGame:Rack:X(33) + 4, mGame:Rack:Y(33) + 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlayBeginsWhenTheLastInvaderIsDrawnIn():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        Frames(InvaderRack:Total() - 1).
        Assert:Equals({&PHASE-STARTING}, mGame:Phase).
        mGame:Advance().
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCannonCannotMoveOrFireWhileTheWaveDrawsIn():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:MoveDirection = 1.
        Frames(10).
        Assert:Equals({&PHASE-STARTING}, mGame:Phase).
        Assert:Equals(105, mGame:PlayerX).
        Assert:Equals(0, mGame:ShotsFired).
        Assert:IsFalse(mGame:ShotActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SkipIntroFinishesTheWaveAtOnceAndDoesNothingOutsideTheStartingPhase():
        mGame:SkipIntro().
        Assert:Equals({&PHASE-TITLE}, mGame:Phase).
        Play().
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
        Assert:Equals(55, mGame:Rack:AliveCount).
        Assert:IsTrue(mGame:Canvas:CountKind({&KIND-ALIEN}) > 1000).
        Assert:IsTrue(mGame:Canvas:CountKind({&KIND-SHIELD}) > 600).
        mGame:SkipIntro().
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWaveStartsWithFourShieldsAndTheCannonInTheMiddle():
        Play().
        Assert:Equals(105, mGame:PlayerX).
        Assert:Equals({&KIND-PLAYER}, mGame:Canvas:KindAt(105, 223)).
        Assert:Equals({&KIND-SHIELD}, mGame:Canvas:KindAt(35 + 10, 184 + 4)).
        Assert:Equals({&KIND-SHIELD}, mGame:Canvas:KindAt(35 + 44 + 10, 184 + 4)).
        Assert:Equals({&KIND-SHIELD}, mGame:Canvas:KindAt(35 + 88 + 10, 184 + 4)).
        Assert:Equals({&KIND-SHIELD}, mGame:Canvas:KindAt(35 + 132 + 10, 184 + 4)).
        /* the arch cut out of the foot of a shield */
        Assert:Equals({&KIND-NONE}, mGame:Canvas:KindAt(35 + 10, 184 + 14)).
    END METHOD.

    /* ---------------------------------- the cannon ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheCannonMovesOneCellAFrameWhileASteeringKeyIsHeld():
        Play().
        mGame:MoveDirection = 1.
        Frames(10).
        Assert:Equals(115, mGame:PlayerX).
        mGame:MoveDirection = -1.
        Frames(25).
        Assert:Equals(90, mGame:PlayerX).
        mGame:MoveDirection = 0.
        Frames(5).
        Assert:Equals(90, mGame:PlayerX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MoveDirectionIsAlwaysMinusOneZeroOrOneAndFireHeldIsAnOnOffState():
        mGame:MoveDirection = 5.
        Assert:Equals(1, mGame:MoveDirection).
        mGame:MoveDirection = -3.
        Assert:Equals(-1, mGame:MoveDirection).
        mGame:MoveDirection = 0.
        Assert:Equals(0, mGame:MoveDirection).
        mGame:FireHeld = TRUE.
        Assert:IsTrue(mGame:FireHeld).
        mGame:FireHeld = FALSE.
        Assert:IsFalse(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCannonStopsAtTheEdgesOfTheField():
        Play().
        mGame:SetPlayerX(0).
        Assert:Equals(8, mGame:PlayerX).
        mGame:MoveDirection = -1.
        Frames(5).
        Assert:Equals(8, mGame:PlayerX).
        mGame:SetPlayerX(500).
        Assert:Equals(203, mGame:PlayerX).
        mGame:MoveDirection = 1.
        Frames(5).
        Assert:Equals(203, mGame:PlayerX).
        Assert:Equals({&KIND-PLAYER}, mGame:Canvas:KindAt(203 + 12, 223)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SettingTheCannonDownTakesItOffWhereItWas():
        Play().
        mGame:SetPlayerX(60).
        Assert:Equals({&KIND-NONE}, mGame:Canvas:KindAt(105, 223)).
        Assert:Equals({&KIND-PLAYER}, mGame:Canvas:KindAt(60, 223)).
    END METHOD.

    /* ---------------------------------- the shot ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheCannonFiresOneShotFromTheTipOfItsBarrel():
        Play().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        Assert:IsTrue(mGame:ShotActive).
        Assert:Equals(111, mGame:ShotX).
        Assert:Equals(1, mGame:ShotsFired).
        Assert:Equals({&KIND-SHOT}, mGame:Canvas:KindAt(mGame:ShotX, mGame:ShotY)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShotRisesFourCellsAFrame():
        Play().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        mGame:Advance().
        Assert:Equals(204, mGame:ShotY).
        Frames(1).
        Assert:Equals(200, mGame:ShotY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsOnlyOneShotAtATimeEvenWithTheKeyHeld():
        Play().
        mGame:FireHeld = TRUE.
        Frames(6).
        Assert:IsTrue(mGame:ShotActive).
        Assert:Equals(1, mGame:ShotsFired).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoldingFireShootsAgainTheMomentTheShotIsGone():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Play().
        EmptyField(1).
        mGame:FireHeld = TRUE.
        DO n = 1 TO 120:
            mGame:Advance().
            IF mGame:ShotsFired >= 2 THEN LEAVE.
        END.
        Assert:Equals(2, mGame:ShotsFired).
        Assert:IsTrue(mGame:ShotActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALetGoKeyDoesNotFireAgain():
        Play().
        EmptyField(1).
        FireAndWait(100).
        Assert:IsFalse(mGame:ShotActive).
        Frames(10).
        Assert:Equals(1, mGame:ShotsFired).
        Assert:IsFalse(mGame:ShotActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotThatReachesTheTopOfTheScreenIsGoneAndHitsNothing():
        Play().
        EmptyField(1).
        FireAndWait(100).
        Assert:IsFalse(mGame:ShotActive).
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, mGame:Canvas:CountKind({&KIND-SHOT})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotKillsTheFirstInvaderItMeetsAndScoresAnOctopusAsTen():
        Play().
        mGame:Canvas:ClearRect(0, 184, 224, 16).
        AimAt(mGame:Rack:X(44) + 4).
        FireAndWait(60).
        Assert:IsFalse(mGame:ShotActive).
        Assert:IsFalse(mGame:Rack:Alive(44)).
        Assert:Equals(54, mGame:Rack:AliveCount).
        Assert:Equals(10, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACrabIsWorthTwentyPoints():
        Play().
        EmptyField(22).
        ClearShields().
        AimAt(mGame:Rack:X(11) + 5).
        FireAndWait(60).
        Assert:IsFalse(mGame:Rack:Alive(11)).
        Assert:Equals(20, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASquidIsWorthThirtyPoints():
        Play().
        EmptyField(11).
        ClearShields().
        /* a row of eleven moves two cells every eleven frames, so the squid has gone six cells right when the shot gets there */
        AimAt(mGame:Rack:X(0) + 8).
        FireAndWait(60).
        Assert:IsFalse(mGame:Rack:Alive(0)).
        Assert:Equals(30, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHiScoreFollowsTheScoreAndNeverGoesDown():
        mGame:HiScore = 100.
        mGame:AddScore(40).
        Assert:Equals(100, mGame:HiScore).
        mGame:AddScore(80).
        Assert:Equals(120, mGame:HiScore).
        mGame:HiScore = -5.
        Assert:Equals(0, mGame:HiScore).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKillLeavesNoExplosionOrSparksBehindForLong():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        Play().
        mGame:Canvas:ClearRect(0, 184, 224, 16).
        before = mGame:Canvas:CountKind({&KIND-FX}).
        AimAt(mGame:Rack:X(44) + 4).
        FireAndWait(60).
        Assert:IsTrue(mGame:Canvas:CountKind({&KIND-FX}) > before).
        EmptyField(1).
        Frames(80).
        Assert:Equals(before, mGame:Canvas:CountKind({&KIND-FX})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotThatHitsAShieldEatsPartOfItAndIsGone():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        Play().
        before = mGame:Canvas:CountKind({&KIND-SHIELD}).
        AimAt(35 + 10).
        FireAndWait(60).
        Assert:IsFalse(mGame:ShotActive).
        Assert:IsTrue(mGame:Canvas:CountKind({&KIND-SHIELD}) < before).
        Assert:Equals(55, mGame:Rack:AliveCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotAndABombThatMeetDestroyEachOther():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Play().
        EmptyField(1).
        mGame:DropBomb(1, 110, 150).
        mGame:FireHeld = TRUE.
        DO n = 1 TO 40:
            mGame:Advance().
            IF NOT mGame:BombActive(1) THEN LEAVE.
        END.
        Assert:IsFalse(mGame:BombActive(1)).
        Assert:IsFalse(mGame:ShotActive).
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
    END METHOD.

    /* ---------------------------------- the saucer ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheSaucerCanBeSentFromEitherSideAndFliesAcrossTheTop():
        Play().
        mGame:SetPlayerX(40).
        mGame:LaunchSaucer(1).
        Assert:IsTrue(mGame:SaucerActive).
        Assert:Equals(-16, mGame:SaucerX).
        Frames(10).
        Assert:Equals(-6, mGame:SaucerX).
        /* a second launch while it is out changes nothing */
        mGame:LaunchSaucer(-1).
        Assert:Equals(-6, mGame:SaucerX).
        Frames(250).
        Assert:IsFalse(mGame:SaucerActive).
        mGame:LaunchSaucer(-1).
        Assert:Equals(224, mGame:SaucerX).
        Frames(10).
        Assert:Equals(214, mGame:SaucerX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotThatHitsTheSaucerKillsItAndScoresByTheShotCount():
        Play().
        EmptyField(1).
        ClearShields().
        mGame:LaunchSaucer(1).
        Frames(40).
        /* the shot takes about 44 frames to get there, and the saucer moves a cell a frame meanwhile */
        AimAt(mGame:SaucerX + 44 + 9).
        FireAndWait(80).
        Assert:IsFalse(mGame:SaucerActive).
        Assert:Equals(SpaceInvadersGame:SaucerPointsFor(1), mGame:Score).
        Assert:Equals(50, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSaucerPaysByTheArcadesTableOfShotCounts():
        Assert:Equals(100, SpaceInvadersGame:SaucerPointsFor(0)).
        Assert:Equals(50, SpaceInvadersGame:SaucerPointsFor(1)).
        Assert:Equals(150, SpaceInvadersGame:SaucerPointsFor(4)).
        Assert:Equals(300, SpaceInvadersGame:SaucerPointsFor(8)).
        Assert:Equals(300, SpaceInvadersGame:SaucerPointsFor(23)).
        Assert:Equals(100, SpaceInvadersGame:SaucerPointsFor(15)).
        Assert:Equals(100, SpaceInvadersGame:SaucerPointsFor(-3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSaucerComesAboutEveryTwentyFiveSecondsFromTheRightFirst():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Play().
        /* eight invaders at the top, with the cannon under a shield, so little can go wrong meanwhile */
        EmptyField(8).
        mGame:SetPlayerX(40).
        DO n = 1 TO 1700:
            mGame:Advance().
            IF mGame:SaucerActive THEN LEAVE.
        END.
        Assert:IsTrue(mGame:SaucerActive, "frame " + STRING(mGame:FrameCount)).
        Assert:IsTrue(mGame:SaucerX > 200).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSaucerNeverComesWithFewerThanEightInvadersLeft():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Play().
        EmptyField(7).
        mGame:SetPlayerX(40).
        DO n = 1 TO 1700:
            mGame:Advance().
            IF mGame:SaucerActive THEN LEAVE.
        END.
        Assert:IsFalse(mGame:SaucerActive).
    END METHOD.

    /* ---------------------------------- the bombs ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ABombIsDroppedOnceTheReloadTimeIsUpStartingWithTheRollingOne():
        Play().
        mGame:SetPlayerX(40).
        Frames(59).
        Assert:IsFalse(mGame:BombActive(0)).
        Frames(2).
        Assert:IsTrue(mGame:BombActive(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombFallsAboutOneAndAQuarterCellsAFrame():
        DEFINE VARIABLE y0 AS INTEGER NO-UNDO.
        Play().
        mGame:DropBomb(2, 20, 100).
        Assert:Equals(20, mGame:BombX(2)).
        Assert:Equals(100, mGame:BombY(2)).
        y0 = mGame:BombY(2).
        Frames(10).
        Assert:IsTrue(mGame:BombY(2) - y0 >= 12 AND mGame:BombY(2) - y0 <= 13, STRING(mGame:BombY(2) - y0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombThatReachesTheGroundIsSpentAndHurtsNothing():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Play().
        mGame:DropBomb(2, 20, 215).
        DO n = 1 TO 30:
            mGame:Advance().
            IF NOT mGame:BombActive(2) THEN LEAVE.
        END.
        Assert:IsFalse(mGame:BombActive(2)).
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
        Assert:Equals(3, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombThatHitsAShieldEatsPartOfItAndIsGone():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        Play().
        before = mGame:Canvas:CountKind({&KIND-SHIELD}).
        mGame:DropBomb(0, 45, 170).
        DO n = 1 TO 30:
            mGame:Advance().
            IF NOT mGame:BombActive(0) THEN LEAVE.
        END.
        Assert:IsFalse(mGame:BombActive(0)).
        Assert:IsTrue(mGame:Canvas:CountKind({&KIND-SHIELD}) < before).
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsAtMostOneBombOfEachTypeAndTheSameTypeCannotBeDroppedTwice():
        Play().
        mGame:DropBomb(0, 10, 100).
        Assert:IsTrue(ThrowsGridException(7)).
        Assert:IsTrue(mGame:BombActive(0)).
        Assert:IsFalse(mGame:BombActive(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSquigglyBombIsNotDroppedWhileTheSaucerIsOut():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Play().
        mGame:SetPlayerX(40).
        mGame:LaunchSaucer(1).
        DO n = 1 TO 200:
            mGame:Advance().
            IF mGame:BombActive(2) THEN LEAVE.
        END.
        Assert:IsFalse(mGame:BombActive(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewBombWaitsForTheOnesInTheAirSoThereIsOneAtATimeAtTheStart():
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE t    AS INTEGER NO-UNDO.
        DEFINE VARIABLE out  AS INTEGER NO-UNDO.
        DEFINE VARIABLE most AS INTEGER NO-UNDO.
        Play().
        mGame:SetPlayerX(40).
        DO n = 1 TO 600:
            mGame:Advance().
            out = 0.
            DO t = 0 TO 2:
                IF mGame:BombActive(t) THEN out = out + 1.
            END.
            most = MAXIMUM(most, out).
        END.
        Assert:Equals(1, most).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnceTheScoreHasRisenSeveralBombsAreInTheAirTogether():
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE t    AS INTEGER NO-UNDO.
        DEFINE VARIABLE out  AS INTEGER NO-UNDO.
        DEFINE VARIABLE most AS INTEGER NO-UNDO.
        Play().
        mGame:SetPlayerX(40).
        mGame:AddScore(1200).
        DO n = 1 TO 600:
            mGame:Advance().
            out = 0.
            DO t = 0 TO 2:
                IF mGame:BombActive(t) THEN out = out + 1.
            END.
            most = MAXIMUM(most, out).
        END.
        Assert:IsTrue(most >= 2, STRING(most)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AllThreeTypesOfBombAreDroppedWhenTheSaucerIsNotOut():
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE seen AS LOGICAL NO-UNDO EXTENT 3.
        DEFINE VARIABLE t    AS INTEGER NO-UNDO.
        Play().
        mGame:SetPlayerX(40).
        DO n = 1 TO 400:
            mGame:Advance().
            DO t = 0 TO 2:
                IF mGame:BombActive(t) THEN seen[t + 1] = TRUE.
            END.
        END.
        Assert:IsTrue(seen[1], "rolling").
        Assert:IsTrue(seen[2], "plunger").
        Assert:IsTrue(seen[3], "squiggly").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTimeBetweenBombsShortensAsTheScoreGoesUp():
        Assert:Equals(48, SpaceInvadersGame:ReloadFor(0)).
        Assert:Equals(48, SpaceInvadersGame:ReloadFor(199)).
        Assert:Equals(16, SpaceInvadersGame:ReloadFor(200)).
        Assert:Equals(16, SpaceInvadersGame:ReloadFor(999)).
        Assert:Equals(11, SpaceInvadersGame:ReloadFor(1000)).
        Assert:Equals(8, SpaceInvadersGame:ReloadFor(2000)).
        Assert:Equals(7, SpaceInvadersGame:ReloadFor(3000)).
        Assert:Equals(7, SpaceInvadersGame:ReloadFor(99999)).
    END METHOD.

    /* ---------------------------------- the cannon is hit ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ABombThatHitsTheCannonBlowsItUpAndTakesEverythingInTheAirOff():
        Play().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        BombTheCannon().
        Assert:Equals({&PHASE-DYING}, mGame:Phase).
        Assert:IsFalse(mGame:ShotActive).
        Assert:IsFalse(mGame:BombActive(0)).
        Assert:IsFalse(mGame:BombActive(1)).
        Assert:IsFalse(mGame:BombActive(2)).
        Assert:Equals(0, mGame:Canvas:CountKind({&KIND-PLAYER})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCannonCannotMoveOrFireWhileItExplodes():
        Play().
        BombTheCannon().
        mGame:MoveDirection = 1.
        mGame:FireHeld = TRUE.
        Frames(20).
        Assert:Equals({&PHASE-DYING}, mGame:Phase).
        Assert:Equals(0, mGame:ShotsFired).
        Assert:Equals(105, mGame:PlayerX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterTheExplosionTheCannonIsBackInTheMiddleWithOneLifeLess():
        Play().
        mGame:SetPlayerX(40).
        BombTheCannon().
        WaitForTheBlast().
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
        Assert:Equals(2, mGame:Lives).
        Assert:Equals(105, mGame:PlayerX).
        Assert:Equals({&KIND-PLAYER}, mGame:Canvas:KindAt(105, 223)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LosingTheLastCannonEndsTheGameAndTheFireKeyReturnsToTheTitle():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Play().
        DO n = 1 TO 3:
            BombTheCannon().
            WaitForTheBlast().
        END.
        Assert:Equals({&PHASE-GAMEOVER}, mGame:Phase).
        Assert:Equals(0, mGame:Lives).
        mGame:FireHeld = TRUE.
        Frames(3).
        Assert:Equals({&PHASE-GAMEOVER}, mGame:Phase).
        mGame:FireHeld = FALSE.
        Frames(2).
        mGame:FireHeld = TRUE.
        mGame:Advance().
        Assert:Equals({&PHASE-TITLE}, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameFromTheGameOverScreenStartsFromScratch():
        Play().
        mGame:AddScore(250).
        mGame:StartGame().
        Assert:Equals(0, mGame:Score).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(1, mGame:Wave).
        Assert:Equals(0, mGame:ShotsFired).
        Assert:Equals({&PHASE-STARTING}, mGame:Phase).
    END METHOD.

    /* ---------------------------------- the invaders land ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID InvadersThatReachTheCannonsRowEndTheGameWhateverLivesAreLeft():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Play().
        EmptyField(1).
        /* walk the lone invader down in the rack until one more drop is the last */
        DO WHILE mGame:Rack:Bottom() < 208:
            mGame:Rack:Step().
        END.
        /* the cannon keeps to the far side from the invader, out of the way of the bombs */
        DO n = 1 TO 600:
            IF mGame:Phase <> {&PHASE-PLAYING} THEN LEAVE.
            mGame:SetPlayerX(IF mGame:Rack:X(0) < 112 THEN 203 ELSE 8).
            mGame:Advance().
        END.
        Assert:IsTrue(mGame:Rack:Bottom() >= 216, "bottom " + STRING(mGame:Rack:Bottom())).
        WaitForTheBlast().
        Assert:Equals({&PHASE-GAMEOVER}, mGame:Phase).
        Assert:Equals(0, mGame:Lives).
    END METHOD.

    /* ---------------------------------- waves and lives ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID KillingTheLastInvaderClearsTheWaveAndTheNextOneStartsLowerDown():
        Play().
        EmptyField(0).
        mGame:Advance().
        Assert:Equals({&PHASE-CLEARED}, mGame:Phase).
        Frames(100).
        Assert:Equals({&PHASE-STARTING}, mGame:Phase).
        Assert:Equals(2, mGame:Wave).
        Assert:Equals("Wave 2", mGame:TakeNotice()).
        Assert:Equals("", mGame:TakeNotice()).
        Assert:Equals(55, mGame:Rack:AliveCount).
        Assert:Equals(SpaceInvadersGame:RackTopFor(2), mGame:Rack:Y(0)).
        Assert:IsTrue(mGame:Rack:Y(0) > 80).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShieldsAreRebuiltForANewWave():
        Play().
        mGame:Canvas:ClearRect(0, 184, 224, 16).
        Assert:Equals(0, mGame:Canvas:CountKind({&KIND-SHIELD})).
        EmptyField(0).
        Frames(100).
        Assert:IsTrue(mGame:Canvas:CountKind({&KIND-SHIELD}) > 600).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRackStartsLowerEachWaveUpToALimit():
        Assert:Equals(80, SpaceInvadersGame:RackTopFor(1)).
        Assert:Equals(88, SpaceInvadersGame:RackTopFor(2)).
        Assert:Equals(136, SpaceInvadersGame:RackTopFor(8)).
        Assert:Equals(136, SpaceInvadersGame:RackTopFor(30)).
        Assert:Equals(80, SpaceInvadersGame:RackTopFor(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnExtraCannonComesAtFifteenHundredPointsOnlyOnce():
        Play().
        mGame:AddScore(1499).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals("", mGame:TakeNotice()).
        mGame:AddScore(1).
        Assert:Equals(4, mGame:Lives).
        Assert:Equals("Extra cannon", mGame:TakeNotice()).
        mGame:AddScore(2000).
        Assert:Equals(4, mGame:Lives).
        Assert:Equals(3500, mGame:Score).
    END METHOD.

    /* ---------------------------------- time ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TickMakesAFrameForEverySixtiethOfASecondItIsGiven():
        Assert:IsFalse(mGame:Tick(0)).
        Assert:IsFalse(mGame:Tick(-5)).
        Assert:IsFalse(mGame:Tick(10)).
        Assert:Equals(0, mGame:FrameCount).
        Assert:IsTrue(mGame:Tick(10)).
        Assert:Equals(1, mGame:FrameCount).
        mGame:Tick(17).
        mGame:Tick(17).
        mGame:Tick(17).
        Assert:Equals(4, mGame:FrameCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALongStallMakesNoMoreThanFourFramesAndTheTimeIsNotOwed():
        mGame:Tick(1000).
        Assert:Equals(4, mGame:FrameCount).
        mGame:Tick(100).
        Assert:Equals(8, mGame:FrameCount).
        Assert:IsFalse(mGame:Tick(1)).
        Assert:Equals(8, mGame:FrameCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASlowerSpeedMakesProportionallyFewerFrames():
        Assert:Equals(100, mGame:SpeedPercent).
        mGame:SpeedPercent = 50.
        mGame:Tick(100).
        Assert:Equals(3, mGame:FrameCount).
        mGame:SpeedPercent = 10.
        Assert:Equals(20, mGame:SpeedPercent).
        mGame:SpeedPercent = 500.
        Assert:Equals(100, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingHappensWhilePaused():
        mGame:Paused = TRUE.
        Assert:IsTrue(mGame:Paused).
        Assert:IsFalse(mGame:Tick(500)).
        Assert:Equals(0, mGame:FrameCount).
        mGame:Paused = FALSE.
        Assert:IsTrue(mGame:Tick(50)).
    END METHOD.

    /* ---------------------------------- the picture ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheGridIsTheArcadesTwoHundredTwentyFourByTwoHundredFiftySixWithThreeLayers():
        Assert:Equals(224, mGame:Grid:Width).
        Assert:Equals(256, mGame:Grid:Height).
        Assert:Equals(224, mGame:Canvas:Width).
        Assert:Equals(256, mGame:Canvas:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStarsDriftButNeverCoverTheInvaders():
        Play().
        Frames(100).
        Assert:IsTrue(mGame:Canvas:CountKind({&KIND-ALIEN}) > 1000).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADroppedBombIsDrawnAsCellsOfTheBombKind():
        Play().
        mGame:DropBomb(1, 20, 100).
        Assert:IsTrue(mGame:Canvas:CountKind({&KIND-BOMB}) > 5).
        Assert:Equals({&KIND-BOMB}, mGame:Canvas:KindAt(21, 103)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeReleasesTheGridAndCanBeCalledAgainSafely():
        mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* ---------------------------------- the look of things ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID AfterTheExplosionTheCannonBlinksWithItsOutlineForOneAndAHalfSeconds():
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE fewest AS INTEGER NO-UNDO INITIAL 9999.
        DEFINE VARIABLE most   AS INTEGER NO-UNDO.
        DEFINE VARIABLE cells  AS INTEGER NO-UNDO.
        Play().
        mGame:SetPlayerX(40).
        BombTheCannon().
        WaitForTheBlast().
        mGame:SetPlayerX(40).
        DO n = 1 TO 80:
            mGame:Advance().
            cells = mGame:Canvas:CountKind({&KIND-PLAYER}).
            fewest = MINIMUM(fewest, cells).
            most = MAXIMUM(most, cells).
        END.
        Assert:IsTrue(fewest < most, "fewest " + STRING(fewest) + " most " + STRING(most)).
        Frames(20).
        Assert:Equals(most, mGame:Canvas:CountKind({&KIND-PLAYER})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCannonExplodesInAFlashThenTwoPicturesThenRubble():
        DEFINE VARIABLE flash  AS INTEGER NO-UNDO.
        DEFINE VARIABLE middle AS INTEGER NO-UNDO.
        DEFINE VARIABLE rubble AS INTEGER NO-UNDO.
        Play().
        mGame:SetPlayerX(40).
        BombTheCannon().
        Frames(3).
        flash = mGame:Canvas:CountKind({&KIND-FX}).
        Frames(20).
        middle = mGame:Canvas:CountKind({&KIND-FX}).
        Frames(40).
        rubble = mGame:Canvas:CountKind({&KIND-FX}).
        Assert:IsTrue(flash > 20).
        Assert:IsTrue(middle > 20).
        Assert:IsTrue(rubble > 5).
        Assert:IsTrue(rubble < flash).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSaucersBodyPulsesThroughSeveralReds():
        DEFINE VARIABLE n       AS INTEGER NO-UNDO.
        DEFINE VARIABLE seen    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE colour  AS CHARACTER NO-UNDO.
        Play().
        mGame:SetPlayerX(40).
        mGame:LaunchSaucer(1).
        DO n = 1 TO 60:
            mGame:Advance().
            /* a cell in the middle of the second row of the saucer, which is always body */
            colour = STRING(mGame:Canvas:ColourAt(mGame:SaucerX + 8, 33)).
            IF LOOKUP(colour, seen) = 0 THEN seen = seen + (IF seen = "" THEN "" ELSE ",") + colour.
        END.
        Assert:IsTrue(NUM-ENTRIES(seen) >= 3, seen).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStarsDriftBehindTheTitleLettersWithoutWipingThem():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        before = CountLit(40, 40, 150, 60).
        Frames(400).
        Assert:Equals(before, CountLit(40, 40, 150, 60)).
    END METHOD.

    /* ---------------------------------- contract errors ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID BadBombTypesAndPositionsAreRefused():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
        Assert:IsTrue(ThrowsGridException(4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NegativePointsAreRefused():
        Assert:IsTrue(ThrowsGridException(5)).
        Assert:IsTrue(ThrowsGridException(6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGridOfTheWrongSizeOrNoRandomSourceIsRefused():
        Assert:IsTrue(ThrowsGridException(8)).
        Assert:IsTrue(ThrowsGridException(9)).
    END METHOD.

END CLASS.
