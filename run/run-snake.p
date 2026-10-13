/* Snake in a window. This is the composition root: the only place that builds the concrete classes and
   wires them together.

   Arcade: Snake | Eat, grow and speed up, and do not bite yourself or hit the wall. | green

   Run it under prowin from the repository root:
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-snake.p"
   Optional entries after the program name: the settings file ("default" for
   %APPDATA%\ProGriddle\settings.json), a number of seconds after which the window closes by itself
   (for scripted checks), and a seed for the food (for scripted checks).

   Settings it reads (all optional, edit the file while the program is closed):
     snake.width, snake.height   board size in cells, 5 to 40 (default 20 x 20)
     snake.size                  the board size chosen in the window, such as 30 x 20 (saved when the window closes,
                                 and it wins over snake.width and snake.height when the window opens)
     snake.best                  the best score (kept by the game)
   The window also saves its own size and position. */
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE cSettingsFile AS CHARACTER          NO-UNDO INITIAL "default".
DEFINE VARIABLE iAutoClose    AS INTEGER            NO-UNDO.
DEFINE VARIABLE iSeed         AS INT64              NO-UNDO.
DEFINE VARIABLE oSettings     AS ISettings          NO-UNDO.
DEFINE VARIABLE oGame         AS SnakeGame          NO-UNDO.
DEFINE VARIABLE oView         AS GridView           NO-UNDO.
DEFINE VARIABLE oClock        AS WinFormsClock      NO-UNDO.
DEFINE VARIABLE oController   AS RealTimeController NO-UNDO.
DEFINE VARIABLE oWindow       AS GameWindow         NO-UNDO.
DEFINE VARIABLE iWidth        AS INTEGER            NO-UNDO.
DEFINE VARIABLE iHeight       AS INTEGER            NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cSettingsFile = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAutoClose = INTEGER(ENTRY(3, SESSION:PARAMETER)).
iSeed = MTIME.
IF NUM-ENTRIES(SESSION:PARAMETER) >= 4 THEN iSeed = INT64(ENTRY(4, SESSION:PARAMETER)).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    IF cSettingsFile = "default" THEN cSettingsFile = JsonFileSettings:DefaultPath().
    oSettings = NEW JsonFileSettings(cSettingsFile).

    iWidth  = MAXIMUM(5, MINIMUM(40, oSettings:GetInteger("snake.width", 20))).
    iHeight = MAXIMUM(5, MINIMUM(40, oSettings:GetInteger("snake.height", 20))).

    /* a tick every 20 ms keeps the steps (60 to 150 ms apart) evenly spaced and redraws only when the snake moved */
    oClock = NEW WinFormsClock().
    oClock:Interval = 20.
    oGame = SnakeFactory:Create(iWidth, iHeight, NEW SeededRandom(iSeed)).
    /* each new game waits for the first arrow key, so the snake never sets off before the player is ready */
    oGame:WaitForKey = TRUE.

    oView = NEW GridView().
    oView:SetPalette(SnakeLook:Palette()).
    oController = NEW RealTimeController(oGame, NEW WinFormsGridRenderer(oView, "view"), oClock).
    oWindow = NEW GameWindow("ProGriddle Snake", oController, oView, NEW SnakeInput(oGame, oSettings),
                             oClock, oSettings, "snake").
    IF iAutoClose > 0 THEN oWindow:AutoCloseSeconds = iAutoClose.

    /* the clock runs from the start, and the snake sets off at the first arrow key: P pauses, F2 starts again */
    oController:Start().

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "ProGriddle Snake could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oController) THEN oController:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
        IF VALID-OBJECT(oClock) THEN oClock:Dispose().
    END FINALLY.
END.
QUIT.
