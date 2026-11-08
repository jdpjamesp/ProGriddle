/* The four ways to hop on the pyramid, as seen on the screen. In lamp coordinates (row, column) a hop goes
     UpLeft     (row - 1, column - 1)
     UpRight    (row - 1, column)
     DownLeft   (row + 1, column)
     DownRight  (row + 1, column + 1)
   The arrow keys are the pyramid seen at 45 degrees: Up is UpRight, Right is DownRight, Down is DownLeft, Left is UpLeft. */
ENUM ProGriddle.Games.Cuber.CuberDir:
    DEFINE ENUM UpLeft = 0
                UpRight
                DownLeft
                DownRight.
END ENUM.
