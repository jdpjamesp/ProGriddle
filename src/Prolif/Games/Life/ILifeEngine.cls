/* Computes one generation of Life on a grid, in place. An engine is built for one grid and
   one rule set. Two exist, with identical results: DenseLifeEngine scans every cell and
   suits crowded boards, SparseLifeEngine visits only live cells and suits mostly empty
   ones. The grid's single layer holds 0 for dead and 1 for alive. */
USING Prolif.Games.Life.ILifeEngine.

INTERFACE Prolif.Games.Life.ILifeEngine:

    /* Replaces the grid's cells with the next generation. All cells change together: the new
       state of a cell never depends on the order cells are visited. */
    METHOD PUBLIC VOID Step().

    /* Frees any memory the engine holds. It does not dispose the grid. Safe to call twice. */
    METHOD PUBLIC VOID Dispose().

END INTERFACE.
