/* Test double: remembers how often it was asked to draw and the generation it last saw.
   Not a test class itself (the name does not end in Tests). */
USING Prolif.Core.*.
USING Prolif.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Engine.RecordingRenderer IMPLEMENTS IGridRenderer:

    DEFINE PUBLIC PROPERTY RenderCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The generation of the last game drawn, or -1 before the first draw. */
    DEFINE PUBLIC PROPERTY LastGeneration AS INTEGER NO-UNDO INITIAL -1
        GET.
        PRIVATE SET.

    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        RenderCount = RenderCount + 1.
        IF TYPE-OF(poGame, ISteppableGame) THEN
            LastGeneration = CAST(poGame, ISteppableGame):Generation.
    END METHOD.

END CLASS.
