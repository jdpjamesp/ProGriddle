/* The numbers of Cuber, in one place, and the geometry of the pyramid. A lamp is named by its row (1 to 7, the apex is row 1) and
   its column (0 to row - 1). A halo is named the same way, one column outside the row: column -1 on the left and column Row on
   the right (rows 3, 4 and 5 have one each side). The picture is 256 x 256 pixels and a lamp is 32 x 32 on a pitch of 32 across
   and 24 down, so a lamp's top left is (128 - 16 * row + 32 * column, 48 + 24 * (row - 1)) and the middle of its top diamond, where
   everything that stands on it puts its feet, is 16 across and 8 down from there. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberRules FINAL:

    /* Rows of the pyramid, and lamps in all. */
    METHOD PUBLIC STATIC INTEGER Rows():
        RETURN 7.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER LampTotal():
        RETURN 28.
    END METHOD.

    /* The size of the picture, in pixels. */
    METHOD PUBLIC STATIC INTEGER CanvasSize():
        RETURN 256.
    END METHOD.

    /* The pixel of the top left of a lamp, and of its foot point (the middle of its top diamond). Row and column may be those of a halo. */
    METHOD PUBLIC STATIC INTEGER LampX(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        RETURN 128 - 16 * piRow + 32 * piCol.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER LampY(INPUT piRow AS INTEGER):
        RETURN 48 + 24 * (piRow - 1).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FootX(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        RETURN LampX(piRow, piCol) + 16.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FootY(INPUT piRow AS INTEGER):
        RETURN LampY(piRow) + 8.
    END METHOD.

    /* True when a row and column name a lamp of the pyramid. */
    METHOD PUBLIC STATIC LOGICAL IsLamp(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        RETURN piRow >= 1 AND piRow <= 7 AND piCol >= 0 AND piCol < piRow.
    END METHOD.

    /* The row and the column a hop in a direction leads to from a row and column (which may be off the pyramid). */
    METHOD PUBLIC STATIC INTEGER HopRow(INPUT piRow AS INTEGER, INPUT poDir AS CuberDir):
        CASE poDir:
            WHEN CuberDir:UpLeft OR WHEN CuberDir:UpRight THEN RETURN piRow - 1.
            OTHERWISE RETURN piRow + 1.
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER HopCol(INPUT piCol AS INTEGER, INPUT poDir AS CuberDir):
        CASE poDir:
            WHEN CuberDir:UpLeft THEN RETURN piCol - 1.
            WHEN CuberDir:DownRight THEN RETURN piCol + 1.
            OTHERWISE RETURN piCol.
        END CASE.
    END METHOD.

    /* The halos: six places, 1 to 6, row 3 left, row 3 right, row 4 left and so on. */
    METHOD PUBLIC STATIC INTEGER HaloSpots():
        RETURN 6.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER HaloRow(INPUT piSpot AS INTEGER):
        CheckSpot(piSpot).
        RETURN 3 + INTEGER(TRUNCATE((piSpot - 1) / 2, 0)).
    END METHOD.

    /* The column of a halo: -1 for the left ones, the row for the right ones. */
    METHOD PUBLIC STATIC INTEGER HaloCol(INPUT piSpot AS INTEGER):
        CheckSpot(piSpot).
        RETURN (IF (piSpot MODULO 2) = 1 THEN -1 ELSE HaloRow(piSpot)).
    END METHOD.

    /* The halo spot at a row and column, or 0 when there is none. */
    METHOD PUBLIC STATIC INTEGER HaloSpotAt(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        IF piRow < 3 OR piRow > 5 THEN RETURN 0.
        IF piCol = -1 THEN RETURN (piRow - 3) * 2 + 1.
        IF piCol = piRow THEN RETURN (piRow - 3) * 2 + 2.
        RETURN 0.
    END METHOD.

    /* Frames in a hop. */
    METHOD PUBLIC STATIC INTEGER HopFrames():
        RETURN 12.
    END METHOD.

    /* The height of a hop at frame piFrame of 12, in pixels: 0 at the ends and piHeight at the top. */
    METHOD PUBLIC STATIC INTEGER HopLift(INPUT piFrame AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN INTEGER(ROUND(piHeight * 4 * piFrame * (12 - piFrame) / 144.0, 0)).
    END METHOD.

    /* Frames Pip stands after landing before the next hop can start, and frames a wanted hop is remembered. */
    METHOD PUBLIC STATIC INTEGER LandingFrames():
        RETURN 2.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER WantFrames():
        RETURN 14.
    END METHOD.

    /* Frames of READY at the start of a life, of the hit, of the fall, of the ride on a halo and of the clear. */
    METHOD PUBLIC STATIC INTEGER ReadyFrames():
        RETURN 90.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER HitFrames():
        RETURN 58.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FallFrames():
        RETURN 70.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER RideFrames():
        RETURN 72.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ClearFrames():
        RETURN 180.
    END METHOD.

    /* Lives: spare Pips at the start (three Pips in all), and an extra one each time the score passes a multiple of this. */
    METHOD PUBLIC STATIC INTEGER StartLives():
        RETURN 2.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ExtraLifeEvery():
        RETURN 8000.
    END METHOD.

    /* The points. */
    METHOD PUBLIC STATIC INTEGER PointsLamp():
        RETURN 25.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PointsHalfLamp():
        RETURN 10.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PointsHalo():
        RETURN 50.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PointsFrost():
        RETURN 100.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PointsMoth():
        RETURN 300.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PointsCoil():
        RETURN 500.
    END METHOD.

    /* ---- what a level means: the rules change with the level, the speed with the level and the round ---- */

    /* Hits a lamp takes to light: one on levels 1 and 2, two from level 3. */
    METHOD PUBLIC STATIC INTEGER HitsToLight(INPUT piLevel AS INTEGER):
        RETURN (IF piLevel >= 3 THEN 2 ELSE 1).
    END METHOD.

    /* True from level 5: Pip landing on a lamp that is lit already puts it back a step. */
    METHOD PUBLIC STATIC LOGICAL UndoOnLand(INPUT piLevel AS INTEGER):
        RETURN piLevel >= 5.
    END METHOD.

    /* True from level 2: the moths come, and put out the lamps they land on. */
    METHOD PUBLIC STATIC LOGICAL MothsCome(INPUT piLevel AS INTEGER):
        RETURN piLevel >= 2.
    END METHOD.

    /* The halos in a round: four on levels 1 and 2, three on 3 and 4, two after. */
    METHOD PUBLIC STATIC INTEGER HalosIn(INPUT piLevel AS INTEGER):
        RETURN (IF piLevel <= 2 THEN 4 ELSE IF piLevel <= 4 THEN 3 ELSE 2).
    END METHOD.

    /* How hard the game is, 0 to 12, from the level (1 up) and the round (1 to 4). Everything quickens with it. */
    METHOD PUBLIC STATIC INTEGER Tempo(INPUT piLevel AS INTEGER, INPUT piRound AS INTEGER):
        RETURN MINIMUM(12, (piLevel - 1) * 3 + piRound - 1).
    END METHOD.

    /* Frames an enemy stands between hops: the Coil, the balls (Seed, Thorn, Frost) and the moths. */
    METHOD PUBLIC STATIC INTEGER CoilRest(INPUT piTempo AS INTEGER):
        RETURN 28 - piTempo.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BallRest(INPUT piTempo AS INTEGER):
        RETURN 22 - INTEGER(TRUNCATE(piTempo / 2, 0)).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER MothRest(INPUT piTempo AS INTEGER):
        RETURN 44 - piTempo.
    END METHOD.

    /* Frames before the first seed drops, and between a Thorn, a Frost and a moth and the next one. */
    METHOD PUBLIC STATIC INTEGER SeedDelay():
        RETURN 150.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ThornEvery(INPUT piTempo AS INTEGER):
        RETURN 300 - 12 * piTempo.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FrostEvery():
        RETURN 900.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER MothEvery(INPUT piTempo AS INTEGER):
        RETURN 420 - 10 * piTempo.
    END METHOD.

    /* The chance in a hundred that the Coil hops the way that brings it nearest to Pip (otherwise it hops at random). */
    METHOD PUBLIC STATIC INTEGER CoilAim(INPUT piTempo AS INTEGER):
        RETURN 65 + 2 * piTempo.
    END METHOD.

    /* Frames the enemies stay frozen. */
    METHOD PUBLIC STATIC INTEGER FreezeFrames(INPUT piTempo AS INTEGER):
        RETURN MAXIMUM(90, 240 - 12 * piTempo).
    END METHOD.

    /* The number of enemy places in a game, and frames a seed takes to hatch. */
    METHOD PUBLIC STATIC INTEGER EnemySlots():
        RETURN 8.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER HatchFrames():
        RETURN 30.
    END METHOD.

    METHOD PRIVATE STATIC VOID CheckSpot(INPUT piSpot AS INTEGER):
        IF piSpot = ? OR piSpot < 1 OR piSpot > 6 THEN UNDO, THROW NEW GridException("A halo spot is 1 to 6, not " + STRING(piSpot)).
    END METHOD.

END CLASS.
