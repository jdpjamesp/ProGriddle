/* An optional extra for a game input: the game wants to know about every cell the mouse passes over while the
   left button is held down, so a click and drag can paint a line of cells instead of needing a click on each one
   (Life). A game input that also implements this interface is told by the window; a game that does not is
   unchanged, and still sees only the click when the button comes up.

   The window calls DragAction once for the cell the drag started on, as soon as the pointer moves to another
   cell, and then once for each cell after that, in order. Cells the pointer jumped over (a fast drag) are filled
   in with a straight line, so none are missed (see CellPath). A drag that goes off the board is paused until it
   comes back. A drag is not also a click: PrimaryAction is not called when the button comes up. Only the left
   button on its own drags. */
USING Progress.Lang.*.
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.IDragInput:

    /* The pointer, with the left button down, is over the cell piX, piY. */
    METHOD PUBLIC VOID DragAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER).

END INTERFACE.
