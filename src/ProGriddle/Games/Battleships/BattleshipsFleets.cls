/* The standard board sizes and the fleet each one carries. The fleet follows from the size, so a
   bigger sea holds more and longer ships, and every fleet is under a fifth of the cells so the
   rule that ships may not touch can always be met.

     Tiny      6 x 6     3 2 2
     Small     8 x 8     4 3 3 2
     Classic  10 x 10    5 4 3 3 2
     Large    12 x 12    5 4 4 3 3 2 2
     Huge     15 x 15    6 5 4 4 3 3 3 2 2

   A ship is never shorter than two cells. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.BattleshipsFleets FINAL:

    /* The size names, smallest first, in the order a picker shows them. */
    METHOD PUBLIC STATIC CHARACTER Names():
        RETURN "Tiny,Small,Classic,Large,Huge".
    END METHOD.

    /* The size a name stands for in its proper spelling, or an empty string for an unknown name. */
    METHOD PUBLIC STATIC CHARACTER Canonical(INPUT pcName AS CHARACTER):
        IF pcName = ? OR LOOKUP(pcName, Names()) = 0 THEN RETURN "".
        RETURN ENTRY(LOOKUP(pcName, Names()), Names()).
    END METHOD.

    /* Boards are square: the side of the board in cells. */
    METHOD PUBLIC STATIC INTEGER SideOf(INPUT pcName AS CHARACTER):
        CASE Canonical(pcName):
            WHEN "Tiny" THEN RETURN 6.
            WHEN "Small" THEN RETURN 8.
            WHEN "Classic" THEN RETURN 10.
            WHEN "Large" THEN RETURN 12.
            WHEN "Huge" THEN RETURN 15.
            OTHERWISE UNDO, THROW NEW GridException("Not a standard size: " + STRING(pcName)).
        END CASE.
    END METHOD.

    /* The ship lengths, longest first, as a comma separated list such as "5,4,3,3,2". */
    METHOD PUBLIC STATIC CHARACTER FleetOf(INPUT pcName AS CHARACTER):
        CASE Canonical(pcName):
            WHEN "Tiny" THEN RETURN "3,2,2".
            WHEN "Small" THEN RETURN "4,3,3,2".
            WHEN "Classic" THEN RETURN "5,4,3,3,2".
            WHEN "Large" THEN RETURN "5,4,4,3,3,2,2".
            WHEN "Huge" THEN RETURN "6,5,4,4,3,3,3,2,2".
            OTHERWISE UNDO, THROW NEW GridException("Not a standard size: " + STRING(pcName)).
        END CASE.
    END METHOD.

    /* How many cells the fleet covers. */
    METHOD PUBLIC STATIC INTEGER CellsOf(INPUT pcName AS CHARACTER):
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE fleet AS CHARACTER NO-UNDO.
        DEFINE VARIABLE total AS INTEGER   NO-UNDO.
        fleet = FleetOf(pcName).
        DO i = 1 TO NUM-ENTRIES(fleet):
            total = total + INTEGER(ENTRY(i, fleet)).
        END.
        RETURN total.
    END METHOD.

    /* The standard size whose board is this side long and whose fleet is this one, or an empty
       string when there is none. */
    METHOD PUBLIC STATIC CHARACTER NameFor(INPUT piSide AS INTEGER, INPUT pcFleet AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(Names()):
            IF SideOf(ENTRY(i, Names())) = piSide AND FleetOf(ENTRY(i, Names())) = pcFleet THEN RETURN ENTRY(i, Names()).
        END.
        RETURN "".
    END METHOD.

END CLASS.
