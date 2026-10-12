USING OpenEdge.Core.Assert.
USING Prolif.Core.Shape.
USING Prolif.Games.Life.LifePatterns.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Games.Life.LifePatternsTests:

    /* Checks a pattern's live cell count and bounding box in one go. */
    METHOD PRIVATE VOID AssertShape(INPUT poShape AS Shape, INPUT piCells AS INTEGER, INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        Assert:Equals(piCells, poShape:Size).
        Assert:Equals(piWidth, poShape:Width).
        Assert:Equals(piHeight, poShape:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StillLifeAndOscillatorsHaveTheirKnownSize():
        AssertShape(LifePatterns:Block(), 4, 2, 2).
        AssertShape(LifePatterns:Beehive(), 6, 4, 3).
        AssertShape(LifePatterns:Blinker(), 3, 3, 1).
        AssertShape(LifePatterns:Toad(), 6, 4, 2).
        AssertShape(LifePatterns:Beacon(), 8, 4, 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceshipsAndMethuselahsHaveTheirKnownSize():
        AssertShape(LifePatterns:Glider(), 5, 3, 3).
        AssertShape(LifePatterns:LightweightSpaceship(), 9, 5, 4).
        AssertShape(LifePatterns:RPentomino(), 5, 3, 3).
        AssertShape(LifePatterns:Diehard(), 7, 8, 3).
        AssertShape(LifePatterns:Acorn(), 7, 7, 3).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGosperGliderGunHasThirtySixCellsInA36By9Box():
        AssertShape(LifePatterns:GosperGliderGun(), 36, 36, 9).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGliderIsTheClassicShape():
        Assert:Equals(".X./..X/XXX", LifePatterns:Glider():ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ByNameFindsEveryListedPattern():
        DEFINE VARIABLE names AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        names = LifePatterns:Names().
        Assert:Equals(11, NUM-ENTRIES(names)).
        DO i = 1 TO NUM-ENTRIES(names):
            Assert:IsTrue(LifePatterns:ByName(ENTRY(i, names)):Size > 0).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ByNameIgnoresCase():
        Assert:IsTrue(LifePatterns:ByName("glider"):Equals(LifePatterns:Glider())).
        Assert:IsTrue(LifePatterns:ByName("RPENTOMINO"):Equals(LifePatterns:RPentomino())).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ByNameThrowsForAnUnknownPattern():
        LifePatterns:ByName("nope").
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ByNameThrowsForAnUnknownName():
        DEFINE VARIABLE s AS CHARACTER NO-UNDO.
        LifePatterns:ByName(s).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlainTextSkipsCommentsAndReadsLiveAndDeadCells():
        DEFINE VARIABLE t AS CHARACTER NO-UNDO.
        t = "!Name: Glider" + CHR(10) + "!A comment" + CHR(10) + ".O." + CHR(10) + "..O" + CHR(10) + "OOO".
        Assert:IsTrue(LifePatterns:FromPlainText(t):Equals(LifePatterns:Glider())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlainTextHandlesWindowsLineEndingsAndOtherLiveMarks():
        DEFINE VARIABLE t AS CHARACTER NO-UNDO.
        t = ".X." + CHR(13) + CHR(10) + "..#" + CHR(13) + CHR(10) + "***".
        Assert:IsTrue(LifePatterns:FromPlainText(t):Equals(LifePatterns:Glider())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlainTextRowsMayHaveDifferentLengths():
        Assert:Equals("XX/X.", LifePatterns:FromPlainText("OO" + CHR(10) + "O"):ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlainTextIsNormalisedToItsBoundingBox():
        DEFINE VARIABLE t AS CHARACTER NO-UNDO.
        t = "...." + CHR(10) + "..O." + CHR(10) + "..O.".
        Assert:Equals("X/X", LifePatterns:FromPlainText(t):ToString()).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID PlainTextWithoutALiveCellThrows():
        LifePatterns:FromPlainText("!only a comment" + CHR(10) + "...").
    END METHOD.

END CLASS.
