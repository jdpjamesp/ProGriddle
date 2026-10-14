USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
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
    METHOD PUBLIC VOID NamedColoursComeFromTheLanternGlassPalette():
        Assert:Equals(ColourMath:FromHex("0A0E16"), TetrisLook:Colour(Tint:NightTop)).
        Assert:Equals(ColourMath:FromHex("FFA24A"), TetrisLook:Colour(Tint:Accent)).
        Assert:Equals(ColourMath:FromHex("FFC857"), TetrisLook:Colour(Tint:Gold)).
        Assert:Equals(ColourMath:FromHex("7A2A20"), TetrisLook:Colour(Tint:DangerLow)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryColourRowHasFiveTonesGettingDarkerAndTheBaseIsTheThirdOne():
        DEFINE VARIABLE row AS INTEGER NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE a   AS INTEGER NO-UNDO.
        DEFINE VARIABLE b   AS INTEGER NO-UNDO.
        DO row = 1 TO 9:
            Assert:Equals(5, NUM-ENTRIES(TetrisLook:Tones(row))).
            DO i = 1 TO 4:
                a = ColourMath:Red(ColourMath:FromHex(ENTRY(i, TetrisLook:Tones(row)))) + ColourMath:Green(ColourMath:FromHex(ENTRY(i, TetrisLook:Tones(row)))).
                b = ColourMath:Red(ColourMath:FromHex(ENTRY(i + 1, TetrisLook:Tones(row)))) + ColourMath:Green(ColourMath:FromHex(ENTRY(i + 1, TetrisLook:Tones(row)))).
                Assert:IsTrue(a >= b, SUBSTITUTE("row &1 tone &2", row, i)).
            END.
        END.
        Assert:Equals("2BC4A8", ENTRY(3, TetrisLook:Tones(1))).
        Assert:Equals("F5C542", ENTRY(3, TetrisLook:Tones(2))).
        Assert:Equals("E4503C", ENTRY(3, TetrisLook:Tones(5))).
        Assert:Equals("FFC857", ENTRY(3, TetrisLook:Tones(9))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSevenPiecesHaveSevenDifferentBaseColours():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DO i = 1 TO 7:
            DO j = i + 1 TO 7:
                Assert:IsTrue(ENTRY(3, TetrisLook:Tones(i)) <> ENTRY(3, TetrisLook:Tones(j))).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LitTonesAreOneStepLighterWithAWhiteHighlightAndWhiteTopKeepsTheRest():
        DEFINE VARIABLE t AS CHARACTER NO-UNDO.
        t = TetrisLook:Tones(1).
        Assert:Equals(SUBSTITUTE("FFFFFF,&1,&2,&3,&4", ENTRY(1, t), ENTRY(2, t), ENTRY(3, t), ENTRY(4, t)), TetrisLook:LitTones(1)).
        Assert:Equals(SUBSTITUTE("FFFFFF,&1,&2,&3,&4", ENTRY(2, t), ENTRY(3, t), ENTRY(4, t), ENTRY(5, t)), TetrisLook:WhiteTopTones(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARowOrColourThatDoesNotExistIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            TetrisLook:Tones(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            TetrisLook:Tones(10).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            TetrisLook:Colour(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePiecesComeInTheOrderIOTSZJLAfterTheEmptyCell():
        Assert:Equals(".IOTSZJL", SUBSTRING(TetrisLook:TextSymbols(), 1, 8)).
    END METHOD.

END CLASS.
