/* How far every square of the level is from the hero on foot, counted in steps round the walls (a breadth first search from the hero's
   square). A monster that is hunting the hero steps to the neighbouring square that is nearest to the hero, so it finds its way round
   corners and through doors instead of walking into walls. A diagonal step is not allowed into or out of a doorway, the same as for the hero. The map is
   worked out once a turn by Refresh and shared by every monster. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Chase FINAL:

    DEFINE PRIVATE VARIABLE mDist  AS INTEGER NO-UNDO EXTENT 1680.
    DEFINE PRIVATE VARIABLE mQueue AS INTEGER NO-UNDO EXTENT 1680.

    /* Works out the distances from the hero's square: 0 there, -1 for squares that cannot be reached. */
    METHOD PUBLIC VOID Refresh(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE head AS INTEGER NO-UNDO.
        DEFINE VARIABLE tail AS INTEGER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy   AS INTEGER NO-UNDO.
        DEFINE VARIABLE nx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE ny   AS INTEGER NO-UNDO.
        DEFINE VARIABLE here AS INTEGER NO-UNDO.
        DO i = 1 TO 1680:
            mDist[i] = -1.
        END.
        mDist[poWorld:Hero:Y * 80 + poWorld:Hero:X + 1] = 0.
        mQueue[1] = poWorld:Hero:Y * 80 + poWorld:Hero:X.
        head = 1.
        tail = 1.
        DO WHILE head <= tail:
            here = mQueue[head].
            head = head + 1.
            x = here MODULO 80.
            y = INTEGER(TRUNCATE(here / 80, 0)).
            DO dy = -1 TO 1:
                DO dx = -1 TO 1:
                    nx = x + dx.
                    ny = y + dy.
                    IF (dx <> 0 OR dy <> 0) AND poWorld:CanStep(x, y, dx, dy) AND mDist[ny * 80 + nx + 1] < 0 THEN DO:
                        mDist[ny * 80 + nx + 1] = mDist[here + 1] + 1.
                        tail = tail + 1.
                        mQueue[tail] = ny * 80 + nx.
                    END.
                END.
            END.
        END.
    END METHOD.

    /* The number of steps from a square to the hero, -1 when there is no way (or the square is off the map). */
    METHOD PUBLIC INTEGER DistanceAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX > 79 OR piY < 0 OR piY > 20 THEN RETURN -1.
        RETURN mDist[piY * 80 + piX + 1].
    END METHOD.

    /* The step a monster should take to get nearer to the hero: gives true and the direction, or false when there is none (it is
       already next to the hero, boxed in, or cannot reach the hero). Squares with another monster on them are not stepped on; of
       several equally good steps one is chosen at random. */
    METHOD PUBLIC LOGICAL BestStep(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster, OUTPUT piDX AS INTEGER, OUTPUT piDY AS INTEGER):
        DEFINE VARIABLE here  AS INTEGER NO-UNDO.
        DEFINE VARIABLE best  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE d     AS INTEGER NO-UNDO.
        DEFINE VARIABLE ties  AS INTEGER NO-UNDO.
        piDX = 0.
        piDY = 0.
        here = DistanceAt(poMonster:X, poMonster:Y).
        IF here <= 1 THEN RETURN FALSE.
        best = here.
        DO dy = -1 TO 1:
            DO dx = -1 TO 1:
                IF (dx <> 0 OR dy <> 0) AND poWorld:CanStep(poMonster:X, poMonster:Y, dx, dy) AND poWorld:Cave:MonsterAt(poMonster:X + dx, poMonster:Y + dy) = 0 THEN DO:
                    d = DistanceAt(poMonster:X + dx, poMonster:Y + dy).
                    IF d >= 0 AND d < best THEN DO:
                        best = d.
                        piDX = dx.
                        piDY = dy.
                        ties = 1.
                    END.
                    ELSE IF d >= 0 AND d = best AND best < here THEN DO:
                        ties = ties + 1.
                        IF poWorld:Random:NextInt(ties) = 0 THEN DO:
                            piDX = dx.
                            piDY = dy.
                        END.
                    END.
                END.
            END.
        END.
        RETURN piDX <> 0 OR piDY <> 0.
    END METHOD.

END CLASS.
