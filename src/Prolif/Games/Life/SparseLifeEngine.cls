/* Life engine for a SparseStore grid. Each step touches only live cells and their neighbours,
   so its cost follows the number of live cells, not the size of the board: the live cells are
   exported, every live cell adds one to the count of each of its neighbours in a second
   table, and only the counted cells (plus live cells with no neighbours) are looked at to
   decide who lives. The new live cells are then imported back into the store.

   The grid must have a SparseStore with exactly one layer holding only 0 and 1. Rules that
   give birth to a cell with no live neighbours (B0) are refused, because they would fill the
   whole empty board and a sparse engine cannot represent that. Needs no memory beyond
   temp tables. */
USING Progress.Lang.*.
USING Prolif.Core.*.
USING Prolif.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Games.Life.SparseLifeEngine FINAL IMPLEMENTS ILifeEngine:

    {Prolif/Core/SparseCells.i &NAME=ttLive &ACCESS=PRIVATE}
    {Prolif/Core/SparseCells.i &NAME=ttNext &ACCESS=PRIVATE}

    DEFINE PRIVATE TEMP-TABLE ttCount NO-UNDO
        FIELD cellIdx AS INTEGER
        FIELD live    AS INTEGER
        INDEX ixCount IS PRIMARY UNIQUE cellIdx.

    DEFINE PRIVATE VARIABLE mGrid    AS Grid         NO-UNDO.
    DEFINE PRIVATE VARIABLE mStore   AS SparseStore  NO-UNDO.
    DEFINE PRIVATE VARIABLE mTable   AS INTEGER      NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mNbr     AS INTEGER      NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mOffsets AS INTEGER      NO-UNDO.

    CONSTRUCTOR PUBLIC SparseLifeEngine(INPUT poGrid AS Grid, INPUT poRules AS LifeRules):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.

        IF NOT VALID-OBJECT(poGrid) THEN UNDO, THROW NEW GridException("The engine needs a grid").
        IF NOT VALID-OBJECT(poRules) THEN UNDO, THROW NEW GridException("The engine needs rules").
        IF NOT TYPE-OF(poGrid:Store, SparseStore) THEN
            UNDO, THROW NEW GridException("SparseLifeEngine needs a grid backed by a SparseStore").
        IF poGrid:Store:LayerCount <> 1 THEN
            UNDO, THROW NEW GridException("A Life grid has exactly one layer").
        IF poRules:Births(0) THEN
            UNDO, THROW NEW GridException("SparseLifeEngine cannot run rules with a birth on 0 neighbours: " + poRules:Notation).

        mGrid = poGrid.
        mStore = CAST(poGrid:Store, SparseStore).
        mOffsets = poGrid:Neighbourhood:OffsetCount.
        EXTENT(mNbr) = mOffsets.
        EXTENT(mTable) = 2 * (mOffsets + 1).
        DO i = 0 TO mOffsets:
            mTable[i + 1] = poRules:NextState(0, i).
            mTable[mOffsets + 1 + i + 1] = poRules:NextState(1, i).
        END.
    END CONSTRUCTOR.

    METHOD PUBLIC VOID Step():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE m AS INTEGER NO-UNDO.
        DEFINE VARIABLE w AS INTEGER NO-UNDO.

        w = mGrid:Width.
        mStore:ExportCells(OUTPUT TABLE ttLive).
        EMPTY TEMP-TABLE ttCount.
        EMPTY TEMP-TABLE ttNext.

        /* every live cell adds one to each of its neighbours */
        FOR EACH ttLive:
            m = mGrid:GetNeighbourIndexes(ttLive.cellIdx MODULO w, INTEGER(TRUNCATE(ttLive.cellIdx / w, 0)), mNbr).
            DO i = 1 TO m:
                FIND ttCount WHERE ttCount.cellIdx = mNbr[i] NO-ERROR.
                IF NOT AVAILABLE ttCount THEN DO:
                    CREATE ttCount.
                    ASSIGN ttCount.cellIdx = mNbr[i]
                           ttCount.live = 0.
                END.
                ttCount.live = ttCount.live + 1.
            END.
        END.

        /* cells with a count: born if dead, kept if alive, by the rule table */
        FOR EACH ttCount:
            IF CAN-FIND(ttLive WHERE ttLive.layerNo = 1 AND ttLive.cellIdx = ttCount.cellIdx) THEN DO:
                IF mTable[mOffsets + 1 + ttCount.live + 1] = 1 THEN DO:
                    CREATE ttNext.
                    ASSIGN ttNext.layerNo = 1 ttNext.cellIdx = ttCount.cellIdx ttNext.cellVal = 1.
                END.
            END.
            ELSE DO:
                IF mTable[ttCount.live + 1] = 1 THEN DO:
                    CREATE ttNext.
                    ASSIGN ttNext.layerNo = 1 ttNext.cellIdx = ttCount.cellIdx ttNext.cellVal = 1.
                END.
            END.
        END.

        /* live cells with no live neighbours at all never reached the count table */
        IF mTable[mOffsets + 1 + 1] = 1 THEN DO:
            FOR EACH ttLive:
                IF NOT CAN-FIND(ttCount WHERE ttCount.cellIdx = ttLive.cellIdx) THEN DO:
                    CREATE ttNext.
                    ASSIGN ttNext.layerNo = 1 ttNext.cellIdx = ttLive.cellIdx ttNext.cellVal = 1.
                END.
            END.
        END.

        mStore:ImportCells(INPUT TABLE ttNext).
    END METHOD.

    METHOD PUBLIC VOID Dispose():
        EMPTY TEMP-TABLE ttLive.
        EMPTY TEMP-TABLE ttCount.
        EMPTY TEMP-TABLE ttNext.
    END METHOD.

END CLASS.
