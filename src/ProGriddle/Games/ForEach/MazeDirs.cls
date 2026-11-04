/* What the four directions of the maze mean on the screen: how far across and down one step in each goes, and which one is the
   way back. x grows to the right and y grows down, so Up is a step of -1 down. An unknown direction is refused. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.MazeDirs FINAL:

    /* The step across the maze: -1 for Left, 1 for Right, otherwise 0. */
    METHOD PUBLIC STATIC INTEGER Dx(INPUT poDir AS MazeDir):
        IF poDir = ? THEN UNDO, THROW NEW GridException("A direction cannot be unknown").
        CASE poDir:
            WHEN MazeDir:Left THEN RETURN -1.
            WHEN MazeDir:Right THEN RETURN 1.
            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    /* The step down the maze: -1 for Up, 1 for Down, otherwise 0. */
    METHOD PUBLIC STATIC INTEGER Dy(INPUT poDir AS MazeDir):
        IF poDir = ? THEN UNDO, THROW NEW GridException("A direction cannot be unknown").
        CASE poDir:
            WHEN MazeDir:Up THEN RETURN -1.
            WHEN MazeDir:Down THEN RETURN 1.
            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    /* The way back. */
    METHOD PUBLIC STATIC MazeDir Opposite(INPUT poDir AS MazeDir):
        IF poDir = ? THEN UNDO, THROW NEW GridException("A direction cannot be unknown").
        CASE poDir:
            WHEN MazeDir:Up THEN RETURN MazeDir:Down.
            WHEN MazeDir:Down THEN RETURN MazeDir:Up.
            WHEN MazeDir:Left THEN RETURN MazeDir:Right.
            OTHERWISE RETURN MazeDir:Left.
        END CASE.
    END METHOD.

END CLASS.
