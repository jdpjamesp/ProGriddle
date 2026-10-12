/* Shared plumbing for the cell stores: size and layer validation, and generic
   implementations of the whole store, shape and row operations written in terms of
   GetCellAt and SetCellAt. A store overrides any of them when it has a faster way.
   Concrete stores implement the four cell accessors, Duplicate and Dispose.
   (Not called Clone, because every ABL object already inherits a Clone method.) */
USING Progress.Lang.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.AbstractCellStore ABSTRACT IMPLEMENTS ICellStore:

    DEFINE PROTECTED VARIABLE mWidth      AS INTEGER   NO-UNDO.
    DEFINE PROTECTED VARIABLE mHeight     AS INTEGER   NO-UNDO.
    DEFINE PROTECTED VARIABLE mCells      AS INTEGER   NO-UNDO.
    DEFINE PROTECTED VARIABLE mLayerCount AS INTEGER   NO-UNDO.
    DEFINE PRIVATE   VARIABLE mLayerNames AS CHARACTER NO-UNDO EXTENT.

    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET():
            RETURN mWidth.
        END GET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET():
            RETURN mHeight.
        END GET.

    DEFINE PUBLIC PROPERTY LayerCount AS INTEGER NO-UNDO
        GET():
            RETURN mLayerCount.
        END GET.

    /* piWidth and piHeight must be at least 1. pcLayers is a comma separated list of layer
       names: letters, digits and underscores, starting with a letter, unique ignoring case.
       The names "x" and "y" are reserved because TableStore uses them for coordinates. */
    CONSTRUCTOR PROTECTED AbstractCellStore(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT pcLayers AS CHARACTER):
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE c    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE name AS CHARACTER NO-UNDO.
        DEFINE VARIABLE ch   AS CHARACTER NO-UNDO.

        IF piWidth < 1 OR piHeight < 1 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Grid size must be at least 1 x 1, not &1 x &2", piWidth, piHeight)).
        IF INT64(piWidth) * piHeight > 50000000 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Grid of &1 x &2 cells is too large", piWidth, piHeight)).
        IF pcLayers = ? OR TRIM(pcLayers) = "" THEN
            UNDO, THROW NEW GridException("A cell store needs at least one layer").

        mLayerCount = NUM-ENTRIES(pcLayers).
        EXTENT(mLayerNames) = mLayerCount.
        DO i = 1 TO mLayerCount:
            name = TRIM(ENTRY(i, pcLayers)).
            IF name = "" THEN
                UNDO, THROW NEW GridException("Layer names must not be empty: " + pcLayers).
            DO c = 1 TO LENGTH(name):
                ch = SUBSTRING(name, c, 1).
                IF NOT ((ch >= "a" AND ch <= "z") OR (ch >= "A" AND ch <= "Z")
                        OR (c > 1 AND ((ch >= "0" AND ch <= "9") OR ch = "_"))) THEN
                    UNDO, THROW NEW GridException("Invalid layer name: " + name).
            END.
            IF name = "x" OR name = "y" THEN
                UNDO, THROW NEW GridException(SUBSTITUTE("Layer name '&1' is reserved", name)).
            DO j = 1 TO i - 1:
                IF mLayerNames[j] = name THEN
                    UNDO, THROW NEW GridException("Duplicate layer name: " + name).
            END.
            mLayerNames[i] = name.
        END.

        mWidth  = piWidth.
        mHeight = piHeight.
        mCells  = piWidth * piHeight.
    END CONSTRUCTOR.

    METHOD PUBLIC INTEGER LayerIndex(INPUT pcName AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mLayerCount:
            IF mLayerNames[i] = pcName THEN RETURN i.
        END.
        UNDO, THROW NEW GridException("Unknown layer: " + STRING(pcName)).
    END METHOD.

    METHOD PUBLIC CHARACTER LayerName(INPUT piLayer AS INTEGER):
        ValidateLayer(piLayer).
        RETURN mLayerNames[piLayer].
    END METHOD.

    METHOD PUBLIC ABSTRACT INTEGER GetCell(INPUT piLayer AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER).

    METHOD PUBLIC ABSTRACT VOID SetCell(INPUT piLayer AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piValue AS INTEGER).

    METHOD PUBLIC ABSTRACT INTEGER GetCellAt(INPUT piLayer AS INTEGER, INPUT piIndex AS INTEGER).

    METHOD PUBLIC ABSTRACT VOID SetCellAt(INPUT piLayer AS INTEGER, INPUT piIndex AS INTEGER, INPUT piValue AS INTEGER).

    METHOD PUBLIC ABSTRACT ICellStore Duplicate().

    METHOD PUBLIC ABSTRACT VOID Dispose().

    METHOD PUBLIC LOGICAL IsEmpty():
        DEFINE VARIABLE l AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO l = 1 TO mLayerCount:
            DO i = 0 TO mCells - 1:
                IF GetCellAt(l, i) <> 0 THEN RETURN FALSE.
            END.
        END.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC VOID FillLayer(INPUT piLayer AS INTEGER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        DO i = 0 TO mCells - 1:
            SetCellAt(piLayer, i, piValue).
        END.
    END METHOD.

    METHOD PUBLIC INTEGER CountOf(INPUT piLayer AS INTEGER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        DO i = 0 TO mCells - 1:
            IF GetCellAt(piLayer, i) = piValue THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    METHOD PUBLIC VOID CopyFrom(INPUT poSource AS ICellStore):
        DEFINE VARIABLE l AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        CheckCompatible(poSource).
        DO l = 1 TO mLayerCount:
            DO i = 0 TO mCells - 1:
                SetCellAt(l, i, poSource:GetCellAt(l, i)).
            END.
        END.
    END METHOD.

    METHOD PUBLIC LOGICAL CanPlace(INPUT piLayer AS INTEGER, INPUT poShape AS Shape, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE gx AS INTEGER NO-UNDO.
        DEFINE VARIABLE gy AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        ValidateShape(poShape).
        DO i = 1 TO poShape:Size:
            gx = piX + poShape:OffsetX(i).
            gy = piY + poShape:OffsetY(i).
            IF gx < 0 OR gx >= mWidth OR gy < 0 OR gy >= mHeight THEN RETURN FALSE.
            IF GetCellAt(piLayer, gy * mWidth + gx) <> 0 THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC VOID Stamp(INPUT piLayer AS INTEGER, INPUT poShape AS Shape, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piValue AS INTEGER):
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE gx AS INTEGER NO-UNDO.
        DEFINE VARIABLE gy AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        ValidateShape(poShape).
        DO i = 1 TO poShape:Size:
            gx = piX + poShape:OffsetX(i).
            gy = piY + poShape:OffsetY(i).
            IF gx < 0 OR gx >= mWidth OR gy < 0 OR gy >= mHeight THEN
                UNDO, THROW NEW GridException(SUBSTITUTE("Shape cell (&1,&2) is off the &3 x &4 board", gx, gy, mWidth, mHeight)).
        END.
        DO i = 1 TO poShape:Size:
            SetCellAt(piLayer, (piY + poShape:OffsetY(i)) * mWidth + piX + poShape:OffsetX(i), piValue).
        END.
    END METHOD.

    METHOD PUBLIC VOID Erase(INPUT piLayer AS INTEGER, INPUT poShape AS Shape, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        Stamp(piLayer, poShape, piX, piY, 0).
    END METHOD.

    METHOD PUBLIC LOGICAL IsRowFull(INPUT piLayer AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        ValidateRow(piY).
        DO x = 0 TO mWidth - 1:
            IF GetCellAt(piLayer, piY * mWidth + x) = 0 THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC VOID ClearRow(INPUT piLayer AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        ValidateRow(piY).
        DO x = 0 TO mWidth - 1:
            SetCellAt(piLayer, piY * mWidth + x, 0).
        END.
    END METHOD.

    METHOD PUBLIC VOID ShiftRowsDown(INPUT piLayer AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE r AS INTEGER NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        ValidateLayer(piLayer).
        ValidateRow(piY).
        DO r = piY TO 1 BY -1:
            DO x = 0 TO mWidth - 1:
                SetCellAt(piLayer, r * mWidth + x, GetCellAt(piLayer, (r - 1) * mWidth + x)).
            END.
        END.
        ClearRow(piLayer, 0).
    END METHOD.

    /* Throws GridException unless the source has the same size and layer names. */
    METHOD PROTECTED VOID CheckCompatible(INPUT poSource AS ICellStore):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poSource) THEN
            UNDO, THROW NEW GridException("Source store is not valid").
        IF poSource:Width <> mWidth OR poSource:Height <> mHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cannot copy a &1 x &2 store into a &3 x &4 store",
                poSource:Width, poSource:Height, mWidth, mHeight)).
        IF poSource:LayerCount <> mLayerCount THEN
            UNDO, THROW NEW GridException("Cannot copy between stores with different layers").
        DO i = 1 TO mLayerCount:
            IF poSource:LayerName(i) <> mLayerNames[i] THEN
                UNDO, THROW NEW GridException("Cannot copy between stores with different layers").
        END.
    END METHOD.

    /* The comma separated layer names, for building a store of the same shape. */
    METHOD PROTECTED CHARACTER LayerList():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DO i = 1 TO mLayerCount:
            result = result + (IF i > 1 THEN "," ELSE "") + mLayerNames[i].
        END.
        RETURN result.
    END METHOD.

    METHOD PROTECTED VOID ValidateLayer(INPUT piLayer AS INTEGER):
        IF piLayer < 1 OR piLayer > mLayerCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Layer &1 is outside 1 to &2", piLayer, mLayerCount)).
    END METHOD.

    METHOD PROTECTED VOID ValidateRow(INPUT piY AS INTEGER):
        IF piY < 0 OR piY >= mHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Row &1 is outside 0 to &2", piY, mHeight - 1)).
    END METHOD.

    METHOD PROTECTED VOID ValidateShape(INPUT poShape AS Shape):
        IF NOT VALID-OBJECT(poShape) THEN
            UNDO, THROW NEW GridException("Shape is not valid").
    END METHOD.

END CLASS.
