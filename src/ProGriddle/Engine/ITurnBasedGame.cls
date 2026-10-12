/* A game that only changes when the player makes a move, such as Minesweeper. The moves
   themselves are game specific (reveal, flag, fire), so the game offers them as its own
   methods and the window reaches them through IGameInput. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.ITurnBasedGame INHERITS IGame:

    /* Number of moves that have changed the game since Initialise. */
    DEFINE PUBLIC PROPERTY Turn AS INTEGER NO-UNDO
        GET.

END INTERFACE.
