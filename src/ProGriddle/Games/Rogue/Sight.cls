/* What the hero can see. In a lit room the hero sees the whole room, its walls and its doors the moment they are inside it (a doorway counts
   as inside). In a dark room, a corridor, or anywhere when the room is not lit, the hero sees only the eight squares round it. A blind
   hero sees nothing but the square under the hero. Everything in sight is marked as seen, and what has been seen stays on the map as a
   memory (drawn dim) when it is out of sight again. Monsters in sight are marked as seen too. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Sight FINAL:

    /* Works out what is in sight now, marks it, and marks the monsters in it as seen. Call it after the hero or the level changes. */
    METHOD PUBLIC STATIC VOID Look(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE hx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE hy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE room   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        hx = poWorld:Hero:X.
        hy = poWorld:Hero:Y.
        poWorld:Cave:ClearView().
        Reveal(poWorld, hx, hy, FALSE).
        IF poWorld:Hero:Blind = 0 THEN DO:
            DO y = hy - 1 TO hy + 1:
                DO x = hx - 1 TO hx + 1:
                    Reveal(poWorld, x, y, TRUE).
                END.
            END.
            room = poWorld:Cave:RoomAt(hx, hy).
            IF room > 0 AND poWorld:RoomLit(room) THEN DO:
                DO y = 0 TO poWorld:Cave:Height - 1:
                    DO x = 0 TO poWorld:Cave:Width - 1:
                        IF poWorld:Cave:RoomAt(x, y) = room THEN Reveal(poWorld, x, y, TRUE).
                    END.
                END.
            END.
        END.
        DO i = 0 TO RogueRules:MostMonsters() - 1:
            oMonster = poWorld:MonsterInSlot(i).
            IF VALID-OBJECT(oMonster) AND poWorld:Cave:InView(oMonster:X, oMonster:Y) AND CanSee(poWorld, oMonster) THEN oMonster:Seen = TRUE.
        END.
    END METHOD.

    /* Puts a cell in sight, and in memory when plRemember. Cells off the map are left alone. */
    METHOD PRIVATE STATIC VOID Reveal(INPUT poWorld AS RogueWorld, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plRemember AS LOGICAL):
        IF NOT poWorld:Cave:InBounds(piX, piY) THEN RETURN.
        poWorld:Cave:SetInView(piX, piY, TRUE).
        IF plRemember THEN poWorld:Cave:SetSeen(piX, piY, TRUE).
    END METHOD.

    /* True when the hero can see a monster now: it is in a square in sight, and is not invisible (unless the hero can see invisible
       things, or it is next to the hero, who can feel it there). */
    METHOD PUBLIC STATIC LOGICAL CanSee(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        IF poWorld:Hero:Blind > 0 THEN RETURN FALSE.
        IF NOT poWorld:Cave:InView(poMonster:X, poMonster:Y) THEN RETURN FALSE.
        IF poMonster:Invisible AND NOT SeesInvisible(poWorld) THEN RETURN FALSE.
        RETURN TRUE.
    END METHOD.

    /* True when the hero can see invisible things: the potion is working or a ring of see invisible is worn. */
    METHOD PUBLIC STATIC LOGICAL SeesInvisible(INPUT poWorld AS RogueWorld):
        RETURN poWorld:Hero:SeesInvisible > 0 OR poWorld:Pack:WearingRing(RingKind:SeeInvisible).
    END METHOD.

    /* True when nothing stops the eye on the straight line from one square to another (the ends themselves do not count). The line is a
       Bresenham line, the same from both ends. */
    METHOD PUBLIC STATIC LOGICAL LineClear(INPUT poWorld AS RogueWorld, INPUT piX0 AS INTEGER, INPUT piY0 AS INTEGER, INPUT piX1 AS INTEGER, INPUT piY1 AS INTEGER):
        DEFINE VARIABLE dx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sy  AS INTEGER NO-UNDO.
        DEFINE VARIABLE err AS INTEGER NO-UNDO.
        DEFINE VARIABLE e2  AS INTEGER NO-UNDO.
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        /* the line is walked from the end with the lower position, so both ends give the same line */
        IF piY1 < piY0 OR (piY1 = piY0 AND piX1 < piX0) THEN RETURN LineClear(poWorld, piX1, piY1, piX0, piY0).
        dx = ABSOLUTE(piX1 - piX0).
        dy = ABSOLUTE(piY1 - piY0).
        sx = (IF piX0 < piX1 THEN 1 ELSE -1).
        sy = 1.
        err = dx - dy.
        x = piX0.
        y = piY0.
        DO WHILE NOT (x = piX1 AND y = piY1):
            e2 = 2 * err.
            IF e2 > - dy THEN DO:
                err = err - dy.
                x = x + sx.
            END.
            IF e2 < dx THEN DO:
                err = err + dx.
                y = y + sy.
            END.
            IF NOT (x = piX1 AND y = piY1) AND poWorld:Cave:Opaque(x, y) THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

END CLASS.
