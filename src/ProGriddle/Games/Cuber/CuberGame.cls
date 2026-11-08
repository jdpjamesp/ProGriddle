/* The rules of Cuber, as a real time game that runs frame by frame (a frame is a sixtieth of a second: Advance makes one, and Tick
   turns the milliseconds a clock gives it into frames, scaled by SpeedPercent). Pip, a small glowing gummy, hops down a pyramid of
   28 lamps (7 rows, the apex is row 1) and lights each lamp it lands on, while enemies chase it and the edge is a long way down.
   The game works on lamp coordinates (a row 1 to 7 and a column 0 to row - 1, see CuberRules) and in pixels only to say where
   something is on the 256 x 256 picture, and it knows nothing about drawing.

   The grid is 7 x 7 with one layer, "lamp": 0 for a lamp not reached, 1 for half way (levels of two hits), 2 for lit. The game
   owns its grid, and Dispose releases it.

   Rules and numbers:
   - Pip hops one lamp at a time along the four diagonals (a hop is 12 frames and cannot be steered in the air). A hop that
     lands on no lamp is a fall, and costs a life. A hop is remembered for 14 frames, so holding a key hops again at once.
   - A lamp takes one landing to light on levels 1 and 2 and two from level 3 (a ring first, then the light). A lamp lit is worth 25
     (10 for the ring). From level 5 a landing on a lamp that is lit already puts it back a step. Lighting all 28 clears the round.
   - A round is four to a level and the light changes every round. The level sets the rules and, with the round, the speed
     (CuberRules:Tempo): a seed falls in at the top, bounces down to the bottom row and hatches into a Coil, which hunts Pip
     (it hops the way that brings it nearest, most of the time). Thorns bounce down and hurt. A Frost bounces down too, and
     touching it freezes every enemy for a few seconds (100 points). From level 2 two moths, Snuff and Puff, climb the edges of
     the pyramid and put out each lamp they land on a step; landing on one of them catches it (300 points). A frozen enemy
     is harmless.
   - Halos wait beside the pyramid (four on levels 1 and 2, then three, then two). Hopping on one lifts Pip to the top again, and the
     Coil that was hunting falls off the edge following it (500 points) while everything else vanishes. A halo can be used once
     a round, and each one left when the round is cleared pays 50.
   - Three Pips in all (two spare) and an extra one at every 8000 points.
   - The title and game over screens wait for the fire key, which has to be let go and pressed again.

   Counters (Hops, LampsLit, Deaths and so on) only go up, so a cue source can compare them with the ones it last saw. Frames
   counts every frame ever made and PhaseFrames the frames of the current phase, so a painter can animate as a function of them.
   Randomness comes from the IRandom given to the constructor. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    /* the most time one Tick will count, and the most frames it will make for it */
    &SCOPED-DEFINE MOST-MS 100
    &SCOPED-DEFINE MOST-FRAMES 6
    /* the layer of the grid, and the enemy places */
    &SCOPED-DEFINE LAMP-LAYER 1
    &SCOPED-DEFINE SLOTS 8
    /* the pop-ups of points kept for the painter */
    &SCOPED-DEFINE POPS 4

    VAR PRIVATE IRandom mRandom.
    VAR PRIVATE INTEGER mAcc.
    VAR PRIVATE CHARACTER mNotice.
    VAR PRIVATE LOGICAL mFireReady.
    VAR PRIVATE INTEGER mNextExtra.
    /* Pip: the lamp it stands on (or hops from), the lamp it hops to, the frame of the hop (0 to 12), what it is doing, the frames
       of that, the way of the last hop, whether the hop in the air leads to a fall, whether it fell in front of the pyramid, and
       the frames it has stood since it landed */
    VAR PRIVATE INTEGER mPipR.
    VAR PRIVATE INTEGER mPipC.
    VAR PRIVATE INTEGER mPipToR.
    VAR PRIVATE INTEGER mPipToC.
    VAR PRIVATE INTEGER mPipF.
    VAR PRIVATE CuberPipMode mPipMode.
    VAR PRIVATE INTEGER mPipModeF.
    VAR PRIVATE CuberDir mPipDir.
    VAR PRIVATE LOGICAL mPipFatal.
    VAR PRIVATE LOGICAL mPipFront.
    VAR PRIVATE INTEGER mPipStand.
    /* the hop that is wanted (a CuberDir number, -1 for none) and how many frames it has been wanted */
    VAR PRIVATE INTEGER mWant = -1.
    VAR PRIVATE INTEGER mWantAge.
    /* the six halos: 0 none, 1 waiting, 2 used, and the frame each was used on */
    VAR PRIVATE INTEGER[6] mHalo.
    VAR PRIVATE INTEGER[6] mHaloUsedAt.
    VAR PRIVATE INTEGER mRideSpot.
    /* the enemies, by place: whether there, the kind (a CuberKind number), the lamp it is on, the lamp it hops to, the frame of
       the hop, the frames until its next hop, what it is doing and the frames of that */
    VAR PRIVATE LOGICAL[{&SLOTS}] mEnOn.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnKind.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnR.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnC.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnToR.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnToC.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnF.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnRest.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnMode.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnModeF.
    VAR PRIVATE INTEGER[{&SLOTS}] mEnDir.
    /* the timers of what comes next, and the frames the enemies stay frozen */
    VAR PRIVATE INTEGER mSeedT.
    VAR PRIVATE INTEGER mThornT.
    VAR PRIVATE INTEGER mFrostT.
    VAR PRIVATE INTEGER mMothT.
    VAR PRIVATE INTEGER mFreeze.
    VAR PRIVATE LOGICAL mSpawnsOff.
    /* the points shown over something, newest last (a round robin of four) */
    VAR PRIVATE INTEGER mPopN.
    VAR PRIVATE INTEGER[{&POPS}] mPopValue.
    VAR PRIVATE INTEGER[{&POPS}] mPopX.
    VAR PRIVATE INTEGER[{&POPS}] mPopY.
    VAR PRIVATE INTEGER[{&POPS}] mPopAt.
    /* hops from every lamp to every other, by lamp number (row * (row - 1) / 2 + column, 0 to 27) */
    VAR PRIVATE INTEGER[784] mDist.

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

    DEFINE PUBLIC PROPERTY Phase AS CuberPhase NO-UNDO
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

    /* Spare Pips, not counting the one in play. */
    DEFINE PUBLIC PROPERTY Lives AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The level (1 up) and the round in it (1 to 4). The light of a round is round 1 mint, 2 rose, 3 sky, 4 lilac. */
    DEFINE PUBLIC PROPERTY LevelNo AS INTEGER NO-UNDO INITIAL 1
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY RoundNo AS INTEGER NO-UNDO INITIAL 1
        GET.
        PRIVATE SET.

    /* Frames made since the game was built, and frames since the phase began. */
    DEFINE PUBLIC PROPERTY Frames AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PhaseFrames AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* True while the fire key is down. */
    DEFINE PUBLIC PROPERTY FireHeld AS LOGICAL NO-UNDO
        GET.
        SET.

    /* The counters, which only go up. */
    DEFINE PUBLIC PROPERTY Hops AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LampsLit AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LampsRinged AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LampsPutOut AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Deaths AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Falls AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Hits AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Rides AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY CoilFalls AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Hatchings AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY FrostsTouched AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY MothsCaught AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ExtraLives AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY RoundsCleared AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LevelsCleared AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY GamesStarted AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The lamp last lit (a row, a column) and the frame (Frames) it was lit on, -1 for none, so a painter can play the glint. */
    DEFINE PUBLIC PROPERTY LastLitRow AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastLitCol AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastLitFrame AS INTEGER NO-UNDO INITIAL -1
        GET.
        PRIVATE SET.

    /* A number that goes up whenever a lamp changes, so a painter redraws the pyramid only when it has to. */
    DEFINE PUBLIC PROPERTY PyramidVersion AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* ---- the level ---- */

    /* How hard it is now, 0 to 12. */
    DEFINE PUBLIC PROPERTY Tempo AS INTEGER NO-UNDO
        GET():
            RETURN CuberRules:Tempo(LevelNo, RoundNo).
        END GET.

    /* Lamps that are lit now. */
    DEFINE PUBLIC PROPERTY LampsDone AS INTEGER NO-UNDO
        GET():
            VAR INTEGER r.
            VAR INTEGER c.
            VAR INTEGER n.
            DO r = 1 TO CuberRules:Rows():
                DO c = 0 TO r - 1:
                    IF Lamp(r, c) = 2 THEN n = n + 1.
                END.
            END.
            RETURN n.
        END GET.

    /* Frames the enemies have still to stay frozen, 0 for none. */
    DEFINE PUBLIC PROPERTY FreezeFrames AS INTEGER NO-UNDO
        GET():
            RETURN mFreeze.
        END GET.

    /* The frame (Frames) the last freeze began on, -1 for none, and where the Frost was (its feet), so a painter can spread the ring. */
    DEFINE PUBLIC PROPERTY FreezeFrame AS INTEGER NO-UNDO INITIAL -1
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY FreezeX AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY FreezeY AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* ---- Pip ---- */

    /* The lamp Pip stands on, or hops from. */
    DEFINE PUBLIC PROPERTY PipRow AS INTEGER NO-UNDO
        GET():
            RETURN mPipR.
        END GET.

    DEFINE PUBLIC PROPERTY PipCol AS INTEGER NO-UNDO
        GET():
            RETURN mPipC.
        END GET.

    /* The lamp (or halo place, or place off the edge) Pip is hopping to, which is the lamp it stands on when it is not hopping. */
    DEFINE PUBLIC PROPERTY PipDestRow AS INTEGER NO-UNDO
        GET():
            RETURN (IF mPipMode = CuberPipMode:Hopping OR mPipMode = CuberPipMode:Falling THEN mPipToR ELSE mPipR).
        END GET.

    DEFINE PUBLIC PROPERTY PipDestCol AS INTEGER NO-UNDO
        GET():
            RETURN (IF mPipMode = CuberPipMode:Hopping OR mPipMode = CuberPipMode:Falling THEN mPipToC ELSE mPipC).
        END GET.

    DEFINE PUBLIC PROPERTY PipMode AS CuberPipMode NO-UNDO
        GET():
            RETURN mPipMode.
        END GET.

    /* The frames Pip has been in its mode, and the frame of the hop (0 when it is not hopping, 1 to 12 in the air). */
    DEFINE PUBLIC PROPERTY PipModeFrames AS INTEGER NO-UNDO
        GET():
            RETURN mPipModeF.
        END GET.

    DEFINE PUBLIC PROPERTY PipHopFrame AS INTEGER NO-UNDO
        GET():
            RETURN mPipF.
        END GET.

    /* The way of the last hop, and the frames Pip has stood since it landed. */
    DEFINE PUBLIC PROPERTY PipDirection AS CuberDir NO-UNDO
        GET():
            RETURN mPipDir.
        END GET.

    DEFINE PUBLIC PROPERTY PipStandFrames AS INTEGER NO-UNDO
        GET():
            RETURN mPipStand.
        END GET.

    /* True when the hop Pip is in leads off the pyramid, and when Pip fell off the front of it (a hop down) as opposed to the back. */
    DEFINE PUBLIC PROPERTY PipDoomed AS LOGICAL NO-UNDO
        GET():
            RETURN mPipFatal.
        END GET.

    DEFINE PUBLIC PROPERTY PipFellInFront AS LOGICAL NO-UNDO
        GET():
            RETURN mPipFront.
        END GET.

    /* Where Pip's feet are, in pixels of the picture, with the hop's arc, the fall or the ride worked in. */
    DEFINE PUBLIC PROPERTY PipX AS INTEGER NO-UNDO
        GET():
            RETURN ThingX(mPipMode, mPipR, mPipC, mPipToR, mPipToC, mPipF, mPipModeF, 12).
        END GET.

    DEFINE PUBLIC PROPERTY PipY AS INTEGER NO-UNDO
        GET():
            RETURN ThingY(mPipMode, mPipR, mPipC, mPipToR, mPipToC, mPipF, mPipModeF, 12).
        END GET.

    /* ---- the enemies ---- */

    /* Places in the enemy table, 0 to EnemySlots - 1, and enemies on the pyramid now. */
    DEFINE PUBLIC PROPERTY EnemySlots AS INTEGER NO-UNDO
        GET():
            RETURN {&SLOTS}.
        END GET.

    DEFINE PUBLIC PROPERTY EnemyCount AS INTEGER NO-UNDO
        GET():
            VAR INTEGER i.
            VAR INTEGER n.
            DO i = 1 TO {&SLOTS}:
                IF mEnOn[i] THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* ---- the pop-ups ---- */

    DEFINE PUBLIC PROPERTY PopSlots AS INTEGER NO-UNDO
        GET():
            RETURN {&POPS}.
        END GET.

    /* The grid must be 7 x 7 with exactly one layer, "lamp". */
    CONSTRUCTOR PUBLIC CuberGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        SUPER("Cuber", poGrid).
        IF poGrid:Width <> CuberRules:Rows() OR poGrid:Height <> CuberRules:Rows() THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A Cuber grid is &1 x &1", CuberRules:Rows())).
        IF poGrid:Store:LayerCount <> 1 OR poGrid:Store:LayerName({&LAMP-LAYER}) <> "lamp" THEN
            UNDO, THROW NEW GridException("A Cuber grid has one layer, lamp").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Cuber game needs a random source").
        mRandom = poRandom.
        BuildDistances().
        Initialise().
    END CONSTRUCTOR.

    /* Moves time on: the milliseconds become frames (at SpeedPercent of 60 a second) and each one is made. Returns true when
       a frame was made, so the controller redraws. A stall of more than 100 ms is cut to 100. Does nothing while Paused. */
    METHOD PUBLIC LOGICAL Tick(INPUT piElapsedMs AS INTEGER):
        VAR INTEGER made.
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

    /* Starts a new game from any phase: no score, three Pips, level 1 round 1. */
    METHOD PUBLIC VOID StartGame():
        Score = 0.
        Lives = CuberRules:StartLives().
        mNextExtra = CuberRules:ExtraLifeEvery().
        mNotice = "".
        mFireReady = FALSE.
        GamesStarted = GamesStarted + 1.
        BeginRound(1, 1).
    END METHOD.

    /* A few words about what just happened (an extra Pip, a new round), or "" for nothing. Taking them clears them. */
    METHOD PUBLIC CHARACTER TakeNotice():
        VAR CHARACTER notice.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    /* Sets up a level and round (the light of the round, the rules of the level): every lamp dark, the halos placed, Pip on the
       apex, no enemies, and the READY banner. Throws GridException for a level under 1 or a round outside 1 to 4. */
    METHOD PUBLIC VOID BeginRound(INPUT piLevel AS INTEGER, INPUT piRound AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER j.
        VAR INTEGER t.
        VAR INTEGER[6] order.
        IF piLevel = ? OR piLevel < 1 THEN UNDO, THROW NEW GridException("A level is 1 or more, not " + STRING(piLevel)).
        IF piRound = ? OR piRound < 1 OR piRound > 4 THEN UNDO, THROW NEW GridException("A round is 1 to 4, not " + STRING(piRound)).
        LevelNo = piLevel.
        RoundNo = piRound.
        Grid:Store:FillLayer({&LAMP-LAYER}, 0).
        PyramidVersion = PyramidVersion + 1.
        /* the halos: a shuffle of the six places, and the first few are used */
        DO i = 1 TO 6:
            order[i] = i.
            mHalo[i] = 0.
            mHaloUsedAt[i] = -1.
        END.
        DO i = 6 TO 2 BY -1:
            j = 1 + mRandom:NextInt(i).
            t = order[i].
            order[i] = order[j].
            order[j] = t.
        END.
        DO i = 1 TO CuberRules:HalosIn(piLevel):
            mHalo[order[i]] = 1.
        END.
        BeginLife().
    END METHOD.

    /* ============================== the lamps ============================== */

    /* The state of a lamp: 0 not reached, 1 half way, 2 lit. Throws GridException for a row and column that are not a lamp. */
    METHOD PUBLIC INTEGER LampAt(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        CheckLamp(piRow, piCol).
        RETURN Lamp(piRow, piCol).
    END METHOD.

    /* Sets the state of a lamp, 0 to 2. Throws GridException for a row and column that are not a lamp, or a state outside 0 to 2. */
    METHOD PUBLIC VOID SetLamp(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER, INPUT piState AS INTEGER):
        CheckLamp(piRow, piCol).
        IF piState = ? OR piState < 0 OR piState > 2 THEN UNDO, THROW NEW GridException("A lamp is 0, 1 or 2, not " + STRING(piState)).
        PutLamp(piRow, piCol, piState).
    END METHOD.

    /* The state of a halo place, 1 to 6: 0 none, 1 waiting, 2 used. */
    METHOD PUBLIC INTEGER HaloState(INPUT piSpot AS INTEGER):
        CheckSpot(piSpot).
        RETURN mHalo[piSpot].
    END METHOD.

    /* The frame (Frames) a halo was used on, -1 when it was not. */
    METHOD PUBLIC INTEGER HaloUsedFrame(INPUT piSpot AS INTEGER):
        CheckSpot(piSpot).
        RETURN mHaloUsedAt[piSpot].
    END METHOD.

    /* Puts a halo in a place (true) or takes it away (false), for a scene. */
    METHOD PUBLIC VOID SetHalo(INPUT piSpot AS INTEGER, INPUT plOn AS LOGICAL):
        CheckSpot(piSpot).
        mHalo[piSpot] = (IF plOn THEN 1 ELSE 0).
        mHaloUsedAt[piSpot] = -1.
    END METHOD.

    /* Halos waiting now. */
    METHOD PUBLIC INTEGER HalosWaiting():
        VAR INTEGER i.
        VAR INTEGER n.
        DO i = 1 TO 6:
            IF mHalo[i] = 1 THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* ============================== Pip ============================== */

    /* Asks for a hop. It is done as soon as Pip is standing, and forgotten after 14 frames. Does nothing unless the game is being
       played. */
    METHOD PUBLIC VOID RequestHop(INPUT poDir AS CuberDir):
        IF Phase <> CuberPhase:Playing THEN RETURN.
        mWant = INTEGER(poDir).
        mWantAge = 0.
    END METHOD.

    /* Puts Pip standing on a lamp, for a scene. Throws GridException for a row and column that are not a lamp. */
    METHOD PUBLIC VOID PlacePip(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        CheckLamp(piRow, piCol).
        mPipR = piRow.
        mPipC = piCol.
        mPipToR = piRow.
        mPipToC = piCol.
        mPipF = 0.
        mPipMode = CuberPipMode:Standing.
        mPipModeF = 0.
        mPipFatal = FALSE.
        mPipStand = CuberRules:LandingFrames().
        mWant = -1.
    END METHOD.

    /* ============================== the enemies ============================== */

    METHOD PUBLIC LOGICAL EnemyOn(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mEnOn[piSlot + 1].
    END METHOD.

    METHOD PUBLIC CuberKind EnemyKind(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN CuberKind:GetEnum(mEnKind[piSlot + 1]).
    END METHOD.

    /* The lamp an enemy stands on, or hops from. */
    METHOD PUBLIC INTEGER EnemyRow(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN mEnR[piSlot + 1].
    END METHOD.

    METHOD PUBLIC INTEGER EnemyCol(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN mEnC[piSlot + 1].
    END METHOD.

    /* The lamp an enemy is hopping to (the one it stands on when it is not hopping). */
    METHOD PUBLIC INTEGER EnemyDestRow(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN (IF mEnMode[piSlot + 1] = INTEGER(CuberEnemyMode:Hopping) OR mEnMode[piSlot + 1] = INTEGER(CuberEnemyMode:Falling) THEN mEnToR[piSlot + 1] ELSE mEnR[piSlot + 1]).
    END METHOD.

    METHOD PUBLIC INTEGER EnemyDestCol(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN (IF mEnMode[piSlot + 1] = INTEGER(CuberEnemyMode:Hopping) OR mEnMode[piSlot + 1] = INTEGER(CuberEnemyMode:Falling) THEN mEnToC[piSlot + 1] ELSE mEnC[piSlot + 1]).
    END METHOD.

    METHOD PUBLIC CuberEnemyMode EnemyMode(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN CuberEnemyMode:GetEnum(mEnMode[piSlot + 1]).
    END METHOD.

    /* The frames an enemy has been in its mode, and the frame of its hop (0 when it is not hopping). */
    METHOD PUBLIC INTEGER EnemyModeFrames(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN mEnModeF[piSlot + 1].
    END METHOD.

    METHOD PUBLIC INTEGER EnemyHopFrame(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN mEnF[piSlot + 1].
    END METHOD.

    /* The way an enemy last hopped (the way it faces), a CuberDir. */
    METHOD PUBLIC CuberDir EnemyDirection(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN CuberDir:GetEnum(mEnDir[piSlot + 1]).
    END METHOD.

    /* True when an enemy is frozen (and so harmless). */
    METHOD PUBLIC LOGICAL EnemyFrozen(INPUT piSlot AS INTEGER):
        CheckEnemy(piSlot).
        RETURN mFreeze > 0.
    END METHOD.

    /* Where an enemy's feet are, in pixels of the picture, with its hop, its drop or its fall worked in. */
    METHOD PUBLIC INTEGER EnemyX(INPUT piSlot AS INTEGER):
        VAR INTEGER i.
        CheckEnemy(piSlot).
        i = piSlot + 1.
        RETURN ThingX(CuberPipMode:Standing, mEnR[i], mEnC[i], mEnToR[i], mEnToC[i], mEnF[i], mEnModeF[i], 10, mEnMode[i]).
    END METHOD.

    METHOD PUBLIC INTEGER EnemyY(INPUT piSlot AS INTEGER):
        VAR INTEGER i.
        CheckEnemy(piSlot).
        i = piSlot + 1.
        RETURN ThingY(CuberPipMode:Standing, mEnR[i], mEnC[i], mEnToR[i], mEnToC[i], mEnF[i], mEnModeF[i], 10, mEnMode[i]).
    END METHOD.

    /* Takes every enemy off the pyramid. */
    METHOD PUBLIC VOID ClearEnemies():
        VAR INTEGER i.
        DO i = 1 TO {&SLOTS}:
            mEnOn[i] = FALSE.
        END.
    END METHOD.

    /* Puts an enemy standing on a lamp, ready to hop at once, for a scene, and returns its place. Throws GridException for a row and
       column that are not a lamp, or when all the places are used. */
    METHOD PUBLIC INTEGER SpawnEnemy(INPUT poKind AS CuberKind, INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        VAR INTEGER i.
        CheckLamp(piRow, piCol).
        i = FreeSlot().
        IF i = 0 THEN UNDO, THROW NEW GridException("All the enemy places are used").
        Place(i, poKind, piRow, piCol, CuberEnemyMode:Resting).
        RETURN i - 1.
    END METHOD.

    /* Sets the frames an enemy has still to stand before its next hop, for a scene (a place that is not used throws GridException). */
    METHOD PUBLIC VOID SetEnemyRest(INPUT piSlot AS INTEGER, INPUT piFrames AS INTEGER):
        CheckEnemy(piSlot).
        mEnRest[piSlot + 1] = piFrames.
    END METHOD.

    /* Stops new enemies coming in, for a scene (a new round or game lets them come again). */
    METHOD PUBLIC VOID StopSpawns():
        mSpawnsOff = TRUE.
    END METHOD.

    /* ============================== the pop-ups ============================== */

    /* The points shown over something: 0 to PopSlots - 1, the points (0 for none yet), where (the feet of whatever scored) and the
       frames since. */
    METHOD PUBLIC INTEGER PopValue(INPUT piSlot AS INTEGER):
        CheckPop(piSlot).
        RETURN mPopValue[piSlot + 1].
    END METHOD.

    METHOD PUBLIC INTEGER PopX(INPUT piSlot AS INTEGER):
        CheckPop(piSlot).
        RETURN mPopX[piSlot + 1].
    END METHOD.

    METHOD PUBLIC INTEGER PopY(INPUT piSlot AS INTEGER):
        CheckPop(piSlot).
        RETURN mPopY[piSlot + 1].
    END METHOD.

    METHOD PUBLIC INTEGER PopAge(INPUT piSlot AS INTEGER):
        CheckPop(piSlot).
        RETURN (IF mPopValue[piSlot + 1] = 0 THEN -1 ELSE Frames - mPopAt[piSlot + 1]).
    END METHOD.

    /* ============================== scoring ============================== */

    /* Adds points to the score, and an extra Pip for each time it passes a multiple of 8000. Throws GridException for points under 0. */
    METHOD PUBLIC VOID AddScore(INPUT piPoints AS INTEGER):
        IF piPoints = ? OR piPoints < 0 THEN UNDO, THROW NEW GridException("Points are 0 or more, not " + STRING(piPoints)).
        Score = Score + piPoints.
        IF Score > HiScore THEN HiScore = Score.
        DO WHILE Score >= mNextExtra AND mNextExtra > 0:
            Lives = Lives + 1.
            ExtraLives = ExtraLives + 1.
            mNextExtra = mNextExtra + CuberRules:ExtraLifeEvery().
            mNotice = "Extra Pip".
        END.
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        Score = 0.
        Lives = CuberRules:StartLives().
        LevelNo = 1.
        RoundNo = 1.
        mNotice = "".
        mAcc = 0.
        mFireReady = FALSE.
        mNextExtra = CuberRules:ExtraLifeEvery().
        Grid:Store:FillLayer({&LAMP-LAYER}, 0).
        PyramidVersion = PyramidVersion + 1.
        ClearEnemies().
        ClearHalos().
        ClearPops().
        mFreeze = 0.
        mPipDir = CuberDir:DownRight.
        PlacePip(1, 0).
        SetPhase(CuberPhase:Title).
    END METHOD.

    /* ============================== one frame ============================== */

    METHOD PRIVATE VOID Step():
        Frames = Frames + 1.
        PhaseFrames = PhaseFrames + 1.
        CASE Phase:
            WHEN CuberPhase:Title OR WHEN CuberPhase:GameOver THEN StepWaiting().
            WHEN CuberPhase:Ready THEN IF PhaseFrames >= CuberRules:ReadyFrames() THEN SetPhase(CuberPhase:Playing).
            WHEN CuberPhase:Playing THEN StepPlaying().
            WHEN CuberPhase:Dying THEN StepDying().
            WHEN CuberPhase:Cleared THEN StepCleared().
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID SetPhase(INPUT poPhase AS CuberPhase):
        Phase = poPhase.
        PhaseFrames = 0.
    END METHOD.

    /* The title and game over screens: the fire key, let go and pressed again, goes on. */
    METHOD PRIVATE VOID StepWaiting():
        IF NOT FireHeld THEN DO:
            mFireReady = TRUE.
            RETURN.
        END.
        IF NOT mFireReady OR (Phase = CuberPhase:GameOver AND PhaseFrames < 90) THEN RETURN.
        mFireReady = FALSE.
        IF Phase = CuberPhase:Title THEN StartGame().
        ELSE DO:
            Initialise().
            mFireReady = FALSE.
        END.
    END METHOD.

    METHOD PRIVATE VOID StepPlaying():
        IF mFreeze > 0 THEN mFreeze = mFreeze - 1.
        StepPip().
        IF Phase <> CuberPhase:Playing THEN RETURN.
        StepEnemies().
        StepSpawns().
        IF Phase = CuberPhase:Playing THEN CheckTouches().
    END METHOD.

    METHOD PRIVATE VOID StepDying():
        mPipModeF = mPipModeF + 1.
        IF mPipModeF >= (IF mPipMode = CuberPipMode:Falling THEN CuberRules:FallFrames() ELSE CuberRules:HitFrames()) THEN AfterDeath().
        /* enemies already falling off the edge carry on falling */
        StepFalling().
    END METHOD.

    METHOD PRIVATE VOID StepCleared():
        mPipModeF = mPipModeF + 1.
        StepFalling().
        IF PhaseFrames >= CuberRules:ClearFrames() THEN DO:
            RoundsCleared = RoundsCleared + 1.
            IF RoundNo = 4 THEN DO:
                LevelsCleared = LevelsCleared + 1.
                BeginRound(LevelNo + 1, 1).
                mNotice = "Level " + STRING(LevelNo).
            END.
            ELSE DO:
                BeginRound(LevelNo, RoundNo + 1).
                mNotice = "Round " + STRING(RoundNo).
            END.
        END.
    END METHOD.

    /* ============================== Pip's hops ============================== */

    METHOD PRIVATE VOID StepPip():
        IF mWant >= 0 THEN DO:
            mWantAge = mWantAge + 1.
            IF mWantAge > CuberRules:WantFrames() THEN mWant = -1.
        END.
        CASE mPipMode:
            WHEN CuberPipMode:Standing THEN DO:
                mPipStand = mPipStand + 1.
                IF mWant >= 0 AND mPipStand >= CuberRules:LandingFrames() THEN BeginHop(CuberDir:GetEnum(mWant)).
            END.
            WHEN CuberPipMode:Hopping THEN DO:
                mPipF = mPipF + 1.
                mPipModeF = mPipModeF + 1.
                IF mPipF >= CuberRules:HopFrames() THEN Landed().
            END.
            WHEN CuberPipMode:Riding THEN DO:
                mPipModeF = mPipModeF + 1.
                IF mPipModeF >= CuberRules:RideFrames() THEN RideEnds().
            END.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID BeginHop(INPUT poDir AS CuberDir):
        VAR INTEGER spot.
        mPipToR = CuberRules:HopRow(mPipR, poDir).
        mPipToC = CuberRules:HopCol(mPipC, poDir).
        spot = CuberRules:HaloSpotAt(mPipToR, mPipToC).
        mPipFatal = NOT CuberRules:IsLamp(mPipToR, mPipToC) AND NOT (spot > 0 AND mHalo[MAXIMUM(1, spot)] = 1).
        mPipDir = poDir.
        mPipF = 0.
        mPipModeF = 0.
        mPipMode = CuberPipMode:Hopping.
        mWant = -1.
        Hops = Hops + 1.
    END METHOD.

    /* The hop has reached its end: on a lamp (which is lit), on a halo (which lifts Pip) or in the air over nothing (a fall). */
    METHOD PRIVATE VOID Landed():
        VAR INTEGER spot.
        mPipR = mPipToR.
        mPipC = mPipToC.
        mPipF = 0.
        mPipModeF = 0.
        mPipStand = 0.
        IF CuberRules:IsLamp(mPipR, mPipC) THEN DO:
            mPipMode = CuberPipMode:Standing.
            LandOn(mPipR, mPipC).
            RETURN.
        END.
        spot = CuberRules:HaloSpotAt(mPipR, mPipC).
        IF spot > 0 AND mHalo[MAXIMUM(1, spot)] = 1 THEN DO:
            StartRide(spot).
            RETURN.
        END.
        /* a fall: off the front when the hop was down, off the back when it was up */
        mPipFront = (mPipDir = CuberDir:DownLeft OR mPipDir = CuberDir:DownRight).
        mPipMode = CuberPipMode:Falling.
        Falls = Falls + 1.
        SetPhase(CuberPhase:Dying).
    END METHOD.

    /* Pip lands on a lamp: it lights, or goes back a step when the level says so. */
    METHOD PRIVATE VOID LandOn(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        VAR INTEGER state.
        VAR INTEGER hits.
        state = Lamp(piRow, piCol).
        hits = CuberRules:HitsToLight(LevelNo).
        IF state < 2 THEN DO:
            IF hits = 1 OR state = 1 THEN DO:
                PutLamp(piRow, piCol, 2).
                LampsLit = LampsLit + 1.
                LastLitRow = piRow.
                LastLitCol = piCol.
                LastLitFrame = Frames.
                AddPop(CuberRules:PointsLamp(), CuberRules:FootX(piRow, piCol), CuberRules:FootY(piRow)).
                AddScore(CuberRules:PointsLamp()).
            END.
            ELSE DO:
                PutLamp(piRow, piCol, 1).
                LampsRinged = LampsRinged + 1.
                AddScore(CuberRules:PointsHalfLamp()).
            END.
        END.
        ELSE IF CuberRules:UndoOnLand(LevelNo) THEN DO:
            PutLamp(piRow, piCol, (IF hits = 1 THEN 0 ELSE 1)).
            LampsPutOut = LampsPutOut + 1.
        END.
        IF Phase = CuberPhase:Playing AND LampsDone = CuberRules:LampTotal() THEN RoundDone().
    END METHOD.

    /* Pip steps onto a halo: the halo is used up, and the enemies are gone (the hunting Coil falls off the edge following). */
    METHOD PRIVATE VOID StartRide(INPUT piSpot AS INTEGER):
        VAR INTEGER i.
        mRideSpot = piSpot.
        mHalo[piSpot] = 2.
        mHaloUsedAt[piSpot] = Frames.
        mPipMode = CuberPipMode:Riding.
        mPipModeF = 0.
        Rides = Rides + 1.
        DO i = 1 TO {&SLOTS}:
            IF mEnOn[i] THEN DO:
                IF mEnKind[i] = INTEGER(CuberKind:Coil) AND mEnMode[i] <> INTEGER(CuberEnemyMode:Falling) THEN DO:
                    mEnMode[i] = INTEGER(CuberEnemyMode:Falling).
                    mEnModeF[i] = 0.
                    mEnToR[i] = mEnR[i].
                    mEnToC[i] = mEnC[i].
                    mEnF[i] = 0.
                    CoilFalls = CoilFalls + 1.
                    AddPop(CuberRules:PointsCoil(), CuberRules:FootX(mEnR[i], mEnC[i]), CuberRules:FootY(mEnR[i])).
                    AddScore(CuberRules:PointsCoil()).
                END.
                ELSE IF mEnMode[i] <> INTEGER(CuberEnemyMode:Falling) THEN mEnOn[i] = FALSE.
            END.
        END.
        mFreeze = 0.
    END METHOD.

    /* The ride is over: Pip is back on the apex. */
    METHOD PRIVATE VOID RideEnds():
        mPipR = 1.
        mPipC = 0.
        mPipToR = 1.
        mPipToC = 0.
        mPipMode = CuberPipMode:Standing.
        mPipModeF = 0.
        mPipStand = 0.
        ResetTimers().
        /* the apex is a lamp like the others: landing on it counts */
        LandOn(1, 0).
    END METHOD.

    /* ============================== the enemies ============================== */

    METHOD PRIVATE VOID StepEnemies():
        VAR INTEGER i.
        DO i = 1 TO {&SLOTS}:
            IF mEnOn[i] THEN StepEnemy(i).
        END.
        /* a hatched seed that has been removed while the loop ran leaves nothing behind */
    END METHOD.

    /* Enemies falling off the edge go on falling when everything else stands still. */
    METHOD PRIVATE VOID StepFalling():
        VAR INTEGER i.
        DO i = 1 TO {&SLOTS}:
            IF mEnOn[i] AND mEnMode[i] = INTEGER(CuberEnemyMode:Falling) THEN DO:
                mEnModeF[i] = mEnModeF[i] + 1.
                IF mEnModeF[i] >= 40 THEN mEnOn[i] = FALSE.
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID StepEnemy(INPUT i AS INTEGER):
        CASE CuberEnemyMode:GetEnum(mEnMode[i]):
            WHEN CuberEnemyMode:Dropping THEN DO:
                mEnModeF[i] = mEnModeF[i] + 1.
                IF mEnModeF[i] >= 8 THEN DO:
                    mEnMode[i] = INTEGER(CuberEnemyMode:Resting).
                    mEnModeF[i] = 0.
                    mEnRest[i] = RestOf(i).
                END.
            END.
            WHEN CuberEnemyMode:Resting THEN DO:
                mEnModeF[i] = mEnModeF[i] + 1.
                IF mFreeze = 0 THEN DO:
                    mEnRest[i] = mEnRest[i] - 1.
                    IF mEnRest[i] <= 0 THEN BeginEnemyHop(i).
                END.
            END.
            WHEN CuberEnemyMode:Hopping THEN DO:
                mEnF[i] = mEnF[i] + 1.
                mEnModeF[i] = mEnModeF[i] + 1.
                IF mEnF[i] >= CuberRules:HopFrames() THEN EnemyLanded(i).
            END.
            WHEN CuberEnemyMode:Hatching THEN DO:
                mEnModeF[i] = mEnModeF[i] + 1.
                IF mEnModeF[i] >= CuberRules:HatchFrames() THEN DO:
                    mEnKind[i] = INTEGER(CuberKind:Coil).
                    mEnMode[i] = INTEGER(CuberEnemyMode:Resting).
                    mEnModeF[i] = 0.
                    mEnRest[i] = RestOf(i).
                END.
            END.
            WHEN CuberEnemyMode:Falling THEN DO:
                mEnModeF[i] = mEnModeF[i] + 1.
                IF mEnModeF[i] >= 40 THEN mEnOn[i] = FALSE.
            END.
        END CASE.
    END METHOD.

    /* The frames an enemy stands between hops, by what it is. */
    METHOD PRIVATE INTEGER RestOf(INPUT i AS INTEGER):
        CASE CuberKind:GetEnum(mEnKind[i]):
            WHEN CuberKind:Coil THEN RETURN CuberRules:CoilRest(Tempo).
            WHEN CuberKind:Snuff OR WHEN CuberKind:Puff THEN RETURN CuberRules:MothRest(Tempo).
            OTHERWISE RETURN CuberRules:BallRest(Tempo).
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID BeginEnemyHop(INPUT i AS INTEGER):
        VAR CuberDir dir.
        CASE CuberKind:GetEnum(mEnKind[i]):
            WHEN CuberKind:Coil THEN dir = CoilDirection(i).
            WHEN CuberKind:Snuff THEN dir = CuberDir:UpRight.
            WHEN CuberKind:Puff THEN dir = CuberDir:UpLeft.
            OTHERWISE dir = (IF mRandom:NextInt(2) = 0 THEN CuberDir:DownLeft ELSE CuberDir:DownRight).
        END CASE.
        mEnToR[i] = CuberRules:HopRow(mEnR[i], dir).
        mEnToC[i] = CuberRules:HopCol(mEnC[i], dir).
        mEnDir[i] = INTEGER(dir).
        mEnF[i] = 0.
        mEnModeF[i] = 0.
        mEnMode[i] = INTEGER(CuberEnemyMode:Hopping).
    END METHOD.

    /* The way the Coil hops: usually the one that brings it nearest to Pip, else any that stays on the pyramid. */
    METHOD PRIVATE CuberDir CoilDirection(INPUT i AS INTEGER):
        VAR INTEGER d.
        VAR INTEGER nr.
        VAR INTEGER nc.
        VAR INTEGER best = 999.
        VAR INTEGER bestDir = -1.
        VAR INTEGER n.
        VAR INTEGER pick.
        VAR INTEGER target.
        VAR INTEGER[4] valid.
        target = LampIndex(PipDestRow, PipDestCol).
        IF NOT CuberRules:IsLamp(PipDestRow, PipDestCol) THEN target = LampIndex(mPipR, mPipC).
        DO d = 0 TO 3:
            nr = CuberRules:HopRow(mEnR[i], CuberDir:GetEnum(d)).
            nc = CuberRules:HopCol(mEnC[i], CuberDir:GetEnum(d)).
            IF CuberRules:IsLamp(nr, nc) THEN DO:
                n = n + 1.
                valid[n] = d.
                IF mDist[LampIndex(nr, nc) * 28 + target + 1] < best THEN ASSIGN
                    best = mDist[LampIndex(nr, nc) * 28 + target + 1]
                    bestDir = d.
            END.
        END.
        IF bestDir >= 0 AND mRandom:NextInt(100) < CuberRules:CoilAim(Tempo) THEN RETURN CuberDir:GetEnum(bestDir).
        pick = 1 + mRandom:NextInt(n).
        RETURN CuberDir:GetEnum(valid[pick]).
    END METHOD.

    /* An enemy's hop has ended. */
    METHOD PRIVATE VOID EnemyLanded(INPUT i AS INTEGER):
        VAR LOGICAL onLamp.
        mEnR[i] = mEnToR[i].
        mEnC[i] = mEnToC[i].
        mEnF[i] = 0.
        mEnModeF[i] = 0.
        onLamp = CuberRules:IsLamp(mEnR[i], mEnC[i]).
        IF NOT onLamp THEN DO:
            mEnMode[i] = INTEGER(CuberEnemyMode:Falling).
            RETURN.
        END.
        mEnMode[i] = INTEGER(CuberEnemyMode:Resting).
        mEnRest[i] = RestOf(i).
        CASE CuberKind:GetEnum(mEnKind[i]):
            WHEN CuberKind:Seed THEN DO:
                IF mEnR[i] = CuberRules:Rows() THEN DO:
                    mEnMode[i] = INTEGER(CuberEnemyMode:Hatching).
                    Hatchings = Hatchings + 1.
                END.
            END.
            WHEN CuberKind:Snuff OR WHEN CuberKind:Puff THEN PutOut(mEnR[i], mEnC[i]).
        END CASE.
    END METHOD.

    /* A moth lands: the lamp goes back a step. */
    METHOD PRIVATE VOID PutOut(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        VAR INTEGER state.
        state = Lamp(piRow, piCol).
        IF state > 0 THEN DO:
            PutLamp(piRow, piCol, (IF CuberRules:HitsToLight(LevelNo) = 1 THEN 0 ELSE state - 1)).
            LampsPutOut = LampsPutOut + 1.
        END.
    END METHOD.

    /* ---- what comes in ---- */

    METHOD PRIVATE VOID StepSpawns():
        VAR INTEGER i.
        VAR LOGICAL hunter.
        VAR LOGICAL frost.
        VAR LOGICAL snuff.
        VAR LOGICAL puff.
        IF mSpawnsOff OR mFreeze > 0 THEN RETURN.
        DO i = 1 TO {&SLOTS}:
            IF mEnOn[i] THEN CASE CuberKind:GetEnum(mEnKind[i]):
                WHEN CuberKind:Seed OR WHEN CuberKind:Coil THEN hunter = TRUE.
                WHEN CuberKind:Frost THEN frost = TRUE.
                WHEN CuberKind:Snuff THEN snuff = TRUE.
                WHEN CuberKind:Puff THEN puff = TRUE.
            END CASE.
        END.
        /* the seed: when nothing hunts, it comes after a pause */
        IF NOT hunter THEN DO:
            mSeedT = mSeedT - 1.
            IF mSeedT <= 0 THEN DO:
                DropIn(CuberKind:Seed).
                mSeedT = CuberRules:SeedDelay().
            END.
        END.
        mThornT = mThornT - 1.
        IF mThornT <= 0 THEN DO:
            DropIn(CuberKind:Thorn).
            mThornT = CuberRules:ThornEvery(Tempo) + mRandom:NextInt(60).
        END.
        mFrostT = mFrostT - 1.
        IF mFrostT <= 0 THEN DO:
            IF NOT frost THEN DropIn(CuberKind:Frost).
            mFrostT = CuberRules:FrostEvery() + mRandom:NextInt(300).
        END.
        IF CuberRules:MothsCome(LevelNo) THEN DO:
            mMothT = mMothT - 1.
            IF mMothT <= 0 THEN DO:
                IF NOT snuff AND (puff OR mRandom:NextInt(2) = 0) THEN SpawnMoth(CuberKind:Snuff).
                ELSE IF NOT puff THEN SpawnMoth(CuberKind:Puff).
                mMothT = CuberRules:MothEvery(Tempo) + mRandom:NextInt(60).
            END.
        END.
    END METHOD.

    /* A ball (or the seed) falls in on one of the two lamps of row 2. */
    METHOD PRIVATE VOID DropIn(INPUT poKind AS CuberKind):
        VAR INTEGER i.
        i = FreeSlot().
        IF i = 0 THEN RETURN.
        Place(i, poKind, 2, mRandom:NextInt(2), CuberEnemyMode:Dropping).
    END METHOD.

    /* A moth comes in at the bottom of its edge. */
    METHOD PRIVATE VOID SpawnMoth(INPUT poKind AS CuberKind):
        VAR INTEGER i.
        i = FreeSlot().
        IF i = 0 THEN RETURN.
        Place(i, poKind, CuberRules:Rows(), (IF poKind = CuberKind:Snuff THEN 0 ELSE CuberRules:Rows() - 1), CuberEnemyMode:Resting).
        mEnRest[i] = 20.
    END METHOD.

    METHOD PRIVATE VOID Place(INPUT i AS INTEGER, INPUT poKind AS CuberKind, INPUT piRow AS INTEGER, INPUT piCol AS INTEGER,
                              INPUT poMode AS CuberEnemyMode):
        mEnOn[i] = TRUE.
        mEnKind[i] = INTEGER(poKind).
        mEnR[i] = piRow.
        mEnC[i] = piCol.
        mEnToR[i] = piRow.
        mEnToC[i] = piCol.
        mEnF[i] = 0.
        mEnModeF[i] = 0.
        mEnMode[i] = INTEGER(poMode).
        mEnRest[i] = 1.
        mEnDir[i] = INTEGER(CuberDir:DownRight).
        IF poKind = CuberKind:Snuff THEN mEnDir[i] = INTEGER(CuberDir:UpRight).
        IF poKind = CuberKind:Puff THEN mEnDir[i] = INTEGER(CuberDir:UpLeft).
    END METHOD.

    METHOD PRIVATE INTEGER FreeSlot():
        VAR INTEGER i.
        DO i = 1 TO {&SLOTS}:
            IF NOT mEnOn[i] THEN RETURN i.
        END.
        RETURN 0.
    END METHOD.

    /* ============================== touching ============================== */

    /* Pip and the enemies, lamp against lamp: each is counted on the lamp it hops to once the hop is half done. */
    METHOD PRIVATE VOID CheckTouches():
        VAR INTEGER i.
        VAR INTEGER pr.
        VAR INTEGER pc.
        VAR INTEGER er.
        VAR INTEGER ec.
        IF mPipMode = CuberPipMode:Hopping AND mPipF >= 6 THEN ASSIGN pr = mPipToR pc = mPipToC.
        ELSE ASSIGN pr = mPipR pc = mPipC.
        IF mPipMode <> CuberPipMode:Standing AND mPipMode <> CuberPipMode:Hopping THEN RETURN.
        IF NOT CuberRules:IsLamp(pr, pc) THEN RETURN.
        DO i = 1 TO {&SLOTS}:
            IF mEnOn[i] AND mEnMode[i] <> INTEGER(CuberEnemyMode:Dropping) AND mEnMode[i] <> INTEGER(CuberEnemyMode:Falling) THEN DO:
                IF mEnMode[i] = INTEGER(CuberEnemyMode:Hopping) AND mEnF[i] >= 6 THEN ASSIGN er = mEnToR[i] ec = mEnToC[i].
                ELSE ASSIGN er = mEnR[i] ec = mEnC[i].
                IF er = pr AND ec = pc THEN DO:
                    Touch(i).
                    IF Phase <> CuberPhase:Playing THEN RETURN.
                END.
            END.
        END.
    END METHOD.

    /* Pip and one enemy are on the same lamp. */
    METHOD PRIVATE VOID Touch(INPUT i AS INTEGER):
        VAR INTEGER x.
        VAR INTEGER y.
        x = CuberRules:FootX(mEnR[i], mEnC[i]).
        y = CuberRules:FootY(mEnR[i]).
        CASE CuberKind:GetEnum(mEnKind[i]):
            WHEN CuberKind:Frost THEN DO:
                mEnOn[i] = FALSE.
                mFreeze = CuberRules:FreezeFrames(Tempo).
                FreezeFrame = Frames.
                FreezeX = x.
                FreezeY = y.
                FrostsTouched = FrostsTouched + 1.
                AddPop(CuberRules:PointsFrost(), x, y).
                AddScore(CuberRules:PointsFrost()).
            END.
            WHEN CuberKind:Snuff OR WHEN CuberKind:Puff THEN DO:
                mEnOn[i] = FALSE.
                MothsCaught = MothsCaught + 1.
                AddPop(CuberRules:PointsMoth(), x, y).
                AddScore(CuberRules:PointsMoth()).
            END.
            OTHERWISE IF mFreeze = 0 THEN DO:
                /* a seed, a Coil or a Thorn that is not frozen */
                Hits = Hits + 1.
                mPipMode = CuberPipMode:Hit.
                mPipModeF = 0.
                mWant = -1.
                Deaths = Deaths + 1.
                SetPhase(CuberPhase:Dying).
            END.
        END CASE.
    END METHOD.

    /* ============================== lives and rounds ============================== */

    /* The death has played out: a Pip fewer, and the next life or the end. */
    METHOD PRIVATE VOID AfterDeath():
        IF mPipMode = CuberPipMode:Falling THEN Deaths = Deaths + 1.
        IF Lives > 0 THEN DO:
            Lives = Lives - 1.
            BeginLife().
        END.
        ELSE SetPhase(CuberPhase:GameOver).
    END METHOD.

    /* Pip on the apex, nothing else on the pyramid, READY. The lamps stay as they are. */
    METHOD PRIVATE VOID BeginLife():
        ClearEnemies().
        mFreeze = 0.
        mSpawnsOff = FALSE.
        mPipFront = FALSE.
        mPipDir = CuberDir:DownLeft.
        PlacePip(1, 0).
        ResetTimers().
        SetPhase(CuberPhase:Ready).
    END METHOD.

    METHOD PRIVATE VOID ResetTimers():
        mSeedT = CuberRules:SeedDelay().
        mThornT = 120 + mRandom:NextInt(60).
        mFrostT = INTEGER(TRUNCATE(CuberRules:FrostEvery() / 2, 0)) + mRandom:NextInt(200).
        mMothT = 300.
    END METHOD.

    /* Every lamp is lit: the enemies go, the halos left over pay, and the ripple runs. */
    METHOD PRIVATE VOID RoundDone():
        VAR INTEGER i.
        DO i = 1 TO {&SLOTS}:
            IF mEnOn[i] AND mEnMode[i] <> INTEGER(CuberEnemyMode:Falling) THEN mEnOn[i] = FALSE.
        END.
        DO i = 1 TO 6:
            IF mHalo[i] = 1 THEN DO:
                AddPop(CuberRules:PointsHalo(), CuberRules:FootX(CuberRules:HaloRow(i), CuberRules:HaloCol(i)), CuberRules:FootY(CuberRules:HaloRow(i))).
                AddScore(CuberRules:PointsHalo()).
            END.
        END.
        mPipMode = CuberPipMode:Winning.
        mPipModeF = 0.
        mWant = -1.
        SetPhase(CuberPhase:Cleared).
    END METHOD.

    /* ============================== small helpers ============================== */

    METHOD PRIVATE INTEGER Lamp(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        RETURN Grid:Store:GetCellAt({&LAMP-LAYER}, (piRow - 1) * CuberRules:Rows() + piCol).
    END METHOD.

    METHOD PRIVATE VOID PutLamp(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER, INPUT piState AS INTEGER):
        Grid:Store:SetCellAt({&LAMP-LAYER}, (piRow - 1) * CuberRules:Rows() + piCol, piState).
        PyramidVersion = PyramidVersion + 1.
    END METHOD.

    /* The number of a lamp, 0 to 27. */
    METHOD PRIVATE INTEGER LampIndex(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        RETURN INTEGER((piRow * (piRow - 1)) / 2) + piCol.
    END METHOD.

    METHOD PRIVATE VOID ClearHalos():
        VAR INTEGER i.
        DO i = 1 TO 6:
            mHalo[i] = 0.
            mHaloUsedAt[i] = -1.
        END.
    END METHOD.

    METHOD PRIVATE VOID ClearPops():
        VAR INTEGER i.
        DO i = 1 TO {&POPS}:
            mPopValue[i] = 0.
        END.
        mPopN = 0.
    END METHOD.

    METHOD PRIVATE VOID AddPop(INPUT piValue AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        mPopN = (mPopN MODULO {&POPS}) + 1.
        mPopValue[mPopN] = piValue.
        mPopX[mPopN] = piX.
        mPopY[mPopN] = piY.
        mPopAt[mPopN] = Frames.
    END METHOD.

    /* The hops from every lamp to every other, by a sweep outwards from each one. */
    METHOD PRIVATE VOID BuildDistances():
        VAR INTEGER s.
        VAR INTEGER pass.
        VAR INTEGER r.
        VAR INTEGER c.
        VAR INTEGER d.
        VAR INTEGER nr.
        VAR INTEGER nc.
        VAR INTEGER here.
        VAR INTEGER there.
        DO s = 0 TO 27:
            DO r = 0 TO 27:
                mDist[s * 28 + r + 1] = 99.
            END.
            mDist[s * 28 + s + 1] = 0.
            DO pass = 1 TO 12:
                DO r = 1 TO 7:
                    DO c = 0 TO r - 1:
                        here = mDist[s * 28 + LampIndex(r, c) + 1].
                        IF here < 99 THEN DO d = 0 TO 3:
                            nr = CuberRules:HopRow(r, CuberDir:GetEnum(d)).
                            nc = CuberRules:HopCol(c, CuberDir:GetEnum(d)).
                            IF CuberRules:IsLamp(nr, nc) THEN DO:
                                there = LampIndex(nr, nc).
                                IF mDist[s * 28 + there + 1] > here + 1 THEN mDist[s * 28 + there + 1] = here + 1.
                            END.
                        END.
                    END.
                END.
            END.
        END.
    END METHOD.

    /* The pixel x or y of the feet of Pip (piHeight 12) or an enemy (10) in whatever it is doing. For Pip pcMode is its mode; for
       an enemy the mode is given as piEnemyMode (-1 for Pip). */
    METHOD PRIVATE INTEGER ThingX(INPUT poPip AS CuberPipMode, INPUT piR AS INTEGER, INPUT piC AS INTEGER, INPUT piToR AS INTEGER,
                                  INPUT piToC AS INTEGER, INPUT piF AS INTEGER, INPUT piModeF AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN ThingX(poPip, piR, piC, piToR, piToC, piF, piModeF, piHeight, -1).
    END METHOD.

    METHOD PRIVATE INTEGER ThingX(INPUT poPip AS CuberPipMode, INPUT piR AS INTEGER, INPUT piC AS INTEGER, INPUT piToR AS INTEGER,
                                  INPUT piToC AS INTEGER, INPUT piF AS INTEGER, INPUT piModeF AS INTEGER, INPUT piHeight AS INTEGER,
                                  INPUT piEnemyMode AS INTEGER):
        VAR INTEGER x0.
        VAR INTEGER x1.
        x0 = CuberRules:FootX(piR, piC).
        x1 = CuberRules:FootX(piToR, piToC).
        IF piEnemyMode >= 0 THEN DO:
            IF piEnemyMode = INTEGER(CuberEnemyMode:Hopping) THEN RETURN x0 + INTEGER(ROUND((x1 - x0) * piF / 12.0, 0)).
            IF piEnemyMode = INTEGER(CuberEnemyMode:Falling) THEN RETURN x1.
            RETURN x0.
        END.
        CASE poPip:
            WHEN CuberPipMode:Hopping THEN RETURN x0 + INTEGER(ROUND((x1 - x0) * piF / 12.0, 0)).
            WHEN CuberPipMode:Falling THEN RETURN x1.
            WHEN CuberPipMode:Riding THEN RETURN CuberRules:FootX(CuberRules:HaloRow(mRideSpot), CuberRules:HaloCol(mRideSpot))
                                                 + INTEGER(ROUND((128 - CuberRules:FootX(CuberRules:HaloRow(mRideSpot), CuberRules:HaloCol(mRideSpot))) * piModeF / CuberRules:RideFrames(), 0)).
            OTHERWISE RETURN x0.
        END CASE.
    END METHOD.

    METHOD PRIVATE INTEGER ThingY(INPUT poPip AS CuberPipMode, INPUT piR AS INTEGER, INPUT piC AS INTEGER, INPUT piToR AS INTEGER,
                                  INPUT piToC AS INTEGER, INPUT piF AS INTEGER, INPUT piModeF AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN ThingY(poPip, piR, piC, piToR, piToC, piF, piModeF, piHeight, -1).
    END METHOD.

    METHOD PRIVATE INTEGER ThingY(INPUT poPip AS CuberPipMode, INPUT piR AS INTEGER, INPUT piC AS INTEGER, INPUT piToR AS INTEGER,
                                  INPUT piToC AS INTEGER, INPUT piF AS INTEGER, INPUT piModeF AS INTEGER, INPUT piHeight AS INTEGER,
                                  INPUT piEnemyMode AS INTEGER):
        VAR INTEGER y0.
        VAR INTEGER y1.
        VAR INTEGER fall.
        y0 = CuberRules:FootY(piR).
        y1 = CuberRules:FootY(piToR).
        IF piEnemyMode >= 0 THEN DO:
            CASE CuberEnemyMode:GetEnum(piEnemyMode):
                WHEN CuberEnemyMode:Hopping THEN RETURN y0 + INTEGER(ROUND((y1 - y0) * piF / 12.0, 0)) - CuberRules:HopLift(piF, piHeight).
                WHEN CuberEnemyMode:Dropping THEN RETURN y0 - (24 - 3 * piModeF).
                WHEN CuberEnemyMode:Falling THEN DO:
                    fall = 2 * piModeF + INTEGER(TRUNCATE(7 * piModeF * piModeF / 40, 0)).
                    RETURN y1 + fall.
                END.
                OTHERWISE RETURN y0.
            END CASE.
        END.
        CASE poPip:
            WHEN CuberPipMode:Hopping THEN RETURN y0 + INTEGER(ROUND((y1 - y0) * piF / 12.0, 0)) - CuberRules:HopLift(piF, piHeight).
            WHEN CuberPipMode:Falling THEN DO:
                fall = 2 * piModeF + INTEGER(TRUNCATE(7 * piModeF * piModeF / 40, 0)).
                RETURN y1 + fall.
            END.
            WHEN CuberPipMode:Riding THEN RETURN CuberRules:FootY(CuberRules:HaloRow(mRideSpot))
                                                 + INTEGER(ROUND((40 - CuberRules:FootY(CuberRules:HaloRow(mRideSpot))) * piModeF / CuberRules:RideFrames(), 0)).
            OTHERWISE RETURN y0.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID CheckLamp(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        IF piRow = ? OR piCol = ? OR NOT CuberRules:IsLamp(piRow, piCol) THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Row &1, column &2 is not a lamp of the pyramid", piRow, piCol)).
    END METHOD.

    METHOD PRIVATE VOID CheckSpot(INPUT piSpot AS INTEGER):
        IF piSpot = ? OR piSpot < 1 OR piSpot > 6 THEN UNDO, THROW NEW GridException("A halo place is 1 to 6, not " + STRING(piSpot)).
    END METHOD.

    METHOD PRIVATE VOID CheckSlot(INPUT piSlot AS INTEGER):
        IF piSlot = ? OR piSlot < 0 OR piSlot >= {&SLOTS} THEN UNDO, THROW NEW GridException(SUBSTITUTE("An enemy place is 0 to &1, not &2", {&SLOTS} - 1, piSlot)).
    END METHOD.

    /* The place must be used by an enemy. */
    METHOD PRIVATE VOID CheckEnemy(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        IF NOT mEnOn[piSlot + 1] THEN UNDO, THROW NEW GridException("There is no enemy in place " + STRING(piSlot)).
    END METHOD.

    METHOD PRIVATE VOID CheckPop(INPUT piSlot AS INTEGER):
        IF piSlot = ? OR piSlot < 0 OR piSlot >= {&POPS} THEN UNDO, THROW NEW GridException(SUBSTITUTE("A pop-up place is 0 to &1, not &2", {&POPS} - 1, piSlot)).
    END METHOD.

END CLASS.
