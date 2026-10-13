/* The window builds a drop down for each option of a game that implements IGameOptions, and puts back
   the options saved in the settings. It needs the .NET bridge, so it runs under prowin -b
   (tools/run-tests.ps1 -Gui). Life is the game used, with a fake clock. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Life.*.
USING ProGriddle.UI.Text.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.GameWindowOptionsTests:

    DEFINE PRIVATE VARIABLE mGame     AS LifeGame       NO-UNDO.
    DEFINE PRIVATE VARIABLE mView     AS GridView       NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock    AS FakeClock      NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mWindow   AS GameWindow     NO-UNDO.
    DEFINE PRIVATE VARIABLE mController AS GameController NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildParts():
        mGame = LifeFactory:Create(100, 70, FALSE, LifeRules:Conway(), 0.1).
        mView = NEW GridView().
        mClock = NEW FakeClock().
        mSettings = NEW MemorySettings().
        mController = NEW GameController(mGame, NEW WinFormsGridRenderer(mView, "state"), mClock).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseParts():
        IF VALID-OBJECT(mWindow) THEN mWindow:Dispose().
        mWindow = ?.
        IF VALID-OBJECT(mView) THEN mView:ReleaseResources().
        IF VALID-OBJECT(mController) THEN mController:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* The window under test, built from the parts above. */
    METHOD PRIVATE VOID OpenWindow():
        mWindow = NEW GameWindow("Life", mController, mView, NEW LifeInput(mGame, NEW SeededRandom(1)), mClock, mSettings, "life").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithNothingSavedTheGameKeepsItsOwnRulesAndSize():
        OpenWindow().
        Assert:Equals("B3/S23", mGame:Rules:Notation).
        Assert:Equals(100, mGame:Grid:Width).
        Assert:Equals(70, mGame:Grid:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSavedRuleSetIsPutBack():
        mSettings:SetString("life.ruleset", "HighLife").
        OpenWindow().
        Assert:Equals("B36/S23", mGame:Rules:Notation).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSavedBoardSizeIsPutBack():
        mSettings:SetString("life.size", "50 x 35").
        OpenWindow().
        Assert:Equals(50, mGame:Grid:Width).
        Assert:Equals(35, mGame:Grid:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BothSavedOptionsAreAppliedTogether():
        mSettings:SetString("life.ruleset", "Seeds").
        mSettings:SetString("life.size", "150 x 100").
        OpenWindow().
        Assert:Equals("B2/S", mGame:Rules:Notation).
        Assert:Equals(150, mGame:Grid:Width).
        Assert:Equals(100, mGame:Grid:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASavedValueThatIsNotOnOfferIsIgnored():
        mSettings:SetString("life.ruleset", "Nonsense").
        mSettings:SetString("life.size", "7 x 7").
        OpenWindow().
        Assert:Equals("B3/S23", mGame:Rules:Notation).
        Assert:Equals(100, mGame:Grid:Width).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineInTheTitleShowsTheRestoredRulesAndSize():
        mSettings:SetString("life.ruleset", "Maze").
        mSettings:SetString("life.size", "75 x 50").
        OpenWindow().
        Assert:IsTrue(INDEX(mWindow:Text, "Rules B3/S12345") > 0).
        Assert:IsTrue(INDEX(mWindow:Text, "75 x 50") > 0).
    END METHOD.

END CLASS.
