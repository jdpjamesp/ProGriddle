/* The chain that the Snake window is made of, without the window: a game, the painter, the window's renderer and a grid view in
   direct colour. What the painter draws on its canvas must be what the view holds, pixel for pixel, at the board's size, and when
   the board changes size the view follows. (Under prowin -b: the view can be built and read, but nothing ticks.) */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.SnakeWindowChainTests:

    DEFINE PRIVATE VARIABLE mGame    AS SnakeGame    NO-UNDO.
    DEFINE PRIVATE VARIABLE mView    AS GridView     NO-UNDO.
    DEFINE PRIVATE VARIABLE mPainter AS SnakePainter NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildChain():
        mGame = SnakeFactory:Create(10, 10, NEW SeededRandom(1)).
        mGame:Animated = TRUE.
        mView = NEW GridView().
        mView:DirectColor = TRUE.
        mView:ShowGridLines = FALSE.
        mView:FitToWindow = TRUE.
        mPainter = NEW SnakePainter(NEW WinFormsGridRenderer(mView, "view"), mGame, NEW SeededRandom(3)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseChain():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        IF VALID-OBJECT(mView) THEN mView:ReleaseResources().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mPainter = ?.
        mView = ?.
        mGame = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheViewHoldsThePictureOfTheBoardInPixels():
        mPainter:Render(mGame:Grid, mGame).
        /* ten cells of 16 pixels across, and 24 for the strip above the ten rows */
        Assert:Equals(160, mView:Columns).
        Assert:Equals(184, mView:Rows).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPixelOfTheViewIsTheColourThePainterDrew():
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE bad AS INTEGER NO-UNDO.
        mPainter:Render(mGame:Grid, mGame).
        DO y = 0 TO 183:
            DO x = 0 TO 159:
                IF mView:PixelAt(x, y) <> mPainter:Canvas:ColourAt(x, y) THEN bad = bad + 1.
            END.
        END.
        Assert:Equals(0, bad).
        /* the picture, not a blank one: the wall ring and the strip's rule */
        Assert:Equals(SnakeLook:Colour(SnakeTint:RingHigh), mView:PixelAt(80, 24)).
        Assert:Equals(SnakeLook:Colour(SnakeTint:FrameInner), mView:PixelAt(80, 23)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewBoardSizeMakesANewPictureSizeInTheView():
        SnakeFactory:Rebuild(mGame, 30, 20).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(240, mView:Columns).
        Assert:Equals(184, mView:Rows).
    END METHOD.

END CLASS.
