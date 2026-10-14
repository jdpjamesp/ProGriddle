/* How a Snake board is drawn: a colour for each value of the "view" layer (see the ViewCode enum), in
   value order so a window gives the list straight to its view. A dark board, a green body, a
   lighter head so the way it is facing shows, and red food. */
USING Progress.Lang.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeLook FINAL:

    /* Cell colours: empty, body, head, food. */
    METHOD PUBLIC STATIC CHARACTER Palette():
        RETURN "1E242B,3FAE78,8EF0C0,E5533D".
    END METHOD.

    /* One character per value, for drawing a board as text in tests: . empty, o body, @ head,
       * food. */
    METHOD PUBLIC STATIC CHARACTER TextSymbols():
        RETURN ".o@*".
    END METHOD.

END CLASS.
