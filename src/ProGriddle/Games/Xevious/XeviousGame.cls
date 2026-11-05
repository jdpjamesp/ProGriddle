/* The rules of Xevious, as a real time game that runs frame by frame (a frame is a sixtieth of a second: Advance makes one, and
   Tick turns the milliseconds a clock gives it into frames, scaled by SpeedPercent). A ship flies up a scrolling land. It has two
   weapons: the Zapper shoots the enemies in the air, and the Blaster drops a bomb on the sight, a mark a fixed way ahead of the
   ship, which hits the targets on the ground. The game works in pixels on a field of 224 x 256 and knows nothing about drawing.

   Rules and numbers (see XeviousRules for all of them):
   - The ship moves 2 pixels a frame in eight directions. The Zapper has at most 2 shots in the air, a shot flies 6 pixels a frame
     and a new one can go after 7 frames. The Blaster has one bomb in the air at a time: it lands on the sight (88 pixels ahead)
     26 frames after it is dropped, and bursts for 14 frames. A bomb touches nothing in the air, and a shot touches nothing on the
     ground.
   - The ground scrolls 2 pixels in 3 frames. A stage is 120 rows of ground. Its ground targets (XeviousMap) are the same every
     time. A target takes a bomb or two. The Sol (a hidden tower) and the Flag are not seen: a bomb that lands on one finds it.
     A Sol is worth 2000 and a Flag is an extra ship.
   - Air enemies come in waves, each kind of enemy from its own stage on (XeviousMotion flies them). The Bacura cannot be killed
     by the Zapper, which only pushes it back, until it has taken 40 shots. A Zakato appears near the ship and bursts into a ring
     of bullets. Giddo Spario, ground turrets and the mothership shoot at the ship.
   - Touching an enemy or a bullet loses the ship. The stage goes back to the last checkpoint (every 480 pixels of ground) and the
     ship comes back protected for 150 frames. Three ships. An extra ship at 20000 and 60000 points and every 60000 after that.
   - A stage ends when its ground has gone by. Every fourth stage ends with the mothership, which only the Blaster hurts (3 hits
     on its core). Then a bonus is counted for the percent of the ground targets destroyed. After stage 16 it goes round again,
     faster and with more bullets.
   - The title and game over screens wait for the fire keys, which have to be let go and pressed again.

   Counters (ZapsFired, AirKills and so on) only go up, so a cue source can compare them with the ones it last saw. Frames counts
   every frame ever made and PhaseFrames the frames of the current phase, so a painter can animate as a function of them.
   Randomness comes from the IRandom given to the constructor. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    /* the most time one Tick will count, and the most frames it will make for it */
    &SCOPED-DEFINE MOST-MS 100
    &SCOPED-DEFINE MOST-FRAMES 6
    /* room for the things that move */
    &SCOPED-DEFINE AIR-MAX 24
    &SCOPED-DEFINE GROUND-MAX 28
    &SCOPED-DEFINE BULLET-MAX 24
    &SCOPED-DEFINE FX-MAX 24
    &SCOPED-DEFINE ZAP-MAX 2

    DEFINE PRIVATE VARIABLE mRandom    AS IRandom NO-UNDO.
    DEFINE PRIVATE VARIABLE mAcc       AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice    AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE mFireReady AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mNextExtra AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mScrollAcc AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mNextRow   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mMaxRow    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLandOff   AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mStageStart AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mStageSols AS INTEGER NO-UNDO.
    /* the ship, the Zapper and the Blaster */
    DEFINE PRIVATE VARIABLE mPx        AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mPy        AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mProtect   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mZapCool   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mZapOn     AS LOGICAL NO-UNDO EXTENT {&ZAP-MAX}.
    DEFINE PRIVATE VARIABLE mZapX      AS INTEGER NO-UNDO EXTENT {&ZAP-MAX}.
    DEFINE PRIVATE VARIABLE mZapY      AS INTEGER NO-UNDO EXTENT {&ZAP-MAX}.
    DEFINE PRIVATE VARIABLE mBombOn    AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mBombT     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBombSx    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBombSy    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBombTx    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBombTy    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBurstOn   AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mBurstT    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBurstX    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBurstY    AS INTEGER NO-UNDO.
    /* the air enemies: where they began (the column of its anchor and the row of its start), the age in frames, which side a Torkan
       came from, the column a Terrazi was aimed at, how far a Bacura has been pushed back, and where each is now */
    DEFINE PRIVATE VARIABLE mAirOn     AS LOGICAL NO-UNDO EXTENT {&AIR-MAX}.
    DEFINE PRIVATE VARIABLE mAirKind   AS INTEGER NO-UNDO EXTENT {&AIR-MAX}.
    DEFINE PRIVATE VARIABLE mAirA      AS INTEGER NO-UNDO EXTENT {&AIR-MAX}.
    DEFINE PRIVATE VARIABLE mAirY0     AS INTEGER NO-UNDO EXTENT {&AIR-MAX}.
    DEFINE PRIVATE VARIABLE mAirAge    AS INTEGER NO-UNDO EXTENT {&AIR-MAX}.
    DEFINE PRIVATE VARIABLE mAirWay    AS INTEGER NO-UNDO EXTENT {&AIR-MAX}.
    DEFINE PRIVATE VARIABLE mAirAim    AS INTEGER NO-UNDO EXTENT {&AIR-MAX}.
    DEFINE PRIVATE VARIABLE mAirPush   AS INTEGER NO-UNDO EXTENT {&AIR-MAX}.
    DEFINE PRIVATE VARIABLE mAirX      AS INTEGER NO-UNDO EXTENT {&AIR-MAX}.
    DEFINE PRIVATE VARIABLE mAirY      AS INTEGER NO-UNDO EXTENT {&AIR-MAX}.
    /* the ground targets: 0 for none, 1 standing, 2 destroyed (a scorch that scrolls away) */
    DEFINE PRIVATE VARIABLE mGrState   AS INTEGER NO-UNDO EXTENT {&GROUND-MAX}.
    DEFINE PRIVATE VARIABLE mGrKind    AS INTEGER NO-UNDO EXTENT {&GROUND-MAX}.
    DEFINE PRIVATE VARIABLE mGrX       AS INTEGER NO-UNDO EXTENT {&GROUND-MAX}.
    DEFINE PRIVATE VARIABLE mGrY       AS INTEGER NO-UNDO EXTENT {&GROUND-MAX}.
    DEFINE PRIVATE VARIABLE mGrT       AS INTEGER NO-UNDO EXTENT {&GROUND-MAX}.
    DEFINE PRIVATE VARIABLE mGrHp      AS INTEGER NO-UNDO EXTENT {&GROUND-MAX}.
    DEFINE PRIVATE VARIABLE mGrWay     AS INTEGER NO-UNDO EXTENT {&GROUND-MAX}.
    /* enemy bullets, in eighths of a pixel */
    DEFINE PRIVATE VARIABLE mBuOn      AS LOGICAL NO-UNDO EXTENT {&BULLET-MAX}.
    DEFINE PRIVATE VARIABLE mBuX       AS INTEGER NO-UNDO EXTENT {&BULLET-MAX}.
    DEFINE PRIVATE VARIABLE mBuY       AS INTEGER NO-UNDO EXTENT {&BULLET-MAX}.
    DEFINE PRIVATE VARIABLE mBuVx      AS INTEGER NO-UNDO EXTENT {&BULLET-MAX}.
    DEFINE PRIVATE VARIABLE mBuVy      AS INTEGER NO-UNDO EXTENT {&BULLET-MAX}.
    /* effects for a painter: the kind (-1 for none), where, the frame it began and a number to show */
    DEFINE PRIVATE VARIABLE mFxKind    AS INTEGER NO-UNDO EXTENT {&FX-MAX} INITIAL -1.
    DEFINE PRIVATE VARIABLE mFxX       AS INTEGER NO-UNDO EXTENT {&FX-MAX}.
    DEFINE PRIVATE VARIABLE mFxY       AS INTEGER NO-UNDO EXTENT {&FX-MAX}.
    DEFINE PRIVATE VARIABLE mFxStart   AS INTEGER NO-UNDO EXTENT {&FX-MAX}.
    DEFINE PRIVATE VARIABLE mFxValue   AS INTEGER NO-UNDO EXTENT {&FX-MAX}.
    DEFINE PRIVATE VARIABLE mFxNext    AS INTEGER NO-UNDO INITIAL 1.
    /* the mothership */
    DEFINE PRIVATE VARIABLE mBossOn    AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mBossSpawned AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mBossDone  AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mBossX     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBossY     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBossHp    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBossT     AS INTEGER NO-UNDO.
    /* the wave being sent: what kind, how many to come, frames between them, frames to the next, where the first goes, the step
       from one to the next, which one it is, and which side (for a Torkan). mWaveTimer counts down to the next wave. */
    DEFINE PRIVATE VARIABLE mQKind     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mQLeft     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mQGap      AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mQTimer    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mQX        AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mQDx       AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mQIndex    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mQWay      AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mWaveTimer AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mStageGround AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mStageKilled AS INTEGER NO-UNDO.

    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    /* How fast the game runs, as a percentage of the real 60 frames a second: 20 to 100. Everything slows together,
       so the game stays the same game and is only easier to play. */
    DEFINE PUBLIC PROPERTY SpeedPercent AS INTEGER NO-UNDO INITIAL 80
        GET.
        SET(INPUT piValue AS INTEGER):
            SpeedPercent = MINIMUM(100, MAXIMUM(20, piValue)).
        END SET.

    DEFINE PUBLIC PROPERTY Phase AS XeviousPhase NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Score AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The best score. The input sets it from the settings and keeps it when it is beaten; the game raises it as the score passes it. */
    DEFINE PUBLIC PROPERTY HiScore AS INTEGER NO-UNDO
        GET.
        SET(INPUT piValue AS INTEGER):
            IF piValue = ? OR piValue < 0 THEN UNDO, THROW NEW GridException("The best score is 0 or more, not " + STRING(piValue)).
            HiScore = piValue.
        END SET.

    /* Ships left, counting the one in play. */
    DEFINE PUBLIC PROPERTY Lives AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The stage, 1 up (17 is stage 1 again, the second time round). */
    DEFINE PUBLIC PROPERTY Stage AS INTEGER NO-UNDO INITIAL 1
        GET.
        PRIVATE SET.

    /* Frames made since the game was built, and frames since the phase began. */
    DEFINE PUBLIC PROPERTY Frames AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PhaseFrames AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Pixels of ground that have gone by in this stage. A painter draws the land from it. */
    DEFINE PUBLIC PROPERTY Distance AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The way the ship is being steered, from the input: -1, 0 or 1 across and down. */
    DEFINE PUBLIC PROPERTY MoveX AS INTEGER NO-UNDO
        GET.
        SET(INPUT piValue AS INTEGER):
            MoveX = MINIMUM(1, MAXIMUM(-1, piValue)).
        END SET.

    DEFINE PUBLIC PROPERTY MoveY AS INTEGER NO-UNDO
        GET.
        SET(INPUT piValue AS INTEGER):
            MoveY = MINIMUM(1, MAXIMUM(-1, piValue)).
        END SET.

    /* True while the Zapper key is down, and while the Blaster key is. */
    DEFINE PUBLIC PROPERTY ZapHeld AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY BombHeld AS LOGICAL NO-UNDO
        GET.
        SET.

    /* The counters, which only go up. */
    DEFINE PUBLIC PROPERTY ZapsFired AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY BombsDropped AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY BombBursts AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY AirKills AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY GroundKills AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY SolsFound AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY FlagsFound AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY EnemyShots AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Clangs AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY BossHits AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY BossKills AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Deaths AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ExtraLives AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY StagesCleared AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The percent of the stage's ground targets destroyed and the bonus it earned, as counted when the last stage ended. */
    DEFINE PUBLIC PROPERTY StagePercent AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY StageBonus AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* True while the ship can be flown (not breaking up, not between games). */
    DEFINE PUBLIC PROPERTY PlayerAlive AS LOGICAL NO-UNDO
        GET():
            RETURN Phase = XeviousPhase:Playing OR Phase = XeviousPhase:StageClear.
        END GET.

    /* ---- the ship and what it fires ---- */

    /* The ship's place in pixels (its top left). */
    DEFINE PUBLIC PROPERTY PlayerX AS INTEGER NO-UNDO
        GET():
            RETURN mPx.
        END GET.

    DEFINE PUBLIC PROPERTY PlayerY AS INTEGER NO-UNDO
        GET():
            RETURN mPy.
        END GET.

    /* Frames left in which the ship cannot be hit. */
    DEFINE PUBLIC PROPERTY Protection AS INTEGER NO-UNDO
        GET():
            RETURN mProtect.
        END GET.

    /* Zapper shots in the air now. */
    DEFINE PUBLIC PROPERTY ZapCount AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO {&ZAP-MAX}:
                IF mZapOn[i] THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    DEFINE PUBLIC PROPERTY BombActive AS LOGICAL NO-UNDO
        GET():
            RETURN mBombOn.
        END GET.

    /* Frames the bomb has been in the air. */
    DEFINE PUBLIC PROPERTY BombAge AS INTEGER NO-UNDO
        GET():
            RETURN mBombT.
        END GET.

    /* The bomb's place in the air (centre, in pixels), on its way from the ship to the place it will land. */
    DEFINE PUBLIC PROPERTY BombX AS INTEGER NO-UNDO
        GET():
            RETURN mBombSx + XeviousMotion:Div((mBombTx - mBombSx) * mBombT, XeviousRules:BombFlight()).
        END GET.

    DEFINE PUBLIC PROPERTY BombY AS INTEGER NO-UNDO
        GET():
            RETURN mBombSy + XeviousMotion:Div((mBombTy - mBombSy) * mBombT, XeviousRules:BombFlight()).
        END GET.

    DEFINE PUBLIC PROPERTY BurstActive AS LOGICAL NO-UNDO
        GET():
            RETURN mBurstOn.
        END GET.

    DEFINE PUBLIC PROPERTY BurstAge AS INTEGER NO-UNDO
        GET():
            RETURN mBurstT.
        END GET.

    DEFINE PUBLIC PROPERTY BurstX AS INTEGER NO-UNDO
        GET():
            RETURN mBurstX.
        END GET.

    DEFINE PUBLIC PROPERTY BurstY AS INTEGER NO-UNDO
        GET():
            RETURN mBurstY.
        END GET.

    /* The centre of the sight, which is the bomb's mark. */
    DEFINE PUBLIC PROPERTY SightX AS INTEGER NO-UNDO
        GET():
            RETURN mPx + 8.
        END GET.

    DEFINE PUBLIC PROPERTY SightY AS INTEGER NO-UNDO
        GET():
            RETURN MAXIMUM(4, mPy + 8 - XeviousRules:SightDistance()).
        END GET.

    /* True when a ground target that can be seen is under the sight. */
    DEFINE PUBLIC PROPERTY SightOnTarget AS LOGICAL NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DO i = 1 TO {&GROUND-MAX}:
                IF mGrState[i] = 1 AND NOT XeviousRules:IsHidden(XeviousGround:GetEnum(mGrKind[i]))
                   AND Overlap(SightX, SightY, 1, 1, mGrX[i] + GroundLeft(i), mGrY[i] + GroundTop(i), GroundWide(i), GroundHigh(i)) THEN RETURN TRUE.
            END.
            RETURN FALSE.
        END GET.

    /* ---- the enemies ---- */

    DEFINE PUBLIC PROPERTY AirSlots AS INTEGER NO-UNDO
        GET():
            RETURN {&AIR-MAX}.
        END GET.

    DEFINE PUBLIC PROPERTY GroundSlots AS INTEGER NO-UNDO
        GET():
            RETURN {&GROUND-MAX}.
        END GET.

    DEFINE PUBLIC PROPERTY BulletSlots AS INTEGER NO-UNDO
        GET():
            RETURN {&BULLET-MAX}.
        END GET.

    DEFINE PUBLIC PROPERTY FxSlots AS INTEGER NO-UNDO
        GET():
            RETURN {&FX-MAX}.
        END GET.

    /* Air enemies, enemy bullets and ground targets standing (hidden ones too) now. */
    DEFINE PUBLIC PROPERTY AirCount AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO {&AIR-MAX}:
                IF mAirOn[i] THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    DEFINE PUBLIC PROPERTY BulletCount AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO {&BULLET-MAX}:
                IF mBuOn[i] THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    DEFINE PUBLIC PROPERTY GroundCount AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO {&GROUND-MAX}:
                IF mGrState[i] = 1 THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* Frames since the stage began, and hidden towers found in it. */
    DEFINE PUBLIC PROPERTY StageAge AS INTEGER NO-UNDO
        GET():
            RETURN Frames - mStageStart.
        END GET.

    DEFINE PUBLIC PROPERTY StageSols AS INTEGER NO-UNDO
        GET():
            RETURN mStageSols.
        END GET.

    /* The ground targets that count towards the bonus (every one but the hidden ones) that have come on the map in this stage,
       and how many of those have been destroyed. */
    DEFINE PUBLIC PROPERTY StageGround AS INTEGER NO-UNDO
        GET():
            RETURN mStageGround.
        END GET.

    DEFINE PUBLIC PROPERTY StageKilled AS INTEGER NO-UNDO
        GET():
            RETURN mStageKilled.
        END GET.

    /* The mothership. */
    DEFINE PUBLIC PROPERTY BossActive AS LOGICAL NO-UNDO
        GET():
            RETURN mBossOn.
        END GET.

    DEFINE PUBLIC PROPERTY BossX AS INTEGER NO-UNDO
        GET():
            RETURN mBossX.
        END GET.

    DEFINE PUBLIC PROPERTY BossY AS INTEGER NO-UNDO
        GET():
            RETURN mBossY.
        END GET.

    DEFINE PUBLIC PROPERTY BossHpLeft AS INTEGER NO-UNDO
        GET():
            RETURN mBossHp.
        END GET.

    DEFINE PUBLIC PROPERTY BossAge AS INTEGER NO-UNDO
        GET():
            RETURN mBossT.
        END GET.

    /* The grid is a screen of ground tiles, 14 x 16, which the game itself does not use: the picture is drawn by a painter from
       what the game says (the land comes from XeviousMap). It must be 14 x 16 with one layer, "ground". */
    CONSTRUCTOR PUBLIC XeviousGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        SUPER("Xevious", poGrid).
        IF poGrid:Width <> XeviousRules:Cols() OR poGrid:Height <> 16 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A Xevious grid is &1 x 16", XeviousRules:Cols())).
        IF poGrid:Store:LayerCount <> 1 OR poGrid:Store:LayerName(1) <> "ground" THEN
            UNDO, THROW NEW GridException("A Xevious grid has one layer, ground").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Xevious game needs a random source").
        mRandom = poRandom.
        Initialise().
    END CONSTRUCTOR.

    /* Moves time on: the milliseconds become frames (at SpeedPercent of 60 a second) and each one is made. Returns true when
       a frame was made, so the controller redraws. A stall of more than 100 ms is cut to 100. Does nothing while Paused. */
    METHOD PUBLIC LOGICAL Tick(INPUT piElapsedMs AS INTEGER):
        DEFINE VARIABLE made AS INTEGER NO-UNDO.
        IF Paused OR piElapsedMs = ? OR piElapsedMs <= 0 THEN RETURN FALSE.
        mAcc = mAcc + INTEGER(ROUND(MINIMUM(piElapsedMs, {&MOST-MS}) * 0.6 * SpeedPercent, 0)).
        DO WHILE mAcc >= 1000 AND made < {&MOST-FRAMES}:
            mAcc = mAcc - 1000.
            Step().
            made = made + 1.
        END.
        IF mAcc >= 1000 THEN mAcc = 0.
        RETURN made > 0.
    END METHOD.

    /* One sixtieth of a second of the game. */
    METHOD PUBLIC VOID Advance():
        Step().
    END METHOD.

    /* Starts a new game from any phase: no score, three ships and stage 1. */
    METHOD PUBLIC VOID StartGame():
        Score = 0.
        Lives = XeviousRules:StartLives().
        mNotice = "".
        mNextExtra = XeviousRules:ExtraLifeFirst().
        mFireReady = FALSE.
        PlacePlayer(104, 208).
        mProtect = 0.
        BeginStage(1).
        SetPhase(XeviousPhase:Playing).
    END METHOD.

    /* A few words about what just happened (an extra ship, a stage), or "" for nothing. Taking them clears them. */
    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    /* Starts stage piStage (1 up) from its beginning: the land at its start, no enemies, the first wave in two seconds. The phase
       is left as it is. Throws GridException for a stage under 1. */
    METHOD PUBLIC VOID BeginStage(INPUT piStage AS INTEGER):
        IF piStage = ? OR piStage < 1 THEN UNDO, THROW NEW GridException("A stage is 1 or more, not " + STRING(piStage)).
        Stage = piStage.
        mLandOff = FALSE.
        mStageStart = Frames.
        mStageSols = 0.
        Distance = 0.
        mScrollAcc = 0.
        mMaxRow = -1.
        mNextRow = 0.
        mStageGround = 0.
        mStageKilled = 0.
        mBossSpawned = FALSE.
        mBossDone = FALSE.
        ClearAir().
        ClearGround().
        ClearBullets().
        ClearBoss().
        mBombOn = FALSE.
        mBurstOn = FALSE.
        mQLeft = 0.
        mWaveTimer = 120.
        Generate().
    END METHOD.

    /* ============================== setting up a scene ============================== */

    /* Puts the ship's top left at piX, piY pixels, brought inside the field. */
    METHOD PUBLIC VOID PlacePlayer(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        mPx = MINIMUM(XeviousRules:FieldWidth() - 16, MAXIMUM(0, piX)).
        mPy = MINIMUM(XeviousRules:FieldHeight() - 16, MAXIMUM(0, piY)).
    END METHOD.

    /* Takes every air enemy away, and the wave that was on its way. */
    METHOD PUBLIC VOID ClearAir():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&AIR-MAX}:
            mAirOn[i] = FALSE.
        END.
        mQLeft = 0.
    END METHOD.

    /* Stops new waves of air enemies coming, so a test or a rest can have the field to itself. */
    METHOD PUBLIC VOID StopWaves():
        mQLeft = 0.
        mWaveTimer = 1000000.
    END METHOD.

    /* Stops the land putting new ground targets on the map as it scrolls, so a scene keeps only what it was given. The next
       BeginStage starts it again. */
    METHOD PUBLIC VOID StopLand():
        mLandOff = TRUE.
    END METHOD.

    METHOD PUBLIC VOID ClearGround():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&GROUND-MAX}:
            mGrState[i] = 0.
        END.
    END METHOD.

    METHOD PUBLIC VOID ClearBullets():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&BULLET-MAX}:
            mBuOn[i] = FALSE.
        END.
    END METHOD.

    /* Takes the mothership away. */
    METHOD PUBLIC VOID ClearBoss():
        mBossOn = FALSE.
    END METHOD.

    /* Puts an air enemy of a kind with its left side at piX and its top at piY, at age 0. Throws GridException for a field that
       is full. */
    METHOD PUBLIC VOID SpawnAir(INPUT poKind AS XeviousAir, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT TrySpawnAir(poKind, piX, piY, 1, piX) THEN UNDO, THROW NEW GridException("The field is full of air enemies").
    END METHOD.

    /* Puts a ground target with its left side at piX and its top at piY. A hidden kind (Sol, Flag) is hidden. Throws GridException
       for a field that is full. */
    METHOD PUBLIC VOID PlaceGround(INPUT poKind AS XeviousGround, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT AddGround(poKind, piX, piY, FALSE) THEN UNDO, THROW NEW GridException("The field is full of ground targets").
    END METHOD.

    /* Puts the mothership out, at the top of the field, for a test or a rehearsal. */
    METHOD PUBLIC VOID SpawnBoss():
        ASSIGN mBossOn = TRUE
               mBossSpawned = TRUE
               mBossX = 96
               mBossY = -32
               mBossHp = XeviousRules:BossHp()
               mBossT = 0.
    END METHOD.

    /* Points for the score, which may bring an extra ship. */
    METHOD PUBLIC VOID AddScore(INPUT piPoints AS INTEGER):
        IF piPoints = ? OR piPoints < 0 THEN UNDO, THROW NEW GridException("Points are 0 or more, not " + STRING(piPoints)).
        Score = Score + piPoints.
        IF Score > HiScore THEN HiScore = Score.
        DO WHILE Score >= mNextExtra:
            Lives = Lives + 1.
            ExtraLives = ExtraLives + 1.
            mNotice = "EXTRA SHIP".
            IF mNextExtra = XeviousRules:ExtraLifeFirst() THEN mNextExtra = XeviousRules:ExtraLifeEvery().
            ELSE mNextExtra = mNextExtra + XeviousRules:ExtraLifeEvery().
        END.
    END METHOD.

    /* ============================== reading the scene ============================== */

    METHOD PUBLIC LOGICAL ZapActive(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= {&ZAP-MAX} THEN UNDO, THROW NEW GridException("There is no shot " + STRING(piIndex)).
        RETURN mZapOn[piIndex + 1].
    END METHOD.

    /* The top left of a Zapper shot, which is 4 pixels wide and 10 high. */
    METHOD PUBLIC INTEGER ZapX(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= {&ZAP-MAX} THEN UNDO, THROW NEW GridException("There is no shot " + STRING(piIndex)).
        RETURN mZapX[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER ZapY(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= {&ZAP-MAX} THEN UNDO, THROW NEW GridException("There is no shot " + STRING(piIndex)).
        RETURN mZapY[piIndex + 1].
    END METHOD.

    /* The air enemies are numbered from 0 to AirSlots - 1; a slot that is empty is not active. Each asks throw GridException for
       a number outside that. */
    METHOD PUBLIC LOGICAL AirActive(INPUT piIndex AS INTEGER):
        CheckAir(piIndex).
        RETURN mAirOn[piIndex + 1].
    END METHOD.

    METHOD PUBLIC XeviousAir AirKindAt(INPUT piIndex AS INTEGER):
        CheckAir(piIndex).
        RETURN XeviousAir:GetEnum(mAirKind[piIndex + 1]).
    END METHOD.

    /* The top left of an air enemy, whose picture is 16 x 16. */
    METHOD PUBLIC INTEGER AirX(INPUT piIndex AS INTEGER):
        CheckAir(piIndex).
        RETURN mAirX[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER AirY(INPUT piIndex AS INTEGER):
        CheckAir(piIndex).
        RETURN mAirY[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER AirAge(INPUT piIndex AS INTEGER):
        CheckAir(piIndex).
        RETURN mAirAge[piIndex + 1].
    END METHOD.

    /* The ground targets: 0 for an empty slot, 1 for one standing, 2 for one destroyed (a scorch, which scrolls away), 3 for a hidden
       tower that has been found (it shows for 24 frames and then bursts) and 4 for a pennant that has been found and waits to be
       flown over. */
    METHOD PUBLIC INTEGER GroundState(INPUT piIndex AS INTEGER):
        CheckGround(piIndex).
        RETURN mGrState[piIndex + 1].
    END METHOD.

    METHOD PUBLIC XeviousGround GroundKindAt(INPUT piIndex AS INTEGER):
        CheckGround(piIndex).
        RETURN XeviousGround:GetEnum(mGrKind[piIndex + 1]).
    END METHOD.

    /* The top left of a ground target, whose picture is 16 x 16. */
    METHOD PUBLIC INTEGER GroundX(INPUT piIndex AS INTEGER):
        CheckGround(piIndex).
        RETURN mGrX[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER GroundY(INPUT piIndex AS INTEGER):
        CheckGround(piIndex).
        RETURN mGrY[piIndex + 1].
    END METHOD.

    /* 1 or -1: the way a ground target that crawls (the tank) is going along the land. */
    METHOD PUBLIC INTEGER GroundWay(INPUT piIndex AS INTEGER):
        CheckGround(piIndex).
        RETURN mGrWay[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER GroundAge(INPUT piIndex AS INTEGER):
        CheckGround(piIndex).
        RETURN mGrT[piIndex + 1].
    END METHOD.

    METHOD PUBLIC LOGICAL BulletActive(INPUT piIndex AS INTEGER):
        CheckBullet(piIndex).
        RETURN mBuOn[piIndex + 1].
    END METHOD.

    /* The centre of an enemy bullet, in pixels. */
    METHOD PUBLIC INTEGER BulletX(INPUT piIndex AS INTEGER):
        CheckBullet(piIndex).
        RETURN XeviousMotion:Div(mBuX[piIndex + 1], 8).
    END METHOD.

    METHOD PUBLIC INTEGER BulletY(INPUT piIndex AS INTEGER):
        CheckBullet(piIndex).
        RETURN XeviousMotion:Div(mBuY[piIndex + 1], 8).
    END METHOD.

    /* The effects: an empty slot has no kind (unknown). Age is the frames since it began. */
    METHOD PUBLIC XeviousFx FxKindAt(INPUT piIndex AS INTEGER):
        CheckFx(piIndex).
        IF mFxKind[piIndex + 1] < 0 OR Frames - mFxStart[piIndex + 1] >= FxLife(mFxKind[piIndex + 1]) THEN RETURN ?.
        RETURN XeviousFx:GetEnum(mFxKind[piIndex + 1]).
    END METHOD.

    METHOD PUBLIC INTEGER FxAge(INPUT piIndex AS INTEGER):
        CheckFx(piIndex).
        RETURN Frames - mFxStart[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER FxX(INPUT piIndex AS INTEGER):
        CheckFx(piIndex).
        RETURN mFxX[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER FxY(INPUT piIndex AS INTEGER):
        CheckFx(piIndex).
        RETURN mFxY[piIndex + 1].
    END METHOD.

    /* The number an effect shows (the points of a Points one). */
    METHOD PUBLIC INTEGER FxValue(INPUT piIndex AS INTEGER):
        CheckFx(piIndex).
        RETURN mFxValue[piIndex + 1].
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        Score = 0.
        Lives = XeviousRules:StartLives().
        mNotice = "".
        mAcc = 0.
        mFireReady = FALSE.
        mProtect = 0.
        mZapCool = 0.
        mZapOn[1] = FALSE.
        mZapOn[2] = FALSE.
        mNextExtra = XeviousRules:ExtraLifeFirst().
        PlacePlayer(104, 208).
        BeginStage(1).
        StopWaves().
        SetPhase(XeviousPhase:Title).
    END METHOD.

    /* ============================== one frame ============================== */

    METHOD PRIVATE VOID Step():
        Frames = Frames + 1.
        PhaseFrames = PhaseFrames + 1.
        CASE Phase:
            WHEN XeviousPhase:Title THEN StepTitle().
            WHEN XeviousPhase:Playing THEN StepPlaying().
            WHEN XeviousPhase:Dying THEN StepDying().
            WHEN XeviousPhase:StageClear THEN StepClear().
            WHEN XeviousPhase:GameOver THEN StepOver().
        END CASE.
    END METHOD.

    /* The title screen: the land scrolls on behind it, and the fire keys start a game once they have been let go. */
    METHOD PRIVATE VOID StepTitle():
        StepScroll().
        IF NOT (ZapHeld OR BombHeld) THEN mFireReady = TRUE.
        ELSE IF mFireReady THEN StartGame().
    END METHOD.

    METHOD PRIVATE VOID StepOver():
        IF NOT (ZapHeld OR BombHeld) THEN mFireReady = TRUE.
        ELSE IF mFireReady AND PhaseFrames >= 90 THEN DO:
            mFireReady = FALSE.
            BeginStage(1).
            StopWaves().
            SetPhase(XeviousPhase:Title).
        END.
    END METHOD.

    METHOD PRIVATE VOID StepDying():
        IF PhaseFrames < XeviousRules:DyingFrames() THEN RETURN.
        IF Lives <= 0 THEN DO:
            mFireReady = FALSE.
            SetPhase(XeviousPhase:GameOver).
        END.
        ELSE Respawn().
    END METHOD.

    METHOD PRIVATE VOID StepClear():
        StepScroll().
        IF PhaseFrames >= XeviousRules:ClearFrames() THEN DO:
            BeginStage(Stage + 1).
            mProtect = 90.
            SetPhase(XeviousPhase:Playing).
        END.
    END METHOD.

    METHOD PRIVATE VOID StepPlaying():
        MovePlayer().
        FireWeapons().
        StepScroll().
        StepWaves().
        StepAir().
        StepGround().
        StepBoss().
        StepZaps().
        StepBomb().
        StepBullets().
        IF mProtect > 0 THEN mProtect = mProtect - 1.
        IF Phase <> XeviousPhase:Playing THEN RETURN.
        IF XeviousRules:HasBoss(Stage) THEN DO:
            IF NOT mBossSpawned AND Distance >= (XeviousRules:StageRows() - 10) * XeviousRules:Tile() THEN SpawnBoss().
            IF mBossDone THEN CompleteStage().
        END.
        ELSE IF Distance >= XeviousRules:StageRows() * XeviousRules:Tile() THEN CompleteStage().
    END METHOD.

    METHOD PRIVATE VOID MovePlayer():
        mPx = MINIMUM(XeviousRules:FieldWidth() - 16, MAXIMUM(0, mPx + MoveX * XeviousRules:PlayerSpeed())).
        mPy = MINIMUM(XeviousRules:FieldHeight() - 16, MAXIMUM(0, mPy + MoveY * XeviousRules:PlayerSpeed())).
    END METHOD.

    METHOD PRIVATE VOID FireWeapons():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF mZapCool > 0 THEN mZapCool = mZapCool - 1.
        IF ZapHeld AND mZapCool = 0 THEN DO:
            DO i = 1 TO {&ZAP-MAX}:
                IF NOT mZapOn[i] THEN DO:
                    ASSIGN mZapOn[i] = TRUE
                           mZapX[i] = mPx + 6
                           mZapY[i] = mPy - 6
                           mZapCool = XeviousRules:ZapCooldown()
                           ZapsFired = ZapsFired + 1.
                    LEAVE.
                END.
            END.
        END.
        IF BombHeld AND NOT mBombOn AND NOT mBurstOn THEN DO:
            ASSIGN mBombOn = TRUE
                   mBombT = 0
                   mBombSx = mPx + 8
                   mBombSy = mPy + 8
                   mBombTx = SightX
                   mBombTy = SightY
                   BombsDropped = BombsDropped + 1.
        END.
    END METHOD.

    /* The ground goes down the screen by ScrollNum pixels in every ScrollDen frames, and the new row at the top is made. */
    METHOD PRIVATE VOID StepScroll():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mScrollAcc = mScrollAcc + XeviousRules:ScrollNum().
        IF mScrollAcc < XeviousRules:ScrollDen() THEN RETURN.
        mScrollAcc = mScrollAcc - XeviousRules:ScrollDen().
        Distance = Distance + 1.
        DO i = 1 TO {&GROUND-MAX}:
            IF mGrState[i] <> 0 THEN DO:
                mGrY[i] = mGrY[i] + 1.
                IF mGrY[i] >= XeviousRules:FieldHeight() THEN mGrState[i] = 0.
            END.
        END.
        IF mBombOn THEN mBombTy = mBombTy + 1.
        Generate().
    END METHOD.

    /* The y of the top of a row of ground. Row 0 is at the bottom when the stage begins. */
    METHOD PRIVATE INTEGER RowY(INPUT piRow AS INTEGER):
        RETURN XeviousRules:FieldHeight() - 16 - piRow * XeviousRules:Tile() + Distance.
    END METHOD.

    /* Puts on the map every row of ground that has come within 32 pixels above the screen. */
    METHOD PRIVATE VOID Generate():
        DEFINE VARIABLE kind AS XeviousGround NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER       NO-UNDO.
        DO WHILE RowY(mNextRow) > -32 AND NOT mLandOff:
            kind = XeviousMap:KindAt(Stage, mNextRow).
            IF VALID-OBJECT(kind) THEN DO:
                y = RowY(mNextRow).
                IF AddGround(kind, XeviousMap:ColAt(Stage, mNextRow) * XeviousRules:Tile(), y, mNextRow > mMaxRow) THEN.
            END.
            IF mNextRow > mMaxRow THEN mMaxRow = mNextRow.
            mNextRow = mNextRow + 1.
        END.
    END METHOD.

    /* Puts a ground target in the first free slot. plCount says it is new to the map, so it counts for the bonus. Returns false
       when there is no room. */
    METHOD PRIVATE LOGICAL AddGround(INPUT poKind AS XeviousGround, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plCount AS LOGICAL):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&GROUND-MAX}:
            IF mGrState[i] = 0 THEN DO:
                ASSIGN mGrState[i] = 1
                       mGrKind[i] = INTEGER(poKind)
                       mGrX[i] = piX
                       mGrY[i] = piY
                       mGrT[i] = 0
                       mGrHp[i] = XeviousRules:GroundHp(poKind)
                       mGrWay[i] = 1.
                IF plCount AND NOT XeviousRules:IsHidden(poKind) THEN mStageGround = mStageGround + 1.
                RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* ============================== the air ============================== */

    METHOD PRIVATE VOID StepWaves():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        IF mBossOn THEN RETURN.
        IF mQLeft > 0 THEN DO:
            mQTimer = mQTimer - 1.
            IF mQTimer <= 0 THEN DO:
                IF mQKind = INTEGER(XeviousAir:Zakato) THEN
                    x = MINIMUM(200, MAXIMUM(8, mPx + (mRandom:NextInt(2) * 2 - 1) * (30 + mRandom:NextInt(30)))).
                ELSE x = mQX + mQIndex * mQDx.
                IF TrySpawnAir(XeviousAir:GetEnum(mQKind), x,
                               (IF mQKind = INTEGER(XeviousAir:Zakato) THEN MINIMUM(150, MAXIMUM(8, mPy - 70))
                                ELSE IF mQKind = INTEGER(XeviousAir:Bacura) THEN -24 ELSE -16),
                               mQWay, mPx) THEN.
                mQLeft = mQLeft - 1.
                mQIndex = mQIndex + 1.
                mQTimer = mQGap.
            END.
        END.
        ELSE DO:
            mWaveTimer = mWaveTimer - 1.
            IF mWaveTimer <= 0 THEN StartWave().
        END.
    END METHOD.

    /* Chooses the next wave: a kind that has come in by this stage, and how many, where and how far apart. */
    METHOD PRIVATE VOID StartWave():
        DEFINE VARIABLE tries AS INTEGER NO-UNDO.
        DEFINE VARIABLE kind  AS XeviousAir NO-UNDO.
        kind = XeviousAir:Toroid.
        DO tries = 1 TO 12:
            kind = XeviousAir:GetEnum(mRandom:NextInt(8)).
            IF XeviousRules:AirFirstStage(kind) <= XeviousRules:StageOf(Stage) THEN LEAVE.
            kind = XeviousAir:Toroid.
        END.
        ASSIGN mQKind = INTEGER(kind)
               mQIndex = 0
               mQTimer = 0
               mQDx = 0
               mQWay = 1.
        CASE kind:
            WHEN XeviousAir:Toroid THEN ASSIGN mQLeft = 6 mQGap = 12 mQX = 24 + mRandom:NextInt(150).
            WHEN XeviousAir:Torkan THEN DO:
                mQWay = mRandom:NextInt(2) * 2 - 1.
                ASSIGN mQLeft = 4 mQGap = 14 mQX = (IF mQWay > 0 THEN 8 ELSE 200).
            END.
            WHEN XeviousAir:GiddoSpario THEN ASSIGN mQLeft = 3 mQGap = 30 mQX = 16 + mRandom:NextInt(190).
            WHEN XeviousAir:Kapi THEN ASSIGN mQLeft = 1 mQGap = 1 mQX = 24 + mRandom:NextInt(170).
            WHEN XeviousAir:Jara THEN ASSIGN mQLeft = 5 mQGap = 10 mQX = 40 + mRandom:NextInt(120).
            WHEN XeviousAir:Zakato THEN ASSIGN mQLeft = 1 mQGap = 1 mQX = 0.
            WHEN XeviousAir:Terrazi THEN ASSIGN mQLeft = 5 mQGap = 6 mQX = 16 + mRandom:NextInt(190).
            WHEN XeviousAir:Bacura THEN ASSIGN mQLeft = 3 mQGap = 1 mQX = 24 + mRandom:NextInt(60) mQDx = 60.
        END CASE.
        mWaveTimer = XeviousRules:WaveDelay(Stage) + mRandom:NextInt(40).
    END METHOD.

    /* Puts an air enemy in the first free slot. Returns false when there is no room. */
    METHOD PRIVATE LOGICAL TrySpawnAir(INPUT poKind AS XeviousAir, INPUT piX AS INTEGER, INPUT piY AS INTEGER,
                                       INPUT piWay AS INTEGER, INPUT piAimX AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&AIR-MAX}:
            IF NOT mAirOn[i] THEN DO:
                ASSIGN mAirOn[i] = TRUE
                       mAirKind[i] = INTEGER(poKind)
                       mAirA[i] = piX
                       mAirY0[i] = piY
                       mAirAge[i] = 0
                       mAirWay[i] = piWay
                       mAirAim[i] = piAimX
                       mAirPush[i] = 0
                       mAirX[i] = piX
                       mAirY[i] = piY.
                RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE VOID StepAir():
        DEFINE VARIABLE i    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE kind AS XeviousAir NO-UNDO.
        DO i = 1 TO {&AIR-MAX}:
            IF mAirOn[i] THEN DO:
                kind = XeviousAir:GetEnum(mAirKind[i]).
                mAirAge[i] = mAirAge[i] + 1.
                mAirX[i] = XeviousMotion:AirX(kind, mAirA[i], mAirAge[i], mAirWay[i], mAirAim[i]).
                mAirY[i] = XeviousMotion:AirY(kind, mAirY0[i], mAirAge[i], mAirPush[i]).
                CASE kind:
                    WHEN XeviousAir:GiddoSpario THEN DO:
                        IF mAirAge[i] = 50 OR mAirAge[i] = 100 THEN FireAt(mAirX[i] + 8, mAirY[i] + 8, mPx + 8, mPy + 8).
                    END.
                    WHEN XeviousAir:Zakato THEN DO:
                        IF mAirAge[i] >= 40 THEN DO:
                            Ring(mAirX[i] + 8, mAirY[i] + 8).
                            AddFx(XeviousFx:AirBlast, mAirX[i] + 8, mAirY[i] + 8, 0).
                            mAirOn[i] = FALSE.
                        END.
                    END.
                END CASE.
                IF mAirOn[i] AND mAirAge[i] > 4 AND (mAirY[i] >= XeviousRules:FieldHeight() + 16 OR mAirY[i] < -48
                                                    OR mAirX[i] < -40 OR mAirX[i] > XeviousRules:FieldWidth() + 24) THEN mAirOn[i] = FALSE.
                IF mAirOn[i] AND Phase = XeviousPhase:Playing AND mProtect = 0 AND NOT Arriving(i)
                   AND Overlap(mAirX[i] + XeviousBoxes:AirLeft(kind), mAirY[i] + XeviousBoxes:AirTop(kind), XeviousBoxes:AirWidth(kind), XeviousBoxes:AirHeight(kind),
                               mPx + 2, mPy + 2, 12, 12) THEN KillPlayer().
            END.
        END.
    END METHOD.

    /* An air enemy is destroyed by a Zapper shot: its points, its blast, and the slot is free. */
    METHOD PRIVATE VOID KillAir(INPUT piIndex AS INTEGER):
        DEFINE VARIABLE points AS INTEGER NO-UNDO.
        points = XeviousRules:AirPoints(XeviousAir:GetEnum(mAirKind[piIndex])).
        mAirOn[piIndex] = FALSE.
        AirKills = AirKills + 1.
        AddScore(points).
        AddFx(XeviousFx:AirBlast, mAirX[piIndex] + 8, mAirY[piIndex] + 8, 0).
        IF points >= 100 THEN AddFx(XeviousFx:Points, mAirX[piIndex] + 8, mAirY[piIndex], points).
    END METHOD.

    /* ============================== the ground ============================== */

    METHOD PRIVATE VOID StepGround():
        DEFINE VARIABLE i      AS INTEGER        NO-UNDO.
        DEFINE VARIABLE kind   AS XeviousGround  NO-UNDO.
        DEFINE VARIABLE period AS INTEGER        NO-UNDO.
        DO i = 1 TO {&GROUND-MAX}:
            IF mGrState[i] <> 0 THEN mGrT[i] = mGrT[i] + 1.
            /* a revealed tower bursts after 24 frames and leaves its scorch */
            IF mGrState[i] = 3 AND mGrT[i] >= 24 THEN DO:
                mGrState[i] = 2.
                AddFx(XeviousFx:GroundBlast, mGrX[i] + 8, mGrY[i] + 8, 0).
            END.
            /* a pennant is an extra ship for the ship that flies over it */
            IF mGrState[i] = 4 AND Phase = XeviousPhase:Playing
               AND Overlap(mGrX[i] + GroundLeft(i), mGrY[i] + GroundTop(i), GroundWide(i), GroundHigh(i), mPx + 2, mPy + 2, 12, 12) THEN DO:
                mGrState[i] = 0.
                Lives = Lives + 1.
                ExtraLives = ExtraLives + 1.
                mNotice = "EXTRA SHIP".
            END.
            IF mGrState[i] = 1 AND mGrY[i] >= 8 AND mGrY[i] < 180 THEN DO:
                kind = XeviousGround:GetEnum(mGrKind[i]).
                CASE kind:
                    WHEN XeviousGround:Logram THEN DO:
                        period = MAXIMUM(45, 150 - 6 * XeviousRules:StageOf(Stage)).
                        IF mGrT[i] MODULO period = period - 1 THEN FireAt(mGrX[i] + 8, mGrY[i] + 8, mPx + 8, mPy + 8).
                    END.
                    WHEN XeviousGround:Derota THEN DO:
                        period = MAXIMUM(30, 100 - 4 * XeviousRules:StageOf(Stage)).
                        IF mGrT[i] MODULO period = period - 1 THEN DO:
                            FireAt(mGrX[i] + 8, mGrY[i] + 8, mPx - 20, mPy + 8).
                            FireAt(mGrX[i] + 8, mGrY[i] + 8, mPx + 36, mPy + 8).
                        END.
                    END.
                    WHEN XeviousGround:Grobda THEN DO:
                        IF mGrT[i] MODULO 2 = 0 THEN DO:
                            mGrX[i] = mGrX[i] + mGrWay[i].
                            IF mGrX[i] <= 0 OR mGrX[i] >= XeviousRules:FieldWidth() - 16 THEN mGrWay[i] = - mGrWay[i].
                        END.
                    END.
                    WHEN XeviousGround:GaruZakato THEN DO:
                        IF mGrT[i] MODULO 180 = 179 AND mGrY[i] < 140 THEN
                            IF TrySpawnAir(XeviousAir:Zakato, mGrX[i], mGrY[i], 1, mGrX[i]) THEN.
                    END.
                END CASE.
            END.
        END.
    END METHOD.

    /* A ground target is hit by a bomb. A hidden one is found (and goes), a target with hit points left only takes one. */
    METHOD PRIVATE VOID HitGround(INPUT piIndex AS INTEGER):
        DEFINE VARIABLE kind   AS XeviousGround NO-UNDO.
        DEFINE VARIABLE points AS INTEGER       NO-UNDO.
        kind = XeviousGround:GetEnum(mGrKind[piIndex]).
        mGrHp[piIndex] = mGrHp[piIndex] - 1.
        IF mGrHp[piIndex] > 0 THEN DO:
            AddFx(XeviousFx:GroundBlast, mGrX[piIndex] + 8, mGrY[piIndex] + 8, 0).
            RETURN.
        END.
        mGrT[piIndex] = 0.
        points = XeviousRules:GroundPoints(kind).
        CASE kind:
            WHEN XeviousGround:Sol THEN DO:
                /* the hidden tower stands for 24 frames, then bursts (StepGround) */
                mGrState[piIndex] = 3.
                SolsFound = SolsFound + 1.
                mStageSols = mStageSols + 1.
                AddFx(XeviousFx:Reveal, mGrX[piIndex] + 8, mGrY[piIndex] + 8, 0).
            END.
            WHEN XeviousGround:Flag THEN DO:
                /* the pennant waits where the hidden spot was bombed, and is collected by flying over it (StepGround) */
                mGrState[piIndex] = 4.
                FlagsFound = FlagsFound + 1.
                AddFx(XeviousFx:Reveal, mGrX[piIndex] + 8, mGrY[piIndex] + 8, 0).
            END.
            OTHERWISE DO:
                mGrState[piIndex] = 2.
                GroundKills = GroundKills + 1.
                mStageKilled = mStageKilled + 1.
                AddFx(XeviousFx:GroundBlast, mGrX[piIndex] + 8, mGrY[piIndex] + 8, 0).
            END.
        END CASE.
        IF points > 0 THEN AddScore(points).
        IF points >= 100 THEN AddFx(XeviousFx:Points, mGrX[piIndex] + 8, mGrY[piIndex], points).
    END METHOD.

    /* ============================== the mothership ============================== */

    METHOD PRIVATE VOID StepBoss():
        DEFINE VARIABLE period AS INTEGER NO-UNDO.
        IF NOT mBossOn THEN RETURN.
        mBossT = mBossT + 1.
        IF mBossY < 56 AND mBossT MODULO 2 = 0 THEN mBossY = mBossY + 1.
        mBossX = 96 + XeviousMotion:Wave(mBossT, 240, 70).
        period = MAXIMUM(60, 110 - 15 * XeviousRules:LapOf(Stage)).
        IF mBossY >= 20 THEN DO:
            IF mBossT MODULO period = 0 THEN Ring(mBossX + 16, mBossY + 16).
            IF mBossT MODULO 55 = 27 THEN FireAt(mBossX + 16, mBossY + 16, mPx + 8, mPy + 8).
        END.
        IF Phase = XeviousPhase:Playing AND mProtect = 0
           AND Overlap(mBossX + 2, mBossY + 2, 28, 28, mPx + 2, mPy + 2, 12, 12) THEN KillPlayer().
    END METHOD.

    /* ============================== the weapons ============================== */

    METHOD PRIVATE VOID StepZaps():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DO i = 1 TO {&ZAP-MAX}:
            IF mZapOn[i] THEN DO:
                mZapY[i] = mZapY[i] - XeviousRules:ZapSpeed().
                IF mZapY[i] < -10 THEN mZapOn[i] = FALSE.
                /* the mothership turns shots away */
                IF mZapOn[i] AND mBossOn AND Overlap(mZapX[i] + ZapLeft(), mZapY[i], ZapWide(), ZapHigh(), mBossX, mBossY, 32, 32) THEN DO:
                    mZapOn[i] = FALSE.
                    Clangs = Clangs + 1.
                END.
                DO j = 1 TO {&AIR-MAX} WHILE mZapOn[i]:
                    IF mAirOn[j] AND NOT Arriving(j) AND Overlap(mZapX[i] + ZapLeft(), mZapY[i], ZapWide(), ZapHigh(), mAirX[j] + AirLeft(j), mAirY[j] + AirTop(j), AirWide(j), AirHigh(j)) THEN DO:
                        mZapOn[i] = FALSE.
                        IF mAirKind[j] = INTEGER(XeviousAir:Bacura) THEN DO:
                            mAirPush[j] = mAirPush[j] + 1.
                            Clangs = Clangs + 1.
                            IF mAirPush[j] >= XeviousRules:BacuraHits() THEN KillAir(j).
                        END.
                        ELSE KillAir(j).
                    END.
                END.
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID StepBomb():
        IF mBurstOn THEN DO:
            mBurstT = mBurstT + 1.
            IF mBurstT >= XeviousRules:BlastFrames() THEN mBurstOn = FALSE.
        END.
        IF NOT mBombOn THEN RETURN.
        mBombT = mBombT + 1.
        IF mBombT >= XeviousRules:BombFlight() THEN DO:
            mBombOn = FALSE.
            ASSIGN mBurstOn = TRUE
                   mBurstT = 0
                   mBurstX = mBombTx
                   mBurstY = mBombTy
                   BombBursts = BombBursts + 1.
            Blast(mBurstX, mBurstY).
        END.
    END METHOD.

    /* What a bomb that has landed at piX, piY hits: ground targets, and the core of the mothership. */
    METHOD PRIVATE VOID Blast(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE r AS INTEGER NO-UNDO.
        r = XeviousRules:BlastRadius().
        DO i = 1 TO {&GROUND-MAX}:
            IF mGrState[i] = 1 AND mGrY[i] > -16 AND Overlap(piX - r, piY - r, 2 * r, 2 * r, mGrX[i] + GroundLeft(i), mGrY[i] + GroundTop(i), GroundWide(i), GroundHigh(i)) THEN HitGround(i).
        END.
        IF mBossOn AND Overlap(piX - r, piY - r, 2 * r, 2 * r, mBossX + 11, mBossY + 11, 10, 10) THEN DO:
            mBossHp = mBossHp - 1.
            BossHits = BossHits + 1.
            IF mBossHp <= 0 THEN DO:
                mBossOn = FALSE.
                mBossDone = TRUE.
                BossKills = BossKills + 1.
                ClearBullets().
                AddFx(XeviousFx:BossBlast, mBossX + 16, mBossY + 16, 0).
                AddScore(4000).
                AddFx(XeviousFx:Points, mBossX + 16, mBossY, 4000).
            END.
            ELSE AddFx(XeviousFx:GroundBlast, piX, piY, 0).
        END.
    END METHOD.

    /* ============================== enemy bullets ============================== */

    /* A bullet from piFromX, piFromY (its centre) towards piToX, piToY at this stage's speed. Nothing happens when the air is full
       of bullets. */
    METHOD PRIVATE VOID FireAt(INPUT piFromX AS INTEGER, INPUT piFromY AS INTEGER, INPUT piToX AS INTEGER, INPUT piToY AS INTEGER):
        DEFINE VARIABLE dx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE a     AS INTEGER NO-UNDO.
        DEFINE VARIABLE b     AS INTEGER NO-UNDO.
        DEFINE VARIABLE len   AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed AS INTEGER NO-UNDO.
        speed = XeviousRules:BulletSpeed(Stage).
        dx = piToX - piFromX.
        dy = piToY - piFromY.
        IF dx = 0 AND dy = 0 THEN dy = 1.
        a = ABSOLUTE(dx).
        b = ABSOLUTE(dy).
        len = MAXIMUM(a, b) + XeviousMotion:Div(MINIMUM(a, b), 2).
        AddBullet(piFromX, piFromY, XeviousMotion:Div(dx * speed, len), XeviousMotion:Div(dy * speed, len)).
    END METHOD.

    /* A ring of eight bullets from a centre. */
    METHOD PRIVATE VOID Ring(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE s AS INTEGER NO-UNDO.
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        s = XeviousRules:BulletSpeed(Stage).
        c = XeviousMotion:Div(s * 7, 10).
        AddBullet(piX, piY, s, 0).
        AddBullet(piX, piY, c, c).
        AddBullet(piX, piY, 0, s).
        AddBullet(piX, piY, - c, c).
        AddBullet(piX, piY, - s, 0).
        AddBullet(piX, piY, - c, - c).
        AddBullet(piX, piY, 0, - s).
        AddBullet(piX, piY, c, - c).
    END METHOD.

    METHOD PRIVATE VOID AddBullet(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piVx AS INTEGER, INPUT piVy AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&BULLET-MAX}:
            IF NOT mBuOn[i] THEN DO:
                ASSIGN mBuOn[i] = TRUE
                       mBuX[i] = piX * 8
                       mBuY[i] = piY * 8
                       mBuVx[i] = piVx
                       mBuVy[i] = piVy
                       EnemyShots = EnemyShots + 1.
                RETURN.
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID StepBullets():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO i = 1 TO {&BULLET-MAX}:
            IF mBuOn[i] THEN DO:
                mBuX[i] = mBuX[i] + mBuVx[i].
                mBuY[i] = mBuY[i] + mBuVy[i].
                x = XeviousMotion:Div(mBuX[i], 8).
                y = XeviousMotion:Div(mBuY[i], 8).
                IF mBuX[i] < -64 OR mBuY[i] < -64 OR x >= XeviousRules:FieldWidth() + 8 OR y >= XeviousRules:FieldHeight() + 8 THEN mBuOn[i] = FALSE.
                ELSE IF Phase = XeviousPhase:Playing AND mProtect = 0
                        AND Overlap(x - 1, y - 1, 3, 3, mPx + 2, mPy + 2, 12, 12) THEN DO:
                    mBuOn[i] = FALSE.
                    KillPlayer().
                END.
            END.
        END.
    END METHOD.

    /* ============================== losing a ship, finishing a stage ============================== */

    METHOD PRIVATE VOID KillPlayer():
        Deaths = Deaths + 1.
        Lives = Lives - 1.
        AddFx(XeviousFx:ShipBlast, mPx + 8, mPy + 8, 0).
        mBombOn = FALSE.
        mBurstOn = FALSE.
        SetPhase(XeviousPhase:Dying).
    END METHOD.

    /* The ship comes back: the stage goes back to the last checkpoint, the air is clear and the ship is protected. */
    METHOD PRIVATE VOID Respawn():
        DEFINE VARIABLE row AS INTEGER NO-UNDO.
        Distance = XeviousMotion:Div(Distance, XeviousRules:CheckpointEvery()) * XeviousRules:CheckpointEvery().
        mScrollAcc = 0.
        ClearGround().
        ClearAir().
        ClearBullets().
        ClearBoss().
        mBossSpawned = FALSE.
        mBossDone = FALSE.
        mNextRow = MAXIMUM(0, XeviousMotion:Div(Distance, XeviousRules:Tile()) - 1).
        Generate().
        mWaveTimer = 120.
        PlacePlayer(104, 208).
        mProtect = XeviousRules:ProtectFrames().
        SetPhase(XeviousPhase:Playing).
    END METHOD.

    METHOD PRIVATE VOID CompleteStage():
        StagePercent = (IF mStageGround = 0 THEN 100 ELSE MINIMUM(100, XeviousMotion:Div(mStageKilled * 100, mStageGround))).
        StageBonus = StagePercent * XeviousRules:BonusPerPercent().
        StagesCleared = StagesCleared + 1.
        ClearAir().
        ClearBullets().
        ClearBoss().
        mBombOn = FALSE.
        mZapOn[1] = FALSE.
        mZapOn[2] = FALSE.
        AddScore(StageBonus).
        SetPhase(XeviousPhase:StageClear).
    END METHOD.

    /* ============================== small things ============================== */

    METHOD PRIVATE VOID SetPhase(INPUT poPhase AS XeviousPhase):
        Phase = poPhase.
        PhaseFrames = 0.
        IsOver = (poPhase = XeviousPhase:GameOver).
    END METHOD.

    /* True when two rectangles (left, top, width, height) share any pixel. */
    METHOD PRIVATE LOGICAL Overlap(INPUT piX1 AS INTEGER, INPUT piY1 AS INTEGER, INPUT piW1 AS INTEGER, INPUT piH1 AS INTEGER,
                                   INPUT piX2 AS INTEGER, INPUT piY2 AS INTEGER, INPUT piW2 AS INTEGER, INPUT piH2 AS INTEGER):
        RETURN piX1 < piX2 + piW2 AND piX2 < piX1 + piW1 AND piY1 < piY2 + piH2 AND piY2 < piY1 + piH1.
    END METHOD.

    /* An effect in the next slot of the ring of them. */
    METHOD PRIVATE VOID AddFx(INPUT poKind AS XeviousFx, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piValue AS INTEGER):
        ASSIGN mFxKind[mFxNext] = INTEGER(poKind)
               mFxX[mFxNext] = piX
               mFxY[mFxNext] = piY
               mFxStart[mFxNext] = Frames
               mFxValue[mFxNext] = piValue
               mFxNext = mFxNext MODULO {&FX-MAX} + 1.
    END METHOD.

    /* How many frames an effect lasts. */
    METHOD PRIVATE INTEGER FxLife(INPUT piKind AS INTEGER):
        CASE XeviousFx:GetEnum(piKind):
            WHEN XeviousFx:AirBlast THEN RETURN 20.
            WHEN XeviousFx:GroundBlast THEN RETURN 30.
            WHEN XeviousFx:ShipBlast OR WHEN XeviousFx:BossBlast THEN RETURN 90.
            WHEN XeviousFx:Reveal THEN RETURN 40.
            OTHERWISE RETURN 60.
        END CASE.
    END METHOD.

    /* The Zapper shot's box from the design (the core of the picture), made as tall as the shot flies in a frame so that a fast shot
       cannot pass through a thin enemy. */
    METHOD PRIVATE INTEGER ZapLeft():
        RETURN XeviousArt:BoxX(XeviousPicture:Zap).
    END METHOD.

    METHOD PRIVATE INTEGER ZapWide():
        RETURN XeviousArt:BoxWidth(XeviousPicture:Zap).
    END METHOD.

    METHOD PRIVATE INTEGER ZapHigh():
        RETURN XeviousArt:BoxHeight(XeviousPicture:Zap) + XeviousRules:ZapSpeed().
    END METHOD.

    /* The box of the air enemy in slot piSlot (1 up), within its 16 x 16 place. */
    /* True while the air enemy in slot piSlot is only a spark where it will be: a Wisp has no box for its first 8 frames. */
    METHOD PRIVATE LOGICAL Arriving(INPUT piSlot AS INTEGER):
        RETURN mAirKind[piSlot] = INTEGER(XeviousAir:Zakato) AND mAirAge[piSlot] < 8.
    END METHOD.

    METHOD PRIVATE INTEGER AirLeft(INPUT piSlot AS INTEGER):
        RETURN XeviousBoxes:AirLeft(XeviousAir:GetEnum(mAirKind[piSlot])).
    END METHOD.

    METHOD PRIVATE INTEGER AirTop(INPUT piSlot AS INTEGER):
        RETURN XeviousBoxes:AirTop(XeviousAir:GetEnum(mAirKind[piSlot])).
    END METHOD.

    METHOD PRIVATE INTEGER AirWide(INPUT piSlot AS INTEGER):
        RETURN XeviousBoxes:AirWidth(XeviousAir:GetEnum(mAirKind[piSlot])).
    END METHOD.

    METHOD PRIVATE INTEGER AirHigh(INPUT piSlot AS INTEGER):
        RETURN XeviousBoxes:AirHeight(XeviousAir:GetEnum(mAirKind[piSlot])).
    END METHOD.

    /* The same for the ground target in slot piSlot. */
    METHOD PRIVATE INTEGER GroundLeft(INPUT piSlot AS INTEGER):
        RETURN XeviousBoxes:GroundLeft(XeviousGround:GetEnum(mGrKind[piSlot])).
    END METHOD.

    METHOD PRIVATE INTEGER GroundTop(INPUT piSlot AS INTEGER):
        RETURN XeviousBoxes:GroundTop(XeviousGround:GetEnum(mGrKind[piSlot])).
    END METHOD.

    METHOD PRIVATE INTEGER GroundWide(INPUT piSlot AS INTEGER):
        RETURN XeviousBoxes:GroundWidth(XeviousGround:GetEnum(mGrKind[piSlot])).
    END METHOD.

    METHOD PRIVATE INTEGER GroundHigh(INPUT piSlot AS INTEGER):
        RETURN XeviousBoxes:GroundHeight(XeviousGround:GetEnum(mGrKind[piSlot])).
    END METHOD.

    METHOD PRIVATE VOID CheckAir(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= {&AIR-MAX} THEN UNDO, THROW NEW GridException("There is no air enemy " + STRING(piIndex)).
    END METHOD.

    METHOD PRIVATE VOID CheckGround(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= {&GROUND-MAX} THEN UNDO, THROW NEW GridException("There is no ground slot " + STRING(piIndex)).
    END METHOD.

    METHOD PRIVATE VOID CheckBullet(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= {&BULLET-MAX} THEN UNDO, THROW NEW GridException("There is no bullet " + STRING(piIndex)).
    END METHOD.

    METHOD PRIVATE VOID CheckFx(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= {&FX-MAX} THEN UNDO, THROW NEW GridException("There is no effect " + STRING(piIndex)).
    END METHOD.

END CLASS.
