/* Helpers shared by the Life tests. Not a test class itself (the name does not end in Tests).
   Engine kinds: 1 is the dense engine on an ArrayStore, 2 is the sparse engine on a
   SparseStore. */
USING Progress.Lang.*.
USING Prolif.Core.ArrayStore.
USING Prolif.Core.BoundedTopology.
USING Prolif.Core.Grid.
USING Prolif.Core.ICellStore.
USING Prolif.Core.ITopology.
USING Prolif.Core.MooreNeighbourhood.
USING Prolif.Core.SparseStore.
USING Prolif.Core.ToroidalTopology.
USING Prolif.Games.Life.DenseLifeEngine.
USING Prolif.Games.Life.ILifeEngine.
USING Prolif.Games.Life.LifeGame.
USING Prolif.Games.Life.LifeRules.
USING Prolif.Games.Life.LifeTestKit.
USING Prolif.Games.Life.SparseLifeEngine.
USING Prolif.UI.Text.TextGridRenderer.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Games.Life.LifeTestKit FINAL:

    METHOD PUBLIC STATIC INTEGER KindCount():
        RETURN 2.
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER KindName(INPUT piKind AS INTEGER):
        RETURN (IF piKind = 1 THEN "DenseLifeEngine" ELSE "SparseLifeEngine").
    END METHOD.

    /* A game on an empty board of the given size, with the engine of the given kind. */
    METHOD PUBLIC STATIC LifeGame Make(INPUT piKind AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER,
                                       INPUT plWrap AS LOGICAL, INPUT poRules AS LifeRules):
        DEFINE VARIABLE store  AS ICellStore  NO-UNDO.
        DEFINE VARIABLE topo   AS ITopology   NO-UNDO.
        DEFINE VARIABLE grid   AS Grid        NO-UNDO.
        DEFINE VARIABLE engine AS ILifeEngine NO-UNDO.
        IF piKind = 1 THEN store = NEW ArrayStore(piW, piH, "state").
        ELSE store = NEW SparseStore(piW, piH, "state").
        IF plWrap THEN topo = NEW ToroidalTopology().
        ELSE topo = NEW BoundedTopology().
        grid = NEW Grid(store, topo, NEW MooreNeighbourhood()).
        IF piKind = 1 THEN engine = NEW DenseLifeEngine(grid, poRules).
        ELSE engine = NEW SparseLifeEngine(grid, poRules).
        RETURN NEW LifeGame(grid, poRules, engine).
    END METHOD.

    /* The board as text, "#" alive and "." dead, rows on separate lines. */
    METHOD PUBLIC STATIC CHARACTER Board(INPUT poGame AS LifeGame):
        RETURN NEW TextGridRenderer("state", ".#"):ToText(poGame:Grid).
    END METHOD.

    /* The next generation worked out the slow, obvious way from the current board, without
       using either engine: resolve each offset through the topology, drop missing cells, the
       cell itself and repeats, count the live ones and apply the rules. */
    METHOD PUBLIC STATIC CHARACTER Reference(INPUT poGame AS LifeGame):
        DEFINE VARIABLE g      AS Grid      NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE r      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE idx    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE seen   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cnt    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        g = poGame:Grid.
        DO y = 0 TO g:Height - 1:
            IF y > 0 THEN result = result + CHR(10).
            DO x = 0 TO g:Width - 1:
                idx = y * g:Width + x.
                seen = "".
                cnt = 0.
                DO k = 1 TO g:Neighbourhood:OffsetCount:
                    r = g:Resolve(x + g:Neighbourhood:OffsetX(k), y + g:Neighbourhood:OffsetY(k)).
                    IF r = ? THEN NEXT.
                    IF r = idx THEN NEXT.
                    IF LOOKUP(STRING(r), seen) > 0 THEN NEXT.
                    seen = seen + (IF seen = "" THEN "" ELSE ",") + STRING(r).
                    IF g:Store:GetCellAt(1, r) <> 0 THEN cnt = cnt + 1.
                END.
                result = result + (IF poGame:Rules:NextState(g:Store:GetCellAt(1, idx), cnt) = 1 THEN "#" ELSE ".").
            END.
        END.
        RETURN result.
    END METHOD.

    /* Adds the engine kind to an error so a failure says which engine broke. */
    METHOD PUBLIC STATIC VOID Rethrow(INPUT piKind AS INTEGER, INPUT poError AS Progress.Lang.Error):
        UNDO, THROW NEW AppError(SUBSTITUTE("[&1] &2", KindName(piKind), poError:GetMessage(1)), 0).
    END METHOD.

END CLASS.
