/* Edges are walls: a coordinate off the board refers to no cell. */
USING Prolif.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.BoundedTopology FINAL IMPLEMENTS ITopology:

    DEFINE PUBLIC PROPERTY Wraps AS LOGICAL NO-UNDO
        GET():
            RETURN FALSE.
        END GET.

    METHOD PUBLIC LOGICAL IsValid(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER,
                                  INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN piX >= 0 AND piX < piWidth AND piY >= 0 AND piY < piHeight.
    END METHOD.

    METHOD PUBLIC INTEGER Resolve(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER,
                                  INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= piWidth OR piY < 0 OR piY >= piHeight THEN RETURN ?.
        RETURN piY * piWidth + piX.
    END METHOD.

END CLASS.
