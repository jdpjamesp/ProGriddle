/* The numbers of Centipede, in one place. The board is 30 x 30 tiles of 8 pixels, and the game works in pixels (a tile is
   8 of them) so that everything moves smoothly. The shooter lives in the bottom rows, the player zone, and cannot leave it. */
USING Progress.Lang.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeRules FINAL:

    /* Tiles across and down. */
    METHOD PUBLIC STATIC INTEGER Cols():
        RETURN 30.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Rows():
        RETURN 30.
    END METHOD.

    /* Pixels in the side of a tile. */
    METHOD PUBLIC STATIC INTEGER Tile():
        RETURN 8.
    END METHOD.

    /* The width and height of the board in pixels. */
    METHOD PUBLIC STATIC INTEGER BoardPixels():
        RETURN Cols() * Tile().
    END METHOD.

    /* The first row of the player zone: the shooter moves in rows PlayerTop to Rows - 1. */
    METHOD PUBLIC STATIC INTEGER PlayerTop():
        RETURN 24.
    END METHOD.

    /* Hit points of a new mushroom. */
    METHOD PUBLIC STATIC INTEGER MushroomHp():
        RETURN 4.
    END METHOD.

    /* The segments of a wave, body and loose heads together. */
    METHOD PUBLIC STATIC INTEGER SegmentsPerWave():
        RETURN 12.
    END METHOD.

    /* The most loose heads a wave has, so the body is never shorter than four. */
    METHOD PUBLIC STATIC INTEGER MostExtraHeads():
        RETURN 8.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER StartLives():
        RETURN 3.
    END METHOD.

    /* A shooter is added each time the score passes a multiple of this. */
    METHOD PUBLIC STATIC INTEGER ExtraLifeEvery():
        RETURN 12000.
    END METHOD.

    /* The points of each thing shot. */
    METHOD PUBLIC STATIC INTEGER PointsSegment():
        RETURN 10.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PointsHead():
        RETURN 100.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PointsMushroom():
        RETURN 1.
    END METHOD.

    /* Each mushroom that is made whole again after a life is lost. */
    METHOD PUBLIC STATIC INTEGER PointsRepair():
        RETURN 5.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PointsFlea():
        RETURN 200.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PointsScorpion():
        RETURN 1000.
    END METHOD.

    /* The spider pays 900 close to the shooter, 600 a little way off and 300 far off (the distance is in pixels). */
    METHOD PUBLIC STATIC INTEGER PointsSpider(INPUT piDistance AS INTEGER):
        IF piDistance < 24 THEN RETURN 900.
        IF piDistance < 56 THEN RETURN 600.
        RETURN 300.
    END METHOD.

    /* Pixels a frame: the shooter, the shot, and the segments of wave piWave (2, then 3 from wave 4). */
    METHOD PUBLIC STATIC INTEGER PlayerSpeed():
        RETURN 3.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ShotSpeed():
        RETURN 8.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER SegmentSpeed(INPUT piWave AS INTEGER):
        RETURN (IF piWave >= 4 THEN 3 ELSE 2).
    END METHOD.

END CLASS.
