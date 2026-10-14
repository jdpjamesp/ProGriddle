/* Space Invaders, with the rules of the 1978 arcade game on the arcade's own 224 x 256 grid, one cell to a pixel.
   It is a real time game that runs at 60 frames a second whatever the clock does: Tick adds up the time it is
   given and makes a frame for every sixtieth of a second, so a test drives it frame by frame with Advance.

   The rules, as the arcade had them:
   - 55 invaders in 5 rows of 11, which move ONE a frame (see InvaderRack), so they speed up as they die. A
     squid is worth 30 points, a crab 20 and an octopus 10. They drop 8 cells and turn at each edge. If the lowest
     reaches the cannon's row the invaders have landed and the game is over, whatever lives are left.
   - The cannon moves 1 cell a frame and has ONE shot at a time: it cannot fire again until its shot has hit
     something or reached the top. A shot moves 4 cells a frame. Holding the fire key fires again at once when
     the shot is gone. A shot that meets an invader's bomb destroys both.
   - Three kinds of bomb, at most one of each in the air, 3 in all. The rolling one is dropped from the column
     above the cannon, the other two from columns in a fixed pattern. They fall about 1.25 cells a frame. As in the
     arcade the reload is a distance as well as a time: a new bomb is only dropped once every bomb already falling
     has come a fair way down, and not sooner than a gap after the last one (3 frames for each reload step, see
     ReloadFor). Both shorten as the score goes up, so at the start there is a bomb every 2.4 seconds or so and
     later one every half second. The squiggly bomb is not dropped while the saucer is out.
   - Four shields that wear away a mark at a time where a shot or a bomb hits them, and that the invaders eat
     as they pass through. They are rebuilt at the start of each wave.
   - The saucer crosses the top about every 25 seconds, never with fewer than 8 invaders left. It is worth 50,
     100, 150 or 300 points according to how many shots the cannon has fired (the arcade's table, so the 23rd
     shot is worth 300, and every 15th after it).
   - Three lives, and an extra one at 1500 points. Each new wave starts the rack lower down the screen.
   - The cannon cannot move or fire while a wave is being drawn in, nor while it is exploding.

   The game is never "over" to its controller: a game ends in the GAMEOVER phase, which waits for the fire key and
   goes back to the TITLE screen, so the clock keeps running and the stars keep drifting. The picture is drawn on
   an InvadersCanvas: what a shot hits is decided by the kind layer, never by colour. The game owns its grid.
   Dispose releases it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.SpaceInvadersGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    {ProGriddle/Games/SpaceInvaders/Kinds.i}
    {ProGriddle/Games/SpaceInvaders/Art.i}
    {ProGriddle/Games/SpaceInvaders/Colours.i}
    {ProGriddle/Games/SpaceInvaders/Phases.i}

    /* the field and where things stand on it */
    &SCOPED-DEFINE WIDTH 224
    &SCOPED-DEFINE HEIGHT 256
    &SCOPED-DEFINE PLAYER-Y 216
    &SCOPED-DEFINE PLAYER-MIN 8
    &SCOPED-DEFINE PLAYER-MAX 203
    &SCOPED-DEFINE PLAYER-START 105
    &SCOPED-DEFINE GROUND-Y 232
    &SCOPED-DEFINE SHIELD-Y 184
    &SCOPED-DEFINE SHIELD-X 35
    &SCOPED-DEFINE SHIELD-PITCH 44
    &SCOPED-DEFINE SAUCER-Y 32
    &SCOPED-DEFINE SHOT-TOP 30
    /* how long things take, in frames */
    &SCOPED-DEFINE DYING-FRAMES 110
    &SCOPED-DEFINE CLEARED-FRAMES 90
    &SCOPED-DEFINE STARTING-FRAMES 130
    &SCOPED-DEFINE SAUCER-FRAMES 1536
    &SCOPED-DEFINE POP-FRAMES 50
    &SCOPED-DEFINE EXTRA-LIFE-AT 1500
    /* the most frames one Tick will make, and the most time it will count: a stall must not make a burst */
    &SCOPED-DEFINE MOST-FRAMES 4
    &SCOPED-DEFINE MOST-MS 100
    /* what the effects use */
    &SCOPED-DEFINE FX-SLOTS 16
    &SCOPED-DEFINE PARTICLES 64
    &SCOPED-DEFINE STARS 48

    DEFINE PRIVATE VARIABLE mRandom      AS IRandom         NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas      AS InvadersCanvas  NO-UNDO.
    DEFINE PRIVATE VARIABLE mRack        AS InvaderRack     NO-UNDO.
    DEFINE PRIVATE VARIABLE mFirst       AS LOGICAL         NO-UNDO INITIAL TRUE.
    DEFINE PRIVATE VARIABLE mAcc         AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mFrames      AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mTimer       AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mArmed       AS LOGICAL         NO-UNDO.
    DEFINE PRIVATE VARIABLE mInvaded     AS LOGICAL         NO-UNDO.
    DEFINE PRIVATE VARIABLE mExtraGiven  AS LOGICAL         NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice      AS CHARACTER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mMove        AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mFire        AS LOGICAL         NO-UNDO.

    /* the cannon, its shot and the pose each invader was last drawn in */
    DEFINE PRIVATE VARIABLE mPX          AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mShotOn      AS LOGICAL         NO-UNDO.
    DEFINE PRIVATE VARIABLE mShotX       AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mShotY       AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mShots       AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mDrawnPose   AS INTEGER         NO-UNDO EXTENT 55.
    DEFINE PRIVATE VARIABLE mDrawn       AS LOGICAL         NO-UNDO EXTENT 55.
    /* the cannon's explosion on show, a picture number from Art.i, or 0 */
    DEFINE PRIVATE VARIABLE mBlast       AS INTEGER         NO-UNDO.
    /* the muzzle flash (frames left, and its column), the shimmer on shield cells, the flash of the ground where a
       bomb landed, the colour the whole ground line has now, the gold pulse of the score and the rising score pop-up */
    DEFINE PRIVATE VARIABLE mMuzzle      AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mMuzzleX     AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mShmOn       AS LOGICAL         NO-UNDO EXTENT 128.
    DEFINE PRIVATE VARIABLE mShmX        AS INTEGER         NO-UNDO EXTENT 128.
    DEFINE PRIVATE VARIABLE mShmY        AS INTEGER         NO-UNDO EXTENT 128.
    DEFINE PRIVATE VARIABLE mShmUntil    AS INTEGER         NO-UNDO EXTENT 128.
    DEFINE PRIVATE VARIABLE mShmNext     AS INTEGER         NO-UNDO INITIAL 1.
    DEFINE PRIVATE VARIABLE mGfTimer     AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mGfFrom      AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mGfTo        AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mGroundCol   AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mPulse       AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mHudGold     AS LOGICAL         NO-UNDO.
    DEFINE PRIVATE VARIABLE mPopY        AS INTEGER         NO-UNDO.
    /* frames left of the blink after the cannon comes back: it swaps with its outline every 6 frames */
    DEFINE PRIVATE VARIABLE mGhost       AS INTEGER         NO-UNDO.
    /* what the idle title screen has on show: 0 nothing, 1 the walking octopus, 2 the saucer, and where */
    DEFINE PRIVATE VARIABLE mIdleKind    AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mIdleX       AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mIdlePic     AS INTEGER         NO-UNDO.

    /* the three bombs, by type: 0 rolling, 1 plunger, 2 squiggly */
    DEFINE PRIVATE VARIABLE mBombOn      AS LOGICAL         NO-UNDO EXTENT 3.
    DEFINE PRIVATE VARIABLE mBombX       AS INTEGER         NO-UNDO EXTENT 3.
    DEFINE PRIVATE VARIABLE mBombY       AS INTEGER         NO-UNDO EXTENT 3.
    DEFINE PRIVATE VARIABLE mBombAge     AS INTEGER         NO-UNDO EXTENT 3.
    DEFINE PRIVATE VARIABLE mReload      AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mNextBomb    AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mTable       AS INTEGER         NO-UNDO EXTENT 3.

    /* the saucer and the score that pops up where it was hit */
    DEFINE PRIVATE VARIABLE mSaucerOn    AS LOGICAL         NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucerX     AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucerDir   AS INTEGER         NO-UNDO INITIAL 1.
    DEFINE PRIVATE VARIABLE mSaucerTimer AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mPopOn       AS LOGICAL         NO-UNDO.
    DEFINE PRIVATE VARIABLE mPopText     AS CHARACTER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mPopX        AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mPopTimer    AS INTEGER         NO-UNDO.

    /* explosions: a picture that is shown for a number of frames, and then another one for a number more */
    DEFINE PRIVATE VARIABLE mFxOn        AS LOGICAL         NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mFxX         AS INTEGER         NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mFxY         AS INTEGER         NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mFxArt       AS INTEGER         NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mFxTimer     AS INTEGER         NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mFxNextArt   AS INTEGER         NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mFxNextTimer AS INTEGER         NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mFxColour    AS INTEGER         NO-UNDO EXTENT 16.
    DEFINE PRIVATE VARIABLE mFxAccent    AS INTEGER         NO-UNDO EXTENT 16.

    /* sparks: positions and speeds in sixteenths of a cell */
    DEFINE PRIVATE VARIABLE mPtOn        AS LOGICAL         NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mPtX         AS INTEGER         NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mPtY         AS INTEGER         NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mPtVx        AS INTEGER         NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mPtVy        AS INTEGER         NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mPtLife      AS INTEGER         NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mPtSpan      AS INTEGER         NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mPtColour    AS INTEGER         NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mPtDrawn     AS INTEGER         NO-UNDO EXTENT 64.
    DEFINE PRIVATE VARIABLE mPtDrawnAt   AS INTEGER         NO-UNDO EXTENT 64.

    /* the stars: where, how often they step down a cell, and the colour */
    DEFINE PRIVATE VARIABLE mStX         AS INTEGER         NO-UNDO EXTENT 48.
    DEFINE PRIVATE VARIABLE mStY         AS INTEGER         NO-UNDO EXTENT 48.
    DEFINE PRIVATE VARIABLE mStPeriod    AS INTEGER         NO-UNDO EXTENT 48.
    DEFINE PRIVATE VARIABLE mStColour    AS INTEGER         NO-UNDO EXTENT 48.
    DEFINE PRIVATE VARIABLE mStShown     AS INTEGER         NO-UNDO EXTENT 48.
    DEFINE PRIVATE VARIABLE mSky         AS INTEGER         NO-UNDO EXTENT 256.
    DEFINE PRIVATE VARIABLE mShieldTone  AS INTEGER         NO-UNDO EXTENT 16.

    /* what is drawn in the score panel now, so only what changed is written again */
    DEFINE PRIVATE VARIABLE mHudScore    AS INTEGER         NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mHudHi       AS INTEGER         NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mHudLives    AS INTEGER         NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mHudWave     AS INTEGER         NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mPromptOn    AS LOGICAL         NO-UNDO.
    /* the best score when this game began, to tell whether it has been beaten */
    DEFINE PRIVATE VARIABLE mHiAtStart   AS INTEGER         NO-UNDO.
    DEFINE PRIVATE VARIABLE mNewHi       AS LOGICAL         NO-UNDO.

    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    /* How fast the game runs, as a percentage of the arcade's 60 frames a second: 20 to 100, 100 being the
       arcade's own speed. Everything slows together (the invaders, the shot, the bombs and the cannon), so the
       game stays the same game and is only easier to play. */
    DEFINE PUBLIC PROPERTY SpeedPercent AS INTEGER NO-UNDO INITIAL 100
        GET.
        SET(INPUT piValue AS INTEGER):
            SpeedPercent = MINIMUM(100, MAXIMUM(20, piValue)).
        END SET.

    /* Which phase of the game this is: the numbers in Phases.i. */
    DEFINE PUBLIC PROPERTY Phase AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Score AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The best score. The window gives it the saved one, and it goes up with the score. */
    DEFINE PUBLIC PROPERTY HiScore AS INTEGER NO-UNDO
        GET.
        SET(INPUT piValue AS INTEGER):
            HiScore = MAXIMUM(0, piValue).
        END SET.

    /* Cannons left, the one in play included. */
    DEFINE PUBLIC PROPERTY Lives AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Wave AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Which way the cannon is being steered: -1 left, 0 stopped, 1 right. The input sets it from the keys that
       are held down. */
    DEFINE PUBLIC PROPERTY MoveDirection AS INTEGER NO-UNDO
        GET():
            RETURN mMove.
        END GET.
        SET(INPUT piValue AS INTEGER):
            mMove = (IF piValue > 0 THEN 1 ELSE IF piValue < 0 THEN -1 ELSE 0).
        END SET.

    /* True while the fire key is held down. */
    DEFINE PUBLIC PROPERTY FireHeld AS LOGICAL NO-UNDO
        GET():
            RETURN mFire.
        END GET.
        SET(INPUT plValue AS LOGICAL):
            mFire = (plValue = TRUE).
        END SET.

    DEFINE PUBLIC PROPERTY PlayerX AS INTEGER NO-UNDO
        GET():
            RETURN mPX.
        END GET.

    DEFINE PUBLIC PROPERTY ShotActive AS LOGICAL NO-UNDO
        GET():
            RETURN mShotOn.
        END GET.

    /* The column of the shot and the row of its head (its top cell). */
    DEFINE PUBLIC PROPERTY ShotX AS INTEGER NO-UNDO
        GET():
            RETURN mShotX.
        END GET.

    DEFINE PUBLIC PROPERTY ShotY AS INTEGER NO-UNDO
        GET():
            RETURN mShotY.
        END GET.

    /* Shots fired this game, which decides what the saucer is worth. */
    DEFINE PUBLIC PROPERTY ShotsFired AS INTEGER NO-UNDO
        GET():
            RETURN mShots.
        END GET.

    DEFINE PUBLIC PROPERTY SaucerActive AS LOGICAL NO-UNDO
        GET():
            RETURN mSaucerOn.
        END GET.

    DEFINE PUBLIC PROPERTY SaucerX AS INTEGER NO-UNDO
        GET():
            RETURN mSaucerX.
        END GET.

    /* Frames made since the game was built. */
    DEFINE PUBLIC PROPERTY FrameCount AS INTEGER NO-UNDO
        GET():
            RETURN mFrames.
        END GET.

    /* Frames spent in the phase now. */
    DEFINE PUBLIC PROPERTY PhaseTimer AS INTEGER NO-UNDO
        GET():
            RETURN mTimer.
        END GET.

    DEFINE PUBLIC PROPERTY Rack AS InvaderRack NO-UNDO
        GET():
            RETURN mRack.
        END GET.

    DEFINE PUBLIC PROPERTY Canvas AS InvadersCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    /* The grid must be 224 x 256 on an ArrayStore with the layers view, kind and back. */
    CONSTRUCTOR PUBLIC SpaceInvadersGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        SUPER("Space Invaders", poGrid).
        IF poGrid:Width <> {&WIDTH} OR poGrid:Height <> {&HEIGHT} THEN
            UNDO, THROW NEW GridException("A Space Invaders grid is " + STRING({&WIDTH}) + " x " + STRING({&HEIGHT})).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Space Invaders game needs a random source").
        mRandom = poRandom.
        mCanvas = NEW InvadersCanvas(poGrid).
        mRack = NEW InvaderRack().
        DO i = 1 TO 16:
            mShieldTone[i] = InvadersLook:Mix(InvadersLook:Colour({&C-SHIELD-TOP}), InvadersLook:Colour({&C-SHIELD-BOTTOM}), i - 1, 15).
        END.
        Initialise().
    END CONSTRUCTOR.

    /* Points for each of the three kinds of invader's row: see InvaderRack. The table the saucer pays by: shot
       number 0 to 14, repeating. The arcade's table: the 23rd shot (23 MODULO 15 is 8) is the 300. */
    METHOD PUBLIC STATIC INTEGER SaucerPointsFor(INPUT piShots AS INTEGER):
        RETURN INTEGER(ENTRY((MAXIMUM(0, piShots) MODULO 15) + 1, "100,50,50,100,150,100,100,50,300,100,100,100,50,150,100")).
    END METHOD.

    /* Frames between one bomb and the next: the arcade's, shorter as the score goes up. */
    METHOD PUBLIC STATIC INTEGER ReloadFor(INPUT piScore AS INTEGER):
        RETURN (IF piScore < 200 THEN 48 ELSE IF piScore < 1000 THEN 16 ELSE IF piScore < 2000 THEN 11 ELSE IF piScore < 3000 THEN 8 ELSE 7).
    END METHOD.

    /* The row the top of the rack starts at in a wave (1 to 8, then it stays): lower each time. */
    METHOD PUBLIC STATIC INTEGER RackTopFor(INPUT piWave AS INTEGER):
        RETURN INTEGER(ENTRY(MINIMUM(8, MAXIMUM(1, piWave)), "80,88,96,104,112,120,128,136")).
    END METHOD.

    /* Moves time on by piElapsedMs milliseconds and makes the frames that are due at the speed, up to 4. Returns true when a
       frame was made. Does nothing while Paused. */
    METHOD PUBLIC LOGICAL Tick(INPUT piElapsedMs AS INTEGER):
        DEFINE VARIABLE made AS INTEGER NO-UNDO.
        IF Paused OR piElapsedMs <= 0 THEN RETURN FALSE.
        mAcc = mAcc + INTEGER(ROUND(MINIMUM(piElapsedMs, {&MOST-MS}) * 0.6 * SpeedPercent, 0)).
        DO WHILE mAcc >= 1000 AND made < {&MOST-FRAMES}:
            mAcc = mAcc - 1000.
            Advance().
            made = made + 1.
        END.
        IF mAcc >= 1000 THEN mAcc = 0.
        RETURN made > 0.
    END METHOD.

    /* One sixtieth of a second of the game. */
    METHOD PUBLIC VOID Advance():
        mFrames = mFrames + 1.
        UpdateStars().
        CASE Phase:
            WHEN {&PHASE-TITLE} THEN FrameTitle().
            WHEN {&PHASE-STARTING} THEN FrameStarting().
            WHEN {&PHASE-PLAYING} THEN FramePlaying().
            WHEN {&PHASE-DYING} THEN FrameDying().
            WHEN {&PHASE-CLEARED} THEN FrameCleared().
            WHEN {&PHASE-GAMEOVER} THEN FrameGameOver().
        END CASE.
        UpdateEffects().
        RefreshHud().
    END METHOD.

    /* Starts a new game: no score, three cannons, the first wave. Works from any phase. */
    METHOD PUBLIC VOID StartGame():
        Score = 0.
        Lives = 3.
        Wave = 1.
        mExtraGiven = FALSE.
        mHiAtStart = HiScore.
        mGhost = 0.
        mShots = 0.
        mInvaded = FALSE.
        mSaucerTimer = 0.
        mSaucerDir = 1.
        mNotice = "".
        ResetPicture().
        mPX = {&PLAYER-START}.
        DrawCannon().
        BeginWave().
        DrawHudFrame().
    END METHOD.

    /* Finishes drawing a wave in at once, and starts play. For tests, and for anything that wants the game in play
       without waiting two seconds. */
    METHOD PUBLIC VOID SkipIntro():
        IF Phase <> {&PHASE-STARTING} THEN RETURN.
        DO WHILE Phase = {&PHASE-STARTING}:
            FrameStarting().
        END.
    END METHOD.

    /* Puts the cannon at a column, between its two limits, taking it off where it was. */
    METHOD PUBLIC VOID SetPlayerX(INPUT piX AS INTEGER):
        IF Phase <> {&PHASE-PLAYING} AND Phase <> {&PHASE-STARTING} THEN RETURN.
        EraseCannon().
        mPX = MINIMUM({&PLAYER-MAX}, MAXIMUM({&PLAYER-MIN}, piX)).
        DrawCannon().
    END METHOD.

    /* Drops a bomb of a type (0 rolling, 1 plunger, 2 squiggly) with its top left cell at piX, piY. Throws
       GridException for a bomb of that type that is out already. The game calls this itself when it is time for one. */
    METHOD PUBLIC VOID DropBomb(INPUT piType AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckType(piType).
        IF mBombOn[piType + 1] THEN UNDO, THROW NEW GridException("Bomb " + STRING(piType) + " is out already").
        mBombOn[piType + 1] = TRUE.
        mBombX[piType + 1] = piX.
        mBombY[piType + 1] = piY.
        mBombAge[piType + 1] = 0.
        DrawBomb(piType).
    END METHOD.

    METHOD PUBLIC LOGICAL BombActive(INPUT piType AS INTEGER):
        CheckType(piType).
        RETURN mBombOn[piType + 1].
    END METHOD.

    /* The column and row of a bomb's top left cell. */
    METHOD PUBLIC INTEGER BombX(INPUT piType AS INTEGER):
        CheckType(piType).
        RETURN mBombX[piType + 1].
    END METHOD.

    METHOD PUBLIC INTEGER BombY(INPUT piType AS INTEGER):
        CheckType(piType).
        RETURN mBombY[piType + 1].
    END METHOD.

    /* Sends the saucer across the top, from the right when piDirection is -1 and from the left when it is 1. Does
       nothing while it is out already. */
    METHOD PUBLIC VOID LaunchSaucer(INPUT piDirection AS INTEGER):
        IF mSaucerOn THEN RETURN.
        mSaucerDir = (IF piDirection < 0 THEN -1 ELSE 1).
        mSaucerX = (IF mSaucerDir > 0 THEN -16 ELSE {&WIDTH}).
        mSaucerOn = TRUE.
        DrawSaucer().
    END METHOD.

    /* What the game has to say, once: an extra life, a new wave. */
    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID Dispose():
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        SUPER:Dispose().
    END METHOD.

    /* A new game, or the title screen the first time. */
    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        mAcc = 0.
        IF mFirst THEN DO:
            mFirst = FALSE.
            ShowTitle().
        END.
        ELSE StartGame().
    END METHOD.

    /* ================================ the phases ================================ */

    METHOD PRIVATE VOID FrameTitle():
        mTimer = mTimer + 1.
        TitleStep().
        IF NOT mFire THEN mArmed = TRUE.
        ELSE IF mArmed THEN StartGame().
    END METHOD.

    /* What the title screen does at the frame it has reached (mTimer): the letters pop in one at a time from
       frame 20 (white for 2 frames, then shaded, each with a shadow), the light bar sweeps under them from frame 90,
       the heading types itself from 110, the four table rows come in from 150 every 18 frames, and PRESS SPACE
       blinks from 222. After that the table sprites change pose twice a second. */
    METHOD PRIVATE VOID TitleStep():
        DEFINE VARIABLE t    AS INTEGER NO-UNDO.
        DEFINE VARIABLE k    AS INTEGER NO-UNDO.
        DEFINE VARIABLE rw   AS INTEGER NO-UNDO.
        DEFINE VARIABLE c0   AS INTEGER NO-UNDO.
        DEFINE VARIABLE c1   AS INTEGER NO-UNDO.
        t = mTimer.
        IF t >= 20 AND t < 20 + 13 * 5 + 3 THEN DO:
            k = t - 20.
            IF k MODULO 5 = 0 THEN PopTitleLetter(INTEGER(TRUNCATE(k / 5, 0)), TRUE).
            ELSE IF k MODULO 5 = 2 THEN PopTitleLetter(INTEGER(TRUNCATE(k / 5, 0)), FALSE).
        END.
        IF t >= 90 AND t < 110 THEN DO:
            c0 = (t - 90) * 7.
            c1 = MINIMUM(140, (t - 90) * 7 + 6).
            SweepLightBar(c0, c1).
        END.
        IF t >= 110 AND t < 110 + 19 * 2 AND (t - 110) MODULO 2 = 0 THEN
            mCanvas:DrawText(SUBSTRING("SCORE ADVANCE TABLE", 1, INTEGER(TRUNCATE((t - 110) / 2, 0)) + 1), 55, 108, InvadersLook:Colour({&C-TEXT-LABEL})).
        DO rw = 0 TO 3:
            IF t = 150 + 18 * rw THEN DrawTableRow(rw, 0, TRUE).
            IF t = 153 + 18 * rw THEN DrawTableRow(rw, 0, FALSE).
        END.
        IF t >= 222 + 480 THEN IdleWalk(t - 222 - 480).
        IF t >= 222 THEN DO:
            BlinkPrompt(200, t - 222).
            IF t MODULO 30 = 0 THEN
                DO rw = 0 TO 3:
                    DrawTableRow(rw, INTEGER(TRUNCATE(t / 30, 0)) MODULO 2, FALSE).
                END.
        END.
    END METHOD.

    /* Left alone for 8 seconds after the title is built, an octopus walks across the foot of the screen a cell every 4
       frames, then the saucer crosses the top once, then 10 seconds of quiet, and round again. piFrame counts from the
       start of the first walk. */
    METHOD PRIVATE VOID IdleWalk(INPUT piFrame AS INTEGER):
        DEFINE VARIABLE u    AS INTEGER NO-UNDO.
        DEFINE VARIABLE kind AS INTEGER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE pic  AS INTEGER NO-UNDO.
        u = piFrame MODULO (944 + 240 + 600).
        IF u < 944 THEN DO:
            kind = 1.
            x = -12 + INTEGER(TRUNCATE(u / 4, 0)).
            pic = INTEGER(TRUNCATE(u / 8, 0)) MODULO 2.
        END.
        ELSE IF u < 944 + 240 THEN DO:
            kind = 2.
            x = -16 + (u - 944).
            pic = INTEGER(TRUNCATE(u / 8, 0)) MODULO 2.
        END.
        IF kind = mIdleKind AND x = mIdleX AND pic = mIdlePic THEN RETURN.
        /* take what was drawn off, and draw what is due */
        IF mIdleKind = 1 THEN mCanvas:Erase(InvadersArt:Invader(2, mIdlePic), mIdleX, 205, {&KIND-FX}).
        ELSE IF mIdleKind = 2 THEN mCanvas:Erase(InvadersArt:Picture(IF mIdlePic = 0 THEN {&ART-SAUCER} ELSE {&ART-SAUCER1}), mIdleX, {&SAUCER-Y}, {&KIND-FX}).
        mIdleKind = kind.
        mIdleX = x.
        mIdlePic = pic.
        IF kind = 1 THEN
            mCanvas:Draw(InvadersArt:Invader(2, pic), x, 205, {&KIND-FX},
                         InvadersLook:InvaderColour(4, 1, 1), InvadersLook:InvaderColour(4, 1, 2), InvadersLook:InvaderColour(4, 1, 3)).
        ELSE IF kind = 2 THEN
            mCanvas:Draw(InvadersArt:Picture(IF pic = 0 THEN {&ART-SAUCER} ELSE {&ART-SAUCER1}), x, {&SAUCER-Y}, {&KIND-FX},
                         InvadersLook:Colour({&C-SAUCER}), InvadersLook:Colour({&C-SAUCER-LIGHT}), InvadersLook:Colour({&C-SAUCER-DEEP})).
    END METHOD.

    /* One letter of SPACE INVADERS (0 to 12), with its shadow. */
    METHOD PRIVATE VOID PopTitleLetter(INPUT piIndex AS INTEGER, INPUT plWhite AS LOGICAL):
        DEFINE VARIABLE ch AS CHARACTER NO-UNDO.
        DEFINE VARIABLE x  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y  AS INTEGER   NO-UNDO.
        IF piIndex < 5 THEN DO:
            ch = SUBSTRING("SPACE", piIndex + 1, 1).
            x = 68 + piIndex * 18.
            y = 44.
        END.
        ELSE DO:
            ch = SUBSTRING("INVADERS", piIndex - 4, 1).
            x = 41 + (piIndex - 5) * 18.
            y = 70.
        END.
        mCanvas:DrawTextScaled(ch, x + 1, y + 1, InvadersLook:Colour({&C-TITLE-SHADOW}), InvadersLook:Colour({&C-TITLE-SHADOW}), 3).
        IF plWhite THEN mCanvas:DrawTextScaled(ch, x, y, InvadersLook:Colour({&C-FLASH}), InvadersLook:Colour({&C-FLASH}), 3).
        ELSE mCanvas:DrawTextScaled(ch, x, y, InvadersLook:Colour({&C-TITLE-TOP}), InvadersLook:Colour({&C-TITLE-BOTTOM}), 3).
    END METHOD.

    /* Columns piFrom to piTo (0 to 140) of the light bar under the title: pink to violet to cyan, with a shadow. */
    METHOD PRIVATE VOID SweepLightBar(INPUT piFrom AS INTEGER, INPUT piTo AS INTEGER):
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        DO c = piFrom TO piTo:
            IF c <= 70 THEN v = InvadersLook:Mix(InvadersLook:Colour({&C-TITLE-TOP}), InvadersLook:Colour({&C-TITLE-BOTTOM}), c, 70).
            ELSE v = InvadersLook:Mix(InvadersLook:Colour({&C-TITLE-BOTTOM}), InvadersLook:Colour({&C-LIGHT-BAR-END}), c - 70, 70).
            mCanvas:Plot(41 + c, 95, {&KIND-NONE}, v).
            mCanvas:Plot(41 + c, 96, {&KIND-NONE}, InvadersLook:Colour({&C-LIGHT-BAR-SHADOW})).
        END.
    END METHOD.

    /* A row of the points table (0 the saucer, 1 the squid, 2 the crab, 3 the octopus): its picture in pose piPose
       and, once the picture has had its moment all in light, the equals sign, the points and the words. */
    METHOD PRIVATE VOID DrawTableRow(INPUT piRow AS INTEGER, INPUT piPose AS INTEGER, INPUT plWhite AS LOGICAL):
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE c1     AS INTEGER NO-UNDO.
        DEFINE VARIABLE c2     AS INTEGER NO-UNDO.
        DEFINE VARIABLE c3     AS INTEGER NO-UNDO.
        DEFINE VARIABLE sprite AS Sprite  NO-UNDO.
        y = 124 + piRow * 14.
        CASE piRow:
            WHEN 0 THEN DO:
                x = 70.
                sprite = InvadersArt:Picture(IF piPose = 0 THEN {&ART-SAUCER} ELSE {&ART-SAUCER1}).
                c1 = InvadersLook:Colour({&C-SAUCER}).
                c2 = InvadersLook:Colour({&C-SAUCER-LIGHT}).
                c3 = InvadersLook:Colour({&C-SAUCER-DEEP}).
            END.
            WHEN 1 THEN DO:
                x = 74.
                sprite = InvadersArt:Invader(0, piPose).
                c1 = InvadersLook:InvaderColour(0, 1, 1).
                c2 = InvadersLook:InvaderColour(0, 1, 2).
                c3 = InvadersLook:InvaderColour(0, 1, 3).
            END.
            WHEN 2 THEN DO:
                x = 72.
                sprite = InvadersArt:Invader(1, piPose).
                c1 = InvadersLook:InvaderColour(1, 1, 1).
                c2 = InvadersLook:InvaderColour(1, 1, 2).
                c3 = InvadersLook:InvaderColour(1, 1, 3).
            END.
            OTHERWISE DO:
                x = 72.
                sprite = InvadersArt:Invader(2, piPose).
                c1 = InvadersLook:InvaderColour(4, 1, 1).
                c2 = InvadersLook:InvaderColour(4, 1, 2).
                c3 = InvadersLook:InvaderColour(4, 1, 3).
            END.
        END CASE.
        mCanvas:ClearRect(x - 1, y, sprite:Width + 2, sprite:Height).
        IF plWhite THEN mCanvas:Draw(sprite, x, y, {&KIND-FX}, InvadersLook:Colour({&C-FLASH}), InvadersLook:Colour({&C-FLASH}), InvadersLook:Colour({&C-FLASH})).
        ELSE DO:
            mCanvas:Draw(sprite, x, y, {&KIND-FX}, c1, c2, c3).
            mCanvas:DrawText("=", 94, y, InvadersLook:Colour({&C-TEXT-DIM})).
            CASE piRow:
                WHEN 0 THEN DO:
                    mCanvas:DrawText("?", 112, y, InvadersLook:Colour({&C-TEXT-GOLD})).
                    mCanvas:DrawText("MYSTERY", 124, y, InvadersLook:Colour({&C-TEXT})).
                END.
                WHEN 1 THEN mCanvas:DrawText("30", 106, y, c1).
                WHEN 2 THEN mCanvas:DrawText("20", 106, y, c1).
                OTHERWISE mCanvas:DrawText("10", 106, y, c1).
            END CASE.
            IF piRow > 0 THEN mCanvas:DrawText("POINTS", 124, y, InvadersLook:Colour({&C-TEXT})).
        END.
    END METHOD.

    /* The wave builds itself over 130 frames: the shields grow row by row from frame 0 (one starting every 4
       frames), the invaders are built one a frame from frame 10, bottom row first, each flashing light for 3 frames,
       WAVE n and a blinking GET READY stay on the screen, and the cannon blinks. Then play begins. */
    METHOD PRIVATE VOID FrameStarting():
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        t = mTimer.
        DO k = 0 TO 3:
            IF t >= 4 * k AND t < 4 * k + 16 THEN DrawShieldRow(k, 15 - (t - 4 * k)).
        END.
        IF t >= 10 AND t < 10 + InvaderRack:Total() THEN RevealAlien(t - 10, TRUE).
        IF t >= 13 AND t < 13 + InvaderRack:Total() THEN RevealAlien(t - 13, FALSE).
        IF t = 0 THEN DrawWaveBanner().
        IF t MODULO 16 = 0 THEN mCanvas:DrawOverlay("GET READY", 85, 170, InvadersLook:Colour({&C-TEXT-GOLD}), InvadersLook:Colour({&C-TEXT-GOLD}), 1, InvadersLook:Colour({&C-TEXT-OUTLINE})).
        ELSE IF t MODULO 16 = 8 THEN mCanvas:ShowBackRect(84, 169, 56, 9).
        BlinkCannon().
        mTimer = mTimer + 1.
        IF mTimer >= {&STARTING-FRAMES} THEN DO:
            mCanvas:ShowBackRect(60, 149, 110, 17).
            mCanvas:ShowBackRect(84, 169, 56, 9).
            Phase = {&PHASE-PLAYING}.
            mTimer = 0.
        END.
    END METHOD.

    /* WAVE n in big shaded letters, centred, with an edge so it reads over the rack. */
    METHOD PRIVATE VOID DrawWaveBanner():
        DEFINE VARIABLE banner AS CHARACTER NO-UNDO.
        banner = "WAVE " + STRING(Wave).
        mCanvas:DrawOverlay(banner, INTEGER(TRUNCATE(({&WIDTH} - InvadersCanvas:ScaledWidth(banner, 2)) / 2, 0)), 150,
                            InvadersLook:Colour({&C-TITLE-TOP}), InvadersLook:Colour({&C-TITLE-BOTTOM}), 2, InvadersLook:Colour({&C-TEXT-OUTLINE})).
    END METHOD.

    METHOD PRIVATE VOID FramePlaying():
        mTimer = mTimer + 1.
        BlinkCannon().
        MoveCannon().
        FireCannon().
        UpdateShot().
        UpdateBombs().
        IF Phase <> {&PHASE-PLAYING} THEN RETURN.
        StepRack().
        IF Phase <> {&PHASE-PLAYING} THEN RETURN.
        DangerPulse().
        MaybeDropBomb().
        UpdateSaucer().
        IF mRack:AliveCount = 0 THEN EndWave().
    END METHOD.

    /* The cannon is blowing up: a white flash, then two pictures that take turns, then the rubble, and then a new
       cannon or the end. */
    METHOD PRIVATE VOID FrameDying():
        DEFINE VARIABLE art AS INTEGER NO-UNDO.
        DEFINE VARIABLE t   AS INTEGER NO-UNDO.
        IF mTimer < 2 THEN DO:
            mTimer = mTimer + 1.
            RETURN.
        END.
        IF mTimer = 2 THEN EraseCannon().
        t = mTimer - 2.
        art = (IF t < 9 THEN {&ART-CANNON-BLAST-FLASH}
               ELSE IF t < 45 THEN (IF INTEGER(TRUNCATE((t - 9) / 6, 0)) MODULO 2 = 0 THEN {&ART-CANNON-BLAST0} ELSE {&ART-CANNON-BLAST1})
               ELSE {&ART-CANNON-BLAST-RUBBLE}).
        IF art <> mBlast THEN DO:
            EraseBlast().
            mBlast = art.
            mCanvas:Draw(InvadersArt:Picture(art), mPX - 1, {&PLAYER-Y}, {&KIND-FX},
                         InvadersLook:Colour({&C-CANNON}), InvadersLook:Colour({&C-FLASH}), InvadersLook:Colour({&C-EMBER})).
        END.
        mTimer = mTimer + 1.
        IF mTimer < {&DYING-FRAMES} THEN RETURN.
        EraseBlast().
        Lives = Lives - 1.
        IF mInvaded OR Lives <= 0 THEN EnterGameOver().
        ELSE DO:
            mPX = {&PLAYER-START}.
            mGhost = 90.
            DrawCannon().
            Phase = {&PHASE-PLAYING}.
            mTimer = 0.
        END.
    END METHOD.

    /* The wave is cleared: a pause while the last explosion plays out, then WAVE CLEARED pops in letter by letter, the
       ground line flashes white and a bright piece of it sweeps across, and NEXT WAVE n appears. */
    METHOD PRIVATE VOID FrameCleared():
        DEFINE VARIABLE t    AS INTEGER NO-UNDO.
        DEFINE VARIABLE pos  AS INTEGER NO-UNDO.
        DEFINE VARIABLE nextText AS CHARACTER NO-UNDO.
        mTimer = mTimer + 1.
        t = mTimer.
        IF t >= 20 AND (t - 20) MODULO 2 = 0 AND (t - 20) / 2 < 12 THEN
            IF SUBSTRING("WAVE CLEARED", INTEGER(TRUNCATE((t - 20) / 2, 0)) + 1, 1) <> " " THEN
                mCanvas:DrawOverlay(SUBSTRING("WAVE CLEARED", INTEGER(TRUNCATE((t - 20) / 2, 0)) + 1, 1), 41 + INTEGER(TRUNCATE((t - 20) / 2, 0)) * 12, 100,
                                    InvadersLook:Colour({&C-CLEAR-TOP}), InvadersLook:Colour({&C-CLEAR-BOTTOM}), 2, InvadersLook:Colour({&C-TEXT-OUTLINE})).
        IF t = 20 THEN PaintGround(InvadersLook:Colour({&C-TEXT})).
        IF t = 26 THEN PaintGround(InvadersLook:Colour({&C-GROUND-LINE})).
        IF t > 26 AND t <= 60 THEN DO:
            pos = (t - 26) * 8.
            PaintGroundPart(pos - 16, pos - 9, InvadersLook:Colour({&C-GROUND-LINE})).
            PaintGroundPart(pos - 8, pos - 1, InvadersLook:Colour({&C-TEXT})).
        END.
        IF t = 50 THEN DO:
            nextText = "NEXT WAVE " + STRING(Wave + 1).
            mCanvas:DrawOverlay(nextText, INTEGER(TRUNCATE(({&WIDTH} - PixelFont:WidthOf(nextText)) / 2, 0)), 120,
                                InvadersLook:Colour({&C-TEXT-LABEL}), InvadersLook:Colour({&C-TEXT-LABEL}), 1, InvadersLook:Colour({&C-TEXT-OUTLINE})).
        END.
        IF t < {&CLEARED-FRAMES} THEN RETURN.
        PaintGround(InvadersLook:Colour({&C-GROUND-LINE})).
        mCanvas:ShowBackRect(38, 97, 150, 21).
        mCanvas:ShowBackRect(60, 118, 110, 11).
        Wave = Wave + 1.
        mNotice = "Wave " + STRING(Wave).
        BeginWave().
    END METHOD.

    METHOD PRIVATE VOID FrameGameOver():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        mTimer = mTimer + 1.
        /* the letters pop in, one every 3 frames */
        IF mTimer MODULO 3 = 0 AND mTimer / 3 <= 9 THEN DO:
            k = INTEGER(TRUNCATE(mTimer / 3, 0)) - 1.
            IF SUBSTRING("GAME OVER", k + 1, 1) <> " " THEN DO:
                /* over the frozen rack, which the next screen wipes, so these go on whatever is there */
                mCanvas:DrawTextScaled(SUBSTRING("GAME OVER", k + 1, 1), 60 + k * 12, 101, InvadersLook:Colour({&C-OVER-SHADOW}), InvadersLook:Colour({&C-OVER-SHADOW}), 2).
                mCanvas:DrawTextScaled(SUBSTRING("GAME OVER", k + 1, 1), 59 + k * 12, 100, InvadersLook:Colour({&C-OVER-TOP}), InvadersLook:Colour({&C-OVER-BOTTOM}), 2).
            END.
        END.
        IF mTimer = 30 THEN DO:
            PaintGround(InvadersLook:Colour({&C-GROUND-LINE})).
            mCanvas:DrawOverlay("SCORE ", 79, 124, InvadersLook:Colour({&C-TEXT-LABEL}), InvadersLook:Colour({&C-TEXT-LABEL}), 1, -1).
            mCanvas:DrawOverlay(STRING(Score, "99999"), 115, 124, InvadersLook:Colour({&C-TEXT}), InvadersLook:Colour({&C-TEXT}), 1, -1).
        END.
        IF mTimer >= 30 AND mNewHi THEN DO:
            IF (mTimer - 30) MODULO 20 = 0 THEN
                mCanvas:DrawOverlay("NEW HI-SCORE", 76, 138, InvadersLook:Colour({&C-TEXT-GOLD}), InvadersLook:Colour({&C-TEXT-GOLD}), 1, -1).
            ELSE IF (mTimer - 30) MODULO 20 = 10 THEN mCanvas:ShowBackRect(76, 138, 72, 7).
        END.
        IF mTimer >= 90 THEN BlinkPrompt(164, mTimer - 90).
        IF NOT mFire THEN mArmed = TRUE.
        ELSE IF mArmed THEN ShowTitle().
    END METHOD.

    /* ================================ starting and ending ================================ */

    /* Puts the picture back to the empty sky with the ground line, its glow and the stars. */
    METHOD PRIVATE VOID ResetPicture():
        DEFINE VARIABLE sky AS INTEGER NO-UNDO EXTENT 256.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DO y = 0 TO {&HEIGHT} - 1:
            IF y < {&GROUND-Y} - 3 THEN sky[y + 1] = InvadersLook:Mix(InvadersLook:Colour({&C-SKY-TOP}), InvadersLook:Colour({&C-SKY-BOTTOM}), y, {&GROUND-Y} - 1).
            ELSE IF y = {&GROUND-Y} - 3 THEN sky[y + 1] = InvadersLook:Colour({&C-GLOW3}).
            ELSE IF y = {&GROUND-Y} - 2 THEN sky[y + 1] = InvadersLook:Colour({&C-GLOW2}).
            ELSE IF y = {&GROUND-Y} - 1 THEN sky[y + 1] = InvadersLook:Colour({&C-GLOW1}).
            ELSE IF y = {&GROUND-Y} THEN sky[y + 1] = InvadersLook:Colour({&C-GROUND-LINE}).
            ELSE IF y = {&GROUND-Y} + 1 THEN sky[y + 1] = InvadersLook:Colour({&C-GROUND-UNDER}).
            ELSE sky[y + 1] = InvadersLook:Colour({&C-GROUND}).
            mSky[y + 1] = sky[y + 1].
        END.
        mCanvas:SetBackRows(sky).
        mGroundCol = InvadersLook:Colour({&C-GROUND-LINE}).
        DO i = 1 TO {&STARS}:
            mStX[i] = mRandom:NextInt({&WIDTH}).
            mStY[i] = 24 + mRandom:NextInt({&GROUND-Y} - 28).
            mStPeriod[i] = (IF i MODULO 3 = 0 THEN 3 ELSE IF i MODULO 3 = 1 THEN 9 ELSE 5).
            mStColour[i] = InvadersLook:Colour(IF mStPeriod[i] = 3 THEN {&C-STAR-BRIGHT} ELSE IF mStPeriod[i] = 5 THEN {&C-STAR-CYAN} ELSE {&C-STAR-DIM}).
            mCanvas:SetBack(mStX[i], mStY[i], mStColour[i]).
            mStShown[i] = mStColour[i].
        END.
        mCanvas:Restore().
        ClearEffects().
        mHudScore = -1.
        mHudHi = -1.
        mHudLives = -1.
        mHudWave = -1.
    END METHOD.

    /* The title screen: the sky and the credit now, and the name, the points table and the prompt coming in one
       piece at a time over the first four seconds (TitleStep). */
    METHOD PRIVATE VOID ShowTitle():
        Phase = {&PHASE-TITLE}.
        mTimer = 0.
        mArmed = FALSE.
        mPX = {&PLAYER-START}.
        ResetPicture().
        DrawHudFrame().
        mCanvas:DrawText("PROGRIDDLE COOKOFF", 58, 241, InvadersLook:Colour({&C-TEXT-CREDIT})).
        mPromptOn = FALSE.
        mIdleKind = 0.
    END METHOD.

    /* Builds the shields, deals out the invaders and starts drawing them in. */
    METHOD PRIVATE VOID BeginWave():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        EraseShot().
        DO i = 0 TO 2:
            EraseBomb(i).
        END.
        IF mSaucerOn THEN EraseSaucer().
        EraseBlast().
        /* the band the shields stand in, whatever is left of the old ones */
        mCanvas:ClearRect(0, {&SHIELD-Y}, {&WIDTH}, 16).
        mGhost = {&STARTING-FRAMES}.
        mRack:Reset(RackTopFor(Wave)).
        DO i = 1 TO InvaderRack:Total():
            mDrawn[i] = FALSE.
            mDrawnPose[i] = 0.
        END.
        mReload = 60.
        mNextBomb = 0.
        mTable[1] = 0.
        mTable[2] = 0.
        mTable[3] = 0.
        mInvaded = FALSE.
        Phase = {&PHASE-STARTING}.
        mTimer = 0.
        mHudWave = -1.
        IF NOT mCanvas:KindAt(mPX, {&PLAYER-Y}) = {&KIND-PLAYER} THEN DrawCannon().
    END METHOD.

    /* The last invader is dead: nothing in the air can hurt the cannon any more, and a pause begins. */
    METHOD PRIVATE VOID EndWave():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        EraseShot().
        DO i = 0 TO 2:
            EraseBomb(i).
        END.
        IF mSaucerOn THEN EraseSaucer().
        Phase = {&PHASE-CLEARED}.
        mTimer = 0.
    END METHOD.

    METHOD PRIVATE VOID EnterGameOver():
        Phase = {&PHASE-GAMEOVER}.
        mTimer = 0.
        mArmed = FALSE.
        mPromptOn = FALSE.
        mNewHi = (Score > mHiAtStart AND Score > 0).
        Lives = 0.
        PaintGround(InvadersLook:Colour({&C-OVER-TOP})).
    END METHOD.

    /* The 13 cells of the ground line round a column take a colour for 6 frames, where a bomb landed. */
    METHOD PRIVATE VOID FlashGround(INPUT piX AS INTEGER, INPUT piColour AS INTEGER):
        IF mGfTimer > 0 THEN PaintGroundPart(mGfFrom, mGfTo, mGroundCol).
        mGfFrom = piX - 6.
        mGfTo = piX + 6.
        mGfTimer = 6.
        PaintGroundPart(mGfFrom, mGfTo, piColour).
    END METHOD.

    METHOD PRIVATE VOID UpdateGroundFlash():
        IF mGfTimer <= 0 THEN RETURN.
        mGfTimer = mGfTimer - 1.
        IF mGfTimer = 0 THEN PaintGroundPart(mGfFrom, mGfTo, mGroundCol).
    END METHOD.

    /* While the rack is down within 8 cells of the shields the ground line pulses red twice a second. */
    METHOD PRIVATE VOID DangerPulse():
        DEFINE VARIABLE c AS INTEGER NO-UNDO.
        c = (IF mRack:Bottom() >= 176 AND INTEGER(TRUNCATE(mFrames / 15, 0)) MODULO 2 = 1 THEN InvadersLook:Colour({&C-OVER-TOP}) ELSE InvadersLook:Colour({&C-GROUND-LINE})).
        IF c <> mGroundCol THEN PaintGround(c).
    END METHOD.

    /* Columns piFrom to piTo of the ground line in one colour (the part off the board is ignored). */
    METHOD PRIVATE VOID PaintGroundPart(INPUT piFrom AS INTEGER, INPUT piTo AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DO x = MAXIMUM(0, piFrom) TO MINIMUM({&WIDTH} - 1, piTo):
            mCanvas:SetBack(x, {&GROUND-Y}, piColour).
            mCanvas:ShowBack(x, {&GROUND-Y}).
        END.
    END METHOD.

    /* The whole ground line in one colour (it shows once nothing is on the row), for a flash. */
    METHOD PRIVATE VOID PaintGround(INPUT piColour AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        mGroundCol = piColour.
        DO x = 0 TO {&WIDTH} - 1:
            mCanvas:SetBack(x, {&GROUND-Y}, piColour).
            mCanvas:ShowBack(x, {&GROUND-Y}).
        END.
    END METHOD.

    /* The cannon has been hit: whatever is in the air goes, and the explosion starts. */
    METHOD PRIVATE VOID KillCannon():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        EraseShot().
        DO i = 0 TO 2:
            EraseBomb(i).
        END.
        /* the cannon goes white for 2 frames before it blows up */
        mCanvas:Draw(InvadersArt:Picture({&ART-CANNON}), mPX, {&PLAYER-Y}, {&KIND-PLAYER},
                     InvadersLook:Colour({&C-FLASH}), InvadersLook:Colour({&C-FLASH}), InvadersLook:Colour({&C-FLASH})).
        mGhost = 0.
        Phase = {&PHASE-DYING}.
        mTimer = 0.
        SpawnSparks(mPX + 6, {&PLAYER-Y} + 4, InvadersLook:Colour({&C-CANNON}), 14).
    END METHOD.

    /* ================================ the cannon and its shot ================================ */

    METHOD PRIVATE VOID MoveCannon():
        DEFINE VARIABLE target AS INTEGER NO-UNDO.
        IF mMove = 0 THEN RETURN.
        target = MINIMUM({&PLAYER-MAX}, MAXIMUM({&PLAYER-MIN}, mPX + mMove)).
        IF target = mPX THEN RETURN.
        EraseCannon().
        mPX = target.
        DrawCannon().
    END METHOD.

    /* One shot at a time: a new one only when the last has gone. */
    METHOD PRIVATE VOID FireCannon():
        IF NOT mFire OR mShotOn THEN RETURN.
        mShotOn = TRUE.
        mShotX = mPX + 6.
        mShotY = {&PLAYER-Y} - 4.
        mShots = mShots + 1.
        mMuzzle = 3.
        mMuzzleX = mShotX.
        DrawMuzzle().
        DrawShot().
    END METHOD.

    /* A small white plus at the tip of the barrel for 3 frames after a shot, on empty cells only. */
    METHOD PRIVATE VOID DrawMuzzle():
        MuzzleCell(mMuzzleX, {&PLAYER-Y} - 3).
        MuzzleCell(mMuzzleX, {&PLAYER-Y} - 2).
        MuzzleCell(mMuzzleX, {&PLAYER-Y} - 1).
        MuzzleCell(mMuzzleX - 1, {&PLAYER-Y} - 2).
        MuzzleCell(mMuzzleX + 1, {&PLAYER-Y} - 2).
    END METHOD.

    METHOD PRIVATE VOID MuzzleCell(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF mCanvas:KindAt(piX, piY) = {&KIND-NONE} THEN mCanvas:Plot(piX, piY, {&KIND-FX}, InvadersLook:Colour({&C-FLASH})).
    END METHOD.

    METHOD PRIVATE VOID UnmuzzleCell(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF mCanvas:KindAt(piX, piY) = {&KIND-FX} AND mCanvas:ColourAt(piX, piY) = InvadersLook:Colour({&C-FLASH}) THEN mCanvas:Unplot(piX, piY).
    END METHOD.

    METHOD PRIVATE VOID UpdateMuzzle():
        IF mMuzzle <= 0 THEN RETURN.
        mMuzzle = mMuzzle - 1.
        IF mMuzzle > 0 THEN RETURN.
        UnmuzzleCell(mMuzzleX, {&PLAYER-Y} - 3).
        UnmuzzleCell(mMuzzleX, {&PLAYER-Y} - 2).
        UnmuzzleCell(mMuzzleX, {&PLAYER-Y} - 1).
        UnmuzzleCell(mMuzzleX - 1, {&PLAYER-Y} - 2).
        UnmuzzleCell(mMuzzleX + 1, {&PLAYER-Y} - 2).
    END METHOD.

    /* The shot goes up 4 cells, one at a time, and stops at the first thing it meets. */
    METHOD PRIVATE VOID UpdateShot():
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE kind AS INTEGER NO-UNDO.
        IF NOT mShotOn THEN RETURN.
        EraseShot().
        mShotOn = TRUE.
        DO n = 1 TO 4:
            mShotY = mShotY - 1.
            IF mShotY <= {&SHOT-TOP} THEN DO:
                mShotOn = FALSE.
                mCanvas:DrawOnEmpty(InvadersArt:Picture({&ART-SHOT-BURST}), mShotX - 4, mShotY - 4, {&KIND-FX},
                                    InvadersLook:Colour({&C-SHOT}), InvadersLook:Colour({&C-FLASH}), InvadersLook:Colour({&C-SHOT})).
                AddFx(mShotX - 4, mShotY - 4, {&ART-SHOT-BURST}, 6, {&ART-SHOT-BURST1}, 6, InvadersLook:Colour({&C-SHOT}), InvadersLook:Colour({&C-FLASH}), TRUE).
                RETURN.
            END.
            kind = mCanvas:KindAt(mShotX, mShotY).
            IF kind = {&KIND-ALIEN} THEN DO:
                mShotOn = FALSE.
                HitAlien(mShotX, mShotY).
                RETURN.
            END.
            IF kind = {&KIND-SHIELD} THEN DO:
                mShotOn = FALSE.
                Erode(mShotX - 3, mShotY - 3, 0).
                RETURN.
            END.
            IF kind = {&KIND-BOMB} THEN DO:
                mShotOn = FALSE.
                HitBomb(mShotX, mShotY).
                RETURN.
            END.
            IF kind = {&KIND-SAUCER} THEN DO:
                mShotOn = FALSE.
                HitSaucer().
                RETURN.
            END.
        END.
        DrawShot().
    END METHOD.

    METHOD PRIVATE VOID HitAlien(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE kind  AS INTEGER NO-UNDO.
        DEFINE VARIABLE ax    AS INTEGER NO-UNDO.
        DEFINE VARIABLE ay    AS INTEGER NO-UNDO.
        DEFINE VARIABLE body  AS INTEGER NO-UNDO.
        i = mRack:At(piX, piY).
        IF i < 0 THEN RETURN.
        kind = InvaderRack:KindOf(i).
        ax = mRack:X(i).
        ay = mRack:Y(i).
        EraseAlien(i).
        mRack:Kill(i).
        body = InvadersLook:InvaderColour(InvaderRack:RowOf(i), Wave, 1).
        AddFx(ax - INTEGER(TRUNCATE((13 - mRack:WidthOf(i)) / 2, 0)), ay, {&ART-ALIEN-BLAST0}, 5, {&ART-ALIEN-BLAST1}, 5,
              body, InvadersLook:Colour({&C-FLASH}), FALSE).
        SpawnSparks(ax + INTEGER(TRUNCATE(mRack:WidthOf(i) / 2, 0)), ay + 4, body, 10).
        AddScore(InvaderRack:PointsOfKind(kind)).
    END METHOD.

    METHOD PRIVATE VOID HitBomb(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        DO b = 0 TO 2:
            IF mBombOn[b + 1] AND piX >= mBombX[b + 1] AND piX < mBombX[b + 1] + 3 AND piY >= mBombY[b + 1] AND piY < mBombY[b + 1] + 7 THEN DO:
                SpawnSparks(piX, piY, InvadersLook:Colour({&C-BOMB}), 6).
                EraseBomb(b).
                RETURN.
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID HitSaucer():
        DEFINE VARIABLE points AS INTEGER NO-UNDO.
        DEFINE VARIABLE sx     AS INTEGER NO-UNDO.
        points = SaucerPointsFor(mShots).
        sx = mSaucerX.
        EraseSaucer().
        AddFx(sx + 1, {&SAUCER-Y} - 1, {&ART-ALIEN-BLAST0}, 6, {&ART-ALIEN-BLAST1}, 6,
              InvadersLook:Colour({&C-SAUCER}), InvadersLook:Colour({&C-SAUCER-LIGHT}), FALSE).
        SpawnSparks(sx + 8, {&SAUCER-Y} + 3, InvadersLook:Colour({&C-SAUCER}), 14).
        mPopText = STRING(points).
        mPopX = MINIMUM(sx, {&WIDTH} - 8 - PixelFont:WidthOf(mPopText)).
        mPopX = MAXIMUM(8, mPopX).
        mPopTimer = {&POP-FRAMES}.
        mPopOn = TRUE.
        mPopY = {&SAUCER-Y}.
        mPulse = 24.
        mCanvas:DrawOverlay(mPopText, mPopX, mPopY, InvadersLook:Colour({&C-TEXT-GOLD}), InvadersLook:Colour({&C-TEXT-GOLD}), 1, -1).
        AddScore(points).
    END METHOD.

    /* ================================ the invaders ================================ */

    /* Moves the next invader along, and decides whether the invasion has landed. */
    METHOD PRIVATE VOID StepRack():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        i = mRack:Step().
        IF i < 0 THEN RETURN.
        EraseAlienAt(i, mRack:OldX, mRack:OldY).
        EatShields(i).
        DrawAlien(i, FALSE).
        IF mRack:Bottom() >= {&PLAYER-Y} THEN DO:
            mInvaded = TRUE.
            KillCannon().
        END.
    END METHOD.

    /* Draws one invader in as the wave builds, in the order the rack moves them, all in light for the first moments. */
    METHOD PRIVATE VOID RevealAlien(INPUT piPlace AS INTEGER, INPUT plLight AS LOGICAL):
        DrawAlien((InvaderRack:Rows() - 1 - INTEGER(TRUNCATE(piPlace / InvaderRack:Columns(), 0))) * InvaderRack:Columns()
                  + piPlace MODULO InvaderRack:Columns(), plLight).
    END METHOD.

    /* An invader that walks into a shield eats the part it overlaps. */
    METHOD PRIVATE VOID EatShields(INPUT piIndex AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        IF mRack:Y(piIndex) + InvaderRack:SpriteHeight() <= {&SHIELD-Y} OR mRack:Y(piIndex) >= {&SHIELD-Y} + 16 THEN RETURN.
        DO y = mRack:Y(piIndex) TO mRack:Y(piIndex) + InvaderRack:SpriteHeight() - 1:
            DO x = mRack:X(piIndex) TO mRack:X(piIndex) + mRack:WidthOf(piIndex) - 1:
                IF mCanvas:KindAt(x, y) = {&KIND-SHIELD} THEN mCanvas:Unplot(x, y).
            END.
        END.
    END METHOD.

    /* ================================ the bombs ================================ */

    /* Every bomb falls: 2 cells every fourth frame and 1 on the others, 1.25 cells a frame. */
    METHOD PRIVATE VOID UpdateBombs():
        DEFINE VARIABLE b      AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE falls  AS INTEGER NO-UNDO.
        DEFINE VARIABLE kind   AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE sprite AS Sprite  NO-UNDO.
        DEFINE VARIABLE hit    AS INTEGER NO-UNDO.
        DO b = 0 TO 2:
            IF NOT mBombOn[b + 1] THEN NEXT.
            sprite = InvadersArt:Bomb(b, INTEGER(TRUNCATE(mBombAge[b + 1] / 2, 0))).
            mCanvas:Erase(sprite, mBombX[b + 1], mBombY[b + 1], {&KIND-BOMB}).
            falls = (IF mFrames MODULO 4 = 0 THEN 2 ELSE 1).
            mBombY[b + 1] = mBombY[b + 1] + falls.
            mBombAge[b + 1] = mBombAge[b + 1] + 1.
            /* the ground: the bomb is spent and leaves a splash */
            IF mBombY[b + 1] + 7 >= {&GROUND-Y} THEN DO:
                AddFx(mBombX[b + 1] - 3, {&GROUND-Y} - 4, {&ART-BOMB-SPLAT}, 4, {&ART-BOMB-SPLAT1}, 6,
                      InvadersLook:Colour({&C-BOMB}), InvadersLook:Colour({&C-BOMB-TIP}), FALSE).
                FlashGround(mBombX[b + 1] + 1, InvadersLook:Colour(IF b = 0 THEN {&C-BOMB-ROLL} ELSE IF b = 1 THEN {&C-BOMB-PLUNGER} ELSE {&C-BOMB})).
                mBombOn[b + 1] = FALSE.
                NEXT.
            END.
            /* what is in the cells the bomb now covers */
            hit = 0.
            sprite = InvadersArt:Bomb(b, INTEGER(TRUNCATE(mBombAge[b + 1] / 2, 0))).
            DO i = 0 TO sprite:Count - 1:
                cx = mBombX[b + 1] + sprite:CellX(i).
                cy = mBombY[b + 1] + sprite:CellY(i).
                kind = mCanvas:KindAt(cx, cy).
                IF kind = {&KIND-PLAYER} OR kind = {&KIND-SHIELD} OR kind = {&KIND-SHOT} THEN DO:
                    hit = kind.
                    LEAVE.
                END.
            END.
            IF hit = {&KIND-PLAYER} THEN DO:
                mBombOn[b + 1] = FALSE.
                KillCannon().
                RETURN.
            END.
            IF hit = {&KIND-SHIELD} THEN DO:
                mBombOn[b + 1] = FALSE.
                Erode(cx - 3, cy - 1, 1).
                NEXT.
            END.
            IF hit = {&KIND-SHOT} THEN DO:
                mBombOn[b + 1] = FALSE.
                SpawnSparks(cx, cy, InvadersLook:Colour({&C-BOMB}), 6).
                EraseShot().
                mShotOn = FALSE.
                NEXT.
            END.
            DrawBomb(b).
        END.
    END METHOD.

    /* When the reload time is up and a type of bomb is free, one is dropped from under an invader. */
    METHOD PRIVATE VOID MaybeDropBomb():
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE b      AS INTEGER NO-UNDO.
        DEFINE VARIABLE chosen AS INTEGER NO-UNDO INITIAL -1.
        DEFINE VARIABLE shooter AS INTEGER NO-UNDO.
        IF mReload > 0 THEN mReload = mReload - 1.
        IF mReload > 0 THEN RETURN.
        /* the arcade's reload: wait until every bomb in the air has come a fair way down */
        DO b = 0 TO 2:
            IF mBombOn[b + 1] AND mBombAge[b + 1] < ReloadFor(Score) * 3 THEN RETURN.
        END.
        DO n = 0 TO 2:
            b = (mNextBomb + n) MODULO 3.
            IF mBombOn[b + 1] THEN NEXT.
            IF b = 2 AND mSaucerOn THEN NEXT.
            chosen = b.
            LEAVE.
        END.
        IF chosen < 0 THEN RETURN.
        shooter = ShooterFor(chosen).
        IF shooter < 0 THEN RETURN.
        DropBomb(chosen, mRack:X(shooter) + INTEGER(TRUNCATE(mRack:WidthOf(shooter) / 2, 0)) - 1, mRack:Y(shooter) + InvaderRack:SpriteHeight()).
        mReload = ReloadFor(Score) * 3.
        mNextBomb = (chosen + 1) MODULO 3.
    END METHOD.

    /* The invader that drops a bomb of a type: the rolling bomb comes from above the cannon, the others from the
       columns of the arcade's pattern. Where a column is empty the next one is tried. -1 when no invader is left. */
    METHOD PRIVATE INTEGER ShooterFor(INPUT piType AS INTEGER):
        DEFINE VARIABLE cols   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE d      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE target AS INTEGER   NO-UNDO.
        DEFINE VARIABLE found  AS INTEGER   NO-UNDO.
        IF piType = 0 THEN DO:
            target = MINIMUM(InvaderRack:Columns() - 1, MAXIMUM(0, INTEGER(TRUNCATE((mPX + 6 - InvaderRack:FirstSlotX()) / InvaderRack:Pitch(), 0)))).
            DO d = 0 TO InvaderRack:Columns() - 1:
                IF target - d >= 0 THEN DO:
                    found = mRack:LowestInColumn(target - d).
                    IF found >= 0 THEN RETURN found.
                END.
                IF d > 0 AND target + d < InvaderRack:Columns() THEN DO:
                    found = mRack:LowestInColumn(target + d).
                    IF found >= 0 THEN RETURN found.
                END.
            END.
            RETURN -1.
        END.
        cols = (IF piType = 1 THEN "1,7,1,1,1,4,11,1,6,3,1,1,11,9,2,8,2,11,4,7,10" ELSE "11,1,6,3,1,1,11,9,2,8,2,11,4,7,10,1,7,1,1,1,4").
        DO n = 1 TO NUM-ENTRIES(cols):
            found = mRack:LowestInColumn(INTEGER(ENTRY((mTable[piType + 1] MODULO NUM-ENTRIES(cols)) + 1, cols)) - 1).
            mTable[piType + 1] = mTable[piType + 1] + 1.
            IF found >= 0 THEN RETURN found.
        END.
        RETURN -1.
    END METHOD.

    /* ================================ the saucer ================================ */

    METHOD PRIVATE VOID UpdateSaucer():
        IF mSaucerOn THEN DO:
            EraseSaucer().
            mSaucerOn = TRUE.
            mSaucerX = mSaucerX + mSaucerDir.
            IF mSaucerX < -16 OR mSaucerX > {&WIDTH} THEN DO:
                mSaucerOn = FALSE.
                mSaucerTimer = 0.
                RETURN.
            END.
            DrawSaucer().
            RETURN.
        END.
        mSaucerTimer = mSaucerTimer + 1.
        IF mSaucerTimer >= {&SAUCER-FRAMES} AND mRack:AliveCount >= 8 THEN DO:
            LaunchSaucer(- mSaucerDir).
            mSaucerTimer = 0.
        END.
    END METHOD.

    /* ================================ scoring ================================ */

    /* Gives points: what the rules award for a kill, and a way for a test or a bonus to move the score along. The
       hi-score follows the score, and the extra cannon comes at 1500, once. Throws GridException for a negative number. */
    METHOD PUBLIC VOID AddScore(INPUT piPoints AS INTEGER):
        IF piPoints = ? OR piPoints < 0 THEN UNDO, THROW NEW GridException("Points cannot be negative: " + STRING(piPoints)).
        Score = Score + piPoints.
        IF Score > HiScore THEN HiScore = Score.
        IF NOT mExtraGiven AND Score >= {&EXTRA-LIFE-AT} THEN DO:
            mExtraGiven = TRUE.
            Lives = Lives + 1.
            mNotice = "Extra cannon".
        END.
    END METHOD.

    /* ================================ drawing and erasing ================================ */

    /* The cannon, or while it blinks after coming back, every other six frames its outline. */
    METHOD PRIVATE VOID DrawCannon():
        IF mGhost > 0 AND INTEGER(TRUNCATE(mGhost / 6, 0)) MODULO 2 = 1 THEN
            mCanvas:Draw(InvadersArt:Picture({&ART-CANNON-GHOST}), mPX, {&PLAYER-Y}, {&KIND-PLAYER},
                         InvadersLook:Colour({&C-CANNON-GHOST}), InvadersLook:Colour({&C-CANNON-GHOST}), InvadersLook:Colour({&C-CANNON-GHOST})).
        ELSE
            mCanvas:Draw(InvadersArt:Picture({&ART-CANNON}), mPX, {&PLAYER-Y}, {&KIND-PLAYER},
                         InvadersLook:Colour({&C-CANNON}), InvadersLook:Colour({&C-CANNON-LIGHT}), InvadersLook:Colour({&C-CANNON-DEEP})).
    END METHOD.

    /* Counts down the blink and swaps the picture when its turn comes. */
    METHOD PRIVATE VOID BlinkCannon():
        IF mGhost <= 0 THEN RETURN.
        mGhost = mGhost - 1.
        IF mGhost MODULO 6 = 5 OR mGhost = 0 THEN DO:
            EraseCannon().
            DrawCannon().
        END.
    END METHOD.

    METHOD PRIVATE VOID EraseCannon():
        mCanvas:Erase(InvadersArt:Picture({&ART-CANNON}), mPX, {&PLAYER-Y}, {&KIND-PLAYER}).
    END METHOD.

    METHOD PRIVATE VOID EraseBlast():
        IF mBlast = 0 THEN RETURN.
        mCanvas:Erase(InvadersArt:Picture(mBlast), mPX - 1, {&PLAYER-Y}, {&KIND-FX}).
        mBlast = 0.
    END METHOD.

    /* The shot: a bright head, a body and a two cell tail that only goes where the sky is empty. */
    METHOD PRIVATE VOID DrawShot():
        mCanvas:DrawOnEmpty(InvadersArt:Picture({&ART-SHOT-LONG}), mShotX, mShotY, {&KIND-SHOT},
                            InvadersLook:Colour({&C-SHOT}), InvadersLook:Colour({&C-SHOT-TIP}), InvadersLook:Colour({&C-SHOT-TAIL})).
    END METHOD.

    /* Takes the shot off the screen and ends it. */
    METHOD PRIVATE VOID EraseShot():
        IF NOT mShotOn THEN RETURN.
        mCanvas:Erase(InvadersArt:Picture({&ART-SHOT-LONG}), mShotX, mShotY, {&KIND-SHOT}).
        mShotOn = FALSE.
    END METHOD.

    METHOD PRIVATE VOID DrawBomb(INPUT piType AS INTEGER):
        /* each type has its own hue: rolling lemon, plunger red-orange, squiggly amber */
        mCanvas:Draw(InvadersArt:Bomb(piType, INTEGER(TRUNCATE(mBombAge[piType + 1] / 2, 0))), mBombX[piType + 1], mBombY[piType + 1], {&KIND-BOMB},
                     InvadersLook:Colour(IF piType = 0 THEN {&C-BOMB-ROLL} ELSE IF piType = 1 THEN {&C-BOMB-PLUNGER} ELSE {&C-BOMB}),
                     InvadersLook:Colour(IF piType = 0 THEN {&C-BOMB-ROLL-TIP} ELSE IF piType = 1 THEN {&C-BOMB-PLUNGER-TIP} ELSE {&C-BOMB-TIP}),
                     InvadersLook:Colour(IF piType = 0 THEN {&C-BOMB-ROLL-DEEP} ELSE IF piType = 1 THEN {&C-BOMB-PLUNGER-DEEP} ELSE {&C-BOMB-SQUIG-DEEP})).
    END METHOD.

    /* Takes a bomb off the screen and ends it. */
    METHOD PRIVATE VOID EraseBomb(INPUT piType AS INTEGER):
        IF NOT mBombOn[piType + 1] THEN RETURN.
        mCanvas:Erase(InvadersArt:Bomb(piType, INTEGER(TRUNCATE(mBombAge[piType + 1] / 2, 0))), mBombX[piType + 1], mBombY[piType + 1], {&KIND-BOMB}).
        mBombOn[piType + 1] = FALSE.
    END METHOD.

    /* The saucer: its lights chase every 8 frames, and its body pulses through four reds. */
    METHOD PRIVATE VOID DrawSaucer():
        DEFINE VARIABLE step AS INTEGER NO-UNDO.
        step = INTEGER(TRUNCATE(mFrames / 8, 0)).
        mCanvas:Draw(InvadersArt:Picture(IF step MODULO 2 = 0 THEN {&ART-SAUCER} ELSE {&ART-SAUCER1}), mSaucerX, {&SAUCER-Y}, {&KIND-SAUCER},
                     InvadersLook:Colour(IF step MODULO 4 = 1 THEN {&C-SAUCER-PULSE1} ELSE IF step MODULO 4 = 3 THEN {&C-SAUCER-PULSE2} ELSE {&C-SAUCER}),
                     InvadersLook:Colour({&C-SAUCER-LIGHT}), InvadersLook:Colour({&C-SAUCER-DEEP})).
    END METHOD.

    METHOD PRIVATE VOID EraseSaucer():
        mCanvas:Erase(InvadersArt:Picture({&ART-SAUCER}), mSaucerX, {&SAUCER-Y}, {&KIND-SAUCER}).
        mSaucerOn = FALSE.
    END METHOD.

    /* Draws an invader where the rack has it, in the pose the rack is in, in its row's colours of this wave. In light
       (plLight) it is all its pale tone: while it is being built, and the last one left flickers so. */
    METHOD PRIVATE VOID DrawAlien(INPUT piIndex AS INTEGER, INPUT plLight AS LOGICAL):
        DEFINE VARIABLE kind AS INTEGER NO-UNDO.
        DEFINE VARIABLE row  AS INTEGER NO-UNDO.
        DEFINE VARIABLE lit  AS LOGICAL NO-UNDO.
        kind = InvaderRack:KindOf(piIndex).
        row = InvaderRack:RowOf(piIndex).
        lit = plLight OR (mRack:AliveCount = 1 AND INTEGER(TRUNCATE(mFrames / 6, 0)) MODULO 2 = 1).
        IF lit THEN
            mCanvas:Draw(InvadersArt:Invader(kind, mRack:Pose), mRack:X(piIndex), mRack:Y(piIndex), {&KIND-ALIEN},
                         InvadersLook:InvaderColour(row, Wave, 2), InvadersLook:InvaderColour(row, Wave, 2), InvadersLook:InvaderColour(row, Wave, 2)).
        ELSE
            mCanvas:Draw(InvadersArt:Invader(kind, mRack:Pose), mRack:X(piIndex), mRack:Y(piIndex), {&KIND-ALIEN},
                         InvadersLook:InvaderColour(row, Wave, 1), InvadersLook:InvaderColour(row, Wave, 2), InvadersLook:InvaderColour(row, Wave, 3)).
        mDrawn[piIndex + 1] = TRUE.
        mDrawnPose[piIndex + 1] = mRack:Pose.
    END METHOD.

    /* Takes an invader off at the place and in the pose it was last drawn in. */
    METHOD PRIVATE VOID EraseAlienAt(INPUT piIndex AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT mDrawn[piIndex + 1] THEN RETURN.
        mCanvas:Erase(InvadersArt:Invader(InvaderRack:KindOf(piIndex), mDrawnPose[piIndex + 1]), piX, piY, {&KIND-ALIEN}).
    END METHOD.

    METHOD PRIVATE VOID EraseAlien(INPUT piIndex AS INTEGER):
        EraseAlienAt(piIndex, mRack:X(piIndex), mRack:Y(piIndex)).
        mDrawn[piIndex + 1] = FALSE.
    END METHOD.

    /* One row (0 at the top, 15 at the foot) of a shield, each row a little darker than the one above. */
    METHOD PRIVATE VOID DrawShieldRow(INPUT piShield AS INTEGER, INPUT piRow AS INTEGER):
        DEFINE VARIABLE sprite AS Sprite  NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        sprite = InvadersArt:Picture({&ART-SHIELD}).
        DO i = 0 TO sprite:Count - 1:
            IF sprite:CellY(i) = piRow THEN
                mCanvas:Plot({&SHIELD-X} + piShield * {&SHIELD-PITCH} + sprite:CellX(i), {&SHIELD-Y} + piRow, {&KIND-SHIELD}, mShieldTone[piRow + 1]).
        END.
    END METHOD.

    /* Eats a mark out of the shields, with its top left cell at piX, piY: kind 0 is the mark a shot leaves, 1 the
       mark of a bomb. Only shield cells are taken, a spark flies from each of a few of them, and the shield
       around the bite shimmers for a moment. */
    METHOD PRIVATE VOID Erode(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piKind AS INTEGER):
        DEFINE VARIABLE chip  AS Sprite  NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE eaten AS INTEGER NO-UNDO.
        DEFINE VARIABLE sumX  AS INTEGER NO-UNDO.
        DEFINE VARIABLE sumY  AS INTEGER NO-UNDO.
        chip = InvadersArt:Chip(piKind, mRandom:NextInt(3)).
        DO i = 0 TO chip:Count - 1:
            x = piX + chip:CellX(i).
            y = piY + chip:CellY(i).
            IF mCanvas:KindAt(x, y) = {&KIND-SHIELD} THEN DO:
                IF i MODULO 5 = 0 THEN SpawnSpark(x, y, mCanvas:ColourAt(x, y)).
                mCanvas:Unplot(x, y).
                eaten = eaten + 1.
                sumX = sumX + x.
                sumY = sumY + y.
            END.
        END.
        IF eaten > 0 THEN Shimmer(INTEGER(TRUNCATE(sumX / eaten, 0)), INTEGER(TRUNCATE(sumY / eaten, 0))).
    END METHOD.

    /* The shield cells within 2 cells of a point take the flash colour for 3 frames. */
    METHOD PRIVATE VOID Shimmer(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        DO dy = -2 TO 2:
            DO dx = -2 TO 2:
                IF mCanvas:KindAt(piX + dx, piY + dy) = {&KIND-SHIELD} THEN DO:
                    IF mShmOn[mShmNext] THEN RestoreShieldCell(mShmX[mShmNext], mShmY[mShmNext]).
                    mShmOn[mShmNext] = TRUE.
                    mShmX[mShmNext] = piX + dx.
                    mShmY[mShmNext] = piY + dy.
                    mShmUntil[mShmNext] = mFrames + 3.
                    mCanvas:Plot(piX + dx, piY + dy, {&KIND-SHIELD}, InvadersLook:Colour({&C-SHIELD-FLASH})).
                    mShmNext = (mShmNext MODULO 128) + 1.
                END.
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID RestoreShieldCell(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF mCanvas:KindAt(piX, piY) = {&KIND-SHIELD} THEN mCanvas:Plot(piX, piY, {&KIND-SHIELD}, mShieldTone[piY - {&SHIELD-Y} + 1]).
    END METHOD.

    METHOD PRIVATE VOID UpdateShimmer():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 128:
            IF mShmOn[i] AND mFrames >= mShmUntil[i] THEN DO:
                RestoreShieldCell(mShmX[i], mShmY[i]).
                mShmOn[i] = FALSE.
            END.
        END.
    END METHOD.

    /* ================================ effects ================================ */

    /* Starts an explosion: a picture for piFrames frames, then (if piNextArt is not 0) another for piNextFrames
       more. It is drawn only on empty cells, so it never paints over anything. */
    METHOD PRIVATE VOID AddFx(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piArt AS INTEGER, INPUT piFrames AS INTEGER,
                              INPUT piNextArt AS INTEGER, INPUT piNextFrames AS INTEGER,
                              INPUT piColour AS INTEGER, INPUT piAccent AS INTEGER, INPUT plAlreadyDrawn AS LOGICAL):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&FX-SLOTS}:
            IF NOT mFxOn[i] THEN DO:
                mFxOn[i] = TRUE.
                mFxX[i] = piX.
                mFxY[i] = piY.
                mFxArt[i] = piArt.
                mFxTimer[i] = piFrames.
                mFxNextArt[i] = piNextArt.
                mFxNextTimer[i] = piNextFrames.
                mFxColour[i] = piColour.
                mFxAccent[i] = piAccent.
                IF NOT plAlreadyDrawn THEN
                    mCanvas:DrawOnEmpty(InvadersArt:Picture(piArt), piX, piY, {&KIND-FX}, piColour, piAccent, piColour).
                RETURN.
            END.
        END.
    END METHOD.

    /* Counts down every effect: explosions change picture and go, the saucer's score fades, sparks fly. */
    METHOD PRIVATE VOID UpdateEffects():
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE rise AS INTEGER NO-UNDO.
        DO i = 1 TO {&FX-SLOTS}:
            IF NOT mFxOn[i] THEN NEXT.
            mFxTimer[i] = mFxTimer[i] - 1.
            IF mFxTimer[i] > 0 THEN NEXT.
            mCanvas:Erase(InvadersArt:Picture(mFxArt[i]), mFxX[i], mFxY[i], {&KIND-FX}).
            IF mFxNextArt[i] <> 0 THEN DO:
                mFxArt[i] = mFxNextArt[i].
                mFxTimer[i] = mFxNextTimer[i].
                mFxNextArt[i] = 0.
                mCanvas:DrawOnEmpty(InvadersArt:Picture(mFxArt[i]), mFxX[i], mFxY[i], {&KIND-FX}, mFxColour[i], mFxAccent[i], mFxColour[i]).
            END.
            ELSE mFxOn[i] = FALSE.
        END.
        UpdateMuzzle().
        UpdateShimmer().
        UpdateGroundFlash().
        IF mPulse > 0 THEN mPulse = mPulse - 1.
        IF mPopOn THEN DO:
            mPopTimer = mPopTimer - 1.
            IF mPopTimer <= 0 THEN DO:
                mCanvas:ShowBackRect(mPopX, mPopY, PixelFont:WidthOf(mPopText), 7).
                mPopOn = FALSE.
            END.
            ELSE DO:
                /* it rises a cell every 3 frames (up to 8 cells) and turns dull for its last 6 */
                rise = MINIMUM(8, INTEGER(TRUNCATE(({&POP-FRAMES} - mPopTimer) / 3, 0))).
                IF {&SAUCER-Y} - rise <> mPopY OR mPopTimer = 6 THEN DO:
                    mCanvas:ShowBackRect(mPopX, mPopY, PixelFont:WidthOf(mPopText), 7).
                    mPopY = {&SAUCER-Y} - rise.
                    mCanvas:DrawOverlay(mPopText, mPopX, mPopY, InvadersLook:Colour(IF mPopTimer <= 6 THEN {&C-GOLD-FADE} ELSE {&C-TEXT-GOLD}),
                                        InvadersLook:Colour(IF mPopTimer <= 6 THEN {&C-GOLD-FADE} ELSE {&C-TEXT-GOLD}), 1, -1).
                END.
            END.
        END.
        UpdateSparks().
    END METHOD.

    /* A few sparks flying out from a point, in a colour. */
    METHOD PRIVATE VOID SpawnSparks(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER, INPUT piCount AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO n = 1 TO piCount:
            SpawnSpark(piX, piY, piColour).
        END.
    END METHOD.

    METHOD PRIVATE VOID SpawnSpark(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&PARTICLES}:
            IF NOT mPtOn[i] THEN DO:
                mPtOn[i] = TRUE.
                mPtX[i] = piX * 16.
                mPtY[i] = piY * 16.
                mPtVx[i] = mRandom:NextInt(41) - 20.
                mPtVy[i] = mRandom:NextInt(33) - 28.
                mPtSpan[i] = 14 + mRandom:NextInt(14).
                mPtLife[i] = mPtSpan[i].
                mPtColour[i] = piColour.
                mPtDrawnAt[i] = -1.
                RETURN.
            END.
        END.
    END METHOD.

    /* Each spark moves on, falls a little faster each frame, dims, and goes out when its life is spent. */
    METHOD PRIVATE VOID UpdateSparks():
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE c   AS INTEGER NO-UNDO.
        DO i = 1 TO {&PARTICLES}:
            IF NOT mPtOn[i] THEN NEXT.
            /* take it off where it was drawn, if it is still there */
            IF mPtDrawnAt[i] >= 0 THEN DO:
                x = mPtDrawnAt[i] MODULO {&WIDTH}.
                y = INTEGER(TRUNCATE(mPtDrawnAt[i] / {&WIDTH}, 0)).
                IF mCanvas:KindAt(x, y) = {&KIND-FX} AND mCanvas:ColourAt(x, y) = mPtDrawn[i] THEN mCanvas:Unplot(x, y).
                mPtDrawnAt[i] = -1.
            END.
            mPtLife[i] = mPtLife[i] - 1.
            IF mPtLife[i] <= 0 THEN DO:
                mPtOn[i] = FALSE.
                NEXT.
            END.
            mPtX[i] = mPtX[i] + mPtVx[i].
            mPtY[i] = mPtY[i] + mPtVy[i].
            mPtVy[i] = mPtVy[i] + 2.
            x = INTEGER(TRUNCATE(mPtX[i] / 16, 0)).
            y = INTEGER(TRUNCATE(mPtY[i] / 16, 0)).
            IF x < 0 OR x >= {&WIDTH} OR y < 0 OR y >= {&GROUND-Y} THEN DO:
                mPtOn[i] = FALSE.
                NEXT.
            END.
            IF mCanvas:KindAt(x, y) <> {&KIND-NONE} THEN NEXT.
            c = InvadersLook:Mix(mPtColour[i], mSky[y + 1], mPtSpan[i] - mPtLife[i], mPtSpan[i]).
            mCanvas:Plot(x, y, {&KIND-FX}, c).
            mPtDrawn[i] = c.
            mPtDrawnAt[i] = y * {&WIDTH} + x.
        END.
    END METHOD.

    /* Takes every explosion, spark and pop-up off, for a new screen. The picture has been wiped already. */
    METHOD PRIVATE VOID ClearEffects():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&FX-SLOTS}:
            mFxOn[i] = FALSE.
        END.
        DO i = 1 TO {&PARTICLES}:
            mPtOn[i] = FALSE.
            mPtDrawnAt[i] = -1.
        END.
        DO i = 0 TO 2:
            mBombOn[i + 1] = FALSE.
        END.
        mShotOn = FALSE.
        mSaucerOn = FALSE.
        mPopOn = FALSE.
        mMuzzle = 0.
        mGfTimer = 0.
        mPulse = 0.
        DO i = 1 TO 128:
            mShmOn[i] = FALSE.
        END.
        mBlast = 0.
        DO i = 1 TO InvaderRack:Total():
            mDrawn[i] = FALSE.
        END.
    END METHOD.

    /* The stars drift down, the far ones slowly, and come back at the top. */
    METHOD PRIVATE VOID UpdateStars():
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE showing AS LOGICAL NO-UNDO.
        DO i = 1 TO {&STARS}:
            IF mFrames MODULO mStPeriod[i] <> 0 THEN NEXT.
            /* a star is only taken off where it is showing, and only put on where the plain sky is showing: text and pictures win */
            IF mCanvas:KindAt(mStX[i], mStY[i]) = {&KIND-NONE} AND mCanvas:ColourAt(mStX[i], mStY[i]) = mStShown[i] THEN DO:
                mCanvas:SetBack(mStX[i], mStY[i], mSky[mStY[i] + 1]).
                mCanvas:ShowBack(mStX[i], mStY[i]).
            END.
            ELSE mCanvas:SetBack(mStX[i], mStY[i], mSky[mStY[i] + 1]).
            mStY[i] = mStY[i] + 1.
            IF mStY[i] >= {&GROUND-Y} - 4 THEN mStY[i] = 24.
            showing = (mCanvas:KindAt(mStX[i], mStY[i]) = {&KIND-NONE} AND mCanvas:ColourAt(mStX[i], mStY[i]) = mCanvas:BackAt(mStX[i], mStY[i])).
            /* the bright stars flash white for a few steps every two seconds or so */
            mStShown[i] = (IF mStPeriod[i] = 3 AND (mFrames + i * 13) MODULO 130 < 12 THEN InvadersLook:Colour({&C-STAR-TWINKLE}) ELSE mStColour[i]).
            mCanvas:SetBack(mStX[i], mStY[i], mStShown[i]).
            IF showing THEN mCanvas:ShowBack(mStX[i], mStY[i]).
        END.
    END METHOD.

    /* ================================ the score panel ================================ */

    /* The labels that do not change: SCORE, HI-SCORE, WAVE and the cannons left. The numbers follow in RefreshHud. */
    METHOD PRIVATE VOID DrawHudFrame():
        mCanvas:DrawText("SCORE", 8, 6, InvadersLook:Colour({&C-TEXT-LABEL})).
        mCanvas:DrawText("HI-SCORE", 88, 6, InvadersLook:Colour({&C-TEXT-LABEL})).
        mCanvas:DrawText("WAVE", 193, 6, InvadersLook:Colour({&C-TEXT-LABEL})).
        mHudScore = -1.
        mHudHi = -1.
        mHudLives = -1.
        mHudWave = -1.
    END METHOD.

    /* Writes the numbers that have changed since they were last written. */
    METHOD PRIVATE VOID RefreshHud():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF Score <> mHudScore OR (mPulse > 0) <> mHudGold THEN DO:
            mCanvas:ClearRect(8, 16, 29, 7).
            mCanvas:DrawText(STRING(Score, "99999"), 8, 16, InvadersLook:Colour(IF mPulse > 0 THEN {&C-TEXT-GOLD} ELSE {&C-TEXT})).
            mHudScore = Score.
            mHudGold = (mPulse > 0).
        END.
        IF HiScore <> mHudHi THEN DO:
            mCanvas:ClearRect(97, 16, 29, 7).
            mCanvas:DrawText(STRING(HiScore, "99999"), 97, 16, InvadersLook:Colour({&C-TEXT})).
            mHudHi = HiScore.
        END.
        IF Phase <> {&PHASE-TITLE} AND Wave <> mHudWave THEN DO:
            mCanvas:ClearRect(192, 16, 24, 7).
            mCanvas:DrawText(STRING(Wave), 216 - PixelFont:WidthOf(STRING(Wave)), 16, InvadersLook:Colour({&C-TEXT})).
            mHudWave = Wave.
        END.
        IF Phase <> {&PHASE-TITLE} AND Lives <> mHudLives THEN DO:
            mCanvas:ClearRect(8, 241, 200, 8).
            mCanvas:DrawText(STRING(Lives), 8, 241, InvadersLook:Colour({&C-TEXT})).
            DO i = 1 TO Lives - 1:
                mCanvas:Draw(InvadersArt:Picture({&ART-LIVES}), 18 + (i - 1) * 16, 241, {&KIND-FX},
                             InvadersLook:Colour({&C-CANNON}), InvadersLook:Colour({&C-CANNON-LIGHT}), InvadersLook:Colour({&C-CANNON-DEEP})).
            END.
            mHudLives = Lives.
        END.
    END METHOD.

    /* The prompt that blinks on the title and game over screens, in gold: 36 frames on and 24 off, counted from
       piElapsed frames since it began. */
    METHOD PRIVATE VOID BlinkPrompt(INPUT piY AS INTEGER, INPUT piElapsed AS INTEGER):
        DEFINE VARIABLE wanted AS LOGICAL NO-UNDO.
        wanted = (piElapsed MODULO 60 < 36).
        IF wanted = mPromptOn AND piElapsed > 0 THEN RETURN.
        mPromptOn = wanted.
        mCanvas:ShowBackRect(70, piY, 90, 7).
        IF wanted THEN mCanvas:DrawOverlay("PRESS SPACE", 79, piY, InvadersLook:Colour({&C-TEXT-GOLD}), InvadersLook:Colour({&C-TEXT-GOLD}), 1, -1).
    END METHOD.

    METHOD PRIVATE VOID CheckType(INPUT piType AS INTEGER):
        IF piType = ? OR piType < 0 OR piType > 2 THEN
            UNDO, THROW NEW GridException("A bomb type is 0, 1 or 2, not " + STRING(piType)).
    END METHOD.

END CLASS.
