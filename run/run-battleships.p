/* Battleships against the computer, in a window. This is the composition root: the only place that
   builds the concrete classes and wires them together.

   Arcade: Battleships | You against a computer on two boards. Place your fleet and sink theirs. | red

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-battleships.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json), a number of seconds after which the window closes by
   itself (for scripted checks), and a seed for the fleets and the computer's shots (for scripted
   checks).

   Settings: the window saves the chosen board size as battleships.choice (Tiny, Small, Classic,
   Large or Huge) and its own size and position. Nothing else needs setting. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Battleships.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER           NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER             NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64               NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings           NO-UNDO.
DEFINE VARIABLE oOpponent     AS HuntTargetOpponent  NO-UNDO.
DEFINE VARIABLE oGame         AS BattleshipsGame     NO-UNDO.
DEFINE VARIABLE oView         AS GridView            NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock       NO-UNDO.
DEFINE VARIABLE oController   AS TurnController      NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow          NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).
iSeed = MTIME.
IF NUM-ENTRIES(SESSION:PARAMETER) >= 4 THEN iSeed = INT64(ENTRY(4, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    /* the game starts as Classic. The window then applies the saved size, which builds the right boards.
       The window wants a clock, and a turn based game has no use for one, so it gets one that never runs. */
    oClock = NEW WinFormsClock().
    oOpponent = NEW HuntTargetOpponent(NEW SeededRandom(iSeed + 1)).
    oGame = BattleshipsFactory:Create(BattleshipsFleets:SideOf("Classic"), BattleshipsFleets:SideOf("Classic"),
                                      BattleshipsFleets:FleetOf("Classic"), NEW SeededRandom(iSeed), oOpponent).

    oView = NEW GridView().
    oView:SetPalette(BattleshipsLook:Palette()).
    oView:SetGlyphs(BattleshipsLook:Glyphs(), BattleshipsLook:GlyphColors()).
    oController = NEW TurnController(oGame, NEW WinFormsGridRenderer(oView, "view")).
    oWindow = NEW GameWindow("ProGriddle Battleships", oController, oView, NEW BattleshipsInput(oGame),
                             oClock, oSettings, "battleships").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Battleships could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
        IF VALID-OBJECT(oOpponent) THEN oOpponent:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
    END FINALLY.
END.
QUIT.
