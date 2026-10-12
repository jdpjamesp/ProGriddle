USING OpenEdge.Core.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrominoesTests:

    @Test.
    METHOD PUBLIC VOID ThereAreSevenPiecesInTheUsualOrder():
        Assert:Equals(7, Tetrominoes:Count()).
        Assert:Equals("I,O,T,S,Z,J,L", Tetrominoes:Names()).
        Assert:Equals(3, Tetrominoes:PieceOf("T")).
        Assert:Equals("L", Tetrominoes:NameOf(7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceNameRoundTripsAndIgnoresCase():
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DO p = 1 TO 7:
            Assert:Equals(p, Tetrominoes:PieceOf(Tetrominoes:NameOf(p))).
        END.
        Assert:Equals(4, Tetrominoes:PieceOf("s")).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownPieceNameThrows():
        Tetrominoes:PieceOf("Q").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID APieceNumberOutOfRangeThrows():
        Tetrominoes:ShapeOf(8, 0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ATurnOutOfRangeThrows():
        Tetrominoes:ShapeOf(1, 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPieceInEveryTurnHasFourCells():
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DO p = 1 TO 7:
            DO t = 0 TO 3:
                Assert:Equals(4, Tetrominoes:ShapeOf(p, t):Size).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TurningAPieceFourTimesGivesItBackWhatItWas():
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS Shape   NO-UNDO.
        DO p = 1 TO 7:
            s = Tetrominoes:ShapeOf(p, 0):Rotate():Rotate():Rotate():Rotate().
            Assert:IsTrue(s:Equals(Tetrominoes:ShapeOf(p, 0))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShapeOfTurnsIsTheSameAsRotatingThatManyTimes():
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DO p = 1 TO 7:
            Assert:IsTrue(Tetrominoes:ShapeOf(p, 1):Equals(Tetrominoes:ShapeOf(p, 0):Rotate())).
            Assert:IsTrue(Tetrominoes:ShapeOf(p, 2):Equals(Tetrominoes:ShapeOf(p, 0):Rotate():Rotate())).
            Assert:IsTrue(Tetrominoes:ShapeOf(p, 3):Equals(Tetrominoes:ShapeOf(p, 0):Rotate():Rotate():Rotate())).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShapesAreThePiecesAsTheyAppear():
        Assert:Equals("XXXX", Tetrominoes:ShapeOf(1, 0):ToString()).
        Assert:Equals("XX/XX", Tetrominoes:ShapeOf(2, 0):ToString()).
        Assert:Equals(".X./XXX", Tetrominoes:ShapeOf(3, 0):ToString()).
        Assert:Equals(".XX/XX.", Tetrominoes:ShapeOf(4, 0):ToString()).
        Assert:Equals("XX./.XX", Tetrominoes:ShapeOf(5, 0):ToString()).
        Assert:Equals("X../XXX", Tetrominoes:ShapeOf(6, 0):ToString()).
        Assert:Equals("..X/XXX", Tetrominoes:ShapeOf(7, 0):ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheIPieceIsOneByFourAndTurnsIntoFourByOne():
        Assert:Equals(4, Tetrominoes:ShapeOf(1, 0):Width).
        Assert:Equals(1, Tetrominoes:ShapeOf(1, 0):Height).
        Assert:Equals(1, Tetrominoes:ShapeOf(1, 1):Width).
        Assert:Equals(4, Tetrominoes:ShapeOf(1, 1):Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOPieceLooksTheSameInEveryTurn():
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DO t = 1 TO 3:
            Assert:IsTrue(Tetrominoes:ShapeOf(2, t):Equals(Tetrominoes:ShapeOf(2, 0))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSZAndIPiecesRepeatAfterTwoTurnsButTheTAndTheLsDoNot():
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DO p = 1 TO 5:
            IF p = 3 THEN NEXT.
            Assert:IsTrue(Tetrominoes:ShapeOf(p, 2):Equals(Tetrominoes:ShapeOf(p, 0))).
        END.
        Assert:IsFalse(Tetrominoes:ShapeOf(3, 2):Equals(Tetrominoes:ShapeOf(3, 0))).
        Assert:IsFalse(Tetrominoes:ShapeOf(6, 2):Equals(Tetrominoes:ShapeOf(6, 0))).
        Assert:IsFalse(Tetrominoes:ShapeOf(7, 2):Equals(Tetrominoes:ShapeOf(7, 0))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheJAndLAreMirrorImagesAndSAndZAreMirrorImages():
        Assert:IsTrue(Tetrominoes:ShapeOf(6, 0):Flip():Equals(Tetrominoes:ShapeOf(7, 0))).
        Assert:IsTrue(Tetrominoes:ShapeOf(4, 0):Flip():Equals(Tetrominoes:ShapeOf(5, 0))).
    END METHOD.

END CLASS.
