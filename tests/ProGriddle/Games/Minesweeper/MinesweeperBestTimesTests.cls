USING OpenEdge.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperBestTimesTests:

    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings        NO-UNDO.
    DEFINE PRIVATE VARIABLE mBest     AS MinesweeperBestTimes  NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildBest():
        mSettings = NEW MemorySettings().
        mBest = NEW MinesweeperBestTimes(mSettings).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoListToBeginWith():
        Assert:Equals("", mBest:Scores("Beginner")).
        Assert:Equals(0, mBest:Count("Beginner")).
        Assert:Equals(0, mBest:Best("Beginner")).
        Assert:Equals(0, mBest:Best("Intermediate")).
        Assert:Equals(0, mBest:Best("Expert")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstWinIsPlaceOneAndIsKeptInTheSettings():
        Assert:Equals(1, mBest:Record("Beginner", 47)).
        Assert:Equals(47, mBest:Best("Beginner")).
        Assert:Equals("47", mSettings:GetString("minesweeper.scores.beginner", "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TimesAreKeptFastestFirstAndReturnTheirPlace():
        Assert:Equals(1, mBest:Record("Expert", 200)).
        Assert:Equals(2, mBest:Record("Expert", 250)).
        Assert:Equals(1, mBest:Record("Expert", 199)).
        Assert:Equals(3, mBest:Record("Expert", 220)).
        Assert:Equals("199,200,220,250", mBest:Scores("Expert")).
        Assert:Equals(4, mBest:Count("Expert")).
        Assert:Equals(199, mBest:Best("Expert")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATimeThatTiesAnOlderOneRanksBelowIt():
        mBest:Record("Beginner", 30).
        mBest:Record("Beginner", 50).
        Assert:Equals(2, mBest:Record("Beginner", 30)).
        Assert:Equals(4, mBest:Record("Beginner", 50)).
        Assert:Equals("30,30,50,50", mBest:Scores("Beginner")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheListKeepsTheTenFastestAndDropsTheRest():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 10:
            mBest:Record("Beginner", 100 + i).
        END.
        Assert:Equals(10, mBest:Count("Beginner")).
        Assert:Equals(0, mBest:Record("Beginner", 120)).
        Assert:Equals(0, mBest:Record("Beginner", 110)).
        Assert:Equals(10, mBest:Count("Beginner")).
        Assert:Equals(1, mBest:Record("Beginner", 5)).
        Assert:Equals(10, mBest:Count("Beginner")).
        Assert:Equals("5,101,102,103,104,105,106,107,108,109", mBest:Scores("Beginner")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATimeFasterThanTheSlowestOfAFullListTakesItsPlace():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 10:
            mBest:Record("Beginner", 100 + i).
        END.
        Assert:Equals(10, mBest:Record("Beginner", 109)).
        Assert:Equals("101,102,103,104,105,106,107,108,109,109", mBest:Scores("Beginner")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachLevelKeepsItsOwnList():
        mBest:Record("Beginner", 10).
        mBest:Record("Intermediate", 90).
        Assert:Equals("10", mBest:Scores("Beginner")).
        Assert:Equals("90", mBest:Scores("Intermediate")).
        Assert:Equals("", mBest:Scores("Expert")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CustomGamesKeepNoList():
        Assert:Equals(0, mBest:Record("Custom", 5)).
        Assert:Equals(0, mBest:Best("Custom")).
        Assert:Equals("", mBest:Scores("Custom")).
        Assert:IsFalse(mSettings:Has("minesweeper.scores.custom")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TimesOutsideOneTo999AreNotRecorded():
        Assert:Equals(0, mBest:Record("Beginner", 0)).
        Assert:Equals(0, mBest:Record("Beginner", -4)).
        Assert:Equals(0, mBest:Record("Beginner", 1000)).
        Assert:Equals(0, mBest:Record("Beginner", ?)).
        Assert:Equals(0, mBest:Count("Beginner")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALevelNameInAnyCaseWorks():
        mBest:Record("beginner", 33).
        Assert:Equals(33, mBest:Best("BEGINNER")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AListAlreadyInTheSettingsIsRead():
        mSettings:SetString("minesweeper.scores.expert", "150,170").
        Assert:Equals(150, mBest:Best("Expert")).
        Assert:Equals(2, mBest:Count("Expert")).
        Assert:Equals(2, mBest:Record("Expert", 151)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHandEditedListIsPutInOrderAndBadEntriesAreDropped():
        mSettings:SetString("minesweeper.scores.beginner", "90, 12,abc,0,1500,45").
        Assert:Equals("12,45,90", mBest:Scores("Beginner")).
        Assert:Equals(12, mBest:Best("Beginner")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnOverlongHandEditedListIsCutToTen():
        mSettings:SetString("minesweeper.scores.beginner", "1,2,3,4,5,6,7,8,9,10,11,12").
        Assert:Equals(10, mBest:Count("Beginner")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheListSizeIsTen():
        Assert:Equals(10, MinesweeperBestTimes:ListSize()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownLevelThrows():
        mBest:Best("Nightmare").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RecordingAnUnknownLevelThrows():
        mBest:Record("Nightmare", 10).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ScoresOfAnUnknownLevelThrows():
        mBest:Scores("Nightmare").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID BestTimesNeedSettings():
        DEFINE VARIABLE b AS MinesweeperBestTimes NO-UNDO.
        b = NEW MinesweeperBestTimes(?).
    END METHOD.

END CLASS.
