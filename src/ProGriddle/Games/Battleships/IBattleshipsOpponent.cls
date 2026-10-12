/* The computer's side of the game: it chooses where to fire, knowing only the results of its own
   shots. It is never told where the player's ships are. The game tells it each result with
   Observe, and the same interface takes any strategy, from random shots to a smart hunter. */
USING ProGriddle.Games.Battleships.*.

INTERFACE ProGriddle.Games.Battleships.IBattleshipsOpponent:

    /* Starts a new game on a board of this size and forgets everything. */
    METHOD PUBLIC VOID Reset(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER).

    /* Chooses a cell to fire at: one that has not been fired at before. Throws GridException
       when every cell has been fired at. */
    METHOD PUBLIC VOID NextShot(OUTPUT piX AS INTEGER, OUTPUT piY AS INTEGER).

    /* The result of the last shot. plSunk is true when it finished a ship (so plHit is true too). */
    METHOD PUBLIC VOID Observe(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plHit AS LOGICAL, INPUT plSunk AS LOGICAL).

    /* Releases what it holds. Call it when finished. */
    METHOD PUBLIC VOID Dispose().

END INTERFACE.
