/* Everything there is in a game of Rogue, with only the rules of keeping it tidy: the map of the level and the builder that made it, the
   hero and what is in the pack, what the unknown things are called, the monsters on the level and the things on its floor (each in a
   list, with the map's layers saying which list slot is in which cell), the messages, the depth and the count of turns. The rules of play
   (moving, fighting, magic) are in other classes that work on a world, so each can be tried on a small scene put together by hand:
   ClearLevel, CarveRoom, PlaceHero, AddMonster and DropOnFloor make one.

   NewLevel builds a whole level for a depth: rooms, gold, things, monsters, and the hero put at the start. Reset starts a new game: a
   new hero with the kit the original gives (food, ring mail +1 worn, a mace +1,+1 wielded, a bow +1 and some arrows), new names for the
   unknown things, and level 1. Everything random goes through the random source. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueWorld FINAL:

    DEFINE PRIVATE VARIABLE mGrid    AS Grid       NO-UNDO.
    DEFINE PRIVATE VARIABLE mMonster AS Monster    NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mFloor   AS Item       NO-UNDO EXTENT 120.
    DEFINE PRIVATE VARIABLE mLit     AS LOGICAL    NO-UNDO EXTENT 9.
    DEFINE PRIVATE VARIABLE mNoFood  AS INTEGER    NO-UNDO.

    DEFINE PUBLIC PROPERTY Cave AS LevelMap NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Builder AS Dungeon NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Random AS IRandom NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Hero AS Hero NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Pack AS Pack NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Names AS Disguises NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Messages AS MessageLog NO-UNDO
        GET.
        PRIVATE SET.

    /* The depth of the level the hero is on (1 is the first level), the deepest the hero has been, and the turns taken. */
    DEFINE PUBLIC PROPERTY Depth AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY DeepestDepth AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Turns AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY StairsX AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY StairsY AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many monsters are on the level, and how many things lie on its floor. */
    DEFINE PUBLIC PROPERTY MonsterCount AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO RogueRules:MostMonsters():
                IF VALID-OBJECT(mMonster[i]) THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    DEFINE PUBLIC PROPERTY FloorItemCount AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO RogueRules:MostFloorItems():
                IF VALID-OBJECT(mFloor[i]) THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* Throws GridException for no grid or no random source. The game is not started: call Reset. */
    CONSTRUCTOR PUBLIC RogueWorld(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        IF NOT VALID-OBJECT(poGrid) THEN UNDO, THROW NEW GridException("A world needs a grid").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A world needs a random source").
        mGrid = poGrid.
        Cave = NEW LevelMap(poGrid).
        Random = poRandom.
        Builder = NEW Dungeon(Cave, poRandom).
        Names = NEW Disguises(poRandom).
        Messages = NEW MessageLog().
        Hero = NEW Hero().
        Pack = NEW Pack().
    END CONSTRUCTOR.

    /* ================================== a new game ================================== */

    /* A new game: a new hero with the starting kit, new names for the unknown things and the first level. */
    METHOD PUBLIC VOID Reset():
        Hero = NEW Hero().
        Pack = NEW Pack().
        Names:Shuffle(Random).
        Messages:Clear().
        Turns = 0.
        DeepestDepth = 0.
        mNoFood = 0.
        GiveKit().
        NewLevel(1).
    END METHOD.

    /* Food, ring mail +1 worn, a mace +1,+1 wielded, a bow +1 and arrows. */
    METHOD PRIVATE VOID GiveKit():
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        Pack:Add(Items:Make(ItemType:Food, INTEGER(FoodKind:Ration))).
        oItem = Items:Make(ItemType:Armour, INTEGER(ArmourKind:RingMail)).
        oItem:Bonus = 1.
        oItem:Known = TRUE.
        Pack:WornSlot = Pack:Add(oItem).
        oItem = Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Mace)).
        oItem:Bonus = 1.
        oItem:DamageBonus = 1.
        oItem:Known = TRUE.
        Pack:WieldedSlot = Pack:Add(oItem).
        oItem = Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Bow)).
        oItem:Bonus = 1.
        oItem:Known = TRUE.
        Pack:Add(oItem).
        oItem = Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Arrow)).
        oItem:Count = 25 + Random:NextInt(15).
        Pack:Add(oItem).
    END METHOD.

    /* ================================== the level ================================== */

    /* Builds a new level for a depth, puts the hero at its start and fills it with gold, things and monsters. The old level is gone. */
    METHOD PUBLIC VOID NewLevel(INPUT piDepth AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF piDepth = ? OR piDepth < 1 OR piDepth > RogueRules:AmuletDepth() THEN
            UNDO, THROW NEW GridException("There is no level " + STRING(piDepth)).
        EmptyLists().
        Builder:Build(piDepth).
        Depth = piDepth.
        DeepestDepth = MAXIMUM(DeepestDepth, piDepth).
        StairsX = Builder:StairsX.
        StairsY = Builder:StairsY.
        Hero:X = Builder:StartX.
        Hero:Y = Builder:StartY.
        Hero:HeldBy = ?.
        DO i = 0 TO 8:
            mLit[i + 1] = Builder:IsLit(i).
        END.
        Populate().
    END METHOD.

    /* The rooms of a built level are not all lit: asks about a room number of the room layer (1 to 9). */
    METHOD PUBLIC LOGICAL RoomLit(INPUT piRoom AS INTEGER):
        IF piRoom = ? OR piRoom < 1 OR piRoom > 9 THEN RETURN FALSE.
        RETURN mLit[piRoom].
    END METHOD.

    METHOD PUBLIC VOID SetRoomLit(INPUT piRoom AS INTEGER, INPUT plLit AS LOGICAL):
        IF piRoom = ? OR piRoom < 1 OR piRoom > 9 THEN UNDO, THROW NEW GridException("There is no room " + STRING(piRoom)).
        mLit[piRoom] = plLit.
    END METHOD.

    /* An empty level for a test to build on: all rock, no monsters, nothing on the floor, no stairs. The hero is left where it was. */
    METHOD PUBLIC VOID ClearLevel():
        EmptyLists().
        Cave:ClearAll().
        StairsX = -1.
        StairsY = -1.
    END METHOD.

    /* A room for a test: a floor piW across and piH down whose top left is (piX, piY), with walls round it and the whole of it as room 1,
       lit. The walls need a square of room outside the floor. */
    METHOD PUBLIC VOID CarveRoom(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        IF NOT Cave:InBounds(piX - 1, piY - 1) OR NOT Cave:InBounds(piX + piW, piY + piH) OR piW < 1 OR piH < 1 THEN
            UNDO, THROW NEW GridException("There is no room for a room of " + STRING(piW) + " x " + STRING(piH) + " at " + STRING(piX) + "," + STRING(piY)).
        DO y = piY - 1 TO piY + piH:
            DO x = piX - 1 TO piX + piW:
                Cave:SetRoom(x, y, 1).
                IF y = piY - 1 AND x = piX - 1 THEN Cave:SetTerrain(x, y, Terrain:CornerTopLeft).
                ELSE IF y = piY - 1 AND x = piX + piW THEN Cave:SetTerrain(x, y, Terrain:CornerTopRight).
                ELSE IF y = piY + piH AND x = piX - 1 THEN Cave:SetTerrain(x, y, Terrain:CornerBottomLeft).
                ELSE IF y = piY + piH AND x = piX + piW THEN Cave:SetTerrain(x, y, Terrain:CornerBottomRight).
                ELSE IF y = piY - 1 OR y = piY + piH THEN Cave:SetTerrain(x, y, Terrain:WallAcross).
                ELSE IF x = piX - 1 OR x = piX + piW THEN Cave:SetTerrain(x, y, Terrain:WallDown).
                ELSE Cave:SetTerrain(x, y, Terrain:Floor).
            END.
        END.
        mLit[1] = TRUE.
    END METHOD.

    /* Puts the hero somewhere. */
    METHOD PUBLIC VOID PlaceHero(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        Hero:X = piX.
        Hero:Y = piY.
    END METHOD.

    METHOD PRIVATE VOID EmptyLists():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO RogueRules:MostMonsters():
            mMonster[i] = ?.
        END.
        DO i = 1 TO RogueRules:MostFloorItems():
            mFloor[i] = ?.
        END.
        Hero:HeldBy = ?.
    END METHOD.

    /* Gold, things and monsters for a level just built. */
    METHOD PRIVATE VOID Populate():
        DEFINE VARIABLE r       AS INTEGER NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER NO-UNDO.
        DEFINE VARIABLE gold    AS LOGICAL NO-UNDO.
        DEFINE VARIABLE oItem   AS Item    NO-UNDO.
        DEFINE VARIABLE hadFood AS LOGICAL NO-UNDO.
        DO r = 0 TO 8:
            IF NOT Builder:IsRoom(r) THEN NEXT.
            gold = Random:NextInt(2) = 0.
            IF gold AND FreeFloor(r, OUTPUT x, OUTPUT y) THEN DropOnFloor(Items:Gold(Depth, Random), x, y).
            IF Random:NextInt(100) < (IF gold THEN 80 ELSE 25) AND FreeFloor(r, OUTPUT x, OUTPUT y) THEN
                AddMonster(Bestiary:ForDepth(Depth, Random), x, y).
        END.
        DO i = 1 TO 9:
            IF Random:NextInt(100) < 35 THEN DO:
                oItem = Items:Roll(Random).
                IF oItem:Category = ItemType:Food THEN hadFood = TRUE.
                IF FreeFloor(Builder:PickRoom(), OUTPUT x, OUTPUT y) THEN DropOnFloor(oItem, x, y).
            END.
        END.
        /* the dungeon is never left without food for long */
        IF hadFood THEN mNoFood = 0.
        ELSE DO:
            mNoFood = mNoFood + 1.
            IF mNoFood > 2 AND FreeFloor(Builder:PickRoom(), OUTPUT x, OUTPUT y) THEN DO:
                DropOnFloor(Items:OfSort(ItemType:Food, Random), x, y).
                mNoFood = 0.
            END.
        END.
        IF Depth = RogueRules:AmuletDepth() AND NOT Pack:HasAmulet() AND FreeFloor(Builder:PickRoom(), OUTPUT x, OUTPUT y) THEN
            DropOnFloor(Items:Amulet(), x, y).
    END METHOD.

    /* A floor square of a room with nothing on it and nobody in it, found in a few tries: false when there is none. */
    METHOD PUBLIC LOGICAL FreeFloor(INPUT piRoom AS INTEGER, OUTPUT piX AS INTEGER, OUTPUT piY AS INTEGER):
        DEFINE VARIABLE tries AS INTEGER NO-UNDO.
        DO tries = 1 TO 30:
            Builder:FloorCellIn(piRoom, OUTPUT piX, OUTPUT piY).
            IF Cave:ItemAt(piX, piY) = 0 AND Cave:MonsterAt(piX, piY) = 0 AND NOT (piX = Hero:X AND piY = Hero:Y) THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* ================================== monsters ================================== */

    /* Puts a monster of a kind in a cell, with the hit points of its level, and gives it something to carry now and then. Throws
       GridException for a cell that cannot be walked on or already has a monster in it, or when the level has no room for another. */
    METHOD PUBLIC Monster AddMonster(INPUT poKind AS MonsterKind, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i        AS INTEGER NO-UNDO.
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        IF NOT Cave:Walkable(piX, piY) OR Cave:MonsterAt(piX, piY) > 0 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A monster cannot be put at &1,&2", piX, piY)).
        DO i = 1 TO RogueRules:MostMonsters():
            IF NOT VALID-OBJECT(mMonster[i]) THEN LEAVE.
        END.
        IF i > RogueRules:MostMonsters() THEN UNDO, THROW NEW GridException("There is no room for another monster on the level").
        oMonster = NEW Monster(poKind, MAXIMUM(1, Dice:Roll(STRING(Bestiary:Level(poKind)) + "d8", Random))).
        oMonster:X = piX.
        oMonster:Y = piY.
        IF Random:NextInt(100) < Bestiary:Carry(poKind) THEN oMonster:Carried = Items:Roll(Random).
        mMonster[i] = oMonster.
        Cave:SetMonster(piX, piY, i).
        RETURN oMonster.
    END METHOD.

    /* The monster in a cell, or unknown. */
    METHOD PUBLIC Monster MonsterAtCell(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        n = Cave:MonsterAt(piX, piY).
        RETURN (IF n > 0 THEN mMonster[n] ELSE ?).
    END METHOD.

    /* The monster in a slot of the list (0 to 63), or unknown for an empty slot: for going through all of them. */
    METHOD PUBLIC Monster MonsterInSlot(INPUT piSlot AS INTEGER):
        IF piSlot = ? OR piSlot < 0 OR piSlot >= RogueRules:MostMonsters() THEN UNDO, THROW NEW GridException("There is no monster slot " + STRING(piSlot)).
        RETURN mMonster[piSlot + 1].
    END METHOD.

    /* Moves a monster to a cell, keeping the map in step. The cell must be walkable and empty. */
    METHOD PUBLIC VOID MoveMonster(INPUT poMonster AS Monster, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        n = Cave:MonsterAt(poMonster:X, poMonster:Y).
        IF n = 0 OR mMonster[n] <> poMonster THEN UNDO, THROW NEW GridException("That monster is not on the map where it says").
        IF NOT Cave:Walkable(piX, piY) OR Cave:MonsterAt(piX, piY) > 0 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A monster cannot move to &1,&2", piX, piY)).
        Cave:SetMonster(poMonster:X, poMonster:Y, 0).
        poMonster:X = piX.
        poMonster:Y = piY.
        Cave:SetMonster(piX, piY, n).
    END METHOD.

    /* Takes a monster off the level. What it carries is not dropped here (see Fighting). */
    METHOD PUBLIC VOID RemoveMonster(INPUT poMonster AS Monster):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        n = Cave:MonsterAt(poMonster:X, poMonster:Y).
        IF n = 0 OR mMonster[n] <> poMonster THEN UNDO, THROW NEW GridException("That monster is not on the map where it says").
        Cave:SetMonster(poMonster:X, poMonster:Y, 0).
        mMonster[n] = ?.
        IF Hero:HeldBy = poMonster THEN Hero:HeldBy = ?.
    END METHOD.

    /* ================================== the floor ================================== */

    /* The thing lying in a cell, or unknown. */
    METHOD PUBLIC Item FloorItemAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        n = Cave:ItemAt(piX, piY).
        RETURN (IF n > 0 THEN mFloor[n] ELSE ?).
    END METHOD.

    /* Lays a thing on the floor at a cell, or, when something is already there or the cell is not floor, at the nearest cell that is
       free (within 3 squares). Gives true when it was put down: false when there is no room (the thing is lost). */
    METHOD PUBLIC LOGICAL DropOnFloor(INPUT poItem AS Item, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE r  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poItem) THEN UNDO, THROW NEW GridException("There is no item to put down").
        DO r = 0 TO 3:
            DO dy = - r TO r:
                DO dx = - r TO r:
                    IF MAXIMUM(ABSOLUTE(dx), ABSOLUTE(dy)) = r AND CanLieAt(piX + dx, piY + dy) THEN DO:
                        DO i = 1 TO RogueRules:MostFloorItems():
                            IF NOT VALID-OBJECT(mFloor[i]) THEN DO:
                                mFloor[i] = poItem.
                                Cave:SetItem(piX + dx, piY + dy, i).
                                RETURN TRUE.
                            END.
                        END.
                        RETURN FALSE.
                    END.
                END.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* Picks up the thing in a cell and gives it: unknown when there is none. */
    METHOD PUBLIC Item TakeFloorItem(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE oItem AS Item    NO-UNDO.
        n = Cave:ItemAt(piX, piY).
        IF n = 0 THEN RETURN ?.
        oItem = mFloor[n].
        mFloor[n] = ?.
        Cave:SetItem(piX, piY, 0).
        RETURN oItem.
    END METHOD.

    /* True when a thing could lie in a cell: floor or a passage, with nothing on it already (stairs and doors keep clear). */
    METHOD PUBLIC LOGICAL CanLieAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN (Cave:TerrainAt(piX, piY) = INTEGER(Terrain:Floor) OR Cave:TerrainAt(piX, piY) = INTEGER(Terrain:Passage)) AND Cave:ItemAt(piX, piY) = 0.
    END METHOD.

    /* ================================== moving about ================================== */

    /* True when something standing at (piX, piY) can step by (piDX, piDY): the square is walkable, and a step across a corner is not
       allowed into or out of a doorway. Monsters in the way are not considered. */
    METHOD PUBLIC LOGICAL CanStep(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piDX AS INTEGER, INPUT piDY AS INTEGER):
        IF piDX = 0 AND piDY = 0 THEN RETURN FALSE.
        IF NOT Cave:Walkable(piX + piDX, piY + piDY) THEN RETURN FALSE.
        IF piDX <> 0 AND piDY <> 0 AND (Cave:IsDoorway(piX, piY) OR Cave:IsDoorway(piX + piDX, piY + piDY)) THEN RETURN FALSE.
        RETURN TRUE.
    END METHOD.

    /* The most squares apart two squares are in a straight count of steps (a diagonal step counts as one). */
    METHOD PUBLIC STATIC INTEGER Distance(INPUT piX0 AS INTEGER, INPUT piY0 AS INTEGER, INPUT piX1 AS INTEGER, INPUT piY1 AS INTEGER):
        RETURN MAXIMUM(ABSOLUTE(piX1 - piX0), ABSOLUTE(piY1 - piY0)).
    END METHOD.

    /* ================================== messages ================================== */

    /* Says something to the hero. */
    METHOD PUBLIC VOID Say(INPUT pcText AS CHARACTER):
        Messages:Add(pcText).
    END METHOD.

    /* Frees what the world holds. */
    METHOD PUBLIC VOID Dispose():
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
    END METHOD.

END CLASS.
