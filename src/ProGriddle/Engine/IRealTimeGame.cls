/* A game that runs against a clock, such as Tetris: pieces fall, things happen whether or not the
   player does anything. The controller feeds it the milliseconds that have gone by and it
   updates itself. The player's moves are the game's own methods (move left, rotate), reached
   through IGameInput, and they, like the clock, do nothing while the game is Paused. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.IRealTimeGame INHERITS IGame:

    /* While true the game ignores the clock and every move. */
    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    /* Moves time on by piElapsedMs milliseconds. Returns true when anything visible changed, so
       the controller redraws only when it has to. Does nothing, and returns false, while Paused
       or when the game is over. */
    METHOD PUBLIC LOGICAL Tick(INPUT piElapsedMs AS INTEGER).

END INTERFACE.
