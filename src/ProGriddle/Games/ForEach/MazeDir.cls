/* The four ways to go in the maze. The order is the tie break order of a phantom choosing a way (up, then left, then down,
   then right), so INTEGER(MazeDir:Up) is 1 and INTEGER(MazeDir:Right) is 4 and MazeDir:GetEnum(n) goes back. "No direction"
   is the unknown value. MazeDirs says which way each one points. */
ENUM ProGriddle.Games.ForEach.MazeDir:

    DEFINE ENUM Up = 1
                Left
                Down
                Right.

END ENUM.
