/* How a phantom picks its way at a tile. Standing on a tile and heading some way, it looks at the neighbours it may enter, never
   the one behind it, and takes the one whose tile is nearest to the target in a straight line; a tie goes to up, then left, then
   down, then right. Two things change that: a tile can forbid turning up (when the rule is on), and only a phantom that may use the
   door can go through it or into the lobby. A rolled back phantom picks one of the open ways at random. A dead end sends the
   phantom back the way it came. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.PhantomSteering FINAL:

    /* Refuses what a steering call cannot work with: no maze, no heading, a tile off the maze. */
    METHOD PRIVATE STATIC VOID Verify(INPUT poMaze AS MazeMap, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT poHeading AS MazeDir):
        IF NOT VALID-OBJECT(poMaze) THEN UNDO, THROW NEW GridException("Steering needs a maze").
        IF poHeading = ? THEN UNDO, THROW NEW GridException("Steering needs a heading").
        poMaze:KindAt(piCol, piRow).
    END METHOD.

    /* True when the phantom may leave the tile in the direction: not back the way it came, into somewhere it may enter, and not up
       from a tile that forbids it when the rule is on. */
    METHOD PRIVATE STATIC LOGICAL MayGo(INPUT poMaze AS MazeMap, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT poHeading AS MazeDir,
                                        INPUT poDir AS MazeDir, INPUT plNoUp AS LOGICAL, INPUT plDoor AS LOGICAL):
        DEFINE VARIABLE nr AS INTEGER NO-UNDO.
        IF poDir = MazeDirs:Opposite(poHeading) THEN RETURN FALSE.
        IF poDir = MazeDir:Up AND plNoUp AND poMaze:NoUpAt(piCol, piRow) THEN RETURN FALSE.
        nr = piRow + MazeDirs:Dy(poDir).
        IF nr < 0 OR nr >= poMaze:Rows THEN RETURN FALSE.
        RETURN poMaze:CanEnter(piCol + MazeDirs:Dx(poDir), nr, plDoor).
    END METHOD.

    /* The way out of the tile that goes nearest to the target tile. plNoUp switches the no turning up tiles on and plDoor lets the
       phantom through the door and into the lobby. Throws GridException for no maze, no heading or a tile off the maze. */
    METHOD PUBLIC STATIC MazeDir Choose(INPUT poMaze AS MazeMap, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT poHeading AS MazeDir,
                                        INPUT piTargetCol AS INTEGER, INPUT piTargetRow AS INTEGER,
                                        INPUT plNoUp AS LOGICAL, INPUT plDoor AS LOGICAL):
        DEFINE VARIABLE d    AS INTEGER NO-UNDO.
        DEFINE VARIABLE dir  AS MazeDir NO-UNDO.
        DEFINE VARIABLE best AS MazeDir NO-UNDO.
        DEFINE VARIABLE gap  AS INTEGER NO-UNDO.
        DEFINE VARIABLE near AS INTEGER NO-UNDO INITIAL ?.
        Verify(poMaze, piCol, piRow, poHeading).
        DO d = 1 TO 4:
            dir = MazeDir:GetEnum(d).
            IF MayGo(poMaze, piCol, piRow, poHeading, dir, plNoUp, plDoor) THEN DO:
                gap = INTEGER(EXP(piCol + MazeDirs:Dx(dir) - piTargetCol, 2) + EXP(piRow + MazeDirs:Dy(dir) - piTargetRow, 2)).
                IF near = ? OR gap < near THEN ASSIGN near = gap
                                                      best = dir.
            END.
        END.
        IF best = ? THEN RETURN MazeDirs:Opposite(poHeading).
        RETURN best.
    END METHOD.

    /* A way out of the tile chosen at random among the open ones, in the order up, left, down, right. The no turning up tiles do not
       apply, and the door is shut. */
    METHOD PUBLIC STATIC MazeDir ChooseAtRandom(INPUT poMaze AS MazeMap, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER,
                                                INPUT poHeading AS MazeDir, INPUT poRandom AS IRandom):
        DEFINE VARIABLE d     AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE pick  AS INTEGER NO-UNDO.
        DEFINE VARIABLE ways  AS INTEGER NO-UNDO EXTENT 4.
        Verify(poMaze, piCol, piRow, poHeading).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("Steering at random needs a random source").
        DO d = 1 TO 4:
            IF MayGo(poMaze, piCol, piRow, poHeading, MazeDir:GetEnum(d), FALSE, FALSE) THEN DO:
                n = n + 1.
                ways[n] = d.
            END.
        END.
        IF n = 0 THEN RETURN MazeDirs:Opposite(poHeading).
        pick = poRandom:NextInt(n).
        RETURN MazeDir:GetEnum(ways[pick + 1]).
    END METHOD.

END CLASS.
