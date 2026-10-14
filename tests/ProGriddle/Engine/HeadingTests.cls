/* The 64 headings and their whole number sine and cosine. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.HeadingTests:

    @Test.
    METHOD PUBLIC VOID ThereAre64HeadingsAndTheScaleIs1024():
        Assert:Equals(64, Heading:Steps()).
        Assert:Equals(1024, Heading:Scale()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFourQuarterTurnsAreExact():
        Assert:Equals(0, Heading:Sin(0)).
        Assert:Equals(1024, Heading:Cos(0)).
        Assert:Equals(1024, Heading:Sin(16)).
        Assert:Equals(0, Heading:Cos(16)).
        Assert:Equals(0, Heading:Sin(32)).
        Assert:Equals(-1024, Heading:Cos(32)).
        Assert:Equals(-1024, Heading:Sin(48)).
        Assert:Equals(0, Heading:Cos(48)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheEighthTurnIsTheSquareRootOfAHalf():
        Assert:Equals(724, Heading:Sin(8)).
        Assert:Equals(724, Heading:Cos(8)).
        Assert:Equals(724, Heading:Sin(24)).
        Assert:Equals(-724, Heading:Cos(24)).
        Assert:Equals(-724, Heading:Sin(40)).
        Assert:Equals(-724, Heading:Sin(-8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryHeadingHasALengthOfOneWithinAHalfPercent():
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE len AS INT64   NO-UNDO.
        DO i = 0 TO 63:
            len = INT64(Heading:Sin(i)) * Heading:Sin(i) + INT64(Heading:Cos(i)) * Heading:Cos(i).
            Assert:IsTrue(len > 1043000 AND len < 1054000, SUBSTITUTE("heading &1 has squared length &2", i, len)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TurningOneStepMovesTheSineTheSameWayOnBothSidesOfTheTop():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 63:
            Assert:Equals(Heading:Sin(i), - Heading:Sin(64 - i)).
            Assert:Equals(Heading:Cos(i), Heading:Cos(64 - i)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStepOutsideZeroTo63IsWrappedRound():
        Assert:Equals(0, Heading:Wrap(0)).
        Assert:Equals(0, Heading:Wrap(64)).
        Assert:Equals(63, Heading:Wrap(-1)).
        Assert:Equals(1, Heading:Wrap(129)).
        Assert:Equals(Heading:Sin(8), Heading:Sin(8 + 64 * 3)).
        Assert:Equals(Heading:Cos(8), Heading:Cos(8 - 64)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownHeadingIsRefused():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            Heading:Wrap(?).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDirectionOnTheScreenHasUpAsNegativeY():
        Assert:Equals(0, Heading:DirX(0)).
        Assert:Equals(-1024, Heading:DirY(0)).
        Assert:Equals(1024, Heading:DirX(16)).
        Assert:Equals(0, Heading:DirY(16)).
        Assert:Equals(1024, Heading:DirY(32)).
        Assert:Equals(-1024, Heading:DirX(48)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NearestFindsTheHeadingThatPointsAlongAVector():
        Assert:Equals(0, Heading:Nearest(0, -5)).
        Assert:Equals(16, Heading:Nearest(5, 0)).
        Assert:Equals(32, Heading:Nearest(0, 5)).
        Assert:Equals(48, Heading:Nearest(-5, 0)).
        Assert:Equals(8, Heading:Nearest(3, -3)).
        Assert:Equals(24, Heading:Nearest(300, 300)).
        Assert:Equals(56, Heading:Nearest(-3, -3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NearestOfNothingIsStraightUpAndNearestOfAHeadingIsThatHeading():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(0, Heading:Nearest(0, 0)).
        DO i = 0 TO 63:
            Assert:Equals(i, Heading:Nearest(Heading:DirX(i), Heading:DirY(i))).
        END.
    END METHOD.

END CLASS.
