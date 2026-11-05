/* FOR EACH in a window. This is the composition root: the only place that builds the concrete classes and wires them together.

   Arcade: FOR EACH | Dibby the database drum visits every bit of data in a dark data centre, and the phantoms visit Dibby. | orange
   Category: Arcade

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-foreach.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json), a number of seconds after which the window closes by itself
   (for scripted checks), and a seed for the rolled back phantoms' choices (for scripted checks).

   The picture is the "Night Shift" look of docs/design/foreach-art.md, drawn by ForEachPainter on a canvas of 224 x 288 pixels, which the
   view scales to fill the window (2 pixels to a pixel, 3 where the screen is tall enough, or more). The window is made the shape of it.

   Settings it reads (all optional):
     foreach.hiscore   the best score (kept by the game)
     foreach.speed     50 to 150, the game's speed as a percentage of normal (default 100; the + and - keys change it)
     sound.on          false for no sound (default true). The Sound button and the M key switch it, and it is saved
     sound.volume      0 to 100 (default 50)
   The window also saves its position. The sounds are made at start up (ForEachSounds) and played by the Windows sound player; with no sound
   device the game is silent. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.
USING ProGriddle.UI.Audio.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER           NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER             NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64               NO-UNDO.
DEFINE VARIABLE dScale        AS DECIMAL             NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings           NO-UNDO.
DEFINE VARIABLE oGame         AS ForEachGame         NO-UNDO.
DEFINE VARIABLE oView         AS GridView            NO-UNDO.
DEFINE VARIABLE oPainter      AS ForEachPainter      NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock       NO-UNDO.
DEFINE VARIABLE oController   AS RealTimeController  NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow          NO-UNDO.
DEFINE VARIABLE oBank         AS SoundBank           NO-UNDO.
DEFINE VARIABLE oPlayer       AS WaveOutPlayer       NO-UNDO.
DEFINE VARIABLE oSound        AS SoundRenderer       NO-UNDO.

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
    oGame = ForEachFactory:Create(NEW SeededRandom(iSeed)).

    /* the picture is drawn by the painter on a canvas of its own, and the view shows that canvas in direct colour, with no grid lines, scaled to fit */
    oView = NEW GridView().
    oView:DirectColor = TRUE.
    oView:ShowGridLines = FALSE.
    oView:FitToWindow = TRUE.
    oPainter = NEW ForEachPainter(NEW WinFormsGridRenderer(oView, "view"), oGame).

    /* the sound: the cues and loops of the game are found after every redraw and played by the Windows player, from sounds made now */
    oBank = NEW SoundBank().
    ForEachSounds:Fill(oBank).
    oPlayer = NEW WaveOutPlayer(oBank).
    SoundSettings:Apply(oPlayer, oSettings).
    oSound = NEW SoundRenderer(oPainter, NEW ForEachCues(), oPlayer).
    oController = NEW RealTimeController(oGame, oSound, oClock).

    /* a window the shape of the picture, as big as the screen has room for, up to 4 pixels to a pixel of the picture. The toolbar and the status
       bar take about 66 more, the title bar and frame about 50. */
    dScale = MINIMUM(4.0, MINIMUM((Screen:PrimaryScreen:WorkingArea:Height - 66 - 50) / oPainter:Canvas:Height, Screen:PrimaryScreen:WorkingArea:Width / oPainter:Canvas:Width)).
    oSettings:SetInteger("foreach.window.width", INTEGER(TRUNCATE(oPainter:Canvas:Width * dScale, 0))).
    oSettings:SetInteger("foreach.window.height", INTEGER(TRUNCATE(oPainter:Canvas:Height * dScale, 0)) + 66).

    oWindow = NEW GameWindow("ProGriddle FOR EACH", oController, oView, NEW ForEachInput(oGame, oSettings, oPlayer),
                             oClock, oSettings, "foreach").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    /* the clock runs from the start: the title screen waits for Space, and P pauses */
    oController:Start().

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle FOR EACH could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
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
