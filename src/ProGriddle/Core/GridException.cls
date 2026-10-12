/* Thrown for every grid contract violation: out of range access, bad layer name,
   mismatched sizes, invalid shapes. Never returned as a magic value. */
USING Progress.Lang.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.GridException INHERITS AppError:

    CONSTRUCTOR PUBLIC GridException(INPUT pcMessage AS CHARACTER):
        SUPER(pcMessage, 0).
    END CONSTRUCTOR.

END CLASS.
