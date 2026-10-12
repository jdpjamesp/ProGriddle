/* Builds a LifeGame with the store and engine that suit the expected crowding of the board.
   Measured on this install (see README): the dense engine costs about the same on any
   density, roughly 46 ms a generation at 100 x 100 and 310 ms at 300 x 300, while the sparse
   engine costs about 8 to 75 microseconds per live cell. They break even at about 5 percent
   of the cells alive, so sparse is used below that and dense from there upward. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeFactory FINAL:

    /* The live fraction below which the sparse engine is chosen. */
    METHOD PUBLIC STATIC DECIMAL SparseBelow():
        RETURN 0.05.
    END METHOD.

    /* True when a board with this fraction of live cells (0 to 1) suits the sparse engine.
       Rules with a birth on 0 neighbours always need the dense engine. */
    METHOD PUBLIC STATIC LOGICAL UsesSparse(INPUT pdLiveFraction AS DECIMAL, INPUT poRules AS LifeRules):
        IF NOT VALID-OBJECT(poRules) THEN UNDO, THROW NEW GridException("A Life game needs rules").
        IF pdLiveFraction < 0 OR pdLiveFraction > 1 THEN
            UNDO, THROW NEW GridException("The live fraction must be from 0 to 1, not " + STRING(pdLiveFraction)).
        RETURN pdLiveFraction < SparseBelow() AND NOT poRules:Births(0).
    END METHOD.

    /* A new game on an empty board of piWidth x piHeight, bounded or wrapped, with Moore
       neighbours. pdLiveFraction is the expected share of live cells. */
    METHOD PUBLIC STATIC LifeGame Create(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT plWrap AS LOGICAL,
                                         INPUT poRules AS LifeRules, INPUT pdLiveFraction AS DECIMAL):
        DEFINE VARIABLE sparse AS LOGICAL      NO-UNDO.
        DEFINE VARIABLE store  AS ICellStore   NO-UNDO.
        DEFINE VARIABLE topo   AS ITopology    NO-UNDO.
        DEFINE VARIABLE grid   AS Grid         NO-UNDO.
        DEFINE VARIABLE engine AS ILifeEngine  NO-UNDO.

        sparse = UsesSparse(pdLiveFraction, poRules).
        IF sparse THEN store = NEW SparseStore(piWidth, piHeight, "state").
        ELSE store = NEW ArrayStore(piWidth, piHeight, "state").
        IF plWrap THEN topo = NEW ToroidalTopology().
        ELSE topo = NEW BoundedTopology().
        grid = NEW Grid(store, topo, NEW MooreNeighbourhood()).
        IF sparse THEN engine = NEW SparseLifeEngine(grid, poRules).
        ELSE engine = NEW DenseLifeEngine(grid, poRules).
        RETURN NEW LifeGame(grid, poRules, engine).
    END METHOD.

END CLASS.
