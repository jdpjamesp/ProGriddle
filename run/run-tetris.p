/* Tetris in a window. This is the composition root: the only place that builds the concrete classes and
   wires them together.

   Arcade: Tetris | Falling blocks on a timer. Seven bag pieces, ghost piece, levels and a high score list. | purple

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-tetris.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json), a number of seconds after which the window closes by itself
   (for scripted checks), and a seed for the pieces (for scripted checks).

   Settings it reads (all optional):
     tetris.ghost     true to show the ghost piece, where the piece will land (default true)
   The window also saves the chosen start level as tetris.choice, and its own size and position. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
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
DEFINE VARIABLE oPainter      AS TetrisPainter      NO-UNDO.
DEFINE VARIABLE iCell         AS INTEGER            NO-UNDO.
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

    /* a window the shape of the picture (17 x 20 cells of 16 pixels), so there is no dead space round it: 3 pixels to a pixel of the
       picture when the screen is tall enough, else 2. The toolbar and the status bar take about 66 more. */
    iCell = (IF Screen:PrimaryScreen:WorkingArea:Height >= 3 * 320 + 66 + 40 THEN 3 ELSE 2).
    oSettings:SetInteger("tetris.window.width", 272 * iCell).
    oSettings:SetInteger("tetris.window.height", 320 * iCell + 66).

    /* a tick every 20 ms is smooth enough for the effects, and the picture is redrawn only when something moved or is moving */
    oClock = NEW WinFormsClock().
    oClock:Interval = 20.
    oGame = TetrisFactory:Create(NEW SeededRandom(iSeed)).
    /* the effects: the game keeps their clocks, and a line clear holds the rows for a third of a second so it can be shown */
    oGame:Animated = TRUE.
    oGame:ClearDelayMs = 300.

    /* the picture is drawn by the painter on a canvas of its own, and the view shows that canvas in direct colour, with no grid lines */
    oView = NEW GridView().
    oView:DirectColor = TRUE.
    oView:ShowGridLines = FALSE.
    oPainter = NEW TetrisPainter(NEW WinFormsGridRenderer(oView, "view"), oGame).
    oController = NEW RealTimeController(oGame, oPainter, oClock).
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
        IF VALID-OBJECT(oPainter) THEN oPainter:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
    END FINALLY.
END.
QUIT.
