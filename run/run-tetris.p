/* Tetris in a window. This is the composition root: the only place that builds the concrete classes and
   wires them together.

   Run it under prowin from the repository root:
     prowin.exe -p tools/launch.p -param "run/run-tetris.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json), a number of seconds after which the window closes by itself
   (for scripted checks), and a seed for the pieces (for scripted checks).

   Settings it reads (all optional):
     tetris.ghost     true to show the ghost piece, where the piece will land (default true)
   The window also saves the chosen start level as tetris.choice, and its own size and position. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER          NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER            NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64              NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings          NO-UNDO.
DEFINE VARIABLE oGame         AS TetrisGame         NO-UNDO.
DEFINE VARIABLE oView         AS GridView           NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock      NO-UNDO.
DEFINE VARIABLE oController   AS RealTimeController NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow         NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).
iSeed = MTIME.
IF NUM-ENTRIES(SESSION:PARAMETER) >= 4 THEN iSeed = INT64(ENTRY(4, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    /* a tick every 30 ms is smooth enough for 20 rows and light enough to redraw only when something moved */
    oClock = NEW WinFormsClock().
    oClock:Interval = 30.
    oGame = TetrisFactory:Create(NEW SeededRandom(iSeed)).

    oView = NEW GridView().
    oView:SetPalette(TetrisLook:Palette()).
    oController = NEW RealTimeController(oGame, NEW WinFormsGridRenderer(oView, "view"), oClock).
    oWindow = NEW GameWindow("ProGriddle Tetris", oController, oView, NEW TetrisInput(oGame, oSettings),
                             oClock, oSettings, "tetris").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    /* the game begins as soon as the window opens: P pauses, F2 starts again */
    oController:Start().

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Tetris could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
    END FINALLY.
END.
QUIT.
