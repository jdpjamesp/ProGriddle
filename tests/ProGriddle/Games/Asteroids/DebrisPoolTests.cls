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
