/* The rules of Asteroids, tested without a window. The game runs on a 320 x 240 grid and makes one frame for each
   call of Advance, so a test plays frame by frame and reads the picture back from the canvas. A seeded random
   source makes the dust, the rocks and the saucers the same every run. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsGameTests:

    {ProGriddle/Games/Asteroids/Phases.i}
    {ProGriddle/Games/Asteroids/Colours.i}

    DEFINE PRIVATE VARIABLE mGame AS AsteroidsGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = AsteroidsFactory:Create(NEW SeededRandom(7)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* ---------------------------------- helpers ---------------------------------- */

    /* From the title screen to a game in play: the fire key is let go, pressed, and let go again. */
    METHOD PRIVATE VOID Play():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        mGame:Advance().
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO n = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE other AS AsteroidsGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN other = NEW AsteroidsGame(?, NEW SeededRandom(1)).
                WHEN 2 THEN other = NEW AsteroidsGame(AsteroidsFactory:CreateGrid(), ?).
                WHEN 3 THEN other = NEW AsteroidsGame(NEW Grid(NEW ArrayStore(40, 30, AsteroidsFactory:Layers())), NEW SeededRandom(1)).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    /* ---------------------------------- building it ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheGameStartsOnTheTitleScreenWithNothingScored():
        Assert:Equals({&PHASE-TITLE}, mGame:Phase).
        Assert:Equals(0, mGame:Score).
        Assert:Equals("Asteroids", mGame:Name).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGridMustBe320By240AndAGameNeedsARandomSource():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFactoryMakesA320By240GridWithThreeLayers():
        Assert:Equals(320, mGame:Grid:Width).
        Assert:Equals(240, mGame:Grid:Height).
        Assert:Equals("view,kind,back", AsteroidsFactory:Layers()).
        Assert:Equals(3, mGame:Grid:Store:LayerCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBackgroundIsADarkVignetteLighterInTheMiddle():
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE centre AS INTEGER NO-UNDO.
        DEFINE VARIABLE edge   AS INTEGER NO-UNDO.
        /* a cell with no dust in it, near the middle and near the corner */
        DO x = 150 TO 170:
            IF mGame:Canvas:BackAt(x, 120) = AsteroidsLook:Colour({&C-VOID-CENTRE}) THEN centre = centre + 1.
        END.
        DO x = 0 TO 20:
            IF mGame:Canvas:BackAt(x, 0) = AsteroidsLook:Colour({&C-VOID-EDGE}) THEN edge = edge + 1.
        END.
        Assert:IsTrue(centre >= 19).
        Assert:IsTrue(edge >= 19).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SeventyCellsOfDustAreBakedIntoTheBackground():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE dim   AS INTEGER NO-UNDO.
        DEFINE VARIABLE mid   AS INTEGER NO-UNDO.
        DEFINE VARIABLE bright AS INTEGER NO-UNDO.
        DO y = 0 TO 239:
            DO x = 0 TO 319:
                CASE mGame:Canvas:BackAt(x, y):
                    WHEN AsteroidsLook:Colour({&C-DUST-DIM}) THEN dim = dim + 1.
                    WHEN AsteroidsLook:Colour({&C-DUST-MID}) THEN mid = mid + 1.
                    WHEN AsteroidsLook:Colour({&C-DUST-BRIGHT}) THEN bright = bright + 1.
                END CASE.
            END.
        END.
        Assert:Equals(40, dim).
        Assert:Equals(20, mid).
        Assert:Equals(10, bright).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDustDriftsLeftAndDownAndWraps():
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        DEFINE VARIABLE after  AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        /* the picture on the title screen differs from one frame to the next only by the drifting dust */
        mGame:Advance().
        DO y = 0 TO 239:
            DO x = 0 TO 319:
                IF mGame:Canvas:ColourAt(x, y) <> mGame:Canvas:BackAt(x, y) THEN before = before + 1.
            END.
        END.
        Frames(2000).
        DO y = 0 TO 239:
            DO x = 0 TO 319:
                IF mGame:Canvas:ColourAt(x, y) <> mGame:Canvas:BackAt(x, y) THEN after = after + 1.
            END.
        END.
        /* 20 drifting cells are on the screen all the time, a few may sit on a baked dust cell of the same colour */
        Assert:IsTrue(before >= 15 AND before <= 20, SUBSTITUTE("before &1", before)).
        Assert:IsTrue(after >= 15 AND after <= 20, SUBSTITUTE("after &1", after)).
    END METHOD.

    /* ---------------------------------- starting ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID PressingFireOnTheTitleScreenStartsAGameWithThreeShipsInTheMiddle():
        Play().
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(1, mGame:Wave).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(160, mGame:ShipX).
        Assert:Equals(120, mGame:ShipY).
        Assert:Equals(0, mGame:ShipHeading).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoldingTheFireKeyOnTheTitleScreenStartsOneGameAndHoldingItInPlayRestartsNothing():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        Frames(2).
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
        mGame:TurnDirection = 1.
        Frames(12).
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
        Assert:Equals(9, mGame:ShipHeading).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartGameWorksFromAnyPhaseAndAlwaysGivesAFreshGame():
        Play().
        mGame:TurnDirection = 1.
        Frames(20).
        mGame:TurnDirection = 0.
        mGame:StartGame().
        Assert:Equals({&PHASE-PLAYING}, mGame:Phase).
        Assert:Equals(0, mGame:ShipHeading).
        Assert:Equals(160, mGame:ShipX).
        Assert:Equals(0, mGame:ShipVX).
        Assert:Equals(0, mGame:ShipVY).
        Assert:Equals(3, mGame:Lives).
    END METHOD.

    /* ---------------------------------- the ship ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TurningRightTurnsThreeStepsInFourFramesAndLeftTheOtherWay():
        Play().
        mGame:TurnDirection = 1.
        Frames(4).
        Assert:Equals(3, mGame:ShipHeading).
        Frames(8).
        Assert:Equals(9, mGame:ShipHeading).
        mGame:TurnDirection = -1.
        Frames(4).
        Assert:Equals(6, mGame:ShipHeading).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TurningLeftFromStraightUpComesRoundTo63AndAFullCircleTakesAboutOneAndAHalfSeconds():
        Play().
        mGame:TurnDirection = -1.
        Frames(2).
        Assert:Equals(63, mGame:ShipHeading).
        Frames(84).
        /* 64 steps need 85.3 frames */
        Assert:Equals(0, mGame:ShipHeading).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LettingGoOfTheTurnKeyStopsTheTurn():
        Play().
        mGame:TurnDirection = 1.
        Frames(8).
        mGame:TurnDirection = 0.
        Frames(20).
        Assert:Equals(6, mGame:ShipHeading).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTurnDirectionIsKeptToMinusOneToOne():
        mGame:TurnDirection = 5.
        Assert:Equals(1, mGame:TurnDirection).
        mGame:TurnDirection = -9.
        Assert:Equals(-1, mGame:TurnDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThrustPushesTheShipTheWayItPointsAndTheShipKeepsDrifting():
        Play().
        mGame:ThrustHeld = TRUE.
        Frames(1).
        Assert:IsTrue(mGame:Thrusting).
        Assert:Equals(0, mGame:ShipVX).
        Assert:IsTrue(mGame:ShipVY < 0).
        mGame:ThrustHeld = FALSE.
        Frames(1).
        Assert:IsFalse(mGame:Thrusting).
        Frames(30).
        Assert:IsTrue(mGame:ShipVY < 0).
        Assert:IsTrue(mGame:ShipY < 120).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThrustFollowsTheHeading():
        Play().
        mGame:TurnDirection = 1.
        Frames(22).
        mGame:TurnDirection = 0.
        /* 22 frames is 16 steps, a quarter turn: the ship now points right */
        Assert:Equals(16, mGame:ShipHeading).
        mGame:ThrustHeld = TRUE.
        Frames(1).
        Assert:IsTrue(mGame:ShipVX > 0).
        Assert:Equals(0, mGame:ShipVY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADragSlowsTheShipWhenItIsNotThrusting():
        DEFINE VARIABLE v1 AS INTEGER NO-UNDO.
        Play().
        mGame:ThrustHeld = TRUE.
        Frames(20).
        mGame:ThrustHeld = FALSE.
        v1 = ABSOLUTE(mGame:ShipVY).
        Frames(60).
        Assert:IsTrue(ABSOLUTE(mGame:ShipVY) < v1).
        Assert:IsTrue(ABSOLUTE(mGame:ShipVY) > v1 / 3).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipHasATopSpeed():
        DEFINE VARIABLE speed AS DECIMAL NO-UNDO.
        Play().
        mGame:ThrustHeld = TRUE.
        Frames(600).
        speed = SQRT(DECIMAL(mGame:ShipVX) * mGame:ShipVX + DECIMAL(mGame:ShipVY) * mGame:ShipVY).
        Assert:IsTrue(speed <= 14337, STRING(speed)).
        Assert:IsTrue(speed > 12000, STRING(speed)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipComesBackInOnTheOtherSideOfEveryEdge():
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE wentY AS LOGICAL NO-UNDO.
        Play().
        mGame:ThrustHeld = TRUE.
        DO i = 1 TO 400:
            mGame:Advance().
            Assert:IsTrue(mGame:ShipX >= 0 AND mGame:ShipX < 320 AND mGame:ShipY >= 0 AND mGame:ShipY < 240).
            IF mGame:ShipY > 200 THEN wentY = TRUE.
        END.
        /* it left the top of the screen and came back at the bottom */
        Assert:IsTrue(wentY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShipsAreNotMovedOnTheTitleScreen():
        mGame:ThrustHeld = TRUE.
        mGame:TurnDirection = 1.
        Frames(10).
        Assert:Equals(0, mGame:ShipHeading).
        Assert:Equals(0, mGame:ShipVY).
    END METHOD.

    /* ---------------------------------- drawing ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheShipIsDrawnAsAGlowingOutlineWithItsNoseUp():
        Play().
        /* nose at (160, 114), the base corners at (156, 123) and (164, 123) */
        Assert:Equals(AsteroidsLook:Colour({&C-SHIP-CORE}), mGame:Canvas:ColourAt(160, 114)).
        Assert:Equals(AsteroidsLook:Colour({&C-SHIP-CORE}), mGame:Canvas:ColourAt(164, 123)).
        Assert:Equals(AsteroidsLook:Colour({&C-SHIP-CORE}), mGame:Canvas:ColourAt(156, 123)).
        /* a halo one cell outside the nose */
        Assert:Equals(AsteroidsLook:Colour({&C-SHIP-HALO}), mGame:Canvas:ColourAt(160, 113)).
        /* the spine down the middle */
        Assert:Equals(AsteroidsLook:Colour({&C-SHIP-SPINE}), mGame:Canvas:ColourAt(160, 118)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoFlameUntilTheThrustIsOnAndThenItIsBehindTheShip():
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE lit  AS INTEGER NO-UNDO.
        Play().
        mGame:ThrustHeld = TRUE.
        Frames(1).
        /* the flame is below the ship's base (row 123) at the start, since the ship barely moved */
        DO y = 126 TO 130:
            IF mGame:Canvas:ColourAt(160, y) = AsteroidsLook:Colour({&C-FLAME-OUTER}) OR mGame:Canvas:ColourAt(160, y) = AsteroidsLook:Colour({&C-FLAME-CORE}) THEN lit = lit + 1.
        END.
        Assert:IsTrue(lit > 0).
        mGame:ThrustHeld = FALSE.
        Frames(1).
        lit = 0.
        DO y = 120 TO 135:
            DO x = 150 TO 170:
                IF mGame:Canvas:ColourAt(x, y) = AsteroidsLook:Colour({&C-FLAME-OUTER}) OR mGame:Canvas:ColourAt(x, y) = AsteroidsLook:Colour({&C-FLAME-CORE}) THEN lit = lit + 1.
            END.
        END.
        Assert:Equals(0, lit).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipTurnsOnTheScreenToo():
        Play().
        mGame:TurnDirection = 1.
        Frames(22).
        mGame:TurnDirection = 0.
        /* pointing right: the nose is now at (166, 120), a little right of where the middle has moved to */
        Assert:Equals(AsteroidsLook:Colour({&C-SHIP-CORE}), mGame:Canvas:ColourAt(166, 120)).
        Assert:IsFalse(mGame:Canvas:ColourAt(160, 114) = AsteroidsLook:Colour({&C-SHIP-CORE})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewFrameStartsFromTheBackgroundSoNothingSmears():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE other AS INTEGER NO-UNDO.
        Play().
        mGame:ThrustHeld = TRUE.
        Frames(100).
        mGame:ThrustHeld = FALSE.
        /* every cell is either the background, a drifting dust cell, or part of the ship (within 12 cells of its middle) */
        DO y = 0 TO 239:
            DO x = 0 TO 319:
                IF mGame:Canvas:ColourAt(x, y) <> mGame:Canvas:BackAt(x, y) THEN DO:
                    IF NOT ((ABSOLUTE(x - mGame:ShipX) <= 12 OR ABSOLUTE(x - mGame:ShipX) >= 308) AND (ABSOLUTE(y - mGame:ShipY) <= 12 OR ABSOLUTE(y - mGame:ShipY) >= 228)) THEN other = other + 1.
                END.
            END.
        END.
        /* only the 20 dust cells may be elsewhere */
        Assert:IsTrue(other <= 20, STRING(other)).
    END METHOD.

    /* ---------------------------------- the clock ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TickMakesAFrameForEverySixtiethOfASecondAtFullSpeed():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        Play().
        before = mGame:FrameCount.
        Assert:IsTrue(mGame:Tick(17)).
        Assert:Equals(1, mGame:FrameCount - before).
        Assert:IsFalse(mGame:Tick(0)).
        Assert:Equals(1, mGame:FrameCount - before).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TickKeepsTheLeftOverTimeAndNeverMakesMoreThanFourFramesAtOnce():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        Play().
        before = mGame:FrameCount.
        mGame:Tick(1000).
        Assert:Equals(4, mGame:FrameCount - before).
        before = mGame:FrameCount.
        mGame:Tick(8).
        Assert:Equals(0, mGame:FrameCount - before).
        mGame:Tick(9).
        Assert:Equals(1, mGame:FrameCount - before).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASlowerSpeedMakesFewerFramesAndTheSpeedIsKeptBetween20And100():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        Play().
        mGame:SpeedPercent = 50.
        before = mGame:FrameCount.
        mGame:Tick(100).
        mGame:Tick(100).
        mGame:Tick(100).
        mGame:Tick(100).
        Assert:Equals(12, mGame:FrameCount - before).
        mGame:SpeedPercent = 5.
        Assert:Equals(20, mGame:SpeedPercent).
        mGame:SpeedPercent = 500.
        Assert:Equals(100, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingHappensWhilePaused():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        Play().
        mGame:ThrustHeld = TRUE.
        mGame:Paused = TRUE.
        before = mGame:FrameCount.
        Assert:IsFalse(mGame:Tick(100)).
        Assert:Equals(before, mGame:FrameCount).
        Assert:Equals(0, mGame:ShipVY).
        mGame:Paused = FALSE.
        Assert:IsTrue(mGame:Tick(100)).
    END METHOD.

    /* ---------------------------------- the rest of the surface ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheHiScoreCanBeSetAndTheGameHasNothingToSayYet():
        mGame:HiScore = 1234.
        Assert:Equals(1234, mGame:HiScore).
        Assert:Equals("", mGame:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HyperspaceDoesNothingOnTheTitleScreen():
        mGame:Hyperspace().
        Assert:Equals({&PHASE-TITLE}, mGame:Phase).
    END METHOD.

END CLASS.
