USING OpenEdge.Core.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* The look is three lists and a string that must all line up with the 15 view codes. */
CLASS ProGriddle.Games.Minesweeper.MinesweeperLookTests:

    @Test.
    METHOD PUBLIC VOID ThereIsAColourAGlyphAndAGlyphColourForEveryViewCode():
        Assert:Equals(15, NUM-ENTRIES(MinesweeperLook:Palette())).
        Assert:Equals(15, NUM-ENTRIES(MinesweeperLook:Glyphs())).
        Assert:Equals(15, NUM-ENTRIES(MinesweeperLook:GlyphColors())).
        Assert:Equals(15, LENGTH(MinesweeperLook:TextSymbols())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryColourIsSixHexDigits():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 15:
            Assert:Equals(6, LENGTH(ENTRY(i, MinesweeperLook:Palette()))).
            Assert:Equals(6, LENGTH(ENTRY(i, MinesweeperLook:GlyphColors()))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDigitsAreAtCodesFourToEleven():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO n = 1 TO 8:
            Assert:Equals(STRING(n), ENTRY(n + 4, MinesweeperLook:Glyphs())).
            Assert:Equals(STRING(n), SUBSTRING(MinesweeperLook:TextSymbols(), n + 4, 1)).
        END.
        Assert:Equals("", ENTRY(4, MinesweeperLook:Glyphs())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HiddenFlaggedAndQuestionedCellsLookAlikeAndDifferFromOpenOnes():
        Assert:Equals(ENTRY(1, MinesweeperLook:Palette()), ENTRY(2, MinesweeperLook:Palette())).
        Assert:Equals(ENTRY(1, MinesweeperLook:Palette()), ENTRY(3, MinesweeperLook:Palette())).
        Assert:IsTrue(ENTRY(1, MinesweeperLook:Palette()) <> ENTRY(4, MinesweeperLook:Palette())).
    END METHOD.

END CLASS.
