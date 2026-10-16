/* The ground of Blast Buddies: a 384 x 240 map of solid and air, one byte to a pixel (0 for air, else 1 plus the scorch ring step 0 to 3), and
   the colour rule of the design (section 2.1) that says what a solid pixel looks like in the theme the map was made in. Depth is how many
   solid pixels lie directly above a pixel before the first air, so it is worked out from the map and the colour changes by itself when ground
   is blown away. A pixel outside the map is air, except that below the bottom row it counts as solid. The map frees its memory in Dispose
   (a destructor does it as a safety net), and its owner calls Dispose. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.Terrain FINAL:

    &SCOPED-DEFINE MAP-WIDTH 384
    &SCOPED-DEFINE MAP-HEIGHT 240

    DEFINE PRIVATE VARIABLE mMap     AS MEMPTR    NO-UNDO.
    DEFINE PRIVATE VARIABLE mRockY   AS INTEGER   NO-UNDO EXTENT {&MAP-WIDTH}.
    DEFINE PRIVATE VARIABLE mSpeckle AS CHARACTER NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mTop1    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mTop2    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mTop3    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSoil    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSoilSp  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mDeep    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mDeepSp  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mRock    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mRockSp  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mEdge    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mScorch1 AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mScorch2 AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mScorch3 AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mBlast3  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mBlast4  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mBlast5  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mCrumbs  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mCrumbX  AS INTEGER   NO-UNDO EXTENT 1000.
    DEFINE PRIVATE VARIABLE mCrumbY  AS INTEGER   NO-UNDO EXTENT 1000.
    DEFINE PRIVATE VARIABLE mCrumbC  AS INTEGER   NO-UNDO EXTENT 1000.
    DEFINE PRIVATE VARIABLE mDirtyL  AS INTEGER   NO-UNDO INITIAL ?.
    DEFINE PRIVATE VARIABLE mDirtyT  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mDirtyR  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mDirtyB  AS INTEGER   NO-UNDO.

    /* The theme the map was made in. */
    DEFINE PUBLIC PROPERTY MapTheme AS Theme NO-UNDO GET. PRIVATE SET.

    CONSTRUCTOR PUBLIC Terrain(INPUT poTheme AS Theme):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poTheme) THEN UNDO, THROW NEW GridException("A map needs a theme").
        MapTheme = poTheme.
        SET-SIZE(mMap) = {&MAP-WIDTH} * {&MAP-HEIGHT}.
        mTop1 = TerrainThemes:Colour(poTheme, ThemeKey:Top1).
        mTop2 = TerrainThemes:Colour(poTheme, ThemeKey:Top2).
        mTop3 = TerrainThemes:Colour(poTheme, ThemeKey:Top3).
        mSoil = TerrainThemes:Colour(poTheme, ThemeKey:Soil).
        mSoilSp = TerrainThemes:Colour(poTheme, ThemeKey:SoilSpeck).
        mDeep = TerrainThemes:Colour(poTheme, ThemeKey:Deep).
        mDeepSp = TerrainThemes:Colour(poTheme, ThemeKey:DeepSpeck).
        mRock = TerrainThemes:Colour(poTheme, ThemeKey:Rock).
        mRockSp = TerrainThemes:Colour(poTheme, ThemeKey:RockSpeck).
        mEdge = TerrainThemes:Colour(poTheme, ThemeKey:Edge).
        mScorch1 = TerrainThemes:Colour(poTheme, ThemeKey:Scorch1).
        mScorch2 = TerrainThemes:Colour(poTheme, ThemeKey:Scorch2).
        mScorch3 = TerrainThemes:Colour(poTheme, ThemeKey:Scorch3).
        mBlast3 = ColourMath:FromHex(ENTRY(3, BuddiesLook:ToneRow("Blast"))).
        mBlast4 = ColourMath:FromHex(ENTRY(4, BuddiesLook:ToneRow("Blast"))).
        mBlast5 = ColourMath:FromHex(ENTRY(5, BuddiesLook:ToneRow("Blast"))).
        /* rockY(x) = 200 + round(3 sin(x / 23)): x / 23 radians is x * 0.44285 of a 64 step turn */
        DO x = 0 TO {&MAP-WIDTH} - 1:
            mRockY[x + 1] = 200 + ROUND(3 * Heading:Sin(INTEGER(ROUND(x * 0.44285, 0))) / Heading:Scale(), 0).
        END.
        mSpeckle[1]  = "................".
        mSpeckle[2]  = "..+.........+...".
        mSpeckle[3]  = ".++.....+.......".
        mSpeckle[4]  = ".......++.......".
        mSpeckle[5]  = "...........+....".
        mSpeckle[6]  = "....+......++...".
        mSpeckle[7]  = "................".
        mSpeckle[8]  = "+.........+.....".
        mSpeckle[9]  = ".........++.....".
        mSpeckle[10] = "...+............".
        mSpeckle[11] = "..++.......+....".
        mSpeckle[12] = ".............+..".
        mSpeckle[13] = "......+.....++..".
        mSpeckle[14] = ".....++.........".
        mSpeckle[15] = "................".
        mSpeckle[16] = ".+.........+....".
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC Terrain():
        Dispose().
    END DESTRUCTOR.

    /* Frees the map. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        SET-SIZE(mMap) = 0.
    END METHOD.

    /* The width of every map, in pixels. */
    METHOD PUBLIC STATIC INTEGER Width():
        RETURN {&MAP-WIDTH}.
    END METHOD.

    /* The height of every map, in pixels. */
    METHOD PUBLIC STATIC INTEGER Height():
        RETURN {&MAP-HEIGHT}.
    END METHOD.

    METHOD PUBLIC LOGICAL InBounds(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN piX >= 0 AND piX < {&MAP-WIDTH} AND piY >= 0 AND piY < {&MAP-HEIGHT}.
    END METHOD.

    /* Whether a pixel is ground. Outside the map is air, except below the bottom row, which is solid. */
    METHOD PUBLIC LOGICAL IsSolid(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piY >= {&MAP-HEIGHT} THEN RETURN TRUE.
        IF NOT InBounds(piX, piY) THEN RETURN FALSE.
        RETURN GET-BYTE(mMap, piY * {&MAP-WIDTH} + piX + 1) > 0.
    END METHOD.

    /* Makes a pixel ground or air. Making it air also takes its scorch away, and making ground of a pixel that is ground already changes nothing. */
    METHOD PUBLIC VOID SetSolid(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plSolid AS LOGICAL):
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        IF NOT InBounds(piX, piY) THEN UNDO, THROW NEW GridException("The pixel " + STRING(piX) + "," + STRING(piY) + " is outside the map").
        p = piY * {&MAP-WIDTH} + piX + 1.
        IF NOT plSolid THEN PUT-BYTE(mMap, p) = 0.
        ELSE IF GET-BYTE(mMap, p) = 0 THEN PUT-BYTE(mMap, p) = 1.
    END METHOD.

    /* Makes the rectangle from (piX1, piY1) to (piX2, piY2), both included, ground or air. The part outside the map is skipped. */
    METHOD PUBLIC VOID FillRect(INPUT piX1 AS INTEGER, INPUT piY1 AS INTEGER, INPUT piX2 AS INTEGER, INPUT piY2 AS INTEGER, INPUT plSolid AS LOGICAL):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = MAXIMUM(piY1, 0) TO MINIMUM(piY2, {&MAP-HEIGHT} - 1):
            DO x = MAXIMUM(piX1, 0) TO MINIMUM(piX2, {&MAP-WIDTH} - 1):
                SetSolid(x, y, plSolid).
            END.
        END.
    END METHOD.

    /* How many pixels are ground. */
    METHOD PUBLIC INTEGER SolidCount():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 1 TO {&MAP-WIDTH} * {&MAP-HEIGHT}:
            IF GET-BYTE(mMap, i) > 0 THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* The scorch ring step of a pixel: 1 to 3, or 0 for none (air has none). */
    METHOD PUBLIC INTEGER ScorchStep(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT InBounds(piX, piY) THEN RETURN 0.
        RETURN MAXIMUM(GET-BYTE(mMap, piY * {&MAP-WIDTH} + piX + 1) - 1, 0).
    END METHOD.

    /* Puts a pixel of ground in a scorch ring step (0 to 3, 0 taking the scorch away). Air cannot be scorched. */
    METHOD PUBLIC VOID SetScorch(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piStep AS INTEGER):
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        IF piStep < 0 OR piStep > 3 THEN UNDO, THROW NEW GridException("A scorch step is 0 to 3, not " + STRING(piStep)).
        IF NOT InBounds(piX, piY) THEN UNDO, THROW NEW GridException("The pixel " + STRING(piX) + "," + STRING(piY) + " is outside the map").
        p = piY * {&MAP-WIDTH} + piX + 1.
        IF GET-BYTE(mMap, p) > 0 THEN PUT-BYTE(mMap, p) = 1 + piStep.
    END METHOD.

    /* Blows a hole: every pixel within the radius of (piCx, piCy) becomes air, and every ground pixel from there to 3 pixels further out
       gets a scorch ring step (1, 2 or 3 by how far past the edge it is), keeping the smaller step if it had one. Distances are compared as
       squares, so there is no square root. The box that has to be coloured again (the design's re-shade box) is added to the dirty box.
       Returns how many pixels of ground were removed. */
    METHOD PUBLIC INTEGER Carve(INPUT piCx AS INTEGER, INPUT piCy AS INTEGER, INPUT piRadius AS INTEGER):
        DEFINE VARIABLE x       AS INTEGER NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy2     AS INTEGER NO-UNDO.
        DEFINE VARIABLE d2      AS INTEGER NO-UNDO.
        DEFINE VARIABLE p       AS INTEGER NO-UNDO.
        DEFINE VARIABLE b       AS INTEGER NO-UNDO.
        DEFINE VARIABLE stp     AS INTEGER NO-UNDO.
        DEFINE VARIABLE r2      AS INTEGER NO-UNDO.
        DEFINE VARIABLE r2a     AS INTEGER NO-UNDO.
        DEFINE VARIABLE r2b     AS INTEGER NO-UNDO.
        DEFINE VARIABLE r2c     AS INTEGER NO-UNDO.
        DEFINE VARIABLE removed AS INTEGER NO-UNDO.
        IF piRadius < 1 THEN UNDO, THROW NEW GridException("A blast has a radius of at least 1").
        r2 = piRadius * piRadius.
        r2a = (piRadius + 1) * (piRadius + 1).
        r2b = (piRadius + 2) * (piRadius + 2).
        r2c = (piRadius + 3) * (piRadius + 3).
        DO y = MAXIMUM(piCy - piRadius - 3, 0) TO MINIMUM(piCy + piRadius + 3, {&MAP-HEIGHT} - 1):
            dy2 = (y - piCy) * (y - piCy).
            DO x = MAXIMUM(piCx - piRadius - 3, 0) TO MINIMUM(piCx + piRadius + 3, {&MAP-WIDTH} - 1):
                p = y * {&MAP-WIDTH} + x + 1.
                b = GET-BYTE(mMap, p).
                IF b = 0 THEN NEXT.
                d2 = dy2 + (x - piCx) * (x - piCx).
                IF d2 <= r2 THEN DO:
                    PUT-BYTE(mMap, p) = 0.
                    removed = removed + 1.
                END.
                ELSE IF d2 <= r2c THEN DO:
                    stp = (IF d2 <= r2a THEN 1 ELSE IF d2 <= r2b THEN 2 ELSE 3).
                    IF b = 1 OR stp < b - 1 THEN PUT-BYTE(mMap, p) = 1 + stp.
                END.
            END.
        END.
        MarkDirty(piCx - piRadius - 4, piCy - piRadius - 4, piCx + piRadius + 4, piCy + piRadius + 18).
        RETURN removed.
    END METHOD.

    /* The crumb rule: after a blast at (piCx, piCy) with a radius, flood fills (4 way) from every ground pixel in the box 8 pixels wider than
       the blast each way, and every piece of ground of 24 pixels or fewer is turned to air, so no specks float in the sky. Bigger pieces stay,
       a floating island is part of the fun. The pixels that were removed can be read with CrumbX, CrumbY and CrumbColour (the colour the
       pixel had) until the next call, so the painter can throw them out as debris. Returns how many were removed. */
    METHOD PUBLIC INTEGER Crumble(INPUT piCx AS INTEGER, INPUT piCy AS INTEGER, INPUT piRadius AS INTEGER):
        DEFINE VARIABLE bl   AS INTEGER NO-UNDO.
        DEFINE VARIABLE bt   AS INTEGER NO-UNDO.
        DEFINE VARIABLE br   AS INTEGER NO-UNDO.
        DEFINE VARIABLE bb   AS INTEGER NO-UNDO.
        DEFINE VARIABLE bw   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE q    AS INTEGER NO-UNDO.
        DEFINE VARIABLE nq   AS INTEGER NO-UNDO.
        DEFINE VARIABLE qx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE qy   AS INTEGER NO-UNDO.
        DEFINE VARIABLE nx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE ny   AS INTEGER NO-UNDO.
        DEFINE VARIABLE k    AS INTEGER NO-UNDO.
        DEFINE VARIABLE j    AS INTEGER NO-UNDO.
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE head AS INTEGER NO-UNDO.
        DEFINE VARIABLE vi   AS INTEGER NO-UNDO.
        DEFINE VARIABLE v    AS INTEGER NO-UNDO.
        DEFINE VARIABLE big  AS LOGICAL NO-UNDO.
        DEFINE VARIABLE dup  AS LOGICAL NO-UNDO.
        DEFINE VARIABLE minX AS INTEGER NO-UNDO.
        DEFINE VARIABLE maxX AS INTEGER NO-UNDO.
        DEFINE VARIABLE maxY AS INTEGER NO-UNDO.
        DEFINE VARIABLE minY AS INTEGER NO-UNDO.
        DEFINE VARIABLE comp AS INTEGER NO-UNDO EXTENT 24.
        DEFINE VARIABLE mark AS MEMPTR  NO-UNDO.
        IF piRadius < 1 THEN UNDO, THROW NEW GridException("A blast has a radius of at least 1").
        mCrumbs = 0.
        bl = MAXIMUM(piCx - piRadius - 8, 0).
        bt = MAXIMUM(piCy - piRadius - 8, 0).
        br = MINIMUM(piCx + piRadius + 8, {&MAP-WIDTH} - 1).
        bb = MINIMUM(piCy + piRadius + 8, {&MAP-HEIGHT} - 1).
        IF bl > br OR bt > bb THEN RETURN 0.
        bw = br - bl + 1.
        minX = {&MAP-WIDTH}.
        minY = {&MAP-HEIGHT}.
        maxX = -1.
        maxY = -1.
        SET-SIZE(mark) = bw * (bb - bt + 1).
        DO ON ERROR UNDO, THROW:
            DO y = bt TO bb:
                DO x = bl TO br:
                    IF GET-BYTE(mMap, y * {&MAP-WIDTH} + x + 1) = 0 OR GET-BYTE(mark, (y - bt) * bw + x - bl + 1) <> 0 THEN NEXT.
                    /* grow the piece from this pixel, a breadth first fill that gives up when the piece passes 24 pixels */
                    n = 1.
                    head = 1.
                    big = FALSE.
                    comp[1] = y * {&MAP-WIDTH} + x + 1.
                    PUT-BYTE(mark, (y - bt) * bw + x - bl + 1) = 2.
                    DO WHILE head <= n AND NOT big:
                        q = comp[head] - 1.
                        head = head + 1.
                        qx = q MODULO {&MAP-WIDTH}.
                        qy = INTEGER(TRUNCATE(q / {&MAP-WIDTH}, 0)).
                        DO k = 1 TO 4:
                            CASE k:
                                WHEN 1 THEN ASSIGN nx = qx - 1 ny = qy.
                                WHEN 2 THEN ASSIGN nx = qx + 1 ny = qy.
                                WHEN 3 THEN ASSIGN nx = qx ny = qy - 1.
                                OTHERWISE ASSIGN nx = qx ny = qy + 1.
                            END CASE.
                            IF nx < 0 OR nx >= {&MAP-WIDTH} OR ny < 0 OR ny >= {&MAP-HEIGHT} THEN NEXT.
                            nq = ny * {&MAP-WIDTH} + nx + 1.
                            IF GET-BYTE(mMap, nq) = 0 THEN NEXT.
                            IF nx >= bl AND nx <= br AND ny >= bt AND ny <= bb THEN DO:
                                /* inside the box, the marks say it all: 2 is this piece, 1 is a piece already known to be big */
                                vi = (ny - bt) * bw + nx - bl + 1.
                                v = GET-BYTE(mark, vi).
                                IF v = 2 THEN NEXT.
                                IF v = 1 THEN big = TRUE.
                                ELSE IF n = 24 THEN DO:
                                    PUT-BYTE(mark, vi) = 1.
                                    big = TRUE.
                                END.
                                ELSE DO:
                                    PUT-BYTE(mark, vi) = 2.
                                    n = n + 1.
                                    comp[n] = nq.
                                END.
                            END.
                            ELSE DO:
                                dup = FALSE.
                                DO j = 1 TO n:
                                    IF comp[j] = nq THEN dup = TRUE.
                                END.
                                IF dup THEN NEXT.
                                IF n = 24 THEN big = TRUE.
                                ELSE ASSIGN n = n + 1
                                            comp[n] = nq.
                            END.
                            IF big THEN LEAVE.
                        END.
                    END.
                    IF big THEN DO:
                        /* a big piece stays: its pixels are marked as known so nothing is grown from them again */
                        DO j = 1 TO n:
                            q = comp[j] - 1.
                            nx = q MODULO {&MAP-WIDTH}.
                            ny = INTEGER(TRUNCATE(q / {&MAP-WIDTH}, 0)).
                            IF nx >= bl AND nx <= br AND ny >= bt AND ny <= bb THEN PUT-BYTE(mark, (ny - bt) * bw + nx - bl + 1) = 1.
                        END.
                        NEXT.
                    END.
                    /* a small piece: note the colours while it is all there, then turn it to air */
                    DO j = 1 TO n:
                        q = comp[j] - 1.
                        nx = q MODULO {&MAP-WIDTH}.
                        ny = INTEGER(TRUNCATE(q / {&MAP-WIDTH}, 0)).
                        IF mCrumbs < EXTENT(mCrumbX) THEN DO:
                            mCrumbs = mCrumbs + 1.
                            mCrumbX[mCrumbs] = nx.
                            mCrumbY[mCrumbs] = ny.
                            mCrumbC[mCrumbs] = ShadeAt(nx, ny).
                        END.
                        minX = MINIMUM(minX, nx).
                        maxX = MAXIMUM(maxX, nx).
                        minY = MINIMUM(minY, ny).
                        maxY = MAXIMUM(maxY, ny).
                    END.
                    DO j = 1 TO n:
                        PUT-BYTE(mMap, comp[j]) = 0.
                    END.
                END.
            END.
            FINALLY:
                SET-SIZE(mark) = 0.
            END FINALLY.
        END.
        IF maxX >= 0 THEN MarkDirty(minX - 1, minY - 1, maxX + 1, maxY + 18).
        RETURN mCrumbs.
    END METHOD.

    /* How many pixels the last Crumble removed. */
    METHOD PUBLIC INTEGER CrumbCount():
        RETURN mCrumbs.
    END METHOD.

    /* The column of crumb i (1 to the count Crumble returned) of the last Crumble. */
    METHOD PUBLIC INTEGER CrumbX(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > mCrumbs THEN UNDO, THROW NEW GridException("There is no crumb " + STRING(piIndex)).
        RETURN mCrumbX[piIndex].
    END METHOD.

    /* The row of crumb i of the last Crumble. */
    METHOD PUBLIC INTEGER CrumbY(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > mCrumbs THEN UNDO, THROW NEW GridException("There is no crumb " + STRING(piIndex)).
        RETURN mCrumbY[piIndex].
    END METHOD.

    /* The colour crumb i of the last Crumble had before it was removed. */
    METHOD PUBLIC INTEGER CrumbColour(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > mCrumbs THEN UNDO, THROW NEW GridException("There is no crumb " + STRING(piIndex)).
        RETURN mCrumbC[piIndex].
    END METHOD.

    /* Grows the dirty box to hold a rectangle, clipped to the map. */
    METHOD PRIVATE VOID MarkDirty(INPUT piL AS INTEGER, INPUT piT AS INTEGER, INPUT piR AS INTEGER, INPUT piB AS INTEGER):
        piL = MAXIMUM(piL, 0).
        piT = MAXIMUM(piT, 0).
        piR = MINIMUM(piR, {&MAP-WIDTH} - 1).
        piB = MINIMUM(piB, {&MAP-HEIGHT} - 1).
        IF mDirtyL = ? THEN
            ASSIGN mDirtyL = piL
                   mDirtyT = piT
                   mDirtyR = piR
                   mDirtyB = piB.
        ELSE
            ASSIGN mDirtyL = MINIMUM(mDirtyL, piL)
                   mDirtyT = MINIMUM(mDirtyT, piT)
                   mDirtyR = MAXIMUM(mDirtyR, piR)
                   mDirtyB = MAXIMUM(mDirtyB, piB).
    END METHOD.

    /* Whether ground has been blown away since the last ClearDirty, so some colours are out of date. */
    METHOD PUBLIC LOGICAL HasDirty():
        RETURN mDirtyL <> ?.
    END METHOD.

    /* The edges of the box (both included) that has to be coloured again by ShadeAt, or unknown when nothing is dirty. */
    METHOD PUBLIC INTEGER DirtyLeft():
        RETURN mDirtyL.
    END METHOD.

    METHOD PUBLIC INTEGER DirtyTop():
        RETURN (IF mDirtyL = ? THEN ? ELSE mDirtyT).
    END METHOD.

    METHOD PUBLIC INTEGER DirtyRight():
        RETURN (IF mDirtyL = ? THEN ? ELSE mDirtyR).
    END METHOD.

    METHOD PUBLIC INTEGER DirtyBottom():
        RETURN (IF mDirtyL = ? THEN ? ELSE mDirtyB).
    END METHOD.

    /* Says the colours are up to date again. */
    METHOD PUBLIC VOID ClearDirty():
        mDirtyL = ?.
    END METHOD.

    /* The colour of a scorch ring pixel piAgeMs after the blast: it glows in the Blast ramp for 200 ms (step 1 tone 3, step 2 tone 4, step 3
       tone 5), then each step moves one colour cooler every 200 ms until at 600 ms it has its own scorch colour. */
    METHOD PUBLIC INTEGER ScorchColour(INPUT piStep AS INTEGER, INPUT piAgeMs AS INTEGER):
        DEFINE VARIABLE stage AS INTEGER NO-UNDO.
        IF piStep < 1 OR piStep > 3 THEN UNDO, THROW NEW GridException("A scorch step is 1 to 3, not " + STRING(piStep)).
        stage = MINIMUM(MAXIMUM(INTEGER(TRUNCATE(piAgeMs / 200, 0)), 0), 3).
        CASE piStep:
            WHEN 1 THEN
                CASE stage:
                    WHEN 0 THEN RETURN mBlast3.
                    WHEN 1 THEN RETURN mBlast4.
                    WHEN 2 THEN RETURN mBlast5.
                    OTHERWISE RETURN mScorch1.
                END CASE.
            WHEN 2 THEN
                CASE stage:
                    WHEN 0 THEN RETURN mBlast4.
                    WHEN 1 THEN RETURN mBlast5.
                    OTHERWISE RETURN mScorch2.
                END CASE.
            OTHERWISE
                CASE stage:
                    WHEN 0 THEN RETURN mBlast5.
                    OTHERWISE RETURN mScorch3.
                END CASE.
        END CASE.
    END METHOD.

    /* The number of ground pixels directly above a pixel before the first air (the top of a column is 0), or unknown for a pixel that is air. */
    METHOD PUBLIC INTEGER Depth(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE d AS INTEGER NO-UNDO.
        IF NOT IsSolid(piX, piY) OR NOT InBounds(piX, piY) THEN RETURN ?.
        DO WHILE piY - d - 1 >= 0 AND GET-BYTE(mMap, (piY - d - 1) * {&MAP-WIDTH} + piX + 1) > 0:
            d = d + 1.
        END.
        RETURN d.
    END METHOD.

    /* The row of the first ground going down a column from the sky, or unknown if the column has none (or is outside the map). */
    METHOD PUBLIC INTEGER FirstGround(INPUT piX AS INTEGER):
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DEFINE VARIABLE e AS INTEGER NO-UNDO.
        IF piX < 0 OR piX >= {&MAP-WIDTH} THEN RETURN ?.
        e = {&MAP-WIDTH} * {&MAP-HEIGHT}.
        DO p = piX + 1 TO e BY {&MAP-WIDTH}:
            IF GET-BYTE(mMap, p) > 0 THEN RETURN INTEGER(TRUNCATE((p - 1) / {&MAP-WIDTH}, 0)).
        END.
        RETURN ?.
    END METHOD.

    /* The row where the bedrock starts in a column: 200 plus a slow wave of up to 3 either way. */
    METHOD PUBLIC INTEGER RockY(INPUT piX AS INTEGER):
        IF piX < 0 OR piX >= {&MAP-WIDTH} THEN UNDO, THROW NEW GridException("The column " + STRING(piX) + " is outside the map").
        RETURN mRockY[piX + 1].
    END METHOD.

    /* Whether the fixed speckle tile has a stone at a pixel (the tile is fixed to the screen, not to the ground). */
    METHOD PUBLIC LOGICAL Speckled(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN SUBSTRING(mSpeckle[(piY MODULO 16) + 1], (piX MODULO 16) + 1, 1) = "+".
    END METHOD.

    /* The colour (0xRRGGBB) of the ground at a pixel by the rule of the design, or unknown for air. This is the busiest method of the
       painter after a blast, so it reads the map directly instead of calling IsSolid and Depth. */
    METHOD PUBLIC INTEGER ShadeAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE p  AS INTEGER NO-UNDO.
        DEFINE VARIABLE b  AS INTEGER NO-UNDO.
        DEFINE VARIABLE d  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sp AS LOGICAL NO-UNDO.
        IF piX < 0 OR piX >= {&MAP-WIDTH} OR piY < 0 OR piY >= {&MAP-HEIGHT} THEN RETURN ?.
        p = piY * {&MAP-WIDTH} + piX + 1.
        b = GET-BYTE(mMap, p).
        IF b = 0 THEN RETURN ?.
        CASE b:
            WHEN 2 THEN RETURN mScorch1.
            WHEN 3 THEN RETURN mScorch2.
            WHEN 4 THEN RETURN mScorch3.
        END CASE.
        /* the depth, counted no further than 14, which is as deep as the colour bands go */
        DO WHILE d < 14 AND piY > d AND GET-BYTE(mMap, p - ({&MAP-WIDTH} * (d + 1))) > 0:
            d = d + 1.
        END.
        CASE d:
            WHEN 0 THEN RETURN mTop1.
            WHEN 1 THEN RETURN mTop2.
            WHEN 2 OR WHEN 3 THEN RETURN mTop3.
        END CASE.
        IF piX = 0 OR piX = {&MAP-WIDTH} - 1 THEN RETURN mEdge.
        IF GET-BYTE(mMap, p - 1) = 0 OR GET-BYTE(mMap, p + 1) = 0 THEN RETURN mEdge.
        IF piY < {&MAP-HEIGHT} - 1 AND GET-BYTE(mMap, p + {&MAP-WIDTH}) = 0 THEN RETURN mEdge.
        sp = SUBSTRING(mSpeckle[(piY MODULO 16) + 1], (piX MODULO 16) + 1, 1) = "+".
        IF piY >= mRockY[piX + 1] THEN RETURN (IF sp THEN mRockSp ELSE mRock).
        IF d < 14 THEN RETURN (IF sp THEN mSoilSp ELSE mSoil).
        RETURN (IF sp THEN mDeepSp ELSE mDeep).
    END METHOD.

END CLASS.
