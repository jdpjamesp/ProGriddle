/* The classic Windows levels and the limits of a custom game.

     Beginner      9 x 9 with 10 mines
     Intermediate  16 x 16 with 40 mines
     Expert        30 x 16 with 99 mines (30 wide, 16 high)
     Custom        width 9 to 30, height 9 to 24, mines from 10 up to (width - 1) * (height - 1) */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperLevels FINAL:

    /* The level names, in the order a picker shows them. */
    METHOD PUBLIC STATIC CHARACTER Names():
        RETURN "Beginner,Intermediate,Expert,Custom".
    END METHOD.

    /* The level a name stands for in its proper spelling, or an empty string for an unknown name. */
    METHOD PUBLIC STATIC CHARACTER Canonical(INPUT pcName AS CHARACTER):
        IF pcName = ? OR LOOKUP(pcName, Names()) = 0 THEN RETURN "".
        RETURN ENTRY(LOOKUP(pcName, Names()), Names()).
    END METHOD.

    /* True for Beginner, Intermediate and Expert, the levels that keep best times. */
    METHOD PUBLIC STATIC LOGICAL IsStandard(INPUT pcName AS CHARACTER):
        RETURN Canonical(pcName) <> "" AND Canonical(pcName) <> "Custom".
    END METHOD.

    METHOD PUBLIC STATIC INTEGER WidthOf(INPUT pcName AS CHARACTER):
        CASE Canonical(pcName):
            WHEN "Beginner" THEN RETURN 9.
            WHEN "Intermediate" THEN RETURN 16.
            WHEN "Expert" THEN RETURN 30.
            OTHERWISE UNDO, THROW NEW GridException("Not a standard level: " + STRING(pcName)).
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER HeightOf(INPUT pcName AS CHARACTER):
        CASE Canonical(pcName):
            WHEN "Beginner" THEN RETURN 9.
            WHEN "Intermediate" THEN RETURN 16.
            WHEN "Expert" THEN RETURN 16.
            OTHERWISE UNDO, THROW NEW GridException("Not a standard level: " + STRING(pcName)).
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER MinesOf(INPUT pcName AS CHARACTER):
        CASE Canonical(pcName):
            WHEN "Beginner" THEN RETURN 10.
            WHEN "Intermediate" THEN RETURN 40.
            WHEN "Expert" THEN RETURN 99.
            OTHERWISE UNDO, THROW NEW GridException("Not a standard level: " + STRING(pcName)).
        END CASE.
    END METHOD.

    /* A custom width brought into 9 to 30. */
    METHOD PUBLIC STATIC INTEGER ClampWidth(INPUT piWidth AS INTEGER):
        IF piWidth = ? THEN RETURN 9.
        RETURN MAXIMUM(9, MINIMUM(30, piWidth)).
    END METHOD.

    /* A custom height brought into 9 to 24. */
    METHOD PUBLIC STATIC INTEGER ClampHeight(INPUT piHeight AS INTEGER):
        IF piHeight = ? THEN RETURN 9.
        RETURN MAXIMUM(9, MINIMUM(24, piHeight)).
    END METHOD.

    /* A custom mine count brought into 10 to (width - 1) * (height - 1). The width and height
       must already be clamped. */
    METHOD PUBLIC STATIC INTEGER ClampMines(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER, INPUT piMines AS INTEGER):
        IF piMines = ? THEN RETURN 10.
        RETURN MAXIMUM(10, MINIMUM((piWidth - 1) * (piHeight - 1), piMines)).
    END METHOD.

END CLASS.
