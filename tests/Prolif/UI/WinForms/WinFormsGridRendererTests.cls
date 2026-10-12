USING OpenEdge.Core.*.
USING Prolif.Core.*.
USING Prolif.Engine.*.
USING Prolif.UI.Text.*.
USING Prolif.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.UI.WinForms.WinFormsGridRendererTests:

    @Test.
    METHOD PUBLIC VOID RenderPutsTheNamedLayerIntoTheView():
        DEFINE VARIABLE g    AS Grid NO-UNDO.
        DEFINE VARIABLE v    AS GridView NO-UNDO.
        DEFINE VARIABLE r    AS WinFormsGridRenderer NO-UNDO.
        DEFINE VARIABLE game AS CountingGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(3, 2, "state")).
            g:Store:SetCell(1, 2, 1, 1).
            game = NEW CountingGame(g, 0).
            v = NEW GridView().
            v:SetPalette("000000,FF8000").
            r = NEW WinFormsGridRenderer(v, "state").
            r:Render(g, game).
            Assert:Equals(3, v:Columns).
            Assert:Equals(2, v:Rows).
            Assert:Equals(16744448, v:PixelAt(2, 1)).
            Assert:Equals(0, v:PixelAt(0, 0)).
            FINALLY:
                IF VALID-OBJECT(v) THEN v:ReleaseResources().
                IF VALID-OBJECT(game) THEN game:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AControllerDrivesTheViewThroughTheRenderer():
        DEFINE VARIABLE g     AS Grid NO-UNDO.
        DEFINE VARIABLE v     AS GridView NO-UNDO.
        DEFINE VARIABLE game  AS CountingGame NO-UNDO.
        DEFINE VARIABLE ctrl  AS GameController NO-UNDO.
        DEFINE VARIABLE clock AS FakeClock NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW Grid(NEW ArrayStore(2, 2, "state")).
            game = NEW CountingGame(g, 0).
            v = NEW GridView().
            v:SetPalette("000000,FFFFFF").
            clock = NEW FakeClock().
            /* building the controller draws the starting state straight away */
            ctrl = NEW GameController(game, NEW WinFormsGridRenderer(v, "state"), clock).
            Assert:Equals(2, v:Columns).
            Assert:Equals(0, v:PixelAt(1, 1)).
            g:Store:SetCell(1, 1, 1, 1).
            ctrl:Refresh().
            Assert:Equals(16777215, v:PixelAt(1, 1)).
            FINALLY:
                IF VALID-OBJECT(ctrl) THEN ctrl:Dispose().
                IF VALID-OBJECT(v) THEN v:ReleaseResources().
                IF VALID-OBJECT(game) THEN game:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ItNeedsAView():
        DEFINE VARIABLE v AS GridView NO-UNDO.
        NEW WinFormsGridRenderer(v, "state").
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ItNeedsALayerName():
        DEFINE VARIABLE v AS GridView NO-UNDO.
        v = NEW GridView().
        NEW WinFormsGridRenderer(v, "").
    END METHOD.

END CLASS.
