/* The maze of FOR EACH: 28 tiles across and 31 down, with 240 bits of data and 4 commit tokens (244 things to eat), a lobby for the
   phantoms in the middle with its door on top, two tunnels along row 14, and the starts of Dibby, the four phantoms and the
   bonus item. The left half is the mirror image of the right half. It is the map for the maze reader in section 2.1 of
   docs/design/foreach-art.md, in the symbols of MazeMap: # wall, _ empty lane, . bit, o commit token, - door, = lobby floor,
   T tunnel lane, U an empty lane where phantoms may not turn up (columns 11 to 16 of rows 11 and 23), D and W the starts of
   Dibby and Mary, which stand on two of those lanes (the P and M of the design), R B C the starts of Rich, Brian and Chip in
   the lobby and F the bonus item spot. */
USING Progress.Lang.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachMaze FINAL:

    /* The rows of the maze, 31 lines of 28 symbols with a line feed between them, for MazeMap. */
    METHOD PUBLIC STATIC CHARACTER Layout():
        RETURN
            "############################" + CHR(10) +
            "#..........................#" + CHR(10) +
            "#.###.####.######.####.###.#" + CHR(10) +
            "#o###.####.######.####.###o#" + CHR(10) +
            "#..........................#" + CHR(10) +
            "#.###.##.##########.##.###.#" + CHR(10) +
            "#.###.##.##########.##.###.#" + CHR(10) +
            "#.###.##.##########.##.###.#" + CHR(10) +
            "#.....##____________##.....#" + CHR(10) +
            "#####.#####.####.#####.#####" + CHR(10) +
            "#####.#####.####.#####.#####" + CHR(10) +
            "#####.##___UUUWUU___##.#####" + CHR(10) +
            "#####.##_####--####_##.#####" + CHR(10) +
            "#####.##_#========#_##.#####" + CHR(10) +
            "TTTTT.___#==B=R=C=#___.TTTTT" + CHR(10) +
            "#####.##_#========#_##.#####" + CHR(10) +
            "#####.##_##########_##.#####" + CHR(10) +
            "#####.##______F_____##.#####" + CHR(10) +
            "#####.##_##########_##.#####" + CHR(10) +
            "#####.##_##########_##.#####" + CHR(10) +
            "#..........................#" + CHR(10) +
            "#.###.#####.####.#####.###.#" + CHR(10) +
            "#.###.#####.####.#####.###.#" + CHR(10) +
            "#o..#....__UUUDUU__....#..o#" + CHR(10) +
            "###.#.##.##########.##.#.###" + CHR(10) +
            "###.#.##.##########.##.#.###" + CHR(10) +
            "#..........................#" + CHR(10) +
            "#.#######.##.##.##.#######.#" + CHR(10) +
            "#.#######.##.##.##.#######.#" + CHR(10) +
            "#............__............#" + CHR(10) +
            "############################".
    END METHOD.

END CLASS.
