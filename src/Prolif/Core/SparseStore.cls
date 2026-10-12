/* Sparse cell store: a temp table holding only the non-zero cells, one record per
   (layer, cell index). A cell set to 0 has its record deleted, so the table size follows
   the number of occupied cells and counting or scanning live cells costs time in
   proportion to them, not to the board size. Best when under about 10 to 15 percent of
   the cells are occupied (see the Phase 0 benchmark in the README). */
USING Progress.Lang.*.
USING Prolif.Core.AbstractCellStore.
USING Prolif.Core.GridException.
USING Prolif.Core.ICellStore.
USING Prolif.Core.SparseStore.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.SparseStore FINAL INHERITS AbstractCellStore:

    DEFINE PROTECTED TEMP-TABLE ttCell NO-UNDO
        FIELD layerNo  AS INTEGER
        FIELD cellIdx  AS INTEGER
        FIELD cellVal  AS INTEGER
        INDEX ixCell IS PRIMARY UNIQUE layerNo cellIdx
        INDEX ixVal layerNo cellVal.

    CONSTRUCTOR PUBLIC SparseStore(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT pcLayers AS CHARACTER):
        SUPER(piWidth, piHeight, pcLayers).
    END CONSTRUCTOR.

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
        FIND ttCell WHERE ttCell.layerNo = piLayer AND ttCell.cellIdx = piIndex NO-ERROR.
        IF AVAILABLE ttCell THEN RETURN ttCell.cellVal.
        RETURN 0.
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID SetCellAt(INPUT piLayer AS INTEGER, INPUT piIndex AS INTEGER, INPUT piValue AS INTEGER):
        IF piLayer < 1 OR piLayer > mLayerCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Layer &1 is outside 1 to &2", piLayer, mLayerCount)).
        IF piIndex < 0 OR piIndex >= mCells THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell index &1 is outside 0 to &2", piIndex, mCells - 1)).
        FIND ttCell WHERE ttCell.layerNo = piLayer AND ttCell.cellIdx = piIndex NO-ERROR.
        IF piValue = 0 THEN DO:
            IF AVAILABLE ttCell THEN DELETE ttCell.
        END.
        ELSE DO:
            IF NOT AVAILABLE ttCell THEN DO:
                CREATE ttCell.
                ASSIGN ttCell.layerNo = piLayer
                       ttCell.cellIdx = piIndex.
            END.
            ttCell.cellVal = piValue.
        END.
    END METHOD.

    /* Number of stored (non-zero) cells across all layers. */
    METHOD PUBLIC INTEGER OccupiedCount():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        FOR EACH ttCell:
            n = n + 1.
        END.
        RETURN n.
    END METHOD.

    METHOD PUBLIC OVERRIDE LOGICAL IsEmpty():
        RETURN NOT CAN-FIND(FIRST ttCell).
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID FillLayer(INPUT piLayer AS INTEGER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        FOR EACH ttCell WHERE ttCell.layerNo = piLayer:
            DELETE ttCell.
        END.
        IF piValue <> 0 THEN DO:
            DO i = 0 TO mCells - 1:
                CREATE ttCell.
                ASSIGN ttCell.layerNo = piLayer
                       ttCell.cellIdx = i
                       ttCell.cellVal = piValue.
            END.
        END.
    END METHOD.

    METHOD PUBLIC OVERRIDE INTEGER CountOf(INPUT piLayer AS INTEGER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        IF piValue = 0 THEN DO:
            FOR EACH ttCell WHERE ttCell.layerNo = piLayer:
                n = n + 1.
            END.
            RETURN mCells - n.
        END.
        FOR EACH ttCell WHERE ttCell.layerNo = piLayer AND ttCell.cellVal = piValue:
            n = n + 1.
        END.
        RETURN n.
    END METHOD.

    METHOD PUBLIC OVERRIDE ICellStore Duplicate():
        DEFINE VARIABLE copy AS SparseStore NO-UNDO.
        copy = NEW SparseStore(mWidth, mHeight, LayerList()).
        copy:CopyFrom(THIS-OBJECT).
        RETURN copy.
    END METHOD.

    /* Copies the whole table in one step when the source is also a SparseStore. */
    METHOD PUBLIC OVERRIDE VOID CopyFrom(INPUT poSource AS ICellStore):
        CheckCompatible(poSource).
        IF poSource = THIS-OBJECT THEN RETURN.
        IF TYPE-OF(poSource, SparseStore) THEN
            CAST(poSource, SparseStore):ExportCells(OUTPUT TABLE ttCell).
        ELSE DO:
            EMPTY TEMP-TABLE ttCell.
            SUPER:CopyFrom(poSource).
        END.
    END METHOD.

    /* Internal: hands the table to the caller. Used by CopyFrom. */
    METHOD PUBLIC VOID ExportCells(OUTPUT TABLE ttCell):
    END METHOD.

    /* Empties the table. Safe to call more than once. */
    METHOD PUBLIC OVERRIDE VOID Dispose():
        EMPTY TEMP-TABLE ttCell.
    END METHOD.

END CLASS.
