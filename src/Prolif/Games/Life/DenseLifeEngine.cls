/* Life engine for an ArrayStore grid. Each step copies the layer into a working buffer in
   one block, computes the next generation into a second buffer, and copies that back, so
   the update is simultaneous. Cells at least the neighbourhood's reach from every edge are
   counted with precomputed index steps and no topology calls (unrolled for eight
   neighbours, which is the fast case); edge cells ask the grid for their neighbours, so
   bounded and toroidal boards both work. About 40 ms a generation at 100 x 100.

   The grid must have an ArrayStore with exactly one layer holding only 0 and 1. The two
   working buffers are MEMPTRs, freed by Dispose and by the destructor. */
USING Progress.Lang.*.
USING Prolif.Core.*.
USING Prolif.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Games.Life.DenseLifeEngine FINAL IMPLEMENTS ILifeEngine:

    DEFINE PRIVATE VARIABLE mGrid    AS Grid       NO-UNDO.
    DEFINE PRIVATE VARIABLE mStore   AS ArrayStore NO-UNDO.
    DEFINE PRIVATE VARIABLE mCur     AS MEMPTR     NO-UNDO.
    DEFINE PRIVATE VARIABLE mNext    AS MEMPTR     NO-UNDO.
    /* Next state by (state, neighbour count): entry (count + 1) for a dead cell and
       (offsets + 1 + count + 1) for a live one. */
    DEFINE PRIVATE VARIABLE mTable   AS INTEGER    NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mDelta   AS INTEGER    NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mNbr     AS INTEGER    NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mOffsets AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mReach   AS INTEGER    NO-UNDO.

    CONSTRUCTOR PUBLIC DenseLifeEngine(INPUT poGrid AS Grid, INPUT poRules AS LifeRules):
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE nbh AS INeighbourhood NO-UNDO.

        IF NOT VALID-OBJECT(poGrid) THEN UNDO, THROW NEW GridException("The engine needs a grid").
        IF NOT VALID-OBJECT(poRules) THEN UNDO, THROW NEW GridException("The engine needs rules").
        IF NOT TYPE-OF(poGrid:Store, ArrayStore) THEN
            UNDO, THROW NEW GridException("DenseLifeEngine needs a grid backed by an ArrayStore").
        IF poGrid:Store:LayerCount <> 1 THEN
            UNDO, THROW NEW GridException("A Life grid has exactly one layer").

        mGrid = poGrid.
        mStore = CAST(poGrid:Store, ArrayStore).
        nbh = poGrid:Neighbourhood.
        mOffsets = nbh:OffsetCount.
        mReach = nbh:Reach.

        EXTENT(mDelta) = mOffsets.
        EXTENT(mNbr) = mOffsets.
        DO i = 1 TO mOffsets:
            mDelta[i] = nbh:OffsetY(i) * poGrid:Width + nbh:OffsetX(i).
        END.

        EXTENT(mTable) = 2 * (mOffsets + 1).
        DO i = 0 TO mOffsets:
            mTable[i + 1] = poRules:NextState(0, i).
            mTable[mOffsets + 1 + i + 1] = poRules:NextState(1, i).
        END.

        SET-SIZE(mCur) = poGrid:CellCount * 4.
        SET-SIZE(mNext) = poGrid:CellCount * 4.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC DenseLifeEngine():
        SET-SIZE(mCur) = 0.
        SET-SIZE(mNext) = 0.
    END DESTRUCTOR.

    METHOD PUBLIC VOID Step():
        DEFINE VARIABLE w    AS INTEGER NO-UNDO.
        DEFINE VARIABLE h    AS INTEGER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE k    AS INTEGER NO-UNDO.
        DEFINE VARIABLE m    AS INTEGER NO-UNDO.
        DEFINE VARIABLE idx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE cnt  AS INTEGER NO-UNDO.
        DEFINE VARIABLE xEnd AS INTEGER NO-UNDO.
        DEFINE VARIABLE yEnd AS INTEGER NO-UNDO.
        DEFINE VARIABLE live AS INTEGER NO-UNDO.
        DEFINE VARIABLE d1   AS INTEGER NO-UNDO.
        DEFINE VARIABLE d2   AS INTEGER NO-UNDO.
        DEFINE VARIABLE d3   AS INTEGER NO-UNDO.
        DEFINE VARIABLE d4   AS INTEGER NO-UNDO.
        DEFINE VARIABLE d5   AS INTEGER NO-UNDO.
        DEFINE VARIABLE d6   AS INTEGER NO-UNDO.
        DEFINE VARIABLE d7   AS INTEGER NO-UNDO.
        DEFINE VARIABLE d8   AS INTEGER NO-UNDO.
        DEFINE VARIABLE inRow AS LOGICAL NO-UNDO.

        w = mGrid:Width.
        h = mGrid:Height.
        xEnd = w - mReach.
        yEnd = h - mReach.
        live = mOffsets + 1.
        IF mOffsets = 8 THEN
            ASSIGN d1 = mDelta[1] d2 = mDelta[2] d3 = mDelta[3] d4 = mDelta[4]
                   d5 = mDelta[5] d6 = mDelta[6] d7 = mDelta[7] d8 = mDelta[8].

        mStore:CopyBytesTo(mCur).
        DO y = 0 TO h - 1:
            inRow = y >= mReach AND y < yEnd.
            DO x = 0 TO w - 1:
                idx = y * w + x.
                IF inRow AND x >= mReach AND x < xEnd THEN DO:
                    IF mOffsets = 8 THEN
                        cnt = GET-LONG(mCur, (idx + d1) * 4 + 1) + GET-LONG(mCur, (idx + d2) * 4 + 1)
                            + GET-LONG(mCur, (idx + d3) * 4 + 1) + GET-LONG(mCur, (idx + d4) * 4 + 1)
                            + GET-LONG(mCur, (idx + d5) * 4 + 1) + GET-LONG(mCur, (idx + d6) * 4 + 1)
                            + GET-LONG(mCur, (idx + d7) * 4 + 1) + GET-LONG(mCur, (idx + d8) * 4 + 1).
                    ELSE DO:
                        cnt = 0.
                        DO k = 1 TO mOffsets:
                            cnt = cnt + GET-LONG(mCur, (idx + mDelta[k]) * 4 + 1).
                        END.
                    END.
                END.
                ELSE DO:
                    m = mGrid:GetNeighbourIndexes(x, y, mNbr).
                    cnt = 0.
                    DO k = 1 TO m:
                        cnt = cnt + GET-LONG(mCur, mNbr[k] * 4 + 1).
                    END.
                END.
                IF GET-LONG(mCur, idx * 4 + 1) <> 0 THEN
                    PUT-LONG(mNext, idx * 4 + 1) = mTable[live + cnt + 1].
                ELSE
                    PUT-LONG(mNext, idx * 4 + 1) = mTable[cnt + 1].
            END.
        END.
        mStore:CopyBytesFrom(mNext).
    END METHOD.

    METHOD PUBLIC VOID Dispose():
        SET-SIZE(mCur) = 0.
        SET-SIZE(mNext) = 0.
    END METHOD.

END CLASS.
