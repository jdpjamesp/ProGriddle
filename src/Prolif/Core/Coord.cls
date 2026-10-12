/* Immutable x, y pair. Used at the edges of the API (moves, UI, tests) only.
   Hot paths use integer x, y and integer cell indexes, never this class. */
USING Progress.Lang.*.
USING Prolif.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.Coord FINAL:

    DEFINE PUBLIC PROPERTY X AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Y AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC Coord(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        X = piX.
        Y = piY.
    END CONSTRUCTOR.

    /* Returns a new Coord moved by the given offsets. */
    METHOD PUBLIC Coord Plus(INPUT piDx AS INTEGER, INPUT piDy AS INTEGER):
        RETURN NEW Coord(X + piDx, Y + piDy).
    END METHOD.

    METHOD PUBLIC OVERRIDE LOGICAL Equals(INPUT poOther AS Progress.Lang.Object):
        IF NOT VALID-OBJECT(poOther) THEN RETURN FALSE.
        IF NOT TYPE-OF(poOther, Coord) THEN RETURN FALSE.
        RETURN X = CAST(poOther, Coord):X AND Y = CAST(poOther, Coord):Y.
    END METHOD.

    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        RETURN SUBSTITUTE("(&1,&2)", X, Y).
    END METHOD.

END CLASS.
