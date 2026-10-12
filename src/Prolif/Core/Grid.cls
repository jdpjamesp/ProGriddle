/* A rectangular board: a width, a height and the cell store that holds its contents.
   Also the single place for index maths. x and y start at 0 and the cell index is
   (y * Width) + x, so a 3 x 5 grid has indexes 0 to 14 and the cell (2, 1) is index 5.
   Topology (what happens at the edges) is added in Phase 2.

   The grid owns its store: Dispose on the grid disposes the store. */
USING Progress.Lang.*.
USING Prolif.Core.Grid.
USING Prolif.Core.GridException.
USING Prolif.Core.ICellStore.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.Grid FINAL:

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

    /* The grid takes its size from the store, so the two can never disagree. */
    CONSTRUCTOR PUBLIC Grid(INPUT poStore AS ICellStore):
        IF NOT VALID-OBJECT(poStore) THEN
            UNDO, THROW NEW GridException("A grid needs a cell store").
        Store = poStore.
        Width = poStore:Width.
        Height = poStore:Height.
        CellCount = Width * Height.
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

    /* New grid with an independent copy of the store. */
    METHOD PUBLIC Grid Duplicate():
        RETURN NEW Grid(Store:Duplicate()).
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
