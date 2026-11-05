/* The world of a game: the kit of a new hero, a built level with its monsters and things, and the bookkeeping that keeps the lists and
   the map in step. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueWorldTests:

    DEFINE PRIVATE VARIABLE mWorld AS RogueWorld NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildWorld():
        mWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW SeededRandom(5)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseWorld():
        IF VALID-OBJECT(mWorld) THEN mWorld:Dispose().
        mWorld = ?.
    END METHOD.

    /* A 10 x 4 room with its floor from (5, 5), the hero in it at (6, 6) and nothing else */
    METHOD PRIVATE VOID Scene():
        mWorld:ClearLevel().
        mWorld:CarveRoom(5, 5, 10, 4).
        mWorld:PlaceHero(6, 6).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameStartsOnLevelOneWithTheKitOfTheOriginal():
        mWorld:Reset().
        Assert:Equals(1, mWorld:Depth).
        Assert:Equals(1, mWorld:DeepestDepth).
        Assert:Equals(0, mWorld:Turns).
        Assert:Equals(5, mWorld:Pack:Count).
        Assert:Equals(ItemType:Food, mWorld:Pack:At(0):Category).
        Assert:Equals(INTEGER(ArmourKind:RingMail), mWorld:Pack:Worn():Kind).
        Assert:Equals(1, mWorld:Pack:Worn():Bonus).
        Assert:Equals(INTEGER(WeaponKind:Mace), mWorld:Pack:Weapon():Kind).
        Assert:Equals(1, mWorld:Pack:Weapon():Bonus).
        Assert:Equals(1, mWorld:Pack:Weapon():DamageBonus).
        Assert:Equals(INTEGER(WeaponKind:Bow), mWorld:Pack:At(3):Kind).
        Assert:Equals(INTEGER(WeaponKind:Arrow), mWorld:Pack:At(4):Kind).
        Assert:IsTrue(mWorld:Pack:At(4):Count >= 25 AND mWorld:Pack:At(4):Count <= 39).
        Assert:IsTrue(mWorld:Pack:Worn():Known).
        Assert:Equals(12, mWorld:Hero:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroStartsOnAFloorSquareOfTheFirstLevelAndTheStairsAreSomewhereElse():
        mWorld:Reset().
        Assert:Equals(INTEGER(Terrain:Floor), mWorld:Cave:TerrainAt(mWorld:Hero:X, mWorld:Hero:Y)).
        Assert:Equals(INTEGER(Terrain:Stairs), mWorld:Cave:TerrainAt(mWorld:StairsX, mWorld:StairsY)).
        Assert:IsTrue(mWorld:StairsX <> mWorld:Hero:X OR mWorld:StairsY <> mWorld:Hero:Y).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryMonsterOfABuiltLevelStandsWhereTheMapSaysAndNoneOnTheHero():
        DEFINE VARIABLE seed     AS INTEGER NO-UNDO.
        DEFINE VARIABLE i        AS INTEGER NO-UNDO.
        DEFINE VARIABLE seen     AS INTEGER NO-UNDO.
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        DEFINE VARIABLE oWorld   AS RogueWorld NO-UNDO.
        DO seed = 1 TO 12:
            oWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW SeededRandom(seed)).
            oWorld:Reset().
            oWorld:NewLevel(1 + seed * 2 MODULO 26).
            seen = 0.
            DO i = 0 TO 63:
                oMonster = oWorld:MonsterInSlot(i).
                IF VALID-OBJECT(oMonster) THEN DO:
                    seen = seen + 1.
                    Assert:IsTrue(oWorld:MonsterAtCell(oMonster:X, oMonster:Y) = oMonster).
                    Assert:IsTrue(oWorld:Cave:Walkable(oMonster:X, oMonster:Y)).
                    Assert:IsFalse(oMonster:X = oWorld:Hero:X AND oMonster:Y = oWorld:Hero:Y).
                    Assert:IsTrue(oMonster:Hp >= 1).
                END.
            END.
            Assert:Equals(oWorld:MonsterCount, seen).
            oWorld:Dispose().
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALevelHasThingsOnItsFloorAndTheFirstLevelHasSomeMonstersAcrossSeeds():
        DEFINE VARIABLE seed   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE items  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE mons   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oWorld AS RogueWorld NO-UNDO.
        DO seed = 1 TO 20:
            oWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW SeededRandom(seed)).
            oWorld:Reset().
            items = items + oWorld:FloorItemCount.
            mons = mons + oWorld:MonsterCount.
            oWorld:Dispose().
        END.
        Assert:IsTrue(items > 40).
        Assert:IsTrue(mons > 20).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheAmuletLiesOnTheLastLevelOnly():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE found AS INTEGER NO-UNDO.
        DEFINE VARIABLE oItem AS Item    NO-UNDO.
        mWorld:Reset().
        mWorld:NewLevel(26).
        DO y = 0 TO 20:
            DO x = 0 TO 79:
                oItem = mWorld:FloorItemAt(x, y).
                IF VALID-OBJECT(oItem) AND oItem:Category = ItemType:Amulet THEN found = found + 1.
            END.
        END.
        Assert:Equals(1, found).
        Assert:Equals(26, mWorld:Depth).
        mWorld:NewLevel(25).
        found = 0.
        DO y = 0 TO 20:
            DO x = 0 TO 79:
                oItem = mWorld:FloorItemAt(x, y).
                IF VALID-OBJECT(oItem) AND oItem:Category = ItemType:Amulet THEN found = found + 1.
            END.
        END.
        Assert:Equals(0, found).
        Assert:Equals(26, mWorld:DeepestDepth).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLevelsOfADepthAreDarkerTheDeeperTheyAre():
        DEFINE VARIABLE dark   AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE seed   AS INTEGER NO-UNDO.
        DEFINE VARIABLE oWorld AS RogueWorld NO-UNDO.
        DO seed = 1 TO 8:
            oWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW SeededRandom(seed)).
            oWorld:Reset().
            oWorld:NewLevel(24).
            DO i = 1 TO 9:
                IF NOT oWorld:RoomLit(i) THEN dark = dark + 1.
            END.
            oWorld:Dispose().
        END.
        Assert:IsTrue(dark > 20).
        mWorld:Reset().
        Assert:IsTrue(mWorld:RoomLit(1) OR NOT mWorld:Builder:IsRoom(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RoomLightCanBeSetAndOnlyForRealRooms():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        mWorld:SetRoomLit(3, FALSE).
        Assert:IsFalse(mWorld:RoomLit(3)).
        mWorld:SetRoomLit(3, TRUE).
        Assert:IsTrue(mWorld:RoomLit(3)).
        Assert:IsFalse(mWorld:RoomLit(0)).
        Assert:IsFalse(mWorld:RoomLit(10)).
        DO ON ERROR UNDO, THROW:
            mWorld:SetRoomLit(10, TRUE).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptySceneHasOneRoomOfFloorAndNothingInIt():
        Scene().
        Assert:Equals(INTEGER(Terrain:Floor), mWorld:Cave:TerrainAt(5, 5)).
        Assert:Equals(INTEGER(Terrain:Floor), mWorld:Cave:TerrainAt(14, 8)).
        Assert:Equals(INTEGER(Terrain:CornerTopLeft), mWorld:Cave:TerrainAt(4, 4)).
        Assert:Equals(INTEGER(Terrain:WallAcross), mWorld:Cave:TerrainAt(8, 4)).
        Assert:Equals(INTEGER(Terrain:WallDown), mWorld:Cave:TerrainAt(4, 6)).
        Assert:Equals(INTEGER(Terrain:CornerBottomRight), mWorld:Cave:TerrainAt(15, 9)).
        Assert:Equals(1, mWorld:Cave:RoomAt(8, 6)).
        Assert:IsTrue(mWorld:RoomLit(1)).
        Assert:Equals(0, mWorld:MonsterCount).
        Assert:Equals(0, mWorld:FloorItemCount).
        Assert:Equals(6, mWorld:Hero:X).
        Assert:Equals(6, mWorld:Hero:Y).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARoomThatDoesNotFitIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mWorld:CarveRoom(0, 5, 4, 4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mWorld:CarveRoom(70, 5, 10, 4).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mWorld:CarveRoom(5, 5, 0, 4).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterIsPutInACellWithTheHitPointsOfItsLevel():
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        Scene().
        oMonster = mWorld:AddMonster(MonsterKind:Hobgoblin, 9, 6).
        Assert:Equals(9, oMonster:X).
        Assert:Equals(6, oMonster:Y).
        Assert:IsTrue(oMonster:Hp >= 1 AND oMonster:Hp <= 8).
        Assert:IsTrue(mWorld:MonsterAtCell(9, 6) = oMonster).
        Assert:Equals(1, mWorld:MonsterCount).
        Assert:IsFalse(VALID-OBJECT(mWorld:MonsterAtCell(10, 6))).
        oMonster = mWorld:AddMonster(MonsterKind:Dragon, 12, 7).
        Assert:IsTrue(oMonster:Hp >= 10 AND oMonster:Hp <= 80).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterMayCarrySomethingAndTheNymphAlwaysDoes():
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        Scene().
        oMonster = mWorld:AddMonster(MonsterKind:Nymph, 9, 6).
        Assert:IsTrue(VALID-OBJECT(oMonster:Carried)).
        oMonster = mWorld:AddMonster(MonsterKind:Bat, 10, 6).
        Assert:IsFalse(VALID-OBJECT(oMonster:Carried)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterCannotBePutInARockOrOnAnotherMonster():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        Scene().
        mWorld:AddMonster(MonsterKind:Bat, 9, 6).
        DO ON ERROR UNDO, THROW:
            mWorld:AddMonster(MonsterKind:Emu, 9, 6).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mWorld:AddMonster(MonsterKind:Emu, 30, 15).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLevelHoldsAtMostSixtyFourMonsters():
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        mWorld:ClearLevel().
        mWorld:CarveRoom(5, 5, 20, 4).
        DO y = 5 TO 8:
            DO x = 5 TO 24:
                IF n < 64 THEN DO:
                    mWorld:AddMonster(MonsterKind:Bat, x, y).
                    n = n + 1.
                END.
            END.
        END.
        Assert:Equals(64, mWorld:MonsterCount).
        DO ON ERROR UNDO, THROW:
            mWorld:AddMonster(MonsterKind:Bat, 24, 8).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:IsTrue(thrown >= 1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterMovesKeepingTheMapInStep():
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        Scene().
        oMonster = mWorld:AddMonster(MonsterKind:Orc, 9, 6).
        mWorld:MoveMonster(oMonster, 10, 7).
        Assert:Equals(10, oMonster:X).
        Assert:Equals(7, oMonster:Y).
        Assert:IsFalse(VALID-OBJECT(mWorld:MonsterAtCell(9, 6))).
        Assert:IsTrue(mWorld:MonsterAtCell(10, 7) = oMonster).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterCannotMoveIntoWallOrAnotherMonster():
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        DEFINE VARIABLE thrown   AS INTEGER NO-UNDO.
        Scene().
        oMonster = mWorld:AddMonster(MonsterKind:Orc, 9, 6).
        mWorld:AddMonster(MonsterKind:Bat, 10, 6).
        DO ON ERROR UNDO, THROW:
            mWorld:MoveMonster(oMonster, 10, 6).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mWorld:MoveMonster(oMonster, 4, 6).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARemovedMonsterIsGoneFromTheListAndTheMap():
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        Scene().
        oMonster = mWorld:AddMonster(MonsterKind:Orc, 9, 6).
        mWorld:Hero:HeldBy = oMonster.
        mWorld:RemoveMonster(oMonster).
        Assert:Equals(0, mWorld:MonsterCount).
        Assert:IsFalse(VALID-OBJECT(mWorld:MonsterAtCell(9, 6))).
        Assert:IsFalse(VALID-OBJECT(mWorld:Hero:HeldBy)).
        /* the slot is used again */
        mWorld:AddMonster(MonsterKind:Orc, 9, 6).
        Assert:Equals(1, mWorld:MonsterCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterNotWhereItSaysItIsIsRefusedWhenRemovedOrMoved():
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        DEFINE VARIABLE thrown   AS INTEGER NO-UNDO.
        Scene().
        oMonster = NEW Monster(MonsterKind:Bat, 3).
        oMonster:X = 9.
        oMonster:Y = 6.
        DO ON ERROR UNDO, THROW:
            mWorld:RemoveMonster(oMonster).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mWorld:MoveMonster(oMonster, 10, 6).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mWorld:MonsterInSlot(64).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThingIsLaidInACellAndPickedUpAgain():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        Scene().
        oItem = Items:Make(ItemType:Potion, 2).
        Assert:IsTrue(mWorld:DropOnFloor(oItem, 8, 7)).
        Assert:Equals(1, mWorld:FloorItemCount).
        Assert:IsTrue(mWorld:FloorItemAt(8, 7) = oItem).
        Assert:IsFalse(mWorld:CanLieAt(8, 7)).
        Assert:IsTrue(mWorld:TakeFloorItem(8, 7) = oItem).
        Assert:Equals(0, mWorld:FloorItemCount).
        Assert:IsTrue(mWorld:CanLieAt(8, 7)).
        Assert:IsFalse(VALID-OBJECT(mWorld:TakeFloorItem(8, 7))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThingDroppedOnAThingLandsOnTheNextFreeSquare():
        DEFINE VARIABLE a AS Item NO-UNDO.
        DEFINE VARIABLE b AS Item NO-UNDO.
        Scene().
        a = Items:Make(ItemType:Potion, 2).
        b = Items:Make(ItemType:Scroll, 1).
        mWorld:DropOnFloor(a, 8, 7).
        Assert:IsTrue(mWorld:DropOnFloor(b, 8, 7)).
        Assert:IsTrue(mWorld:FloorItemAt(8, 7) = a).
        Assert:Equals(2, mWorld:FloorItemCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThingCannotLieOnStairsADoorOrRock():
        Scene().
        mWorld:Cave:SetTerrain(9, 6, Terrain:Stairs).
        mWorld:Cave:SetTerrain(10, 6, Terrain:Door).
        Assert:IsFalse(mWorld:CanLieAt(9, 6)).
        Assert:IsFalse(mWorld:CanLieAt(10, 6)).
        Assert:IsFalse(mWorld:CanLieAt(40, 10)).
        mWorld:Cave:SetTerrain(11, 6, Terrain:Passage).
        Assert:IsTrue(mWorld:CanLieAt(11, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNothingToDropOnWhenNoSquareIsNear():
        Scene().
        Assert:IsFalse(mWorld:DropOnFloor(Items:Make(ItemType:Potion, 0), 60, 15)).
        Assert:Equals(0, mWorld:FloorItemCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLevelHoldsAtMostOneHundredAndTwentyThings():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE placed AS INTEGER NO-UNDO.
        mWorld:ClearLevel().
        mWorld:CarveRoom(2, 2, 40, 10).
        DO y = 2 TO 11:
            DO x = 2 TO 41:
                IF mWorld:DropOnFloor(Items:Make(ItemType:Potion, 0), x, y) THEN placed = placed + 1.
            END.
        END.
        Assert:Equals(120, placed).
        Assert:Equals(120, mWorld:FloorItemCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFreeFloorSquareHasNothingOnItAndNobodyInIt():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE room  AS INTEGER NO-UNDO.
        mWorld:Reset().
        room = mWorld:Builder:PickRoom().
        DO i = 1 TO 20:
            Assert:IsTrue(mWorld:FreeFloor(room, OUTPUT x, OUTPUT y)).
            Assert:Equals(0, mWorld:Cave:ItemAt(x, y)).
            Assert:Equals(0, mWorld:Cave:MonsterAt(x, y)).
            Assert:IsFalse(x = mWorld:Hero:X AND y = mWorld:Hero:Y).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStepIntoAWallOrDiagonallyThroughADoorIsNotAllowed():
        Scene().
        Assert:IsTrue(mWorld:CanStep(6, 6, 1, 0)).
        Assert:IsTrue(mWorld:CanStep(6, 6, 1, 1)).
        Assert:IsFalse(mWorld:CanStep(5, 6, -1, 0)).
        Assert:IsFalse(mWorld:CanStep(6, 6, 0, 0)).
        mWorld:Cave:SetTerrain(9, 4, Terrain:Door).
        mWorld:Cave:SetTerrain(9, 3, Terrain:Passage).
        Assert:IsTrue(mWorld:CanStep(9, 5, 0, -1)).
        Assert:IsTrue(mWorld:CanStep(9, 3, 0, 1)).
        Assert:IsFalse(mWorld:CanStep(8, 5, 1, -1)).
        Assert:IsFalse(mWorld:CanStep(10, 5, -1, -1)).
        Assert:IsFalse(mWorld:CanStep(9, 4, 1, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DistanceCountsADiagonalStepAsOne():
        Assert:Equals(0, RogueWorld:Distance(3, 3, 3, 3)).
        Assert:Equals(5, RogueWorld:Distance(3, 3, 8, 3)).
        Assert:Equals(5, RogueWorld:Distance(3, 3, 8, 6)).
        Assert:Equals(4, RogueWorld:Distance(10, 10, 6, 12)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MessagesGoToTheLog():
        mWorld:Say("You feel better.").
        Assert:Equals("You feel better.", mWorld:Messages:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameMakesNewNamesAndForgetsWhatWasLearnt():
        DEFINE VARIABLE before AS CHARACTER NO-UNDO.
        mWorld:Reset().
        before = mWorld:Names:Appearance(ItemType:Potion, 0).
        mWorld:Names:Learn(ItemType:Potion, 0).
        mWorld:Reset().
        Assert:IsFalse(mWorld:Names:IsKnown(ItemType:Potion, 0)).
        Assert:Equals(5, mWorld:Pack:Count).
        Assert:Equals(0, mWorld:Messages:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALevelThatDoesNotExistIsRefusedAndNoGridOrNoSourceToo():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mWorld:NewLevel(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mWorld:NewLevel(27).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW RogueWorld(?, NEW SeededRandom(1)).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW RogueWorld(LevelMap:CreateGrid(), ?).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(4, thrown).
    END METHOD.

END CLASS.
