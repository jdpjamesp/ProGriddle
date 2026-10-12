/* A rectangular board: a width, a height, the cell store that holds its contents, a
   topology (what happens at the edges) and a neighbourhood (which cells are neighbours).
   Also the single place for index maths. x and y start at 0 and the cell index is
   (y * Width) + x, so a 3 x 5 grid has indexes 0 to 14 and the cell (2, 1) is index 5.

   The grid owns its store: Dispose on the grid disposes the store. */
USING Progress.Lang.*.
USING Prolif.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.Grid FINAL:

    /* Index step of each neighbourhood offset: dy * Width + dx. For a cell far enough from
       every edge, its neighbours are simply its own index plus these. */
    DEFINE PRIVATE VARIABLE mDelta       AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mDx          AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mDy          AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mOffsets     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mReach       AS INTEGER NO-UNDO.
    /* True when wrapping on a board this small can list a cell twice or list the cell itself. */
    DEFINE PRIVATE VARIABLE mNeedsUnique AS LOGICAL NO-UNDO.

    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Width * Height. */
    DEFINE PUBLIC PROPERTY CellCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Store AS ICellStore NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Topology AS ITopology NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Neighbourhood AS INeighbourhood NO-UNDO
        GET.
        PRIVATE SET.

    /* A bounded grid with Moore (eight cell) neighbours. */
    CONSTRUCTOR PUBLIC Grid(INPUT poStore AS ICellStore):
        THIS-OBJECT(poStore, NEW BoundedTopology(), NEW MooreNeighbourhood()).
    END CONSTRUCTOR.

    /* The grid takes its size from the store, so the two can never disagree. */
    CONSTRUCTOR PUBLIC Grid(INPUT poStore AS ICellStore, INPUT poTopology AS ITopology, INPUT poNeighbourhood AS INeighbourhood):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poStore) THEN
            UNDO, THROW NEW GridException("A grid needs a cell store").
        IF NOT VALID-OBJECT(poTopology) THEN
            UNDO, THROW NEW GridException("A grid needs a topology").
        IF NOT VALID-OBJECT(poNeighbourhood) THEN
            UNDO, THROW NEW GridException("A grid needs a neighbourhood").

        Store = poStore.
        Topology = poTopology.
        Neighbourhood = poNeighbourhood.
        Width = poStore:Width.
        Height = poStore:Height.
        CellCount = Width * Height.

        mOffsets = poNeighbourhood:OffsetCount.
        mReach = poNeighbourhood:Reach.
        EXTENT(mDx) = mOffsets.
        EXTENT(mDy) = mOffsets.
        EXTENT(mDelta) = mOffsets.
        DO i = 1 TO mOffsets:
            mDx[i] = poNeighbourhood:OffsetX(i).
            mDy[i] = poNeighbourhood:OffsetY(i).
            mDelta[i] = mDy[i] * Width + mDx[i].
        END.
        mNeedsUnique = poTopology:Wraps AND (Width <= 2 * mReach OR Height <= 2 * mReach).
    END CONSTRUCTOR.

    /* True when (piX, piY) is on the grid. */
    METHOD PUBLIC LOGICAL InBounds(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN piX >= 0 AND piX < Width AND piY >= 0 AND piY < Height.
    END METHOD.

    /* Cell index of (piX, piY). Throws GridException when it is off the grid. */
    METHOD PUBLIC INTEGER IndexOf(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= Width OR piY < 0 OR piY >= Height THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 grid", piX, piY, Width, Height)).
        RETURN piY * Width + piX.
    END METHOD.

    /* Cell index that (piX, piY) refers to after the topology is applied, or the unknown
       value when there is no such cell. Unlike IndexOf, any x and y are accepted. */
    METHOD PUBLIC INTEGER Resolve(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Topology:Resolve(Width, Height, piX, piY).
    END METHOD.

    /* Column of a cell index. Throws GridException when the index is off the grid. */
    METHOD PUBLIC INTEGER XOf(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN piIndex MODULO Width.
    END METHOD.

    /* Row of a cell index. Throws GridException when the index is off the grid. */
    METHOD PUBLIC INTEGER YOf(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN INTEGER(TRUNCATE(piIndex / Width, 0)).
    END METHOD.

    /* Writes the cell indexes of the neighbours of (piX, piY) into the caller's array and
       returns how many there are. No object is allocated, so it is safe in hot loops.

       The array must have at least as many elements as the neighbourhood has offsets, and
       is filled from element 1 in the neighbourhood's offset order. Elements after the
       returned count are left as they were. Neighbours that fall off a bounded board are
       left out. Each distinct neighbouring cell is listed once, and a cell is never its own
       neighbour, which matters on tiny wrapped boards: a 2 x 2 torus gives every cell 3
       Moore neighbours and a 1 x 1 torus gives none.

       Throws GridException when (piX, piY) is off the grid or the array is too small. */
    METHOD PUBLIC INTEGER GetNeighbourIndexes(INPUT piX AS INTEGER, INPUT piY AS INTEGER,
                                              INPUT-OUTPUT piIndexes AS INTEGER EXTENT):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE idx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE r     AS INTEGER NO-UNDO.
        DEFINE VARIABLE dupe  AS LOGICAL NO-UNDO.

        IF piX < 0 OR piX >= Width OR piY < 0 OR piY >= Height THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 grid", piX, piY, Width, Height)).
        IF EXTENT(piIndexes) = ? OR EXTENT(piIndexes) < mOffsets THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Neighbour array needs at least &1 elements", mOffsets)).

        idx = piY * Width + piX.

        /* Far from every edge: no topology involved, no wrapping, no duplicates. */
        IF piX >= mReach AND piX < Width - mReach AND piY >= mReach AND piY < Height - mReach THEN DO:
            DO i = 1 TO mOffsets:
                piIndexes[i] = idx + mDelta[i].
            END.
            RETURN mOffsets.
        END.

        DO i = 1 TO mOffsets:
            r = Topology:Resolve(Width, Height, piX + mDx[i], piY + mDy[i]).
            IF r = ? THEN NEXT.
            IF mNeedsUnique THEN DO:
                IF r = idx THEN NEXT.
                dupe = FALSE.
                DO j = 1 TO n:
                    IF piIndexes[j] = r THEN dupe = TRUE.
                END.
                IF dupe THEN NEXT.
            END.
            n = n + 1.
            piIndexes[n] = r.
        END.
        RETURN n.
    END METHOD.

    /* New grid with an independent copy of the store, sharing the topology and neighbourhood
       (both hold no state). */
    METHOD PUBLIC Grid Duplicate():
        RETURN NEW Grid(Store:Duplicate(), Topology, Neighbourhood).
    END METHOD.

    /* Disposes the store. Call it when the grid is no longer needed. */
    METHOD PUBLIC VOID Dispose():
        IF VALID-OBJECT(Store) THEN Store:Dispose().
    END METHOD.

    METHOD PRIVATE VOID CheckIndex(INPUT piIndex AS INTEGER):
        IF piIndex < 0 OR piIndex >= CellCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell index &1 is outside 0 to &2", piIndex, CellCount - 1)).
    END METHOD.

END CLASS.
