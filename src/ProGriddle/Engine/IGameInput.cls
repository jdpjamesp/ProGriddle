/* What a window needs from a game besides drawing it, without knowing which game it is: a
   line of status text, an optional picker (Life: which pattern to place), a few named extra
   commands (Life: Random, Clear) and what a left click, a right click or both buttons together on a cell does. The window
   builds its status bar, picker and buttons from this, so a new game needs no new window.
   Implementations live with the game and use no UI types. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.IGameInput:

    /* One line for the status bar, for example "Generation 12   Alive 340   B3/S23". Read it
       after every change. */
    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET.

    /* Label for the picker, for example "Pattern". Empty when there is no picker. */
    DEFINE PUBLIC PROPERTY ChoiceLabel AS CHARACTER NO-UNDO
        GET.

    /* Comma separated names the picker offers. Empty hides the picker. */
    DEFINE PUBLIC PROPERTY ChoiceNames AS CHARACTER NO-UNDO
        GET.

    /* The selected name. Setting a name that is not in ChoiceNames throws GridException. */
    DEFINE PUBLIC PROPERTY Choice AS CHARACTER NO-UNDO
        GET.
        SET.

    /* Comma separated extra commands, shown as buttons. Each entry is a name, optionally
       followed by a colon and a single letter that triggers it from the keyboard, as in
       "Random:G,Clear:C". Empty for none. */
    DEFINE PUBLIC PROPERTY CommandNames AS CHARACTER NO-UNDO
        GET.

    /* A few words about what the last action did, for example "Question marks on" or "Ships
       cannot touch", or an empty string when there is nothing to say. The window calls it after
       every click, key and command and shows the words over the board for a moment, because a
       button that switches a setting, or a click that is refused, otherwise gives no sign that
       anything happened. Calling it takes the notice, so the next call returns an empty string
       until there is a new one. */
    METHOD PUBLIC CHARACTER TakeNotice().

    /* An optional extra screen of text, such as the high scores. The same form as one entry of
       CommandNames: a name, optionally followed by a colon and a key letter, as in "Scores:H".
       The window adds a button and the key, and shows InfoText in a dialog titled with the
       name. Empty for none. */
    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET.

    /* The text for that screen, one line per CHR(10). Read each time the screen is opened. */
    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET.

    /* Runs one of the commands in CommandNames, by name only (no key letter). Throws
       GridException for any other name. */
    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER).

    /* A left click on a cell. A click off the board is ignored. */
    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER).

    /* A right click on a cell. A click off the board is ignored. */
    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER).

    /* A middle click, or the left and right buttons pressed together, on a cell. A click off
       the board is ignored. Games with no use for it leave the body empty. */
    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER).

END INTERFACE.
