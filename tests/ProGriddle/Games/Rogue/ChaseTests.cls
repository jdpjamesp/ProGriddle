/* The chase map: how many steps every square is from the hero, round walls and through doors, and the step a monster takes along it. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.ChaseTests:

    VAR PRIVATE RogueWorld mWorld.
    VAR PRIVATE Chase mChase.

    /* a room with floor (5, 5) to (14, 8), a door at (15, 7) and a corridor east of it, the hero at (6, 6) */
    @Setup.
    METHOD PUBLIC VOID BuildScene():
        mWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW ScriptedRandom("0")).
        mWorld:ClearLevel().
        mWorld:CarveRoom(5, 5, 10, 4).
        mWorld:Cave:SetTerrain(15, 7, Terrain:Door).
        mWorld:Cave:SetTerrain(16, 7, Terrain:Passage).
        mWorld:Cave:SetTerrain(17, 7, Terrain:Passage).
        mWorld:Cave:SetTerrain(17, 8, Terrain:Passage).
        mWorld:PlaceHero(6, 6).
        mChase = NEW Chase().
        mChase:Refresh(mWorld).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseScene():
        IF VALID-OBJECT(mWorld) THEN mWorld:Dispose().
        mWorld = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroIsAtDistanceZeroAndTheRoomSquaresAreCountedInSteps():
        Assert:Equals(0, mChase:DistanceAt(6, 6)).
        Assert:Equals(1, mChase:DistanceAt(7, 7)).
        Assert:Equals(1, mChase:DistanceAt(5, 5)).
        Assert:Equals(8, mChase:DistanceAt(14, 6)).
        Assert:Equals(8, mChase:DistanceAt(14, 8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WallsAndRockCannotBeReached():
        Assert:Equals(-1, mChase:DistanceAt(4, 6)).
        Assert:Equals(-1, mChase:DistanceAt(40, 15)).
        Assert:Equals(-1, mChase:DistanceAt(-1, 3)).
        Assert:Equals(-1, mChase:DistanceAt(80, 3)).
        Assert:Equals(-1, mChase:DistanceAt(3, 21)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWayOutIsThroughTheDoorAndNotDiagonallyThroughIt():
        /* (14, 7) is next to the door at (15, 7); the hero is 8 steps from (14, 7) and the door is the 9th */
        Assert:Equals(8, mChase:DistanceAt(14, 7)).
        Assert:Equals(9, mChase:DistanceAt(15, 7)).
        Assert:Equals(10, mChase:DistanceAt(16, 7)).
        Assert:Equals(11, mChase:DistanceAt(17, 7)).
        /* (17, 8) is next to (17, 7) and (16, 7): it is reached from (16, 7) by a diagonal step, 11 steps */
        Assert:Equals(11, mChase:DistanceAt(17, 8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASquareThatCannotBeReachedKeepsMinusOneAfterTheHeroMoves():
        mWorld:Cave:SetTerrain(30, 15, Terrain:Floor).
        mWorld:PlaceHero(14, 7).
        mChase:Refresh(mWorld).
        Assert:Equals(-1, mChase:DistanceAt(30, 15)).
        Assert:Equals(0, mChase:DistanceAt(14, 7)).
        Assert:Equals(1, mChase:DistanceAt(15, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterStepsToTheNearestSquareToTheHero():
        VAR Monster oMonster.
        VAR INTEGER dx.
        VAR INTEGER dy.
        oMonster = mWorld:AddMonster(MonsterKind:Orc, 12, 6).
        Assert:IsTrue(mChase:BestStep(mWorld, oMonster, OUTPUT dx, OUTPUT dy)).
        Assert:Equals(-1, dx).
        Assert:IsTrue(dy >= -1 AND dy <= 1).
        Assert:Equals(mChase:DistanceAt(12, 6) - 1, mChase:DistanceAt(12 + dx, 6 + dy)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterNextToTheHeroHasNoStepToTake():
        VAR Monster oMonster.
        VAR INTEGER dx.
        VAR INTEGER dy.
        oMonster = mWorld:AddMonster(MonsterKind:Orc, 7, 6).
        Assert:IsFalse(mChase:BestStep(mWorld, oMonster, OUTPUT dx, OUTPUT dy)).
        Assert:Equals(0, dx).
        Assert:Equals(0, dy).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterDoesNotStepOntoAnotherMonster():
        VAR Monster oMonster.
        VAR INTEGER dx.
        VAR INTEGER dy.
        /* a monster in a corridor of one square width with another in front of it: no step */
        mWorld:Cave:SetTerrain(20, 7, Terrain:Passage).
        mWorld:Cave:SetTerrain(19, 7, Terrain:Passage).
        mWorld:Cave:SetTerrain(18, 7, Terrain:Passage).
        mWorld:Cave:SetTerrain(17, 8, Terrain:Rock).
        mWorld:AddMonster(MonsterKind:Bat, 18, 7).
        oMonster = mWorld:AddMonster(MonsterKind:Orc, 19, 7).
        mChase:Refresh(mWorld).
        Assert:IsFalse(mChase:BestStep(mWorld, oMonster, OUTPUT dx, OUTPUT dy)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterThatCannotReachTheHeroHasNoStep():
        VAR Monster oMonster.
        VAR INTEGER dx.
        VAR INTEGER dy.
        mWorld:Cave:SetTerrain(30, 15, Terrain:Floor).
        oMonster = mWorld:AddMonster(MonsterKind:Orc, 30, 15).
        Assert:IsFalse(mChase:BestStep(mWorld, oMonster, OUTPUT dx, OUTPUT dy)).
    END METHOD.

END CLASS.
