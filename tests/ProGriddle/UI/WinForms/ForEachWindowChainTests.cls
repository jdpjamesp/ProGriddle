/* The chain that the FOR EACH window is made of, without the window: a game, the painter, the sound renderer, the window's renderer and a
   grid view in direct colour. What the painter draws on its canvas must be what the view holds, pixel for pixel, at the picture's size,
   and a long game with random keys, played frame by frame through all of it (the picture and the cues of every frame), must run to the
   end without an error. (Under prowin -b: the view can be built and read, but nothing ticks.) A class can only hold about 32000 bytes of
   variables and a write past that fails only after a game has gone on a while, which is what the long game is for. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.ForEachWindowChainTests:

    VAR PRIVATE ForEachGame mGame.
    VAR PRIVATE GridView mView.
    VAR PRIVATE ForEachPainter mPainter.
    VAR PRIVATE SoundRenderer mSound.
    VAR PRIVATE ForEachInput mInput.

    @Setup.
    METHOD PUBLIC VOID BuildChain():
        mGame = ForEachFactory:Create(NEW SeededRandom(1)).
        mView = NEW GridView().
        mView:DirectColor = TRUE.
        mView:ShowGridLines = FALSE.
        mView:FitToWindow = TRUE.
        mPainter = NEW ForEachPainter(NEW WinFormsGridRenderer(mView, "view"), mGame).
        mSound = NEW SoundRenderer(mPainter, NEW ForEachCues(), NEW NullSoundPlayer()).
        mInput = NEW ForEachInput(mGame, NEW MemorySettings()).
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
    METHOD PUBLIC VOID TheViewHoldsThePictureOf224By288Pixels():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(224, mView:Columns).
        Assert:Equals(288, mView:Rows).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPixelOfTheViewIsTheColourThePainterDrew():
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER bad.
        mInput:HandleKey("Space").
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        mPainter:Render(mGame:Grid, mGame).
        DO y = 0 TO 287:
            DO x = 0 TO 223:
                IF mView:PixelAt(x, y) <> mPainter:Canvas:ColourAt(x, y) THEN bad = bad + 1.
            END.
        END.
        Assert:Equals(0, bad).
        /* the picture, not a blank one: the first lane's bit and the border's wall line */
        Assert:Equals(ForEachLook:Colour(ForEachTint:Bit), mView:PixelAt(8 + 3, 24 + 8 + 3)).
        Assert:IsTrue(mView:PixelAt(4, 40) <> ForEachLook:Colour(ForEachTint:Floor)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALongGameWithRandomKeysPlaysThroughTheRealRendererAndTheSoundWithoutAnError():
        VAR INTEGER n.
        VAR SeededRandom random.
        VAR CHARACTER ways = "Up,Left,Down,Right".
        VAR INTEGER ended.
        random = NEW SeededRandom(11).
        mInput:HandleKey("Space").
        DO n = 1 TO 12000:
            IF n MODULO 25 = 0 THEN mInput:HandleKey(ENTRY(random:NextInt(4) + 1, ways)).
            /* a phantom now and then is rolled back, an item shown and the level made short, so the whole game is seen */
            IF n MODULO 900 = 0 THEN mGame:Rollback().
            IF n MODULO 1700 = 0 THEN mGame:ShowItem().
            IF n MODULO 3000 = 0 THEN mGame:EatBits(40).
            mGame:Advance().
            IF n MODULO 3 = 0 THEN mSound:Render(mGame:Grid, mGame).
            IF mGame:Phase = ForEachPhase:GameOver THEN DO:
                ended = ended + 1.
                mInput:HandleKey("Space").
            END.
        END.
        mSound:Render(mGame:Grid, mGame).
        Assert:IsTrue(mGame:FrameCount >= 12000).
        Assert:IsTrue(mGame:Score >= 0).
    END METHOD.

END CLASS.
