/* The map of one level, as typed access to the layers of the game's grid (80 x 21 cells, eight layers):

     terrain  what the cell is made of (a Terrain, as its number)       room    which room the cell belongs to, 1 to 9, 0 for none
     seen     1 once the hero has seen the cell (it is then remembered)  view    1 while the cell is in the hero's sight now
     trap     0, or the kind of the trap plus 1                          found   1 once the hero has found the trap
     item     0, or the position in the game's floor list plus 1         mon     0, or the position in the game's monster list plus 1

   Whatever walks is Floor, Door, Passage or Stairs. Whatever stops the eye is everything that cannot be walked on: rock, walls, corners
   and secret doors (a door in the wall that looks like wall until it is found). The map does not own the grid. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.LevelMap FINAL:

    VAR PRIVATE Grid mGrid.
    VAR PRIVATE ICellStore mStore.
    VAR PRIVATE INTEGER mTerrain.
    VAR PRIVATE INTEGER mRoom.
    VAR PRIVATE INTEGER mSeen.
    VAR PRIVATE INTEGER mView.
    VAR PRIVATE INTEGER mTrap.
    VAR PRIVATE INTEGER mFound.
    VAR PRIVATE INTEGER mItem.
    VAR PRIVATE INTEGER mMon.

    /* The layers a Rogue grid must have, in order. */
    METHOD PUBLIC STATIC CHARACTER Layers():
        RETURN "terrain,room,seen,view,trap,found,item,mon".
    END METHOD.

    /* A grid of the right size and layers for a level. */
    METHOD PUBLIC STATIC Grid CreateGrid():
        RETURN NEW Grid(NEW ArrayStore(RogueRules:MapWidth(), RogueRules:MapHeight(), Layers())).
    END METHOD.

    /* Throws GridException for no grid, or a grid that is not 80 x 21 with the layers of Layers(). */
    CONSTRUCTOR PUBLIC LevelMap(INPUT poGrid AS Grid):
        IF NOT VALID-OBJECT(poGrid) THEN UNDO, THROW NEW GridException("A level map needs a grid").
        IF poGrid:Width <> RogueRules:MapWidth() OR poGrid:Height <> RogueRules:MapHeight() THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A level map is &1 x &2, not &3 x &4", RogueRules:MapWidth(), RogueRules:MapHeight(), poGrid:Width, poGrid:Height)).
        mGrid = poGrid.
        mStore = poGrid:Store.
        mTerrain = mStore:LayerIndex("terrain").
        mRoom = mStore:LayerIndex("room").
        mSeen = mStore:LayerIndex("seen").
        mView = mStore:LayerIndex("view").
        mTrap = mStore:LayerIndex("trap").
        mFound = mStore:LayerIndex("found").
        mItem = mStore:LayerIndex("item").
        mMon = mStore:LayerIndex("mon").
    END CONSTRUCTOR.

    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET():
            RETURN mGrid:Width.
        END GET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET():
            RETURN mGrid:Height.
        END GET.

    METHOD PUBLIC LOGICAL InBounds(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN piX >= 0 AND piX < mGrid:Width AND piY >= 0 AND piY < mGrid:Height.
    END METHOD.

    /* Empties every layer: all rock, nothing seen, nothing on it. */
    METHOD PUBLIC VOID ClearAll():
        VAR INTEGER i.
        DO i = 1 TO mStore:LayerCount:
            mStore:FillLayer(i, 0).
        END.
    END METHOD.

    /* The terrain of a cell as its number (INTEGER of a Terrain). Cells off the map are rock. */
    METHOD PUBLIC INTEGER TerrainAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT InBounds(piX, piY) THEN RETURN INTEGER(Terrain:Rock).
        RETURN mStore:GetCell(mTerrain, piX, piY).
    END METHOD.

    METHOD PUBLIC VOID SetTerrain(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT poTerrain AS Terrain):
        mStore:SetCell(mTerrain, piX, piY, INTEGER(poTerrain)).
    END METHOD.

    /* The room of a cell, 1 to 9, or 0. */
    METHOD PUBLIC INTEGER RoomAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT InBounds(piX, piY) THEN RETURN 0.
        RETURN mStore:GetCell(mRoom, piX, piY).
    END METHOD.

    METHOD PUBLIC VOID SetRoom(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piRoom AS INTEGER):
        mStore:SetCell(mRoom, piX, piY, piRoom).
    END METHOD.

    METHOD PUBLIC LOGICAL IsSeen(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN InBounds(piX, piY) AND mStore:GetCell(mSeen, piX, piY) = 1.
    END METHOD.

    METHOD PUBLIC VOID SetSeen(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plSeen AS LOGICAL):
        mStore:SetCell(mSeen, piX, piY, (IF plSeen THEN 1 ELSE 0)).
    END METHOD.

    METHOD PUBLIC LOGICAL InView(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN InBounds(piX, piY) AND mStore:GetCell(mView, piX, piY) = 1.
    END METHOD.

    METHOD PUBLIC VOID SetInView(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plView AS LOGICAL):
        mStore:SetCell(mView, piX, piY, (IF plView THEN 1 ELSE 0)).
    END METHOD.

    /* Takes every cell out of sight (the first thing a look does). */
    METHOD PUBLIC VOID ClearView():
        mStore:FillLayer(mView, 0).
    END METHOD.

    /* The trap in a cell, as the number of a TrapKind plus 1, or 0 for none. */
    METHOD PUBLIC INTEGER TrapAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT InBounds(piX, piY) THEN RETURN 0.
        RETURN mStore:GetCell(mTrap, piX, piY).
    END METHOD.

    METHOD PUBLIC VOID SetTrap(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piCode AS INTEGER):
        mStore:SetCell(mTrap, piX, piY, piCode).
    END METHOD.

    METHOD PUBLIC LOGICAL TrapFound(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN InBounds(piX, piY) AND mStore:GetCell(mFound, piX, piY) = 1.
    END METHOD.

    METHOD PUBLIC VOID SetTrapFound(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plFound AS LOGICAL):
        mStore:SetCell(mFound, piX, piY, (IF plFound THEN 1 ELSE 0)).
    END METHOD.

    /* The position in the game's floor list plus 1 of the item in a cell, or 0. */
    METHOD PUBLIC INTEGER ItemAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT InBounds(piX, piY) THEN RETURN 0.
        RETURN mStore:GetCell(mItem, piX, piY).
    END METHOD.

    METHOD PUBLIC VOID SetItem(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piCode AS INTEGER):
        mStore:SetCell(mItem, piX, piY, piCode).
    END METHOD.

    /* The position in the game's monster list plus 1 of the monster in a cell, or 0. */
    METHOD PUBLIC INTEGER MonsterAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT InBounds(piX, piY) THEN RETURN 0.
        RETURN mStore:GetCell(mMon, piX, piY).
    END METHOD.

    METHOD PUBLIC VOID SetMonster(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piCode AS INTEGER):
        mStore:SetCell(mMon, piX, piY, piCode).
    END METHOD.

    /* The numbers of the terrain that the three questions below are asked about, which the tests check against the Terrain enum. They
       are plain numbers because these are asked tens of thousands of times a turn (every step of every search). */
    /* Floor 1, Door 8, Passage 11, Stairs 12: true for terrain that can be walked on. Off the map is not. */
    METHOD PUBLIC LOGICAL Walkable(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR INTEGER t.
        t = TerrainAt(piX, piY).
        RETURN t = 1 OR t = 8 OR t = 11 OR t = 12.
    END METHOD.

    /* True for what the eye cannot pass: everything that cannot be walked on. */
    METHOD PUBLIC LOGICAL Opaque(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN NOT Walkable(piX, piY).
    END METHOD.

    /* True for a door, found or not (Door 8, SecretAcross 9, SecretDown 10): no diagonal step goes into or out of one. */
    METHOD PUBLIC LOGICAL IsDoorway(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR INTEGER t.
        t = TerrainAt(piX, piY).
        RETURN t >= 8 AND t <= 10.
    END METHOD.

    /* True for a secret door that has not been found. */
    METHOD PUBLIC LOGICAL IsSecret(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR INTEGER t.
        t = TerrainAt(piX, piY).
        RETURN t = 9 OR t = 10.
    END METHOD.
END CLASS.
