/* Prints where the computer's ships are for a seeded Battleships game, for the GUI smoke test,
   which needs to know what it is firing at. One line per row: "." for water and the ship number
   (1 to 9) for a ship cell, written to a file.
     _progres -b -p tools/launch.p -param "tools/battleships-layout.p,<seed>,<restarts>,<file>[,<size>]"
   <restarts> is how many times the game has been started again after it was built (the window
   applies a saved or default size, which starts a new game and places the fleets again). <size>
   is Tiny, Small, Classic (the default), Large or Huge. Run from the repository root. */
USING ProGriddle.Core.*.
USING ProGriddle.Games.Battleships.*.

DEFINE VARIABLE oGame   AS BattleshipsGame    NO-UNDO.
DEFINE VARIABLE oOpp    AS HuntTargetOpponent NO-UNDO.
DEFINE VARIABLE cSize   AS CHARACTER          NO-UNDO INITIAL "Classic".
DEFINE VARIABLE iRepeat AS INTEGER            NO-UNDO.
DEFINE VARIABLE i       AS INTEGER            NO-UNDO.
DEFINE VARIABLE x       AS INTEGER            NO-UNDO.
DEFINE VARIABLE y       AS INTEGER            NO-UNDO.
DEFINE VARIABLE cLine   AS CHARACTER          NO-UNDO.
DEFINE VARIABLE iId     AS INTEGER            NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 5 THEN cSize = ENTRY(5, SESSION:PARAMETER).
iRepeat = INTEGER(ENTRY(3, SESSION:PARAMETER)).

oOpp = NEW HuntTargetOpponent(NEW SeededRandom(INT64(ENTRY(2, SESSION:PARAMETER)) + 1)).
oGame = BattleshipsFactory:Create(BattleshipsFleets:SideOf("Classic"), BattleshipsFleets:SideOf("Classic"),
                                  BattleshipsFleets:FleetOf("Classic"), NEW SeededRandom(INT64(ENTRY(2, SESSION:PARAMETER))), oOpp).
/* the window then applies the size it saved, or Classic */
oGame:Configure(BattleshipsFleets:SideOf(cSize), BattleshipsFleets:SideOf(cSize), BattleshipsFleets:FleetOf(cSize)).
DO i = 2 TO iRepeat:
    oGame:Initialise().
END.

OUTPUT TO VALUE(ENTRY(4, SESSION:PARAMETER)).
DO y = 0 TO oGame:BoardHeight - 1:
    cLine = "".
    DO x = 0 TO oGame:BoardWidth - 1:
        iId = oGame:EnemyShipAt(x, y).
        cLine = cLine + (IF iId = 0 THEN "." ELSE STRING(iId)).
    END.
    PUT UNFORMATTED cLine SKIP.
END.
OUTPUT CLOSE.
oGame:Dispose().
oOpp:Dispose().
QUIT.
