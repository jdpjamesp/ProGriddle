/* The ten best games: kept sorted, kept in the settings, and read back. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueScoresTests:

    VAR PRIVATE ISettings mSettings.
    VAR PRIVATE RogueScores mScores.

    @Setup.
    METHOD PUBLIC VOID BuildScores():
        mSettings = NEW MemorySettings().
        mScores = NEW RogueScores(mSettings).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewListIsEmpty():
        Assert:Equals(0, mScores:Count).
        Assert:Equals("", mScores:Text()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameIsPlacedBySoreHighestFirst():
        Assert:Equals(1, mScores:Add(100, 3, "a bat", FALSE)).
        Assert:Equals(1, mScores:Add(500, 5, "an orc", FALSE)).
        Assert:Equals(2, mScores:Add(300, 4, "a snake", FALSE)).
        Assert:Equals(3, mScores:Count).
        Assert:Equals(500, mScores:ScoreAt(1)).
        Assert:Equals(300, mScores:ScoreAt(2)).
        Assert:Equals(100, mScores:ScoreAt(3)).
        Assert:Equals(4, mScores:DepthAt(2)).
        Assert:Equals("a snake", mScores:CauseAt(2)).
        Assert:IsFalse(mScores:WonAt(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATieGoesBelowTheGameAlreadyThere():
        mScores:Add(200, 3, "first", FALSE).
        Assert:Equals(2, mScores:Add(200, 3, "second", FALSE)).
        Assert:Equals("first", mScores:CauseAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyTheTenBestAreKept():
        VAR INTEGER i.
        DO i = 1 TO 12:
            mScores:Add(i * 100, i, "x", FALSE).
        END.
        Assert:Equals(10, mScores:Count).
        Assert:Equals(1200, mScores:ScoreAt(1)).
        Assert:Equals(300, mScores:ScoreAt(10)).
        Assert:Equals(0, mScores:Add(50, 1, "too low", FALSE)).
        Assert:Equals(10, mScores:Count).
        Assert:Equals(0, mScores:Add(299, 1, "just under", FALSE)).
        Assert:Equals(10, mScores:Add(301, 1, "just over", FALSE)).
        Assert:Equals(0, mScores:Add(1, 1, "nothing", FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheListIsKeptInTheSettingsAndReadBack():
        VAR RogueScores oAgain.
        mScores:Add(700, 6, "a troll", FALSE).
        mScores:Add(900, 1, "the Amulet", TRUE).
        oAgain = NEW RogueScores(mSettings).
        Assert:Equals(2, oAgain:Count).
        Assert:Equals(900, oAgain:ScoreAt(1)).
        Assert:IsTrue(oAgain:WonAt(1)).
        Assert:Equals("a troll", oAgain:CauseAt(2)).
        Assert:Equals(6, oAgain:DepthAt(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADamagedEntryIsLeftOut():
        VAR RogueScores oList.
        mSettings:SetString("rogue.scores", "100|2|a bat|0;nonsense;x|2|y|0;300|4|an orc|0").
        oList = NEW RogueScores(mSettings).
        Assert:Equals(2, oList:Count).
        Assert:Equals(100, oList:ScoreAt(1)).
        Assert:Equals(300, oList:ScoreAt(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSeparatorsAreTakenOutOfACause():
        mScores:Add(10, 1, "a|b;c", FALSE).
        Assert:Equals("a b c", mScores:CauseAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EndingsAreSaidInWords():
        Assert:Equals("killed by a bat", RogueScores:Ending(FALSE, "a bat")).
        Assert:Equals("quit", RogueScores:Ending(FALSE, "quit")).
        Assert:Equals("starved to death", RogueScores:Ending(FALSE, "starvation")).
        Assert:Equals("escaped with the Amulet of Yendor", RogueScores:Ending(TRUE, "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineHasTheRankTheScoreTheLevelAndHowItEnded():
        mScores:Add(1234, 7, "a yeti", FALSE).
        Assert:IsTrue(INDEX(mScores:Line(1), "1234") > 0).
        Assert:IsTrue(INDEX(mScores:Line(1), "level 7") > 0).
        Assert:IsTrue(INDEX(mScores:Line(1), "killed by a yeti") > 0).
        mScores:Add(50, 1, "quit", FALSE).
        Assert:Equals(2, NUM-ENTRIES(mScores:Text(), CHR(10))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlaceOffTheListAndNoSettingsAreRefused():
        VAR INTEGER thrown.
        DO ON ERROR UNDO, THROW:
            mScores:ScoreAt(1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW RogueScores(?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        mScores:Add(10, 1, "x", FALSE).
        DO ON ERROR UNDO, THROW:
            mScores:Line(2).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
