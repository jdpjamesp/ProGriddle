/* Space Invaders in a window. This is the composition root: the only place that builds the concrete classes
   and wires them together.

   Arcade: Space Invaders | The 1978 classic in neon: one shot at a time, crumbling shields, a mystery saucer. | red

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-spaceinvaders.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json), a number of seconds after which the window closes by itself
   (for scripted checks), and a seed for the sparks and the marks on the shields (for scripted checks).

   Settings it reads (all optional):
     spaceinvaders.hiscore   the best score (kept by the game)
     sound.on   false for no sound (default true). The Sound button and the M key switch it, and it is saved
     sound.volume   0 to 100 (default 50)
   The window saves its position as spaceinvaders.window.x and y. Its size is always worked out from the board
   (224 x 256 cells, 3 pixels to a cell where the screen is tall enough, else 2), so there is no empty space round it. The sounds
   are made at start up (InvadersSounds) and played by the Windows sound player; with no sound device the game is silent. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.
USING ProGriddle.UI.Audio.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER           NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER             NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64               NO-UNDO.
DEFINE VARIABLE iCell         AS INTEGER             NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings           NO-UNDO.
DEFINE VARIABLE oGame         AS SpaceInvadersGame   NO-UNDO.
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
       enough (the board is 224 x 256, and the toolbar and the status bar take about 66 more), else 2. The size it
       had when it last closed is not kept, because it would only be a window that had been dragged away from this
       shape: the position is. */
    iCell = (IF Screen:PrimaryScreen:WorkingArea:Height >= 3 * 256 + 66 + 40 THEN 3 ELSE 2).
    oSettings:SetInteger("spaceinvaders.window.width", 224 * iCell).
    oSettings:SetInteger("spaceinvaders.window.height", 256 * iCell + 66).

    /* the clock ticks as often as Windows will let it: the game makes its own 60 frames a second out of the time it is given */
    oClock = NEW WinFormsClock().
    oClock:Interval = 15.
    oGame = SpaceInvadersFactory:Create(NEW SeededRandom(iSeed)).

    /* every cell holds its own colour, and a cell is a pixel of the picture, so there are no lines between them */
    oView = NEW GridView().
    oView:DirectColor = TRUE.
    oView:ShowGridLines = FALSE.

    /* the sound: the cues and loops of the game are found after every redraw and played by the Windows player, from sounds made now */
    oBank = NEW SoundBank().
    InvadersSounds:Fill(oBank).
    oPlayer = NEW WaveOutPlayer(oBank).
    SoundSettings:Apply(oPlayer, oSettings).
    oSound = NEW SoundRenderer(NEW WinFormsGridRenderer(oView, "view"), NEW InvadersCues(), oPlayer).
    oController = NEW RealTimeController(oGame, oSound, oClock).
    oWindow = NEW GameWindow("ProGriddle Space Invaders", oController, oView, NEW SpaceInvadersInput(oGame, oSettings, oPlayer),
                             oClock, oSettings, "spaceinvaders").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    /* the clock runs from the start: the title screen waits for the fire key, and P pauses */
    oController:Start().

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Space Invaders could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
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
