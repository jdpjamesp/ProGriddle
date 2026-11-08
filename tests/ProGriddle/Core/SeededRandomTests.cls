USING OpenEdge.Core.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.SeededRandomTests:

    @Test.
    METHOD PUBLIC VOID TheSameSeedGivesTheSameSequence():
        VAR IRandom a.
        VAR IRandom b.
        VAR INTEGER i.
        a = NEW SeededRandom(42).
        b = NEW SeededRandom(42).
        DO i = 1 TO 20:
            Assert:Equals(a:NextDecimal(), b:NextDecimal()).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DifferentSeedsGiveDifferentSequences():
        VAR IRandom a.
        VAR IRandom b.
        a = NEW SeededRandom(1).
        b = NEW SeededRandom(2).
        Assert:IsTrue(a:NextDecimal() <> b:NextDecimal()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItFollowsTheDocumentedGenerator():
        /* (1 * 1103515245 + 12345) mod 2^31 = 1103527590, and 1103527590 / 2^31 is about 0.51387 */
        VAR IRandom r = NEW SeededRandom(1).
        Assert:IsTrue(ABSOLUTE(r:NextDecimal() - 0.5138700782) < 0.000001).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANegativeSeedMatchesItsAbsoluteValueAndZeroWorks():
        VAR IRandom a.
        VAR IRandom b.
        VAR IRandom z.
        a = NEW SeededRandom(-77).
        b = NEW SeededRandom(77).
        Assert:Equals(a:NextDecimal(), b:NextDecimal()).
        z = NEW SeededRandom(0).
        Assert:IsTrue(z:NextDecimal() >= 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DecimalsStayInZeroToOneAndAverageNearAHalf():
        VAR IRandom r.
        VAR INTEGER i.
        VAR DECIMAL d.
        VAR DECIMAL total.
        r = NEW SeededRandom(2024).
        DO i = 1 TO 2000:
            d = r:NextDecimal().
            Assert:IsTrue(d >= 0 AND d < 1).
            total = total + d.
        END.
        Assert:IsTrue(total / 2000 > 0.45 AND total / 2000 < 0.55).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NextIntStaysBelowTheLimitAndReachesEveryValue():
        VAR IRandom r.
        VAR INTEGER i.
        VAR INTEGER n.
        VAR INTEGER[6] seen.
        r = NEW SeededRandom(7).
        DO i = 1 TO 600:
            n = r:NextInt(6).
            Assert:IsTrue(n >= 0 AND n < 6).
            seen[n + 1] = seen[n + 1] + 1.
        END.
        DO i = 1 TO 6:
            Assert:IsTrue(seen[i] > 40).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NextIntOfOneIsAlwaysZero():
        VAR IRandom r.
        VAR INTEGER i.
        r = NEW SeededRandom(3).
        DO i = 1 TO 20:
            Assert:Equals(0, r:NextInt(1)).
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID NextIntThrowsForALimitOfZero():
        NEW SeededRandom(1):NextInt(0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID NextIntThrowsForANegativeLimit():
        NEW SeededRandom(1):NextInt(-5).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMostNegativeSeedWorksAndIsTheSameAsSeedZero():
        VAR INT64 lowest.
        VAR SeededRandom a.
        VAR SeededRandom b.
        lowest = - 9223372036854775807 - 1.
        a = NEW SeededRandom(lowest).
        b = NEW SeededRandom(0).
        Assert:Equals(b:NextDecimal(), a:NextDecimal()).
        Assert:Equals(b:NextInt(1000), a:NextInt(1000)).
    END METHOD.

END CLASS.
