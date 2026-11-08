/* Dice specs such as 2d4, and lists of them such as 1d2/1d5: their parts, their range and a roll with a scripted or seeded source. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.DiceTests:

    METHOD PRIVATE LOGICAL Refused(INPUT pcSpec AS CHARACTER):
        VAR LOGICAL oRefused.
        DO ON ERROR UNDO, THROW:
            Dice:Number(pcSpec).
            CATCH e AS GridException:
                oRefused = TRUE.
            END CATCH.
        END.
        RETURN oRefused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpecHasANumberOfDiceAndSides():
        Assert:Equals(2, Dice:Number("2d4")).
        Assert:Equals(4, Dice:Sides("2d4")).
        Assert:Equals(3, Dice:Number("3d10")).
        Assert:Equals(10, Dice:Sides("3d10")).
        Assert:Equals(19, Dice:Sides("1d19")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRangeIsOneEachToAllTheSides():
        Assert:Equals(2, Dice:Lowest("2d4")).
        Assert:Equals(8, Dice:Highest("2d4")).
        Assert:Equals(0, Dice:Lowest("0d0")).
        Assert:Equals(0, Dice:Highest("0d0")).
        Assert:Equals(1, Dice:Highest("1d1")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARollAddsUpTheDice():
        /* a scripted 0 is a one on every die, a scripted 3 is a four */
        Assert:Equals(2, Dice:Roll("2d4", NEW ScriptedRandom("0"))).
        Assert:Equals(8, Dice:Roll("2d4", NEW ScriptedRandom("3"))).
        Assert:Equals(5, Dice:Roll("2d4", NEW ScriptedRandom("1,2"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARollOfNoDiceIsZeroAndUsesNoRandomNumbers():
        VAR ScriptedRandom oRandom = NEW ScriptedRandom("5").
        Assert:Equals(0, Dice:Roll("0d0", oRandom)).
        Assert:Equals(0, oRandom:Calls).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RollsStayInRangeAndReachBothEnds():
        VAR SeededRandom oRandom.
        VAR INTEGER i.
        VAR INTEGER r.
        VAR INTEGER lowest = 99.
        VAR INTEGER highest.
        oRandom = NEW SeededRandom(3).
        DO i = 1 TO 500:
            r = Dice:Roll("1d6", oRandom).
            Assert:IsTrue(r >= 1 AND r <= 6).
            lowest = MINIMUM(lowest, r).
            highest = MAXIMUM(highest, r).
        END.
        Assert:Equals(1, lowest).
        Assert:Equals(6, highest).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AListOfDiceHoldsOneSpecForEachAttack():
        Assert:Equals(1, Dice:Attacks("1d8")).
        Assert:Equals(3, Dice:Attacks("1d2/1d5/1d5")).
        Assert:Equals("1d5", Dice:Attack("1d2/1d5/3d10", 2)).
        Assert:Equals("3d10", Dice:Attack("1d2/1d5/3d10", 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BadSpecsAndBadAttackNumbersAreRefused():
        VAR INTEGER thrown.
        Assert:IsTrue(Refused("four")).
        Assert:IsTrue(Refused("d4")).
        Assert:IsTrue(Refused("2d")).
        Assert:IsTrue(Refused("xd4")).
        Assert:IsTrue(Refused(?)).
        DO ON ERROR UNDO, THROW:
            Dice:Attack("1d2/1d5", 3).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            Dice:Attacks("").
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            Dice:Roll("1d6", ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
