USING OpenEdge.Core.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* The look is a palette and a string of symbols that must line up with the 11 view codes. */
CLASS ProGriddle.Games.Tetris.TetrisLookTests:

    @Test.
    METHOD PUBLIC VOID ThereIsAColourAndASymbolForEveryViewCode():
        Assert:Equals(11, NUM-ENTRIES(TetrisLook:Palette())).
        Assert:Equals(11, LENGTH(TetrisLook:TextSymbols())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryColourIsSixHexDigitsAndTheyAreAllDifferent():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DO i = 1 TO 11:
            Assert:Equals(6, LENGTH(ENTRY(i, TetrisLook:Palette()))).
            DO j = i + 1 TO 11:
                Assert:IsTrue(ENTRY(i, TetrisLook:Palette()) <> ENTRY(j, TetrisLook:Palette())).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePiecesComeInTheOrderIOTSZJLAfterTheEmptyCell():
        Assert:Equals(".IOTSZJL", SUBSTRING(TetrisLook:TextSymbols(), 1, 8)).
    END METHOD.

END CLASS.
