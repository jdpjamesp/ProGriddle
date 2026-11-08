/* The numbers of FOR EACH, in one place: speeds (a percentage of full speed), how long phantoms stay rolled back, the waves of
   scatter and chase, how many bits Dibby must eat to let each phantom out of the lobby or to wind Mary up, the bonus items and the
   points. Time is in frames at 60 a second. A level of less than 1 is refused by every table that depends on the level; a level
   beyond the last one in a table is read as the last one. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachRules FINAL:

    /* seconds Dibby's enemies stay rolled back on levels 1 to 18 (from 19 on, none), and how many times they flash */
    &SCOPED-DEFINE ROLLBACK-SECONDS "6,5,4,3,2,5,2,2,1,5,2,1,1,3,1,1,0,1"
    &SCOPED-DEFINE FLASHES "5,5,5,5,5,5,5,5,3,5,5,3,3,5,3,3,0,3"

    /* Refuses a level below 1. */
    METHOD PRIVATE STATIC VOID CheckLevel(INPUT piLevel AS INTEGER):
        IF piLevel = ? OR piLevel < 1 THEN UNDO, THROW NEW GridException("A level is 1 or more").
    END METHOD.

    /* Which row of the three-way speed tables a level is in: 1 for level 1, 2 for levels 2 to 4, 3 for 5 on. */
    METHOD PRIVATE STATIC INTEGER Band(INPUT piLevel AS INTEGER):
        CheckLevel(piLevel).
        IF piLevel = 1 THEN RETURN 1.
        IF piLevel <= 4 THEN RETURN 2.
        RETURN 3.
    END METHOD.

    /* ---------------------------------- lives and points ---------------------------------- */

    METHOD PUBLIC STATIC INTEGER StartLives():
        RETURN 3.
    END METHOD.

    /* The score at which a life is added, once. */
    METHOD PUBLIC STATIC INTEGER ExtraLifeScore():
        RETURN 10000.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BitPoints():
        RETURN 10.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER CommitPoints():
        RETURN 50.
    END METHOD.

    /* The frames Dibby stops for after eating: one for a bit, three for a commit token. */
    METHOD PUBLIC STATIC INTEGER EatPauseFrames(INPUT poKind AS TileKind):
        CASE poKind:
            WHEN TileKind:Bit THEN RETURN 1.
            WHEN TileKind:Commit THEN RETURN 3.
            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    /* The points for the nth phantom eaten on one commit token: 200, 400, 800, 1600. */
    METHOD PUBLIC STATIC INTEGER PhantomPoints(INPUT piNth AS INTEGER):
        IF piNth = ? OR piNth < 1 OR piNth > 4 THEN UNDO, THROW NEW GridException("Only 4 phantoms can be eaten on one commit token").
        RETURN INTEGER(200 * EXP(2, piNth - 1)).
    END METHOD.

    /* ---------------------------------- speeds, as a percentage of full speed ---------------------------------- */

    /* Dibby's speed: 80 on level 1, 90 on levels 2 to 4, 100 from 5 to 20 and 90 from 21. */
    METHOD PUBLIC STATIC INTEGER DibbySpeed(INPUT piLevel AS INTEGER):
        CASE Band(piLevel):
            WHEN 1 THEN RETURN 80.
            WHEN 2 THEN RETURN 90.
            OTHERWISE RETURN (IF piLevel >= 21 THEN 90 ELSE 100).
        END CASE.
    END METHOD.

    /* A phantom's speed: always under Dibby's (80, 90, 100 and 90 again from level 21 for the same levels), so he can get away from one that is behind him. */
    METHOD PUBLIC STATIC INTEGER PhantomSpeed(INPUT piLevel AS INTEGER):
        CASE Band(piLevel):
            WHEN 1 THEN RETURN 70.
            WHEN 2 THEN RETURN 80.
            OTHERWISE RETURN (IF piLevel >= 21 THEN 85 ELSE 90).
        END CASE.
    END METHOD.

    /* A phantom in a tunnel lane. */
    METHOD PUBLIC STATIC INTEGER TunnelSpeed(INPUT piLevel AS INTEGER):
        CASE Band(piLevel):
            WHEN 1 THEN RETURN 40.
            WHEN 2 THEN RETURN 45.
            OTHERWISE RETURN 50.
        END CASE.
    END METHOD.

    /* Dibby while the phantoms are rolled back. */
    METHOD PUBLIC STATIC INTEGER DibbyRollbackSpeed(INPUT piLevel AS INTEGER):
        CASE Band(piLevel):
            WHEN 1 THEN RETURN 90.
            WHEN 2 THEN RETURN 95.
            OTHERWISE RETURN 100.
        END CASE.
    END METHOD.

    /* A rolled back phantom. */
    METHOD PUBLIC STATIC INTEGER PhantomRollbackSpeed(INPUT piLevel AS INTEGER):
        CASE Band(piLevel):
            WHEN 1 THEN RETURN 50.
            WHEN 2 THEN RETURN 55.
            OTHERWISE RETURN 60.
        END CASE.
    END METHOD.

    /* Mary's speed in her first (1) or second (2) stage of rage: the second only just as fast as Dibby, never faster. */
    METHOD PUBLIC STATIC INTEGER RageSpeed(INPUT piLevel AS INTEGER, INPUT piStage AS INTEGER):
        IF piStage <> 1 AND piStage <> 2 THEN UNDO, THROW NEW GridException("Rage has stages 1 and 2").
        CASE Band(piLevel):
            WHEN 1 THEN RETURN (IF piStage = 1 THEN 75 ELSE 80).
            WHEN 2 THEN RETURN (IF piStage = 1 THEN 85 ELSE 90).
            OTHERWISE DO:
                IF piLevel >= 21 THEN RETURN (IF piStage = 1 THEN 85 ELSE 90).
                RETURN (IF piStage = 1 THEN 95 ELSE 100).
            END.
        END CASE.
    END METHOD.

    /* The bits and commit tokens left when Mary reaches the stage of rage: 20 and 10 on level 1, and more as the levels go up. */
    METHOD PUBLIC STATIC INTEGER RageBits(INPUT piLevel AS INTEGER, INPUT piStage AS INTEGER):
        VAR INTEGER stageOne.
        IF piStage <> 1 AND piStage <> 2 THEN UNDO, THROW NEW GridException("Rage has stages 1 and 2").
        CheckLevel(piLevel).
        IF piLevel = 1 THEN stageOne = 20.
        ELSE IF piLevel = 2 THEN stageOne = 30.
        ELSE IF piLevel <= 5 THEN stageOne = 40.
        ELSE IF piLevel <= 8 THEN stageOne = 50.
        ELSE IF piLevel <= 11 THEN stageOne = 60.
        ELSE IF piLevel <= 14 THEN stageOne = 80.
        ELSE IF piLevel <= 18 THEN stageOne = 100.
        ELSE stageOne = 120.
        RETURN (IF piStage = 1 THEN stageOne ELSE INTEGER(stageOne / 2)).
    END METHOD.

    /* ---------------------------------- rolling back ---------------------------------- */

    /* How long phantoms stay rolled back after a commit token: 6 seconds on level 1, less after, none from level 19. */
    METHOD PUBLIC STATIC INTEGER RollbackFrames(INPUT piLevel AS INTEGER):
        CheckLevel(piLevel).
        IF piLevel > NUM-ENTRIES({&ROLLBACK-SECONDS}) THEN RETURN 0.
        RETURN 60 * INTEGER(ENTRY(piLevel, {&ROLLBACK-SECONDS})).
    END METHOD.

    /* How many times they flash in the last two seconds of it. */
    METHOD PUBLIC STATIC INTEGER FlashCount(INPUT piLevel AS INTEGER):
        CheckLevel(piLevel).
        IF piLevel > NUM-ENTRIES({&FLASHES}) THEN RETURN 0.
        RETURN INTEGER(ENTRY(piLevel, {&FLASHES})).
    END METHOD.

    /* ---------------------------------- the waves ---------------------------------- */

    /* How long wave 1 to 7 lasts, in frames. The odd waves scatter and the even ones chase. Wave 8 is a chase that never ends, so
       its length is unknown. */
    METHOD PUBLIC STATIC INTEGER WaveFrames(INPUT piLevel AS INTEGER, INPUT piWave AS INTEGER):
        IF piWave = ? OR piWave < 1 OR piWave > 8 THEN UNDO, THROW NEW GridException("There are waves 1 to 8").
        IF piWave = 8 THEN DO:
            CheckLevel(piLevel).
            RETURN ?.
        END.
        CASE Band(piLevel):
            WHEN 1 THEN RETURN INTEGER(ENTRY(piWave, "420,1200,420,1200,300,1200,300")).
            WHEN 2 THEN RETURN INTEGER(ENTRY(piWave, "420,1200,420,1200,300,61980,1")).
            OTHERWISE RETURN INTEGER(ENTRY(piWave, "300,1200,300,1200,300,62220,1")).
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC LOGICAL IsScatterWave(INPUT piWave AS INTEGER):
        RETURN piWave MODULO 2 = 1.
    END METHOD.

    /* ---------------------------------- the lobby ---------------------------------- */

    /* How many bits Dibby must have eaten on this level before the phantom leaves the lobby. */
    METHOD PUBLIC STATIC INTEGER LobbyLimit(INPUT piLevel AS INTEGER, INPUT poKind AS PhantomKind):
        CheckLevel(piLevel).
        IF piLevel = 1 THEN DO:
            CASE poKind:
                WHEN PhantomKind:Brian THEN RETURN 30.
                WHEN PhantomKind:Chip THEN RETURN 60.
                OTHERWISE RETURN 0.
            END CASE.
        END.
        IF piLevel = 2 AND poKind = PhantomKind:Chip THEN RETURN 50.
        RETURN 0.
    END METHOD.

    /* After a life is lost the phantoms leave on one count shared between them, from the life being lost. */
    METHOD PUBLIC STATIC INTEGER GlobalLimit(INPUT poKind AS PhantomKind):
        CASE poKind:
            WHEN PhantomKind:Rich THEN RETURN 7.
            WHEN PhantomKind:Brian THEN RETURN 17.
            WHEN PhantomKind:Chip THEN RETURN 32.
            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    /* Frames without eating after which the next phantom is let out whatever the counts say: 4 seconds, then 3 from level 5. */
    METHOD PUBLIC STATIC INTEGER LobbyIdleFrames(INPUT piLevel AS INTEGER):
        CheckLevel(piLevel).
        RETURN (IF piLevel <= 4 THEN 240 ELSE 180).
    END METHOD.

    /* ---------------------------------- bonus items ---------------------------------- */

    METHOD PUBLIC STATIC ItemKind ItemFor(INPUT piLevel AS INTEGER):
        CheckLevel(piLevel).
        IF piLevel <= 2 THEN RETURN ItemKind:GetEnum(piLevel).
        IF piLevel <= 4 THEN RETURN ItemKind:Key.
        IF piLevel <= 6 THEN RETURN ItemKind:Table.
        IF piLevel <= 8 THEN RETURN ItemKind:Query.
        IF piLevel <= 10 THEN RETURN ItemKind:Trigger.
        IF piLevel <= 12 THEN RETURN ItemKind:Lock.
        RETURN ItemKind:Server.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ItemPoints(INPUT poKind AS ItemKind):
        CASE poKind:
            WHEN ItemKind:Floppy THEN RETURN 100.
            WHEN ItemKind:Tape THEN RETURN 300.
            WHEN ItemKind:Key THEN RETURN 500.
            WHEN ItemKind:Table THEN RETURN 700.
            WHEN ItemKind:Query THEN RETURN 1000.
            WHEN ItemKind:Trigger THEN RETURN 2000.
            WHEN ItemKind:Lock THEN RETURN 3000.
            WHEN ItemKind:Server THEN RETURN 5000.
            OTHERWISE UNDO, THROW NEW GridException("A bonus item cannot be unknown").
        END CASE.
    END METHOD.

    /* The number of things eaten on a level at which the first (1) or second (2) item comes out: 70 and 170. */
    METHOD PUBLIC STATIC INTEGER ItemBitCount(INPUT piWhich AS INTEGER):
        CASE piWhich:
            WHEN 1 THEN RETURN 70.
            WHEN 2 THEN RETURN 170.
            OTHERWISE UNDO, THROW NEW GridException("An item comes out twice on a level").
        END CASE.
    END METHOD.

    /* How long an item stays out: about ten seconds. */
    METHOD PUBLIC STATIC INTEGER ItemFrames():
        RETURN 570.
    END METHOD.

    /* ---------------------------------- cartoons ---------------------------------- */

    /* The cartoon (1 to 3) that plays after the level, or 0 for none: after levels 2, 5, 9, 13 and 17. */
    METHOD PUBLIC STATIC INTEGER IntermissionAfter(INPUT piLevel AS INTEGER):
        CheckLevel(piLevel).
        CASE piLevel:
            WHEN 2 THEN RETURN 1.
            WHEN 5 THEN RETURN 2.
            WHEN 9 OR WHEN 13 OR WHEN 17 THEN RETURN 3.
            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

END CLASS.
