/* Builds a LifeGame with the store and engine that suit the expected crowding of the board.
   Measured on this install (see README): the dense engine costs about the same on any
   density, roughly 46 ms a generation at 100 x 100 and 310 ms at 300 x 300, while the sparse
   engine costs about 8 to 75 microseconds per live cell. They break even at about 5 percent
   of the cells alive, so sparse is used below that and dense from there upward.

   Rebuild changes the rules and the size of a game that is running, which is how the window
   changes them without starting again. */
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
        DEFINE VARIABLE sparse AS LOGICAL     NO-UNDO.
        DEFINE VARIABLE grid   AS Grid        NO-UNDO.
        DEFINE VARIABLE game   AS LifeGame    NO-UNDO.
        sparse = UsesSparse(pdLiveFraction, poRules).
        grid = BuildGrid(piWidth, piHeight, plWrap, sparse).
        game = NEW LifeGame(grid, poRules, BuildEngine(grid, poRules, sparse)).
        game:ExpectedLive = pdLiveFraction.
        RETURN game.
    END METHOD.

    /* Changes the rules and the size of a running game, keeping its board. The new board starts
       from the live cells of the old one: the same cells in the same places, and any that fall
       outside a smaller board are lost. The wrapping, the expected crowding and the generation
       stay as they were, except that a new size goes back to generation 0, because the start that
       Reset returns to belongs to the old size. The engine is chosen again for the new rules, so
       the board may move between the dense and the sparse engine. Throws GridException for a side
       outside LifeSizes:MinSide to MaxSide, and changes nothing. */
    METHOD PUBLIC STATIC VOID Rebuild(INPUT poGame AS LifeGame, INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT poRules AS LifeRules):
        DEFINE VARIABLE oldGrid  AS Grid   NO-UNDO.
        DEFINE VARIABLE newGrid  AS Grid   NO-UNDO.
        DEFINE VARIABLE sparse   AS LOGICAL NO-UNDO.
        DEFINE VARIABLE sameSize AS LOGICAL NO-UNDO.
        DEFINE VARIABLE x        AS INTEGER NO-UNDO.
        DEFINE VARIABLE y        AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("There is no game to rebuild").
        IF NOT VALID-OBJECT(poRules) THEN UNDO, THROW NEW GridException("A Life game needs rules").
        IF piWidth = ? OR piHeight = ? OR piWidth < LifeSizes:MinSide() OR piWidth > LifeSizes:MaxSide()
           OR piHeight < LifeSizes:MinSide() OR piHeight > LifeSizes:MaxSide() THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A Life board side is &1 to &2 cells", LifeSizes:MinSide(), LifeSizes:MaxSide())).
        oldGrid = poGame:Grid.
        sameSize = (piWidth = oldGrid:Width AND piHeight = oldGrid:Height).
        sparse = UsesSparse(poGame:ExpectedLive, poRules).
        newGrid = BuildGrid(piWidth, piHeight, oldGrid:Topology:Wraps, sparse).
        /* the live cells carry across: every cell that is on both boards */
        DO y = 0 TO MINIMUM(oldGrid:Height, piHeight) - 1:
            DO x = 0 TO MINIMUM(oldGrid:Width, piWidth) - 1:
                IF oldGrid:Store:GetCell(1, x, y) <> 0 THEN newGrid:Store:SetCell(1, x, y, 1).
            END.
        END.
        poGame:Replace(newGrid, poRules, BuildEngine(newGrid, poRules, sparse), sameSize).
    END METHOD.

    METHOD PRIVATE STATIC Grid BuildGrid(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT plWrap AS LOGICAL, INPUT plSparse AS LOGICAL):
        DEFINE VARIABLE store AS ICellStore NO-UNDO.
        DEFINE VARIABLE topo  AS ITopology  NO-UNDO.
        IF plSparse THEN store = NEW SparseStore(piWidth, piHeight, "state").
        ELSE store = NEW ArrayStore(piWidth, piHeight, "state").
        IF plWrap THEN topo = NEW ToroidalTopology().
        ELSE topo = NEW BoundedTopology().
        RETURN NEW Grid(store, topo, NEW MooreNeighbourhood()).
    END METHOD.

    METHOD PRIVATE STATIC ILifeEngine BuildEngine(INPUT poGrid AS Grid, INPUT poRules AS LifeRules, INPUT plSparse AS LOGICAL):
        IF plSparse THEN RETURN NEW SparseLifeEngine(poGrid, poRules).
        RETURN NEW DenseLifeEngine(poGrid, poRules).
    END METHOD.

END CLASS.
