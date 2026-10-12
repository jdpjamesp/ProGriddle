/* Prints where the mines are for a seeded Minesweeper board, for the GUI smoke test, which
   needs to know what it is clicking on. One line per row, "*" for a mine and "." for an
   empty cell, written to a file.
     _progres -b -p tools/launch.p -param "tools/minesweeper-layout.p,<seed>,<restarts>,<file>[,<level>]"
   <restarts> is how many times the game has been started again after it was built (the
   window applies a saved level, which starts a new game and draws the mines again). <level>
   is Beginner (the default), Intermediate or Expert. Run from the repository root. */
USING ProGriddle.Core.*.
USING ProGriddle.Games.Minesweeper.*.
USING ProGriddle.UI.Text.*.

DEFINE VARIABLE oGame   AS MinesweeperGame NO-UNDO.
DEFINE VARIABLE cLevel  AS CHARACTER       NO-UNDO INITIAL "Beginner".
DEFINE VARIABLE iRepeat AS INTEGER         NO-UNDO.
DEFINE VARIABLE i       AS INTEGER         NO-UNDO.
DEFINE VARIABLE x       AS INTEGER         NO-UNDO.
DEFINE VARIABLE y       AS INTEGER         NO-UNDO.
DEFINE VARIABLE cLine   AS CHARACTER       NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 5 THEN cLevel = ENTRY(5, SESSION:PARAMETER).
iRepeat = INTEGER(ENTRY(3, SESSION:PARAMETER)).

oGame = MinesweeperFactory:Create(MinesweeperLevels:WidthOf(cLevel), MinesweeperLevels:HeightOf(cLevel),
                                  MinesweeperLevels:MinesOf(cLevel), NEW SeededRandom(INT64(ENTRY(2, SESSION:PARAMETER))), NEW FakeClock()).
DO i = 1 TO iRepeat:
    oGame:Initialise().
END.

OUTPUT TO VALUE(ENTRY(4, SESSION:PARAMETER)).
DO y = 0 TO oGame:Grid:Height - 1:
    cLine = "".
    DO x = 0 TO oGame:Grid:Width - 1:
        cLine = cLine + (IF oGame:MineAt(x, y) THEN "*" ELSE ".").
    END.
    PUT UNFORMATTED cLine SKIP.
END.
OUTPUT CLOSE.
oGame:Dispose().
QUIT.
