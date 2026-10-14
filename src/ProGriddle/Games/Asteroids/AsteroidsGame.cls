/* Asteroids, on a 320 x 240 grid, one cell to a pixel, in direct colour. It is a real time game that runs at 60 frames
   a second whatever the clock does: Tick adds up the time it is given and makes a frame for every sixtieth of a second
   (at the speed chosen), so a test drives it frame by frame with Advance.

   Everything that moves has a position and a velocity in 4096ths of a cell (a "unit"), so the maths is whole numbers
   and the game plays the same every time. Headings are the 64 steps of Heading, and the shapes are outlines turned
   to a heading and drawn as lines (see OutlinePen), so a frame is: put the background back, draw all the lines in
   one batch, then the cells (shots, sparks, text) over them. Collisions are circles, never the drawn lines.

   The ship turns, thrusts and drifts with a little drag, on a screen that wraps on all four edges, and has up to four
   shots in the air that fade after about three quarters of the screen. A wave starts with 4 large rocks and 2 more
   each wave up to 11: a shot splits a large rock into two medium ones, a medium into two small ones, and a small one
   just bursts (20, 50 and 100 points). The ship that touches a rock breaks up, and a new one comes only when the middle
   of the screen is clear, blinking and protected for a second and a half. Three ships, and an extra one at every
   10000 points. Now and then a saucer crosses the screen and shoots: the large one (200 points) at random, the small
   one (1000 points, from 3000 points up) aimed at the ship, less wildly as the score grows. A saucer, and its shots,
   break the ship too; a saucer that touches a rock is destroyed. The game owns its grid. Dispose releases it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:


    /* the field: cells, and the 4096ths of a cell a unit is */
    &SCOPED-DEFINE WIDTH 320
    &SCOPED-DEFINE HEIGHT 240
    &SCOPED-DEFINE UNIT 4096
    &SCOPED-DEFINE WIDTH-U 1310720
    &SCOPED-DEFINE HEIGHT-U 983040
    /* the ship: acceleration a frame, the top speed and the drag, in units. The ship turns 3 steps in 4 frames, so a
       full circle takes about 1.4 seconds */
    &SCOPED-DEFINE THRUST 225
    &SCOPED-DEFINE MAX-SPEED 14336
    &SCOPED-DEFINE DRAG-DIVISOR 128
    /* shots: how many, how fast (6 cells a frame), how long they live, the gap between two, and where the nose is */
    &SCOPED-DEFINE SHOTS 4
    &SCOPED-DEFINE SHOT-SPEED 24576
    &SCOPED-DEFINE SHOT-LIFE 40
    &SCOPED-DEFINE FIRE-GAP 8
    &SCOPED-DEFINE NOSE 24576
    /* the saucers: how fast they cross, how fast their shots fly (cells a frame), and how long a shot lives */
    &SCOPED-DEFINE SAUCER-SHOTS 4
    &SCOPED-DEFINE SAUCER-SHOT-LIFE 80
    /* how long things take, in frames */
    &SCOPED-DEFINE INTRO-FRAMES 30
    &SCOPED-DEFINE DYING-FRAMES 90
    &SCOPED-DEFINE SHIELD-FRAMES 90
    &SCOPED-DEFINE CLEARED-FRAMES 60
    &SCOPED-DEFINE OVER-FRAMES 90
    &SCOPED-DEFINE HYPER-OUT-FRAMES 12
    &SCOPED-DEFINE HYPER-GAP-FRAMES 30
    &SCOPED-DEFINE HYPER-BACK-FRAMES 12
    /* how many pieces of text the game keeps ready to draw */
    &SCOPED-DEFINE STAMPS 96
    /* the most frames one Tick will make, and the most time it will count: a stall must not make a burst */
    &SCOPED-DEFINE MOST-FRAMES 4
    &SCOPED-DEFINE MOST-MS 100
    /* the dust that drifts, and the dust that is baked into the background */
    &SCOPED-DEFINE MOVING-DUST 20

    DEFINE PRIVATE VARIABLE mRandom    AS IRandom     NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas    AS PixelCanvas NO-UNDO.
    DEFINE PRIVATE VARIABLE mPen       AS OutlinePen  NO-UNDO.
    DEFINE PRIVATE VARIABLE mAcc       AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mFrames    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mPaused    AS LOGICAL     NO-UNDO.
    DEFINE PRIVATE VARIABLE mTitleT    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mTrace     AS TitleTrace  NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice    AS CHARACTER   NO-UNDO.
    /* the vignette: 65 colours from the middle of the screen to its edge */
    DEFINE PRIVATE VARIABLE mVignette  AS INTEGER     NO-UNDO EXTENT 65.
    /* the ship */
    DEFINE PRIVATE VARIABLE mSX        AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSY        AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSVX       AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSVY       AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeading   AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mTurnAcc   AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mFlameT    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mThrusting AS LOGICAL     NO-UNDO.
    DEFINE PRIVATE VARIABLE mShipMode  AS ShipMode    NO-UNDO.
    DEFINE PRIVATE VARIABLE mShipTimer AS INTEGER     NO-UNDO.
    /* frames since the ship last appeared: it is protected and blinks while this is under 90 */
    DEFINE PRIVATE VARIABLE mShieldT   AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mFireGap   AS INTEGER     NO-UNDO.
    /* whether the jump through hyperspace in progress will go wrong when the ship comes back */
    DEFINE PRIVATE VARIABLE mHyperFail AS LOGICAL     NO-UNDO.
    /* whether the fire key was down a frame ago */
    DEFINE PRIVATE VARIABLE mFireWas   AS LOGICAL     NO-UNDO.
    /* the shots in the air: place and velocity in units, the heading they were fired at, and the frames they have left */
    DEFINE PRIVATE VARIABLE mShX       AS INTEGER     NO-UNDO EXTENT {&SHOTS}.
    DEFINE PRIVATE VARIABLE mShY       AS INTEGER     NO-UNDO EXTENT {&SHOTS}.
    DEFINE PRIVATE VARIABLE mShVX      AS INTEGER     NO-UNDO EXTENT {&SHOTS}.
    DEFINE PRIVATE VARIABLE mShVY      AS INTEGER     NO-UNDO EXTENT {&SHOTS}.
    DEFINE PRIVATE VARIABLE mShHead    AS INTEGER     NO-UNDO EXTENT {&SHOTS}.
    DEFINE PRIVATE VARIABLE mShLife    AS INTEGER     NO-UNDO EXTENT {&SHOTS}.
    DEFINE PRIVATE VARIABLE mRocks     AS RockField   NO-UNDO.
    DEFINE PRIVATE VARIABLE mDebris    AS DebrisPool  NO-UNDO.
    /* the pieces of text that are ready to draw, and what each is (see Stamp) */
    DEFINE PRIVATE VARIABLE mStamp     AS TextStamp   NO-UNDO EXTENT {&STAMPS}.
    DEFINE PRIVATE VARIABLE mStampKey  AS CHARACTER   NO-UNDO EXTENT {&STAMPS}.
    DEFINE PRIVATE VARIABLE mStampNext AS INTEGER     NO-UNDO.
    /* the saucer: there is at most one. Place and velocity in units, which size, how long it has been out, frames to its
       next shot and to its next change of height */
    DEFINE PRIVATE VARIABLE mSaucOn    AS LOGICAL     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucLarge AS LOGICAL     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucX     AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucY     AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucVX    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucVY    AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucAge   AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucFireT AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucZigT  AS INTEGER     NO-UNDO.
    /* frames until the next saucer, and the one that has been planned: its size, side and height */
    DEFINE PRIVATE VARIABLE mSaucWait  AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlanned   AS LOGICAL     NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlanLarge AS LOGICAL     NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlanDir   AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlanY     AS INTEGER     NO-UNDO.
    /* the saucers' shots */
    DEFINE PRIVATE VARIABLE mSsX       AS INTEGER     NO-UNDO EXTENT {&SAUCER-SHOTS}.
    DEFINE PRIVATE VARIABLE mSsY       AS INTEGER     NO-UNDO EXTENT {&SAUCER-SHOTS}.
    DEFINE PRIVATE VARIABLE mSsVX      AS INTEGER     NO-UNDO EXTENT {&SAUCER-SHOTS}.
    DEFINE PRIVATE VARIABLE mSsVY      AS INTEGER     NO-UNDO EXTENT {&SAUCER-SHOTS}.
    DEFINE PRIVATE VARIABLE mSsLife    AS INTEGER     NO-UNDO EXTENT {&SAUCER-SHOTS}.
    DEFINE PRIVATE VARIABLE mSsLarge   AS LOGICAL     NO-UNDO EXTENT {&SAUCER-SHOTS}.
    /* frames until the rocks of a new wave appear, and frames since the last rock was shot */
    DEFINE PRIVATE VARIABLE mIntro     AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mClearT    AS INTEGER     NO-UNDO.
    /* frames since the wave began, for its banner */
    DEFINE PRIVATE VARIABLE mWaveT     AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mOverT     AS INTEGER     NO-UNDO.
    /* the score at which the next extra ship comes */
    DEFINE PRIVATE VARIABLE mNextExtra AS INTEGER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mNewHi     AS LOGICAL     NO-UNDO.
    /* frames the score still shows gold after a saucer or an extra ship */
    DEFINE PRIVATE VARIABLE mPulseT    AS INTEGER     NO-UNDO.
    /* the dust that drifts: position and velocity in units, and the colour number */
    DEFINE PRIVATE VARIABLE mDustX     AS INTEGER     NO-UNDO EXTENT {&MOVING-DUST}.
    DEFINE PRIVATE VARIABLE mDustY     AS INTEGER     NO-UNDO EXTENT {&MOVING-DUST}.
    DEFINE PRIVATE VARIABLE mDustV     AS INTEGER     NO-UNDO EXTENT {&MOVING-DUST}.
    DEFINE PRIVATE VARIABLE mDustC     AS Palette     NO-UNDO EXTENT {&MOVING-DUST}.

    /* While false, Advance makes its frame but does not draw the picture, so a test can run hundreds of frames in
       a moment and draw only the last one. True to begin with. Tick always draws. */
    DEFINE PUBLIC PROPERTY Drawing AS LOGICAL NO-UNDO INITIAL TRUE
        GET.
        SET.

    /* True while the game is stopped. Pausing a game that has run shows the picture dimmed once, with PAUSED over it; the
       next frame after resuming draws a fresh picture, so nothing needs undoing. */
    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET():
            RETURN mPaused.
        END GET.
        SET(INPUT plPaused AS LOGICAL):
            IF plPaused AND NOT mPaused AND mFrames > 0 THEN DO:
                mCanvas:Dim(45).
                Stamp("PAUSED", 3, AsteroidsLook:Colour(Palette:TextWhite), AsteroidsLook:Colour(Palette:TextWhite), AsteroidsLook:Colour(Palette:TextOutline)):DrawTo(mCanvas, 107, 100).
            END.
            mPaused = plPaused.
        END SET.

    /* How fast the game runs, as a percentage of the real 60 frames a second: 20 to 100. Everything slows together,
       so the game stays the same game and is only easier to play. */
    DEFINE PUBLIC PROPERTY SpeedPercent AS INTEGER NO-UNDO INITIAL 100
        GET.
        SET(INPUT piValue AS INTEGER):
            SpeedPercent = MINIMUM(100, MAXIMUM(20, piValue)).
        END SET.

    /* Which phase of the game this is. */
    DEFINE PUBLIC PROPERTY Phase AS GamePhase NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Score AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The best score. The input sets it from the settings and keeps it when it is beaten. */
    DEFINE PUBLIC PROPERTY HiScore AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Lives AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Wave AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Which way the ship is being turned: -1 left, 1 right, 0 not at all. The input sets it from the held keys. */
    DEFINE PUBLIC PROPERTY TurnDirection AS INTEGER NO-UNDO
        GET.
        SET(INPUT piValue AS INTEGER):
            TurnDirection = MINIMUM(1, MAXIMUM(-1, piValue)).
        END SET.

    /* True while the thrust key is held. */
    DEFINE PUBLIC PROPERTY ThrustHeld AS LOGICAL NO-UNDO
        GET.
        SET.

    /* True while the fire key is held. On the title and game over screens it must be pressed afresh to count. */
    DEFINE PUBLIC PROPERTY FireHeld AS LOGICAL NO-UNDO
        GET.
        SET.

    /* The ship's heading, 0 to 63, 0 being straight up. */
    DEFINE PUBLIC PROPERTY ShipHeading AS INTEGER NO-UNDO
        GET():
            RETURN mHeading.
        END GET.

    /* Where the middle of the ship is, in whole cells (0 to 319 and 0 to 239). */
    DEFINE PUBLIC PROPERTY ShipX AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(mSX / {&UNIT}, 0)).
        END GET.

    DEFINE PUBLIC PROPERTY ShipY AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(mSY / {&UNIT}, 0)).
        END GET.

    /* How fast the ship moves, in 4096ths of a cell a frame. */
    DEFINE PUBLIC PROPERTY ShipVX AS INTEGER NO-UNDO
        GET():
            RETURN mSVX.
        END GET.

    DEFINE PUBLIC PROPERTY ShipVY AS INTEGER NO-UNDO
        GET():
            RETURN mSVY.
        END GET.

    /* True while the thrust is pushing the ship this frame. */
    DEFINE PUBLIC PROPERTY Thrusting AS LOGICAL NO-UNDO
        GET():
            RETURN mThrusting.
        END GET.

    /* True while the ship is flying (not breaking up, and not waiting for a clear middle of the screen). */
    DEFINE PUBLIC PROPERTY ShipAlive AS LOGICAL NO-UNDO
        GET():
            RETURN mShipMode = ShipMode:Alive AND Phase = GamePhase:Playing.
        END GET.

    /* True while the ship is away in hyperspace: leaving, gone, or coming back. */
    DEFINE PUBLIC PROPERTY Hyperspacing AS LOGICAL NO-UNDO
        GET():
            RETURN (mShipMode = ShipMode:HyperOut OR mShipMode = ShipMode:HyperGap OR mShipMode = ShipMode:HyperBack) AND Phase = GamePhase:Playing.
        END GET.

    /* Frames of protection the ship has left: it cannot be hit while this is above 0. */
    DEFINE PUBLIC PROPERTY ShieldFrames AS INTEGER NO-UNDO
        GET():
            RETURN (IF ShipAlive THEN MAXIMUM(0, {&SHIELD-FRAMES} - mShieldT) ELSE 0).
        END GET.

    /* The rocks. A test may add and take away rocks to set up a position. */
    DEFINE PUBLIC PROPERTY Rocks AS RockField NO-UNDO
        GET():
            RETURN mRocks.
        END GET.

    /* How many of the ship's shots are in the air. */
    DEFINE PUBLIC PROPERTY ShotCount AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO {&SHOTS}:
                IF mShLife[i] > 0 THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* True while a saucer is out, and which: the large one or the small one. */
    DEFINE PUBLIC PROPERTY SaucerActive AS LOGICAL NO-UNDO
        GET():
            RETURN mSaucOn.
        END GET.

    DEFINE PUBLIC PROPERTY SaucerLarge AS LOGICAL NO-UNDO
        GET():
            RETURN mSaucLarge.
        END GET.

    /* Where the saucer's middle is, in whole cells. It may be a little off the screen as it comes in and goes out. */
    DEFINE PUBLIC PROPERTY SaucerX AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(mSaucX / {&UNIT}, 0)).
        END GET.

    DEFINE PUBLIC PROPERTY SaucerY AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(mSaucY / {&UNIT}, 0)).
        END GET.

    /* True once the best score has been beaten in this game. */
    DEFINE PUBLIC PROPERTY NewHiScore AS LOGICAL NO-UNDO
        GET():
            RETURN mNewHi.
        END GET.

    /* How many frames the game has made. */
    DEFINE PUBLIC PROPERTY FrameCount AS INTEGER NO-UNDO
        GET():
            RETURN mFrames.
        END GET.

    /* The canvas the picture is drawn on, for tests and for anything that wants to look at it. */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    /* The grid must be 320 x 240 on an ArrayStore with the layers view, kind and back. */
    CONSTRUCTOR PUBLIC AsteroidsGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        SUPER("Asteroids", poGrid).
        IF poGrid:Width <> {&WIDTH} OR poGrid:Height <> {&HEIGHT} THEN
            UNDO, THROW NEW GridException("An Asteroids grid is " + STRING({&WIDTH}) + " x " + STRING({&HEIGHT})).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("An Asteroids game needs a random source").
        mRandom = poRandom.
        mCanvas = NEW PixelCanvas(poGrid).
        mPen = NEW OutlinePen(mCanvas).
        mRocks = NEW RockField().
        mDebris = NEW DebrisPool(poRandom, {&WIDTH}, {&HEIGHT}).
        DO i = 0 TO 64:
            mVignette[i + 1] = ColourMath:Mix(AsteroidsLook:Colour(Palette:VoidCentre), AsteroidsLook:Colour(Palette:VoidEdge), i, 64).
        END.
        Initialise().
    END CONSTRUCTOR.

    /* Moves time on by piElapsedMs milliseconds and makes the frames that are due at the speed, up to 4. Returns true
       when a frame was made. Does nothing while Paused. The picture is drawn once, after the last frame. */
    METHOD PUBLIC LOGICAL Tick(INPUT piElapsedMs AS INTEGER):
        DEFINE VARIABLE made AS INTEGER NO-UNDO.
        IF Paused OR piElapsedMs <= 0 THEN RETURN FALSE.
        mAcc = mAcc + INTEGER(ROUND(MINIMUM(piElapsedMs, {&MOST-MS}) * 0.6 * SpeedPercent, 0)).
        DO WHILE mAcc >= 1000 AND made < {&MOST-FRAMES}:
            mAcc = mAcc - 1000.
            Step().
            made = made + 1.
        END.
        IF mAcc >= 1000 THEN mAcc = 0.
        IF made > 0 THEN Render().
        RETURN made > 0.
    END METHOD.

    /* One sixtieth of a second of the game, and the picture of it (unless Drawing is off). */
    METHOD PUBLIC VOID Advance():
        Step().
        IF Drawing THEN Render().
    END METHOD.

    /* Starts a new game: no score, three ships, the first wave. Works from any phase. */
    METHOD PUBLIC VOID StartGame():
        Score = 0.
        Lives = 3.
        Wave = 1.
        mNotice = "".
        mNextExtra = 10000.
        mNewHi = FALSE.
        mOverT = 0.
        mDebris:Clear().
        mRocks:Clear().
        ClearShots().
        ClearSaucer().
        mSaucWait = 1200.
        Phase = GamePhase:Playing.
        PlaceShip().
        StartWave().
        Render().
    END METHOD.

    /* Puts the rocks of the wave on the screen at once instead of after the short pause that starts a wave. For tests,
       and for anything that wants the game in play without waiting half a second. */
    METHOD PUBLIC VOID SkipIntro():
        DO WHILE mIntro > 0 AND Phase = GamePhase:Playing:
            Step().
        END.
        Render().
    END METHOD.

    /* How many large rocks a wave starts with: 4, and 2 more each wave, up to 11. */
    METHOD PUBLIC STATIC INTEGER RocksFor(INPUT piWave AS INTEGER):
        RETURN MINIMUM(11, 4 + 2 * (MAXIMUM(1, piWave) - 1)).
    END METHOD.

    /* The points for breaking a rock of a size (1 large, 2 medium, 3 small): 20, 50 and 100. */
    METHOD PUBLIC STATIC INTEGER RockPoints(INPUT piSize AS INTEGER):
        IF piSize = ? OR piSize < 1 OR piSize > 3 THEN UNDO, THROW NEW GridException("A rock size is 1, 2 or 3, not " + STRING(piSize)).
        RETURN INTEGER(ENTRY(piSize, "20,50,100")).
    END METHOD.

    /* Adds to the score, and gives an extra ship at every 10000 points, and the best score follows the score. */
    METHOD PUBLIC VOID AddScore(INPUT piPoints AS INTEGER):
        IF piPoints = ? OR piPoints < 0 THEN UNDO, THROW NEW GridException("Points are 0 or more, not " + STRING(piPoints)).
        Score = Score + piPoints.
        DO WHILE Score >= mNextExtra:
            mNextExtra = mNextExtra + 10000.
            Lives = Lives + 1.
            mNotice = "Extra ship".
            mPulseT = 20.
        END.
        IF Score > HiScore THEN DO:
            HiScore = Score.
            mNewHi = TRUE.
        END.
    END METHOD.

    /* Sends a saucer across the screen now, from the left (piDirection 1) or the right (-1), at a random height: the large
       one or the small one. Throws GridException when one is out already, or when there is no game in play. */
    METHOD PUBLIC VOID LaunchSaucer(INPUT plLarge AS LOGICAL, INPUT piDirection AS INTEGER):
        LaunchSaucerAt(plLarge, piDirection, 30 + mRandom:NextInt(181)).
    END METHOD.

    /* The same, at a chosen row of the screen (20 to 220). */
    METHOD PUBLIC VOID LaunchSaucerAt(INPUT plLarge AS LOGICAL, INPUT piDirection AS INTEGER, INPUT piRow AS INTEGER):
        IF plLarge = ? THEN UNDO, THROW NEW GridException("A saucer is large or small, not unknown").
        IF piDirection <> 1 AND piDirection <> -1 THEN UNDO, THROW NEW GridException("A saucer comes from the left (1) or the right (-1), not " + STRING(piDirection)).
        IF piRow = ? OR piRow < 20 OR piRow > 220 THEN UNDO, THROW NEW GridException("A saucer flies at a row from 20 to 220, not " + STRING(piRow)).
        IF mSaucOn THEN UNDO, THROW NEW GridException("A saucer is out already").
        IF Phase <> GamePhase:Playing THEN UNDO, THROW NEW GridException("There is no game in play to put a saucer in").
        StartSaucer(plLarge, piDirection, piRow * {&UNIT}).
    END METHOD.

    /* Moves the saucer that is out to a place, in whole cells. Throws GridException when there is none. */
    METHOD PUBLIC VOID PlaceSaucer(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT mSaucOn THEN UNDO, THROW NEW GridException("There is no saucer to place").
        mSaucX = piX * {&UNIT}.
        mSaucY = piY * {&UNIT}.
    END METHOD.

    /* How many pieces of debris are flying (ship, rock and saucer break ups, rings and sparks). */
    DEFINE PUBLIC PROPERTY DebrisCount AS INTEGER NO-UNDO
        GET():
            RETURN mDebris:Count.
        END GET.

    /* Takes every piece of debris off the screen, for a test that wants to count only one kind. */
    METHOD PUBLIC VOID ClearDebris():
        mDebris:Clear().
    END METHOD.

    /* How many saucer shots are in the air, and where one is, in whole cells (slots 0 to 3). */
    DEFINE PUBLIC PROPERTY SaucerShotCount AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO {&SAUCER-SHOTS}:
                IF mSsLife[i] > 0 THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    METHOD PUBLIC INTEGER SaucerShotX(INPUT piSlot AS INTEGER):
        CheckSaucerShot(piSlot).
        RETURN INTEGER(TRUNCATE(mSsX[piSlot + 1] / {&UNIT}, 0)).
    END METHOD.

    METHOD PUBLIC INTEGER SaucerShotY(INPUT piSlot AS INTEGER):
        CheckSaucerShot(piSlot).
        RETURN INTEGER(TRUNCATE(mSsY[piSlot + 1] / {&UNIT}, 0)).
    END METHOD.

    /* The shot in a slot (0 to 3): where it is in whole cells, and the frames it has left (0 when the slot is free). */
    METHOD PUBLIC INTEGER ShotX(INPUT piSlot AS INTEGER):
        CheckShot(piSlot).
        RETURN INTEGER(TRUNCATE(mShX[piSlot + 1] / {&UNIT}, 0)).
    END METHOD.

    METHOD PUBLIC INTEGER ShotY(INPUT piSlot AS INTEGER):
        CheckShot(piSlot).
        RETURN INTEGER(TRUNCATE(mShY[piSlot + 1] / {&UNIT}, 0)).
    END METHOD.

    METHOD PUBLIC INTEGER ShotLife(INPUT piSlot AS INTEGER):
        CheckShot(piSlot).
        RETURN mShLife[piSlot + 1].
    END METHOD.

    /* The ship jumps to a random place and comes back a moment later, with a small chance of blowing up. Does
       nothing outside a game, or when the ship is not flying. */
    METHOD PUBLIC VOID Hyperspace():
        IF Phase <> GamePhase:Playing OR mShipMode <> ShipMode:Alive THEN RETURN.
        mShipMode = ShipMode:HyperOut.
        mShipTimer = 0.
        mThrusting = FALSE.
        /* a 6 percent chance of trouble, and half a percent more for every rock there is to come back among */
        mHyperFail = mRandom:NextInt(100) < 6 + INTEGER(TRUNCATE(mRocks:Count / 2, 0)).
    END METHOD.

    /* What the game has to say, once: an extra life, a new wave. */
    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID Dispose():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&STAMPS}:
            IF VALID-OBJECT(mStamp[i]) THEN mStamp[i]:Dispose().
        END.
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        SUPER:Dispose().
    END METHOD.

    /* A new game, or the title screen the first time. */
    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        mAcc = 0.
        mFrames = 0.
        mTitleT = 0.
        Phase = GamePhase:Title.
        Score = 0.
        mNewHi = FALSE.
        mDebris:Clear().
        ClearShots().
        ClearSaucer().
        BakeBackground().
        MakeDust().
        PlaceShip().
        MakeAttractRocks().
        Render().
    END METHOD.

    /* ================================ the frame ================================ */

    METHOD PRIVATE VOID Step():
        mFrames = mFrames + 1.
        IF mPulseT > 0 THEN mPulseT = mPulseT - 1.
        MoveDust().
        mDebris:Step().
        CASE Phase:
            WHEN GamePhase:Title THEN FrameTitle().
            WHEN GamePhase:Playing THEN FramePlaying().
            WHEN GamePhase:GameOver THEN FrameGameOver().
        END CASE.
        mFireWas = FireHeld.
    END METHOD.

    METHOD PRIVATE VOID FrameTitle():
        mTitleT = mTitleT + 1.
        /* every 14 seconds a large saucer crosses behind the words, left to right at row 140 (clear of PRESS SPACE), and
           fires nothing */
        IF mTitleT MODULO 840 = 0 AND NOT mSaucOn THEN StartSaucer(TRUE, 1, 140 * {&UNIT}).
        IF mSaucOn THEN MoveSaucer().
        mRocks:Move().
        IF FireHeld AND NOT mFireWas THEN StartGame().
    END METHOD.

    /* A frame of play: the wave, the ship, the shots, the rocks, and what they hit. */
    METHOD PRIVATE VOID FramePlaying():
        RunWave().
        CASE mShipMode:
            WHEN ShipMode:Alive THEN FlyShip().
            WHEN ShipMode:Dying THEN FrameDying().
            WHEN ShipMode:Waiting THEN FrameWaiting().
            WHEN ShipMode:HyperOut THEN FrameHyperOut().
            WHEN ShipMode:HyperGap THEN FrameHyperGap().
            WHEN ShipMode:HyperBack THEN FrameHyperBack().
        END CASE.
        MoveShots().
        MoveSaucerShots().
        RunSaucer().
        mRocks:Move().
        HitRocksWithShots().
        HitSaucerWithShots().
        IF mShipMode = ShipMode:Alive AND mShieldT >= {&SHIELD-FRAMES} THEN DO:
            HitShipWithRocks().
            HitShipWithSaucer().
            HitShipWithSaucerShots().
        END.
        HitRocksWithSaucer().
    END METHOD.

    /* The rocks go on drifting behind GAME OVER, and the fire key, pressed afresh once the prompt is up, starts again. */
    METHOD PRIVATE VOID FrameGameOver():
        mOverT = mOverT + 1.
        mRocks:Move().
        MoveShots().
        MoveSaucerShots().
        IF mSaucOn THEN MoveSaucer().
        IF FireHeld AND NOT mFireWas AND mOverT >= {&OVER-FRAMES} THEN Initialise().
    END METHOD.

    /* ================================ the waves ================================ */

    /* A new wave: the rocks come after a short pause, flashing white as they appear. */
    METHOD PRIVATE VOID StartWave():
        mIntro = {&INTRO-FRAMES}.
        mClearT = 0.
        mWaveT = 0.
    END METHOD.

    /* The pause before the rocks, and when the last rock is gone, the pause before the next wave. */
    METHOD PRIVATE VOID RunWave():
        mWaveT = mWaveT + 1.
        IF mIntro > 0 THEN DO:
            mIntro = mIntro - 1.
            IF mIntro = 0 THEN SpawnRocks().
            RETURN.
        END.
        IF mRocks:Count = 0 AND NOT mSaucOn THEN DO:
            mClearT = mClearT + 1.
            IF mClearT >= {&CLEARED-FRAMES} THEN DO:
                Wave = Wave + 1.
                StartWave().
            END.
        END.
        ELSE mClearT = 0.
    END METHOD.

    /* The large rocks of the wave, in places away from the ship, drifting in random directions. */
    METHOD PRIVATE VOID SpawnRocks():
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE tries AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DO n = 1 TO RocksFor(Wave):
            DO tries = 1 TO 30:
                x = mRandom:NextInt({&WIDTH-U}).
                y = mRandom:NextInt({&HEIGHT-U}).
                IF NOT Near(x, y, mSX, mSY, 70 * {&UNIT}) THEN LEAVE.
            END.
            AddRock(x, y, 0, 0, 1, 0).
        END.
    END METHOD.

    /* Puts a rock of a size in a place, drifting at a random speed for its size (a little faster in later waves)
       in a random direction, plus the velocity it is given. If piSpeed is above 0 it is the speed instead. The
       outline, the first heading and the spin are random. */
    METHOD PRIVATE VOID AddRock(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piVX AS INTEGER, INPUT piVY AS INTEGER,
                                INPUT piSize AS INTEGER, INPUT piSpeed AS INTEGER):
        DEFINE VARIABLE dir    AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed  AS INTEGER NO-UNDO.
        DEFINE VARIABLE lo     AS INTEGER NO-UNDO.
        DEFINE VARIABLE hi     AS INTEGER NO-UNDO.
        DEFINE VARIABLE period AS INTEGER NO-UNDO.
        DEFINE VARIABLE slot   AS INTEGER NO-UNDO.
        dir = mRandom:NextInt(64).
        CASE piSize:
            WHEN 1 THEN ASSIGN lo = 1024 hi = 2253 period = 30 + mRandom:NextInt(31).
            WHEN 2 THEN ASSIGN lo = 1638 hi = 3686 period = 15 + mRandom:NextInt(16).
            OTHERWISE ASSIGN lo = 2458 hi = 5325 period = 6 + mRandom:NextInt(9).
        END CASE.
        speed = lo + mRandom:NextInt(hi - lo + 1).
        speed = INTEGER(TRUNCATE(speed * (100 + MINIMUM(30, 3 * (MAXIMUM(1, Wave) - 1))) / 100, 0)).
        IF piSpeed > 0 THEN speed = piSpeed.
        slot = mRocks:Add(piX, piY, piVX + INTEGER(TRUNCATE(Heading:DirX(dir) * speed / 1024, 0)),
                          piVY + INTEGER(TRUNCATE(Heading:DirY(dir) * speed / 1024, 0)), piSize,
                          mRandom:NextInt(AsteroidsArt:RockVariants(piSize)), mRandom:NextInt(64), period,
                          (IF mRandom:NextInt(2) = 0 THEN -1 ELSE 1)).
    END METHOD.

    /* Six slow rocks to drift behind the title: two of each size. */
    METHOD PRIVATE VOID MakeAttractRocks():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mRocks:Clear().
        DO i = 0 TO 5:
            AddRock(mRandom:NextInt({&WIDTH-U}), mRandom:NextInt({&HEIGHT-U}), 0, 0, 1 + (i MODULO 3), 205 + mRandom:NextInt(615)).
        END.
    END METHOD.

    /* What a shot hits: the first rock whose circle holds the head of the shot. The rock breaks in two (a large one
       into two medium, a medium into two small, a small one only bursts), and scores. */
    METHOD PRIVATE VOID HitRocksWithShots():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE r AS INTEGER NO-UNDO.
        DO i = 1 TO {&SHOTS}:
            IF mShLife[i] <= 0 THEN NEXT.
            DO r = 0 TO RockField:Capacity() - 1:
                IF mRocks:SizeAt(r) = 0 THEN NEXT.
                IF Near(mShX[i], mShY[i], mRocks:X(r), mRocks:Y(r), AsteroidsArt:RockRadius(mRocks:SizeAt(r)) * 16 + {&UNIT}) THEN DO:
                    mShLife[i] = 0.
                    BreakRock(r, TRUE).
                    LEAVE.
                END.
            END.
        END.
    END METHOD.

    /* A rock is destroyed: its points, and two smaller ones that fly apart in its place. */
    METHOD PRIVATE VOID BreakRock(INPUT piSlot AS INTEGER, INPUT plScore AS LOGICAL):
        DEFINE VARIABLE size AS INTEGER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE vx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE vy   AS INTEGER NO-UNDO.
        DEFINE VARIABLE push AS INTEGER NO-UNDO.
        DEFINE VARIABLE dir  AS INTEGER NO-UNDO.
        DEFINE VARIABLE px   AS INTEGER NO-UNDO.
        DEFINE VARIABLE py   AS INTEGER NO-UNDO.
        size = mRocks:SizeAt(piSlot).
        x = mRocks:X(piSlot).
        y = mRocks:Y(piSlot).
        vx = mRocks:VX(piSlot).
        vy = mRocks:VY(piSlot).
        mDebris:RockBurst(size, x, y, mRocks:HeadingAt(piSlot), mRocks:Variant(piSlot)).
        mRocks:Remove(piSlot).
        IF plScore THEN AddScore(RockPoints(size)).
        IF size < 3 THEN DO:
            /* the two pieces get the old velocity and a push of 0.3 to 0.6 cells a frame in opposite directions */
            push = 1229 + mRandom:NextInt(1230).
            dir = mRandom:NextInt(64).
            px = INTEGER(TRUNCATE(Heading:DirX(dir) * push / 1024, 0)).
            py = INTEGER(TRUNCATE(Heading:DirY(dir) * push / 1024, 0)).
            AddPiece(x, y, vx + px, vy + py, size + 1).
            AddPiece(x, y, vx - px, vy - py, size + 1).
        END.
    END METHOD.

    METHOD PRIVATE VOID AddPiece(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piVX AS INTEGER, INPUT piVY AS INTEGER, INPUT piSize AS INTEGER):
        DEFINE VARIABLE period AS INTEGER NO-UNDO.
        DEFINE VARIABLE slot   AS INTEGER NO-UNDO.
        period = (IF piSize = 2 THEN 15 + mRandom:NextInt(16) ELSE 6 + mRandom:NextInt(9)).
        slot = mRocks:Add(piX, piY, piVX, piVY, piSize, mRandom:NextInt(AsteroidsArt:RockVariants(piSize)), mRandom:NextInt(64), period,
                          (IF mRandom:NextInt(2) = 0 THEN -1 ELSE 1)).
    END METHOD.

    /* True when two places, on a screen that wraps, are within a distance of each other. All in units. */
    METHOD PRIVATE LOGICAL Near(INPUT piX1 AS INTEGER, INPUT piY1 AS INTEGER, INPUT piX2 AS INTEGER, INPUT piY2 AS INTEGER, INPUT piRadius AS INTEGER):
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        dx = ABSOLUTE(piX1 - piX2).
        IF dx > {&WIDTH-U} / 2 THEN dx = {&WIDTH-U} - dx.
        dy = ABSOLUTE(piY1 - piY2).
        IF dy > {&HEIGHT-U} / 2 THEN dy = {&HEIGHT-U} - dy.
        RETURN INT64(dx) * dx + INT64(dy) * dy <= INT64(piRadius) * piRadius.
    END METHOD.

    /* ================================ the saucers ================================ */

    /* Waits for the next saucer, shows a warning a second before it comes, and flies the one that is out. */
    METHOD PRIVATE VOID RunSaucer():
        IF mSaucOn THEN DO:
            MoveSaucer().
            RETURN.
        END.
        IF mIntro > 0 THEN RETURN.
        mSaucWait = mSaucWait - 1.
        IF mSaucWait <= 60 AND NOT mPlanned THEN PlanSaucer().
        IF mSaucWait <= 0 THEN StartSaucer(mPlanLarge, mPlanDir, mPlanY).
    END METHOD.

    /* Decides which saucer comes next, which side it comes from and at what height. The small one only comes once
       the score is 3000, and more and more often after that. */
    METHOD PRIVATE VOID PlanSaucer():
        DEFINE VARIABLE small AS LOGICAL NO-UNDO.
        mPlanned = TRUE.
        small = Score >= 3000 AND mRandom:NextInt(100) < (IF Score >= 10000 THEN 70 ELSE 35).
        mPlanLarge = NOT small.
        mPlanDir = (IF mRandom:NextInt(2) = 0 THEN 1 ELSE -1).
        mPlanY = (30 + mRandom:NextInt(181)) * {&UNIT}.
    END METHOD.

    /* The saucer comes in at the edge it was planned for, moving across at its own speed: 0.7 of a cell a frame for the
       large one and a cell a frame for the small one. */
    METHOD PRIVATE VOID StartSaucer(INPUT plLarge AS LOGICAL, INPUT piDirection AS INTEGER, INPUT piY AS INTEGER):
        mSaucOn = TRUE.
        mSaucLarge = plLarge.
        mSaucX = (IF piDirection = 1 THEN - 8 * {&UNIT} ELSE {&WIDTH-U} + 8 * {&UNIT}).
        mSaucY = piY.
        mSaucVX = piDirection * (IF plLarge THEN 2867 ELSE 4096).
        mSaucVY = 0.
        mSaucAge = 0.
        mSaucFireT = 60 + mRandom:NextInt(40).
        mSaucZigT = 40 + mRandom:NextInt(60).
        mPlanned = FALSE.
    END METHOD.

    /* The saucer moves across, changes height now and then, turns back from the top and the bottom, fires, and goes
       when it is across. */
    METHOD PRIVATE VOID MoveSaucer():
        mSaucAge = mSaucAge + 1.
        mSaucX = mSaucX + mSaucVX.
        mSaucY = mSaucY + mSaucVY.
        IF mSaucY < 20 * {&UNIT} THEN mSaucVY = ABSOLUTE(mSaucVY).
        IF mSaucY > 220 * {&UNIT} THEN mSaucVY = - ABSOLUTE(mSaucVY).
        /* the saucer on the title screen flies straight and fires nothing */
        IF Phase <> GamePhase:Title THEN DO:
            mSaucZigT = mSaucZigT - 1.
            IF mSaucZigT <= 0 THEN DO:
                mSaucVY = (mRandom:NextInt(3) - 1) * 1638.
                mSaucZigT = 40 + mRandom:NextInt(80).
            END.
            mSaucFireT = mSaucFireT - 1.
            IF mSaucFireT <= 0 THEN DO:
                SaucerFire().
                mSaucFireT = (IF mSaucLarge THEN 70 + mRandom:NextInt(50) ELSE 55 + mRandom:NextInt(35)).
            END.
        END.
        IF (mSaucVX > 0 AND mSaucX > {&WIDTH-U} + 9 * {&UNIT}) OR (mSaucVX < 0 AND mSaucX < - 9 * {&UNIT}) THEN RemoveSaucer().
    END METHOD.

    /* A saucer shot leaves the saucer: the large saucer fires in a random direction, the small one aims at the ship, with
       an error that gets smaller as the score grows (6 headings at 3000 points, none at 30000). */
    METHOD PRIVATE VOID SaucerFire():
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE h     AS INTEGER NO-UNDO.
        DEFINE VARIABLE err   AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed AS INTEGER NO-UNDO.
        DO i = 1 TO {&SAUCER-SHOTS}:
            IF mSsLife[i] > 0 THEN NEXT.
            IF mSaucLarge OR NOT ShipAlive THEN h = mRandom:NextInt(64).
            ELSE DO:
                dx = mSX - mSaucX.
                IF dx > {&WIDTH-U} / 2 THEN dx = dx - {&WIDTH-U}.
                IF dx < - {&WIDTH-U} / 2 THEN dx = dx + {&WIDTH-U}.
                dy = mSY - mSaucY.
                IF dy > {&HEIGHT-U} / 2 THEN dy = dy - {&HEIGHT-U}.
                IF dy < - {&HEIGHT-U} / 2 THEN dy = dy + {&HEIGHT-U}.
                h = Heading:Nearest(INTEGER(TRUNCATE(dx / 16, 0)), INTEGER(TRUNCATE(dy / 16, 0))).
                err = MAXIMUM(0, 6 - INTEGER(TRUNCATE(Score / 5000, 0))).
                h = h + mRandom:NextInt(2 * err + 1) - err.
            END.
            speed = (IF mSaucLarge THEN 8192 ELSE 9011).
            mSsX[i] = WrapUnits(mSaucX, {&WIDTH-U}).
            mSsY[i] = WrapUnits(mSaucY, {&HEIGHT-U}).
            mSsVX[i] = INTEGER(TRUNCATE(Heading:DirX(h) * speed / 1024, 0)).
            mSsVY[i] = INTEGER(TRUNCATE(Heading:DirY(h) * speed / 1024, 0)).
            mSsLife[i] = {&SAUCER-SHOT-LIFE}.
            mSsLarge[i] = mSaucLarge.
            RETURN.
        END.
    END METHOD.

    METHOD PRIVATE VOID MoveSaucerShots():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&SAUCER-SHOTS}:
            IF mSsLife[i] <= 0 THEN NEXT.
            mSsX[i] = WrapUnits(mSsX[i] + mSsVX[i], {&WIDTH-U}).
            mSsY[i] = WrapUnits(mSsY[i] + mSsVY[i], {&HEIGHT-U}).
            mSsLife[i] = mSsLife[i] - 1.
        END.
    END METHOD.

    /* The saucer is gone, shot or crossed: the next one comes in 15 to 30 seconds. */
    METHOD PRIVATE VOID RemoveSaucer():
        mSaucOn = FALSE.
        mSaucWait = 900 + mRandom:NextInt(900).
    END METHOD.

    METHOD PRIVATE VOID ClearSaucer():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mSaucOn = FALSE.
        mPlanned = FALSE.
        mSaucWait = 1200.
        DO i = 1 TO {&SAUCER-SHOTS}:
            mSsLife[i] = 0.
        END.
    END METHOD.

    /* A shot of the ship that reaches the saucer destroys it: 200 points for the large one, 1000 for the small. */
    METHOD PRIVATE VOID HitSaucerWithShots():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT mSaucOn THEN RETURN.
        DO i = 1 TO {&SHOTS}:
            IF mShLife[i] <= 0 THEN NEXT.
            IF Near(mShX[i], mShY[i], mSaucX, mSaucY, AsteroidsArt:SaucerRadius(mSaucLarge) * 16 + {&UNIT}) THEN DO:
                mShLife[i] = 0.
                AddScore(IF mSaucLarge THEN 200 ELSE 1000).
                mPulseT = 20.
                RemoveSaucer().
                RETURN.
            END.
        END.
    END METHOD.

    /* A saucer that flies into the ship breaks it, and is destroyed itself (and scores). */
    METHOD PRIVATE VOID HitShipWithSaucer():
        IF NOT mSaucOn THEN RETURN.
        IF Near(mSX, mSY, mSaucX, mSaucY, (AsteroidsArt:SaucerRadius(mSaucLarge) + AsteroidsArt:ShipRadius()) * 16) THEN DO:
            AddScore(IF mSaucLarge THEN 200 ELSE 1000).
            mPulseT = 20.
            RemoveSaucer().
            KillShip().
        END.
    END METHOD.

    /* A saucer's shot that reaches the ship breaks it. */
    METHOD PRIVATE VOID HitShipWithSaucerShots():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&SAUCER-SHOTS}:
            IF mSsLife[i] <= 0 THEN NEXT.
            IF Near(mSX, mSY, mSsX[i], mSsY[i], AsteroidsArt:ShipRadius() * 16 + 6144) THEN DO:
                mSsLife[i] = 0.
                KillShip().
                RETURN.
            END.
        END.
    END METHOD.

    /* A saucer that flies into a rock is destroyed, and the rock breaks (but nobody scores). */
    METHOD PRIVATE VOID HitRocksWithSaucer():
        DEFINE VARIABLE r AS INTEGER NO-UNDO.
        IF NOT mSaucOn THEN RETURN.
        DO r = 0 TO RockField:Capacity() - 1:
            IF mRocks:SizeAt(r) = 0 THEN NEXT.
            IF Near(mSaucX, mSaucY, mRocks:X(r), mRocks:Y(r), (AsteroidsArt:RockRadius(mRocks:SizeAt(r)) + AsteroidsArt:SaucerRadius(mSaucLarge)) * 16) THEN DO:
                RemoveSaucer().
                BreakRock(r, FALSE).
                RETURN.
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID CheckSaucerShot(INPUT piSlot AS INTEGER):
        IF piSlot = ? OR piSlot < 0 OR piSlot >= {&SAUCER-SHOTS} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A saucer shot slot is 0 to &1, not &2", {&SAUCER-SHOTS} - 1, piSlot)).
    END METHOD.

    METHOD PRIVATE VOID CheckShot(INPUT piSlot AS INTEGER):
        IF piSlot = ? OR piSlot < 0 OR piSlot >= {&SHOTS} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A shot slot is 0 to &1, not &2", {&SHOTS} - 1, piSlot)).
    END METHOD.

    METHOD PRIVATE VOID ClearShots():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&SHOTS}:
            mShLife[i] = 0.
        END.
    END METHOD.

    /* ================================ the ship ================================ */

    /* The ship in the middle of the screen, still, nose up, protected for the first second and a half. */
    METHOD PRIVATE VOID PlaceShip():
        mSX = {&WIDTH-U} / 2.
        mSY = {&HEIGHT-U} / 2.
        mSVX = 0.
        mSVY = 0.
        mHeading = 0.
        mTurnAcc = 0.
        mFlameT = 0.
        mThrusting = FALSE.
        mShipMode = ShipMode:Alive.
        mShieldT = 0.
        mFireGap = 0.
    END METHOD.

    /* A frame of the flying ship: the shield runs down, it moves, and it fires if the key is down. */
    METHOD PRIVATE VOID FlyShip():
        IF mShieldT < {&SHIELD-FRAMES} THEN mShieldT = mShieldT + 1.
        MoveShip().
        IF mFireGap > 0 THEN mFireGap = mFireGap - 1.
        IF FireHeld AND mFireGap = 0 THEN Fire().
    END METHOD.

    /* A shot leaves the nose along the heading, faster than the ship by half the ship's own speed, if there is a free
       slot (at most 4 are in the air). */
    METHOD PRIVATE VOID Fire():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&SHOTS}:
            IF mShLife[i] = 0 THEN DO:
                mShX[i] = WrapUnits(mSX + INTEGER(TRUNCATE(Heading:DirX(mHeading) * {&NOSE} / 1024, 0)), {&WIDTH-U}).
                mShY[i] = WrapUnits(mSY + INTEGER(TRUNCATE(Heading:DirY(mHeading) * {&NOSE} / 1024, 0)), {&HEIGHT-U}).
                mShVX[i] = INTEGER(TRUNCATE(Heading:DirX(mHeading) * {&SHOT-SPEED} / 1024, 0)) + INTEGER(TRUNCATE(mSVX / 2, 0)).
                mShVY[i] = INTEGER(TRUNCATE(Heading:DirY(mHeading) * {&SHOT-SPEED} / 1024, 0)) + INTEGER(TRUNCATE(mSVY / 2, 0)).
                mShHead[i] = mHeading.
                mShLife[i] = {&SHOT-LIFE}.
                mFireGap = {&FIRE-GAP}.
                RETURN.
            END.
        END.
    END METHOD.

    /* Every shot moves, wraps and runs down. */
    METHOD PRIVATE VOID MoveShots():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&SHOTS}:
            IF mShLife[i] <= 0 THEN NEXT.
            mShX[i] = WrapUnits(mShX[i] + mShVX[i], {&WIDTH-U}).
            mShY[i] = WrapUnits(mShY[i] + mShVY[i], {&HEIGHT-U}).
            mShLife[i] = mShLife[i] - 1.
        END.
    END METHOD.

    /* A rock touches the ship: it breaks up. */
    METHOD PRIVATE VOID HitShipWithRocks():
        DEFINE VARIABLE r AS INTEGER NO-UNDO.
        DO r = 0 TO RockField:Capacity() - 1:
            IF mRocks:SizeAt(r) = 0 THEN NEXT.
            IF Near(mSX, mSY, mRocks:X(r), mRocks:Y(r), (AsteroidsArt:RockRadius(mRocks:SizeAt(r)) + AsteroidsArt:ShipRadius()) * 16) THEN DO:
                KillShip().
                RETURN.
            END.
        END.
    END METHOD.

    /* Leaving: the ship drifts on and stretches away. */
    METHOD PRIVATE VOID FrameHyperOut():
        mShipTimer = mShipTimer + 1.
        mSX = WrapUnits(mSX + mSVX, {&WIDTH-U}).
        mSY = WrapUnits(mSY + mSVY, {&HEIGHT-U}).
        IF mShipTimer >= {&HYPER-OUT-FRAMES} THEN DO:
            mShipMode = ShipMode:HyperGap.
            mShipTimer = 0.
            /* it comes back somewhere else, at rest, away from the very edge */
            mSX = (20 + mRandom:NextInt(281)) * {&UNIT}.
            mSY = (30 + mRandom:NextInt(181)) * {&UNIT}.
            mSVX = 0.
            mSVY = 0.
        END.
    END METHOD.

    /* Gone: nothing can touch the ship. */
    METHOD PRIVATE VOID FrameHyperGap():
        mShipTimer = mShipTimer + 1.
        IF mShipTimer >= {&HYPER-GAP-FRAMES} THEN DO:
            mShipMode = ShipMode:HyperBack.
            mShipTimer = 0.
        END.
    END METHOD.

    /* Coming back: the ship draws itself in again, and then it either flies or, if the jump went wrong, breaks up
       where it came back. It has no shield: it may come back among the rocks. */
    METHOD PRIVATE VOID FrameHyperBack():
        mShipTimer = mShipTimer + 1.
        IF mShipTimer >= {&HYPER-BACK-FRAMES} THEN DO:
            IF mHyperFail THEN KillShip().
            ELSE DO:
                mShipMode = ShipMode:Alive.
                mShieldT = {&SHIELD-FRAMES}.
                mFireGap = 0.
            END.
        END.
    END METHOD.

    /* The ship breaks up and a ship is gone. */
    METHOD PRIVATE VOID KillShip():
        Lives = Lives - 1.
        mShipMode = ShipMode:Dying.
        mShipTimer = 0.
        mThrusting = FALSE.
    END METHOD.

    /* The ship comes apart for a second and a half, drifting on. Then the next ship, or the end of the game. */
    METHOD PRIVATE VOID FrameDying():
        mShipTimer = mShipTimer + 1.
        /* the ship has been white for three frames: now it comes apart */
        IF mShipTimer = 3 THEN mDebris:ShipBreakup(mSX, mSY, mSVX, mSVY, mHeading).
        mSX = WrapUnits(mSX + mSVX, {&WIDTH-U}).
        mSY = WrapUnits(mSY + mSVY, {&HEIGHT-U}).
        IF mShipTimer >= {&DYING-FRAMES} THEN DO:
            IF Lives > 0 THEN DO:
                mShipMode = ShipMode:Waiting.
                mShipTimer = 0.
            END.
            ELSE DO:
                Phase = GamePhase:GameOver.
                mOverT = 0.
            END.
        END.
    END METHOD.

    /* A new ship comes only when the middle of the screen is clear: no rock within 30 cells of the middle, counting the
       size of the rock itself. */
    METHOD PRIVATE VOID FrameWaiting():
        DEFINE VARIABLE r     AS INTEGER NO-UNDO.
        DEFINE VARIABLE isClear AS LOGICAL NO-UNDO INITIAL TRUE.
        DEFINE VARIABLE reach AS INTEGER NO-UNDO.
        mShipTimer = mShipTimer + 1.
        DO r = 0 TO RockField:Capacity() - 1:
            IF mRocks:SizeAt(r) = 0 THEN NEXT.
            reach = (30 * {&UNIT}) + AsteroidsArt:RockRadius(mRocks:SizeAt(r)) * 16.
            IF ABSOLUTE(mRocks:X(r) - {&WIDTH-U} / 2) <= reach AND ABSOLUTE(mRocks:Y(r) - {&HEIGHT-U} / 2) <= reach THEN isClear = FALSE.
        END.
        IF isClear THEN PlaceShip().
    END METHOD.

    /* One frame of the ship: turn, thrust, drag, the speed limit, move and wrap. */
    METHOD PRIVATE VOID MoveShip():
        DEFINE VARIABLE speed AS DECIMAL NO-UNDO.
        /* turning: 3 steps in every 4 frames */
        IF TurnDirection <> 0 THEN DO:
            mTurnAcc = mTurnAcc + 3.
            DO WHILE mTurnAcc >= 4:
                mTurnAcc = mTurnAcc - 4.
                mHeading = Heading:Wrap(mHeading + TurnDirection).
            END.
        END.
        ELSE mTurnAcc = 0.
        /* thrust */
        mThrusting = ThrustHeld.
        IF mThrusting THEN DO:
            mSVX = mSVX + INTEGER(TRUNCATE(Heading:DirX(mHeading) * {&THRUST} / 1024, 0)).
            mSVY = mSVY + INTEGER(TRUNCATE(Heading:DirY(mHeading) * {&THRUST} / 1024, 0)).
            mFlameT = mFlameT + 1.
        END.
        ELSE mFlameT = 0.
        /* drag, then the speed limit */
        mSVX = mSVX - INTEGER(TRUNCATE(mSVX / {&DRAG-DIVISOR}, 0)).
        mSVY = mSVY - INTEGER(TRUNCATE(mSVY / {&DRAG-DIVISOR}, 0)).
        speed = SQRT(DECIMAL(mSVX) * mSVX + DECIMAL(mSVY) * mSVY).
        IF speed > {&MAX-SPEED} THEN DO:
            mSVX = INTEGER(TRUNCATE(mSVX * {&MAX-SPEED} / speed, 0)).
            mSVY = INTEGER(TRUNCATE(mSVY * {&MAX-SPEED} / speed, 0)).
        END.
        mSX = WrapUnits(mSX + mSVX, {&WIDTH-U}).
        mSY = WrapUnits(mSY + mSVY, {&HEIGHT-U}).
    END METHOD.

    /* A position put back on the screen: 0 up to the size, whichever side it left by. */
    METHOD PRIVATE STATIC INTEGER WrapUnits(INPUT piValue AS INTEGER, INPUT piSize AS INTEGER):
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        v = piValue MODULO piSize.
        IF v < 0 THEN v = v + piSize.
        RETURN v.
    END METHOD.

    /* A position in units as 256ths of a cell, which is what the pen takes. Positions are never negative. */
    METHOD PRIVATE STATIC INTEGER ToPen(INPUT piUnits AS INTEGER):
        RETURN INTEGER((piUnits - piUnits MODULO 16) / 16).
    END METHOD.

    /* ================================ the background and the dust ================================ */

    /* The vignette, a very dark blue that is a touch lighter in the middle, and 70 cells of dust, baked into the
       background layer so they cost nothing each frame. */
    METHOD PRIVATE VOID BakeBackground():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE d2    AS DECIMAL NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cells AS ICellStore NO-UNDO.
        DEFINE VARIABLE backLayer AS INTEGER NO-UNDO.
        DEFINE VARIABLE idx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE tries AS INTEGER NO-UNDO.
        DEFINE VARIABLE c     AS Palette NO-UNDO.
        cells = Grid:Store.
        backLayer = cells:LayerIndex("back").
        DO y = 0 TO {&HEIGHT} - 1:
            DO x = 0 TO {&WIDTH} - 1:
                d2 = ((x - 160) / 200) * ((x - 160) / 200) + ((y - 120) / 150) * ((y - 120) / 150).
                cells:SetCellAt(backLayer, y * {&WIDTH} + x, mVignette[INTEGER(ROUND(MINIMUM(1, d2) * 64, 0)) + 1]).
            END.
        END.
        /* 40 dim, 20 mid and 10 bright dust cells, each in a cell of its own */
        DO n = 1 TO 70:
            c = (IF n <= 40 THEN Palette:DustDim ELSE IF n <= 60 THEN Palette:DustMid ELSE Palette:DustBright).
            DO tries = 1 TO 50:
                idx = mRandom:NextInt({&WIDTH} * {&HEIGHT}).
                IF LOOKUP(STRING(cells:GetCellAt(backLayer, idx)), DustColours()) = 0 THEN LEAVE.
            END.
            cells:SetCellAt(backLayer, idx, AsteroidsLook:Colour(c)).
        END.
    END METHOD.

    /* The colours of dust, as numbers in a comma list, to tell a dust cell from the vignette. */
    METHOD PRIVATE STATIC CHARACTER DustColours():
        RETURN SUBSTITUTE("&1,&2,&3", AsteroidsLook:Colour(Palette:DustDim), AsteroidsLook:Colour(Palette:DustMid), AsteroidsLook:Colour(Palette:DustBright)).
    END METHOD.

    /* 20 cells of dust that drift left and a little down, in three speeds. */
    METHOD PRIVATE VOID MakeDust():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&MOVING-DUST}:
            mDustX[i] = mRandom:NextInt({&WIDTH-U}).
            mDustY[i] = mRandom:NextInt({&HEIGHT-U}).
            CASE i MODULO 3:
                WHEN 0 THEN ASSIGN mDustV[i] = 164 mDustC[i] = Palette:DustDim.
                WHEN 1 THEN ASSIGN mDustV[i] = 328 mDustC[i] = Palette:DustMid.
                OTHERWISE ASSIGN mDustV[i] = 573 mDustC[i] = Palette:DustBright.
            END CASE.
        END.
    END METHOD.

    METHOD PRIVATE VOID MoveDust():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&MOVING-DUST}:
            mDustX[i] = WrapUnits(mDustX[i] - mDustV[i], {&WIDTH-U}).
            mDustY[i] = WrapUnits(mDustY[i] + INTEGER(TRUNCATE(mDustV[i] / 4, 0)), {&HEIGHT-U}).
        END.
    END METHOD.

    /* ================================ drawing ================================ */

    /* The whole picture: the background, the drifting dust, every line in one batch, then the cells over them. */
    METHOD PRIVATE VOID Render():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mCanvas:Restore().
        DO i = 1 TO {&MOVING-DUST}:
            mCanvas:Plot(INTEGER(TRUNCATE(mDustX[i] / {&UNIT}, 0)), INTEGER(TRUNCATE(mDustY[i] / {&UNIT}, 0)), 0, AsteroidsLook:Colour(mDustC[i])).
        END.
        mCanvas:BeginBatch().
        /* every halo first, so a glow can never cover a line */
        IF mSaucOn THEN DrawSaucerHalo().
        IF ShipVisible() THEN DrawShipHalo().
        DrawRocks().
        IF mSaucOn THEN DrawSaucerCore().
        IF ShipVisible() THEN DrawShipCore().
        IF mShipMode = ShipMode:Dying AND mShipTimer < 3 THEN
            mPen:DrawWrapped(AsteroidsArt:Ship(), ToPen(mSX), ToPen(mSY), mHeading, AsteroidsArt:ShipExtent(), 0, AsteroidsLook:Colour(Palette:Flash), 0, 0).
        mDebris:DrawTo(mCanvas).
        IF mShipMode = ShipMode:HyperOut AND Phase = GamePhase:Playing THEN DrawHyperShip(MINIMUM(5, INTEGER(TRUNCATE(MAXIMUM(0, mShipTimer - 1) / 2, 0)))).
        IF mShipMode = ShipMode:HyperBack AND Phase = GamePhase:Playing THEN DrawHyperShip(5 - MINIMUM(5, INTEGER(TRUNCATE(MAXIMUM(0, mShipTimer - 1) / 2, 0)))).
        IF ShipAlive AND ShieldFrames > 0 THEN DrawShieldRing().
        DrawLivesIcons().
        DrawHud().
        IF Phase = GamePhase:Playing AND mWaveT <= 90 THEN DrawWaveBanner().
        IF Phase = GamePhase:GameOver THEN DrawGameOver().
        IF Phase = GamePhase:Title THEN DrawTitle().
        mCanvas:EndBatch().
        DrawSaucerShots().
        DrawShots().
    END METHOD.

    /* The banner of a new wave, for a second and a half: a line grows out from the middle over the first quarter of a
       second, WAVE and its number appear in a shade from white to grey, and for the last third of a second both step
       down through grey to nothing. All of it sits above the middle of the screen, so the ship stays in view. */
    METHOD PRIVATE VOID DrawWaveBanner():
        DEFINE VARIABLE half   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE colour AS INTEGER   NO-UNDO.
        DEFINE VARIABLE halo   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE words   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE edge   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE bx     AS INTEGER   NO-UNDO.
        /* the colour of the line, and of the words once they fade: Dim, Label, Title Rule, then gone */
        IF mWaveT < 77 THEN colour = AsteroidsLook:Colour(Palette:Dim).
        ELSE IF mWaveT < 84 THEN colour = AsteroidsLook:Colour(Palette:Label).
        ELSE colour = AsteroidsLook:Colour(Palette:TitleRule).
        halo = AsteroidsLook:Colour(Palette:TitleHalo).
        half = INTEGER(TRUNCATE(60 * MINIMUM(15, mWaveT) / 15, 0)).
        IF half > 0 THEN DO:
            mCanvas:DrawLine(160 - half - 1, 88, 160 + half - 1, 88, 0, halo).
            mCanvas:DrawLine(160 - half + 1, 88, 160 + half + 1, 88, 0, halo).
            mCanvas:DrawLine(160 - half, 87, 160 + half, 87, 0, halo).
            mCanvas:DrawLine(160 - half, 89, 160 + half, 89, 0, halo).
            mCanvas:DrawLine(160 - half, 88, 160 + half, 88, 0, colour).
        END.
        IF mWaveT < 8 THEN RETURN.
        words = "WAVE " + STRING(Wave).
        edge = AsteroidsLook:Colour(Palette:TextOutline).
        bx = INTEGER(TRUNCATE((320 - PixelFont:WidthOf(words) * 3) / 2, 0)).
        IF mWaveT >= 70 THEN Stamp(words, 3, colour, colour, edge):DrawTo(mCanvas, bx, 64).
        ELSE Stamp(words, 3, AsteroidsLook:Colour(Palette:BannerTop), AsteroidsLook:Colour(Palette:BannerBottom), edge):DrawTo(mCanvas, bx, 64).
    END METHOD.

    /* The title screen over the attract rocks: ASTEROIDS traced stroke by stroke by a beam (see TitleTrace). */
    METHOD PRIVATE VOID DrawTitle():
        DEFINE VARIABLE half   AS INTEGER NO-UNDO.
        DEFINE VARIABLE edge   AS INTEGER NO-UNDO.
        DEFINE VARIABLE labelCol AS INTEGER NO-UNDO.
        DEFINE VARIABLE white  AS INTEGER NO-UNDO.
        DEFINE VARIABLE tint   AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(mTrace) THEN mTrace = NEW TitleTrace().
        mTrace:DrawTo(mCanvas, mTitleT).
        /* ticks 110 to 128: the rule under the title grows from the middle, 14 cells a tick each way, to 240 cells */
        IF mTitleT > 110 THEN DO:
            half = MINIMUM(120, 14 * (mTitleT - 110)).
            mCanvas:DrawLine(160 - half, 98, 159 + half, 98, 0, AsteroidsLook:Colour(Palette:TitleRule)).
        END.
        edge = AsteroidsLook:Colour(Palette:TextOutline).
        labelCol = AsteroidsLook:Colour(Palette:Label).
        white = AsteroidsLook:Colour(Palette:TextWhite).
        /* from tick 128: the subtitle types in, a letter a tick */
        IF mTitleT >= 128 THEN
            Stamp(SUBSTRING("A PROGRIDDLE COOKOFF GAME", 1, MINIMUM(25, mTitleT - 127)), 1, labelCol, labelCol, edge):DrawTo(mCanvas, 85, 106).
        /* from tick 160: the two hint lines fade in, each through Title Rule, Label and Dim, 5 ticks a step */
        tint = HintColour(160).
        IF tint >= 0 THEN Stamp("LEFT RIGHT TURN   UP THRUST   SPACE FIRE", 1, tint, tint, edge):DrawTo(mCanvas, 40, 168).
        tint = HintColour(180).
        IF tint >= 0 THEN Stamp("DOWN HYPERSPACE", 1, tint, tint, edge):DrawTo(mCanvas, 115, 180).
        /* from tick 200: PRESS SPACE, 36 ticks on and 24 off */
        IF mTitleT >= 200 AND (mTitleT - 200) MODULO 60 < 36 THEN
            Stamp("PRESS SPACE", 2, white, white, edge):DrawTo(mCanvas, 95, 204).
    END METHOD.

    /* The colour of a hint line that began to fade in at a tick of the title: Title Rule, then Label, then Dim, five
       ticks each. -1 before it begins. */
    METHOD PRIVATE INTEGER HintColour(INPUT piStart AS INTEGER):
        DEFINE VARIABLE passed AS INTEGER NO-UNDO.
        passed = mTitleT - piStart.
        IF passed < 0 THEN RETURN -1.
        IF passed < 5 THEN RETURN AsteroidsLook:Colour(Palette:TitleRule).
        IF passed < 10 THEN RETURN AsteroidsLook:Colour(Palette:Label).
        RETURN AsteroidsLook:Colour(Palette:Dim).
    END METHOD.

    /* The game over screen over the drifting rocks: GAME OVER in a red gradient, one letter every 3 frames, the score, a
       gold NEW HI-SCORE that blinks (10 frames on, 10 off) when the record fell, and after 90 frames PRESS SPACE (36 on,
       24 off). The letters are stamps of growing beginnings of the words, so each is made once and then only copied. */
    METHOD PRIVATE VOID DrawGameOver():
        DEFINE VARIABLE edge   AS INTEGER NO-UNDO.
        DEFINE VARIABLE white  AS INTEGER NO-UNDO.
        DEFINE VARIABLE labelCol AS INTEGER NO-UNDO.
        DEFINE VARIABLE shown  AS INTEGER NO-UNDO.
        edge = AsteroidsLook:Colour(Palette:TextOutline).
        white = AsteroidsLook:Colour(Palette:TextWhite).
        labelCol = AsteroidsLook:Colour(Palette:Label).
        shown = MINIMUM(9, INTEGER(TRUNCATE(mOverT / 3, 0)) + 1).
        Stamp(SUBSTRING("GAME OVER", 1, shown), 3, AsteroidsLook:Colour(Palette:OverTop), AsteroidsLook:Colour(Palette:OverBottom), edge):DrawTo(mCanvas, 80, 84).
        Stamp("SCORE ", 1, labelCol, labelCol, edge):DrawTo(mCanvas, 124, 116).
        Stamp(STRING(MINIMUM(Score, 999999), "999999"), 1, white, white, edge):DrawTo(mCanvas, 124 + PixelFont:WidthOf("SCORE "), 116).
        IF mNewHi AND INTEGER(TRUNCATE(mOverT / 10, 0)) MODULO 2 = 0 THEN
            Stamp("NEW HI-SCORE", 1, AsteroidsLook:Colour(Palette:Gold), AsteroidsLook:Colour(Palette:Gold), edge):DrawTo(mCanvas, 124, 132).
        IF mOverT >= {&OVER-FRAMES} AND (mOverT - {&OVER-FRAMES}) MODULO 60 < 36 THEN
            Stamp("PRESS SPACE", 1, white, white, edge):DrawTo(mCanvas, 127, 170).
    END METHOD.

    /* One small ship, nine tenths of its size, for every spare ship, along the left under the score (at most six). While
       a ship is flying the one in play is not a spare. */
    METHOD PRIVATE VOID DrawLivesIcons():
        DEFINE VARIABLE spare AS INTEGER NO-UNDO.
        DEFINE VARIABLE k     AS INTEGER NO-UNDO.
        spare = (IF mShipMode = ShipMode:Alive OR Hyperspacing THEN Lives - 1 ELSE Lives).
        IF Phase = GamePhase:GameOver THEN spare = 0.
        spare = MINIMUM(6, MAXIMUM(0, spare)).
        DO k = 0 TO spare - 1:
            mPen:DrawScaled(AsteroidsArt:Ship(), (17 + 11 * k) * 256, 44 * 256, 0, 90, 90, 0, AsteroidsLook:Colour(Palette:ShipIcon)).
        END.
    END METHOD.

    /* The score at the top left, the best score in the middle and the wave at the right, in the pixel font with a dark
       edge so that a rock drifting under a letter does not cut it. The words are stamps made once and kept (see
       Stamp), so a frame only copies them. */
    METHOD PRIVATE VOID DrawHud():
        DEFINE VARIABLE edge   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE labelCol AS INTEGER NO-UNDO.
        DEFINE VARIABLE white  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE dimCol AS INTEGER   NO-UNDO.
        DEFINE VARIABLE waveTx AS CHARACTER NO-UNDO.
        edge = AsteroidsLook:Colour(Palette:TextOutline).
        labelCol = AsteroidsLook:Colour(Palette:Label).
        white = AsteroidsLook:Colour(Palette:TextWhite).
        dimCol = AsteroidsLook:Colour(Palette:Dim).
        Stamp("SCORE", 1, labelCol, labelCol, edge):DrawTo(mCanvas, 12, 8).
        IF mPulseT > 0 THEN white = AsteroidsLook:Colour(Palette:Gold).
        Stamp(STRING(MINIMUM(Score, 999999), "999999"), 2, white, white, edge):DrawTo(mCanvas, 12, 18).
        Stamp("HI-SCORE", 1, labelCol, labelCol, edge):DrawTo(mCanvas, 136, 8).
        Stamp(STRING(MINIMUM(HiScore, 999999), "999999"), 1, dimCol, dimCol, edge):DrawTo(mCanvas, 142, 18).
        waveTx = STRING(Wave).
        Stamp("WAVE", 1, labelCol, labelCol, edge):DrawTo(mCanvas, 285, 8).
        white = AsteroidsLook:Colour(Palette:TextWhite).
        Stamp(waveTx, 2, white, white, edge):DrawTo(mCanvas, 307 - (LENGTH(waveTx) * 12 - 2), 18).
    END METHOD.

    /* A stamp of some text, made the first time it is asked for and kept: the last 48 are remembered, and the oldest
       goes when a new one needs the room. The game frees them all in Dispose. */
    METHOD PRIVATE TextStamp Stamp(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT piTop AS INTEGER, INPUT piBottom AS INTEGER, INPUT piEdge AS INTEGER):
        DEFINE VARIABLE key AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER   NO-UNDO.
        key = SUBSTITUTE("&1|&2|&3|&4|&5", pcText, piScale, piTop, piBottom, piEdge).
        DO i = 1 TO {&STAMPS}:
            IF mStampKey[i] = key AND VALID-OBJECT(mStamp[i]) THEN RETURN mStamp[i].
        END.
        mStampNext = mStampNext MODULO {&STAMPS} + 1.
        IF VALID-OBJECT(mStamp[mStampNext]) THEN mStamp[mStampNext]:Dispose().
        mStamp[mStampNext] = NEW TextStamp(pcText, piScale, piTop, piBottom, piEdge).
        mStampKey[mStampNext] = key.
        RETURN mStamp[mStampNext].
    END METHOD.

    /* True when the ship is on the screen: flying, and not in the blink of a new ship's protection. */
    METHOD PRIVATE LOGICAL ShipVisible():
        RETURN ShipAlive AND (ShieldFrames = 0 OR INTEGER(TRUNCATE(mShieldT / 5, 0)) MODULO 2 = 0).
    END METHOD.

    /* The saucer's glow, four dim copies one cell to each side. */
    METHOD PRIVATE VOID DrawSaucerHalo():
        DEFINE VARIABLE halo AS INTEGER NO-UNDO.
        DEFINE VARIABLE px   AS INTEGER NO-UNDO.
        DEFINE VARIABLE py   AS INTEGER NO-UNDO.
        halo = AsteroidsLook:Colour(IF mSaucLarge THEN Palette:SaucerLHalo ELSE Palette:SaucerSHalo).
        px = ToPen(mSaucX).
        py = ToPen(mSaucY).
        mPen:Draw(AsteroidsArt:Saucer(mSaucLarge), px, py, 0, 0, halo, -1, 0).
        mPen:Draw(AsteroidsArt:Saucer(mSaucLarge), px, py, 0, 0, halo, 1, 0).
        mPen:Draw(AsteroidsArt:Saucer(mSaucLarge), px, py, 0, 0, halo, 0, -1).
        mPen:Draw(AsteroidsArt:Saucer(mSaucLarge), px, py, 0, 0, halo, 0, 1).
    END METHOD.

    METHOD PRIVATE VOID DrawSaucerCore():
        mPen:Draw(AsteroidsArt:Saucer(mSaucLarge), ToPen(mSaucX), ToPen(mSaucY), 0, 0,
                  AsteroidsLook:Colour(IF mSaucLarge THEN Palette:SaucerLCore ELSE Palette:SaucerSCore), 0, 0).
    END METHOD.

    /* The saucers' shots: a plus and a cross of five cells that take turns every four frames, in the colour of the saucer
       that fired them and a pale middle. */
    METHOD PRIVATE VOID DrawSaucerShots():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE arm    AS INTEGER NO-UNDO.
        DEFINE VARIABLE d      AS INTEGER NO-UNDO.
        DEFINE VARIABLE plus   AS LOGICAL NO-UNDO.
        DO i = 1 TO {&SAUCER-SHOTS}:
            IF mSsLife[i] <= 0 THEN NEXT.
            x = INTEGER(TRUNCATE(mSsX[i] / {&UNIT}, 0)).
            y = INTEGER(TRUNCATE(mSsY[i] / {&UNIT}, 0)).
            arm = AsteroidsLook:Colour(IF mSsLarge[i] THEN Palette:SaucerLCore ELSE Palette:SaucerSCore).
            plus = INTEGER(TRUNCATE(mSsLife[i] / 4, 0)) MODULO 2 = 0.
            IF plus THEN DO:
                mCanvas:Plot(x - 1, y, 0, arm).
                mCanvas:Plot(x + 1, y, 0, arm).
                mCanvas:Plot(x, y - 1, 0, arm).
                mCanvas:Plot(x, y + 1, 0, arm).
            END.
            ELSE DO:
                mCanvas:Plot(x - 1, y - 1, 0, arm).
                mCanvas:Plot(x + 1, y - 1, 0, arm).
                mCanvas:Plot(x - 1, y + 1, 0, arm).
                mCanvas:Plot(x + 1, y + 1, 0, arm).
            END.
            mCanvas:Plot(x, y, 0, AsteroidsLook:Colour(Palette:SaucerShotCentre)).
        END.
    END METHOD.

    /* The rocks, large ones first, one cell lines. On the title screen they are dim, and a new rock flashes white. */
    METHOD PRIVATE VOID DrawRocks():
        DEFINE VARIABLE size   AS INTEGER NO-UNDO.
        DEFINE VARIABLE r      AS INTEGER NO-UNDO.
        DEFINE VARIABLE colour AS INTEGER NO-UNDO.
        DO size = 1 TO 3:
            DO r = 0 TO RockField:Capacity() - 1:
                IF mRocks:SizeAt(r) <> size THEN NEXT.
                IF mRocks:Flash(r) > 0 THEN colour = AsteroidsLook:Colour(Palette:Flash).
                ELSE IF Phase = GamePhase:Title THEN colour = AsteroidsLook:SizeColour(TRUE, size).
                ELSE colour = AsteroidsLook:SizeColour(FALSE, size).
                mPen:DrawWrapped(AsteroidsArt:Rock(size, mRocks:Variant(r)), ToPen(mRocks:X(r)), ToPen(mRocks:Y(r)), mRocks:HeadingAt(r),
                                 AsteroidsArt:RockExtent(size), 0, colour, 0, 0).
            END.
        END.
    END METHOD.

    /* A dashed ring round a ship that has just come: it closes in, then breathes, and flickers when the shield is about
       to end. 16 points on a circle, and the even dashes between them. */
    METHOD PRIVATE VOID DrawShieldRing():
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE radius AS INTEGER NO-UNDO.
        DEFINE VARIABLE h      AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x0     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y0     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x1     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y1     AS INTEGER NO-UNDO.
        IF {&SHIELD-FRAMES} - mShieldT <= 30 AND INTEGER(TRUNCATE(mShieldT / 3, 0)) MODULO 2 = 1 THEN RETURN.
        /* the radius in 256ths of a cell: 14 closing to 9 over 12 frames, then 9 plus or minus 1.5 */
        IF mShieldT < 12 THEN radius = 3584 - INTEGER(TRUNCATE((3584 - 2304) * mShieldT / 12, 0)).
        ELSE radius = 2304 + INTEGER(TRUNCATE(384 * Heading:Sin(INTEGER(TRUNCATE(mShieldT * 64 / 30, 0))) / 1024, 0)).
        cx = ToPen(mSX).
        cy = ToPen(mSY).
        DO k = 0 TO 15 BY 2:
            h = k * 4 + INTEGER(TRUNCATE(mShieldT * 8 / 15, 0)).
            x0 = INTEGER(TRUNCATE((cx + INTEGER(TRUNCATE(radius * Heading:DirX(h) / 1024, 0)) + 128) / 256, 0)).
            y0 = INTEGER(TRUNCATE((cy + INTEGER(TRUNCATE(radius * Heading:DirY(h) / 1024, 0)) + 128) / 256, 0)).
            x1 = INTEGER(TRUNCATE((cx + INTEGER(TRUNCATE(radius * Heading:DirX(h + 4) / 1024, 0)) + 128) / 256, 0)).
            y1 = INTEGER(TRUNCATE((cy + INTEGER(TRUNCATE(radius * Heading:DirY(h + 4) / 1024, 0)) + 128) / 256, 0)).
            mCanvas:DrawLine(x0, y0, x1, y1, 0, AsteroidsLook:Colour(Palette:ShieldRing)).
        END.
    END METHOD.

    /* The shots: a 2 by 2 head and a short trail of three cells behind it, dimming; in the last 15 frames the shot
       fades away. Cells, not lines. The trail does not paint over a rock or a ship. */
    METHOD PRIVATE VOID DrawShots():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE hx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE hy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE tx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE ty     AS INTEGER NO-UNDO.
        DEFINE VARIABLE head   AS Palette NO-UNDO.
        DEFINE VARIABLE trail  AS INTEGER NO-UNDO.
        DO i = 1 TO {&SHOTS}:
            IF mShLife[i] <= 0 THEN NEXT.
            hx = INTEGER(TRUNCATE(mShX[i] / {&UNIT}, 0)).
            hy = INTEGER(TRUNCATE(mShY[i] / {&UNIT}, 0)).
            head = (IF mShLife[i] > 15 THEN Palette:ShotHead ELSE Palette:ShotTrail1).
            mCanvas:Plot(hx, hy, 0, AsteroidsLook:Colour(head)).
            mCanvas:Plot(hx + 1, hy, 0, AsteroidsLook:Colour(head)).
            mCanvas:Plot(hx, hy + 1, 0, AsteroidsLook:Colour(head)).
            mCanvas:Plot(hx + 1, hy + 1, 0, AsteroidsLook:Colour(head)).
            IF mShLife[i] <= 5 THEN NEXT.
            DO k = 1 TO 3:
                tx = INTEGER(TRUNCATE(WrapUnits(mShX[i] - INTEGER(TRUNCATE(Heading:DirX(mShHead[i]) * k * 1331 / 1024, 0)), {&WIDTH-U}) / {&UNIT}, 0)).
                ty = INTEGER(TRUNCATE(WrapUnits(mShY[i] - INTEGER(TRUNCATE(Heading:DirY(mShHead[i]) * k * 1331 / 1024, 0)), {&HEIGHT-U}) / {&UNIT}, 0)).
                trail = (IF mShLife[i] > 15 THEN AsteroidsLook:Colour(Palette:GetEnum(INTEGER(Palette:ShotTrail1) + k - 1)) ELSE AsteroidsLook:Colour(Palette:ShotTrail3)).
                IF mCanvas:ColourAt(tx, ty) = mCanvas:BackAt(tx, ty) THEN mCanvas:Plot(tx, ty, 0, trail).
            END.
        END.
    END METHOD.

    /* The ship as it stretches into hyperspace or back out of it, in one of 6 steps: thinner and longer each step, white
       in the middle of the jump and fading to the colours of its wreckage at the end. No glow. */
    METHOD PRIVATE VOID DrawHyperShip(INPUT piStep AS INTEGER):
        DEFINE VARIABLE colour AS INTEGER NO-UNDO.
        CASE piStep:
            WHEN 0 OR WHEN 1 THEN colour = AsteroidsLook:Colour(Palette:ShipCore).
            WHEN 2 OR WHEN 3 THEN colour = AsteroidsLook:Colour(Palette:Flash).
            OTHERWISE colour = AsteroidsLook:RampColour(Ramp:ShipDebris, piStep - 4).
        END CASE.
        mPen:DrawScaled(AsteroidsArt:Ship(), ToPen(mSX), ToPen(mSY), mHeading, INTEGER(ENTRY(piStep + 1, "100,80,60,40,25,10")),
                        INTEGER(ENTRY(piStep + 1, "100,140,190,250,320,400")), 0, colour).
    END METHOD.

    /* The ship's glow: four dim copies one cell to each side. */
    METHOD PRIVATE VOID DrawShipHalo():
        DEFINE VARIABLE px   AS INTEGER NO-UNDO.
        DEFINE VARIABLE py   AS INTEGER NO-UNDO.
        DEFINE VARIABLE halo AS INTEGER NO-UNDO.
        px = ToPen(mSX).
        py = ToPen(mSY).
        halo = AsteroidsLook:Colour(Palette:ShipHalo).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, halo, -1, 0).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, halo, 1, 0).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, halo, 0, -1).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, halo, 0, 1).
    END METHOD.

    /* The ship: the body, the spine and the flame. */
    METHOD PRIVATE VOID DrawShipCore():
        DEFINE VARIABLE px         AS INTEGER NO-UNDO.
        DEFINE VARIABLE py         AS INTEGER NO-UNDO.
        DEFINE VARIABLE flameFrame AS INTEGER NO-UNDO.
        px = ToPen(mSX).
        py = ToPen(mSY).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, AsteroidsLook:Colour(Palette:ShipCore), 0, 0).
        mPen:DrawWrapped(AsteroidsArt:ShipSpine(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, AsteroidsLook:Colour(Palette:ShipSpine), 0, 0).
        IF mThrusting THEN DO:
            /* the flame cycles through frames 0, 1, 2, 1, three ticks to a frame */
            flameFrame = INTEGER(ENTRY((INTEGER(TRUNCATE(mFlameT / 3, 0)) MODULO 4) + 1, "0,1,2,1")).
            mPen:DrawWrapped(AsteroidsArt:FlameOuter(flameFrame), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, AsteroidsLook:Colour(Palette:FlameOuter), 0, 0).
            mPen:DrawWrapped(AsteroidsArt:FlameCore(flameFrame), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, AsteroidsLook:Colour(Palette:FlameCore), 0, 0).
        END.
    END METHOD.

END CLASS.
