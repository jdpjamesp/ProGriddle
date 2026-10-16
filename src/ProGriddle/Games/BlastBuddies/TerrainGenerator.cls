/* Makes the ground of a Blast Buddies map from a seeded random source, so a seed always gives the same map. The land is a few rolling
   waves (one long, one middling, one short and small) with the bedrock and soil under it, 10 columns of open air at each side, one or two
   caves and up to two floating islands. The land is built so that it holds no piece of 24 pixels or fewer (the tests run the crumb rule over it).
   FindSpots then picks the places where buddies start: flat, clear of rock overhead, above the water and spaced out. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.TerrainGenerator FINAL:

    /* The columns of open air at each side of the map. */
    DEFINE PUBLIC STATIC PROPERTY EdgeGap AS INTEGER NO-UNDO INITIAL 10 GET.

    /* One wave of a land: a sine with a period in pixels, a phase in steps of a 64 step turn and an amplitude in pixels, got from the 64 step
       table with the steps in between worked out as a straight line. */
    METHOD PRIVATE DECIMAL Wave(INPUT piX AS INTEGER, INPUT pdPeriod AS DECIMAL, INPUT pdPhase AS DECIMAL):
        DEFINE VARIABLE t  AS DECIMAL NO-UNDO.
        DEFINE VARIABLE i0 AS INTEGER NO-UNDO.
        DEFINE VARIABLE f  AS DECIMAL NO-UNDO.
        t = piX * 64 / pdPeriod + pdPhase.
        t = t - 64 * TRUNCATE(t / 64, 0).
        i0 = INTEGER(TRUNCATE(t, 0)).
        f = t - i0.
        RETURN (Heading:Sin(i0) * (1 - f) + Heading:Sin(i0 + 1) * f) / Heading:Scale().
    END METHOD.

    /* A number from piLow to piHigh, both included. */
    METHOD PRIVATE INTEGER RandomIn(INPUT poRandom AS IRandom, INPUT piLow AS INTEGER, INPUT piHigh AS INTEGER):
        RETURN piLow + poRandom:NextInt(piHigh - piLow + 1).
    END METHOD.

    /* Fills a map with new ground. The map should be empty. */
    METHOD PUBLIC VOID Generate(INPUT poTerrain AS Terrain, INPUT poRandom AS IRandom):
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE surf   AS INTEGER NO-UNDO EXTENT 384.
        DEFINE VARIABLE base   AS INTEGER NO-UNDO.
        DEFINE VARIABLE p1     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE p2     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE p3     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE a1     AS INTEGER NO-UNDO.
        DEFINE VARIABLE a2     AS INTEGER NO-UNDO.
        DEFINE VARIABLE a3     AS INTEGER NO-UNDO.
        DEFINE VARIABLE l1     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE l2     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE l3     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE h      AS DECIMAL NO-UNDO.
        DEFINE VARIABLE cx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE rad    AS INTEGER NO-UNDO.
        DEFINE VARIABLE ea     AS INTEGER NO-UNDO.
        DEFINE VARIABLE eb     AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poTerrain) OR NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A generator needs a map and a random source").
        base = RandomIn(poRandom, 115, 135).
        l1 = RandomIn(poRandom, 200, 300).
        l2 = RandomIn(poRandom, 90, 140).
        l3 = RandomIn(poRandom, 40, 60).
        a1 = RandomIn(poRandom, 15, 26).
        a2 = RandomIn(poRandom, 5, 10).
        a3 = RandomIn(poRandom, 1, 3).
        p1 = poRandom:NextDecimal() * 64.
        p2 = poRandom:NextDecimal() * 64.
        p3 = poRandom:NextDecimal() * 64.
        /* the land, down to the bottom of the map */
        DO x = EdgeGap TO Terrain:Width() - 1 - EdgeGap:
            h = base + a1 * Wave(x, l1, p1) + a2 * Wave(x, l2, p2) + a3 * Wave(x, l3, p3).
            surf[x + 1] = MAXIMUM(70, MINIMUM(190, INTEGER(ROUND(h, 0)))).
            poTerrain:FillRect(x, surf[x + 1], x, Terrain:Height() - 1, TRUE).
        END.
        /* one or two caves, with a roof of at least 14 pixels over them */
        DO k = 1 TO RandomIn(poRandom, 1, 2):
            cx = RandomIn(poRandom, 40, 340).
            rad = RandomIn(poRandom, 10, 18).
            cy = surf[cx + 1] + rad + RandomIn(poRandom, 14, 40).
            IF cy + rad < 195 THEN ClearDisc(poTerrain, cx, cy, rad).
        END.
        /* up to two floating islands, well above the land under them */
        DO k = 1 TO RandomIn(poRandom, 0, 2):
            cx = RandomIn(poRandom, 40, 340).
            ea = RandomIn(poRandom, 12, 22).
            eb = RandomIn(poRandom, 5, 8).
            cy = RandomIn(poRandom, 35, 65).
            IF cy + eb < surf[cx + 1] - 30 THEN FillEllipse(poTerrain, cx, cy, ea, eb).
        END.
    END METHOD.

    /* Turns the pixels within a radius of a point to air, without any scorch. */
    METHOD PRIVATE VOID ClearDisc(INPUT poTerrain AS Terrain, INPUT piCx AS INTEGER, INPUT piCy AS INTEGER, INPUT piR AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = piCy - piR TO piCy + piR:
            DO x = piCx - piR TO piCx + piR:
                IF (x - piCx) * (x - piCx) + (y - piCy) * (y - piCy) <= piR * piR AND poTerrain:InBounds(x, y) THEN poTerrain:SetSolid(x, y, FALSE).
            END.
        END.
    END METHOD.

    /* Turns the pixels inside an ellipse with half widths piA across and piB down to ground. */
    METHOD PRIVATE VOID FillEllipse(INPUT poTerrain AS Terrain, INPUT piCx AS INTEGER, INPUT piCy AS INTEGER, INPUT piA AS INTEGER, INPUT piB AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = piCy - piB TO piCy + piB:
            DO x = piCx - piA TO piCx + piA:
                IF (x - piCx) * (x - piCx) * piB * piB + (y - piCy) * (y - piCy) * piA * piA <= piA * piA * piB * piB AND poTerrain:InBounds(x, y) THEN
                    poTerrain:SetSolid(x, y, TRUE).
            END.
        END.
    END METHOD.

    /* Picks places for piCount buddies to start. Each is a column and the row of the ground it stands on (the first ground pixel under its
       feet): the ground is nearly flat under the 9 pixels the buddy covers (no more than 3 pixels of difference), there are 14 pixels of air
       above, it is well above the water, away from the open edges, and at least piSpacing columns from every other spot. The spots come in
       no order. Throws if the land has no room. */
    METHOD PUBLIC VOID FindSpots(INPUT poTerrain AS Terrain, INPUT poRandom AS IRandom, INPUT piCount AS INTEGER, INPUT piSpacing AS INTEGER,
                                 OUTPUT paX AS INTEGER EXTENT, OUTPUT paY AS INTEGER EXTENT):
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE nc     AS INTEGER NO-UNDO.
        DEFINE VARIABLE nm     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE s      AS INTEGER NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE left   AS INTEGER NO-UNDO.
        DEFINE VARIABLE span   AS INTEGER NO-UNDO.
        DEFINE VARIABLE lo     AS INTEGER NO-UNDO.
        DEFINE VARIABLE hi     AS INTEGER NO-UNDO.
        DEFINE VARIABLE centre AS INTEGER NO-UNDO.
        DEFINE VARIABLE best   AS INTEGER NO-UNDO.
        DEFINE VARIABLE bestD  AS INTEGER NO-UNDO.
        DEFINE VARIABLE tmp    AS INTEGER NO-UNDO.
        DEFINE VARIABLE ok     AS LOGICAL NO-UNDO.
        DEFINE VARIABLE tops   AS INTEGER NO-UNDO EXTENT 384.
        DEFINE VARIABLE cand   AS INTEGER NO-UNDO EXTENT 384.
        DEFINE VARIABLE near   AS INTEGER NO-UNDO EXTENT 384.
        IF piCount < 1 THEN UNDO, THROW NEW GridException("A map needs at least one start spot").
        EXTENT(paX) = piCount.
        EXTENT(paY) = piCount.
        DO x = 0 TO Terrain:Width() - 1:
            tops[x + 1] = poTerrain:FirstGround(x).
        END.
        left = EdgeGap + 8.
        span = Terrain:Width() - 2 * left.
        DO x = left TO left + span - 1:
            IF tops[x + 1] <> ? AND FlatUnder(tops, x, tops[x + 1]) THEN ASSIGN nc = nc + 1
                                                                            cand[nc] = x.
        END.
        /* the width is cut into one slot for each buddy, and each takes a flat column from the middle of its slot (a random one), or failing that the nearest
           flat column to its middle that is far enough from the others, so the buddies are spread over the whole land */
        DO s = 0 TO piCount - 1:
            lo = left + INTEGER(TRUNCATE(s * span / piCount, 0)).
            hi = left + INTEGER(TRUNCATE((s + 1) * span / piCount, 0)) - 1.
            centre = INTEGER(TRUNCATE((lo + hi) / 2, 0)).
            nm = 0.
            best = ?.
            bestD = 0.
            DO j = 1 TO nc:
                ok = TRUE.
                DO k = 1 TO n:
                    IF ABSOLUTE(paX[k] - cand[j]) < piSpacing THEN ok = FALSE.
                END.
                IF NOT ok THEN NEXT.
                IF ABSOLUTE(cand[j] - centre) <= INTEGER(TRUNCATE((hi - lo) * 0.3, 0)) THEN ASSIGN nm = nm + 1
                                                                                                    near[nm] = cand[j].
                IF best = ? OR ABSOLUTE(cand[j] - centre) < bestD THEN ASSIGN best = cand[j]
                                                                              bestD = ABSOLUTE(cand[j] - centre).
            END.
            IF nm > 0 THEN best = near[poRandom:NextInt(nm) + 1].
            IF best = ? THEN UNDO, THROW NEW GridException("The land has no room for " + STRING(piCount) + " buddies").
            n = n + 1.
            paX[n] = best.
            paY[n] = tops[best + 1].
        END.
        /* the slots are in order along the land, so shuffle the spots to let the teams mix */
        DO j = piCount TO 2 BY -1:
            k = poRandom:NextInt(j) + 1.
            tmp = paX[j].
            paX[j] = paX[k].
            paX[k] = tmp.
            tmp = paY[j].
            paY[j] = paY[k].
            paY[k] = tmp.
        END.
    END METHOD.

    /* Whether a buddy fits standing with its feet in the middle of column piX on the ground at row piY: the first ground of each of the 9
       columns it covers is within 3 pixels of the others (so there is nothing above it but sky, because the first ground is the highest),
       and it is not too high up or too near the water. */
    METHOD PUBLIC LOGICAL Standable(INPUT poTerrain AS Terrain, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE tops AS INTEGER NO-UNDO EXTENT 384.
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DO x = MAXIMUM(piX - 4, 0) TO MINIMUM(piX + 4, Terrain:Width() - 1):
            tops[x + 1] = poTerrain:FirstGround(x).
        END.
        RETURN FlatUnder(tops, piX, piY).
    END METHOD.

    /* Standable, from a list of the first ground of every column (unknown for a column with none). */
    METHOD PRIVATE LOGICAL FlatUnder(INPUT paTops AS INTEGER EXTENT, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE topY AS INTEGER NO-UNDO.
        DEFINE VARIABLE lo   AS INTEGER NO-UNDO.
        DEFINE VARIABLE hi   AS INTEGER NO-UNDO.
        IF piY > 205 OR piY < 20 THEN RETURN FALSE.
        IF piX < 4 OR piX > Terrain:Width() - 5 THEN RETURN FALSE.
        lo = piY.
        hi = piY.
        DO x = piX - 4 TO piX + 4:
            topY = paTops[x + 1].
            IF topY = ? THEN RETURN FALSE.
            lo = MINIMUM(lo, topY).
            hi = MAXIMUM(hi, topY).
        END.
        RETURN hi - lo <= 6.
    END METHOD.

END CLASS.
