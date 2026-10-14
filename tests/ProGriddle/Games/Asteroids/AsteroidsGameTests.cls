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
        DEFINE VARIABLE drawn AS LOGICAL NO-UNDO.
        /* only the last frame is drawn (and none if the test turned Drawing off): a picture of every frame is what made
           the tests slow */
        drawn = mGame:Drawing.
        DO n = 1 TO piCount:
            mGame:Drawing = drawn AND n = piCount.
            mGame:Advance().
        END.
        mGame:Drawing = drawn.
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
        Assert:Equals(GamePhase:Title, mGame:Phase).
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
            IF mGame:Canvas:BackAt(x, 120) = AsteroidsLook:Colour(Palette:VoidCentre) THEN centre = centre + 1.
        END.
        DO x = 0 TO 20:
            IF mGame:Canvas:BackAt(x, 0) = AsteroidsLook:Colour(Palette:VoidEdge) THEN edge = edge + 1.
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
                    WHEN AsteroidsLook:Colour(Palette:DustDim) THEN dim = dim + 1.
                    WHEN AsteroidsLook:Colour(Palette:DustMid) THEN mid = mid + 1.
                    WHEN AsteroidsLook:Colour(Palette:DustBright) THEN bright = bright + 1.
                END CASE.
            END.
        END.
        Assert:Equals(40, dim).
        Assert:Equals(20, mid).
        Assert:Equals(10, bright).
    END METHOD.

    /* The cells below the HUD that are in a dust colour and not the background's: the drifting dust. */
    METHOD PRIVATE INTEGER DriftingDust():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = 50 TO 239:
            DO x = 0 TO 319:
                c = mGame:Canvas:ColourAt(x, y).
                IF c <> mGame:Canvas:BackAt(x, y) AND (c = AsteroidsLook:Colour(Palette:DustDim) OR c = AsteroidsLook:Colour(Palette:DustMid) OR c = AsteroidsLook:Colour(Palette:DustBright)) THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDustDriftsLeftAndDownAndWraps():
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        DEFINE VARIABLE after  AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        /* with the rocks taken away, the cells of the dust colours that differ from the background are the drifting dust
           (the title and its words are in other colours) */
        mGame:Rocks:Clear().
        mGame:Advance().
        before = DriftingDust().
        Frames(2000).
        mGame:Rocks:Clear().
        mGame:Advance().
        after = DriftingDust().
        /* of the 20 drifting cells, most are below the HUD; a few may sit on a baked dust cell of the same colour */
        Assert:IsTrue(before >= 5 AND before <= 20, SUBSTITUTE("before &1", before)).
        Assert:IsTrue(after >= 5 AND after <= 20, SUBSTITUTE("after &1", after)).
    END METHOD.

    /* ---------------------------------- starting ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID PressingFireOnTheTitleScreenStartsAGameWithThreeShipsInTheMiddle():
        Play().
        Assert:Equals(GamePhase:Playing, mGame:Phase).
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
        Assert:Equals(GamePhase:Playing, mGame:Phase).
        mGame:TurnDirection = 1.
        Frames(12).
        Assert:Equals(GamePhase:Playing, mGame:Phase).
        Assert:Equals(9, mGame:ShipHeading).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartGameWorksFromAnyPhaseAndAlwaysGivesAFreshGame():
        Play().
        mGame:TurnDirection = 1.
        Frames(20).
        mGame:TurnDirection = 0.
        mGame:StartGame().
        Assert:Equals(GamePhase:Playing, mGame:Phase).
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
        mGame:Drawing = FALSE.
        DO i = 1 TO 400:
            mGame:Advance().
            Assert:IsTrue(mGame:ShipX >= 0 AND mGame:ShipX < 320 AND mGame:ShipY >= 0 AND mGame:ShipY < 240).
            IF mGame:ShipY > 200 THEN wentY = TRUE.
        END.
        mGame:Drawing = TRUE.
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
        Assert:Equals(AsteroidsLook:Colour(Palette:ShipCore), mGame:Canvas:ColourAt(160, 114)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShipCore), mGame:Canvas:ColourAt(164, 123)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShipCore), mGame:Canvas:ColourAt(156, 123)).
        /* a halo one cell outside the nose */
        Assert:Equals(AsteroidsLook:Colour(Palette:ShipHalo), mGame:Canvas:ColourAt(160, 113)).
        /* the spine down the middle */
        Assert:Equals(AsteroidsLook:Colour(Palette:ShipSpine), mGame:Canvas:ColourAt(160, 118)).
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
            IF mGame:Canvas:ColourAt(160, y) = AsteroidsLook:Colour(Palette:FlameOuter) OR mGame:Canvas:ColourAt(160, y) = AsteroidsLook:Colour(Palette:FlameCore) THEN lit = lit + 1.
        END.
        Assert:IsTrue(lit > 0).
        mGame:ThrustHeld = FALSE.
        Frames(1).
        lit = 0.
        DO y = 120 TO 135:
            DO x = 150 TO 170:
                IF mGame:Canvas:ColourAt(x, y) = AsteroidsLook:Colour(Palette:FlameOuter) OR mGame:Canvas:ColourAt(x, y) = AsteroidsLook:Colour(Palette:FlameCore) THEN lit = lit + 1.
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
        Assert:Equals(AsteroidsLook:Colour(Palette:ShipCore), mGame:Canvas:ColourAt(166, 120)).
        Assert:IsFalse(mGame:Canvas:ColourAt(160, 114) = AsteroidsLook:Colour(Palette:ShipCore)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewFrameStartsFromTheBackgroundSoNothingSmears():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE other AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        Play().
        mGame:ThrustHeld = TRUE.
        Quiet(100).
        mGame:ThrustHeld = FALSE.
        mGame:Rocks:Clear().
        mGame:Advance().
        /* every cell is either the background, a drifting dust cell, or part of the ship (within 12 cells of its middle) */
        DO y = 50 TO 239:
            DO x = 0 TO 319:
                IF mGame:Canvas:ColourAt(x, y) <> mGame:Canvas:BackAt(x, y) THEN DO:
                    IF NOT ((ABSOLUTE(x - mGame:ShipX) <= 12 OR ABSOLUTE(x - mGame:ShipX) >= 308) AND (ABSOLUTE(y - mGame:ShipY) <= 12 OR ABSOLUTE(y - mGame:ShipY) >= 228)) THEN other = other + 1.
                END.
            END.
        END.
        /* only the 20 dust cells may be elsewhere */
        Assert:IsTrue(other <= 20, STRING(other)).
    END METHOD.

    /* ---------------------------------- the helpers for rocks ---------------------------------- */

    /* A stationary rock of a size with its middle at a cell. */
    METHOD PRIVATE INTEGER RockAt(INPUT piSize AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN mGame:Rocks:Add(piX * 4096, piY * 4096, 0, 0, piSize, 0, 0, 1000, 1).
    END METHOD.

    /* A game in play with the wave in and no rocks, and the ship's protection over, so only what a test puts there can
       hit it. */
    METHOD PRIVATE VOID EmptySky():
        mGame:StartGame().
        mGame:SkipIntro().
        mGame:Rocks:Clear().
        Quiet(60).
    END METHOD.

    /* Frames with the rocks taken away before each one, except a small rock in the far corner that is only there so the
       wave never looks cleared and the next wave's rocks cannot get in the way of a test. It is taken away at the end. */
    METHOD PRIVATE VOID Quiet(INPUT piCount AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE drawn AS LOGICAL NO-UNDO.
        drawn = mGame:Drawing.
        DO n = 1 TO piCount:
            mGame:Rocks:Clear().
            RockAt(3, 2, 2).
            mGame:Drawing = drawn AND n = piCount.
            mGame:Advance().
        END.
        mGame:Drawing = drawn.
        mGame:Rocks:Clear().
    END METHOD.

    /* The ship is hit by a rock at the middle of the screen, and the rock goes. */
    METHOD PRIVATE VOID Crash():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO WHILE mGame:ShieldFrames > 0 AND i < 200:
            mGame:Rocks:Clear().
            mGame:Advance().
            i = i + 1.
        END.
        mGame:Rocks:Clear().
        RockAt(1, 160, 120).
        mGame:Advance().
        mGame:Rocks:Clear().
    END METHOD.

    /* ---------------------------------- the shots ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID FiringSendsAShotUpFromTheNoseSixCellsAFrame():
        EmptySky().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        Assert:Equals(1, mGame:ShotCount).
        Assert:Equals(160, mGame:ShotX(0)).
        Assert:Equals(108, mGame:ShotY(0)).
        Assert:Equals(39, mGame:ShotLife(0)).
        mGame:FireHeld = FALSE.
        Frames(1).
        Assert:Equals(102, mGame:ShotY(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotGoesTheWayTheShipPoints():
        EmptySky().
        mGame:TurnDirection = 1.
        Frames(22).
        mGame:TurnDirection = 0.
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        /* heading 16, a quarter turn: the shot leaves to the right */
        Assert:IsTrue(mGame:ShotX(0) > 160).
        Assert:Equals(120, mGame:ShotY(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotFadesAfterFortyFramesAndItsSlotIsFree():
        EmptySky().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        Quiet(38).
        Assert:Equals(1, mGame:ShotLife(0)).
        Assert:Equals(1, mGame:ShotCount).
        Quiet(1).
        Assert:Equals(0, mGame:ShotLife(0)).
        Assert:Equals(0, mGame:ShotCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoldingFireMakesAShotEveryEightFramesUpToFourInTheAir():
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE top AS INTEGER NO-UNDO.
        EmptySky().
        mGame:FireHeld = TRUE.
        Frames(8).
        Assert:Equals(1, mGame:ShotCount).
        Frames(1).
        Assert:Equals(2, mGame:ShotCount).
        DO i = 1 TO 100:
            mGame:Rocks:Clear().
            mGame:Advance().
            top = MAXIMUM(top, mGame:ShotCount).
            Assert:IsTrue(mGame:ShotCount <= 4).
        END.
        Assert:Equals(4, top).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotComesInOnTheOtherSideOfTheScreen():
        EmptySky().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        Frames(19).
        /* 114 up by 20 frames of 6 cells is -6, which is 234 */
        Assert:Equals(234, mGame:ShotY(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipDoesNotFireWhileItIsBreakingUp():
        EmptySky().
        Crash().
        mGame:FireHeld = TRUE.
        Quiet(20).
        Assert:Equals(0, mGame:ShotCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASlotMustBeZeroToThree():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:ShotX(4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:ShotY(-1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:ShotLife(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShotHasAWhiteTwoByTwoHead():
        EmptySky().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotHead), mGame:Canvas:ColourAt(160, 108)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotHead), mGame:Canvas:ColourAt(161, 108)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotHead), mGame:Canvas:ColourAt(160, 109)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotHead), mGame:Canvas:ColourAt(161, 109)).
    END METHOD.

    /* ---------------------------------- the rocks and the waves ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID AWaveHasFourLargeRocksAndTwoMoreEachWaveUpToEleven():
        Assert:Equals(4, AsteroidsGame:RocksFor(1)).
        Assert:Equals(6, AsteroidsGame:RocksFor(2)).
        Assert:Equals(8, AsteroidsGame:RocksFor(3)).
        Assert:Equals(10, AsteroidsGame:RocksFor(4)).
        Assert:Equals(11, AsteroidsGame:RocksFor(5)).
        Assert:Equals(11, AsteroidsGame:RocksFor(40)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRocksOfAWaveComeAfterAShortPauseAndFlashWhite():
        mGame:StartGame().
        Frames(29).
        Assert:Equals(0, mGame:Rocks:Count).
        Frames(1).
        Assert:Equals(4, mGame:Rocks:Count).
        Assert:Equals(4, mGame:Rocks:CountOfSize(1)).
        Assert:IsTrue(mGame:Rocks:Flash(0) > 0 OR mGame:Rocks:Flash(1) > 0 OR mGame:Rocks:Flash(2) > 0 OR mGame:Rocks:Flash(3) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstRocksAreWellAwayFromTheShip():
        DEFINE VARIABLE r  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        mGame:StartGame().
        mGame:SkipIntro().
        DO r = 0 TO 63:
            IF NOT mGame:Rocks:Alive(r) THEN NEXT.
            dx = ABSOLUTE(mGame:Rocks:X(r) / 4096 - 160).
            IF dx > 160 THEN dx = 320 - dx.
            dy = ABSOLUTE(mGame:Rocks:Y(r) / 4096 - 120).
            IF dy > 120 THEN dy = 240 - dy.
            Assert:IsTrue(SQRT(dx * dx + dy * dy) >= 68, SUBSTITUTE("rock &1 is &2 from the ship", r, SQRT(dx * dx + dy * dy))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRocksDriftAndSpin():
        DEFINE VARIABLE x0 AS INTEGER NO-UNDO.
        DEFINE VARIABLE y0 AS INTEGER NO-UNDO.
        DEFINE VARIABLE h0 AS INTEGER NO-UNDO.
        mGame:StartGame().
        mGame:SkipIntro().
        x0 = mGame:Rocks:X(0).
        y0 = mGame:Rocks:Y(0).
        h0 = mGame:Rocks:HeadingAt(0).
        Frames(70).
        Assert:IsTrue(mGame:Rocks:X(0) <> x0 OR mGame:Rocks:Y(0) <> y0).
        Assert:IsTrue(mGame:Rocks:HeadingAt(0) <> h0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotThatReachesALargeRockBreaksItIntoTwoMediumOnesAndScoresTwenty():
        EmptySky().
        RockAt(1, 160, 60).
        mGame:FireHeld = TRUE.
        Frames(6).
        mGame:FireHeld = FALSE.
        Assert:Equals(20, mGame:Score).
        Assert:Equals(0, mGame:Rocks:CountOfSize(1)).
        Assert:Equals(2, mGame:Rocks:CountOfSize(2)).
        Assert:Equals(0, mGame:ShotCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMediumRockBreaksIntoTwoSmallOnesAndScoresFifty():
        EmptySky().
        RockAt(2, 160, 60).
        mGame:FireHeld = TRUE.
        Frames(8).
        mGame:FireHeld = FALSE.
        Assert:Equals(50, mGame:Score).
        Assert:Equals(0, mGame:Rocks:CountOfSize(2)).
        Assert:Equals(2, mGame:Rocks:CountOfSize(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASmallRockJustBurstsAndScoresAHundred():
        EmptySky().
        RockAt(3, 160, 60).
        mGame:FireHeld = TRUE.
        Frames(9).
        mGame:FireHeld = FALSE.
        Assert:Equals(100, mGame:Score).
        Assert:Equals(0, mGame:Rocks:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotThatMissesTheRockFliesOn():
        EmptySky().
        RockAt(1, 220, 60).
        mGame:FireHeld = TRUE.
        Frames(1).
        mGame:FireHeld = FALSE.
        Frames(12).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(1, mGame:Rocks:Count).
        Assert:Equals(1, mGame:ShotCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePiecesOfARockFlyApartWithTheOldVelocityBetweenThem():
        DEFINE VARIABLE a   AS INTEGER NO-UNDO.
        DEFINE VARIABLE b   AS INTEGER NO-UNDO.
        DEFINE VARIABLE r   AS INTEGER NO-UNDO.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        EmptySky().
        RockAt(1, 160, 60).
        mGame:FireHeld = TRUE.
        Frames(6).
        mGame:FireHeld = FALSE.
        a = -1.
        DO r = 0 TO 63:
            IF mGame:Rocks:SizeAt(r) = 2 THEN DO:
                IF a < 0 THEN a = r.
                ELSE b = r.
            END.
        END.
        Assert:IsTrue(a >= 0 AND b > 0).
        Assert:IsTrue(ABSOLUTE(mGame:Rocks:VX(a) + mGame:Rocks:VX(b)) <= 2 * 8).
        Assert:IsTrue(ABSOLUTE(mGame:Rocks:VY(a) + mGame:Rocks:VY(b)) <= 2 * 8).
        Assert:IsTrue(mGame:Rocks:VX(a) <> mGame:Rocks:VX(b) OR mGame:Rocks:VY(a) <> mGame:Rocks:VY(b)).
        /* a push of between 0.3 and 0.6 of a cell a frame each */
        Assert:IsTrue(SQRT(DECIMAL(mGame:Rocks:VX(a)) * mGame:Rocks:VX(a) + DECIMAL(mGame:Rocks:VY(a)) * mGame:Rocks:VY(a)) >= 1200).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheLastRockGoesTheNextWaveComesAfterASecondAndTheRocksAfterAHalfSecondMore():
        mGame:StartGame().
        mGame:SkipIntro().
        mGame:Rocks:Clear().
        Frames(59).
        Assert:Equals(1, mGame:Wave).
        Frames(1).
        Assert:Equals(2, mGame:Wave).
        Frames(29).
        Assert:Equals(0, mGame:Rocks:Count).
        Frames(1).
        Assert:Equals(6, mGame:Rocks:CountOfSize(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RockPointsAre20And50And100AndNothingElseIsAnAnswer():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        Assert:Equals(20, AsteroidsGame:RockPoints(1)).
        Assert:Equals(50, AsteroidsGame:RockPoints(2)).
        Assert:Equals(100, AsteroidsGame:RockPoints(3)).
        DO ON ERROR UNDO, THROW:
            AsteroidsGame:RockPoints(4).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAreSixSlowRocksBehindTheTitle():
        Assert:Equals(6, mGame:Rocks:Count).
        Assert:Equals(2, mGame:Rocks:CountOfSize(1)).
        Assert:Equals(2, mGame:Rocks:CountOfSize(2)).
        Assert:Equals(2, mGame:Rocks:CountOfSize(3)).
        Assert:IsTrue(ABSOLUTE(mGame:Rocks:VX(0)) + ABSOLUTE(mGame:Rocks:VY(0)) <= 4 * 820).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARockIsADrawnOutlineAndANewOneFlashesWhite():
        EmptySky().
        /* a large rock with its first outline, not turned: a corner of it is at (100.9, 80.9), so cell (101, 81) */
        RockAt(1, 100, 100).
        mGame:Advance().
        Assert:Equals(AsteroidsLook:Colour(Palette:Flash), mGame:Canvas:ColourAt(101, 81)).
        Frames(8).
        Assert:Equals(AsteroidsLook:Colour(Palette:RockLarge), mGame:Canvas:ColourAt(101, 81)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRocksBehindTheTitleAreDim():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE dimly AS INTEGER NO-UNDO.
        mGame:Rocks:Clear().
        mGame:Advance().
        Frames(8).
        RockAt(1, 100, 100).
        Frames(8).
        DO y = 70 TO 130:
            DO x = 70 TO 130:
                IF mGame:Canvas:ColourAt(x, y) = AsteroidsLook:Colour(Palette:AttractLarge) THEN dimly = dimly + 1.
            END.
        END.
        Assert:IsTrue(dimly > 30).
    END METHOD.

    /* ---------------------------------- breaking up and coming back ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ARockThatTouchesTheShipBreaksItAndCostsAShip():
        EmptySky().
        RockAt(1, 160, 120).
        mGame:Advance().
        Assert:Equals(2, mGame:Lives).
        Assert:IsFalse(mGame:ShipAlive).
        Assert:Equals(GamePhase:Playing, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARockThatMissesTheShipDoesNothing():
        EmptySky().
        RockAt(1, 160, 70).
        Frames(30).
        Assert:IsTrue(mGame:ShipAlive).
        Assert:Equals(3, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewShipCannotBeHitForAMinuteAndAHalfAndBlinksAndThenCan():
        mGame:StartGame().
        mGame:SkipIntro().
        mGame:Rocks:Clear().
        Assert:IsTrue(mGame:ShieldFrames > 0).
        RockAt(1, 160, 120).
        Frames(10).
        Assert:IsTrue(mGame:ShipAlive).
        Assert:Equals(3, mGame:Lives).
        Frames(60).
        Assert:IsFalse(mGame:ShipAlive).
        Assert:Equals(2, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShieldRingIsDrawnRoundANewShipAndTheShipBlinksInsideIt():
        mGame:StartGame().
        Assert:Equals(90, mGame:ShieldFrames).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShieldRing), mGame:Canvas:ColourAt(160, 106)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShipCore), mGame:Canvas:ColourAt(160, 114)).
        Frames(5).
        /* hidden for five frames, and then back */
        Assert:IsFalse(mGame:Canvas:ColourAt(160, 114) = AsteroidsLook:Colour(Palette:ShipCore)).
        Frames(5).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShipCore), mGame:Canvas:ColourAt(160, 114)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNextShipWaitsForAClearMiddleAndComesBackProtected():
        EmptySky().
        RockAt(1, 160, 120).
        mGame:Advance().
        /* the rock sits in the middle: the ship cannot come back */
        Frames(200).
        Assert:IsFalse(mGame:ShipAlive).
        Assert:Equals(2, mGame:Lives).
        mGame:Rocks:Clear().
        Frames(1).
        Assert:IsTrue(mGame:ShipAlive).
        Assert:Equals(90, mGame:ShieldFrames).
        Assert:Equals(160, mGame:ShipX).
        Assert:Equals(120, mGame:ShipY).
        Assert:Equals(0, mGame:ShipVX).
        Assert:Equals(0, mGame:ShipHeading).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARockNearTheMiddleButNotInItDoesNotKeepTheShipOut():
        EmptySky().
        RockAt(3, 160, 120).
        mGame:Advance().
        mGame:Rocks:Clear().
        RockAt(3, 160, 200).
        Frames(150).
        Assert:IsTrue(mGame:ShipAlive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LosingTheLastShipEndsTheGameAfterItBreaksUp():
        EmptySky().
        Crash().
        Quiet(200).
        Crash().
        Quiet(200).
        Crash().
        Assert:Equals(0, mGame:Lives).
        Assert:Equals(GamePhase:Playing, mGame:Phase).
        Quiet(89).
        Assert:Equals(GamePhase:Playing, mGame:Phase).
        Quiet(1).
        Assert:Equals(GamePhase:GameOver, mGame:Phase).
        Assert:IsFalse(mGame:ShipAlive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameOverScreenWaitsNinetyFramesForAFreshFirePressThenGoesToTheTitle():
        EmptySky().
        Crash().
        Quiet(200).
        Crash().
        Quiet(200).
        Crash().
        Quiet(90).
        mGame:AddScore(50).
        mGame:FireHeld = TRUE.
        Quiet(3).
        Assert:Equals(GamePhase:GameOver, mGame:Phase).
        mGame:FireHeld = FALSE.
        Quiet(90).
        Assert:Equals(GamePhase:GameOver, mGame:Phase).
        mGame:FireHeld = TRUE.
        Frames(1).
        Assert:Equals(GamePhase:Title, mGame:Phase).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(50, mGame:HiScore).
        Assert:Equals(6, mGame:Rocks:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRocksKeepDriftingBehindGameOver():
        DEFINE VARIABLE x0 AS INTEGER NO-UNDO.
        EmptySky().
        Crash().
        Quiet(200).
        Crash().
        Quiet(200).
        Crash().
        Quiet(90).
        Assert:Equals(GamePhase:GameOver, mGame:Phase).
        mGame:Rocks:Clear().
        RockAt(1, 50, 50).
        mGame:Rocks:Add(50 * 4096, 60 * 4096, 2000, 0, 1, 0, 0, 1000, 1).
        x0 = mGame:Rocks:X(1).
        Frames(10).
        Assert:Equals(x0 + 20000, mGame:Rocks:X(1)).
    END METHOD.

    /* ---------------------------------- debris ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheShipFlashesWhiteForThreeFramesThenBreaksIntoNineteenPieces():
        EmptySky().
        Assert:Equals(0, mGame:DebrisCount).
        Crash().
        /* the rock that hit it burst too: leave only the ship's pieces to count */
        mGame:ClearDebris().
        /* frames 0 to 2: the whole ship in white, nothing broken yet */
        Assert:Equals(AsteroidsLook:Colour(Palette:Flash), mGame:Canvas:ColourAt(160, 114)).
        Assert:Equals(0, mGame:DebrisCount).
        Quiet(2).
        Assert:Equals(AsteroidsLook:Colour(Palette:Flash), mGame:Canvas:ColourAt(160, 114)).
        Assert:Equals(0, mGame:DebrisCount).
        Quiet(1).
        Assert:Equals(19, mGame:DebrisCount).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:ShipDebris, 0), mGame:Canvas:ColourAt(160, 114)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotRockBurstsIntoDebrisThirteenPiecesForALargeOneTenForAMediumAndEightForASmall():
        EmptySky().
        RockAt(1, 160, 60).
        mGame:FireHeld = TRUE.
        Frames(6).
        mGame:FireHeld = FALSE.
        Assert:Equals(13, mGame:DebrisCount).
        EmptySky().
        RockAt(2, 160, 60).
        mGame:FireHeld = TRUE.
        Frames(8).
        mGame:FireHeld = FALSE.
        Assert:Equals(10, mGame:DebrisCount).
        EmptySky().
        RockAt(3, 160, 60).
        mGame:FireHeld = TRUE.
        Frames(8).
        mGame:FireHeld = FALSE.
        Assert:Equals(8, mGame:DebrisCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADestroyedSaucerExplodesIntoTwentyTwoOrTwentyThreePiecesButOneThatFliesOffDoesNot():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        mGame:PlaceSaucer(154, 60).
        mGame:FireHeld = TRUE.
        Quiet(14).
        mGame:FireHeld = FALSE.
        Assert:IsFalse(mGame:SaucerActive).
        Assert:Equals(22, mGame:DebrisCount).
        EmptySky().
        mGame:LaunchSaucerAt(FALSE, 1, 100).
        mGame:PlaceSaucer(151, 60).
        mGame:FireHeld = TRUE.
        Quiet(14).
        mGame:FireHeld = FALSE.
        Assert:Equals(23, mGame:DebrisCount).
        /* a saucer that crosses the screen and leaves is not a kill: no explosion */
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        mGame:Drawing = FALSE.
        DO WHILE mGame:SaucerActive AND n < 600:
            Quiet(1).
            n = n + 1.
        END.
        mGame:Drawing = TRUE.
        Assert:IsFalse(mGame:SaucerActive).
        Assert:Equals(0, mGame:DebrisCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARockThatASaucerFliesIntoBurstsToo():
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        mGame:PlaceSaucer(60, 60).
        mGame:Rocks:Add(60 * 4096, 60 * 4096, 0, 0, 1, 0, 0, 1000, 1).
        mGame:Advance().
        Assert:IsTrue(mGame:DebrisCount >= 13).
        mGame:ClearDebris().
        Assert:Equals(0, mGame:DebrisCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShipDebrisIsGoneAfterNinetyMoreFramesAndANewGameClearsIt():
        EmptySky().
        Crash().
        mGame:ClearDebris().
        Quiet(3).
        Assert:Equals(19, mGame:DebrisCount).
        Quiet(14).
        Assert:Equals(11, mGame:DebrisCount).
        mGame:StartGame().
        Assert:Equals(0, mGame:DebrisCount).
        Crash().
        mGame:ClearDebris().
        Quiet(3).
        Quiet(90).
        Assert:Equals(0, mGame:DebrisCount).
    END METHOD.

    /* ---------------------------------- the title screen ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheTitleIsTracedLetterByLetterOverTheFirstSecondsOfTheTitleScreen():
        DEFINE VARIABLE core AS INTEGER NO-UNDO.
        core = AsteroidsLook:Colour(Palette:TitleCore).
        Frames(10).
        Assert:Equals(0, CellsOf(core, 0, 50, 320, 50)).
        Frames(20).
        Assert:IsTrue(CellsOf(core, 40, 58, 22, 30) > 5).
        Assert:Equals(0, CellsOf(core, 260, 58, 22, 30)).
        Frames(80).
        Assert:IsTrue(CellsOf(core, 260, 58, 22, 30) > 15).
        Assert:IsTrue(CellsOf(core, 40, 58, 22, 30) > 15).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRuleGrowsFromTheMiddleBetweenTicksOneHundredAndTenAndOneHundredAndTwentyEight():
        DEFINE VARIABLE rule AS INTEGER NO-UNDO.
        rule = AsteroidsLook:Colour(Palette:TitleRule).
        Frames(110).
        Assert:Equals(0, CellsOf(rule, 0, 98, 320, 1)).
        Frames(1).
        Assert:IsTrue(CellsOf(rule, 0, 98, 320, 1) >= 20 AND CellsOf(rule, 0, 98, 320, 1) <= 40).
        Assert:IsTrue(CellsOf(rule, 150, 98, 20, 1) >= 20).
        Frames(17).
        /* all 240 cells, from x = 40 to x = 279 */
        Assert:Equals(240, CellsOf(rule, 0, 98, 320, 1)).
        Assert:Equals(1, CellsOf(rule, 40, 98, 1, 1)).
        Assert:Equals(1, CellsOf(rule, 279, 98, 1, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSubtitleTypesInALetterATickFromTickOneHundredAndTwentyEight():
        DEFINE VARIABLE labelCol AS INTEGER NO-UNDO.
        DEFINE VARIABLE early    AS INTEGER NO-UNDO.
        labelCol = AsteroidsLook:Colour(Palette:Label).
        Frames(127).
        Assert:Equals(0, CellsOf(labelCol, 85, 106, 160, 9)).
        Frames(3).
        early = CellsOf(labelCol, 85, 106, 160, 9).
        Assert:IsTrue(early > 5).
        /* three letters so far, so nothing past the first 20 cells */
        Assert:Equals(0, CellsOf(labelCol, 105, 106, 140, 9)).
        Frames(30).
        Assert:IsTrue(CellsOf(labelCol, 85, 106, 160, 9) > early * 4).
        Assert:IsTrue(CellsOf(labelCol, 200, 106, 45, 9) > 5).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHintLinesFadeInThroughRuleLabelAndDimFiveTicksAStepTwentyTicksApart():
        DEFINE VARIABLE rule AS INTEGER NO-UNDO.
        DEFINE VARIABLE labelCol AS INTEGER NO-UNDO.
        DEFINE VARIABLE dimCol AS INTEGER NO-UNDO.
        rule = AsteroidsLook:Colour(Palette:TitleRule).
        labelCol = AsteroidsLook:Colour(Palette:Label).
        dimCol = AsteroidsLook:Colour(Palette:Dim).
        Frames(159).
        Assert:Equals(0, CellsOf(rule, 40, 168, 200, 9)).
        Frames(1).
        Assert:IsTrue(CellsOf(rule, 40, 168, 200, 9) > 20).
        Frames(5).
        Assert:Equals(0, CellsOf(rule, 40, 168, 200, 9)).
        Assert:IsTrue(CellsOf(labelCol, 40, 168, 200, 9) > 20).
        Frames(5).
        Assert:IsTrue(CellsOf(dimCol, 40, 168, 200, 9) > 20).
        /* the second line has not begun */
        Assert:Equals(0, CellsOf(dimCol, 115, 180, 100, 9) + CellsOf(labelCol, 115, 180, 100, 9) + CellsOf(rule, 115, 180, 100, 9)).
        Frames(10).
        Assert:IsTrue(CellsOf(rule, 115, 180, 100, 9) > 10).
        Frames(10).
        Assert:IsTrue(CellsOf(dimCol, 115, 180, 100, 9) > 10).
        Assert:IsTrue(CellsOf(dimCol, 40, 168, 200, 9) > 20).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PressSpaceAppearsAtTickTwoHundredAndBlinksThirtySixOnTwentyFourOff():
        DEFINE VARIABLE white AS INTEGER NO-UNDO.
        white = AsteroidsLook:Colour(Palette:TextWhite).
        Frames(199).
        Assert:Equals(0, CellsOf(white, 95, 204, 130, 14)).
        Frames(1).
        Assert:IsTrue(CellsOf(white, 95, 204, 130, 14) > 20).
        Frames(35).
        Assert:IsTrue(CellsOf(white, 95, 204, 130, 14) > 20).
        Frames(1).
        Assert:Equals(0, CellsOf(white, 95, 204, 130, 14)).
        Frames(24).
        Assert:IsTrue(CellsOf(white, 95, 204, 130, 14) > 20).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALargeSaucerCrossesTheTitleScreenLeftToRightAtRowOneHundredFortyEveryFourteenSecondsAndFiresNothing():
        DEFINE VARIABLE x0   AS INTEGER NO-UNDO.
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE shots AS INTEGER NO-UNDO.
        mGame:Drawing = FALSE.
        Frames(839).
        Assert:IsFalse(mGame:SaucerActive).
        Frames(1).
        Assert:IsTrue(mGame:SaucerActive).
        Assert:IsTrue(mGame:SaucerLarge).
        Assert:Equals(140, mGame:SaucerY).
        x0 = mGame:SaucerX.
        /* it crosses in a straight line without firing, and is gone once across (about 470 frames) */
        DO WHILE mGame:SaucerActive AND n < 600:
            Frames(1).
            n = n + 1.
            shots = shots + mGame:SaucerShotCount.
            IF mGame:SaucerActive THEN Assert:Equals(140, mGame:SaucerY).
        END.
        Assert:IsTrue(n >= 400 AND n <= 520, STRING(n)).
        Assert:Equals(0, shots).
        Assert:IsTrue(x0 < 10).
        /* and the next one comes fourteen seconds after the first */
        Frames(840 - n - 1).
        Assert:IsFalse(mGame:SaucerActive).
        Frames(1).
        Assert:IsTrue(mGame:SaucerActive).
        mGame:Drawing = TRUE.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingAGameSendsTheTitleSaucerAway():
        Frames(850).
        Assert:IsTrue(mGame:SaucerActive).
        Play().
        Assert:IsFalse(mGame:SaucerActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingAGameTakesTheTitleAwayAndANewTitleStartsAgainFromTheBeginning():
        DEFINE VARIABLE core AS INTEGER NO-UNDO.
        core = AsteroidsLook:Colour(Palette:TitleCore).
        Frames(130).
        Play().
        Assert:Equals(0, CellsOf(core, 36, 54, 250, 40)).
        mGame:Initialise().
        Frames(2).
        Assert:Equals(GamePhase:Title, mGame:Phase).
        Assert:Equals(0, CellsOf(core, 36, 54, 250, 40)).
    END METHOD.

    /* ---------------------------------- the game over screen ---------------------------------- */

    /* Three ships lost and the game over screen has just begun (its first frame, tick 0). */
    METHOD PRIVATE VOID GameOverScreen():
        EmptySky().
        Crash().
        Quiet(200).
        Crash().
        Quiet(200).
        Crash().
        Quiet(90).
        Assert:Equals(GamePhase:GameOver, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLettersOfGameOverAppearOneEveryThreeFramesInAGradient():
        GameOverScreen().
        Quiet(1).
        /* the first letter is there, the rest are not */
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:OverTop), 80, 84, 18, 1) > 0).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:OverTop), 100, 84, 150, 1)).
        Quiet(3).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:OverTop), 98, 84, 18, 1) > 0).
        Quiet(30).
        /* all nine letters: the top row in the top colour, the bottom row in the bottom colour */
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:OverTop), 200, 84, 40, 1) > 0).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:OverBottom), 80, 104, 160, 1) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreLineShowsTheLabelAndTheScoreInWhite():
        GameOverScreen().
        Quiet(10).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:Label), 124, 116, 36, 7) > 5).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TextWhite), 160, 116, 40, 7) > 5).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NewHiScoreBlinksInGoldTenFramesOnAndTenOffAndOnlyWhenTheRecordIsBeaten():
        DEFINE VARIABLE gold AS INTEGER NO-UNDO.
        gold = AsteroidsLook:Colour(Palette:Gold).
        GameOverScreen().
        Quiet(5).
        Assert:IsFalse(mGame:NewHiScore).
        Assert:Equals(0, CellsOf(gold, 124, 132, 100, 7)).
        /* a record */
        EmptySky().
        Crash().
        Quiet(200).
        mGame:AddScore(50).
        Crash().
        Quiet(200).
        Crash().
        Quiet(90).
        Assert:IsTrue(mGame:NewHiScore).
        Quiet(5).
        Assert:IsTrue(CellsOf(gold, 124, 132, 100, 7) > 5).
        Quiet(10).
        Assert:Equals(0, CellsOf(gold, 124, 132, 100, 7)).
        Quiet(10).
        Assert:IsTrue(CellsOf(gold, 124, 132, 100, 7) > 5).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PressSpaceAppearsAfterNinetyFramesAndBlinksThirtySixOnAndTwentyFourOff():
        DEFINE VARIABLE white AS INTEGER NO-UNDO.
        white = AsteroidsLook:Colour(Palette:TextWhite).
        GameOverScreen().
        Quiet(89).
        Assert:Equals(0, CellsOf(white, 127, 170, 100, 7)).
        Quiet(1).
        Assert:IsTrue(CellsOf(white, 127, 170, 100, 7) > 5).
        Quiet(40).
        Assert:Equals(0, CellsOf(white, 127, 170, 100, 7)).
        Quiet(20).
        Assert:IsTrue(CellsOf(white, 127, 170, 100, 7) > 5).
    END METHOD.

    /* ---------------------------------- the saucers ---------------------------------- */

    /* Runs frames, rocks away, until the saucer has fired once (up to piMax frames). */
    METHOD PRIVATE VOID UntilTheFirstSaucerShot(INPUT piMax AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO WHILE n < piMax AND mGame:SaucerShotCount = 0:
            Quiet(1).
            n = n + 1.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerComesInAtTheEdgeAtTheRowItWasGiven():
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        Assert:IsTrue(mGame:SaucerActive).
        Assert:IsTrue(mGame:SaucerLarge).
        Assert:Equals(-8, mGame:SaucerX).
        Assert:Equals(100, mGame:SaucerY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLargeSaucerCrossesAtSevenTenthsOfACellAFrameAndTheSmallOneAtOne():
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        Quiet(100).
        Assert:IsTrue(mGame:SaucerX >= 61 AND mGame:SaucerX <= 63, STRING(mGame:SaucerX)).
        mGame:PlaceSaucer(400, 100).
        Quiet(20).
        Assert:IsFalse(mGame:SaucerActive).
        mGame:LaunchSaucerAt(FALSE, 1, 100).
        Quiet(100).
        Assert:IsTrue(mGame:SaucerX >= 91 AND mGame:SaucerX <= 93, STRING(mGame:SaucerX)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerFromTheRightFliesLeftAndLeavesTheScreen():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        EmptySky().
        mGame:LaunchSaucerAt(FALSE, -1, 100).
        Assert:Equals(328, mGame:SaucerX).
        mGame:Drawing = FALSE.
        DO WHILE mGame:SaucerActive AND n < 400:
            Quiet(1).
            n = n + 1.
        END.
        mGame:Drawing = TRUE.
        Assert:IsFalse(mGame:SaucerActive).
        Assert:IsTrue(n >= 300 AND n <= 345, STRING(n)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyOneSaucerAtATimeAndOnlyInAGame():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:LaunchSaucer(TRUE, 1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        EmptySky().
        mGame:LaunchSaucer(TRUE, 1).
        DO ON ERROR UNDO, THROW:
            mGame:LaunchSaucer(FALSE, -1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadSaucerRequestIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        EmptySky().
        DO ON ERROR UNDO, THROW:
            mGame:LaunchSaucerAt(?, 1, 100).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:LaunchSaucerAt(TRUE, 0, 100).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:LaunchSaucerAt(TRUE, 1, 10).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:PlaceSaucer(10, 10).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(4, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSaucerFiresItsFirstShotAfterASecondAndNotBefore():
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 30).
        Quiet(55).
        Assert:Equals(0, mGame:SaucerShotCount).
        UntilTheFirstSaucerShot(60).
        Assert:Equals(1, mGame:SaucerShotCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSmallSaucerAimsAtTheShipWhenTheScoreIsHigh():
        DEFINE VARIABLE sx0  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sy0  AS INTEGER NO-UNDO.
        DEFINE VARIABLE ax   AS INTEGER NO-UNDO.
        DEFINE VARIABLE ay   AS INTEGER NO-UNDO.
        DEFINE VARIABLE h1   AS INTEGER NO-UNDO.
        DEFINE VARIABLE h2   AS INTEGER NO-UNDO.
        DEFINE VARIABLE diff AS INTEGER NO-UNDO.
        EmptySky().
        mGame:AddScore(30000).
        mGame:LaunchSaucerAt(FALSE, 1, 30).
        mGame:PlaceSaucer(40, 30).
        UntilTheFirstSaucerShot(100).
        Assert:Equals(1, mGame:SaucerShotCount).
        sx0 = mGame:SaucerShotX(0).
        sy0 = mGame:SaucerShotY(0).
        ax = mGame:SaucerX.
        ay = mGame:SaucerY.
        Quiet(5).
        /* five frames of flight show which way it is going: from the saucer to the ship at (160, 120) */
        h1 = Heading:Nearest(mGame:SaucerShotX(0) - sx0, mGame:SaucerShotY(0) - sy0).
        h2 = Heading:Nearest(160 - ax, 120 - ay).
        diff = ABSOLUTE(h1 - h2).
        IF diff > 32 THEN diff = 64 - diff.
        Assert:IsTrue(diff <= 2, SUBSTITUTE("flying &1, ship is &2", h1, h2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerShotIsDrawnAsAPlusWithAPaleMiddle():
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 30).
        UntilTheFirstSaucerShot(100).
        Assert:Equals(AsteroidsLook:Colour(Palette:SaucerShotCentre), mGame:Canvas:ColourAt(mGame:SaucerShotX(0), mGame:SaucerShotY(0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShipShotThatReachesTheLargeSaucerDestroysItAndScoresTwoHundred():
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        mGame:PlaceSaucer(154, 60).
        mGame:FireHeld = TRUE.
        Quiet(14).
        mGame:FireHeld = FALSE.
        Assert:IsFalse(mGame:SaucerActive).
        Assert:Equals(200, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShipShotThatReachesTheSmallSaucerScoresAThousand():
        EmptySky().
        mGame:LaunchSaucerAt(FALSE, 1, 100).
        mGame:PlaceSaucer(151, 60).
        mGame:FireHeld = TRUE.
        Quiet(14).
        mGame:FireHeld = FALSE.
        Assert:IsFalse(mGame:SaucerActive).
        Assert:Equals(1000, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerThatFliesIntoTheShipBreaksItAndIsDestroyedAndScores():
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        mGame:PlaceSaucer(155, 120).
        Quiet(2).
        Assert:IsFalse(mGame:SaucerActive).
        Assert:IsFalse(mGame:ShipAlive).
        Assert:Equals(2, mGame:Lives).
        Assert:Equals(200, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerShotThatReachesTheShipBreaksIt():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        EmptySky().
        mGame:AddScore(30000).
        mGame:LaunchSaucerAt(FALSE, 1, 120).
        mGame:PlaceSaucer(30, 120).
        /* the first shot is aimed along the row, 130 cells at 2.2 cells a frame */
        DO WHILE n < 160 AND mGame:ShipAlive:
            Quiet(1).
            n = n + 1.
        END.
        Assert:IsFalse(mGame:ShipAlive).
        Assert:Equals(5, mGame:Lives).
        Assert:IsTrue(mGame:SaucerActive).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerThatFliesIntoARockIsDestroyedAndTheRockBreaksWithoutPoints():
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        mGame:PlaceSaucer(60, 60).
        mGame:Rocks:Add(60 * 4096, 60 * 4096, 0, 0, 1, 0, 0, 1000, 1).
        mGame:Advance().
        Assert:IsFalse(mGame:SaucerActive).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, mGame:Rocks:CountOfSize(1)).
        Assert:Equals(2, mGame:Rocks:CountOfSize(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerComesByItselfAfterTwentySecondsOrSoAndTheFirstOnesAreLarge():
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE seen  AS INTEGER NO-UNDO.
        DEFINE VARIABLE was   AS LOGICAL NO-UNDO.
        DEFINE VARIABLE small AS LOGICAL NO-UNDO.
        EmptySky().
        mGame:Drawing = FALSE.
        DO n = 1 TO 1500:
            Quiet(1).
            IF mGame:SaucerActive AND NOT was THEN DO:
                seen = seen + 1.
                IF NOT mGame:SaucerLarge THEN small = TRUE.
            END.
            was = mGame:SaucerActive.
        END.
        mGame:Drawing = TRUE.
        Assert:Equals(1, seen).
        Assert:IsFalse(small).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSaucerIsDrawnWithItsGlowAndTheTwoLinesInside():
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE core AS INTEGER NO-UNDO.
        DEFINE VARIABLE halo AS INTEGER NO-UNDO.
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        mGame:PlaceSaucer(100, 60).
        mGame:Advance().
        DO y = 50 TO 70:
            DO x = 90 TO 112:
                IF mGame:Canvas:ColourAt(x, y) = AsteroidsLook:Colour(Palette:SaucerLCore) THEN core = core + 1.
                IF mGame:Canvas:ColourAt(x, y) = AsteroidsLook:Colour(Palette:SaucerLHalo) THEN halo = halo + 1.
            END.
        END.
        /* the body, the waist and the dome base make about forty cells; the glow is more than that */
        Assert:IsTrue(core >= 30 AND core <= 60, STRING(core)).
        Assert:IsTrue(halo >= core, SUBSTITUTE("&1 glow, &2 core", halo, core)).
    END METHOD.

    /* ---------------------------------- hyperspace ---------------------------------- */

    /* A game whose luck is fixed: with 99 the hyperspace never fails and the ship comes back at (119, 129), with 0 it always
       fails and the ship comes back at (20, 30). */
    METHOD PRIVATE VOID LuckyGame(INPUT piLuck AS INTEGER):
        mGame:Dispose().
        mGame = AsteroidsFactory:Create(NEW FixedRandom(piLuck)).
        EmptySky().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HyperspaceTakesTheShipAwayForFiftyFourFramesAndBringsItBackSomewhereElseAtRest():
        LuckyGame(99).
        mGame:ThrustHeld = TRUE.
        Frames(10).
        mGame:ThrustHeld = FALSE.
        mGame:Hyperspace().
        Assert:IsTrue(mGame:Hyperspacing).
        Assert:IsFalse(mGame:ShipAlive).
        Quiet(53).
        Assert:IsTrue(mGame:Hyperspacing).
        Quiet(1).
        Assert:IsFalse(mGame:Hyperspacing).
        Assert:IsTrue(mGame:ShipAlive).
        Assert:Equals(119, mGame:ShipX).
        Assert:Equals(129, mGame:ShipY).
        Assert:Equals(0, mGame:ShipVX).
        Assert:Equals(0, mGame:ShipVY).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals(0, mGame:ShieldFrames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipIsNotHurtWhileItIsAwayButCanBeOnTheWayBack():
        LuckyGame(99).
        mGame:Hyperspace().
        Quiet(20).
        /* a rock where the ship will come back: nothing happens while it is gone */
        mGame:Rocks:Clear().
        RockAt(1, 119, 129).
        mGame:Advance().
        Assert:Equals(3, mGame:Lives).
        mGame:Rocks:Clear().
        RockAt(1, 119, 129).
        Frames(10).
        Assert:Equals(3, mGame:Lives).
        mGame:Rocks:Clear().
        RockAt(1, 119, 129).
        Frames(30).
        Assert:Equals(2, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFailedJumpBreaksTheShipWhereItComesBack():
        LuckyGame(0).
        mGame:Hyperspace().
        Quiet(53).
        Assert:Equals(3, mGame:Lives).
        Quiet(1).
        Assert:Equals(2, mGame:Lives).
        Assert:IsFalse(mGame:ShipAlive).
        Assert:IsFalse(mGame:Hyperspacing).
        Assert:Equals(20, mGame:ShipX).
        Assert:Equals(30, mGame:ShipY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheChanceOfAFailureGrowsWithTheRocksOnTheScreen():
        /* a roll of 10: no failure with no rocks (6 percent), a failure among 10 rocks (11 percent) */
        LuckyGame(10).
        mGame:Hyperspace().
        Quiet(54).
        Assert:IsTrue(mGame:ShipAlive).
        LuckyGame(10).
        DO WHILE mGame:Rocks:Count < 10:
            RockAt(3, 5 + mGame:Rocks:Count * 20, 5).
        END.
        mGame:Hyperspace().
        DO WHILE mGame:Hyperspacing:
            mGame:Advance().
        END.
        Assert:IsFalse(mGame:ShipAlive).
        Assert:Equals(2, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipCannotFireOrJumpAgainWhileItIsAwayOrBreakingUp():
        LuckyGame(99).
        mGame:Hyperspace().
        mGame:FireHeld = TRUE.
        Quiet(20).
        Assert:Equals(0, mGame:ShotCount).
        mGame:Hyperspace().
        Quiet(34).
        Assert:IsTrue(mGame:ShipAlive).
        mGame:FireHeld = FALSE.
        RockAt(1, mGame:ShipX, mGame:ShipY).
        mGame:Advance().
        Assert:IsFalse(mGame:ShipAlive).
        mGame:Hyperspace().
        Assert:IsFalse(mGame:Hyperspacing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipStretchesAndFadesAsItLeaves():
        LuckyGame(99).
        mGame:Hyperspace().
        Quiet(9).
        /* the fifth step: 320 percent along, so the nose is at 120 - 19.2, row 101, in the first colour of the wreckage */
        Assert:Equals(AsteroidsLook:Colour(Palette:ShipDebris1), mGame:Canvas:ColourAt(160, 101)).
    END METHOD.

    /* ---------------------------------- the HUD ---------------------------------- */

    /* How many cells of a colour there are in a rectangle of the picture. */
    METHOD PRIVATE INTEGER CellsOf(INPUT piColour AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = piY TO piY + piH - 1:
            DO x = piX TO piX + piW - 1:
                IF mGame:Canvas:ColourAt(x, y) = piColour THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreHiScoreAndWaveAreWrittenAtTheTopOfTheScreenInPlayAndOnTheTitle():
        mGame:HiScore = 1234.
        mGame:Advance().
        /* on the title: SCORE, its six digits at twice the size, HI-SCORE and its digits, and WAVE and its digit */
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:Label), 12, 8, 30, 7) > 20).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TextWhite), 12, 18, 70, 14) > 60).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:Label), 136, 8, 48, 7) > 20).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:Dim), 142, 18, 36, 7) > 15).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:Label), 285, 8, 24, 7) > 15).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TextWhite), 295, 18, 12, 14) > 10).
        mGame:StartGame().
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TextWhite), 12, 18, 70, 14) > 60).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreDigitsChangeWithTheScoreAndTheWaveMovesLeftAsItGetsMoreDigits():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        DEFINE VARIABLE one    AS INTEGER NO-UNDO.
        mGame:StartGame().
        before = CellsOf(AsteroidsLook:Colour(Palette:TextWhite), 12, 18, 70, 14).
        mGame:AddScore(88).
        mGame:Advance().
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TextWhite), 12, 18, 70, 14) <> before).
        /* a one digit wave sits at 297 to 307, and a two digit one starts at 285 */
        one = CellsOf(AsteroidsLook:Colour(Palette:TextWhite), 285, 18, 12, 14).
        Assert:Equals(0, one).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASmallShipIsShownForEverySpareShipUpToSix():
        DEFINE VARIABLE icon AS INTEGER NO-UNDO.
        icon = AsteroidsLook:Colour(Palette:ShipIcon).
        EmptySky().
        /* three ships, one flying: two spares at (17, 44) and (28, 44), and none at (39, 44) */
        Assert:IsTrue(CellsOf(icon, 10, 38, 14, 12) > 6).
        Assert:IsTrue(CellsOf(icon, 21, 38, 14, 12) > 6).
        Assert:Equals(0, CellsOf(icon, 32, 38, 14, 12)).
        mGame:AddScore(10000).
        mGame:AddScore(10000).
        mGame:AddScore(10000).
        mGame:AddScore(10000).
        mGame:AddScore(10000).
        mGame:AddScore(10000).
        Quiet(1).
        /* eight ships, but only six icons are shown */
        Assert:IsTrue(CellsOf(icon, 65, 38, 14, 12) > 6).
        Assert:Equals(0, CellsOf(icon, 79, 38, 14, 12)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreTurnsGoldForTwentyFramesAfterASaucerOrAnExtraShip():
        DEFINE VARIABLE gold AS INTEGER NO-UNDO.
        gold = AsteroidsLook:Colour(Palette:Gold).
        EmptySky().
        Assert:Equals(0, CellsOf(gold, 12, 18, 70, 14)).
        mGame:AddScore(10000).
        Quiet(1).
        Assert:IsTrue(CellsOf(gold, 12, 18, 70, 14) > 60).
        Quiet(20).
        Assert:Equals(0, CellsOf(gold, 12, 18, 70, 14)).
    END METHOD.

    /* ---------------------------------- the wave banner ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID AWaveBeginsWithALineGrowingFromTheMiddleAndTheWordsInAShadeFromWhiteToGrey():
        DEFINE VARIABLE dimN AS INTEGER NO-UNDO.
        mGame:StartGame().
        Frames(4).
        /* the line is about a quarter grown at the 4th frame (16 of 60 cells each side) and the words are not there yet */
        dimN = CellsOf(AsteroidsLook:Colour(Palette:Dim), 90, 88, 140, 1).
        Assert:IsTrue(dimN >= 28 AND dimN <= 36, STRING(dimN)).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:BannerTop), 90, 60, 140, 30)).
        Frames(20).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:Dim), 90, 88, 140, 1) >= 118).
        /* WAVE 1 at three times the size: the top row in the top colour and the bottom row in the bottom colour */
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:BannerTop), 105, 64, 110, 1) > 5).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:BannerBottom), 105, 84, 110, 1) > 5).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:BannerTop), 0, 90, 320, 150)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBannerFadesInThreeStepsAndIsGoneAfterNinetyFrames():
        mGame:StartGame().
        Frames(40).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:BannerTop), 105, 64, 110, 1) > 5).
        Frames(32).
        /* frames 72 to 76: grey words, the colour of the line */
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:BannerTop), 105, 64, 110, 1)).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:Dim), 105, 60, 110, 30) > 50).
        Frames(8).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:Label), 105, 60, 110, 30) > 50).
        Frames(8).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TitleRule), 105, 60, 110, 30) > 50).
        Frames(10).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:TitleRule), 0, 55, 320, 40)).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:Dim), 0, 55, 320, 40)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNextWaveHasItsOwnBannerWithItsNumber():
        mGame:StartGame().
        mGame:SkipIntro().
        mGame:Rocks:Clear().
        Frames(59).
        Assert:Equals(1, mGame:Wave).
        Frames(1).
        Assert:Equals(2, mGame:Wave).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:BannerTop), 0, 60, 320, 30)).
        Frames(12).
        mGame:Rocks:Clear().
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:BannerTop), 105, 64, 110, 1) > 5).
    END METHOD.

    /* ---------------------------------- the score ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID AnExtraShipComesAtEveryTenThousandPoints():
        Play().
        mGame:AddScore(9990).
        Assert:Equals(3, mGame:Lives).
        Assert:Equals("", mGame:TakeNotice()).
        mGame:AddScore(10).
        Assert:Equals(4, mGame:Lives).
        Assert:Equals("Extra ship", mGame:TakeNotice()).
        Assert:Equals("", mGame:TakeNotice()).
        mGame:AddScore(10000).
        Assert:Equals(5, mGame:Lives).
        mGame:AddScore(20000).
        Assert:Equals(7, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHiScoreFollowsTheScoreWhenItIsBeatenAndKeepsTheOldOneWhenNot():
        Play().
        mGame:HiScore = 500.
        mGame:AddScore(300).
        Assert:Equals(500, mGame:HiScore).
        Assert:IsFalse(mGame:NewHiScore).
        mGame:AddScore(300).
        Assert:Equals(600, mGame:HiScore).
        Assert:IsTrue(mGame:NewHiScore).
        mGame:StartGame().
        Assert:IsFalse(mGame:NewHiScore).
        Assert:Equals(600, mGame:HiScore).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NegativePointsAreRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:AddScore(-5).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:AddScore(?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
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

    @Test.
    METHOD PUBLIC VOID PausingAGameThatHasRunDimsThePictureOnceAndShowsPaused():
        DEFINE VARIABLE white AS INTEGER NO-UNDO.
        DEFINE VARIABLE sky   AS INTEGER NO-UNDO.
        white = AsteroidsLook:Colour(Palette:TextWhite).
        sky = mGame:Canvas:BackAt(2, 235).
        Play().
        Quiet(5).
        Assert:Equals(sky, mGame:Canvas:ColourAt(2, 235)).
        Assert:Equals(0, CellsOf(white, 107, 100, 110, 21)).
        mGame:Paused = TRUE.
        Assert:Equals(ColourMath:Scale(sky, 45), mGame:Canvas:ColourAt(2, 235)).
        Assert:IsTrue(CellsOf(white, 107, 100, 110, 21) > 20).
        /* pausing again does not dim it twice */
        mGame:Paused = TRUE.
        Assert:Equals(ColourMath:Scale(sky, 45), mGame:Canvas:ColourAt(2, 235)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePausedPictureIsGoneAtTheNextFrameAfterResuming():
        DEFINE VARIABLE white AS INTEGER NO-UNDO.
        white = AsteroidsLook:Colour(Palette:TextWhite).
        Play().
        Quiet(5).
        mGame:Paused = TRUE.
        mGame:Paused = FALSE.
        Frames(1).
        Assert:Equals(mGame:Canvas:BackAt(2, 235), mGame:Canvas:ColourAt(2, 235)).
        Assert:Equals(0, CellsOf(white, 107, 100, 110, 21)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithDrawingOffAFrameIsMadeButNotDrawn():
        DEFINE VARIABLE core AS INTEGER NO-UNDO.
        DEFINE VARIABLE y0   AS INTEGER NO-UNDO.
        core = AsteroidsLook:Colour(Palette:ShipCore).
        Assert:IsTrue(mGame:Drawing).
        Play().
        Assert:Equals(core, mGame:Canvas:ColourAt(160, 114)).
        y0 = mGame:ShipY.
        mGame:ThrustHeld = TRUE.
        mGame:Drawing = FALSE.
        DO WHILE mGame:ShipY = y0:
            mGame:Advance().
        END.
        /* the frames were made and the ship has moved, but the picture still shows the ship where it was */
        Assert:IsTrue(mGame:ShipY <> y0).
        Assert:Equals(core, mGame:Canvas:ColourAt(160, 114)).
        mGame:Drawing = TRUE.
        mGame:Advance().
        Assert:IsTrue(mGame:ShipY <> y0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APauseBeforeTheGameHasRunShowsNothing():
        DEFINE VARIABLE sky AS INTEGER NO-UNDO.
        sky = mGame:Canvas:BackAt(2, 235).
        mGame:Paused = TRUE.
        Assert:Equals(sky, mGame:Canvas:ColourAt(2, 235)).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:TextWhite), 107, 100, 110, 21)).
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
        Assert:Equals(GamePhase:Title, mGame:Phase).
    END METHOD.

END CLASS.
