/* Shared help for the FOR EACH tests (it holds no tests): small mazes written as text, a game built on one, and ways to run a
   game forward until something happens. A maze is written with | between the rows, so a test reads as a picture. The symbols
   are the ones of MazeMap: # wall, _ path, . bit, o commit, - door, = lobby floor, T tunnel path, N bit where phantoms may not
   turn up, U empty path where they may not turn up, and the starts P (Dibby), M R B C (Mary, Rich, Brian, Chip) and F
   (item). A start sits on a tile and means the left edge of that tile across and the middle of it down. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachKit FINAL:

    /* The text of a maze from rows written with | between them. */
    METHOD PUBLIC STATIC CHARACTER Pipes(INPUT pcRows AS CHARACTER):
        RETURN REPLACE(pcRows, "|", CHR(10)).
    END METHOD.

    /* One empty lane with walls at both ends, 20 tiles long. Dibby starts in the middle of it (x 88, y 12). No phantoms. */
    METHOD PUBLIC STATIC CHARACTER ClosedCorridor():
        RETURN Pipes("####################|#__________P_______#|####################").
    END METHOD.

    /* The same lane with a bit on every tile, and a commit at each end (15 bits and 2 commits, 17 in all). */
    METHOD PUBLIC STATIC CHARACTER DataCorridor():
        RETURN Pipes("####################|#o.........P......o#|####################").
    END METHOD.

    /* A lane that is open at both ends, so Dibby walking along it comes out of the other side. Dibby starts at x 72. */
    METHOD PUBLIC STATIC CHARACTER TunnelCorridor():
        RETURN Pipes("####################|_________P__________|####################").
    END METHOD.

    /* An open lane whose left half is slow tunnel (columns 0 to 8) and whose right half is ordinary path. */
    METHOD PUBLIC STATIC CHARACTER SlowCorridor():
        RETURN Pipes("####################|TTTTTTTTTP__________|####################").
    END METHOD.

    /* A lane with three bits left of Dibby, who starts at x 32: eating them clears the level. */
    METHOD PUBLIC STATIC CHARACTER FewBits():
        RETURN Pipes("####################|#...P" + FILL("_", 14) + "#|####################").
    END METHOD.

    /* The closed lane with a item spot at column 3 (x 24, y 12). */
    METHOD PUBLIC STATIC CHARACTER ItemCorridor():
        RETURN Pipes("####################|#__F_______P_______#|####################").
    END METHOD.

    /* A lane along the top with one opening down at column 5 into a lane along the bottom. Dibby starts above the opening. */
    METHOD PUBLIC STATIC CHARACTER SideDoor():
        RETURN Pipes("###########|#____P____#|#####_#####|#_________#|###########").
    END METHOD.

    /* Two separate lanes that both wrap round (rows 1 and 3), so something in one can never meet something in the other. Dibby
       starts on the lower one at x 8. */
    METHOD PUBLIC STATIC CHARACTER TwoLanes():
        RETURN Pipes("####################|____________________|####################|_P__________________|####################").
    END METHOD.

    /* A game on a maze given as text, with a seeded random source. */
    METHOD PUBLIC STATIC ForEachGame GameOn(INPUT pcMaze AS CHARACTER):
        RETURN ForEachFactory:CreateOn(NEW MazeMap(pcMaze), NEW SeededRandom(5)).
    END METHOD.

    /* Advances the game one frame at a time until it is in the phase, for at most piMax frames. Returns true when it got there. */
    METHOD PUBLIC STATIC LOGICAL RunUntil(INPUT poGame AS ForEachGame, INPUT poPhase AS ForEachPhase, INPUT piMax AS INTEGER):
        VAR INTEGER n.
        DO n = 1 TO piMax:
            IF poGame:Phase = poPhase THEN RETURN TRUE.
            poGame:Advance().
        END.
        RETURN poGame:Phase = poPhase.
    END METHOD.

    /* From the title screen to a game in play: the new game and its READY! are got through. */
    METHOD PUBLIC STATIC VOID Play(INPUT poGame AS ForEachGame):
        poGame:StartGame().
        RunUntil(poGame, ForEachPhase:Playing, 900).
    END METHOD.

    METHOD PUBLIC STATIC VOID Frames(INPUT poGame AS ForEachGame, INPUT piCount AS INTEGER):
        VAR INTEGER n.
        DO n = 1 TO piCount:
            poGame:Advance().
        END.
    END METHOD.

END CLASS.
