/* Minesweeper in a window, with the rules of the classic Windows game. This is the composition
   root: the only place that builds the concrete classes and wires them together.

   Run it under prowin from the repository root:
     prowin.exe -p tools/launch.p -param "run/run-minesweeper.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json) and a number of seconds after which the window closes
   by itself (for scripted checks), and then a seed for the mines (for scripted checks).

   Settings it reads (all optional, edit the file while the program is closed):
     minesweeper.choice         Beginner, Intermediate, Expert or Custom (saved when the window closes)
     minesweeper.marks          true for question marks on the right click cycle (default true)
     minesweeper.customWidth    width of a Custom game, 9 to 30 (default 9)
     minesweeper.customHeight   height of a Custom game, 9 to 24 (default 9)
     minesweeper.customMines    mines in a Custom game, 10 to (width - 1) * (height - 1) (default 10)
     minesweeper.best.beginner, .intermediate, .expert   best times in seconds (kept by the game)
   The window also saves its own size and position. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Minesweeper.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER        NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER          NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64            NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings        NO-UNDO.
DEFINE VARIABLE oGame         AS MinesweeperGame  NO-UNDO.
DEFINE VARIABLE oView         AS GridView         NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock    NO-UNDO.
DEFINE VARIABLE oController   AS TurnController   NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow       NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).
iSeed = MTIME.
IF NUM-ENTRIES(SESSION:PARAMETER) >= 4 THEN iSeed = INT64(ENTRY(4, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    /* the game starts as Beginner. The window then applies the saved level, which builds the right board */
    oClock = NEW WinFormsClock().
    oClock:Interval = 1000.
    oGame = MinesweeperFactory:Create(MinesweeperLevels:WidthOf("Beginner"), MinesweeperLevels:HeightOf("Beginner"),
                                      MinesweeperLevels:MinesOf("Beginner"), NEW SeededRandom(iSeed), oClock).

    oView = NEW GridView().
    oView:SetPalette(MinesweeperLook:Palette()).
    oView:SetGlyphs(MinesweeperLook:Glyphs(), MinesweeperLook:GlyphColors()).
    oController = NEW TurnController(oGame, NEW WinFormsGridRenderer(oView, "view")).
    oWindow = NEW GameWindow("ProGriddle Minesweeper", oController, oView, NEW MinesweeperInput(oGame, oSettings),
                             oClock, oSettings, "minesweeper").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Minesweeper could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
    END FINALLY.
END.
QUIT.
