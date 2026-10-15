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
     sound.on         false for no sound (default true). The Sound button and the M key switch it, and it is saved
     sound.volume     0 to 100 (default 50)
   The window also saves the chosen start level as tetris.choice, and its own size and position. The sounds are made at start up
   (TetrisSounds) and played by the Windows sound player; with no sound device the game is silent. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.
USING ProGriddle.UI.Audio.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER          NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER            NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64              NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings          NO-UNDO.
DEFINE VARIABLE oGame         AS TetrisGame         NO-UNDO.
DEFINE VARIABLE oView         AS GridView           NO-UNDO.
DEFINE VARIABLE oPainter      AS TetrisPainter      NO-UNDO.
DEFINE VARIABLE dScale        AS DECIMAL            NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock      NO-UNDO.
DEFINE VARIABLE oController   AS RealTimeController NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow         NO-UNDO.
DEFINE VARIABLE oBank         AS SoundBank          NO-UNDO.
DEFINE VARIABLE oPlayer       AS WaveOutPlayer      NO-UNDO.
DEFINE VARIABLE oSound        AS SoundRenderer      NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).
iSeed = MTIME.
IF NUM-ENTRIES(SESSION:PARAMETER) >= 4 THEN iSeed = INT64(ENTRY(4, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    /* a window the shape of the picture (17 x 20 cells of 16 pixels), as big as the screen has room for, up to 4 pixels to a pixel of the
       picture: the view scales the picture to fill it. The toolbar and the status bar take about 66 more, the title bar and frame
       about 50. */
    dScale = MINIMUM(4.0, MINIMUM((Screen:PrimaryScreen:WorkingArea:Height - 66 - 50) / 320, Screen:PrimaryScreen:WorkingArea:Width / 272)).
    oSettings:SetInteger("tetris.window.width", INTEGER(TRUNCATE(272 * dScale, 0))).
    oSettings:SetInteger("tetris.window.height", INTEGER(TRUNCATE(320 * dScale, 0)) + 66).

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
    oView:FitToWindow = TRUE.
    oPainter = NEW TetrisPainter(NEW WinFormsGridRenderer(oView, "view"), oGame, NEW SeededRandom(iSeed + 1)).

    /* the sound: the cues of the game are found after every redraw and played by the Windows player, from sounds made now */
    oBank = NEW SoundBank().
    TetrisSounds:Fill(oBank).
    oPlayer = NEW WaveOutPlayer(oBank).
    SoundSettings:Apply(oPlayer, oSettings).
    oSound = NEW SoundRenderer(oPainter, NEW TetrisCues(), oPlayer).
    oController = NEW RealTimeController(oGame, oSound, oClock).
    oWindow = NEW GameWindow("ProGriddle Tetris", oController, oView, NEW TetrisInput(oGame, oSettings, oPlayer),
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
        /* the player first (it stops the sounds, which are read from the bank), then the bank */
        IF VALID-OBJECT(oPlayer) THEN oPlayer:Dispose().
        IF VALID-OBJECT(oBank) THEN oBank:Dispose().
    END FINALLY.
END.
QUIT.
