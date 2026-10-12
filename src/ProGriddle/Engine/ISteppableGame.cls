/* A game whose whole grid updates at once on each step, such as Conway's Life. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.ISteppableGame INHERITS IGame:

    /* Number of steps taken since Initialise. */
    DEFINE PUBLIC PROPERTY Generation AS INTEGER NO-UNDO
        GET.

    /* Advances the whole grid by one generation. */
    METHOD PUBLIC VOID Step().

END INTERFACE.
