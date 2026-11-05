/* What the hero sees: a lit room all at once, anything else only the squares next to the hero, and what has been seen is remembered. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.SightTests:

    DEFINE PRIVATE VARIABLE mWorld AS RogueWorld NO-UNDO.

    /* A room with its floor from (5, 5) to (14, 8), lit, the hero at (6, 6), and a corridor of three squares leaving by a door at (15, 7) */
    @Setup.
    METHOD PUBLIC VOID BuildScene():
        mWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW ScriptedRandom("5")).
        mWorld:ClearLevel().
        mWorld:CarveRoom(5, 5, 10, 4).
        mWorld:Cave:SetTerrain(15, 7, Terrain:Door).
        mWorld:Cave:SetTerrain(16, 7, Terrain:Passage).
        mWorld:Cave:SetTerrain(17, 7, Terrain:Passage).
        mWorld:Cave:SetTerrain(18, 7, Terrain:Passage).
        mWorld:PlaceHero(6, 6).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseScene():
        IF VALID-OBJECT(mWorld) THEN mWorld:Dispose().
        mWorld = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InALitRoomTheWholeRoomWallsAndDoorsAreInSight():
        Sight:Look(mWorld).
        Assert:IsTrue(mWorld:Cave:InView(5, 5)).
        Assert:IsTrue(mWorld:Cave:InView(14, 8)).
        Assert:IsTrue(mWorld:Cave:InView(4, 4)).
        Assert:IsTrue(mWorld:Cave:InView(15, 9)).
        Assert:IsTrue(mWorld:Cave:InView(15, 7)).
        Assert:IsTrue(mWorld:Cave:IsSeen(10, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatIsOutsideTheRoomIsNotInSight():
        Sight:Look(mWorld).
        Assert:IsFalse(mWorld:Cave:InView(16, 7)).
        Assert:IsFalse(mWorld:Cave:InView(18, 7)).
        Assert:IsFalse(mWorld:Cave:IsSeen(18, 7)).
        Assert:IsFalse(mWorld:Cave:InView(30, 15)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InADarkRoomOnlyTheNeighbouringSquaresAreSeen():
        mWorld:SetRoomLit(1, FALSE).
        Sight:Look(mWorld).
        Assert:IsTrue(mWorld:Cave:InView(6, 6)).
        Assert:IsTrue(mWorld:Cave:InView(5, 5)).
        Assert:IsTrue(mWorld:Cave:InView(7, 7)).
        Assert:IsFalse(mWorld:Cave:InView(8, 6)).
        Assert:IsFalse(mWorld:Cave:InView(10, 8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InACorridorOnlyTheNeighbouringSquaresAreSeen():
        mWorld:PlaceHero(17, 7).
        Sight:Look(mWorld).
        Assert:IsTrue(mWorld:Cave:InView(16, 7)).
        Assert:IsTrue(mWorld:Cave:InView(18, 7)).
        Assert:IsFalse(mWorld:Cave:InView(14, 7)).
        Assert:IsFalse(mWorld:Cave:InView(10, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StandingInTheDoorwayTheWholeRoomIsInSight():
        mWorld:PlaceHero(15, 7).
        Sight:Look(mWorld).
        Assert:IsTrue(mWorld:Cave:InView(5, 5)).
        Assert:IsTrue(mWorld:Cave:InView(14, 8)).
        Assert:IsTrue(mWorld:Cave:InView(16, 7)).
        Assert:IsFalse(mWorld:Cave:InView(17, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatWasSeenIsRememberedWhenTheHeroHasGone():
        Sight:Look(mWorld).
        mWorld:PlaceHero(17, 7).
        Sight:Look(mWorld).
        Assert:IsFalse(mWorld:Cave:InView(10, 6)).
        Assert:IsTrue(mWorld:Cave:IsSeen(10, 6)).
        Assert:IsTrue(mWorld:Cave:IsSeen(18, 7)).
        Assert:IsFalse(mWorld:Cave:IsSeen(19, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlindHeroSeesNothingButTheirOwnSquare():
        mWorld:Hero:Blind = 5.
        Sight:Look(mWorld).
        Assert:IsTrue(mWorld:Cave:InView(6, 6)).
        Assert:IsFalse(mWorld:Cave:InView(7, 6)).
        Assert:IsFalse(mWorld:Cave:InView(10, 6)).
        Assert:IsFalse(mWorld:Cave:IsSeen(7, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterInSightIsSeenAndOneOutOfSightIsNot():
        DEFINE VARIABLE oNear AS Monster NO-UNDO.
        DEFINE VARIABLE oFar  AS Monster NO-UNDO.
        oNear = mWorld:AddMonster(MonsterKind:Orc, 9, 6).
        oFar = mWorld:AddMonster(MonsterKind:Orc, 17, 7).
        Sight:Look(mWorld).
        Assert:IsTrue(Sight:CanSee(mWorld, oNear)).
        Assert:IsFalse(Sight:CanSee(mWorld, oFar)).
        Assert:IsTrue(oNear:Seen).
        Assert:IsFalse(oFar:Seen).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnInvisibleMonsterIsNotSeenUntilTheHeroCanSeeInvisibleThings():
        DEFINE VARIABLE oPhantom AS Monster NO-UNDO.
        DEFINE VARIABLE oRing    AS Item    NO-UNDO.
        oPhantom = mWorld:AddMonster(MonsterKind:Phantom, 9, 6).
        Sight:Look(mWorld).
        Assert:IsFalse(Sight:CanSee(mWorld, oPhantom)).
        Assert:IsFalse(oPhantom:Seen).
        Assert:IsFalse(Sight:SeesInvisible(mWorld)).
        mWorld:Hero:SeesInvisible = 10.
        Assert:IsTrue(Sight:SeesInvisible(mWorld)).
        Assert:IsTrue(Sight:CanSee(mWorld, oPhantom)).
        mWorld:Hero:SeesInvisible = 0.
        oRing = Items:Make(ItemType:Ring, INTEGER(RingKind:SeeInvisible)).
        mWorld:Pack:LeftRingSlot = mWorld:Pack:Add(oRing).
        Assert:IsTrue(Sight:SeesInvisible(mWorld)).
        Assert:IsTrue(Sight:CanSee(mWorld, oPhantom)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlindHeroSeesNoMonsters():
        DEFINE VARIABLE oOrc AS Monster NO-UNDO.
        oOrc = mWorld:AddMonster(MonsterKind:Orc, 7, 6).
        mWorld:Cave:SetInView(7, 6, TRUE).
        mWorld:Hero:Blind = 3.
        Assert:IsFalse(Sight:CanSee(mWorld, oOrc)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALineBetweenTwoSquaresIsClearWhenNothingStopsTheEye():
        Assert:IsTrue(Sight:LineClear(mWorld, 5, 5, 14, 8)).
        Assert:IsTrue(Sight:LineClear(mWorld, 14, 8, 5, 5)).
        Assert:IsTrue(Sight:LineClear(mWorld, 5, 5, 5, 5)).
        Assert:IsTrue(Sight:LineClear(mWorld, 5, 5, 6, 5)).
        Assert:IsTrue(Sight:LineClear(mWorld, 5, 7, 14, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWallOnTheLineStopsTheEyeFromBothEnds():
        Assert:IsFalse(Sight:LineClear(mWorld, 10, 6, 10, 2)).
        Assert:IsFalse(Sight:LineClear(mWorld, 10, 2, 10, 6)).
        Assert:IsFalse(Sight:LineClear(mWorld, 6, 6, 18, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheEyeCanLookOutOfADoorway():
        Assert:IsTrue(Sight:LineClear(mWorld, 8, 7, 18, 7)).
        Assert:IsTrue(Sight:LineClear(mWorld, 18, 7, 8, 7)).
    END METHOD.

END CLASS.
