/* The seven pieces. Pieces are numbered 1 to 7 in the order I, O, T, S, Z, J, L. Each is a Shape
   in its spawn position, and a turn of 0 to 3 quarter turns clockwise gives the other three. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.Tetrominoes FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 7.
    END METHOD.

    /* The piece names in order, "I,O,T,S,Z,J,L". */
    METHOD PUBLIC STATIC CHARACTER Names():
        RETURN "I,O,T,S,Z,J,L".
    END METHOD.

    /* The number of the piece with this name, 1 to 7. Throws GridException for any other name. */
    METHOD PUBLIC STATIC INTEGER PieceOf(INPUT pcName AS CHARACTER):
        IF pcName = ? OR LOOKUP(TRIM(pcName), Names()) = 0 THEN UNDO, THROW NEW GridException("Not a piece: " + STRING(pcName)).
        RETURN LOOKUP(TRIM(pcName), Names()).
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT piPiece AS INTEGER):
        CheckPiece(piPiece).
        RETURN ENTRY(piPiece, Names()).
    END METHOD.

    /* The shape of a piece after piTurns quarter turns clockwise (0 to 3), with its top left corner
       at (0, 0), as Shape always is. */
    METHOD PUBLIC STATIC Shape ShapeOf(INPUT piPiece AS INTEGER, INPUT piTurns AS INTEGER):
        DEFINE VARIABLE result AS Shape   NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        CheckPiece(piPiece).
        IF piTurns < 0 OR piTurns > 3 THEN UNDO, THROW NEW GridException("A piece has turns 0 to 3, not " + STRING(piTurns)).
        CASE piPiece:
            WHEN 1 THEN result = Shape:Parse("XXXX").
            WHEN 2 THEN result = Shape:Parse("XX/XX").
            WHEN 3 THEN result = Shape:Parse(".X./XXX").
            WHEN 4 THEN result = Shape:Parse(".XX/XX.").
            WHEN 5 THEN result = Shape:Parse("XX./.XX").
            WHEN 6 THEN result = Shape:Parse("X../XXX").
            OTHERWISE result = Shape:Parse("..X/XXX").
        END CASE.
        DO i = 1 TO piTurns:
            result = result:Rotate().
        END.
        RETURN result.
    END METHOD.

    METHOD PRIVATE STATIC VOID CheckPiece(INPUT piPiece AS INTEGER):
        IF piPiece = ? OR piPiece < 1 OR piPiece > 7 THEN UNDO, THROW NEW GridException("A piece is 1 to 7, not " + STRING(piPiece)).
    END METHOD.

END CLASS.
