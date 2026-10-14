/* Each game keeps the size of its own window, falling back to the last window to close. The window needs
   the .NET bridge, so this runs under prowin -b (tools/run-tests.ps1 -Gui). Life is the game used, with a
   fake clock. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Life.*.
USING ProGriddle.UI.Text.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.GameWindowSizeTests:

    DEFINE PRIVATE VARIABLE mGame       AS LifeGame        NO-UNDO.
    DEFINE PRIVATE VARIABLE mView       AS GridView        NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock      AS FakeClock       NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings   AS MemorySettings  NO-UNDO.
    DEFINE PRIVATE VARIABLE mWindow     AS GameWindow      NO-UNDO.
    DEFINE PRIVATE VARIABLE mController AS GameController  NO-UNDO.

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

    METHOD PRIVATE VOID OpenWindow():
        mWindow = NEW GameWindow("Life", mController, mView, NEW LifeInput(mGame, NEW SeededRandom(1)), mClock, mSettings, "life").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithNothingSavedTheWindowIsTheDefaultSize():
        OpenWindow().
        Assert:Equals(1000, mWindow:ClientSize:Width).
        Assert:Equals(760, mWindow:ClientSize:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameWithNoWindowOfItsOwnOpensAtTheLastWindowToClose():
        mSettings:SetInteger("window.width", 900).
        mSettings:SetInteger("window.height", 650).
        OpenWindow().
        Assert:Equals(900, mWindow:ClientSize:Width).
        Assert:Equals(650, mWindow:ClientSize:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGamesOwnWindowSizeBeatsTheLastWindowsSize():
        mSettings:SetInteger("window.width", 900).
        mSettings:SetInteger("window.height", 650).
        mSettings:SetInteger("life.window.width", 700).
        mSettings:SetInteger("life.window.height", 600).
        OpenWindow().
        Assert:Equals(700, mWindow:ClientSize:Width).
        Assert:Equals(600, mWindow:ClientSize:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnotherGamesWindowSizeIsNotUsed():
        mSettings:SetInteger("snake.window.width", 500).
        mSettings:SetInteger("snake.window.height", 500).
        OpenWindow().
        Assert:Equals(1000, mWindow:ClientSize:Width).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SizesOutsideTheLimitsAreBroughtBackInside():
        mSettings:SetInteger("life.window.width", 10).
        mSettings:SetInteger("life.window.height", 99999).
        OpenWindow().
        Assert:Equals(400, mWindow:ClientSize:Width).
        Assert:IsTrue(mWindow:ClientSize:Height > 300 AND mWindow:ClientSize:Height <= 3000).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWindowIsNeverOpenedTallerOrWiderThanTheScreensWorkingArea():
        mSettings:SetInteger("life.window.width", 4000).
        mSettings:SetInteger("life.window.height", 3000).
        OpenWindow().
        Assert:IsTrue(mWindow:Height <= Screen:PrimaryScreen:WorkingArea:Height, "height " + STRING(mWindow:Height) + " client " + STRING(mWindow:ClientSize:Height) + " wa " + STRING(Screen:PrimaryScreen:WorkingArea:Height)).
        Assert:IsTrue(mWindow:Width <= Screen:PrimaryScreen:WorkingArea:Width, "width " + STRING(mWindow:Width)).
    END METHOD.

END CLASS.
