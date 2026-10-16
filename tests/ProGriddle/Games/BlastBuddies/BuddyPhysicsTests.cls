/* Buddies on the ground of Blast Buddies: walking, steps, falling, jumping, being thrown, landing and drowning. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddyPhysicsTests:

    DEFINE PRIVATE VARIABLE mT AS Terrain      NO-UNDO.
    DEFINE PRIVATE VARIABLE mP AS BuddyPhysics NO-UNDO.
    DEFINE PRIVATE VARIABLE mB AS Buddy        NO-UNDO.

    /* flat ground with the top at row 150, and a buddy standing on it in column 100 */
    @Setup.
    METHOD PUBLIC VOID Setup():
        mT = NEW Terrain(Theme:Meadow).
        mT:FillRect(0, 150, 383, 239, TRUE).
        mP = NEW BuddyPhysics().
        mB = NEW Buddy("BOLT", 1, 100, 150).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID TearDown():
        mT:Dispose().
        DELETE OBJECT mT.
    END METHOD.

    /* steps until the buddy stands or drowns, up to a number of frames; returns how many it took */
    METHOD PRIVATE INTEGER Settle(INPUT piMax AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO WHILE n < piMax:
            n = n + 1.
            mP:Step(mB, mT).
            IF mB:State <> BuddyState:Airborne THEN LEAVE.
        END.
        RETURN n.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyOnSolidGroundStaysWhereItIs():
        mP:Step(mB, mT).
        Assert:IsTrue(mB:State = BuddyState:Standing).
        Assert:Equals(100, mB:X()).
        Assert:Equals(150, mB:Y()).
        Assert:IsFalse(mB:Landed).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingMovesOnePixelAndTurnsTheBuddy():
        Assert:IsTrue(mP:Walk(mB, mT, -1)).
        Assert:Equals(99, mB:X()).
        Assert:Equals(-1, mB:Facing).
        Assert:Equals(150, mB:Y()).
        Assert:IsTrue(mP:Walk(mB, mT, 1)).
        Assert:IsTrue(mP:Walk(mB, mT, 1)).
        Assert:Equals(101, mB:X()).
        Assert:Equals(1, mB:Facing).
        Assert:IsTrue(mB:State = BuddyState:Standing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADirectionIsMinusOneOrOne():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mP:Walk(mB, mT, 0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARiseOfThreePixelsIsClimbedButFourIsAWall():
        mT:FillRect(101, 147, 101, 149, TRUE).
        Assert:IsTrue(mP:Walk(mB, mT, 1)).
        Assert:Equals(101, mB:X()).
        Assert:Equals(147, mB:Y()).
        mB:PlaceAt(100, 150).
        mT:FillRect(101, 146, 101, 146, TRUE).
        Assert:IsFalse(mP:Walk(mB, mT, 1)).
        Assert:Equals(100, mB:X()).
        Assert:Equals(150, mB:Y()).
        Assert:Equals(1, mB:Facing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASlopeDownOfThreeOrFewerIsWalkedDown():
        mT:FillRect(101, 150, 101, 152, FALSE).
        Assert:IsTrue(mP:Walk(mB, mT, 1)).
        Assert:Equals(101, mB:X()).
        Assert:Equals(153, mB:Y()).
        Assert:IsTrue(mB:State = BuddyState:Standing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADropOfMoreThanThreeIsAFallAndItLandsOnTheFloorBelow():
        mT:FillRect(101, 150, 101, 160, FALSE).
        Assert:IsTrue(mP:Walk(mB, mT, 1)).
        Assert:Equals(101, mB:X()).
        Assert:IsTrue(mB:State = BuddyState:Airborne).
        Settle(100).
        Assert:IsTrue(mB:State = BuddyState:Standing).
        Assert:Equals(161, mB:Y()).
        Assert:IsTrue(mB:Landed).
        Assert:Equals(0, mB:LastFallDamage).
        Assert:Equals(100, mB:Health).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALowCeilingStopsAWalkAndABuddyOnlyWalksWhenStanding():
        /* only 9 pixels of air over the ground in column 101: too low for a body of 11 */
        mT:FillRect(101, 130, 101, 140, TRUE).
        mT:FillRect(101, 141, 101, 149, FALSE).
        Assert:IsFalse(mP:Walk(mB, mT, 1)).
        Assert:Equals(100, mB:X()).
        mP:Hop(mB).
        Assert:IsFalse(mP:Walk(mB, mT, -1)).
        Assert:Equals(100, mB:X()).
        Assert:Equals(-1, mB:Facing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingOffTheSideOfTheMapDrownsTheBuddy():
        mB:PlaceAt(0, 150).
        Assert:IsTrue(mP:Walk(mB, mT, -1)).
        Assert:IsTrue(mB:State = BuddyState:Drowned).
        Assert:Equals(0, mB:Health).
        mB:PlaceAt(383, 150).
        Assert:IsTrue(mP:Walk(mB, mT, 1)).
        Assert:IsTrue(mB:State = BuddyState:Drowned).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingDownToTheWaterDrowns():
        /* a shelf at row 224 (above the water), with a step down to 225, and the water row at 226 */
        mT:FillRect(0, 150, 383, 239, FALSE).
        mT:FillRect(101, 224, 383, 239, TRUE).
        mT:FillRect(0, 225, 100, 239, TRUE).
        mB:PlaceAt(101, 224).
        Assert:IsTrue(mP:Walk(mB, mT, -1)).
        Assert:Equals(225, mB:Y()).
        Assert:IsTrue(mB:State = BuddyState:Standing).
        mT:FillRect(0, 225, 99, 225, FALSE).
        Assert:IsTrue(mP:Walk(mB, mT, -1)).
        Assert:IsTrue(mB:State = BuddyState:Drowned).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHopIsSixPixelsHighAndComesDownForwardWithoutHarm():
        DEFINE VARIABLE minY AS INTEGER NO-UNDO INITIAL 1000.
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        Assert:IsTrue(mP:Hop(mB)).
        Assert:IsTrue(mB:State = BuddyState:Airborne).
        DO WHILE n < 100:
            n = n + 1.
            mP:Step(mB, mT).
            minY = MINIMUM(minY, mB:Y()).
            IF mB:State <> BuddyState:Airborne THEN LEAVE.
        END.
        Assert:IsTrue(mB:State = BuddyState:Standing).
        Assert:IsTrue(minY >= 143 AND minY <= 145, "peak " + STRING(minY)).
        Assert:IsTrue(mB:X() >= 108 AND mB:X() <= 113, "x " + STRING(mB:X())).
        Assert:Equals(150, mB:Y()).
        Assert:Equals(100, mB:Health).
        Assert:IsTrue(n >= 16 AND n <= 20, "frames " + STRING(n)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHopGoesTheWayTheBuddyFaces():
        mP:Walk(mB, mT, -1).
        mP:Hop(mB).
        Settle(100).
        Assert:IsTrue(mB:X() <= 90, "x " + STRING(mB:X())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABackflipIsElevenPixelsHighAndNineBack():
        DEFINE VARIABLE minY AS INTEGER NO-UNDO INITIAL 1000.
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        Assert:IsTrue(mP:Backflip(mB)).
        DO WHILE n < 100:
            n = n + 1.
            mP:Step(mB, mT).
            minY = MINIMUM(minY, mB:Y()).
            IF mB:State <> BuddyState:Airborne THEN LEAVE.
        END.
        Assert:IsTrue(minY >= 138 AND minY <= 140, "peak " + STRING(minY)).
        Assert:IsTrue(mB:X() >= 90 AND mB:X() <= 92, "x " + STRING(mB:X())).
        Assert:Equals(1, mB:Facing).
        Assert:Equals(100, mB:Health).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyAStandingBuddyCanHopOrFlip():
        mP:Hop(mB).
        Assert:IsFalse(mP:Hop(mB)).
        Assert:IsFalse(mP:Backflip(mB)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHopUnderALowCeilingBumpsTheHeadAndComesBackDown():
        DEFINE VARIABLE minY AS INTEGER NO-UNDO INITIAL 1000.
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        /* rock 14 pixels over the feet: a body of 11 has 2 pixels to rise */
        mT:FillRect(90, 130, 110, 136, TRUE).
        mP:Hop(mB).
        DO WHILE n < 100:
            n = n + 1.
            mP:Step(mB, mT).
            minY = MINIMUM(minY, mB:Y()).
            IF mB:State <> BuddyState:Airborne THEN LEAVE.
        END.
        Assert:IsTrue(mB:State = BuddyState:Standing).
        Assert:Equals(148, minY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyWhoseGroundIsBlownAwayFallsAndTakesFallDamage():
        mT:FillRect(90, 150, 110, 200, FALSE).
        mP:Step(mB, mT).
        Assert:IsTrue(mB:State = BuddyState:Airborne).
        Settle(200).
        Assert:IsTrue(mB:State = BuddyState:Standing).
        Assert:Equals(201, mB:Y()).
        /* a fall of 51 pixels: (51 - 24) / 2 */
        Assert:Equals(13, mB:LastFallDamage).
        Assert:Equals(87, mB:Health).
        Assert:IsTrue(mB:Landed).
        mP:Step(mB, mT).
        Assert:IsFalse(mB:Landed).
        Assert:Equals(0, mB:LastFallDamage).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FallDamageIsOneForEveryTwoPixelsBeyondTwentyFour():
        /* the fall is measured from the highest point to the ground the buddy lands on (row 150) */
        mB:PlaceAt(100, 120).
        Settle(200).
        Assert:Equals(3, mB:LastFallDamage).
        mB:PlaceAt(100, 126).
        Settle(200).
        Assert:Equals(0, mB:LastFallDamage).
        mB:PlaceAt(100, 125).
        Settle(200).
        Assert:Equals(0, mB:LastFallDamage).
        mB:PlaceAt(100, 124).
        Settle(200).
        Assert:Equals(1, mB:LastFallDamage).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFallFromAHopCountsFromThePeakOfTheHop():
        mT:FillRect(101, 150, 140, 190, FALSE).
        mP:Hop(mB).
        Settle(200).
        Assert:IsTrue(mB:State = BuddyState:Standing).
        Assert:Equals(191, mB:Y()).
        /* 191 - 144 is 47 pixels: 11 */
        Assert:IsTrue(mB:LastFallDamage >= 10 AND mB:LastFallDamage <= 12, "damage " + STRING(mB:LastFallDamage)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyCannotLoseMoreHealthThanItHas():
        mB:Hurt(95).
        mT:FillRect(0, 150, 383, 239, FALSE).
        mT:FillRect(0, 200, 383, 239, TRUE).
        mB:PlaceAt(100, 100).
        Settle(200).
        Assert:Equals(0, mB:Health).
        Assert:IsTrue(mB:IsDead()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFallIntoTheWaterDrowns():
        mT:FillRect(0, 150, 383, 239, FALSE).
        mB:PlaceAt(100, 150).
        Settle(400).
        Assert:IsTrue(mB:State = BuddyState:Drowned).
        Assert:Equals(0, mB:Health).
        Assert:Equals(226, mB:Y()).
        Assert:IsFalse(mB:Landed).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADrownedBuddyDoesNotMoveOrGetLaunched():
        mB:State = BuddyState:Drowned.
        mP:Launch(mB, 500, -500).
        mP:Step(mB, mT).
        Assert:IsTrue(mB:State = BuddyState:Drowned).
        Assert:Equals(100, mB:X()).
        Assert:IsFalse(mP:Hop(mB)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LaunchThrowsABuddyAlongAParabolaToLandFurtherOn():
        mP:Launch(mB, 512, -768).
        Assert:IsTrue(mB:State = BuddyState:Airborne).
        Settle(200).
        Assert:IsTrue(mB:State = BuddyState:Standing).
        /* up at 3 pixels a frame against gravity 0.15 is about 40 frames in the air, at 2 pixels a frame */
        Assert:IsTrue(mB:X() > 150 AND mB:X() < 190, "x " + STRING(mB:X())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALaunchInTheAirKeepsTheHighestPointReached():
        mP:Launch(mB, 0, -1024).
        DO WHILE mB:Y() > 130:
            mP:Step(mB, mT).
        END.
        mP:Launch(mB, 0, 0).
        Assert:IsTrue(mB:PeakY <= 130).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyThrownIntoAWallStopsSidewaysAndDropsDown():
        mT:FillRect(130, 100, 135, 149, TRUE).
        mB:PlaceAt(125, 150).
        mP:Launch(mB, 768, -300).
        Settle(200).
        Assert:IsTrue(mB:State = BuddyState:Standing).
        Assert:IsTrue(mB:X() <= 129, "x " + STRING(mB:X())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyThrownOffTheSideOfTheMapDrowns():
        mB:PlaceAt(3, 150).
        mP:Launch(mB, -1024, -500).
        Settle(200).
        Assert:IsTrue(mB:State = BuddyState:Drowned).
        mB:PlaceAt(380, 150).
        mP:Launch(mB, 1024, -500).
        Settle(200).
        Assert:IsTrue(mB:State = BuddyState:Drowned).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThinShelfIsNotSkippedByAFastFall():
        mT:FillRect(0, 150, 383, 239, FALSE).
        mT:FillRect(90, 210, 110, 210, TRUE).
        mB:PlaceAt(100, 0).
        Settle(400).
        Assert:IsTrue(mB:State = BuddyState:Standing).
        Assert:Equals(210, mB:Y()).
        Assert:Equals(0, mB:VY).
    END METHOD.

END CLASS.
