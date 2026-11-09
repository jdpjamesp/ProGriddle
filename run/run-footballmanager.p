/* Football Manager in a window: run a small club from the bottom division, a week at a time. This is the composition root: the only place
   that builds the concrete classes and wires them together.

   Arcade: Football Manager | Take a small club up from the fourth division: pick the team, watch the highlights, mind the bank. | green
   Category: Strategy

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -l 2048 -p tools/launch.p -param "run/run-footballmanager.p"
   Optional entries after the program name: the settings file ("default" for %APPDATA%\ProGriddle\settings.json), a number of seconds after
   which the window closes by itself (for scripted checks), and a seed for the game (for scripted checks).

   The picture is drawn by FootballPainter on a pixel canvas of 320 x 240, and the window is made the shape of it, up to 3 pixels to a pixel
   where the screen is big enough. The clock ticks only to run the match highlights; everything else waits for a key (see FootballInput
   for the keys of each screen). The window saves its own position. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.
USING ProGriddle.UI.WinForms.*.

VAR CHARACTER cSettingsFile = "default".
VAR INTEGER iAutoClose.
VAR INT64 iSeed.
VAR DECIMAL dScale.
VAR ISettings oSettings.
VAR FootballGame oGame.
VAR FootballUi oUi.
VAR GridView oView.
VAR FootballPainter oPainter.
VAR WinFormsClock oClock.
VAR RealTimeController oController.
VAR GameWindow oWindow.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).
iSeed = MTIME.
IF NUM-ENTRIES(SESSION:PARAMETER) >= 4 THEN iSeed = INT64(ENTRY(4, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    /* the clock ticks about 30 times a second: the highlights are a function of the milliseconds it gives them */
    oClock = NEW WinFormsClock().
    oClock:Interval = 30.
    oGame = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(iSeed)).
    oUi = NEW FootballUi().

    /* the picture is drawn by the painter on a canvas of its own, and the view shows that canvas in direct colour, with no grid lines */
    oView = NEW GridView().
    oView:DirectColor = TRUE.
    oView:ShowGridLines = FALSE.
    oView:FitToWindow = TRUE.
    oPainter = NEW FootballPainter(NEW WinFormsGridRenderer(oView, "view"), oGame, oUi).
    oController = NEW RealTimeController(oGame, oPainter, oClock).

    /* a window the shape of the picture, as big as the screen has room for, up to 3 pixels to a pixel. The toolbar and the status bar take
       about 66 more, the title bar and frame about 50. */
    dScale = MINIMUM(3.0, MINIMUM((Screen:PrimaryScreen:WorkingArea:Height - 66 - 50) / oPainter:Canvas:Height, Screen:PrimaryScreen:WorkingArea:Width / oPainter:Canvas:Width)).
    oSettings:SetInteger("footballmanager.window.width", INTEGER(TRUNCATE(oPainter:Canvas:Width * dScale, 0))).
    oSettings:SetInteger("footballmanager.window.height", INTEGER(TRUNCATE(oPainter:Canvas:Height * dScale, 0)) + 66).

    oWindow = NEW GameWindow("ProGriddle Football Manager", oController, oView, NEW FootballInput(oGame, oUi), oClock, oSettings, "footballmanager").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    /* the clock runs from the start (it only moves the match highlights) */
    oController:Start().

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Football Manager could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oPainter) THEN oPainter:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
    END FINALLY.
END.
QUIT.
