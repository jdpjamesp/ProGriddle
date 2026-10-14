/* A tile: a small picture as a map of tones (1 to 5 for a colour row, letters for named colours, a dot for nothing), turned
   and coloured into a stamp. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.TileTests:

    /* The tones of a test colour row: five greys that are easy to tell apart. */
    &SCOPED-DEFINE TONES "F00000,E00000,D00000,C00000,B00000"

    @Test.
    METHOD PUBLIC VOID ATileKnowsItsSizeAndEachPixel():
        DEFINE VARIABLE t AS Tile NO-UNDO.
        t = NEW Tile("12./3.A").
        Assert:Equals(3, t:Width).
        Assert:Equals(2, t:Height).
        Assert:Equals("1", t:PixelAt(0, 0)).
        Assert:Equals(".", t:PixelAt(2, 0)).
        Assert:Equals("A", t:PixelAt(2, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATileRefusesNothingRaggedRowsAndOddCharacters():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW Tile("").
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Tile("12/3").
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Tile("12/3?").
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TurnedRotatesASquareTileClockwise():
        DEFINE VARIABLE t  AS Tile NO-UNDO.
        DEFINE VARIABLE t1 AS Tile NO-UNDO.
        /* 1 at the top left, 2 at the top right, 3 at the bottom left */
        t = NEW Tile("12/3.").
        t1 = t:Turned(1).
        /* clockwise: the top left goes to the top right, the top right to the bottom right, the bottom left to the top left */
        Assert:Equals("3", t1:PixelAt(0, 0)).
        Assert:Equals("1", t1:PixelAt(1, 0)).
        Assert:Equals(".", t1:PixelAt(0, 1)).
        Assert:Equals("2", t1:PixelAt(1, 1)).
        Assert:Equals("2", t:Turned(2):PixelAt(0, 1)).
        Assert:Equals("1", t:Turned(2):PixelAt(1, 1)).
        /* four turns are none, and a negative count turns the other way */
        Assert:Equals("1", t:Turned(4):PixelAt(0, 0)).
        Assert:Equals("2", t:Turned(-1):PixelAt(0, 0)).
        Assert:Equals("1", t:Turned(0):PixelAt(0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATileThatIsNotSquareCannotBeTurned():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW Tile("123/456"):Turned(1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ColouriseGivesAStampWithATonePerPixelAndNothingWhereThereIsADot():
        DEFINE VARIABLE s AS PixelStamp NO-UNDO.
        s = NEW Tile("15/.3"):Colourise({&TONES}, "").
        Assert:Equals(2, s:Width).
        Assert:Equals(2, s:Height).
        Assert:Equals(3, s:Count).
        Assert:Equals(ColourMath:FromHex("F00000"), s:ColourAt(0, 0)).
        Assert:Equals(ColourMath:FromHex("B00000"), s:ColourAt(1, 0)).
        Assert:Equals(-1, s:ColourAt(0, 1)).
        Assert:Equals(ColourMath:FromHex("D00000"), s:ColourAt(1, 1)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LettersTakeTheirColoursFromTheLegend():
        DEFINE VARIABLE s AS PixelStamp NO-UNDO.
        s = NEW Tile("AB/3."):Colourise({&TONES}, "A=112233,B=445566").
        Assert:Equals(ColourMath:FromHex("112233"), s:ColourAt(0, 0)).
        Assert:Equals(ColourMath:FromHex("445566"), s:ColourAt(1, 0)).
        Assert:Equals(ColourMath:FromHex("D00000"), s:ColourAt(0, 1)).
        s:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ColouriseRefusesAWrongToneListAndALetterThatIsNotInTheLegend():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW Tile("1"):Colourise("F00000,E00000", "").
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Tile("Q"):Colourise({&TONES}, "A=112233").
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Tile("1"):Colourise({&TONES}, "A112233").
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
