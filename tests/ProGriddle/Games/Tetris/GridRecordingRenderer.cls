/* Test double: a renderer that remembers the grid it was last asked to draw and how often it was asked. Not a test class
   itself (the name does not end in Tests). */
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.GridRecordingRenderer IMPLEMENTS IGridRenderer:

    DEFINE PUBLIC PROPERTY RenderCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastGrid AS Grid NO-UNDO
        GET.
        PRIVATE SET.

    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        RenderCount = RenderCount + 1.
        LastGrid = poGrid.
    END METHOD.

END CLASS.
