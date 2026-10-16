/* A buddy and the numbers of the buddy physics. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddyTests:

    @Test.
    METHOD PUBLIC VOID ANewBuddyStandsStillWithFullHealthAndItsNameAndTeam():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        b = NEW Buddy("BOLT", 2, 100, 150).
        Assert:Equals("BOLT", b:BuddyName).
        Assert:Equals(2, b:Team).
        Assert:Equals(100, b:Health).
        Assert:Equals(100, b:X()).
        Assert:Equals(150, b:Y()).
        Assert:Equals(25600, b:X256).
        Assert:Equals(38400, b:Y256).
        Assert:Equals(1, b:Facing).
        Assert:Equals(0, b:VX).
        Assert:Equals(0, b:VY).
        Assert:Equals(150, b:PeakY).
        Assert:IsTrue(b:State = BuddyState:Standing).
        Assert:IsFalse(b:Landed).
        Assert:Equals(0, b:LastFallDamage).
        Assert:IsFalse(b:IsDead()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyNeedsANameAndATeamFromOneToFour():
        DEFINE VARIABLE b       AS Buddy   NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            b = NEW Buddy("", 1, 0, 0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            b = NEW Buddy("TAD", 5, 0, 0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            b = NEW Buddy("TAD", 0, 0, 0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWholePixelIsRoundedDownEvenBelowZero():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        b = NEW Buddy("LOU", 1, 10, 10).
        b:X256 = 255.
        Assert:Equals(0, b:X()).
        b:X256 = 256.
        Assert:Equals(1, b:X()).
        b:X256 = -1.
        Assert:Equals(-1, b:X()).
        b:X256 = -256.
        Assert:Equals(-1, b:X()).
        b:X256 = -257.
        Assert:Equals(-2, b:X()).
        b:Y256 = 3 * 256 + 100.
        Assert:Equals(3, b:Y()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlaceAtPutsItStandingStill():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        b = NEW Buddy("LOU", 1, 10, 10).
        b:VX = 50.
        b:VY = 60.
        b:State = BuddyState:Airborne.
        b:Landed = TRUE.
        b:LastFallDamage = 5.
        b:PlaceAt(40, 90).
        Assert:Equals(40, b:X()).
        Assert:Equals(90, b:Y()).
        Assert:Equals(0, b:VX).
        Assert:Equals(0, b:VY).
        Assert:Equals(90, b:PeakY).
        Assert:IsTrue(b:State = BuddyState:Standing).
        Assert:IsFalse(b:Landed).
        Assert:Equals(0, b:LastFallDamage).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HurtTakesHealthDownToZeroAndReturnsWhatItTook():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        b = NEW Buddy("LOU", 1, 10, 10).
        Assert:Equals(30, b:Hurt(30)).
        Assert:Equals(70, b:Health).
        Assert:Equals(70, b:Hurt(500)).
        Assert:Equals(0, b:Health).
        Assert:IsTrue(b:IsDead()).
        Assert:Equals(0, b:Hurt(10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HurtRefusesNegativeDamage():
        DEFINE VARIABLE b       AS Buddy   NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        b = NEW Buddy("LOU", 1, 10, 10).
        DO ON ERROR UNDO, LEAVE:
            b:Hurt(-1).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADrownedBuddyIsDeadWhateverItsHealth():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        b = NEW Buddy("LOU", 1, 10, 10).
        b:State = BuddyState:Drowned.
        Assert:IsTrue(b:IsDead()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRulesAreTheNumbersOfTheDesign():
        Assert:Equals(256, BuddyRules:Scale()).
        Assert:Equals(38, BuddyRules:Gravity()).
        Assert:Equals(2048, BuddyRules:TerminalSpeed()).
        Assert:Equals(11, BuddyRules:BuddyHeight()).
        Assert:Equals(3, BuddyRules:StepUp()).
        Assert:Equals(226, BuddyRules:WaterRow()).
        Assert:Equals(100, BuddyRules:StartHealth()).
        Assert:Equals(24, BuddyRules:FallFree()).
        Assert:Equals(343, BuddyRules:HopLift()).
        Assert:Equals(154, BuddyRules:HopForward()).
        Assert:Equals(465, BuddyRules:FlipLift()).
        Assert:Equals(96, BuddyRules:FlipBack()).
        Assert:Equals(300, BuddyRules:ArrivalFrames()).
        Assert:Equals(90, BuddyRules:BannerFrames()).
        Assert:Equals(2700, BuddyRules:TurnFrames()).
        Assert:Equals(180, BuddyRules:RetreatFrames()).
        Assert:Equals(30, BuddyRules:SettleFrames()).
        Assert:Equals(10, BuddyRules:WindMax()).
    END METHOD.

END CLASS.
