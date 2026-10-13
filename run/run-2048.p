/* 2048 in a window. This is the composition root: the only place that builds the concrete
   classes and wires them together.

   Arcade: 2048 | Slide the tiles, join the matching pairs, and make 2048. | orange

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-2048.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json) and a number of seconds after which the window closes
   by itself (for scripted checks), and then a seed for the new tiles (for scripted checks).

   Settings it reads (all optional, edit the file while the program is closed):
     2048.width, 2048.height   board size in cells, 2 to 8 (default 4 x 4)
     2048.best                 the best score (kept by the game)
   The window also saves its own size and position. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.2048.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER       NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER         NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64           NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings       NO-UNDO.
DEFINE VARIABLE oGame         AS TilesGame       NO-UNDO.
DEFINE VARIABLE oView         AS GridView        NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock   NO-UNDO.
DEFINE VARIABLE oController   AS TurnController  NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow      NO-UNDO.
DEFINE VARIABLE iWidth        AS INTEGER         NO-UNDO.
DEFINE VARIABLE iHeight       AS INTEGER         NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).
iSeed = MTIME.
IF NUM-ENTRIES(SESSION:PARAMETER) >= 4 THEN iSeed = INT64(ENTRY(4, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    iWidth  = MAXIMUM(2, MINIMUM(8, oSettings:GetInteger("2048.width", 4))).
    iHeight = MAXIMUM(2, MINIMUM(8, oSettings:GetInteger("2048.height", 4))).

    oGame = TilesFactory:Create(iWidth, iHeight, NEW SeededRandom(iSeed)).

    oView = NEW GridView().
    oView:SetPalette(TilesLook:Palette()).
    oView:SetGlyphs(TilesLook:Glyphs(), TilesLook:GlyphColors()).
    /* a turn based game has no clock of its own, but the window wants one */
    oClock = NEW WinFormsClock().
    oController = NEW TurnController(oGame, NEW WinFormsGridRenderer(oView, "view")).
    oWindow = NEW GameWindow("ProGriddle 2048", oController, oView, NEW TilesInput(oGame, oSettings),
                             oClock, oSettings, "2048").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle 2048 could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
    END FINALLY.
END.
QUIT.
