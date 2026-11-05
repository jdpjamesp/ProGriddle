/* How the air enemies of Xevious fly: the triangle wave, and where each kind is at a given age. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousMotionTests:

    @Test.
    METHOD PUBLIC VOID DivisionGoesTowardsZero():
        Assert:Equals(3, XeviousMotion:Div(7, 2)).
        Assert:Equals(-3, XeviousMotion:Div(-7, 2)).
        Assert:Equals(0, XeviousMotion:Div(1, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWaveStartsAtZeroPeaksTroughsAndComesBack():
        Assert:Equals(0, XeviousMotion:Wave(0, 80, 40)).
        Assert:Equals(40, XeviousMotion:Wave(20, 80, 40)).
        Assert:Equals(0, XeviousMotion:Wave(40, 80, 40)).
        Assert:Equals(-40, XeviousMotion:Wave(60, 80, 40)).
        Assert:Equals(0, XeviousMotion:Wave(80, 80, 40)).
        Assert:Equals(20, XeviousMotion:Wave(10, 80, 40)).
        Assert:Equals(-20, XeviousMotion:Wave(70, 80, 40)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWaveNeverLeavesItsAmplitude():
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DO t = 0 TO 400:
            Assert:IsTrue(XeviousMotion:Wave(t, 92, 30) >= -30).
            Assert:IsTrue(XeviousMotion:Wave(t, 92, 30) <= 30).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AToroidFallsAndWeavesFromWhereItBegan():
        Assert:Equals(100, XeviousMotion:AirX(XeviousAir:Toroid, 100, 0, 1, 100)).
        Assert:Equals(140, XeviousMotion:AirX(XeviousAir:Toroid, 100, 22, 1, 100)).
        Assert:Equals(-16, XeviousMotion:AirY(XeviousAir:Toroid, -16, 0, 0)).
        Assert:Equals(24, XeviousMotion:AirY(XeviousAir:Toroid, -16, 32, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATorkanSweepsToTheSideItGoesToAndDivesInAndOut():
        Assert:Equals(8 + 60, XeviousMotion:AirX(XeviousAir:Torkan, 8, 40, 1, 8)).
        Assert:Equals(200 - 60, XeviousMotion:AirX(XeviousAir:Torkan, 200, 40, -1, 200)).
        Assert:Equals(104, XeviousMotion:AirY(XeviousAir:Torkan, -16, 60, 0)).
        Assert:IsTrue(XeviousMotion:AirY(XeviousAir:Torkan, -16, 90, 0) < 104).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKapiDivesAndThenSnapsBackUp():
        Assert:Equals(74, XeviousMotion:AirY(XeviousAir:Kapi, -16, 45, 0)).
        Assert:IsTrue(XeviousMotion:AirY(XeviousAir:Kapi, -16, 55, 0) < 74).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATerrazisFliesStraightToTheColumnItWasAimedAt():
        Assert:Equals(20, XeviousMotion:AirX(XeviousAir:Terrazi, 20, 0, 1, 160)).
        Assert:Equals(160, XeviousMotion:AirX(XeviousAir:Terrazi, 20, 70, 1, 160)).
        Assert:Equals(-16 + 3 * 10, XeviousMotion:AirY(XeviousAir:Terrazi, -16, 10, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AZakatoStaysWhereItAppeared():
        Assert:Equals(80, XeviousMotion:AirX(XeviousAir:Zakato, 80, 25, 1, 80)).
        Assert:Equals(60, XeviousMotion:AirY(XeviousAir:Zakato, 60, 25, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABacuraIsPushedBackByEveryShot():
        Assert:Equals(-24 + 50, XeviousMotion:AirY(XeviousAir:Bacura, -24, 50, 0)).
        Assert:Equals(-24 + 50 - 20, XeviousMotion:AirY(XeviousAir:Bacura, -24, 50, 10)).
        Assert:Equals(70, XeviousMotion:AirX(XeviousAir:Bacura, 70, 50, 1, 70)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOtherKindsWeaveAndFallToo():
        Assert:Equals(100 + 12, XeviousMotion:AirX(XeviousAir:GiddoSpario, 100, 15, 1, 100)).
        Assert:Equals(100 + 28, XeviousMotion:AirX(XeviousAir:Jara, 100, 12, 1, 100)).
        Assert:Equals(100 + 20, XeviousMotion:AirX(XeviousAir:Kapi, 100, 25, 1, 100)).
        Assert:Equals(-16 + 40, XeviousMotion:AirY(XeviousAir:Jara, -16, 40, 0)).
        Assert:Equals(-16 + 30, XeviousMotion:AirY(XeviousAir:GiddoSpario, -16, 40, 0)).
    END METHOD.

END CLASS.
