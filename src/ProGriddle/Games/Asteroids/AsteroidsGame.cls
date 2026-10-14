/* Asteroids, on a 320 x 240 grid, one cell to a pixel, in direct colour. It is a real time game that runs at 60 frames
   a second whatever the clock does: Tick adds up the time it is given and makes a frame for every sixtieth of a second
   (at the speed chosen), so a test drives it frame by frame with Advance.

   Everything that moves has a position and a velocity in 4096ths of a cell (a "unit"), so the maths is whole numbers
   and the game plays the same every time. Headings are the 64 steps of Heading, and the shapes are outlines turned
   to a heading and drawn as lines (see OutlinePen), so a frame is: put the background back, draw all the lines in
   one batch, then the cells (shots, sparks, text) over them. Collisions are circles, never the drawn lines.

   The ship turns, thrusts and drifts with a little drag, on a screen that wraps on all four edges. The game owns its
   grid. Dispose releases it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    {ProGriddle/Games/Asteroids/Colours.i}
    {ProGriddle/Games/Asteroids/Phases.i}

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
    /* keys, as the input gives them, and whether the fire key was down a frame ago */
    DEFINE PRIVATE VARIABLE mFireWas   AS LOGICAL     NO-UNDO.
    /* the dust that drifts: position and velocity in units, and the colour number */
    DEFINE PRIVATE VARIABLE mDustX     AS INTEGER     NO-UNDO EXTENT {&MOVING-DUST}.
    DEFINE PRIVATE VARIABLE mDustY     AS INTEGER     NO-UNDO EXTENT {&MOVING-DUST}.
    DEFINE PRIVATE VARIABLE mDustV     AS INTEGER     NO-UNDO EXTENT {&MOVING-DUST}.
    DEFINE PRIVATE VARIABLE mDustC     AS INTEGER     NO-UNDO EXTENT {&MOVING-DUST}.

    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    /* How fast the game runs, as a percentage of the real 60 frames a second: 20 to 100. Everything slows together,
       so the game stays the same game and is only easier to play. */
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
        DO i = 0 TO 64:
            mVignette[i + 1] = ColourMath:Mix(AsteroidsLook:Colour({&C-VOID-CENTRE}), AsteroidsLook:Colour({&C-VOID-EDGE}), i, 64).
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

    /* One sixtieth of a second of the game, and the picture of it. */
    METHOD PUBLIC VOID Advance():
        Step().
        Render().
    END METHOD.

    /* Starts a new game: no score, three ships, the first wave. Works from any phase. */
    METHOD PUBLIC VOID StartGame():
        Score = 0.
        Lives = 3.
        Wave = 1.
        mNotice = "".
        Phase = {&PHASE-PLAYING}.
        PlaceShip().
        Render().
    END METHOD.

    /* The ship jumps to a random place and comes back a moment later, with a small chance of blowing up. Does
       nothing outside a game, or when the ship is not flying. */
    METHOD PUBLIC VOID Hyperspace():
        IF Phase <> {&PHASE-PLAYING} THEN RETURN.
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
        mFrames = 0.
        Phase = {&PHASE-TITLE}.
        Score = 0.
        BakeBackground().
        MakeDust().
        PlaceShip().
        Render().
    END METHOD.

    /* ================================ the frame ================================ */

    METHOD PRIVATE VOID Step():
        mFrames = mFrames + 1.
        MoveDust().
        CASE Phase:
            WHEN {&PHASE-TITLE} THEN FrameTitle().
            WHEN {&PHASE-PLAYING} THEN FramePlaying().
            WHEN {&PHASE-GAMEOVER} THEN FrameGameOver().
        END CASE.
        mFireWas = FireHeld.
    END METHOD.

    METHOD PRIVATE VOID FrameTitle():
        IF FireHeld AND NOT mFireWas THEN StartGame().
    END METHOD.

    METHOD PRIVATE VOID FramePlaying():
        MoveShip().
    END METHOD.

    METHOD PRIVATE VOID FrameGameOver():
        IF FireHeld AND NOT mFireWas THEN Initialise().
    END METHOD.

    /* ================================ the ship ================================ */

    /* The ship in the middle of the screen, still, nose up. */
    METHOD PRIVATE VOID PlaceShip():
        mSX = {&WIDTH-U} / 2.
        mSY = {&HEIGHT-U} / 2.
        mSVX = 0.
        mSVY = 0.
        mHeading = 0.
        mTurnAcc = 0.
        mFlameT = 0.
        mThrusting = FALSE.
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
        DEFINE VARIABLE c     AS INTEGER NO-UNDO.
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
            c = (IF n <= 40 THEN {&C-DUST-DIM} ELSE IF n <= 60 THEN {&C-DUST-MID} ELSE {&C-DUST-BRIGHT}).
            DO tries = 1 TO 50:
                idx = mRandom:NextInt({&WIDTH} * {&HEIGHT}).
                IF LOOKUP(STRING(cells:GetCellAt(backLayer, idx)), DustColours()) = 0 THEN LEAVE.
            END.
            cells:SetCellAt(backLayer, idx, AsteroidsLook:Colour(c)).
        END.
    END METHOD.

    /* The colours of dust, as numbers in a comma list, to tell a dust cell from the vignette. */
    METHOD PRIVATE STATIC CHARACTER DustColours():
        RETURN SUBSTITUTE("&1,&2,&3", AsteroidsLook:Colour({&C-DUST-DIM}), AsteroidsLook:Colour({&C-DUST-MID}), AsteroidsLook:Colour({&C-DUST-BRIGHT})).
    END METHOD.

    /* 20 cells of dust that drift left and a little down, in three speeds. */
    METHOD PRIVATE VOID MakeDust():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&MOVING-DUST}:
            mDustX[i] = mRandom:NextInt({&WIDTH-U}).
            mDustY[i] = mRandom:NextInt({&HEIGHT-U}).
            CASE i MODULO 3:
                WHEN 0 THEN ASSIGN mDustV[i] = 164 mDustC[i] = {&C-DUST-DIM}.
                WHEN 1 THEN ASSIGN mDustV[i] = 328 mDustC[i] = {&C-DUST-MID}.
                OTHERWISE ASSIGN mDustV[i] = 573 mDustC[i] = {&C-DUST-BRIGHT}.
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
        IF Phase = {&PHASE-PLAYING} THEN DrawShip().
        mCanvas:EndBatch().
    END METHOD.

    /* The ship: a glow of four dim copies one cell to each side, then the body, the spine and the flame. */
    METHOD PRIVATE VOID DrawShip():
        DEFINE VARIABLE px    AS INTEGER NO-UNDO.
        DEFINE VARIABLE py    AS INTEGER NO-UNDO.
        DEFINE VARIABLE halo  AS INTEGER NO-UNDO.
        DEFINE VARIABLE flameFrame AS INTEGER NO-UNDO.
        px = ToPen(mSX).
        py = ToPen(mSY).
        halo = AsteroidsLook:Colour({&C-SHIP-HALO}).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, halo, -1, 0).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, halo, 1, 0).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, halo, 0, -1).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, halo, 0, 1).
        mPen:DrawWrapped(AsteroidsArt:Ship(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, AsteroidsLook:Colour({&C-SHIP-CORE}), 0, 0).
        mPen:DrawWrapped(AsteroidsArt:ShipSpine(), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, AsteroidsLook:Colour({&C-SHIP-SPINE}), 0, 0).
        IF mThrusting THEN DO:
            /* the flame cycles through frames 0, 1, 2, 1, three ticks to a frame */
            flameFrame = INTEGER(ENTRY((INTEGER(TRUNCATE(mFlameT / 3, 0)) MODULO 4) + 1, "0,1,2,1")).
            mPen:DrawWrapped(AsteroidsArt:FlameOuter(flameFrame), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, AsteroidsLook:Colour({&C-FLAME-OUTER}), 0, 0).
            mPen:DrawWrapped(AsteroidsArt:FlameCore(flameFrame), px, py, mHeading, AsteroidsArt:ShipExtent(), 0, AsteroidsLook:Colour({&C-FLAME-CORE}), 0, 0).
        END.
    END METHOD.

END CLASS.
