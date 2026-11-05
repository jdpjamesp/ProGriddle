/* Builds a level the way the original does. The map is cut into a 3 x 3 board of cells (26 or 28 across, 7 down), and every cell holds
   either a room of a random size and place inside it or, for up to four cells chosen at random, nothing but a single passage square
   where corridors meet. Rooms are joined: first by a random spanning tree over the board, so every room can be reached, then by some
   extra corridors for loops. A corridor leaves a room by a door in the wall that faces the next cell (a doorway is sometimes a secret
   door that looks like wall, more often the deeper the level) and runs in three straight pieces to the other door.

   Each room is lit unless a roll beats the depth: the deeper the level, the more rooms are dark and show only what is next to the hero.
   One room has the stairs down, another (a different one when there is a choice) is where the hero starts, and the level has a few
   hidden traps. Items and monsters are put in by the game, which uses RealRooms and FloorCellIn to find places for them.

   Rooms are numbered 0 to 8 here, row by row (and 1 to 9 in the room layer of the map). Everything is chosen with the random source. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Dungeon FINAL:

    DEFINE PRIVATE VARIABLE mMap    AS LevelMap NO-UNDO.
    DEFINE PRIVATE VARIABLE mRandom AS IRandom  NO-UNDO.
    DEFINE PRIVATE VARIABLE mDepth  AS INTEGER  NO-UNDO.
    /* the wall extents of each room (all four the same cell for a passage square), whether it is a room, and whether it is lit */
    DEFINE PRIVATE VARIABLE mLeft   AS INTEGER  NO-UNDO EXTENT 9.
    DEFINE PRIVATE VARIABLE mTop    AS INTEGER  NO-UNDO EXTENT 9.
    DEFINE PRIVATE VARIABLE mRight  AS INTEGER  NO-UNDO EXTENT 9.
    DEFINE PRIVATE VARIABLE mBottom AS INTEGER  NO-UNDO EXTENT 9.
    DEFINE PRIVATE VARIABLE mReal   AS LOGICAL  NO-UNDO EXTENT 9.
    DEFINE PRIVATE VARIABLE mLit    AS LOGICAL  NO-UNDO EXTENT 9.
    /* which pairs of cells have a corridor between them: cell * 9 + other */
    DEFINE PRIVATE VARIABLE mLinked AS LOGICAL  NO-UNDO EXTENT 81.

    DEFINE PUBLIC PROPERTY StartX AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY StartY AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY StairsX AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY StairsY AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many of the nine cells hold a room. */
    DEFINE PUBLIC PROPERTY RealRooms AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO 9:
                IF mReal[i] THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* How many traps the last Build laid. */
    DEFINE PUBLIC PROPERTY TrapCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Throws GridException for no map or no random source. */
    CONSTRUCTOR PUBLIC Dungeon(INPUT poMap AS LevelMap, INPUT poRandom AS IRandom):
        IF NOT VALID-OBJECT(poMap) THEN UNDO, THROW NEW GridException("A dungeon needs a map to build on").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A dungeon needs a random source").
        mMap = poMap.
        mRandom = poRandom.
    END CONSTRUCTOR.

    /* True when the cell (0 to 8) holds a room rather than a passage square. */
    METHOD PUBLIC LOGICAL IsRoom(INPUT piRoom AS INTEGER):
        CheckRoom(piRoom).
        RETURN mReal[piRoom + 1].
    END METHOD.

    /* True when the room is lit, so the hero sees all of it on stepping in. A passage square is never lit. */
    METHOD PUBLIC LOGICAL IsLit(INPUT piRoom AS INTEGER):
        CheckRoom(piRoom).
        RETURN mLit[piRoom + 1].
    END METHOD.

    /* The wall extents of a room (the cell of a passage square for all four): the left and top walls and the right and bottom walls. */
    METHOD PUBLIC INTEGER LeftOf(INPUT piRoom AS INTEGER):
        CheckRoom(piRoom).
        RETURN mLeft[piRoom + 1].
    END METHOD.

    METHOD PUBLIC INTEGER TopOf(INPUT piRoom AS INTEGER):
        CheckRoom(piRoom).
        RETURN mTop[piRoom + 1].
    END METHOD.

    METHOD PUBLIC INTEGER RightOf(INPUT piRoom AS INTEGER):
        CheckRoom(piRoom).
        RETURN mRight[piRoom + 1].
    END METHOD.

    METHOD PUBLIC INTEGER BottomOf(INPUT piRoom AS INTEGER):
        CheckRoom(piRoom).
        RETURN mBottom[piRoom + 1].
    END METHOD.

    /* True when a corridor was dug between two cells. */
    METHOD PUBLIC LOGICAL Linked(INPUT piA AS INTEGER, INPUT piB AS INTEGER):
        CheckRoom(piA).
        CheckRoom(piB).
        RETURN mLinked[piA * 9 + piB + 1].
    END METHOD.

    /* A room (not a passage square) picked at random: its number 0 to 8. */
    METHOD PUBLIC INTEGER PickRoom():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        k = mRandom:NextInt(RealRooms).
        DO i = 1 TO 9:
            IF mReal[i] THEN DO:
                IF n = k THEN RETURN i - 1.
                n = n + 1.
            END.
        END.
        RETURN 0.
    END METHOD.

    /* A floor cell inside a room, chosen at random, with no stairs on it (a few random tries, then the first floor cell of the room).
       Throws GridException for a cell that holds no room. */
    METHOD PUBLIC VOID FloorCellIn(INPUT piRoom AS INTEGER, OUTPUT piX AS INTEGER, OUTPUT piY AS INTEGER):
        DEFINE VARIABLE tries AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        CheckRoom(piRoom).
        IF NOT mReal[piRoom + 1] THEN UNDO, THROW NEW GridException("Cell " + STRING(piRoom) + " has no room, only a passage square").
        DO tries = 1 TO 20:
            piX = mLeft[piRoom + 1] + 1 + mRandom:NextInt(mRight[piRoom + 1] - mLeft[piRoom + 1] - 1).
            piY = mTop[piRoom + 1] + 1 + mRandom:NextInt(mBottom[piRoom + 1] - mTop[piRoom + 1] - 1).
            IF mMap:TerrainAt(piX, piY) = INTEGER(Terrain:Floor) THEN RETURN.
        END.
        DO y = mTop[piRoom + 1] + 1 TO mBottom[piRoom + 1] - 1:
            DO x = mLeft[piRoom + 1] + 1 TO mRight[piRoom + 1] - 1:
                IF mMap:TerrainAt(x, y) = INTEGER(Terrain:Floor) THEN DO:
                    piX = x.
                    piY = y.
                    RETURN.
                END.
            END.
        END.
    END METHOD.
    /* Forgets the rooms of the level that was built: for a level that is then cleared and made by hand, so nothing asks about rooms that
       are no longer there. */
    METHOD PUBLIC VOID Forget():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 9:
            mReal[i] = FALSE.
            mLit[i] = FALSE.
        END.
        DO i = 1 TO 81:
            mLinked[i] = FALSE.
        END.
    END METHOD.
    /* Builds a whole level for a depth on the map: the map is emptied first. */
    METHOD PUBLIC VOID Build(INPUT piDepth AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF piDepth = ? OR piDepth < 1 THEN UNDO, THROW NEW GridException("A level has a depth of 1 or more, not " + STRING(piDepth)).
        mDepth = piDepth.
        mMap:ClearAll().
        DO i = 1 TO 81:
            mLinked[i] = FALSE.
        END.
        MakeRooms().
        JoinRooms().
        PlaceStairsAndStart().
        LayTraps().
    END METHOD.

    /* ===================================== rooms ===================================== */

    METHOD PRIVATE VOID MakeRooms():
        DEFINE VARIABLE gone    AS LOGICAL NO-UNDO EXTENT 9.
        DEFINE VARIABLE order   AS INTEGER NO-UNDO EXTENT 9.
        DEFINE VARIABLE howMany AS INTEGER NO-UNDO.
        DEFINE VARIABLE c       AS INTEGER NO-UNDO.
        DEFINE VARIABLE j       AS INTEGER NO-UNDO.
        DEFINE VARIABLE swap    AS INTEGER NO-UNDO.
        DO c = 1 TO 9:
            order[c] = c.
        END.
        /* up to four cells are left without a room: the first few of a shuffle of the nine */
        howMany = mRandom:NextInt(5).
        DO c = 1 TO howMany:
            j = c + mRandom:NextInt(9 - c + 1).
            swap = order[c].
            order[c] = order[j].
            order[j] = swap.
            gone[order[c]] = TRUE.
        END.
        DO c = 0 TO 8:
            IF gone[c + 1] THEN MakePassageSquare(c).
            ELSE MakeRoom(c).
        END.
    END METHOD.
    /* The left edge and width of the cell of the board: 26 columns each, and the last takes the 2 over. */
    METHOD PRIVATE INTEGER CellLeft(INPUT piCell AS INTEGER):
        RETURN (piCell MODULO 3) * 26.
    END METHOD.

    METHOD PRIVATE INTEGER CellWidth(INPUT piCell AS INTEGER):
        RETURN (IF piCell MODULO 3 = 2 THEN 28 ELSE 26).
    END METHOD.

    METHOD PRIVATE INTEGER CellTop(INPUT piCell AS INTEGER):
        RETURN INTEGER(TRUNCATE(piCell / 3, 0)) * 7.
    END METHOD.

    METHOD PRIVATE VOID MakePassageSquare(INPUT piCell AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        x = CellLeft(piCell) + 3 + mRandom:NextInt(CellWidth(piCell) - 6).
        y = CellTop(piCell) + 1 + mRandom:NextInt(5).
        mMap:SetTerrain(x, y, Terrain:Passage).
        mLeft[piCell + 1] = x.
        mRight[piCell + 1] = x.
        mTop[piCell + 1] = y.
        mBottom[piCell + 1] = y.
        mReal[piCell + 1] = FALSE.
        mLit[piCell + 1] = FALSE.
    END METHOD.

    /* A room whose floor is 4 to 18 across and 2 or 3 down, with a wall round it, kept one square in from the edge of its cell on the left,
       the right and the top and bottom so that corridors can pass between rooms. */
    METHOD PRIVATE VOID MakeRoom(INPUT piCell AS INTEGER):
        DEFINE VARIABLE iw      AS INTEGER NO-UNDO.
        DEFINE VARIABLE ih      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x0      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y0      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER NO-UNDO.
        iw = 4 + mRandom:NextInt(15).
        ih = 2 + mRandom:NextInt(2).
        x0 = CellLeft(piCell) + 1 + mRandom:NextInt(CellWidth(piCell) - 2 - (iw + 2) + 1).
        y0 = CellTop(piCell) + 1 + mRandom:NextInt(5 - (ih + 2) + 1).
        mLeft[piCell + 1] = x0.
        mRight[piCell + 1] = x0 + iw + 1.
        mTop[piCell + 1] = y0.
        mBottom[piCell + 1] = y0 + ih + 1.
        mReal[piCell + 1] = TRUE.
        mLit[piCell + 1] = NOT (mRandom:NextInt(10) < mDepth - 1).
        DO y = y0 TO y0 + ih + 1:
            DO x = x0 TO x0 + iw + 1:
                mMap:SetRoom(x, y, piCell + 1).
                IF y = y0 AND x = x0 THEN mMap:SetTerrain(x, y, Terrain:CornerTopLeft).
                ELSE IF y = y0 AND x = x0 + iw + 1 THEN mMap:SetTerrain(x, y, Terrain:CornerTopRight).
                ELSE IF y = y0 + ih + 1 AND x = x0 THEN mMap:SetTerrain(x, y, Terrain:CornerBottomLeft).
                ELSE IF y = y0 + ih + 1 AND x = x0 + iw + 1 THEN mMap:SetTerrain(x, y, Terrain:CornerBottomRight).
                ELSE IF y = y0 OR y = y0 + ih + 1 THEN mMap:SetTerrain(x, y, Terrain:WallAcross).
                ELSE IF x = x0 OR x = x0 + iw + 1 THEN mMap:SetTerrain(x, y, Terrain:WallDown).
                ELSE mMap:SetTerrain(x, y, Terrain:Floor).
            END.
        END.
    END METHOD.

    /* ================================== corridors ================================== */

    /* Joins every cell to the board by a random spanning tree, then adds some extra corridors. */
    METHOD PRIVATE VOID JoinRooms():
        DEFINE VARIABLE visited AS LOGICAL NO-UNDO EXTENT 9.
        DEFINE VARIABLE pairA   AS INTEGER NO-UNDO EXTENT 36.
        DEFINE VARIABLE pairB   AS INTEGER NO-UNDO EXTENT 36.
        DEFINE VARIABLE joined  AS INTEGER NO-UNDO.
        DEFINE VARIABLE a       AS INTEGER NO-UNDO.
        DEFINE VARIABLE b       AS INTEGER NO-UNDO.
        DEFINE VARIABLE k       AS INTEGER NO-UNDO.
        DEFINE VARIABLE pairs   AS INTEGER NO-UNDO.
        DEFINE VARIABLE pick    AS INTEGER NO-UNDO.
        visited[mRandom:NextInt(9) + 1] = TRUE.
        joined = 1.
        DO WHILE joined < 9:
            /* every pair of a visited cell and an unvisited neighbour: one of them is joined */
            pairs = 0.
            DO a = 0 TO 8:
                DO k = 0 TO 3:
                    b = Neighbour(a, k).
                    IF b >= 0 AND visited[a + 1] AND NOT visited[b + 1] THEN DO:
                        pairs = pairs + 1.
                        pairA[pairs] = a.
                        pairB[pairs] = b.
                    END.
                END.
            END.
            pick = mRandom:NextInt(pairs) + 1.
            Connect(pairA[pick], pairB[pick]).
            visited[pairB[pick] + 1] = TRUE.
            joined = joined + 1.
        END.
        /* some loops */
        DO a = 0 TO 8:
            DO k = 0 TO 3:
                b = Neighbour(a, k).
                IF b > a AND NOT mLinked[a * 9 + b + 1] AND mRandom:NextInt(5) = 0 THEN Connect(a, b).
            END.
        END.
    END METHOD.
    /* The cell next to a cell in a direction (0 left, 1 right, 2 up, 3 down), or -1 off the board. */
    METHOD PRIVATE INTEGER Neighbour(INPUT piCell AS INTEGER, INPUT piDirection AS INTEGER):
        CASE piDirection:
            WHEN 0 THEN RETURN (IF piCell MODULO 3 > 0 THEN piCell - 1 ELSE -1).
            WHEN 1 THEN RETURN (IF piCell MODULO 3 < 2 THEN piCell + 1 ELSE -1).
            WHEN 2 THEN RETURN (IF piCell >= 3 THEN piCell - 3 ELSE -1).
            OTHERWISE RETURN (IF piCell < 6 THEN piCell + 3 ELSE -1).
        END CASE.
    END METHOD.

    /* Digs the corridor between two neighbouring cells, in either order. */
    METHOD PRIVATE VOID Connect(INPUT piA AS INTEGER, INPUT piB AS INTEGER):
        DEFINE VARIABLE lowCell AS INTEGER NO-UNDO.
        DEFINE VARIABLE highCell AS INTEGER NO-UNDO.
        DEFINE VARIABLE sx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE sy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE ex     AS INTEGER NO-UNDO.
        DEFINE VARIABLE ey     AS INTEGER NO-UNDO.
        DEFINE VARIABLE mid    AS INTEGER NO-UNDO.
        lowCell = MINIMUM(piA, piB).
        highCell = MAXIMUM(piA, piB).
        mLinked[lowCell * 9 + highCell + 1] = TRUE.
        mLinked[highCell * 9 + lowCell + 1] = TRUE.
        IF highCell = lowCell + 1 THEN DO:
            /* side by side: out of the right wall of the first, in at the left wall of the second */
            DoorOn(lowCell, 1, OUTPUT sx, OUTPUT sy).
            DoorOn(highCell, 0, OUTPUT ex, OUTPUT ey).
            mid = sx + mRandom:NextInt(ex - sx + 1).
            DigAcross(sx, mid, sy).
            DigDown(mid, sy, ey).
            DigAcross(mid, ex, ey).
        END.
        ELSE DO:
            /* one above the other: out of the bottom wall of the first, in at the top wall of the second */
            DoorOn(lowCell, 3, OUTPUT sx, OUTPUT sy).
            DoorOn(highCell, 2, OUTPUT ex, OUTPUT ey).
            mid = sy + mRandom:NextInt(ey - sy + 1).
            DigDown(sx, sy, mid).
            DigAcross(sx, ex, mid).
            DigDown(ex, mid, ey).
        END.
    END METHOD.

    /* Makes the door on the wall of a room that faces a direction (0 left, 1 right, 2 up, 3 down) and gives the square just outside it,
       where the corridor starts. A passage square has no wall: the square itself is where the corridor starts. */
    METHOD PRIVATE VOID DoorOn(INPUT piCell AS INTEGER, INPUT piDirection AS INTEGER, OUTPUT piX AS INTEGER, OUTPUT piY AS INTEGER):
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        IF NOT mReal[piCell + 1] THEN DO:
            piX = mLeft[piCell + 1].
            piY = mTop[piCell + 1].
            RETURN.
        END.
        CASE piDirection:
            WHEN 0 THEN DO:
                dx = mLeft[piCell + 1].
                dy = mTop[piCell + 1] + 1 + mRandom:NextInt(mBottom[piCell + 1] - mTop[piCell + 1] - 1).
                piX = dx - 1.
                piY = dy.
            END.
            WHEN 1 THEN DO:
                dx = mRight[piCell + 1].
                dy = mTop[piCell + 1] + 1 + mRandom:NextInt(mBottom[piCell + 1] - mTop[piCell + 1] - 1).
                piX = dx + 1.
                piY = dy.
            END.
            WHEN 2 THEN DO:
                dx = mLeft[piCell + 1] + 1 + mRandom:NextInt(mRight[piCell + 1] - mLeft[piCell + 1] - 1).
                dy = mTop[piCell + 1].
                piX = dx.
                piY = dy - 1.
            END.
            OTHERWISE DO:
                dx = mLeft[piCell + 1] + 1 + mRandom:NextInt(mRight[piCell + 1] - mLeft[piCell + 1] - 1).
                dy = mBottom[piCell + 1].
                piX = dx.
                piY = dy + 1.
            END.
        END CASE.
        PutDoor(dx, dy, (piDirection <= 1)).
    END METHOD.

    /* A door in a wall: a secret one now and then on the deeper levels. poSide is true for a wall that runs up and down. A door that is
       already there stays. */
    METHOD PRIVATE VOID PutDoor(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plUpAndDown AS LOGICAL):
        IF mMap:IsDoorway(piX, piY) THEN RETURN.
        IF mRandom:NextInt(10) + 1 < mDepth AND mRandom:NextInt(5) = 0 THEN
            mMap:SetTerrain(piX, piY, (IF plUpAndDown THEN Terrain:SecretDown ELSE Terrain:SecretAcross)).
        ELSE mMap:SetTerrain(piX, piY, Terrain:Door).
    END METHOD.

    METHOD PRIVATE VOID DigAcross(INPUT piX0 AS INTEGER, INPUT piX1 AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DO x = MINIMUM(piX0, piX1) TO MAXIMUM(piX0, piX1):
            Dig(x, piY).
        END.
    END METHOD.

    METHOD PRIVATE VOID DigDown(INPUT piX AS INTEGER, INPUT piY0 AS INTEGER, INPUT piY1 AS INTEGER):
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = MINIMUM(piY0, piY1) TO MAXIMUM(piY0, piY1):
            Dig(piX, y).
        END.
    END METHOD.

    /* Turns rock into passage. Anything already open stays as it is. */
    METHOD PRIVATE VOID Dig(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF mMap:TerrainAt(piX, piY) = INTEGER(Terrain:Rock) THEN mMap:SetTerrain(piX, piY, Terrain:Passage).
    END METHOD.

    /* ============================ stairs, start and traps ============================ */

    METHOD PRIVATE VOID PlaceStairsAndStart():
        DEFINE VARIABLE stairsRoom AS INTEGER NO-UNDO.
        DEFINE VARIABLE startRoom  AS INTEGER NO-UNDO.
        DEFINE VARIABLE k          AS INTEGER NO-UNDO.
        DEFINE VARIABLE n          AS INTEGER NO-UNDO.
        DEFINE VARIABLE i          AS INTEGER NO-UNDO.
        stairsRoom = PickRoom().
        FloorCellIn(stairsRoom, OUTPUT StairsX, OUTPUT StairsY).
        mMap:SetTerrain(StairsX, StairsY, Terrain:Stairs).
        /* the start room is one of the other rooms, if there are any */
        startRoom = stairsRoom.
        IF RealRooms > 1 THEN DO:
            k = mRandom:NextInt(RealRooms - 1).
            DO i = 0 TO 8:
                IF mReal[i + 1] AND i <> stairsRoom THEN DO:
                    IF n = k THEN startRoom = i.
                    n = n + 1.
                END.
            END.
        END.
        FloorCellIn(startRoom, OUTPUT StartX, OUTPUT StartY).
    END METHOD.
    /* From 1 to 10 hidden traps on floor squares, more the deeper the level. */
    METHOD PRIVATE VOID LayTraps():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        n = MINIMUM(10, mRandom:NextInt(INTEGER(TRUNCATE(mDepth / 4, 0)) + 1) + 1).
        TrapCount = 0.
        DO i = 1 TO n:
            FloorCellIn(PickRoom(), OUTPUT x, OUTPUT y).
            IF mMap:TrapAt(x, y) = 0 AND NOT (x = StartX AND y = StartY) THEN DO:
                mMap:SetTrap(x, y, INTEGER(Traps:Roll(mRandom)) + 1).
                TrapCount = TrapCount + 1.
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID CheckRoom(INPUT piRoom AS INTEGER):
        IF piRoom = ? OR piRoom < 0 OR piRoom > 8 THEN UNDO, THROW NEW GridException("There is no room " + STRING(piRoom) + ", only 0 to 8").
    END METHOD.

END CLASS.
