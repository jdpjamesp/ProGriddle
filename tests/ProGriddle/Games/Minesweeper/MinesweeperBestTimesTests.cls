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
    METHOD PUBLIC VOID ThereIsNoBestTimeToBeginWith():
        Assert:Equals(0, mBest:Best("Beginner")).
        Assert:Equals(0, mBest:Best("Intermediate")).
        Assert:Equals(0, mBest:Best("Expert")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstWinIsANewBestAndIsKept():
        Assert:IsTrue(mBest:Record("Beginner", 47)).
        Assert:Equals(47, mBest:Best("Beginner")).
        Assert:Equals(47, mSettings:GetInteger("minesweeper.best.beginner", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyAFasterTimeReplacesTheBest():
        mBest:Record("Expert", 200).
        Assert:IsFalse(mBest:Record("Expert", 200)).
        Assert:IsFalse(mBest:Record("Expert", 250)).
        Assert:Equals(200, mBest:Best("Expert")).
        Assert:IsTrue(mBest:Record("Expert", 199)).
        Assert:Equals(199, mBest:Best("Expert")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachLevelKeepsItsOwnBest():
        mBest:Record("Beginner", 10).
        mBest:Record("Intermediate", 90).
        Assert:Equals(10, mBest:Best("Beginner")).
        Assert:Equals(90, mBest:Best("Intermediate")).
        Assert:Equals(0, mBest:Best("Expert")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CustomGamesKeepNoRecord():
        Assert:IsFalse(mBest:Record("Custom", 5)).
        Assert:Equals(0, mBest:Best("Custom")).
        Assert:IsFalse(mSettings:Has("minesweeper.best.custom")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TimesOutsideOneTo999AreNotRecorded():
        Assert:IsFalse(mBest:Record("Beginner", 0)).
        Assert:IsFalse(mBest:Record("Beginner", -4)).
        Assert:IsFalse(mBest:Record("Beginner", 1000)).
        Assert:IsFalse(mBest:Record("Beginner", ?)).
        Assert:Equals(0, mBest:Best("Beginner")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALevelNameInAnyCaseWorks():
        mBest:Record("beginner", 33).
        Assert:Equals(33, mBest:Best("BEGINNER")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABestTimeAlreadyInTheSettingsIsRead():
        mSettings:SetInteger("minesweeper.best.expert", 150).
        Assert:Equals(150, mBest:Best("Expert")).
        Assert:IsFalse(mBest:Record("Expert", 151)).
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
    METHOD PUBLIC VOID BestTimesNeedSettings():
        DEFINE VARIABLE b AS MinesweeperBestTimes NO-UNDO.
        b = NEW MinesweeperBestTimes(?).
    END METHOD.

END CLASS.
