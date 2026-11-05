/* Rogue in a window: an ASCII dungeon crawler after the 1980 original. This is the composition root: the only place that builds the
   concrete classes and wires them together.

   Arcade: Rogue | Twenty six levels of rooms and corridors, unknown potions and scrolls, and the Amulet of Yendor at the bottom. | green
   Category: Adventure

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-rogue.p"
   Optional entries after the program name: the settings file ("default" for %APPDATA%\ProGriddle\settings.json), a number of seconds
   after which the window closes by itself (for scripted checks), and a seed for the dungeon (for scripted checks).

   The picture is drawn by RoguePainter on a pixel canvas of 80 x 24 characters, and the window is made the shape of it, up to 2 pixels to
   a pixel where the screen is big enough.

   Settings it reads (all optional, edit the file while the program is closed):
     rogue.keys     vi (the default: h j k l y u b n move) or numpad (the number pad and the arrow keys). The Keys button changes it
     rogue.scores   the ten best games (kept by the game)
   The window also saves its own position. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING System.Windows.Forms.Screen FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER        NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER          NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64            NO-UNDO.
DEFINE VARIABLE dScale        AS DECIMAL          NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings        NO-UNDO.
DEFINE VARIABLE oGame         AS RogueGame        NO-UNDO.
DEFINE VARIABLE oScores       AS RogueScores      NO-UNDO.
DEFINE VARIABLE oView         AS GridView         NO-UNDO.
DEFINE VARIABLE oPainter      AS RoguePainter     NO-UNDO.
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
    oScores = NEW RogueScores(oSettings).

    /* the game has no clock of its own: the window only needs one for its own timers */
    oClock = NEW WinFormsClock().
    oClock:Interval = 1000.
    oGame = NEW RogueGame(LevelMap:CreateGrid(), NEW SeededRandom(iSeed)).
    oGame:Initialise().

    /* the picture is drawn by the painter on a canvas of its own, and the view shows that canvas in direct colour, with no grid lines */
    oView = NEW GridView().
    oView:DirectColor = TRUE.
    oView:ShowGridLines = FALSE.
    oView:FitToWindow = TRUE.
    oPainter = NEW RoguePainter(NEW WinFormsGridRenderer(oView, "view"), oGame, oScores).
    oController = NEW TurnController(oGame, oPainter).

    /* a window the shape of the picture, as big as the screen has room for, up to 2 pixels to a pixel. The toolbar and the status bar take
       about 66 more, the title bar and frame about 50. */
    dScale = MINIMUM(2.0, MINIMUM((Screen:PrimaryScreen:WorkingArea:Height - 66 - 50) / oPainter:Canvas:Height, Screen:PrimaryScreen:WorkingArea:Width / oPainter:Canvas:Width)).
    oSettings:SetInteger("rogue.window.width", INTEGER(TRUNCATE(oPainter:Canvas:Width * dScale, 0))).
    oSettings:SetInteger("rogue.window.height", INTEGER(TRUNCATE(oPainter:Canvas:Height * dScale, 0)) + 66).

    oWindow = NEW GameWindow("ProGriddle Rogue", oController, oView, NEW RogueInput(oGame, oSettings, oScores), oClock, oSettings, "rogue").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Rogue could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oPainter) THEN oPainter:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
    END FINALLY.
END.
QUIT.
