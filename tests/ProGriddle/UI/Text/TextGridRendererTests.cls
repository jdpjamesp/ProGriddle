USING OpenEdge.Core.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.Text.TextGridRendererTests:

    @Test.
    METHOD PUBLIC VOID DrawsEachCellAsOneSymbolWithRowsOnSeparateLines():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE r AS TextGridRenderer NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(4, 3, "state")).
            g:Store:SetCell(1, 0, 0, 1).
            g:Store:SetCell(1, 3, 1, 1).
            g:Store:SetCell(1, 1, 2, 1).
            r = NEW TextGridRenderer("state", ".#").
            Assert:Equals("#..." + CHR(10) + "...#" + CHR(10) + ".#..", r:ToText(g)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ValuesWithoutASymbolDrawAsAQuestionMark():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DEFINE VARIABLE r AS TextGridRenderer NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 1, "state")).
            g:Store:SetCell(1, 0, 0, 2).
            g:Store:SetCell(1, 1, 0, -1).
            r = NEW TextGridRenderer("state", ".#").
            Assert:Equals("??.", r:ToText(g)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawsTheNamedLayerOnly():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(2, 1, "mine,flag")).
            g:Store:SetCell(1, 0, 0, 1).
            g:Store:SetCell(2, 1, 0, 1).
            Assert:Equals("*.", NEW TextGridRenderer("mine", ".*"):ToText(g)).
            Assert:Equals(".F", NEW TextGridRenderer("flag", ".F"):ToText(g)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WorksWithAnyStoreKind():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW SparseStore(3, 2, "state")).
            g:Store:SetCell(1, 2, 1, 1).
            Assert:Equals("..." + CHR(10) + "..#", NEW TextGridRenderer("state", ".#"):ToText(g)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RenderRecordsTheOutputAndCountsTheCalls():
        DEFINE VARIABLE g    AS Grid NO-UNDO.
        DEFINE VARIABLE game AS CountingGame NO-UNDO.
        DEFINE VARIABLE r    AS TextGridRenderer NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(2, 2, "state")).
            game = NEW CountingGame(g, 0).
            r = NEW TextGridRenderer("state", ".#").
            Assert:Equals(0, r:RenderCount).
            r:Render(g, game).
            Assert:Equals("..", ENTRY(1, r:LastOutput, CHR(10))).
            Assert:Equals(1, r:RenderCount).
            g:Store:SetCell(1, 0, 0, 1).
            r:Render(g, game).
            Assert:Equals("#." + CHR(10) + "..", r:LastOutput).
            Assert:Equals(2, r:RenderCount).
            FINALLY:
                IF VALID-OBJECT(game) THEN game:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ToTextThrowsForAnUnknownLayer():
        DEFINE VARIABLE g AS Grid NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(2, 2, "state")).
            NEW TextGridRenderer("nope", ".#"):ToText(g).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutSymbols():
        NEW TextGridRenderer("state", "").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutALayerName():
        NEW TextGridRenderer("", ".#").
    END METHOD.

END CLASS.
