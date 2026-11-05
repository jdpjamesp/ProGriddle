/* The numbers of Xevious, in one place. The field is 224 x 256 pixels (14 x 16 tiles of 16 pixels) and the game works in pixels.
   The ground scrolls down the screen by 2 pixels in every 3 frames, and a stage is 120 rows of ground long. Points, hit points
   and the stage at which each enemy first appears are here too, so they are easy to correct. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousRules FINAL:

    METHOD PUBLIC STATIC INTEGER FieldWidth():
        RETURN 224.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FieldHeight():
        RETURN 256.
    END METHOD.

    /* Pixels in the side of a ground tile, and tiles across. */
    METHOD PUBLIC STATIC INTEGER Tile():
        RETURN 16.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Cols():
        RETURN 14.
    END METHOD.

    /* Stages in the game before it goes round again, harder. */
    METHOD PUBLIC STATIC INTEGER Stages():
        RETURN 16.
    END METHOD.

    /* Rows of ground in one stage. */
    METHOD PUBLIC STATIC INTEGER StageRows():
        RETURN 120.
    END METHOD.

    /* The ground scrolls ScrollNum pixels in every ScrollDen frames. */
    METHOD PUBLIC STATIC INTEGER ScrollNum():
        RETURN 2.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ScrollDen():
        RETURN 3.
    END METHOD.

    /* True for a stage with the mothership at its end (every fourth stage). */
    METHOD PUBLIC STATIC LOGICAL HasBoss(INPUT piStage AS INTEGER):
        RETURN piStage MODULO 4 = 0.
    END METHOD.

    /* Bombs on its core that the mothership takes. */
    METHOD PUBLIC STATIC INTEGER BossHp():
        RETURN 3.
    END METHOD.

    /* The stage a number of 1 up goes to, in the 16 the game has: 17 is 1 again. */
    METHOD PUBLIC STATIC INTEGER StageOf(INPUT piStage AS INTEGER):
        RETURN (piStage - 1) MODULO Stages() + 1.
    END METHOD.

    /* How many times round the 16 stages the game has been (0 the first time). */
    METHOD PUBLIC STATIC INTEGER LapOf(INPUT piStage AS INTEGER):
        RETURN INTEGER(TRUNCATE((piStage - 1) / Stages(), 0)).
    END METHOD.

    /* ---- the ship ---- */

    /* Pixels the ship moves each frame on each axis, and the side of its picture. */
    METHOD PUBLIC STATIC INTEGER PlayerSpeed():
        RETURN 2.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER PlayerSize():
        RETURN 16.
    END METHOD.

    /* The side of the square of the ship that can be hit (the middle of its picture). */
    METHOD PUBLIC STATIC INTEGER PlayerBox():
        RETURN 8.
    END METHOD.

    /* Zapper shots in the air at once, pixels a frame, and frames between two shots. */
    METHOD PUBLIC STATIC INTEGER ZapMax():
        RETURN 2.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ZapSpeed():
        RETURN 6.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ZapCooldown():
        RETURN 7.
    END METHOD.

    /* How far above the middle of the ship the sight is, and how many frames the bomb takes to land. */
    METHOD PUBLIC STATIC INTEGER SightDistance():
        RETURN 88.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BombFlight():
        RETURN 26.
    END METHOD.

    /* Half the side of the square a bomb blast reaches, and the frames it lasts. */
    METHOD PUBLIC STATIC INTEGER BlastRadius():
        RETURN 8.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BlastFrames():
        RETURN 14.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER StartLives():
        RETURN 3.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER DyingFrames():
        RETURN 90.
    END METHOD.

    /* Frames the ship cannot be hit after it comes back. */
    METHOD PUBLIC STATIC INTEGER ProtectFrames():
        RETURN 150.
    END METHOD.

    /* Frames the bonus screen of a finished stage lasts. */
    METHOD PUBLIC STATIC INTEGER ClearFrames():
        RETURN 300.
    END METHOD.

    /* After a death the stage goes back to the last multiple of this many pixels of ground. */
    METHOD PUBLIC STATIC INTEGER CheckpointEvery():
        RETURN 480.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ExtraLifeFirst():
        RETURN 20000.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ExtraLifeEvery():
        RETURN 60000.
    END METHOD.

    /* Points for each percent of the ground targets destroyed in a stage. */
    METHOD PUBLIC STATIC INTEGER BonusPerPercent():
        RETURN 30.
    END METHOD.

    /* ---- the enemies ---- */

    METHOD PUBLIC STATIC INTEGER AirPoints(INPUT poKind AS XeviousAir):
        CASE poKind:
            WHEN XeviousAir:Toroid THEN RETURN 30.
            WHEN XeviousAir:Torkan THEN RETURN 50.
            WHEN XeviousAir:GiddoSpario THEN RETURN 10.
            WHEN XeviousAir:Kapi THEN RETURN 1000.
            WHEN XeviousAir:Jara THEN RETURN 150.
            WHEN XeviousAir:Zakato THEN RETURN 300.
            WHEN XeviousAir:Terrazi THEN RETURN 100.
            WHEN XeviousAir:Bacura THEN RETURN 1000.
            OTHERWISE UNDO, THROW NEW GridException("No points for air enemy " + STRING(poKind)).
        END CASE.
    END METHOD.

    /* The first stage at which an air enemy can appear. */
    METHOD PUBLIC STATIC INTEGER AirFirstStage(INPUT poKind AS XeviousAir):
        CASE poKind:
            WHEN XeviousAir:Toroid THEN RETURN 1.
            WHEN XeviousAir:Torkan OR WHEN XeviousAir:GiddoSpario THEN RETURN 2.
            WHEN XeviousAir:Kapi OR WHEN XeviousAir:Zakato OR WHEN XeviousAir:Bacura THEN RETURN 3.
            WHEN XeviousAir:Jara THEN RETURN 4.
            WHEN XeviousAir:Terrazi THEN RETURN 5.
            OTHERWISE UNDO, THROW NEW GridException("No first stage for air enemy " + STRING(poKind)).
        END CASE.
    END METHOD.

    /* Shots a Bacura must take, without a break, before it gives up. */
    METHOD PUBLIC STATIC INTEGER BacuraHits():
        RETURN 40.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER GroundPoints(INPUT poKind AS XeviousGround):
        CASE poKind:
            WHEN XeviousGround:Barra THEN RETURN 10.
            WHEN XeviousGround:Zolbak THEN RETURN 20.
            WHEN XeviousGround:Logram THEN RETURN 100.
            WHEN XeviousGround:Derota THEN RETURN 200.
            WHEN XeviousGround:Grobda THEN RETURN 200.
            WHEN XeviousGround:GaruBarra THEN RETURN 300.
            WHEN XeviousGround:GaruZakato THEN RETURN 400.
            WHEN XeviousGround:Sol THEN RETURN 2000.
            WHEN XeviousGround:Flag THEN RETURN 0.
            OTHERWISE UNDO, THROW NEW GridException("No points for ground target " + STRING(poKind)).
        END CASE.
    END METHOD.

    /* Bombs a ground target takes. */
    METHOD PUBLIC STATIC INTEGER GroundHp(INPUT poKind AS XeviousGround):
        CASE poKind:
            WHEN XeviousGround:GaruBarra OR WHEN XeviousGround:GaruZakato THEN RETURN 2.
            OTHERWISE RETURN 1.
        END CASE.
    END METHOD.

    /* The first stage at which a ground target is put on the map. */
    METHOD PUBLIC STATIC INTEGER GroundFirstStage(INPUT poKind AS XeviousGround):
        CASE poKind:
            WHEN XeviousGround:Barra OR WHEN XeviousGround:Zolbak OR WHEN XeviousGround:Sol OR WHEN XeviousGround:Flag THEN RETURN 1.
            WHEN XeviousGround:Logram THEN RETURN 2.
            WHEN XeviousGround:Derota THEN RETURN 3.
            WHEN XeviousGround:Grobda THEN RETURN 4.
            WHEN XeviousGround:GaruBarra THEN RETURN 5.
            WHEN XeviousGround:GaruZakato THEN RETURN 7.
            OTHERWISE UNDO, THROW NEW GridException("No first stage for ground target " + STRING(poKind)).
        END CASE.
    END METHOD.

    /* How common a ground target is among the others (0 for the hidden ones, which are put on the map by hand). */
    METHOD PUBLIC STATIC INTEGER GroundWeight(INPUT poKind AS XeviousGround):
        CASE poKind:
            WHEN XeviousGround:Barra THEN RETURN 40.
            WHEN XeviousGround:Zolbak THEN RETURN 20.
            WHEN XeviousGround:Logram THEN RETURN 15.
            WHEN XeviousGround:Derota THEN RETURN 10.
            WHEN XeviousGround:Grobda THEN RETURN 8.
            WHEN XeviousGround:GaruBarra THEN RETURN 5.
            WHEN XeviousGround:GaruZakato THEN RETURN 4.
            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    /* Whether a ground target is hidden until a bomb lands on it. */
    METHOD PUBLIC STATIC LOGICAL IsHidden(INPUT poKind AS XeviousGround):
        RETURN poKind = XeviousGround:Sol OR poKind = XeviousGround:Flag.
    END METHOD.

    /* The most enemy bullets in the air at once. */
    METHOD PUBLIC STATIC INTEGER MostBullets():
        RETURN 24.
    END METHOD.

    /* The speed of an enemy bullet, in eighths of a pixel a frame, at a stage. */
    METHOD PUBLIC STATIC INTEGER BulletSpeed(INPUT piStage AS INTEGER):
        RETURN 10 + MINIMUM(6, INTEGER(TRUNCATE(StageOf(piStage) / 3, 0))) + 2 * LapOf(piStage).
    END METHOD.

    /* Frames before the next wave of air enemies starts, at a stage. */
    METHOD PUBLIC STATIC INTEGER WaveDelay(INPUT piStage AS INTEGER):
        RETURN MAXIMUM(50, 140 - 3 * StageOf(piStage) - 20 * LapOf(piStage)).
    END METHOD.

END CLASS.
