/* Asteroids in a window. This is the composition root: the only place that builds the concrete
   classes and wires them together.

   Arcade: Asteroids | Fly, thrust and drift, and shoot the rocks into smaller rocks while saucers hunt you.

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-asteroids.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json) and a number of seconds after which the window closes by
   itself (for scripted checks).

   Settings it reads (all optional):
     asteroids.width, asteroids.height   board size in cells, 5 to 200 (default 30 x 20)
   The window also saves its own size, position and speed. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER       NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER         NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings       NO-UNDO.
DEFINE VARIABLE oGame         AS AsteroidsGame    NO-UNDO.
DEFINE VARIABLE oView         AS GridView        NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock   NO-UNDO.
DEFINE VARIABLE oController   AS GameController  NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow      NO-UNDO.
DEFINE VARIABLE iWidth        AS INTEGER         NO-UNDO.
DEFINE VARIABLE iHeight       AS INTEGER         NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    iWidth  = MAXIMUM(5, MINIMUM(200, oSettings:GetInteger("asteroids.width", 30))).
    iHeight = MAXIMUM(5, MINIMUM(200, oSettings:GetInteger("asteroids.height", 20))).

    /* the grid: a store with one layer called state, wrapped in a Grid */
    oGame = NEW AsteroidsGame(NEW Grid(NEW ArrayStore(iWidth, iHeight, "state"))).

    oView = NEW GridView().
    /* the palette maps cell values to colours in order: 0 is dark, 1 is gold */
    oView:SetPalette("1B1F24,F2C14E").
    oClock = NEW WinFormsClock().
    oController = NEW GameController(oGame, NEW WinFormsGridRenderer(oView, "state"), oClock).
    oWindow = NEW GameWindow("ProGriddle Asteroids", oController, oView, NEW AsteroidsInput(oGame), oClock, oSettings, "asteroids").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Asteroids could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
    END FINALLY.
END.
QUIT.
