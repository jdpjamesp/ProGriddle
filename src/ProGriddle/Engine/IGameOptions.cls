/* Extra pickers a game can offer its window, beyond the one in IGameInput (the pattern box of Life).
   A game input that also implements this interface gets one labelled drop down list for each option,
   after the picker in the toolbar. Life uses it for the rule set and the board size. A game that
   needs no such options does not implement it, and nothing about it changes.

   Options are numbered from 1 to OptionCount. Choosing an item in the window calls SetOption, after
   which the window redraws and refreshes the status line, so an option may change the game itself,
   even replace its grid, as a board size does. The window saves each option under the setting
   "<prefix>.<OptionKey>" when it closes and puts it back with SetOption when it is built, but only
   if the saved value is one of the option's names. Names and values are single items of a comma
   separated list, so they cannot contain a comma. */
USING Progress.Lang.*.
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.IGameOptions:

    /* How many options there are, 0 or more. */
    DEFINE PUBLIC PROPERTY OptionCount AS INTEGER NO-UNDO
        GET.

    /* The caption beside the list, for example "Rules". */
    METHOD PUBLIC CHARACTER OptionLabel(INPUT piOption AS INTEGER).

    /* The last part of the setting the choice is saved under: "rules" is saved as "life.rules"
       by the Life window. Letters and digits only. */
    METHOD PUBLIC CHARACTER OptionKey(INPUT piOption AS INTEGER).

    /* The items to offer, comma separated. It is read when the window is built, so an option can
       add the game's current value when that is not one of the usual ones. */
    METHOD PUBLIC CHARACTER OptionNames(INPUT piOption AS INTEGER).

    /* The item that is chosen now. */
    METHOD PUBLIC CHARACTER OptionValue(INPUT piOption AS INTEGER).

    /* Chooses an item. Throws GridException for an option that does not exist or a value that
       the option does not accept. */
    METHOD PUBLIC VOID SetOption(INPUT piOption AS INTEGER, INPUT pcValue AS CHARACTER).

END INTERFACE.
