/* Draws a game's grid. The seam between game logic and presentation: the WinForms renderer
   paints it, the text renderer turns it into a string for tests. */
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.IGridRenderer:

    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame).

END INTERFACE.
