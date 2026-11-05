/* An optional extra for a game input (IGameInput) that cares whether the Shift key is down, such as a game with a command on > and
   another on <, or with a capital letter that means something else. HandleKey is given only the name of the key, so the window,
   when the input also implements this, sets ShiftDown just before every HandleKey. Inputs that do not care need not implement it. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.IModifierKeys:

    /* True while the Shift key is held, as of the key being handled. */
    DEFINE PUBLIC PROPERTY ShiftDown AS LOGICAL NO-UNDO
        GET.
        SET.

END INTERFACE.
