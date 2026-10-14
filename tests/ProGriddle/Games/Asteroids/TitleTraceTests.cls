/* The ASTEROIDS title drawn stroke by stroke, one letter after another, as a vector monitor would draw it. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.TitleTraceTests:

    DEFINE PRIVATE VARIABLE mGrid   AS Grid        NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas AS PixelCanvas NO-UNDO.
    DEFINE PRIVATE VARIABLE mTrace  AS TitleTrace  NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildTrace():
        mGrid = NEW Grid(NEW ArrayStore(320, 240, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mCanvas:Restore().
        mTrace = NEW TitleTrace().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseTrace():
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        mCanvas = ?.
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        mGrid = ?.
        mTrace = ?.
    END METHOD.

    /* The picture of the title at a tick. */
    METHOD PRIVATE VOID DrawAt(INPUT piTick AS INTEGER):
        mCanvas:Restore().
        mCanvas:BeginBatch().
        mTrace:DrawTo(mCanvas, piTick).
        mCanvas:EndBatch().
    END METHOD.

    /* How many cells of a colour there are in a rectangle of the picture. */
    METHOD PRIVATE INTEGER CellsOf(INPUT piColour AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = piY TO piY + piH - 1:
            DO x = piX TO piX + piW - 1:
                IF mCanvas:ColourAt(x, y) = piColour THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingIsDrawnBeforeTickTwentyAndTheTitleIsDoneAtTickOneHundredAndTen():
        Assert:IsFalse(mTrace:IsDone(0)).
        Assert:IsFalse(mTrace:IsDone(109)).
        Assert:IsTrue(mTrace:IsDone(110)).
        DrawAt(20).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 0, 0, 320, 240)).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:Flash), 0, 0, 320, 240)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstLetterIsTracedFirstWithABrightHeadAtTheEndOfTheStroke():
        DrawAt(21).
        /* 12 cells of the first stroke of the A (it climbs from the bottom left corner): core cells and a white head, all in the A */
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 40, 58, 22, 30) > 5).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:Flash), 40, 58, 22, 30) >= 3).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TitleHalo), 38, 56, 26, 34) > 5).
        /* and nothing yet in the other eight */
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 64, 50, 256, 50)).
        /* the stroke is short of the apex of the A */
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 48, 58, 6, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLettersFollowOneAnotherEveryTenTicks():
        DrawAt(35).
        /* the S started at tick 30 and the T has not started (it starts at 40) */
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 68, 58, 22, 30) > 5).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 96, 50, 224, 50)).
        /* the A is finished: its crossbar is there and it has no head any more */
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 43, 77, 15, 1) > 5).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:Flash), 40, 58, 22, 30)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenItIsDoneAllNineLettersStandInTheCoreColourWithTheirGlowAndNoHead():
        DEFINE VARIABLE xs AS CHARACTER NO-UNDO INITIAL "40,68,96,124,152,180,208,232,260".
        DEFINE VARIABLE i  AS INTEGER   NO-UNDO.
        DrawAt(110).
        DO i = 1 TO 9:
            Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TitleCore), INTEGER(ENTRY(i, xs)), 58, 21, 29) > 15, SUBSTITUTE("letter &1", i)).
        END.
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:Flash), 0, 0, 320, 240)).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TitleHalo), 0, 50, 320, 45) > 100).
        /* nothing outside the band of the title */
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 0, 0, 320, 56)).
        Assert:Equals(0, CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 0, 90, 320, 150)).
        /* and it stays the same after that */
        DrawAt(500).
        Assert:IsTrue(CellsOf(AsteroidsLook:Colour(Palette:TitleCore), 260, 58, 21, 29) > 15).
    END METHOD.

END CLASS.
