/* Renders one layer of a grid as text, for tests and debugging. Each cell becomes one
   character: the character of pcSymbols at position (value + 1), so ".#" draws 0 as "." and
   1 as "#". A value with no symbol draws as "?". Rows are separated by a line feed, with no
   trailing one. The last result is kept in LastOutput. */
USING Progress.Lang.*.
USING Prolif.Core.Grid.
USING Prolif.Core.GridException.
USING Prolif.Engine.IGame.
USING Prolif.Engine.IGridRenderer.
USING Prolif.UI.Text.TextGridRenderer.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.UI.Text.TextGridRenderer FINAL IMPLEMENTS IGridRenderer:

    DEFINE PRIVATE VARIABLE mLayer   AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSymbols AS CHARACTER NO-UNDO.

    DEFINE PUBLIC PROPERTY LastOutput AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    /* Number of times Render has been called. */
    DEFINE PUBLIC PROPERTY RenderCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC TextGridRenderer(INPUT pcLayer AS CHARACTER, INPUT pcSymbols AS CHARACTER):
        IF pcLayer = ? OR pcLayer = "" THEN
            UNDO, THROW NEW GridException("A text renderer needs a layer name").
        IF pcSymbols = ? OR pcSymbols = "" THEN
            UNDO, THROW NEW GridException("A text renderer needs at least one symbol").
        mLayer = pcLayer.
        mSymbols = pcSymbols.
    END CONSTRUCTOR.

    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        LastOutput = ToText(poGrid).
        RenderCount = RenderCount + 1.
    END METHOD.

    /* The grid as text without recording it. */
    METHOD PUBLIC CHARACTER ToText(INPUT poGrid AS Grid):
        DEFINE VARIABLE layer  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE v      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        IF NOT VALID-OBJECT(poGrid) THEN
            UNDO, THROW NEW GridException("Nothing to render: the grid is not valid").
        layer = poGrid:Store:LayerIndex(mLayer).
        DO y = 0 TO poGrid:Height - 1:
            IF y > 0 THEN result = result + CHR(10).
            DO x = 0 TO poGrid:Width - 1:
                v = poGrid:Store:GetCellAt(layer, y * poGrid:Width + x).
                result = result + (IF v >= 0 AND v < LENGTH(mSymbols) THEN SUBSTRING(mSymbols, v + 1, 1) ELSE "?").
            END.
        END.
        RETURN result.
    END METHOD.

END CLASS.
