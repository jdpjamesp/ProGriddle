USING OpenEdge.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisHighScoresTests:

    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings    NO-UNDO.
    DEFINE PRIVATE VARIABLE mScores   AS TetrisHighScores  NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildScores():
        mSettings = NEW MemorySettings().
        mScores = NEW TetrisHighScores(mSettings).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoListToBeginWith():
        Assert:Equals(0, mScores:Count()).
        Assert:Equals(0, mScores:Best()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstScoreIsPlaceOneAndIsKeptInTheSettings():
        Assert:Equals(1, mScores:Record(1200, 8)).
        Assert:Equals(1200, mScores:Best()).
        Assert:Equals(8, mScores:LinesAt(1)).
        Assert:Equals("1200:8", mSettings:GetString("tetris.scores", "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ScoresAreKeptBestFirstAndReturnTheirPlace():
        Assert:Equals(1, mScores:Record(500, 4)).
        Assert:Equals(1, mScores:Record(900, 7)).
        Assert:Equals(3, mScores:Record(100, 1)).
        Assert:Equals(2, mScores:Record(700, 5)).
        Assert:Equals("900:7,700:5,500:4,100:1", mSettings:GetString("tetris.scores", "")).
        Assert:Equals(4, mScores:Count()).
        Assert:Equals(700, mScores:ScoreAt(2)).
        Assert:Equals(5, mScores:LinesAt(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScoreThatTiesAnOlderOneRanksBelowIt():
        mScores:Record(300, 2).
        Assert:Equals(2, mScores:Record(300, 3)).
        Assert:Equals(2, mScores:LinesAt(1)).
        Assert:Equals(3, mScores:LinesAt(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheListKeepsTheTenBestAndDropsTheRest():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 10:
            mScores:Record(i * 100, i).
        END.
        Assert:Equals(10, mScores:Count()).
        Assert:Equals(0, mScores:Record(100, 1)).
        Assert:Equals(0, mScores:Record(50, 1)).
        Assert:Equals(1, mScores:Record(5000, 40)).
        Assert:Equals(10, mScores:Count()).
        Assert:Equals(5000, mScores:Best()).
        Assert:Equals(200, mScores:ScoreAt(10)).
        Assert:Equals(10, TetrisHighScores:ListSize()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScoreOfNothingIsNotRecorded():
        Assert:Equals(0, mScores:Record(0, 0)).
        Assert:Equals(0, mScores:Record(-5, 0)).
        Assert:Equals(0, mScores:Record(?, 0)).
        Assert:Equals(0, mScores:Count()).
        Assert:Equals("", mSettings:GetString("tetris.scores", "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewObjectOnTheSameSettingsSeesTheSameList():
        DEFINE VARIABLE other AS TetrisHighScores NO-UNDO.
        mScores:Record(800, 6).
        other = NEW TetrisHighScores(mSettings).
        Assert:Equals(800, other:Best()).
        Assert:Equals(1, other:Count()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHandEditedListIsCleanedAndPutInOrder():
        mSettings:SetString("tetris.scores", "100:1,junk,300:2,0:0,-4:1,200:x,250:2:9,500:4").
        Assert:Equals(3, mScores:Count()).
        Assert:Equals(500, mScores:ScoreAt(1)).
        Assert:Equals(300, mScores:ScoreAt(2)).
        Assert:Equals(100, mScores:ScoreAt(3)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID APlaceOffTheListThrows():
        mScores:ScoreAt(1).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheConstructorNeedsSettings():
        DEFINE VARIABLE s AS TetrisHighScores NO-UNDO.
        s = NEW TetrisHighScores(?).
    END METHOD.

END CLASS.
