/* The arcade: one window with a button for every game. This is the composition root. It builds a
   catalog of the games in the run folder and a launcher that starts each one in its own prowin, so
   one launch command reaches every game, and a new game appears as soon as its run file is added.

   Run it under prowin from the repository root:
     prowin.exe -p tools/launch.p -param "run/run-arcade.p"
   Optional entries after the program name: a number of seconds after which the window closes by
   itself (for scripted checks), and the folder to look for games in (default run).

   Arcade: hidden
*/
USING Progress.Lang.*.
USING System.Windows.Forms.Application FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

DEFINE VARIABLE iAutoClose AS INTEGER       NO-UNDO.
DEFINE VARIABLE cFolder    AS CHARACTER     NO-UNDO INITIAL "run".
DEFINE VARIABLE oCatalog   AS IGameCatalog  NO-UNDO.
DEFINE VARIABLE oLauncher  AS IGameLauncher NO-UNDO.
DEFINE VARIABLE oWindow    AS ArcadeWindow  NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN iAutoClose = INTEGER(ENTRY(2, SESSION:PARAMETER)).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN cFolder = ENTRY(3, SESSION:PARAMETER).

DO ON ERROR UNDO, THROW:
    Application:EnableVisualStyles().

    oCatalog = NEW DirectoryGameCatalog(cFolder).
    oLauncher = NEW ProcessGameLauncher().
    oWindow = NEW ArcadeWindow("ProGriddle Cookoff", oCatalog, oLauncher).
    IF iAutoClose > 0 THEN oWindow:AutoClose(iAutoClose).

    WAIT-FOR Application:Run(oWindow).

    CATCH eRun AS Progress.Lang.Error:
        MESSAGE "The ProGriddle arcade could not start:" SKIP eRun:GetMessage(1) VIEW-AS ALERT-BOX ERROR.
    END CATCH.
    FINALLY:
        IF VALID-OBJECT(oWindow) THEN oWindow:ReleaseResources().
    END FINALLY.
END.
QUIT.
