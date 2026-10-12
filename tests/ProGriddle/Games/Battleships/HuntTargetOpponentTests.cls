USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.HuntTargetOpponentTests:

    DEFINE PRIVATE VARIABLE mOpponent AS HuntTargetOpponent NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildOpponent():
        mOpponent = NEW HuntTargetOpponent(NEW SeededRandom(3)).
        mOpponent:Reset(10, 10).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseOpponent():
        IF VALID-OBJECT(mOpponent) THEN mOpponent:Dispose().
        mOpponent = ?.
    END METHOD.

    /* True when the two cells are next to each other, up, down, left or right. */
    METHOD PRIVATE LOGICAL Adjacent(INPUT px AS INTEGER, INPUT py AS INTEGER, INPUT qx AS INTEGER, INPUT qy AS INTEGER):
        RETURN ABSOLUTE(px - qx) + ABSOLUTE(py - qy) = 1.
    END METHOD.

    /* ---- shooting ---- */

    @Test.
    METHOD PUBLIC VOID ItNeverFiresAtTheSameCellTwiceAndUsesEveryCellInTheEnd():
        DEFINE VARIABLE o     AS HuntTargetOpponent NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE seen  AS LOGICAL NO-UNDO EXTENT 36.
        DEFINE VARIABLE twice AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            o = NEW HuntTargetOpponent(NEW SeededRandom(9)).
            o:Reset(6, 6).
            DO i = 1 TO 36:
                o:NextShot(OUTPUT x, OUTPUT y).
                IF seen[y * 6 + x + 1] THEN twice = twice + 1.
                seen[y * 6 + x + 1] = TRUE.
                o:Observe(x, y, FALSE, FALSE).
            END.
            Assert:Equals(0, twice).
            FINALLY:
                IF VALID-OBJECT(o) THEN o:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID WhenEveryCellHasBeenFiredAtItThrows():
        DEFINE VARIABLE o AS HuntTargetOpponent NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            o = NEW HuntTargetOpponent(NEW SeededRandom(9)).
            o:Reset(3, 3).
            DO i = 1 TO 10:
                o:NextShot(OUTPUT x, OUTPUT y).
                o:Observe(x, y, FALSE, FALSE).
            END.
            FINALLY:
                IF VALID-OBJECT(o) THEN o:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShotsAreOnAChessboardPatternWhileHunting():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE parity AS INTEGER NO-UNDO.
        DEFINE VARIABLE offPattern    AS INTEGER NO-UNDO.
        mOpponent:NextShot(OUTPUT x, OUTPUT y).
        parity = (x + y) MODULO 2.
        mOpponent:Observe(x, y, FALSE, FALSE).
        DO i = 1 TO 30:
            mOpponent:NextShot(OUTPUT x, OUTPUT y).
            IF (x + y) MODULO 2 <> parity THEN offPattern = offPattern + 1.
            mOpponent:Observe(x, y, FALSE, FALSE).
        END.
        Assert:Equals(0, offPattern).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterALoneHitItFiresNextToIt():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        mOpponent:Observe(5, 5, TRUE, FALSE).
        mOpponent:NextShot(OUTPUT x, OUTPUT y).
        Assert:IsTrue(Adjacent(x, y, 5, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterTwoHitsInARowItOnlyExtendsTheLine():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE bad AS INTEGER NO-UNDO.
        mOpponent:Observe(4, 5, TRUE, FALSE).
        mOpponent:Observe(5, 5, TRUE, FALSE).
        /* the line runs along row 5, so the only sensible cells are (3,5) and (6,5) */
        DO i = 1 TO 2:
            mOpponent:NextShot(OUTPUT x, OUTPUT y).
            IF NOT ((y = 5 AND (x = 3 OR x = 6))) THEN bad = bad + 1.
            mOpponent:Observe(x, y, FALSE, FALSE).
        END.
        Assert:Equals(0, bad).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterTwoHitsInAColumnItOnlyExtendsTheColumn():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        mOpponent:Observe(2, 3, TRUE, FALSE).
        mOpponent:Observe(2, 4, TRUE, FALSE).
        mOpponent:NextShot(OUTPUT x, OUTPUT y).
        Assert:IsTrue(x = 2 AND (y = 2 OR y = 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineBlockedAtOneEndContinuesAtTheOther():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        mOpponent:Observe(0, 0, TRUE, FALSE).
        mOpponent:Observe(1, 0, TRUE, FALSE).
        /* (0,0) is at the edge, so the only way on is (2,0) */
        mOpponent:NextShot(OUTPUT x, OUTPUT y).
        Assert:IsTrue(x = 2 AND y = 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMissNextToAHitIsNotFiredAtAgain():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE repeats AS INTEGER NO-UNDO.
        mOpponent:Observe(5, 5, TRUE, FALSE).
        mOpponent:Observe(4, 5, FALSE, FALSE).
        mOpponent:Observe(6, 5, FALSE, FALSE).
        DO i = 1 TO 2:
            mOpponent:NextShot(OUTPUT x, OUTPUT y).
            IF NOT (x = 5 AND (y = 4 OR y = 6)) THEN repeats = repeats + 1.
            mOpponent:Observe(x, y, FALSE, FALSE).
        END.
        Assert:Equals(0, repeats).
    END METHOD.

    /* ---- sinking ---- */

    @Test.
    METHOD PUBLIC VOID ASunkShipAndTheWaterAllRoundItAreKnown():
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        mOpponent:Observe(4, 4, TRUE, FALSE).
        mOpponent:Observe(5, 4, TRUE, FALSE).
        mOpponent:Observe(6, 4, TRUE, TRUE).
        Assert:Equals(3, mOpponent:KnownAt(4, 4)).
        Assert:Equals(3, mOpponent:KnownAt(5, 4)).
        Assert:Equals(3, mOpponent:KnownAt(6, 4)).
        DO dy = 3 TO 5:
            DO dx = 3 TO 7:
                IF NOT (dy = 4 AND dx >= 4 AND dx <= 6) THEN Assert:Equals(1, mOpponent:KnownAt(dx, dy)).
            END.
        END.
        Assert:Equals(0, mOpponent:KnownAt(2, 4)).
        Assert:Equals(0, mOpponent:KnownAt(4, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASunkShipOnTheEdgeMarksOnlyCellsOnTheBoard():
        mOpponent:Observe(0, 0, TRUE, FALSE).
        mOpponent:Observe(0, 1, TRUE, TRUE).
        Assert:Equals(1, mOpponent:KnownAt(1, 0)).
        Assert:Equals(1, mOpponent:KnownAt(1, 1)).
        Assert:Equals(1, mOpponent:KnownAt(1, 2)).
        Assert:Equals(1, mOpponent:KnownAt(0, 2)).
        Assert:Equals(0, mOpponent:KnownAt(2, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterSinkingItGoesBackToHuntingAndNeverFiresAtTheWater():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE inside AS INTEGER NO-UNDO.
        mOpponent:Observe(4, 4, TRUE, FALSE).
        mOpponent:Observe(5, 4, TRUE, TRUE).
        DO i = 1 TO 40:
            mOpponent:NextShot(OUTPUT x, OUTPUT y).
            IF x >= 3 AND x <= 6 AND y >= 3 AND y <= 5 THEN inside = inside + 1.
            mOpponent:Observe(x, y, FALSE, FALSE).
        END.
        Assert:Equals(0, inside).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASecondShipNextDoorIsStillTargetedAfterTheFirstIsSunk():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        /* the first ship, sunk; then a hit on another ship two cells away */
        mOpponent:Observe(1, 1, TRUE, FALSE).
        mOpponent:Observe(2, 1, TRUE, TRUE).
        mOpponent:Observe(6, 6, TRUE, FALSE).
        mOpponent:NextShot(OUTPUT x, OUTPUT y).
        Assert:IsTrue(Adjacent(x, y, 6, 6)).
    END METHOD.

    /* ---- the rest of the contract ---- */

    @Test.
    METHOD PUBLIC VOID TheSameSeedPlaysTheSameShots():
        DEFINE VARIABLE a  AS HuntTargetOpponent NO-UNDO.
        DEFINE VARIABLE b  AS HuntTargetOpponent NO-UNDO.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE ax AS INTEGER NO-UNDO.
        DEFINE VARIABLE ay AS INTEGER NO-UNDO.
        DEFINE VARIABLE bx AS INTEGER NO-UNDO.
        DEFINE VARIABLE by2 AS INTEGER NO-UNDO.
        DEFINE VARIABLE differ AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = NEW HuntTargetOpponent(NEW SeededRandom(21)).
            b = NEW HuntTargetOpponent(NEW SeededRandom(21)).
            a:Reset(10, 10).
            b:Reset(10, 10).
            DO i = 1 TO 40:
                a:NextShot(OUTPUT ax, OUTPUT ay).
                b:NextShot(OUTPUT bx, OUTPUT by2).
                IF ax <> bx OR ay <> by2 THEN differ = differ + 1.
                a:Observe(ax, ay, i MODULO 7 = 0, FALSE).
                b:Observe(bx, by2, i MODULO 7 = 0, FALSE).
            END.
            Assert:Equals(0, differ).
            FINALLY:
                IF VALID-OBJECT(a) THEN a:Dispose().
                IF VALID-OBJECT(b) THEN b:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ResetForgetsEverything():
        mOpponent:Observe(3, 3, TRUE, FALSE).
        mOpponent:Observe(3, 4, FALSE, FALSE).
        mOpponent:Reset(10, 10).
        Assert:Equals(0, mOpponent:KnownAt(3, 3)).
        Assert:Equals(0, mOpponent:KnownAt(3, 4)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ObservingOffTheBoardThrows():
        mOpponent:Observe(10, 0, FALSE, FALSE).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ASinkingMissThrows():
        mOpponent:Observe(1, 1, FALSE, TRUE).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ShootingBeforeAResetThrows():
        DEFINE VARIABLE o AS HuntTargetOpponent NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        o = NEW HuntTargetOpponent(NEW SeededRandom(1)).
        o:NextShot(OUTPUT x, OUTPUT y).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABoardUnderTwoByTwoThrows():
        mOpponent:Reset(1, 5).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnOpponentNeedsARandomSource():
        DEFINE VARIABLE o AS HuntTargetOpponent NO-UNDO.
        o = NEW HuntTargetOpponent(?).
    END METHOD.

END CLASS.
