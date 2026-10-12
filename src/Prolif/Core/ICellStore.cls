/* Storage contract for the cells of a grid. A store holds one or more named integer
   layers over a width x height board. Three implementations exist: ArrayStore (dense),
   TableStore (named fields, small boards) and SparseStore (occupied cells only). They
   are interchangeable: the same contract tests run against all of them.

   Conventions
   - x and y start at 0. Cell index = (y * Width) + x, from 0 to Width * Height - 1.
   - Layers are numbered from 1 in the order they were declared. Resolve a name once
     with LayerIndex and use the number in loops.
   - Every layer starts at 0 and 0 means empty. Cell meaning is defined by the game.
   - Any x, y, index or layer outside its range throws GridException.
   - Dispose releases memory or tables. Call it when the store is no longer needed. */
USING Prolif.Core.ICellStore.
USING Prolif.Core.Shape.

INTERFACE Prolif.Core.ICellStore:

    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET.

    DEFINE PUBLIC PROPERTY LayerCount AS INTEGER NO-UNDO
        GET.

    /* Number of the layer with this name, case insensitive. Throws GridException when unknown. */
    METHOD PUBLIC INTEGER LayerIndex(INPUT pcName AS CHARACTER).

    /* Name of layer piLayer as it was declared. */
    METHOD PUBLIC CHARACTER LayerName(INPUT piLayer AS INTEGER).

    METHOD PUBLIC INTEGER GetCell(INPUT piLayer AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER).

    METHOD PUBLIC VOID SetCell(INPUT piLayer AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piValue AS INTEGER).

    METHOD PUBLIC INTEGER GetCellAt(INPUT piLayer AS INTEGER, INPUT piIndex AS INTEGER).

    METHOD PUBLIC VOID SetCellAt(INPUT piLayer AS INTEGER, INPUT piIndex AS INTEGER, INPUT piValue AS INTEGER).

    /* True when every cell of every layer is 0. */
    METHOD PUBLIC LOGICAL IsEmpty().

    /* Sets every cell of one layer to piValue. */
    METHOD PUBLIC VOID FillLayer(INPUT piLayer AS INTEGER, INPUT piValue AS INTEGER).

    /* Number of cells in one layer that hold piValue. */
    METHOD PUBLIC INTEGER CountOf(INPUT piLayer AS INTEGER, INPUT piValue AS INTEGER).

    /* Independent copy of this store, same type, size, layers and contents. (Not called
       Clone, because every ABL object already inherits a Clone method.) */
    METHOD PUBLIC ICellStore Duplicate().

    /* Copies every cell from another store with the same size and layers. Throws
       GridException when the size or the layer names differ. */
    METHOD PUBLIC VOID CopyFrom(INPUT poSource AS ICellStore).

    /* True when the shape, placed with its top left corner at piX, piY, lies fully on the
       board and every cell it covers is 0 in this layer. */
    METHOD PUBLIC LOGICAL CanPlace(INPUT piLayer AS INTEGER, INPUT poShape AS Shape, INPUT piX AS INTEGER, INPUT piY AS INTEGER).

    /* Writes piValue into every cell the shape covers. Throws GridException, and writes
       nothing, when any covered cell is off the board. Does not check for collisions. */
    METHOD PUBLIC VOID Stamp(INPUT piLayer AS INTEGER, INPUT poShape AS Shape, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piValue AS INTEGER).

    /* Same as Stamp with the value 0. */
    METHOD PUBLIC VOID Erase(INPUT piLayer AS INTEGER, INPUT poShape AS Shape, INPUT piX AS INTEGER, INPUT piY AS INTEGER).

    /* True when no cell in row piY of the layer is 0. */
    METHOD PUBLIC LOGICAL IsRowFull(INPUT piLayer AS INTEGER, INPUT piY AS INTEGER).

    /* Sets every cell in row piY of the layer to 0. */
    METHOD PUBLIC VOID ClearRow(INPUT piLayer AS INTEGER, INPUT piY AS INTEGER).

    /* Removes row piY from the layer: rows 0 to piY - 1 each move down one row, the old
       row piY is lost and row 0 becomes empty. Used after a Tetris line clear. */
    METHOD PUBLIC VOID ShiftRowsDown(INPUT piLayer AS INTEGER, INPUT piY AS INTEGER).

    METHOD PUBLIC VOID Dispose().

END INTERFACE.
