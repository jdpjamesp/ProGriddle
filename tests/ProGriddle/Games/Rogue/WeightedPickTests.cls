/* A pick by chances written as a comma list. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.WeightedPickTests:

    @Test.
    METHOD PUBLIC VOID TheTotalIsTheSumOfTheChances():
        Assert:Equals(100, WeightedPick:Total("26,36,16,7,7,4,4")).
        Assert:Equals(5, WeightedPick:Total("5")).
        Assert:Equals(3, WeightedPick:Total("0,3,0")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APickLandsInTheThingWhoseChancesTheRollFallsIn():
        /* chances 3,2,5: rolls 0-2 pick the first, 3-4 the second, 5-9 the third */
        Assert:Equals(0, WeightedPick:Choose("3,2,5", NEW ScriptedRandom("0"))).
        Assert:Equals(0, WeightedPick:Choose("3,2,5", NEW ScriptedRandom("2"))).
        Assert:Equals(1, WeightedPick:Choose("3,2,5", NEW ScriptedRandom("3"))).
        Assert:Equals(1, WeightedPick:Choose("3,2,5", NEW ScriptedRandom("4"))).
        Assert:Equals(2, WeightedPick:Choose("3,2,5", NEW ScriptedRandom("5"))).
        Assert:Equals(2, WeightedPick:Choose("3,2,5", NEW ScriptedRandom("9"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATingWithNoChanceIsNeverPicked():
        DEFINE VARIABLE i       AS INTEGER      NO-UNDO.
        DEFINE VARIABLE oRandom AS SeededRandom NO-UNDO.
        oRandom = NEW SeededRandom(11).
        DO i = 1 TO 300:
            Assert:IsTrue(WeightedPick:Choose("5,0,5", oRandom) <> 1).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BadListsAndNoSourceAreRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            WeightedPick:Total("").
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            WeightedPick:Total("3,x").
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            WeightedPick:Total("3,-1").
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            WeightedPick:Choose("0,0", NEW ScriptedRandom("1")).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            WeightedPick:Choose("1,1", ?).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(5, thrown).
    END METHOD.

END CLASS.
