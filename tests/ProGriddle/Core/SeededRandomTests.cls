USING OpenEdge.Core.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.SeededRandomTests:

    @Test.
    METHOD PUBLIC VOID TheSameSeedGivesTheSameSequence():
        DEFINE VARIABLE a AS IRandom NO-UNDO.
        DEFINE VARIABLE b AS IRandom NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        a = NEW SeededRandom(42).
        b = NEW SeededRandom(42).
        DO i = 1 TO 20:
            Assert:Equals(a:NextDecimal(), b:NextDecimal()).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DifferentSeedsGiveDifferentSequences():
        DEFINE VARIABLE a AS IRandom NO-UNDO.
        DEFINE VARIABLE b AS IRandom NO-UNDO.
        a = NEW SeededRandom(1).
        b = NEW SeededRandom(2).
        Assert:IsTrue(a:NextDecimal() <> b:NextDecimal()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItFollowsTheDocumentedGenerator():
        /* (1 * 1103515245 + 12345) mod 2^31 = 1103527590, and 1103527590 / 2^31 is about 0.51387 */
        DEFINE VARIABLE r AS IRandom NO-UNDO.
        r = NEW SeededRandom(1).
        Assert:IsTrue(ABSOLUTE(r:NextDecimal() - 0.5138700782) < 0.000001).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANegativeSeedMatchesItsAbsoluteValueAndZeroWorks():
        DEFINE VARIABLE a AS IRandom NO-UNDO.
        DEFINE VARIABLE b AS IRandom NO-UNDO.
        DEFINE VARIABLE z AS IRandom NO-UNDO.
        a = NEW SeededRandom(-77).
        b = NEW SeededRandom(77).
        Assert:Equals(a:NextDecimal(), b:NextDecimal()).
        z = NEW SeededRandom(0).
        Assert:IsTrue(z:NextDecimal() >= 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DecimalsStayInZeroToOneAndAverageNearAHalf():
        DEFINE VARIABLE r     AS IRandom NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE d     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE total AS DECIMAL NO-UNDO.
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
        DEFINE VARIABLE r    AS IRandom NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE seen AS INTEGER NO-UNDO EXTENT 6.
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
        DEFINE VARIABLE r AS IRandom NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
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
        DEFINE VARIABLE lowest AS INT64 NO-UNDO.
        DEFINE VARIABLE a      AS SeededRandom NO-UNDO.
        DEFINE VARIABLE b      AS SeededRandom NO-UNDO.
        lowest = - 9223372036854775807 - 1.
        a = NEW SeededRandom(lowest).
        b = NEW SeededRandom(0).
        Assert:Equals(b:NextDecimal(), a:NextDecimal()).
        Assert:Equals(b:NextInt(1000), a:NextInt(1000)).
    END METHOD.

END CLASS.
