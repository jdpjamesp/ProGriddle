/* Draws a game by handing one layer of its grid to a GridView. The view does the painting. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.WinFormsGridRenderer FINAL IMPLEMENTS IGridRenderer:

    DEFINE PRIVATE VARIABLE mView  AS GridView  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLayer AS CHARACTER NO-UNDO.

    CONSTRUCTOR PUBLIC WinFormsGridRenderer(INPUT poView AS GridView, INPUT pcLayer AS CHARACTER):
        IF NOT VALID-OBJECT(poView) THEN UNDO, THROW NEW GridException("A renderer needs a view").
        IF pcLayer = ? OR pcLayer = "" THEN UNDO, THROW NEW GridException("A renderer needs a layer name").
        mView = poView.
        mLayer = pcLayer.
    END CONSTRUCTOR.

    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        mView:Show(poGrid, mLayer).
    END METHOD.

END CLASS.
