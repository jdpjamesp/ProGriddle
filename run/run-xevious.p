/* Xevious in a window. This is the composition root: the only place that builds the concrete classes and wires them
   together.

   Arcade: Xevious | A vertical scrolling shooter: the Zapper for the air, the Blaster for the ground, hidden towers and a mothership. | blue
   Category: Arcade

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-xevious.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json), a number of seconds after which the window closes by itself
   (for scripted checks), and a seed for the waves of enemies (for scripted checks).

   Settings it reads (all optional):
     xevious.hiscore   the best score (kept by the game)
     xevious.speed     20 to 100, the speed as a percentage of the real 60 frames a second (default 80, the + and - keys change it)
     sound.on          false for no sound (default true). The Sound button and the M key switch it, and it is saved
     sound.volume      0 to 100 (default 50)
   The window saves its position as xevious.window.x and y. Its size is worked out from the field (224 x 256 pixels and a strip of
   numbers, 224 x 272 in all, up to 3 pixels to a pixel where the screen is tall enough), and the view scales the picture to fill
   the window. The sounds are made at start up (XeviousSounds) and played by the Windows sound player; with no sound device the
   game is silent. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.
USING ProGriddle.UI.Audio.*.
USING ProGriddle.UI.WinForms.*.

VAR CHARACTER cSettingsFile = "default".
VAR INTEGER iAutoClose.
VAR INT64 iSeed.
VAR DECIMAL dScale.
VAR ISettings oSettings.
VAR XeviousGame oGame.
VAR GridView oView.
VAR XeviousPainter oPainter.
VAR WinFormsClock oClock.
VAR RealTimeController oController.
VAR GameWindow oWindow.
VAR SoundBank oBank.
VAR WaveOutPlayer oPlayer.
VAR SoundRenderer oSound.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).
iSeed = MTIME.
IF NUM-ENTRIES(SESSION:PARAMETER) >= 4 THEN iSeed = INT64(ENTRY(4, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    /* the clock ticks as often as Windows will let it: the game makes its own 60 frames a second out of the time it is given */
    oClock = NEW WinFormsClock().
    oClock:Interval = 15.
    oGame = XeviousFactory:Create(NEW SeededRandom(iSeed)).

    /* the picture is drawn by the painter on a canvas of its own, and the view shows that canvas in direct colour, with no grid lines */
    oView = NEW GridView().
    oView:DirectColor = TRUE.
    oView:ShowGridLines = FALSE.
    oView:FitToWindow = TRUE.
    oPainter = NEW XeviousPainter(NEW WinFormsGridRenderer(oView, "view"), oGame).

    /* the sound: the cues and loops of the game are found after every redraw and played by the Windows player, from sounds made now */
    oBank = NEW SoundBank().
    XeviousSounds:Fill(oBank).
    oPlayer = NEW WaveOutPlayer(oBank).
    SoundSettings:Apply(oPlayer, oSettings).
    oSound = NEW SoundRenderer(oPainter, NEW XeviousCues(), oPlayer).
    oController = NEW RealTimeController(oGame, oSound, oClock).

    /* a window the shape of the picture, as big as the screen has room for, up to 3 pixels to a pixel of the picture. The toolbar and
       the status bar take about 66 more, the title bar and frame about 50. The size it had when it last closed is not kept, because
       it would only be a window that had been dragged away from this shape: the position is. */
    dScale = MINIMUM(3.0, MINIMUM((Screen:PrimaryScreen:WorkingArea:Height - 66 - 50) / oPainter:Canvas:Height, Screen:PrimaryScreen:WorkingArea:Width / oPainter:Canvas:Width)).
    oSettings:SetInteger("xevious.window.width", INTEGER(TRUNCATE(oPainter:Canvas:Width * dScale, 0))).
    oSettings:SetInteger("xevious.window.height", INTEGER(TRUNCATE(oPainter:Canvas:Height * dScale, 0)) + 66).

    oWindow = NEW GameWindow("ProGriddle Xevious", oController, oView, NEW XeviousInput(oGame, oSettings, oPlayer),
                             oClock, oSettings, "xevious").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    /* the clock runs from the start: the title screen waits for a fire key, and P pauses */
    oController:Start().

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Xevious could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
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
