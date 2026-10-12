/* Dense cell store. All layers live in one MEMPTR of 4 byte integers, layer after layer,
   so cell (layer, x, y) is at byte ((layer - 1) * cells + y * width + x) * 4 + 1.
   A MEMPTR is used because a dynamic extent array is limited to 28,000 elements here.
   No object is allocated when a cell is read or written.

   The MEMPTR is freed by Dispose, and by the destructor as a safety net. Do not use a
   store after Dispose. */
USING Progress.Lang.*.
USING Prolif.Core.AbstractCellStore.
USING Prolif.Core.ArrayStore.
USING Prolif.Core.GridException.
USING Prolif.Core.ICellStore.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.ArrayStore FINAL INHERITS AbstractCellStore:

    DEFINE PRIVATE VARIABLE mMem AS MEMPTR NO-UNDO.

    CONSTRUCTOR PUBLIC ArrayStore(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT pcLayers AS CHARACTER):
        SUPER(piWidth, piHeight, pcLayers).
        IF INT64(mCells) * mLayerCount * 4 >= 2147483647 THEN
            UNDO, THROW NEW GridException("Store needs more than 2 GB of memory").
        SET-SIZE(mMem) = mCells * mLayerCount * 4.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC ArrayStore():
        SET-SIZE(mMem) = 0.
    END DESTRUCTOR.

    METHOD PUBLIC OVERRIDE INTEGER GetCell(INPUT piLayer AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piLayer < 1 OR piLayer > mLayerCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Layer &1 is outside 1 to &2", piLayer, mLayerCount)).
        IF piX < 0 OR piX >= mWidth OR piY < 0 OR piY >= mHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 grid", piX, piY, mWidth, mHeight)).
        RETURN GET-LONG(mMem, ((piLayer - 1) * mCells + piY * mWidth + piX) * 4 + 1).
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID SetCell(INPUT piLayer AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piValue AS INTEGER):
        IF piLayer < 1 OR piLayer > mLayerCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Layer &1 is outside 1 to &2", piLayer, mLayerCount)).
        IF piX < 0 OR piX >= mWidth OR piY < 0 OR piY >= mHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 grid", piX, piY, mWidth, mHeight)).
        PUT-LONG(mMem, ((piLayer - 1) * mCells + piY * mWidth + piX) * 4 + 1) = piValue.
    END METHOD.

    METHOD PUBLIC OVERRIDE INTEGER GetCellAt(INPUT piLayer AS INTEGER, INPUT piIndex AS INTEGER):
        IF piLayer < 1 OR piLayer > mLayerCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Layer &1 is outside 1 to &2", piLayer, mLayerCount)).
        IF piIndex < 0 OR piIndex >= mCells THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell index &1 is outside 0 to &2", piIndex, mCells - 1)).
        RETURN GET-LONG(mMem, ((piLayer - 1) * mCells + piIndex) * 4 + 1).
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID SetCellAt(INPUT piLayer AS INTEGER, INPUT piIndex AS INTEGER, INPUT piValue AS INTEGER):
        IF piLayer < 1 OR piLayer > mLayerCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Layer &1 is outside 1 to &2", piLayer, mLayerCount)).
        IF piIndex < 0 OR piIndex >= mCells THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell index &1 is outside 0 to &2", piIndex, mCells - 1)).
        PUT-LONG(mMem, ((piLayer - 1) * mCells + piIndex) * 4 + 1) = piValue.
    END METHOD.

    METHOD PUBLIC OVERRIDE LOGICAL IsEmpty():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO mCells * mLayerCount - 1:
            IF GET-LONG(mMem, i * 4 + 1) <> 0 THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID FillLayer(INPUT piLayer AS INTEGER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE base AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        base = (piLayer - 1) * mCells.
        DO i = 0 TO mCells - 1:
            PUT-LONG(mMem, (base + i) * 4 + 1) = piValue.
        END.
    END METHOD.

    METHOD PUBLIC OVERRIDE INTEGER CountOf(INPUT piLayer AS INTEGER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE base AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        base = (piLayer - 1) * mCells.
        DO i = 0 TO mCells - 1:
            IF GET-LONG(mMem, (base + i) * 4 + 1) = piValue THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    METHOD PUBLIC OVERRIDE ICellStore Duplicate():
        DEFINE VARIABLE copy AS ArrayStore NO-UNDO.
        copy = NEW ArrayStore(mWidth, mHeight, LayerList()).
        copy:CopyFrom(THIS-OBJECT).
        RETURN copy.
    END METHOD.

    /* Copies in one block when the source is also an ArrayStore, cell by cell otherwise. */
    METHOD PUBLIC OVERRIDE VOID CopyFrom(INPUT poSource AS ICellStore):
        CheckCompatible(poSource).
        IF TYPE-OF(poSource, ArrayStore) THEN
            CAST(poSource, ArrayStore):CopyBytesTo(mMem).
        ELSE
            SUPER:CopyFrom(poSource).
    END METHOD.

    /* Internal: writes this store's raw bytes into a MEMPTR of the same size. The MEMPTR is
       passed by reference, so the caller sees the bytes. Used by CopyFrom. */
    METHOD PUBLIC VOID CopyBytesTo(INPUT pmTarget AS MEMPTR):
        IF GET-SIZE(pmTarget) <> GET-SIZE(mMem) THEN
            UNDO, THROW NEW GridException("Target memory size differs").
        COPY-LOB FROM mMem FOR GET-SIZE(mMem) TO pmTarget OVERLAY AT 1.
    END METHOD.

    /* Frees the memory. Safe to call more than once. */
    METHOD PUBLIC OVERRIDE VOID Dispose():
        SET-SIZE(mMem) = 0.
    END METHOD.

END CLASS.
