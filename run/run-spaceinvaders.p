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
   The window also saves its own size and position, as spaceinvaders.window.width and the like. The first
   time it opens it asks for a window tall enough for 3 pixel cells (about 860 high), but a window is never
   taller or wider than the screen's working area, so on a smaller screen the cells come out smaller. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER           NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER             NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64               NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings           NO-UNDO.
DEFINE VARIABLE oGame         AS SpaceInvadersGame   NO-UNDO.
DEFINE VARIABLE oView         AS GridView            NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock       NO-UNDO.
DEFINE VARIABLE oController   AS RealTimeController  NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow          NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).
iSeed = MTIME.
IF NUM-ENTRIES(SESSION:PARAMETER) >= 4 THEN iSeed = INT64(ENTRY(4, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    /* a window of its own shape the first time: tall, for a tall board */
    IF NOT oSettings:Has("spaceinvaders.window.width") THEN DO:
        oSettings:SetInteger("spaceinvaders.window.width", 700).
        oSettings:SetInteger("spaceinvaders.window.height", 860).
    END.

    /* the clock ticks as often as Windows will let it: the game makes its own 60 frames a second out of the time it is given */
    oClock = NEW WinFormsClock().
    oClock:Interval = 15.
    oGame = SpaceInvadersFactory:Create(NEW SeededRandom(iSeed)).

    /* every cell holds its own colour, and a cell is a pixel of the picture, so there are no lines between them */
    oView = NEW GridView().
    oView:DirectColor = TRUE.
    oView:ShowGridLines = FALSE.
    oController = NEW RealTimeController(oGame, NEW WinFormsGridRenderer(oView, "view"), oClock).
    oWindow = NEW GameWindow("ProGriddle Space Invaders", oController, oView, NEW SpaceInvadersInput(oGame, oSettings),
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
    END FINALLY.
END.
QUIT.
