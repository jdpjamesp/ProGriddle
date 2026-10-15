/* Asteroids in a window. This is the composition root: the only place that builds the concrete classes
   and wires them together.

   Arcade: Asteroids | Thrust, drift and shoot the rocks into smaller rocks while saucers hunt you. | blue

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-asteroids.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json), a number of seconds after which the window closes by itself
   (for scripted checks), and a seed for the rocks, the saucers and the dust (for scripted checks).

   Settings it reads (all optional):
     asteroids.hiscore   the best score (kept by the game)
     sound.on   false for no sound (default true). The Sound button and the M key switch it, and it is saved
     sound.volume   0 to 100 (default 50)
   The window saves its position as asteroids.window.x and y. Its size is always worked out from the board
   (320 x 240 cells, 3 pixels to a cell where the screen is tall enough, else 2), so there is no empty space round it. The sounds
   are made at start up (AsteroidsSounds) and played by the Windows sound player; with no sound device the game is silent. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.
USING ProGriddle.UI.Audio.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER           NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER             NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64               NO-UNDO.
DEFINE VARIABLE iCell         AS INTEGER             NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings           NO-UNDO.
DEFINE VARIABLE oGame         AS AsteroidsGame      NO-UNDO.
DEFINE VARIABLE oView         AS GridView            NO-UNDO.
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

    /* a window the shape of the board, so there is no dead space round it: 3 pixels to a cell when the screen is tall
       enough (the board is 320 x 240, and the toolbar and the status bar take about 66 more), else 2. The size it
       had when it last closed is not kept, because it would only be a window that had been dragged away from this
       shape: the position is. */
    iCell = (IF Screen:PrimaryScreen:WorkingArea:Height >= 3 * 240 + 66 + 40 THEN 3 ELSE 2).
    oSettings:SetInteger("asteroids.window.width", 320 * iCell).
    oSettings:SetInteger("asteroids.window.height", 240 * iCell + 66).

    /* the clock ticks as often as Windows will let it: the game makes its own 60 frames a second out of the time it is given */
    oClock = NEW WinFormsClock().
    oClock:Interval = 15.
    oGame = AsteroidsFactory:Create(NEW SeededRandom(iSeed)).

    /* every cell holds its own colour, and a cell is a pixel of the picture, so there are no lines between them */
    oView = NEW GridView().
    oView:DirectColor = TRUE.
    oView:ShowGridLines = FALSE.

    /* the sound: the cues and loops of the game are found after every redraw and played by the Windows player, from sounds made now */
    oBank = NEW SoundBank().
    AsteroidsSounds:Fill(oBank).
    oPlayer = NEW WaveOutPlayer(oBank).
    SoundSettings:Apply(oPlayer, oSettings).
    oSound = NEW SoundRenderer(NEW WinFormsGridRenderer(oView, "view"), NEW AsteroidsCues(), oPlayer).
    oController = NEW RealTimeController(oGame, oSound, oClock).
    oWindow = NEW GameWindow("ProGriddle Asteroids", oController, oView, NEW AsteroidsInput(oGame, oSettings, oPlayer),
                             oClock, oSettings, "asteroids").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    /* the clock runs from the start: the title screen waits for the fire key, and P pauses */
    oController:Start().

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Asteroids could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
        /* the player first (it stops the sounds, which are read from the bank), then the bank */
        IF VALID-OBJECT(oPlayer) THEN oPlayer:Dispose().
        IF VALID-OBJECT(oBank) THEN oBank:Dispose().
    END FINALLY.
END.
QUIT.
