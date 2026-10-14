/* The rocks: slots with a size, a place, a velocity and a spin, moving on a screen that wraps. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.RockFieldTests:

    DEFINE PRIVATE VARIABLE mRocks AS RockField NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildField():
        mRocks = NEW RockField().
    END METHOD.

    /* A cell as units. */
    METHOD PRIVATE INTEGER U(INPUT piCells AS INTEGER):
        RETURN piCells * 4096.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT piWhich AS INTEGER):
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN mRocks:Add(0, 0, 0, 0, 0, 0, 0, 10, 1).
                WHEN 2 THEN mRocks:Add(0, 0, 0, 0, 4, 0, 0, 10, 1).
                WHEN 3 THEN mRocks:Add(0, 0, 0, 0, 1, 0, 0, 0, 1).
                WHEN 4 THEN mRocks:SizeAt(-1).
                WHEN 5 THEN mRocks:SizeAt(64).
                WHEN 6 THEN mRocks:Remove(99).
                WHEN 7 THEN mRocks:X(-1).
                WHEN 8 THEN mRocks:Add(0, 0, 0, 0, 1, 0, 0, 10, 2).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewFieldHasNoRocksAndRoomForSixtyFour():
        Assert:Equals(0, mRocks:Count).
        Assert:Equals(64, RockField:Capacity()).
        Assert:Equals(0, mRocks:CountOfSize(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AddingARockGivesItASlotAndKeepsWhatItWasTold():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        i = mRocks:Add(U(10), U(20), 100, -200, 2, 3, 5, 30, -1).
        Assert:Equals(1, mRocks:Count).
        Assert:Equals(2, mRocks:SizeAt(i)).
        Assert:Equals(U(10), mRocks:X(i)).
        Assert:Equals(U(20), mRocks:Y(i)).
        Assert:Equals(100, mRocks:VX(i)).
        Assert:Equals(-200, mRocks:VY(i)).
        Assert:Equals(3, mRocks:Variant(i)).
        Assert:Equals(5, mRocks:HeadingAt(i)).
        Assert:Equals(1, mRocks:CountOfSize(2)).
        Assert:IsTrue(mRocks:Alive(i)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstFreeSlotIsUsedAndARemovedRockLeavesItFree():
        DEFINE VARIABLE a AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        a = mRocks:Add(0, 0, 0, 0, 1, 0, 0, 10, 1).
        b = mRocks:Add(0, 0, 0, 0, 1, 0, 0, 10, 1).
        Assert:IsTrue(a <> b).
        mRocks:Remove(a).
        Assert:Equals(1, mRocks:Count).
        Assert:IsFalse(mRocks:Alive(a)).
        Assert:Equals(0, mRocks:SizeAt(a)).
        c = mRocks:Add(0, 0, 0, 0, 3, 0, 0, 10, 1).
        Assert:Equals(a, c).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MoveAddsTheVelocityAndWrapsOverEveryEdge():
        DEFINE VARIABLE a AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        a = mRocks:Add(U(10), U(10), 1000, 500, 1, 0, 0, 100, 1).
        b = mRocks:Add(U(319), U(5), U(2), 0 - U(7), 1, 0, 0, 100, 1).
        c = mRocks:Add(U(2), U(238), 0 - U(5), U(3), 1, 0, 0, 100, 1).
        mRocks:Move().
        Assert:Equals(U(10) + 1000, mRocks:X(a)).
        Assert:Equals(U(10) + 500, mRocks:Y(a)).
        Assert:Equals(U(1), mRocks:X(b)).
        Assert:Equals(U(238), mRocks:Y(b)).
        Assert:Equals(U(317), mRocks:X(c)).
        Assert:Equals(U(1), mRocks:Y(c)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARockSpinsOneHeadingStepEveryPeriodFramesInItsDirection():
        DEFINE VARIABLE a AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        a = mRocks:Add(0, 0, 0, 0, 1, 0, 10, 4, 1).
        b = mRocks:Add(0, 0, 0, 0, 1, 0, 0, 3, -1).
        DO i = 1 TO 3:
            mRocks:Move().
        END.
        Assert:Equals(10, mRocks:HeadingAt(a)).
        Assert:Equals(63, mRocks:HeadingAt(b)).
        mRocks:Move().
        Assert:Equals(11, mRocks:HeadingAt(a)).
        DO i = 1 TO 6:
            mRocks:Move().
        END.
        Assert:Equals(61, mRocks:HeadingAt(b)).
        Assert:Equals(12, mRocks:HeadingAt(a)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewRockFlashesForSixFramesAndThenStops():
        DEFINE VARIABLE a AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        a = mRocks:Add(0, 0, 0, 0, 1, 0, 0, 10, 1).
        Assert:Equals(6, mRocks:Flash(a)).
        DO i = 1 TO 5:
            mRocks:Move().
        END.
        Assert:Equals(1, mRocks:Flash(a)).
        mRocks:Move().
        Assert:Equals(0, mRocks:Flash(a)).
        mRocks:Move().
        Assert:Equals(0, mRocks:Flash(a)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CountOfSizeCountsEachSizeAndClearEmptiesTheField():
        mRocks:Add(0, 0, 0, 0, 1, 0, 0, 10, 1).
        mRocks:Add(0, 0, 0, 0, 3, 0, 0, 10, 1).
        mRocks:Add(0, 0, 0, 0, 3, 0, 0, 10, 1).
        Assert:Equals(3, mRocks:Count).
        Assert:Equals(1, mRocks:CountOfSize(1)).
        Assert:Equals(0, mRocks:CountOfSize(2)).
        Assert:Equals(2, mRocks:CountOfSize(3)).
        mRocks:Clear().
        Assert:Equals(0, mRocks:Count).
        Assert:Equals(0, mRocks:CountOfSize(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFieldHoldsSixtyFourRocksAndRefusesTheNext():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO i = 1 TO 64:
            mRocks:Add(0, 0, 0, 0, 3, 0, 0, 10, 1).
        END.
        Assert:Equals(64, mRocks:Count).
        DO ON ERROR UNDO, THROW:
            mRocks:Add(0, 0, 0, 0, 3, 0, 0, 10, 1).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BadRocksAndBadSlotsAreRefused():
        Assert:IsTrue(Refused(1)).
        Assert:IsTrue(Refused(2)).
        Assert:IsTrue(Refused(3)).
        Assert:IsTrue(Refused(4)).
        Assert:IsTrue(Refused(5)).
        Assert:IsTrue(Refused(6)).
        Assert:IsTrue(Refused(7)).
        Assert:IsTrue(Refused(8)).
    END METHOD.

END CLASS.
