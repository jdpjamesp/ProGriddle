/* Cell store backed by a temp table with one record per cell: integer fields "x" and "y",
   one integer field per layer named after the layer, and a unique index on (x, y). Games
   with small boards (Minesweeper, Battleships, Tetris) get readable, queryable data:
   BufferHandle exposes the table so a layer such as "mine" is a real field.

   Each cell's ROWID is cached when the store is built (as fixed width text in a MEMPTR,
   because an extent of ROWIDs is limited to a few thousand elements), so a read or write
   is one direct find plus a field access. The store is meant for small boards and is
   limited to 100,000 cells. Use ArrayStore or SparseStore for larger boards.

   The temp table and the MEMPTR are freed by Dispose, and by the destructor as a safety net. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.TableStore FINAL INHERITS AbstractCellStore:

    DEFINE PRIVATE VARIABLE mTable  AS HANDLE NO-UNDO.
    DEFINE PRIVATE VARIABLE mBuffer AS HANDLE NO-UNDO.
    DEFINE PRIVATE VARIABLE mFields AS HANDLE NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mRows   AS MEMPTR NO-UNDO.
    DEFINE PRIVATE VARIABLE mIdLen  AS INTEGER NO-UNDO.

    CONSTRUCTOR PUBLIC TableStore(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT pcLayers AS CHARACTER):
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE hX AS HANDLE  NO-UNDO.
        DEFINE VARIABLE hY AS HANDLE  NO-UNDO.

        SUPER(piWidth, piHeight, pcLayers).
        IF mCells > 100000 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("TableStore holds at most 100000 cells, not &1. Use ArrayStore or SparseStore.", mCells)).

        CREATE TEMP-TABLE mTable.
        mTable:ADD-NEW-FIELD("x", "INTEGER").
        mTable:ADD-NEW-FIELD("y", "INTEGER").
        DO i = 1 TO mLayerCount:
            mTable:ADD-NEW-FIELD(LayerName(i), "INTEGER", 0, ?, 0).
        END.
        mTable:ADD-NEW-INDEX("ixcell", TRUE, TRUE).
        mTable:ADD-INDEX-FIELD("ixcell", "x").
        mTable:ADD-INDEX-FIELD("ixcell", "y").
        mTable:TEMP-TABLE-PREPARE("cells").
        mBuffer = mTable:DEFAULT-BUFFER-HANDLE.

        EXTENT(mFields) = mLayerCount.
        DO i = 1 TO mLayerCount:
            mFields[i] = mBuffer:BUFFER-FIELD(LayerName(i)).
        END.

        hX = mBuffer:BUFFER-FIELD("x").
        hY = mBuffer:BUFFER-FIELD("y").
        DO i = 0 TO mCells - 1:
            mBuffer:BUFFER-CREATE().
            hX:BUFFER-VALUE = i MODULO mWidth.
            hY:BUFFER-VALUE = TRUNCATE(i / mWidth, 0).
            IF i = 0 THEN DO:
                mIdLen = LENGTH(STRING(mBuffer:ROWID)).
                SET-SIZE(mRows) = mCells * mIdLen.
            END.
            IF LENGTH(STRING(mBuffer:ROWID)) <> mIdLen THEN
                UNDO, THROW NEW GridException("Temp table row ids are not a fixed width").
            PUT-STRING(mRows, i * mIdLen + 1, mIdLen) = STRING(mBuffer:ROWID).
        END.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC TableStore():
        SET-SIZE(mRows) = 0.
        IF VALID-HANDLE(mTable) THEN DELETE OBJECT mTable.
    END DESTRUCTOR.

    /* The buffer of the underlying temp table, for queries and debugging. Read only use:
       do not create or delete records, and do not change x or y. */
    METHOD PUBLIC HANDLE BufferHandle():
        RETURN mBuffer.
    END METHOD.

    METHOD PUBLIC OVERRIDE INTEGER GetCell(INPUT piLayer AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= mWidth OR piY < 0 OR piY >= mHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 grid", piX, piY, mWidth, mHeight)).
        RETURN GetCellAt(piLayer, piY * mWidth + piX).
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID SetCell(INPUT piLayer AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piValue AS INTEGER):
        IF piX < 0 OR piX >= mWidth OR piY < 0 OR piY >= mHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 grid", piX, piY, mWidth, mHeight)).
        SetCellAt(piLayer, piY * mWidth + piX, piValue).
    END METHOD.

    METHOD PUBLIC OVERRIDE INTEGER GetCellAt(INPUT piLayer AS INTEGER, INPUT piIndex AS INTEGER):
        IF piLayer < 1 OR piLayer > mLayerCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Layer &1 is outside 1 to &2", piLayer, mLayerCount)).
        IF piIndex < 0 OR piIndex >= mCells THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell index &1 is outside 0 to &2", piIndex, mCells - 1)).
        mBuffer:FIND-BY-ROWID(TO-ROWID(GET-STRING(mRows, piIndex * mIdLen + 1, mIdLen))).
        RETURN mFields[piLayer]:BUFFER-VALUE.
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID SetCellAt(INPUT piLayer AS INTEGER, INPUT piIndex AS INTEGER, INPUT piValue AS INTEGER):
        IF piLayer < 1 OR piLayer > mLayerCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Layer &1 is outside 1 to &2", piLayer, mLayerCount)).
        IF piIndex < 0 OR piIndex >= mCells THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell index &1 is outside 0 to &2", piIndex, mCells - 1)).
        mBuffer:FIND-BY-ROWID(TO-ROWID(GET-STRING(mRows, piIndex * mIdLen + 1, mIdLen))).
        mFields[piLayer]:BUFFER-VALUE = piValue.
    END METHOD.

    METHOD PUBLIC OVERRIDE ICellStore Duplicate():
        DEFINE VARIABLE copy AS TableStore NO-UNDO.
        copy = NEW TableStore(mWidth, mHeight, LayerList()).
        copy:CopyFrom(THIS-OBJECT).
        RETURN copy.
    END METHOD.

    /* Deletes the temp table and frees the row id cache. Safe to call more than once. */
    METHOD PUBLIC OVERRIDE VOID Dispose():
        SET-SIZE(mRows) = 0.
        IF VALID-HANDLE(mTable) THEN DELETE OBJECT mTable.
        mTable = ?.
        mBuffer = ?.
    END METHOD.

END CLASS.
