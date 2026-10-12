/* Edges wrap: leaving one side brings you back in on the opposite side, so the board
   behaves like the surface of a doughnut. Every coordinate refers to a cell. */
USING Prolif.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.ToroidalTopology FINAL IMPLEMENTS ITopology:

    DEFINE PUBLIC PROPERTY Wraps AS LOGICAL NO-UNDO
        GET():
            RETURN TRUE.
        END GET.

    METHOD PUBLIC LOGICAL IsValid(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER,
                                  INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN TRUE.
    END METHOD.

    /* MODULO keeps the sign of its first operand in ABL, so the remainder is shifted into
       range with a second step: -1 on a width of 5 gives 4. */
    METHOD PUBLIC INTEGER Resolve(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER,
                                  INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE wx AS INTEGER NO-UNDO.
        DEFINE VARIABLE wy AS INTEGER NO-UNDO.
        wx = ((piX MODULO piWidth) + piWidth) MODULO piWidth.
        wy = ((piY MODULO piHeight) + piHeight) MODULO piHeight.
        RETURN wy * piWidth + wx.
    END METHOD.

END CLASS.
