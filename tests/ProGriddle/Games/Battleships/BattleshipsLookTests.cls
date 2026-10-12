USING OpenEdge.Core.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* The look is three lists and a string that must all line up with the 14 view codes. */
CLASS ProGriddle.Games.Battleships.BattleshipsLookTests:

    @Test.
    METHOD PUBLIC VOID ThereIsAColourAGlyphAndAGlyphColourForEveryViewCode():
        Assert:Equals(14, NUM-ENTRIES(BattleshipsLook:Palette())).
        Assert:Equals(14, NUM-ENTRIES(BattleshipsLook:Glyphs())).
        Assert:Equals(14, NUM-ENTRIES(BattleshipsLook:GlyphColors())).
        Assert:Equals(14, LENGTH(BattleshipsLook:TextSymbols())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryColourIsSixHexDigits():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 14:
            Assert:Equals(6, LENGTH(ENTRY(i, BattleshipsLook:Palette()))).
            Assert:Equals(6, LENGTH(ENTRY(i, BattleshipsLook:GlyphColors()))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryTextSymbolIsDifferent():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DEFINE VARIABLE same AS INTEGER NO-UNDO.
        DO i = 1 TO 14:
            DO j = i + 1 TO 14:
                IF SUBSTRING(BattleshipsLook:TextSymbols(), i, 1) = SUBSTRING(BattleshipsLook:TextSymbols(), j, 1) THEN same = same + 1.
            END.
        END.
        Assert:Equals(0, same).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTwoBoardsHaveDifferentWaterColours():
        /* enemy hidden water is view code 0, your own water is code 6 */
        Assert:IsTrue(ENTRY(1, BattleshipsLook:Palette()) <> ENTRY(7, BattleshipsLook:Palette())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HitsAndSunkShipsAreDrawnWithACrossAndMissesWithADot():
        Assert:Equals("U+2716", ENTRY(4, BattleshipsLook:Glyphs())).
        Assert:Equals("U+2716", ENTRY(5, BattleshipsLook:Glyphs())).
        Assert:Equals("U+2022", ENTRY(3, BattleshipsLook:Glyphs())).
        Assert:Equals("U+2248", ENTRY(2, BattleshipsLook:Glyphs())).
        Assert:Equals("", ENTRY(1, BattleshipsLook:Glyphs())).
    END METHOD.

END CLASS.
