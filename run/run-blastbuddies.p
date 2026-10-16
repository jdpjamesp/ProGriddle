/* Blast Buddies in a window. This is the composition root: the only place that builds the concrete classes and wires them together.

   Arcade: Blast Buddies | Turn based artillery on ground that blows away. Aim, charge and fire a bazooka, or play the computer. | orange

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -l 1024 -p tools/launch.p -param "run/run-blastbuddies.p"
   Optional entries after the program name: the settings file ("default" for %APPDATA%\ProGriddle\settings.json), a number of
   seconds after which the window closes by itself (for scripted checks), and a seed for the land, the wind and the computer (for
   scripted checks).

   The picture is the "Sunny Side" look of docs/design/blast-buddies-art.md, drawn by BlastBuddiesPainter on the 384 x 240 canvas of
   the game. The window is made the shape of the picture and the view scales the picture to fill it.

   Settings it reads (all optional; the window sets them from its lists and saves them when it closes):
     blastbuddies.teams      2 to 4 (default 2)
     blastbuddies.buddies    buddies in each team, 3 or 4 (default 3)
     blastbuddies.computer   None, or 1 to 3 teams at the end played by the computer (default 1)
     blastbuddies.skill      Easy, Normal or Hard (default Normal)
     blastbuddies.theme      Meadow, Canyon, Candy or Random (default Meadow)
     blastbuddies.speed      the speed as a percentage of the real 60 frames a second (default 100, the + and - keys change it)
     sound.on                false for no sound (default true). The Sound button and the M key switch it, and it is saved
     sound.volume            0 to 100 (default 50)
   The window also saves its own size and position. The sounds are made at start up (BuddySounds) and played by the Windows sound
   player; with no sound device the game is silent. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.
USING ProGriddle.UI.Audio.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER           NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER             NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64               NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings           NO-UNDO.
DEFINE VARIABLE oGame         AS BlastBuddiesGame    NO-UNDO.
DEFINE VARIABLE oBrain        AS SimulatingBrain     NO-UNDO.
DEFINE VARIABLE oView         AS GridView            NO-UNDO.
DEFINE VARIABLE oPainter      AS BlastBuddiesPainter NO-UNDO.
DEFINE VARIABLE dScale        AS DECIMAL             NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock       NO-UNDO.
DEFINE VARIABLE oController   AS RealTimeController  NO-UNDO.
DEFINE VARIABLE oBank         AS SoundBank           NO-UNDO.
DEFINE VARIABLE oPlayer       AS WaveOutPlayer       NO-UNDO.
DEFINE VARIABLE oSound        AS SoundRenderer       NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow          NO-UNDO.

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
    oGame = BlastBuddiesFactory:CreateWithTitle(NEW SeededRandom(iSeed), BuddySetup:Default()).
    oBrain = NEW SimulatingBrain(NEW SeededRandom(iSeed + 2), BuddySkill:Normal).
    oGame:Brain = oBrain.

    /* every cell holds its own colour, and a cell is a pixel of the picture, so there are no lines between them */
    oView = NEW GridView().
    oView:DirectColor = TRUE.
    oView:ShowGridLines = FALSE.
    oView:FitToWindow = TRUE.
    oPainter = NEW BlastBuddiesPainter(NEW WinFormsGridRenderer(oView, "view"), oGame, NEW SeededRandom(iSeed + 1)).

    /* the sound: the cues and the loop of the game are found after every redraw and played by the Windows player, from sounds made now */
    oBank = NEW SoundBank().
    BuddySounds:Fill(oBank).
    oPlayer = NEW WaveOutPlayer(oBank).
    SoundSettings:Apply(oPlayer, oSettings).
    oSound = NEW SoundRenderer(oPainter, NEW BuddyCues(), oPlayer).
    oController = NEW RealTimeController(oGame, oSound, oClock).

    /* a window the shape of the picture, as big as the screen has room for, up to 3 pixels to a pixel of the picture. The toolbar and
       the status bar take about 66 more, the title bar and frame about 50. */
    dScale = MINIMUM(3.0, MINIMUM((Screen:PrimaryScreen:WorkingArea:Height - 66 - 50) / 240, Screen:PrimaryScreen:WorkingArea:Width / 384)).
    oSettings:SetInteger("blastbuddies.window.width", INTEGER(TRUNCATE(384 * dScale, 0))).
    oSettings:SetInteger("blastbuddies.window.height", INTEGER(TRUNCATE(240 * dScale, 0)) + 66).

    oWindow = NEW GameWindow("ProGriddle Blast Buddies", oController, oView, NEW BlastBuddiesInput(oGame, oSettings, oPlayer),
                             oClock, oSettings, "blastbuddies").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    /* the clock runs from the start: the title waits for Space, then the buddies arrive and the first turn is the person's. P pauses, F2 starts again */
    oController:Start().

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Blast Buddies could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
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
