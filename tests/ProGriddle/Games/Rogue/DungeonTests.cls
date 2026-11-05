/* The level builder, on many seeds and depths: every room can be reached, the stairs, the start and the traps are where they should be,
   the deeper levels have dark rooms and secret doors, and the same seed gives the same level. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.DungeonTests:

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

    METHOD PRIVATE Dungeon Build(INPUT piSeed AS INTEGER, INPUT piDepth AS INTEGER):
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        oDungeon = NEW Dungeon(mMap, NEW SeededRandom(piSeed)).
        oDungeon:Build(piDepth).
        RETURN oDungeon.
    END METHOD.

    /* The number of cells that can be reached on foot from a cell, counting a secret door as a door that is there to be found. */
    METHOD PRIVATE INTEGER Reachable(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE seen  AS LOGICAL NO-UNDO EXTENT 1680.
        DEFINE VARIABLE queue AS INTEGER NO-UNDO EXTENT 1680.
        DEFINE VARIABLE head  AS INTEGER NO-UNDO.
        DEFINE VARIABLE tail  AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE nx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE ny    AS INTEGER NO-UNDO.
        DEFINE VARIABLE d     AS INTEGER NO-UNDO.
        queue[1] = piY * 80 + piX.
        seen[piY * 80 + piX + 1] = TRUE.
        head = 1.
        tail = 1.
        DO WHILE head <= tail:
            x = queue[head] MODULO 80.
            y = INTEGER(TRUNCATE(queue[head] / 80, 0)).
            head = head + 1.
            DO d = 0 TO 3:
                nx = x + (IF d = 0 THEN -1 ELSE IF d = 1 THEN 1 ELSE 0).
                ny = y + (IF d = 2 THEN -1 ELSE IF d = 3 THEN 1 ELSE 0).
                IF mMap:InBounds(nx, ny) AND NOT seen[ny * 80 + nx + 1] AND (mMap:Walkable(nx, ny) OR mMap:IsSecret(nx, ny)) THEN DO:
                    seen[ny * 80 + nx + 1] = TRUE.
                    tail = tail + 1.
                    queue[tail] = ny * 80 + nx.
                END.
            END.
        END.
        RETURN tail.
    END METHOD.

    /* How many cells of the map can be walked on or are secret doors. */
    METHOD PRIVATE INTEGER OpenCells():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = 0 TO 20:
            DO x = 0 TO 79:
                IF mMap:Walkable(x, y) OR mMap:IsSecret(x, y) THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryOpenCellOfEveryLevelCanBeReachedFromTheStart():
        DEFINE VARIABLE seed     AS INTEGER NO-UNDO.
        DEFINE VARIABLE depth    AS INTEGER NO-UNDO.
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DO seed = 1 TO 40:
            depth = 1 + (seed * 7) MODULO 26.
            oDungeon = Build(seed, depth).
            Assert:Equals(OpenCells(), Reachable(oDungeon:StartX, oDungeon:StartY)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStairsAreOnTheirSquareAndTheStartIsAFloorSquareAwayFromThem():
        DEFINE VARIABLE seed     AS INTEGER NO-UNDO.
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DO seed = 1 TO 30:
            oDungeon = Build(seed, 1 + seed MODULO 26).
            Assert:Equals(INTEGER(Terrain:Stairs), mMap:TerrainAt(oDungeon:StairsX, oDungeon:StairsY)).
            Assert:Equals(INTEGER(Terrain:Floor), mMap:TerrainAt(oDungeon:StartX, oDungeon:StartY)).
            Assert:IsFalse(oDungeon:StartX = oDungeon:StairsX AND oDungeon:StartY = oDungeon:StairsY).
            Assert:Equals(1, mGrid:Store:CountOf(mGrid:Store:LayerIndex("terrain"), INTEGER(Terrain:Stairs))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAreFiveToNineRoomsAndEachRoomIsWhereItsExtentsSay():
        DEFINE VARIABLE seed     AS INTEGER NO-UNDO.
        DEFINE VARIABLE r        AS INTEGER NO-UNDO.
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DO seed = 1 TO 30:
            oDungeon = Build(seed, 5).
            Assert:IsTrue(oDungeon:RealRooms >= 5 AND oDungeon:RealRooms <= 9).
            DO r = 0 TO 8:
                IF oDungeon:IsRoom(r) THEN DO:
                    Assert:IsTrue(oDungeon:LeftOf(r) >= 0 AND oDungeon:RightOf(r) <= 79).
                    Assert:IsTrue(oDungeon:TopOf(r) >= 0 AND oDungeon:BottomOf(r) <= 20).
                    Assert:IsTrue(oDungeon:RightOf(r) - oDungeon:LeftOf(r) >= 5).
                    Assert:IsTrue(oDungeon:BottomOf(r) - oDungeon:TopOf(r) >= 3).
                    Assert:Equals(INTEGER(Terrain:CornerTopLeft), mMap:TerrainAt(oDungeon:LeftOf(r), oDungeon:TopOf(r))).
                    Assert:Equals(INTEGER(Terrain:CornerBottomRight), mMap:TerrainAt(oDungeon:RightOf(r), oDungeon:BottomOf(r))).
                    Assert:Equals(r + 1, mMap:RoomAt(oDungeon:LeftOf(r) + 1, oDungeon:TopOf(r) + 1)).
                END.
                ELSE DO:
                    Assert:Equals(INTEGER(Terrain:Passage), mMap:TerrainAt(oDungeon:LeftOf(r), oDungeon:TopOf(r))).
                    Assert:IsFalse(oDungeon:IsLit(r)).
                END.
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWallsAreAWallAroundTheFloorWithOnlyDoorsBrokenIn():
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DEFINE VARIABLE r        AS INTEGER NO-UNDO.
        DEFINE VARIABLE x        AS INTEGER NO-UNDO.
        DEFINE VARIABLE t        AS INTEGER NO-UNDO.
        oDungeon = Build(3, 1).
        DO r = 0 TO 8:
            IF NOT oDungeon:IsRoom(r) THEN NEXT.
            DO x = oDungeon:LeftOf(r) + 1 TO oDungeon:RightOf(r) - 1:
                t = mMap:TerrainAt(x, oDungeon:TopOf(r)).
                Assert:IsTrue(t = INTEGER(Terrain:WallAcross) OR t = INTEGER(Terrain:Door) OR t = INTEGER(Terrain:SecretAcross)).
                t = mMap:TerrainAt(x, oDungeon:BottomOf(r)).
                Assert:IsTrue(t = INTEGER(Terrain:WallAcross) OR t = INTEGER(Terrain:Door) OR t = INTEGER(Terrain:SecretAcross)).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCellHasACorridorToAtLeastOneNeighbourAndTheLinksRunBothWays():
        DEFINE VARIABLE seed     AS INTEGER NO-UNDO.
        DEFINE VARIABLE a        AS INTEGER NO-UNDO.
        DEFINE VARIABLE b        AS INTEGER NO-UNDO.
        DEFINE VARIABLE links    AS INTEGER NO-UNDO.
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DO seed = 1 TO 20:
            oDungeon = Build(seed, 2).
            links = 0.
            DO a = 0 TO 8:
                DO b = 0 TO 8:
                    Assert:Equals(oDungeon:Linked(a, b), oDungeon:Linked(b, a)).
                    IF oDungeon:Linked(a, b) AND a < b THEN links = links + 1.
                END.
            END.
            Assert:IsTrue(links >= 8).
            Assert:IsTrue(links <= 12).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TrapsAreHiddenOnFloorSquaresAndThereAreFewOnShallowLevels():
        DEFINE VARIABLE seed     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x        AS INTEGER NO-UNDO.
        DEFINE VARIABLE y        AS INTEGER NO-UNDO.
        DEFINE VARIABLE n        AS INTEGER NO-UNDO.
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DO seed = 1 TO 20:
            oDungeon = Build(seed, 1).
            n = 0.
            DO y = 0 TO 20:
                DO x = 0 TO 79:
                    IF mMap:TrapAt(x, y) > 0 THEN DO:
                        n = n + 1.
                        Assert:Equals(INTEGER(Terrain:Floor), mMap:TerrainAt(x, y)).
                        Assert:IsFalse(mMap:TrapFound(x, y)).
                        Assert:IsTrue(mMap:TrapAt(x, y) <= 8).
                    END.
                END.
            END.
            Assert:Equals(oDungeon:TrapCount, n).
            Assert:IsTrue(n >= 1 AND n <= 10).
            Assert:IsTrue(mMap:TrapAt(oDungeon:StartX, oDungeon:StartY) = 0).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnTheFirstLevelEveryRoomIsLitAndNoDoorIsSecret():
        DEFINE VARIABLE seed     AS INTEGER NO-UNDO.
        DEFINE VARIABLE r        AS INTEGER NO-UNDO.
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DO seed = 1 TO 25:
            oDungeon = Build(seed, 1).
            DO r = 0 TO 8:
                IF oDungeon:IsRoom(r) THEN Assert:IsTrue(oDungeon:IsLit(r)).
            END.
            Assert:Equals(0, mGrid:Store:CountOf(mGrid:Store:LayerIndex("terrain"), INTEGER(Terrain:SecretAcross))).
            Assert:Equals(0, mGrid:Store:CountOf(mGrid:Store:LayerIndex("terrain"), INTEGER(Terrain:SecretDown))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DeepLevelsHaveDarkRoomsAndSecretDoors():
        DEFINE VARIABLE seed     AS INTEGER NO-UNDO.
        DEFINE VARIABLE r        AS INTEGER NO-UNDO.
        DEFINE VARIABLE dark     AS INTEGER NO-UNDO.
        DEFINE VARIABLE secret   AS INTEGER NO-UNDO.
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DO seed = 1 TO 25:
            oDungeon = Build(seed, 22).
            DO r = 0 TO 8:
                IF oDungeon:IsRoom(r) AND NOT oDungeon:IsLit(r) THEN dark = dark + 1.
            END.
            secret = secret + mGrid:Store:CountOf(mGrid:Store:LayerIndex("terrain"), INTEGER(Terrain:SecretAcross))
                            + mGrid:Store:CountOf(mGrid:Store:LayerIndex("terrain"), INTEGER(Terrain:SecretDown)).
        END.
        Assert:IsTrue(dark > 25).
        Assert:IsTrue(secret > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameSeedBuildsTheSameLevelAndAnotherSeedAnotherOne():
        DEFINE VARIABLE a AS Dungeon NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE same AS INTEGER NO-UNDO.
        DEFINE VARIABLE before AS INTEGER NO-UNDO EXTENT 1680.
        DEFINE VARIABLE differs AS INTEGER NO-UNDO.
        a = Build(77, 6).
        DO y = 0 TO 20:
            DO x = 0 TO 79:
                before[y * 80 + x + 1] = mMap:TerrainAt(x, y).
            END.
        END.
        Build(77, 6).
        DO y = 0 TO 20:
            DO x = 0 TO 79:
                IF before[y * 80 + x + 1] = mMap:TerrainAt(x, y) THEN same = same + 1.
            END.
        END.
        Assert:Equals(1680, same).
        Build(78, 6).
        DO y = 0 TO 20:
            DO x = 0 TO 79:
                IF before[y * 80 + x + 1] <> mMap:TerrainAt(x, y) THEN differs = differs + 1.
            END.
        END.
        Assert:IsTrue(differs > 50).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BuildingAgainStartsFromAnEmptyMap():
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        oDungeon = NEW Dungeon(mMap, NEW SeededRandom(5)).
        oDungeon:Build(3).
        mMap:SetSeen(10, 10, TRUE).
        mMap:SetItem(10, 10, 4).
        oDungeon:Build(4).
        Assert:IsFalse(mMap:IsSeen(10, 10)).
        Assert:Equals(0, mMap:ItemAt(10, 10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APickedRoomIsARoomAndAFloorCellInItIsInsideIt():
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DEFINE VARIABLE r        AS INTEGER NO-UNDO.
        DEFINE VARIABLE x        AS INTEGER NO-UNDO.
        DEFINE VARIABLE y        AS INTEGER NO-UNDO.
        DEFINE VARIABLE i        AS INTEGER NO-UNDO.
        oDungeon = Build(11, 8).
        DO i = 1 TO 50:
            r = oDungeon:PickRoom().
            Assert:IsTrue(oDungeon:IsRoom(r)).
            oDungeon:FloorCellIn(r, OUTPUT x, OUTPUT y).
            Assert:IsTrue(x > oDungeon:LeftOf(r) AND x < oDungeon:RightOf(r) AND y > oDungeon:TopOf(r) AND y < oDungeon:BottomOf(r)).
            Assert:Equals(INTEGER(Terrain:Floor), mMap:TerrainAt(x, y)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ForgettingTheRoomsLeavesNoneToAskAbout():
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        oDungeon = Build(5, 3).
        Assert:IsTrue(oDungeon:RealRooms >= 5).
        oDungeon:Forget().
        Assert:Equals(0, oDungeon:RealRooms).
        Assert:IsFalse(oDungeon:IsRoom(0)).
        Assert:IsFalse(oDungeon:Linked(0, 1)).
        Assert:IsFalse(oDungeon:IsLit(4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BadDepthsRoomsAndNoMapAreRefused():
        DEFINE VARIABLE oDungeon AS Dungeon NO-UNDO.
        DEFINE VARIABLE thrown   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x        AS INTEGER NO-UNDO.
        DEFINE VARIABLE y        AS INTEGER NO-UNDO.
        DEFINE VARIABLE r        AS INTEGER NO-UNDO.
        oDungeon = Build(4, 1).
        DO ON ERROR UNDO, THROW:
            oDungeon:Build(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oDungeon:IsRoom(9).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Dungeon(?, NEW SeededRandom(1)).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Dungeon(mMap, ?).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO r = 0 TO 8:
            IF NOT oDungeon:IsRoom(r) THEN DO ON ERROR UNDO, THROW:
                oDungeon:FloorCellIn(r, OUTPUT x, OUTPUT y).
                CATCH e5 AS GridException:
                    thrown = thrown + 1.
                END CATCH.
            END.
        END.
        Assert:IsTrue(thrown >= 4).
    END METHOD.

END CLASS.
