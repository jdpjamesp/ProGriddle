/* Conway's Game of Life in a window. This is the composition root: the only place that builds
   the concrete classes and wires them together.

   Run it under prowin from the repository root:
     prowin.exe -p tools/launch.p -param "run/run-life.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProLific\settings.json) and a number of seconds after which the window closes
   by itself (for scripted checks).

   Settings it reads (all optional, edit the file while the program is closed):
     life.width, life.height   board size in cells, 5 to 400 (default 100 x 70)
     life.wrap                 true to wrap the edges (default false)
     life.rules                B/S notation, for example "B36/S23" for HighLife (default B3/S23)
     life.expectedLive         expected share of live cells, 0 to 1. Below 0.05 the sparse
                               engine is used. Default 0.1
     life.palette              hex colours for dead and alive, "1B1F24,F2C14E"
     life.startPattern         pattern placed on a new board, or "None" (default GosperGliderGun)
   The window also saves its own size, position, speed and chosen pattern. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING Prolif.Core.*.
USING Prolif.Engine.*.
USING Prolif.Games.Life.*.
USING Prolif.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER        NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER          NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings        NO-UNDO.
DEFINE VARIABLE oRules        AS LifeRules        NO-UNDO.
DEFINE VARIABLE oGame         AS LifeGame         NO-UNDO.
DEFINE VARIABLE oView         AS GridView         NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock    NO-UNDO.
DEFINE VARIABLE oController   AS GameController   NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow       NO-UNDO.
DEFINE VARIABLE oStart        AS Shape            NO-UNDO.
DEFINE VARIABLE iWidth        AS INTEGER          NO-UNDO.
DEFINE VARIABLE iHeight       AS INTEGER          NO-UNDO.
DEFINE VARIABLE cStart        AS CHARACTER        NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    /* a bad rules entry falls back to Conway's Life rather than stopping the program */
    DO ON ERROR UNDO, THROW:
        oRules = NEW LifeRules(oSettings:GetString("life.rules", "B3/S23")).
        CATCH eRules AS Progress.Lang.Error:
            oRules = LifeRules:Conway().
        END CATCH.
    END.

    iWidth  = MAXIMUM(5, MINIMUM(400, oSettings:GetInteger("life.width", 100))).
    iHeight = MAXIMUM(5, MINIMUM(400, oSettings:GetInteger("life.height", 70))).
    oGame = LifeFactory:Create(iWidth, iHeight, oSettings:GetLogical("life.wrap", FALSE), oRules,
                               MAXIMUM(0, MINIMUM(1, oSettings:GetDecimal("life.expectedLive", 0.1)))).

    /* something to watch on a new board: the Gosper gun when it fits, else a glider */
    cStart = oSettings:GetString("life.startPattern", "GosperGliderGun").
    IF cStart <> "None" THEN DO ON ERROR UNDO, THROW:
        oStart = LifePatterns:ByName(cStart).
        IF oStart:Width + 4 > iWidth OR oStart:Height + 4 > iHeight THEN oStart = LifePatterns:Glider().
        oGame:Place(oStart, 2, 2).
        CATCH ePattern AS Progress.Lang.Error:
            oGame:Place(LifePatterns:Glider(), 1, 1).
        END CATCH.
    END.

    oView = NEW GridView().
    DO ON ERROR UNDO, THROW:
        oView:SetPalette(oSettings:GetString("life.palette", "1B1F24,F2C14E")).
        CATCH ePalette AS Progress.Lang.Error:
            oView:SetPalette("1B1F24,F2C14E").
        END CATCH.
    END.
    oClock = NEW WinFormsClock().
    oController = NEW GameController(oGame, NEW WinFormsGridRenderer(oView, "state"), oClock).
    oWindow = NEW GameWindow("ProLific Life", oController, oView,
                             NEW LifeInput(oGame, NEW SeededRandom(MTIME)), oClock, oSettings, "life").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProLific Life could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
    END FINALLY.
END.
QUIT.
