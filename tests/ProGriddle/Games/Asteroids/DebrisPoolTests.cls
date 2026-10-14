/* The pool of flying debris: single cells and short line chips that drift, slow down, spin, step through a ramp of
   colours as they age and go when their life is over. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.DebrisPoolTests:

    DEFINE PRIVATE VARIABLE mGrid   AS Grid        NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas AS PixelCanvas NO-UNDO.
    DEFINE PRIVATE VARIABLE mPool   AS DebrisPool  NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildPool():
        mGrid = NEW Grid(NEW ArrayStore(320, 240, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mCanvas:Restore().
        mPool = NEW DebrisPool(NEW SeededRandom(7), 320, 240).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleasePool():
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        mCanvas = ?.
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        mGrid = ?.
        mPool = ?.
    END METHOD.

    /* The pool's picture, on a fresh canvas. */
    METHOD PRIVATE VOID Draw():
        mCanvas:Restore().
        mCanvas:BeginBatch().
        mPool:DrawTo(mCanvas).
        mCanvas:EndBatch().
    END METHOD.

    METHOD PRIVATE VOID Steps(INPUT piCount AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO n = 1 TO piCount:
            mPool:Step().
        END.
    END METHOD.

    METHOD PRIVATE LOGICAL Cell(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piVX AS INTEGER, INPUT piVY AS INTEGER, INPUT piLife AS INTEGER):
        RETURN mPool:AddCell(piX * 4096, piY * 4096, piVX, piVY, 970, piLife, Ramp:RockDebris).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePoolHoldsFortyEightAndStartsEmpty():
        Assert:Equals(48, DebrisPool:Capacity()).
        Assert:Equals(0, mPool:Count).
        Assert:IsFalse(mPool:Alive(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACellIsAddedWhereItIsPutAndTheCountGoesUp():
        Assert:IsTrue(Cell(100, 50, 0, 0, 10)).
        Assert:Equals(1, mPool:Count).
        Assert:IsTrue(mPool:Alive(0)).
        Assert:Equals(100, mPool:X(0)).
        Assert:Equals(50, mPool:Y(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACellMovesByItsVelocityAndSlowsByItsDragEveryStep():
        Cell(100, 50, 4096, 0, 30).
        Steps(1).
        Assert:Equals(101, mPool:X(0)).
        Assert:Equals(3973, mPool:VX(0)).
        Steps(1).
        Assert:Equals(101, mPool:X(0)).
        Assert:Equals(3853, mPool:VX(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACellGoesWhenItsLifeIsOver():
        Cell(100, 50, 0, 0, 3).
        Steps(2).
        Assert:Equals(1, mPool:Count).
        Steps(1).
        Assert:Equals(0, mPool:Count).
        Assert:IsFalse(mPool:Alive(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScreenWrapsAtTheEdges():
        mPool:AddCell(319 * 4096, 10 * 4096, 2 * 4096, 0, 1000, 10, Ramp:RockDebris).
        Steps(1).
        Assert:Equals(1, mPool:X(0)).
        mPool:AddCell(10 * 4096, 1 * 4096, 0, -2 * 4096, 1000, 10, Ramp:RockDebris).
        Steps(1).
        Assert:Equals(239, mPool:Y(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFullPoolRefusesMoreAndAFreedSlotIsUsedAgain():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 48:
            Assert:IsTrue(Cell(i, 10, 0, 0, 5 + i)).
        END.
        Assert:Equals(48, mPool:Count).
        Assert:IsFalse(Cell(200, 200, 0, 0, 5)).
        Assert:Equals(48, mPool:Count).
        /* the one with the shortest life (6 steps) goes first and its slot is free for the next */
        Steps(6).
        Assert:Equals(47, mPool:Count).
        Assert:IsTrue(Cell(200, 200, 0, 0, 5)).
        Assert:Equals(48, mPool:Count).
        Assert:Equals(200, mPool:X(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearEmptiesThePool():
        Cell(1, 1, 0, 0, 5).
        Cell(2, 2, 0, 0, 5).
        mPool:Clear().
        Assert:Equals(0, mPool:Count).
        Assert:IsFalse(mPool:Alive(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACellIsDrawnInTheColourOfItsStepOfTheRampAcrossItsLife():
        Cell(100, 50, 0, 0, 12).
        Draw().
        Assert:Equals(AsteroidsLook:RampColour(Ramp:RockDebris, 0), mCanvas:ColourAt(100, 50)).
        Steps(2).
        Draw().
        Assert:Equals(AsteroidsLook:RampColour(Ramp:RockDebris, 1), mCanvas:ColourAt(100, 50)).
        Steps(8).
        Draw().
        Assert:Equals(AsteroidsLook:RampColour(Ramp:RockDebris, 5), mCanvas:ColourAt(100, 50)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:RockDebris, 5), mPool:ColourOf(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeadSlotDrawsNothing():
        Cell(100, 50, 0, 0, 2).
        Steps(2).
        Draw().
        Assert:Equals(mCanvas:BackAt(100, 50), mCanvas:ColourAt(100, 50)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AChipIsALineAboutItsMiddleAlongItsAngle():
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        c = AsteroidsLook:RampColour(Ramp:Ember, 0).
        /* heading 16 points right: half a length of 5 cells each way along the row */
        mPool:AddChip(100 * 4096, 100 * 4096, 0, 0, 1000, 20, 16 * 16, 0, 5 * 4096, Ramp:Ember).
        Draw().
        Assert:Equals(c, mCanvas:ColourAt(95, 100)).
        Assert:Equals(c, mCanvas:ColourAt(100, 100)).
        Assert:Equals(c, mCanvas:ColourAt(105, 100)).
        Assert:Equals(mCanvas:BackAt(100, 95), mCanvas:ColourAt(100, 95)).
        Assert:Equals(mCanvas:BackAt(94, 100), mCanvas:ColourAt(94, 100)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AChipTurnsBySpinEveryStep():
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        c = AsteroidsLook:RampColour(Ramp:Ember, 0).
        /* a heading a step: sixteen steps take it from pointing right to pointing down, so the row becomes a column */
        mPool:AddChip(100 * 4096, 100 * 4096, 0, 0, 1000, 60, 16 * 16, 16, 5 * 4096, Ramp:Ember).
        Steps(16).
        Draw().
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Ember, 1), mCanvas:ColourAt(100, 95)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Ember, 1), mCanvas:ColourAt(100, 105)).
        Assert:Equals(mCanvas:BackAt(95, 100), mCanvas:ColourAt(95, 100)).
    END METHOD.

    /* ---------------------------------- the ship breaking up ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheShipBreaksIntoFivePiecesSixDebrisCellsAndARingOfEightAndTheyAllGoInTime():
        mPool:ShipBreakup(160 * 4096, 120 * 4096, 0, 0, 0).
        Assert:Equals(19, mPool:Count).
        /* the ring (14 steps) goes first, then the debris cells (40), then the pieces (90) */
        Steps(14).
        Assert:Equals(11, mPool:Count).
        Steps(26).
        Assert:Equals(5, mPool:Count).
        Steps(49).
        Assert:Equals(5, mPool:Count).
        Steps(1).
        Assert:Equals(0, mPool:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePiecesStartWhereTheShipsLinesWereAndAreDrawnInTheShipDebrisColour():
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        c = AsteroidsLook:RampColour(Ramp:ShipDebris, 0).
        mPool:ShipBreakup(160 * 4096, 120 * 4096, 0, 0, 0).
        Draw().
        /* the nose is at 6 cells above the middle, the base corners are 3 cells below it */
        Assert:Equals(c, mCanvas:ColourAt(160, 114)).
        Assert:Equals(c, mCanvas:ColourAt(156, 123)).
        Assert:Equals(c, mCanvas:ColourAt(164, 123)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePiecesAreTurnedWithTheShip():
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        c = AsteroidsLook:RampColour(Ramp:ShipDebris, 0).
        /* heading 16: the nose points right, so it is 6 cells to the right of the middle */
        mPool:ShipBreakup(160 * 4096, 120 * 4096, 0, 0, 16).
        Draw().
        Assert:Equals(c, mCanvas:ColourAt(166, 120)).
        Assert:Equals(mCanvas:BackAt(160, 114), mCanvas:ColourAt(160, 114)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePiecesFlyAwayFromTheMiddleOfTheShip():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE before AS DECIMAL NO-UNDO.
        DEFINE VARIABLE after  AS DECIMAL NO-UNDO.
        mPool:ShipBreakup(160 * 4096, 120 * 4096, 0, 0, 0).
        DO i = 0 TO 4:
            before = SQRT(DECIMAL((mPool:X(i) - 160) * (mPool:X(i) - 160) + (mPool:Y(i) - 120) * (mPool:Y(i) - 120))).
            after = before.
            Steps(10).
            after = SQRT(DECIMAL((mPool:X(i) - 160) * (mPool:X(i) - 160) + (mPool:Y(i) - 120) * (mPool:Y(i) - 120))).
            Assert:IsTrue(after >= before + 1.0, SUBSTITUTE("piece &1 went from &2 to &3", i, before, after)).
            mPool:Clear().
            mPool:ShipBreakup(160 * 4096, 120 * 4096, 0, 0, 0).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePiecesTakeHalfTheShipsSpeedWithThem():
        DEFINE VARIABLE still  AS DebrisPool NO-UNDO.
        DEFINE VARIABLE moving AS DebrisPool NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER    NO-UNDO.
        DEFINE VARIABLE gain   AS INTEGER    NO-UNDO.
        still = NEW DebrisPool(NEW SeededRandom(3), 320, 240).
        moving = NEW DebrisPool(NEW SeededRandom(3), 320, 240).
        still:ShipBreakup(100 * 4096, 120 * 4096, 0, 0, 0).
        moving:ShipBreakup(100 * 4096, 120 * 4096, 2 * 4096, 0, 0).
        DO i = 1 TO 5:
            still:Step().
            moving:Step().
        END.
        /* the same luck, so only the ship's speed differs: 1 cell a step for 5 steps, a little less for the drag */
        DO i = 0 TO 4:
            gain = gain + moving:X(i) - still:X(i).
        END.
        Assert:IsTrue(gain >= 19 AND gain <= 30, STRING(gain)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSixDebrisCellsAreInTheShipRampAndTheRingStartsThreeCellsOutInTheSparkColours():
        mPool:ShipBreakup(160 * 4096, 120 * 4096, 0, 0, 0).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:ShipDebris, 0), mPool:ColourOf(5)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:ShipDebris, 0), mPool:ColourOf(10)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Spark, 0), mPool:ColourOf(11)).
        /* eight cells every 45 degrees from straight up, three cells from the middle */
        Assert:Equals(160, mPool:X(11)).
        Assert:Equals(117, mPool:Y(11)).
        Assert:Equals(160, mPool:X(15)).
        Assert:Equals(123, mPool:Y(15)).
        Assert:Equals(163, mPool:X(13)).
        Assert:Equals(120, mPool:Y(13)).
    END METHOD.

    /* ---------------------------------- rocks bursting ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ABurstHasThirteenPiecesForALargeRockTenForAMediumAndEightForASmallOne():
        mPool:RockBurst(1, 160 * 4096, 120 * 4096, 0, 0).
        Assert:Equals(13, mPool:Count).
        mPool:Clear().
        mPool:RockBurst(2, 160 * 4096, 120 * 4096, 0, 0).
        Assert:Equals(10, mPool:Count).
        mPool:Clear().
        mPool:RockBurst(3, 160 * 4096, 120 * 4096, 0, 0).
        Assert:Equals(8, mPool:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBurstsFadeAwayInTheirOwnTime():
        /* large: cells live 30 to 44 steps and the chips 36 */
        mPool:RockBurst(1, 160 * 4096, 120 * 4096, 0, 0).
        Steps(29).
        Assert:Equals(13, mPool:Count).
        Steps(16).
        Assert:Equals(0, mPool:Count).
        /* medium: cells 24 to 36, chips 28 */
        mPool:RockBurst(2, 160 * 4096, 120 * 4096, 0, 0).
        Steps(23).
        Assert:Equals(10, mPool:Count).
        Steps(13).
        Assert:Equals(0, mPool:Count).
        /* small: 16 to 22 */
        mPool:RockBurst(3, 160 * 4096, 120 * 4096, 0, 0).
        Steps(15).
        Assert:Equals(8, mPool:Count).
        Steps(7).
        Assert:Equals(0, mPool:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASmallRocksEightCellsLeaveInAnEvenRingAtThreeQuartersOfACellAStep():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE d AS DECIMAL NO-UNDO.
        mPool:RockBurst(3, 160 * 4096, 120 * 4096, 0, 0).
        Steps(4).
        DO i = 0 TO 7:
            d = SQRT(DECIMAL((mPool:X(i) - 160) * (mPool:X(i) - 160) + (mPool:Y(i) - 120) * (mPool:Y(i) - 120))).
            Assert:IsTrue(d >= 1.5 AND d <= 4.5, SUBSTITUTE("cell &1 is &2 cells out", i, d)).
        END.
        Assert:Equals(AsteroidsLook:RampColour(Ramp:RockDebris, 1), mPool:ColourOf(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALargeRocksChipsStartOnItsOutlineAndTheCellsAreInTheRockDebrisRamp():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE d AS DECIMAL NO-UNDO.
        mPool:RockBurst(1, 160 * 4096, 120 * 4096, 0, 0).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:RockDebris, 0), mPool:ColourOf(0)).
        /* slots 0 to 9 are the cells, 10 to 12 the chips, each on a vertex of the rock */
        DO i = 10 TO 12:
            d = SQRT(DECIMAL((mPool:X(i) - 160) * (mPool:X(i) - 160) + (mPool:Y(i) - 120) * (mPool:Y(i) - 120))).
            Assert:IsTrue(d >= 4 AND d <= AsteroidsArt:RockExtent(1) + 1, SUBSTITUTE("chip &1 is &2 cells out", i, d)).
        END.
    END METHOD.

    /* ---------------------------------- the muzzle spark and the exhaust ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheMuzzleSparkIsThreeCellsFromTheNoseWithinTwentyDegreesOfTheHeadingForSixSteps():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mPool:Muzzle(160 * 4096, 114 * 4096, 0).
        Assert:Equals(3, mPool:Count).
        Assert:Equals(3, mPool:CountOf(Ramp:Muzzle)).
        DO i = 0 TO 2:
            Assert:Equals(160, mPool:X(i)).
            Assert:Equals(114, mPool:Y(i)).
            /* going up, at about 0.9 of a cell a step, and no more than 20 degrees off straight up */
            Assert:IsTrue(mPool:VY(i) <= -3400, STRING(mPool:VY(i))).
            Assert:IsTrue(ABSOLUTE(mPool:VX(i)) <= ABSOLUTE(mPool:VY(i)) * 0.36, STRING(mPool:VX(i))).
            Assert:Equals(AsteroidsLook:RampColour(Ramp:Muzzle, 0), mPool:ColourOf(i)).
        END.
        Steps(5).
        Assert:Equals(3, mPool:Count).
        Steps(1).
        Assert:Equals(0, mPool:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExhaustLeavesTheTailAtNinetyPercentOfTheShipsSpeedLessAThirdOfACellBackwardsForTwentySteps():
        mPool:Exhaust(160 * 4096, 120 * 4096, 4096, 0, 0).
        Assert:Equals(1, mPool:Count).
        Assert:Equals(1, mPool:CountOf(Ramp:Exhaust)).
        Assert:Equals(0, mPool:CountOf(Ramp:Muzzle)).
        /* three cells behind a ship pointing up, moving right at a cell a step: 0.9 of that, and 0.3 of a cell down */
        Assert:Equals(160, mPool:X(0)).
        Assert:Equals(123, mPool:Y(0)).
        Assert:Equals(3686, mPool:VX(0)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Exhaust, 0), mPool:ColourOf(0)).
        Steps(19).
        Assert:Equals(1, mPool:Count).
        Steps(1).
        Assert:Equals(0, mPool:Count).
    END METHOD.

    /* ---------------------------------- rings ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ARingIsEvenlySpacedCellsFromStraightUpAtItsRadiusMovingOut():
        mPool:Ring(160 * 4096, 120 * 4096, 8, 3, 4096, 10, Ramp:Spark).
        Assert:Equals(8, mPool:Count).
        Assert:Equals(160, mPool:X(0)).
        Assert:Equals(117, mPool:Y(0)).
        Assert:Equals(163, mPool:X(2)).
        Assert:Equals(120, mPool:Y(2)).
        Assert:Equals(160, mPool:X(4)).
        Assert:Equals(123, mPool:Y(4)).
        Steps(2).
        Assert:Equals(160, mPool:X(0)).
        Assert:Equals(115, mPool:Y(0)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Spark, 0), mPool:ColourOf(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANegativeSpeedMakesTheRingCloseInOnItsMiddleAndTenCellsMakeTenPieces():
        mPool:Ring(160 * 4096, 120 * 4096, 10, 12, -4096, 12, Ramp:SparkIn).
        Assert:Equals(10, mPool:Count).
        Assert:Equals(108, mPool:Y(0)).
        Steps(11).
        /* a cell a step for eleven steps: from twelve cells out to one */
        Assert:Equals(119, mPool:Y(0)).
        Steps(1).
        Assert:Equals(0, mPool:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingRefusesNoCellsAndNegativeRadius():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mPool:Ring(0, 0, 0, 3, 4096, 10, Ramp:Spark).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPool:Ring(0, 0, 8, -1, 4096, 10, Ramp:Spark).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    /* ---------------------------------- saucers exploding ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ASaucerBreaksIntoItsOwnLinesAndARingOfTwelve():
        mPool:SaucerBurst(TRUE, 160 * 4096, 100 * 4096, 0, 0).
        Assert:Equals(10 + 12, mPool:Count).
        mPool:Clear().
        mPool:SaucerBurst(FALSE, 160 * 4096, 100 * 4096, 0, 0).
        Assert:Equals(11 + 12, mPool:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLargeSaucerFadesThroughEmberAndTheSmallOneThroughRed():
        mPool:SaucerBurst(TRUE, 160 * 4096, 100 * 4096, 0, 0).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Ember, 0), mPool:ColourOf(0)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Ember, 0), mPool:ColourOf(10)).
        mPool:Clear().
        mPool:SaucerBurst(FALSE, 160 * 4096, 100 * 4096, 0, 0).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Red, 0), mPool:ColourOf(0)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Red, 0), mPool:ColourOf(11)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRingGoesAfterTwentyTwoStepsAndTheLinesAfterSixty():
        mPool:SaucerBurst(TRUE, 160 * 4096, 100 * 4096, 0, 0).
        Steps(21).
        Assert:Equals(22, mPool:Count).
        Steps(1).
        Assert:Equals(10, mPool:Count).
        Steps(37).
        Assert:Equals(10, mPool:Count).
        Steps(1).
        Assert:Equals(0, mPool:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLinesFlyOutwardAndTheRingStartsTwoCellsOutFromStraightUp():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE d AS DECIMAL NO-UNDO.
        mPool:SaucerBurst(TRUE, 160 * 4096, 100 * 4096, 0, 0).
        Assert:Equals(160, mPool:X(10)).
        Assert:Equals(98, mPool:Y(10)).
        Assert:Equals(160, mPool:X(16)).
        Assert:Equals(102, mPool:Y(16)).
        Steps(10).
        DO i = 0 TO 9:
            d = SQRT(DECIMAL((mPool:X(i) - 160) * (mPool:X(i) - 160) + (mPool:Y(i) - 100) * (mPool:Y(i) - 100))).
            Assert:IsTrue(d >= 1.0, SUBSTITUTE("line &1 is only &2 cells out", i, d)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLinesTakeHalfTheSaucersSpeedWithThem():
        DEFINE VARIABLE still  AS DebrisPool NO-UNDO.
        DEFINE VARIABLE moving AS DebrisPool NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER    NO-UNDO.
        DEFINE VARIABLE gain   AS INTEGER    NO-UNDO.
        still = NEW DebrisPool(NEW SeededRandom(5), 320, 240).
        moving = NEW DebrisPool(NEW SeededRandom(5), 320, 240).
        still:SaucerBurst(TRUE, 100 * 4096, 100 * 4096, 0, 0).
        moving:SaucerBurst(TRUE, 100 * 4096, 100 * 4096, 2 * 4096, 0).
        DO i = 1 TO 5:
            still:Step().
            moving:Step().
        END.
        /* ten lines, each about 1 cell a step further for 5 steps less the drag */
        DO i = 0 TO 9:
            gain = gain + moving:X(i) - still:X(i).
        END.
        Assert:IsTrue(gain >= 38 AND gain <= 60, STRING(gain)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARockBurstRefusesASizeThatIsNotOneTwoOrThree():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mPool:RockBurst(0, 0, 0, 0, 0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPool:RockBurst(4, 0, 0, 0, 0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnAddRefusesNonsense():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mPool:AddCell(0, 0, 0, 0, 1000, 0, Ramp:RockDebris).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPool:AddCell(0, 0, 0, 0, 1000, 5, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPool:AddChip(0, 0, 0, 0, 1000, 0, 0, 0, 4096, Ramp:Ember).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
