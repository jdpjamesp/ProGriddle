/* The map of a level: typed access to the layers, what can be walked on and what stops the eye. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.LevelMapTests:

    DEFINE PRIVATE VARIABLE mGrid AS Grid     NO-UNDO.
    DEFINE PRIVATE VARIABLE mMap  AS LevelMap NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildMap():
        mGrid = LevelMap:CreateGrid().
        mMap = NEW LevelMap(mGrid).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseMap():
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        mGrid = ?.
        mMap = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALevelIsEightyByTwentyOneWithEightLayers():
        Assert:Equals(80, mMap:Width).
        Assert:Equals(21, mMap:Height).
        Assert:Equals(8, mGrid:Store:LayerCount).
        Assert:Equals("terrain,room,seen,view,trap,found,item,mon", LevelMap:Layers()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewMapIsAllRockAndEmpty():
        Assert:Equals(INTEGER(Terrain:Rock), mMap:TerrainAt(10, 10)).
        Assert:Equals(0, mMap:RoomAt(10, 10)).
        Assert:IsFalse(mMap:IsSeen(10, 10)).
        Assert:IsFalse(mMap:InView(10, 10)).
        Assert:Equals(0, mMap:TrapAt(10, 10)).
        Assert:IsFalse(mMap:TrapFound(10, 10)).
        Assert:Equals(0, mMap:ItemAt(10, 10)).
        Assert:Equals(0, mMap:MonsterAt(10, 10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachLayerKeepsItsOwnValues():
        mMap:SetTerrain(3, 4, Terrain:Floor).
        mMap:SetRoom(3, 4, 5).
        mMap:SetSeen(3, 4, TRUE).
        mMap:SetInView(3, 4, TRUE).
        mMap:SetTrap(3, 4, 7).
        mMap:SetTrapFound(3, 4, TRUE).
        mMap:SetItem(3, 4, 12).
        mMap:SetMonster(3, 4, 3).
        Assert:Equals(INTEGER(Terrain:Floor), mMap:TerrainAt(3, 4)).
        Assert:Equals(5, mMap:RoomAt(3, 4)).
        Assert:IsTrue(mMap:IsSeen(3, 4)).
        Assert:IsTrue(mMap:InView(3, 4)).
        Assert:Equals(7, mMap:TrapAt(3, 4)).
        Assert:IsTrue(mMap:TrapFound(3, 4)).
        Assert:Equals(12, mMap:ItemAt(3, 4)).
        Assert:Equals(3, mMap:MonsterAt(3, 4)).
        Assert:Equals(INTEGER(Terrain:Rock), mMap:TerrainAt(4, 4)).
        mMap:SetSeen(3, 4, FALSE).
        mMap:SetInView(3, 4, FALSE).
        mMap:SetTrapFound(3, 4, FALSE).
        Assert:IsFalse(mMap:IsSeen(3, 4)).
        Assert:IsFalse(mMap:InView(3, 4)).
        Assert:IsFalse(mMap:TrapFound(3, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CellsOffTheMapAreRockAndNothing():
        Assert:IsFalse(mMap:InBounds(-1, 0)).
        Assert:IsFalse(mMap:InBounds(80, 0)).
        Assert:IsFalse(mMap:InBounds(0, 21)).
        Assert:IsTrue(mMap:InBounds(79, 20)).
        Assert:Equals(INTEGER(Terrain:Rock), mMap:TerrainAt(-1, 3)).
        Assert:Equals(0, mMap:RoomAt(90, 3)).
        Assert:IsFalse(mMap:IsSeen(-5, 3)).
        Assert:IsFalse(mMap:InView(0, 30)).
        Assert:Equals(0, mMap:TrapAt(-1, -1)).
        Assert:IsFalse(mMap:TrapFound(100, 100)).
        Assert:Equals(0, mMap:ItemAt(-1, 0)).
        Assert:Equals(0, mMap:MonsterAt(0, -1)).
        Assert:IsFalse(mMap:Walkable(-1, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyFloorDoorPassageAndStairsCanBeWalkedOn():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 12:
            mMap:SetTerrain(i, 0, Terrain:GetEnum(i)).
        END.
        Assert:IsTrue(mMap:Walkable(INTEGER(Terrain:Floor), 0)).
        Assert:IsTrue(mMap:Walkable(INTEGER(Terrain:Door), 0)).
        Assert:IsTrue(mMap:Walkable(INTEGER(Terrain:Passage), 0)).
        Assert:IsTrue(mMap:Walkable(INTEGER(Terrain:Stairs), 0)).
        Assert:IsFalse(mMap:Walkable(INTEGER(Terrain:Rock), 0)).
        Assert:IsFalse(mMap:Walkable(INTEGER(Terrain:WallAcross), 0)).
        Assert:IsFalse(mMap:Walkable(INTEGER(Terrain:WallDown), 0)).
        Assert:IsFalse(mMap:Walkable(INTEGER(Terrain:CornerTopLeft), 0)).
        Assert:IsFalse(mMap:Walkable(INTEGER(Terrain:CornerBottomRight), 0)).
        Assert:IsFalse(mMap:Walkable(INTEGER(Terrain:SecretAcross), 0)).
        Assert:IsFalse(mMap:Walkable(INTEGER(Terrain:SecretDown), 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatCannotBeWalkedOnStopsTheEye():
        mMap:SetTerrain(1, 1, Terrain:Floor).
        mMap:SetTerrain(2, 1, Terrain:WallDown).
        mMap:SetTerrain(3, 1, Terrain:Door).
        Assert:IsFalse(mMap:Opaque(1, 1)).
        Assert:IsTrue(mMap:Opaque(2, 1)).
        Assert:IsFalse(mMap:Opaque(3, 1)).
        Assert:IsTrue(mMap:Opaque(4, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DoorwaysIncludeSecretOnesAndOnlySecretOnesAreSecret():
        mMap:SetTerrain(1, 1, Terrain:Door).
        mMap:SetTerrain(2, 1, Terrain:SecretAcross).
        mMap:SetTerrain(3, 1, Terrain:SecretDown).
        mMap:SetTerrain(4, 1, Terrain:WallAcross).
        Assert:IsTrue(mMap:IsDoorway(1, 1)).
        Assert:IsTrue(mMap:IsDoorway(2, 1)).
        Assert:IsTrue(mMap:IsDoorway(3, 1)).
        Assert:IsFalse(mMap:IsDoorway(4, 1)).
        Assert:IsFalse(mMap:IsSecret(1, 1)).
        Assert:IsTrue(mMap:IsSecret(2, 1)).
        Assert:IsTrue(mMap:IsSecret(3, 1)).
        Assert:IsFalse(mMap:IsSecret(4, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearingTheViewLeavesWhatHasBeenSeen():
        mMap:SetSeen(5, 5, TRUE).
        mMap:SetInView(5, 5, TRUE).
        mMap:SetInView(6, 5, TRUE).
        mMap:ClearView().
        Assert:IsTrue(mMap:IsSeen(5, 5)).
        Assert:IsFalse(mMap:InView(5, 5)).
        Assert:IsFalse(mMap:InView(6, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearAllEmptiesEveryLayer():
        mMap:SetTerrain(5, 5, Terrain:Floor).
        mMap:SetSeen(5, 5, TRUE).
        mMap:SetTrap(5, 5, 2).
        mMap:SetItem(5, 5, 1).
        mMap:SetMonster(5, 5, 1).
        mMap:ClearAll().
        Assert:Equals(INTEGER(Terrain:Rock), mMap:TerrainAt(5, 5)).
        Assert:IsFalse(mMap:IsSeen(5, 5)).
        Assert:Equals(0, mMap:TrapAt(5, 5)).
        Assert:Equals(0, mMap:ItemAt(5, 5)).
        Assert:Equals(0, mMap:MonsterAt(5, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGridOfTheWrongSizeOrNoGridIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE oSmall AS Grid    NO-UNDO.
        oSmall = NEW Grid(NEW ArrayStore(10, 10, LevelMap:Layers())).
        DO ON ERROR UNDO, THROW:
            NEW LevelMap(oSmall).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW LevelMap(?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        oSmall:Dispose().
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
