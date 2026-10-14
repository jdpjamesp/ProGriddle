/* What a Asteroids window gets from the game's input: the status line and the members it leaves empty. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsInputTests:

    DEFINE PRIVATE VARIABLE mGame  AS AsteroidsGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput AS AsteroidsInput NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mGame = NEW AsteroidsGame(NEW Grid(NEW ArrayStore(4, 3, "state"))).
        mInput = NEW AsteroidsInput(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineShowsTheGenerationAndTheLitCell():
        Assert:Equals("Generation 0   Lit cell 0", mInput:StatusText).
        mGame:Step().
        Assert:Equals("Generation 1   Lit cell 1", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoPickerNoCommandsNoBannerAndNoExtraScreen():
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        Assert:Equals("", mInput:CommandNames).
        Assert:Equals("", mInput:BannerText).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
        mInput:Choice = "anything".
        Assert:Equals("", mInput:Choice).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNothingToSayAndNoKeysAreUsed():
        Assert:Equals("", mInput:TakeNotice()).
        Assert:IsFalse(mInput:HandleKey("Space")).
        mInput:ReleaseKey("Space").
        mInput:ReleaseKey("").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClicksChangeNothing():
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(1, 1).
        mInput:TertiaryAction(1, 1).
        Assert:Equals(0, mGame:Position).
        Assert:Equals(1, mGame:Grid:Store:CountOf(1, 1)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownCommandThrows():
        mInput:Perform("Cheat").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheInputNeedsAGame():
        DEFINE VARIABLE i AS AsteroidsInput NO-UNDO.
        i = NEW AsteroidsInput(?).
    END METHOD.

END CLASS.
