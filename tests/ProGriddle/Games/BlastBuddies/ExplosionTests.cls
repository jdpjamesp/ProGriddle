/* Shells in the air and blasts: the pool of shell slots, and what an explosion does to the ground and to the buddies near it. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.ExplosionTests:

    DEFINE PRIVATE VARIABLE mT    AS Terrain       NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlan AS TurnPlan      NO-UNDO.
    DEFINE PRIVATE VARIABLE mP    AS BuddyPhysics  NO-UNDO.
    DEFINE PRIVATE VARIABLE mX    AS Explosion     NO-UNDO.
    DEFINE PRIVATE VARIABLE mTeam AS Team          NO-UNDO.

    /* flat ground at row 150 and a team of four buddies at columns 100, 114, 128 and 300 */
    @Setup.
    METHOD PUBLIC VOID Setup():
        mT = NEW Terrain(Theme:Meadow).
        mT:FillRect(0, 150, 383, 239, TRUE).
        mP = NEW BuddyPhysics().
        mX = NEW Explosion().
        mTeam = NEW Team(1, FALSE).
        mTeam:Add(NEW Buddy("A", 1, 100, 150)).
        mTeam:Add(NEW Buddy("B", 1, 114, 150)).
        mTeam:Add(NEW Buddy("C", 1, 128, 150)).
        mTeam:Add(NEW Buddy("D", 1, 300, 150)).
        mPlan = NEW TurnPlan().
        mPlan:Add(mTeam).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID TearDown():
        mT:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlastAtTheMiddleOfABuddyDoesFullDamageAndThrowsItStraightUp():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        n = mX:Detonate(mT, mPlan, mP, 100, 145, 20, 50).
        Assert:Equals(2, n).
        Assert:Equals(50, mTeam:BuddyAt(1):Health).
        Assert:Equals(0, mTeam:BuddyAt(1):VX).
        Assert:Equals(-1024, mTeam:BuddyAt(1):VY).
        Assert:IsTrue(mTeam:BuddyAt(1):State = BuddyState:Airborne).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DamageAndKnockbackFallInAStraightLineWithDistance():
        /* buddy B is 14 pixels away along the row: half of the 28 pixel reach */
        mX:Detonate(mT, mPlan, mP, 100, 145, 20, 50).
        Assert:Equals(75, mTeam:BuddyAt(2):Health).
        Assert:Equals(512, mTeam:BuddyAt(2):VX).
        Assert:Equals(-64, mTeam:BuddyAt(2):VY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyAtTheEdgeOfTheReachOrBeyondIsLeftAlone():
        mX:Detonate(mT, mPlan, mP, 100, 145, 20, 50).
        Assert:Equals(100, mTeam:BuddyAt(3):Health).
        Assert:IsTrue(mTeam:BuddyAt(3):State = BuddyState:Standing).
        Assert:Equals(100, mTeam:BuddyAt(4):Health).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBlastCarvesTheGroundAndCrumblesWhatItLeaves():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        before = mT:SolidCount().
        mX:Detonate(mT, mPlan, mP, 200, 150, 20, 50).
        Assert:IsFalse(mT:IsSolid(200, 160)).
        Assert:IsTrue(mT:IsSolid(200, 175)).
        Assert:IsTrue(mT:SolidCount() < before).
        Assert:IsTrue(mT:HasDirty()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHitsAreListedWithWhatEachTook():
        mX:Detonate(mT, mPlan, mP, 100, 145, 20, 50).
        Assert:Equals(2, mX:HitCount()).
        Assert:IsTrue(mX:HitBuddy(1) = mTeam:BuddyAt(1)).
        Assert:Equals(50, mX:HitDamage(1)).
        Assert:IsTrue(mX:HitBuddy(2) = mTeam:BuddyAt(2)).
        Assert:Equals(25, mX:HitDamage(2)).
        mX:Detonate(mT, mPlan, mP, 300, 145, 20, 50).
        Assert:Equals(1, mX:HitCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AskingForAHitThatIsNotThereIsRefused():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        mX:Detonate(mT, mPlan, mP, 10, 145, 20, 50).
        DO ON ERROR UNDO, LEAVE:
            mX:HitBuddy(1).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mX:HitDamage(1).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeadBuddyIsThrownButNotHurtAndADrownedOneIsIgnored():
        mTeam:BuddyAt(1):Hurt(100).
        mTeam:BuddyAt(2):State = BuddyState:Drowned.
        mX:Detonate(mT, mPlan, mP, 100, 145, 20, 50).
        Assert:Equals(0, mX:HitCount()).
        Assert:Equals(0, mTeam:BuddyAt(1):Health).
        Assert:IsTrue(mTeam:BuddyAt(1):State = BuddyState:Airborne).
        Assert:IsTrue(mTeam:BuddyAt(2):State = BuddyState:Drowned).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyCannotLoseMoreThanItHas():
        mTeam:BuddyAt(1):Hurt(80).
        mX:Detonate(mT, mPlan, mP, 100, 145, 20, 50).
        Assert:Equals(0, mTeam:BuddyAt(1):Health).
        Assert:Equals(20, mX:HitDamage(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlastNeedsATerrainAPlanAndPhysics():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mX:Detonate(?, mPlan, mP, 1, 1, 20, 50).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShellPoolHoldsEightShellsInSlotsAndKeepsTheirNumbers():
        DEFINE VARIABLE pool AS ShellPool NO-UNDO.
        DEFINE VARIABLE s    AS INTEGER   NO-UNDO.
        pool = NEW ShellPool().
        Assert:Equals(8, ShellPool:Capacity()).
        Assert:Equals(0, pool:Count()).
        s = pool:Launch(WeaponKind:Bazooka, 2, 1000, 2000, 30, -40).
        Assert:Equals(1, s).
        Assert:Equals(1, pool:Count()).
        Assert:IsTrue(pool:Active(1)).
        Assert:IsFalse(pool:Active(2)).
        Assert:Equals(1000, pool:X(1)).
        Assert:Equals(2000, pool:Y(1)).
        Assert:Equals(30, pool:VX(1)).
        Assert:Equals(-40, pool:VY(1)).
        Assert:Equals(0, pool:Age(1)).
        Assert:Equals(2, pool:Team(1)).
        Assert:IsTrue(pool:Kind(1) = WeaponKind:Bazooka).
        pool:Move(1, 5, 6, 7, 8).
        pool:Grow(1).
        pool:Grow(1).
        Assert:Equals(5, pool:X(1)).
        Assert:Equals(6, pool:Y(1)).
        Assert:Equals(7, pool:VX(1)).
        Assert:Equals(8, pool:VY(1)).
        Assert:Equals(2, pool:Age(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AReleasedSlotIsReusedAndAFullPoolRefusesAnotherShell():
        DEFINE VARIABLE pool    AS ShellPool NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL   NO-UNDO.
        pool = NEW ShellPool().
        DO i = 1 TO 8:
            pool:Launch(WeaponKind:Bazooka, 1, i, i, 0, 0).
        END.
        Assert:Equals(8, pool:Count()).
        DO ON ERROR UNDO, LEAVE:
            pool:Launch(WeaponKind:Bazooka, 1, 0, 0, 0, 0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        pool:Release(3).
        Assert:Equals(7, pool:Count()).
        Assert:Equals(3, pool:Launch(WeaponKind:Bazooka, 1, 99, 99, 0, 0)).
        pool:Clear().
        Assert:Equals(0, pool:Count()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASlotOutsideOneToEightAndAShellWithoutAKindAreRefused():
        DEFINE VARIABLE pool    AS ShellPool NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL   NO-UNDO.
        pool = NEW ShellPool().
        DO ON ERROR UNDO, LEAVE:
            pool:X(9).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            pool:Launch(?, 1, 0, 0, 0, 0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePixelRoundsDownEvenBelowZero():
        Assert:Equals(0, BuddyRules:Pixel(255)).
        Assert:Equals(1, BuddyRules:Pixel(256)).
        Assert:Equals(-1, BuddyRules:Pixel(-1)).
        Assert:Equals(-2, BuddyRules:Pixel(-257)).
        Assert:Equals(20, BuddyRules:BazookaRadius()).
        Assert:Equals(50, BuddyRules:BazookaDamage()).
        Assert:Equals(8, BuddyRules:BlastReach()).
        Assert:Equals(1024, BuddyRules:KnockbackMax()).
        Assert:Equals(64, BuddyRules:KnockbackLift()).
        Assert:Equals(128, BuddyRules:ShotSpeedMin()).
        Assert:Equals(1536, BuddyRules:ShotSpeedMax()).
        Assert:Equals(1200, BuddyRules:ShotMaxFrames()).
        Assert:Equals(8, BuddyRules:ShotSafeFrames()).
    END METHOD.

END CLASS.
