/* The chain that the Tetris window is made of, without the window: a game, the painter, the window's renderer and a grid view in
   direct colour. What the painter draws on its canvas must be what the view holds, pixel for pixel, so the real window shows
   the Lantern Glass picture. (Under prowin -b: the view can be built and read, but nothing ticks.) */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.TetrisWindowChainTests:

    DEFINE PRIVATE VARIABLE mGame    AS TetrisGame    NO-UNDO.
    DEFINE PRIVATE VARIABLE mView    AS GridView      NO-UNDO.
    DEFINE PRIVATE VARIABLE mPainter AS TetrisPainter NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildChain():
        mGame = TetrisFactory:Create(NEW SeededRandom(1)).
        mGame:StartWith("I,O,T,S,Z,J,L").
        mView = NEW GridView().
        mView:DirectColor = TRUE.
        mView:ShowGridLines = FALSE.
        mPainter = NEW TetrisPainter(NEW WinFormsGridRenderer(mView, "view"), mGame, NEW SeededRandom(3)).
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
    METHOD PUBLIC VOID TheViewHoldsTheSeventeenByTwentyCellsOfSixteenPixelsThePainterDrew():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(272, mView:Columns).
        Assert:Equals(320, mView:Rows).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPixelOfTheViewIsTheColourThePainterDrew():
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE bad AS INTEGER NO-UNDO.
        mGame:LoadLocked("T........./IIIIIII.II").
        mPainter:Render(mGame:Grid, mGame).
        DO y = 0 TO 319:
            DO x = 0 TO 271:
                IF mView:PixelAt(x, y) <> mPainter:Canvas:ColourAt(x, y) THEN bad = bad + 1.
            END.
        END.
        Assert:Equals(0, bad).
        /* and it is the picture, not a blank one: the corner of the T block, the divider and a lit card edge */
        Assert:Equals(ColourMath:FromHex(ENTRY(5, TetrisLook:Tones(3))), mView:PixelAt(0, 16 * 18)).
        Assert:Equals(TetrisLook:Colour(Tint:FrameOuter), mView:PixelAt(175, 50)).
    END METHOD.

END CLASS.
