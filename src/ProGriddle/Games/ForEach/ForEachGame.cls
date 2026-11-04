/* FOR EACH: Dibby, a database drum, visits every bit of data in a maze while four phantoms hunt him. It is a real time game that
   runs at 60 frames a second whatever the clock does: Tick adds up the time it is given and makes a frame for every sixtieth of a
   second (at the speed chosen), so a test drives it frame by frame with Advance. The rules are in ForEachRules, the maze in
   MazeMap and the phantoms' choices in PhantomTargeting and PhantomSteering. The game has no picture yet: it owns a grid for one.

   Everything that moves has a position in pixels of the maze (8 to a tile, the origin at the top left of the maze) and a speed
   as a percentage of full speed, which is 1.25 pixels a frame. A speed is added up in 256ths of a pixel, and the character moves
   a whole pixel for each 256, so the game plays the same every time. Characters walk the lanes. At the middle of a tile (4 pixels
   in from its left and top edge) Dibby may turn, and a phantom chooses its way; a character that cannot go on stops. A column
   off one edge of the maze is the one on the other side, which is the tunnel.

   Dibby eats the bit or commit token on every tile he enters, with a pause of a frame for a bit and three for a commit token. A
   commit token rolls the phantoms back for a time, turning them round: they are slow and random, and Dibby may eat them for 200,
   400, 800 and 1600 points (then they run home as Returning and come out again). The phantoms leave the lobby by counts of
   what Dibby has eaten, and the waves of scatter and chase run on a timer that stands still while they are rolled back. The
   same tile, or nearly, as a phantom that is not rolled back ends the turn. Two bonus items come out per level, at 70 and 170
   things eaten. Three lives, and another at 10000 points.

   A turn is made at the tile middle, a reversal at once. Phases: Title, Ready (240 frames at the start of a level, 60 after a
   life), Playing, Caught (60 frames), Dying (100), Cleared (168, the maze flashing), Intermission (300, after some levels) and
   GameOver. The tests have a few hooks: PlaceDibby, PlacePhantom, EatBits, Rollback, SwitchWave, ShowItem and SetRage do
   what the game does itself, at once. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    /* a tile is 8 pixels; a percentage of full speed is a speed of 16 / 5 of a 256th of a pixel a frame (100 percent is 320) */
    &SCOPED-DEFINE TILE 8
    &SCOPED-DEFINE UNIT 256
    /* characters this close, in pixels across and down, have touched */
    &SCOPED-DEFINE TOUCH 6
    /* how long things take, in frames */
    &SCOPED-DEFINE READY-FRAMES 240
    &SCOPED-DEFINE RETRY-FRAMES 60
    &SCOPED-DEFINE CAUGHT-FRAMES 60
    &SCOPED-DEFINE DYING-FRAMES 100
    &SCOPED-DEFINE CLEARED-FRAMES 168
    &SCOPED-DEFINE ACT-FRAMES 300
    &SCOPED-DEFINE EATEN-FRAMES 60
    /* the most frames one Tick will make, and the most time it will count: a stall must not make a burst */
    &SCOPED-DEFINE MOST-FRAMES 4
    &SCOPED-DEFINE MOST-MS 100
    /* a returning phantom runs at 150 percent; a phantom leaving the lobby at 50. The door is 92 pixels down, the lobby row 116 */
    &SCOPED-DEFINE RETURNING-SPEED 150
    &SCOPED-DEFINE LEAVING-SPEED 50
    &SCOPED-DEFINE DOOR-X 112
    &SCOPED-DEFINE OUTSIDE-Y 92
    &SCOPED-DEFINE INSIDE-Y 116

    DEFINE PRIVATE VARIABLE mMaze      AS MazeMap NO-UNDO.
    DEFINE PRIVATE VARIABLE mRandom    AS IRandom NO-UNDO.
    DEFINE PRIVATE VARIABLE mWidth     AS INTEGER NO-UNDO.

    /* Dibby */
    DEFINE PRIVATE VARIABLE mDx        AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mDy        AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mDir       AS MazeDir NO-UNDO.
    DEFINE PRIVATE VARIABLE mDAcc      AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mMoving    AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mEatPause  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLastCol   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLastRow   AS INTEGER NO-UNDO.
    /* true while Dibby is cutting a corner, and the pixel (across for a lane that runs across, else down) of the tile middle he is cutting it at */
    DEFINE PRIVATE VARIABLE mCornering AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mCorner    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mCornerDir AS MazeDir NO-UNDO.

    /* the phantoms, by INTEGER(PhantomKind) */
    DEFINE PRIVATE VARIABLE mPresent   AS LOGICAL     NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mPx        AS INTEGER     NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mPy        AS INTEGER     NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mPDir      AS MazeDir     NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mPMode     AS PhantomMode NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mPAcc      AS INTEGER     NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mPersonal  AS INTEGER     NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mDescend   AS LOGICAL     NO-UNDO EXTENT 4.

    /* the level */
    DEFINE PRIVATE VARIABLE mPhaseFrames AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mChain       AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mWaveForever AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mItem1       AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mItem2       AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mIdle        AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mGlobalOn    AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mGlobalCount AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mRageForce   AS INTEGER NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mRageHeld    AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mExtraGiven  AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mAcc         AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mHiAtStart   AS INTEGER NO-UNDO.
    /* the last tiles eaten, round and round */
    DEFINE PRIVATE VARIABLE mEatenCol    AS INTEGER NO-UNDO EXTENT 256.
    DEFINE PRIVATE VARIABLE mEatenRow    AS INTEGER NO-UNDO EXTENT 256.

    /* The frames the game has been in this phase: what the picture's timed effects (the title, the crash, the flash) are worked from. */
    DEFINE PUBLIC PROPERTY PhaseAge AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PRIVATE VARIABLE mPhase AS ForEachPhase NO-UNDO.

    /* The phase the game is in. Every change of phase starts PhaseAge again. */
    DEFINE PUBLIC PROPERTY Phase AS ForEachPhase NO-UNDO
        GET():
            RETURN mPhase.
        END GET.
        PRIVATE SET(INPUT poPhase AS ForEachPhase):
            mPhase = poPhase.
            PhaseAge = 0.
        END SET.

    /* The number of times the maze has been filled (a game or a level starting) and of bits and commit tokens eaten (a count that
       goes on over levels): with EatenColAt and EatenRowAt, which tiles were eaten last, so the picture can take each one off. */
    DEFINE PUBLIC PROPERTY LevelSerial AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY EatenSerial AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The pop-up of the points just earned: where (in pixels of the maze), how many, whether it is an item's, and the frames it has left. */
    DEFINE PUBLIC PROPERTY PopupFramesLeft AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PopupX AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PopupY AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PopupPoints AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PopupIsItem AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Maze AS MazeMap NO-UNDO
        GET():
            RETURN mMaze.
        END GET.

    DEFINE PUBLIC PROPERTY Score AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY HiScore AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Lives AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Level AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many frames the READY! of this turn lasts: 240 at the start of a level (the maze builds in the first 120) and 60 after a life. */
    DEFINE PUBLIC PROPERTY ReadyLength AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* True once the score has beaten the best score the game started with. */
    DEFINE PUBLIC PROPERTY NewHiScore AS LOGICAL NO-UNDO
        GET():
            RETURN Score > mHiAtStart AND Score > 0.
        END GET.

    /* While true the game ignores the clock. */
    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    /* The game's speed as a percentage of its normal one: 100 makes a frame for every sixtieth of a second. */
    DEFINE PUBLIC PROPERTY SpeedPercent AS INTEGER NO-UNDO INITIAL 100
        GET.
        SET.

    DEFINE PUBLIC PROPERTY FrameCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The bits and commit tokens left, and the number eaten on this level. */
    DEFINE PUBLIC PROPERTY BitsLeft AS INTEGER NO-UNDO
        GET():
            RETURN mMaze:BitsLeft.
        END GET.

    DEFINE PUBLIC PROPERTY BitsEaten AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Dibby: where he is (the middle of him, in pixels), the tile he is in, the way he faces, whether he is walking, and the way
       the player last asked for. */
    DEFINE PUBLIC PROPERTY DibbyX AS INTEGER NO-UNDO
        GET():
            RETURN mDx.
        END GET.

    DEFINE PUBLIC PROPERTY DibbyY AS INTEGER NO-UNDO
        GET():
            RETURN mDy.
        END GET.

    DEFINE PUBLIC PROPERTY DibbyCol AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(mDx / {&TILE}, 0)).
        END GET.

    DEFINE PUBLIC PROPERTY DibbyRow AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(mDy / {&TILE}, 0)).
        END GET.

    DEFINE PUBLIC PROPERTY DibbyDir AS MazeDir NO-UNDO
        GET():
            RETURN mDir.
        END GET.

    DEFINE PUBLIC PROPERTY DibbyMoving AS LOGICAL NO-UNDO
        GET():
            RETURN mMoving.
        END GET.

    DEFINE PUBLIC PROPERTY WantedDir AS MazeDir NO-UNDO
        GET.
        PRIVATE SET.

    /* The wave (1 to 8, odd ones scatter and even ones chase) and the frames it has left (0 for the last wave, which never ends),
       the frames the phantoms have left rolled back, and the frames the game stands still after a phantom is eaten. */
    DEFINE PUBLIC PROPERTY WaveNumber AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY WaveFramesLeft AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY RollbackFramesLeft AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY FreezeFramesLeft AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The bonus item: whether it is out, which one, where (the maze says) and how long it has left. */
    DEFINE PUBLIC PROPERTY ItemActive AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ItemOnShow AS ItemKind NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ItemFramesLeft AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ItemX AS INTEGER NO-UNDO
        GET():
            RETURN mMaze:ItemX.
        END GET.

    DEFINE PUBLIC PROPERTY ItemY AS INTEGER NO-UNDO
        GET():
            RETURN mMaze:ItemY.
        END GET.

    /* How wound up Mary is: 0, 1 or 2. */
    DEFINE PUBLIC PROPERTY RageStage AS INTEGER NO-UNDO
        GET():
            IF mRageForce >= 0 THEN RETURN mRageForce.
            IF mRageHeld OR mMaze:BitsLeft = 0 THEN RETURN 0.
            IF mMaze:BitsLeft <= ForEachRules:RageBits(Level, 2) THEN RETURN 2.
            IF mMaze:BitsLeft <= ForEachRules:RageBits(Level, 1) THEN RETURN 1.
            RETURN 0.
        END GET.

    /* The cartoon playing (1 to 3) while the phase is Intermission, otherwise 0. */
    DEFINE PUBLIC PROPERTY IntermissionAct AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* True while the target of each phantom is to be shown (for the picture). */
    DEFINE PUBLIC PROPERTY ShowTargets AS LOGICAL NO-UNDO
        GET.
        SET.

    /* Counts the picture and the sounds read: they only go up during a game and start again with a new one. */
    DEFINE PUBLIC PROPERTY BitsEatenTotal AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY CommitsEatenTotal AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PhantomsEatenTotal AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ItemsEatenTotal AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many times a bonus item has come out in this game (so the sound can tell the player it has). */
    DEFINE PUBLIC PROPERTY ItemsShownTotal AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY DeathCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The points of the last phantom eaten, for its pop-up. */
    DEFINE PUBLIC PROPERTY LastPhantomPoints AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Throws GridException for no grid, no maze or no random source, or a grid that is not the size of the maze: 8 pixels a tile
       and 40 rows of pixels for the strips above and below it. */
    CONSTRUCTOR PUBLIC ForEachGame(INPUT poGrid AS Grid, INPUT poMaze AS MazeMap, INPUT poRandom AS IRandom):
        SUPER("FOR EACH", poGrid).
        IF NOT VALID-OBJECT(poMaze) THEN UNDO, THROW NEW GridException("FOR EACH needs a maze").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("FOR EACH needs a random source").
        IF poGrid:Width <> poMaze:Cols * {&TILE} OR poGrid:Height <> poMaze:Rows * {&TILE} + 40 THEN
            UNDO, THROW NEW GridException("The grid of FOR EACH is the maze at 8 pixels a tile with 40 rows of pixels more").
        mMaze = poMaze.
        mRandom = poRandom.
        mWidth = poMaze:Cols * {&TILE}.
        Phase = ForEachPhase:Title.
        Lives = ForEachRules:StartLives().
        Level = 1.
        PrepareLevel(1).
    END CONSTRUCTOR.

    /* ---------------------------------- starting ---------------------------------- */

    /* Starts a new game: no score, three lives, the first level with READY! on the screen. Works from any phase. The best score
       stays. */
    METHOD PUBLIC VOID StartGame():
        Score = 0.
        Lives = ForEachRules:StartLives().
        mExtraGiven = FALSE.
        mHiAtStart = HiScore.
        ASSIGN BitsEatenTotal = 0
               CommitsEatenTotal = 0
               PhantomsEatenTotal = 0
               ItemsEatenTotal = 0
               ItemsShownTotal = 0
               DeathCount = 0
               LastPhantomPoints = 0.
        IsOver = FALSE.
        BeginLevel(1).
    END METHOD.

    /* Starts a level with READY! on the screen, keeping the score and the lives. Throws GridException for a level below 1. */
    METHOD PUBLIC VOID StartLevel(INPUT piLevel AS INTEGER):
        IF piLevel = ? OR piLevel < 1 THEN UNDO, THROW NEW GridException("A level is 1 or more").
        IsOver = FALSE.
        BeginLevel(piLevel).
    END METHOD.

    METHOD PRIVATE VOID BeginLevel(INPUT piLevel AS INTEGER):
        PrepareLevel(piLevel).
        Phase = ForEachPhase:Ready.
        mPhaseFrames = {&READY-FRAMES}.
        ReadyLength = {&READY-FRAMES}.
    END METHOD.

    /* The maze full again, the counts of a level at nothing and everyone at their start. */
    METHOD PRIVATE VOID PrepareLevel(INPUT piLevel AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Level = piLevel.
        mMaze:Refill().
        LevelSerial = LevelSerial + 1.
        ASSIGN BitsEaten = 0
               mItem1 = FALSE
               mItem2 = FALSE
               mGlobalOn = FALSE
               mRageHeld = FALSE
               IntermissionAct = 0.
        DO i = 1 TO 4:
            mPersonal[i] = 0.
        END.
        PlaceStarts().
    END METHOD.

    /* Everyone back at their start, the waves beginning again and no item out. */
    METHOD PRIVATE VOID PlaceStarts():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ASSIGN mDx = mMaze:DibbyStartX
               mDy = mMaze:DibbyStartY
               mDir = MazeDir:Left
               mDAcc = 0
               mMoving = TRUE
               mCornering = FALSE
               mEatPause = 0
               mLastCol = DibbyCol
               mLastRow = DibbyRow
               mChain = 0
               mIdle = 0
               FreezeFramesLeft = 0
               RollbackFramesLeft = 0
               ItemActive = FALSE
               mRageForce = -1.
        DO i = 1 TO 4:
            mPAcc[i] = 0.
            mDescend[i] = FALSE.
            mPresent[i] = mMaze:HasPhantomStart(PhantomKind:GetEnum(i)).
            IF mPresent[i] THEN
                ASSIGN mPx[i] = mMaze:PhantomStartX(PhantomKind:GetEnum(i))
                       mPy[i] = mMaze:PhantomStartY(PhantomKind:GetEnum(i)).
            CASE PhantomKind:GetEnum(i):
                WHEN PhantomKind:Mary THEN ASSIGN mPDir[i] = MazeDir:Left
                                                  mPMode[i] = PhantomMode:Scatter.
                WHEN PhantomKind:Rich THEN ASSIGN mPDir[i] = MazeDir:Down
                                                  mPMode[i] = PhantomMode:Waiting.
                OTHERWISE ASSIGN mPDir[i] = MazeDir:Up
                                 mPMode[i] = PhantomMode:Waiting.
            END CASE.
        END.
        StartWaves().
    END METHOD.

    METHOD PRIVATE VOID StartWaves():
        WaveNumber = 1.
        SetWaveTimer().
    END METHOD.

    /* The timer of the wave that WaveNumber says. The last wave has none. */
    METHOD PRIVATE VOID SetWaveTimer():
        mWaveForever = WaveNumber >= 8.
        WaveFramesLeft = (IF mWaveForever THEN 0 ELSE ForEachRules:WaveFrames(Level, WaveNumber)).
    END METHOD.

    /* ---------------------------------- the clock ---------------------------------- */

    /* Moves time on by piElapsedMs milliseconds, making a frame for every sixtieth of a second at the speed chosen. Returns true
       when a frame was made. Does nothing, and returns false, while Paused. */
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
        FrameCount = FrameCount + 1.
        PhaseAge = PhaseAge + 1.
        IF PopupFramesLeft > 0 THEN PopupFramesLeft = PopupFramesLeft - 1.
        CASE Phase:
            WHEN ForEachPhase:Ready THEN DO:
                mPhaseFrames = mPhaseFrames - 1.
                IF mPhaseFrames <= 0 THEN DO:
                    Phase = ForEachPhase:Playing.
                    ReleaseCheck().
                END.
            END.
            WHEN ForEachPhase:Playing THEN PlayFrame().
            WHEN ForEachPhase:Caught THEN DO:
                mPhaseFrames = mPhaseFrames - 1.
                IF mPhaseFrames <= 0 THEN DO:
                    Phase = ForEachPhase:Dying.
                    mPhaseFrames = {&DYING-FRAMES}.
                    DeathCount = DeathCount + 1.
                END.
            END.
            WHEN ForEachPhase:Dying THEN DO:
                mPhaseFrames = mPhaseFrames - 1.
                IF mPhaseFrames <= 0 THEN AfterDeath().
            END.
            WHEN ForEachPhase:Cleared THEN DO:
                mPhaseFrames = mPhaseFrames - 1.
                IF mPhaseFrames <= 0 THEN AfterClear().
            END.
            WHEN ForEachPhase:Intermission THEN DO:
                mPhaseFrames = mPhaseFrames - 1.
                IF mPhaseFrames <= 0 THEN BeginLevel(Level + 1).
            END.
        END CASE.
    END METHOD.

    /* A life is gone: the game ends, or the turn starts again with everyone at their start. The phantoms now leave the lobby on one
       count shared between them, and Mary does not wind up until Chip is out. */
    METHOD PRIVATE VOID AfterDeath():
        Lives = MAXIMUM(0, Lives - 1).
        IF Lives = 0 THEN DO:
            Phase = ForEachPhase:GameOver.
            IsOver = TRUE.
            RETURN.
        END.
        PlaceStarts().
        ASSIGN mGlobalOn = TRUE
               mGlobalCount = 0
               mRageHeld = TRUE.
        Phase = ForEachPhase:Ready.
        mPhaseFrames = {&RETRY-FRAMES}.
        ReadyLength = {&RETRY-FRAMES}.
    END METHOD.

    /* Plays a cartoon (1 to 3) now, as if a level had been cleared that has one, and goes on to the next level when it is over. Throws
       GridException for any other number. */
    METHOD PUBLIC VOID StartIntermission(INPUT piAct AS INTEGER):
        IF piAct = ? OR piAct < 1 OR piAct > 3 THEN UNDO, THROW NEW GridException("There are cartoons 1 to 3").
        IntermissionAct = piAct.
        Phase = ForEachPhase:Intermission.
        mPhaseFrames = {&ACT-FRAMES}.
    END METHOD.

    /* The maze has flashed: a cartoon, or the next level. */
    METHOD PRIVATE VOID AfterClear():
        DEFINE VARIABLE act AS INTEGER NO-UNDO.
        act = ForEachRules:IntermissionAfter(Level).
        IF act = 0 THEN DO:
            BeginLevel(Level + 1).
            RETURN.
        END.
        IntermissionAct = act.
        Phase = ForEachPhase:Intermission.
        mPhaseFrames = {&ACT-FRAMES}.
    END METHOD.

    /* ---------------------------------- a frame of play ---------------------------------- */

    METHOD PRIVATE VOID PlayFrame():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF FreezeFramesLeft > 0 THEN DO:
            FreezeFramesLeft = FreezeFramesLeft - 1.
            RETURN.
        END.
        /* the clocks: the waves stand still while the phantoms are rolled back */
        IF RollbackFramesLeft > 0 THEN DO:
            RollbackFramesLeft = RollbackFramesLeft - 1.
            IF RollbackFramesLeft = 0 THEN EndRollback().
        END.
        ELSE IF NOT mWaveForever THEN DO:
            WaveFramesLeft = WaveFramesLeft - 1.
            IF WaveFramesLeft <= 0 THEN SwitchWave().
        END.
        IF ItemActive THEN DO:
            ItemFramesLeft = ItemFramesLeft - 1.
            IF ItemFramesLeft <= 0 THEN ItemActive = FALSE.
        END.
        mIdle = mIdle + 1.
        IF mIdle >= ForEachRules:LobbyIdleFrames(Level) THEN DO:
            ReleaseNext().
            mIdle = 0.
        END.
        MoveDibby().
        IF Phase <> ForEachPhase:Playing THEN RETURN.
        DO i = 1 TO 4:
            MovePhantom(i).
        END.
        ReleaseCheck().
        Collide().
    END METHOD.

    /* ---------------------------------- Dibby ---------------------------------- */

    /* The way the player wants Dibby to go. He turns at the next tile middle where the way is open, and a turn back is at once.
       Throws GridException for no direction. */
    METHOD PUBLIC VOID Steer(INPUT poDir AS MazeDir):
        IF poDir = ? THEN UNDO, THROW NEW GridException("Dibby cannot be steered nowhere").
        WantedDir = poDir.
        /* a turn back is at once, except in the few pixels of cutting a corner, which are finished first */
        IF Phase = ForEachPhase:Playing AND mDir <> ? AND NOT mCornering AND poDir = MazeDirs:Opposite(mDir) THEN
            ASSIGN mDir = poDir
                   mMoving = TRUE.
    END METHOD.

    /* True when a tile can be entered by Dibby, or by a phantom. A tile off the top or bottom of the maze cannot. */
    METHOD PRIVATE LOGICAL OpenTile(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT plPhantom AS LOGICAL):
        IF piRow < 0 OR piRow >= mMaze:Rows THEN RETURN FALSE.
        RETURN mMaze:CanEnter(piCol, piRow, plPhantom).
    END METHOD.

    /* True when a character at (piX, piY) is at the middle of a tile. */
    METHOD PRIVATE LOGICAL AtMiddle(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN piX MODULO {&TILE} = 4 AND piY MODULO {&TILE} = 4.
    END METHOD.

    /* The tile column of a pixel across, wrapping round the maze. */
    METHOD PRIVATE INTEGER ColOf(INPUT piX AS INTEGER):
        RETURN INTEGER(TRUNCATE(((piX MODULO mWidth) + mWidth) MODULO mWidth / {&TILE}, 0)).
    END METHOD.

    METHOD PRIVATE INTEGER RowOf(INPUT piY AS INTEGER):
        RETURN INTEGER(TRUNCATE(piY / {&TILE}, 0)).
    END METHOD.

    /* The pixel across after a step, wrapping round the maze. */
    METHOD PRIVATE INTEGER Wrapped(INPUT piX AS INTEGER):
        RETURN ((piX MODULO mWidth) + mWidth) MODULO mWidth.
    END METHOD.

    METHOD PRIVATE VOID MoveDibby():
        DEFINE VARIABLE steps AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        IF mEatPause > 0 THEN DO:
            mEatPause = mEatPause - 1.
            RETURN.
        END.
        mDAcc = mDAcc + INTEGER((IF RollbackFramesLeft > 0 THEN ForEachRules:DibbyRollbackSpeed(Level) ELSE ForEachRules:DibbySpeed(Level)) * 16 / 5).
        steps = INTEGER(TRUNCATE(mDAcc / {&UNIT}, 0)).
        mDAcc = mDAcc MODULO {&UNIT}.
        DO i = 1 TO steps:
            IF NOT StepDibby() THEN DO:
                mDAcc = 0.
                RETURN.
            END.
            IF mEatPause > 0 OR Phase <> ForEachPhase:Playing THEN RETURN.
        END.
    END METHOD.

    /* One pixel. Returns false when Dibby cannot go on. */
    METHOD PRIVATE LOGICAL StepDibby():
        DEFINE VARIABLE nx AS INTEGER NO-UNDO.
        DEFINE VARIABLE ny AS INTEGER NO-UNDO.
        DEFINE VARIABLE tc AS INTEGER NO-UNDO.
        DEFINE VARIABLE rw AS INTEGER NO-UNDO.
        IF AtMiddle(mDx, mDy) THEN DO:
            mCornering = FALSE.
            tc = DibbyCol.
            rw = DibbyRow.
            IF WantedDir <> ? AND WantedDir <> mDir AND OpenTile(tc + MazeDirs:Dx(WantedDir), rw + MazeDirs:Dy(WantedDir), FALSE) THEN mDir = WantedDir.
            IF NOT OpenTile(tc + MazeDirs:Dx(mDir), rw + MazeDirs:Dy(mDir), FALSE) THEN DO:
                mMoving = FALSE.
                RETURN FALSE.
            END.
        END.
        ELSE IF CutCorner() THEN DO:
            AfterStep().
            RETURN TRUE.
        END.
        ELSE DO:
            /* between middles: do not walk into a tile that cannot be entered */
            nx = Wrapped(mDx + MazeDirs:Dx(mDir)).
            ny = mDy + MazeDirs:Dy(mDir).
            IF (ColOf(nx) <> DibbyCol OR RowOf(ny) <> DibbyRow) AND NOT OpenTile(ColOf(nx), RowOf(ny), FALSE) THEN DO:
                mMoving = FALSE.
                RETURN FALSE.
            END.
        END.
        ASSIGN mDx = Wrapped(mDx + MazeDirs:Dx(mDir))
               mDy = mDy + MazeDirs:Dy(mDir).
        /* a pixel a step back to the middle of the lane if he is off it (a corner cut leaves him on it, a placed Dibby may not be) */
        IF (mDir = MazeDir:Left OR mDir = MazeDir:Right) AND mDy MODULO {&TILE} <> 4 THEN mDy = mDy + (IF mDy MODULO {&TILE} < 4 THEN 1 ELSE -1).
        IF (mDir = MazeDir:Up OR mDir = MazeDir:Down) AND mDx MODULO {&TILE} <> 4 THEN mDx = Wrapped(mDx + (IF mDx MODULO {&TILE} < 4 THEN 1 ELSE -1)).
        mMoving = TRUE.
        AfterStep().
        RETURN TRUE.
    END METHOD.

    /* What a step of Dibby's does once he has made it: eat what is on a tile he has just entered. */
    METHOD PRIVATE VOID AfterStep():
        IF DibbyCol <> mLastCol OR DibbyRow <> mLastRow THEN DO:
            ASSIGN mLastCol = DibbyCol
                   mLastRow = DibbyRow.
            EatAt(mLastCol, mLastRow).
        END.
    END METHOD.

    /* Cutting a corner: when the way he was asked to go is across the lane he is walking and opens at the middle of a tile that is no more
       than 4 pixels ahead, Dibby does not walk on to the middle first. Each pixel he goes both on along the lane and into the turn, so
       he comes into the new lane as he reaches the middle, up to 4 pixels sooner than if he had waited for it. This is what lets him get
       away from a phantom at a corner. Returns true when this step was a step of cutting a corner (it has been made), false when it was not. */
    METHOD PRIVATE LOGICAL CutCorner():
        DEFINE VARIABLE want   AS MazeDir NO-UNDO.
        DEFINE VARIABLE across AS LOGICAL NO-UNDO.
        DEFINE VARIABLE pos    AS INTEGER NO-UNDO.
        DEFINE VARIABLE centre AS INTEGER NO-UNDO.
        DEFINE VARIABLE gap    AS INTEGER NO-UNDO.
        DEFINE VARIABLE tc     AS INTEGER NO-UNDO.
        DEFINE VARIABLE rw     AS INTEGER NO-UNDO.
        /* a corner that has been started is finished the way it was started, whatever is asked for meanwhile */
        want = (IF mCornering THEN mCornerDir ELSE WantedDir).
        IF want = ? OR want = mDir OR want = MazeDirs:Opposite(mDir) THEN RETURN FALSE.
        across = mDir = MazeDir:Left OR mDir = MazeDir:Right.
        IF NOT mCornering THEN DO:
            /* the lane must be the one he is centred in, and the middle ahead must be 1 to 4 pixels away */
            IF across AND mDy MODULO {&TILE} <> 4 THEN RETURN FALSE.
            IF NOT across AND mDx MODULO {&TILE} <> 4 THEN RETURN FALSE.
            pos = (IF across THEN mDx ELSE mDy).
            IF mDir = MazeDir:Right OR mDir = MazeDir:Down THEN
                centre = pos - (pos MODULO {&TILE}) + (IF pos MODULO {&TILE} <= 4 THEN 4 ELSE 12).
            ELSE
                centre = pos - (pos MODULO {&TILE}) + (IF pos MODULO {&TILE} >= 4 THEN 4 ELSE -4).
            gap = ABSOLUTE(centre - pos).
            IF gap < 1 OR gap > 4 THEN RETURN FALSE.
            IF centre < 0 OR centre >= (IF across THEN mWidth ELSE mMaze:Rows * {&TILE}) THEN RETURN FALSE.
            /* the tile whose middle it is, and the tile the turn goes into, must be open */
            IF across THEN ASSIGN tc = INTEGER(TRUNCATE(centre / {&TILE}, 0))
                                  rw = DibbyRow.
            ELSE ASSIGN tc = DibbyCol
                        rw = INTEGER(TRUNCATE(centre / {&TILE}, 0)).
            IF NOT OpenTile(tc, rw, FALSE) OR NOT OpenTile(tc + MazeDirs:Dx(want), rw + MazeDirs:Dy(want), FALSE) THEN RETURN FALSE.
            ASSIGN mCornering = TRUE
                   mCorner = centre
                   mCornerDir = want.
        END.
        /* a pixel along the lane and a pixel into the turn */
        ASSIGN mDx = Wrapped(mDx + MazeDirs:Dx(mDir) + MazeDirs:Dx(want))
               mDy = mDy + MazeDirs:Dy(mDir) + MazeDirs:Dy(want)
               mMoving = TRUE.
        IF (IF across THEN mDx ELSE mDy) = mCorner THEN ASSIGN mDir = want
                                                               mCornering = FALSE.
        RETURN TRUE.
    END METHOD.

    /* Eats what is on the tile Dibby has just entered. The last bit clears the level. */
    METHOD PRIVATE VOID EatAt(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        DEFINE VARIABLE kind AS TileKind NO-UNDO.
        kind = mMaze:Take(piCol, piRow).
        IF kind <> TileKind:Bit AND kind <> TileKind:Commit THEN RETURN.
        Noted(piCol, piRow).
        WasEaten(kind).
        mEatPause = ForEachRules:EatPauseFrames(kind).
        IF mMaze:BitsLeft = 0 THEN DO:
            Phase = ForEachPhase:Cleared.
            mPhaseFrames = {&CLEARED-FRAMES}.
            ItemActive = FALSE.
        END.
    END METHOD.

    /* Notes that a tile has been eaten, for the picture. */
    METHOD PRIVATE VOID Noted(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        EatenSerial = EatenSerial + 1.
        mEatenCol[(EatenSerial - 1) MODULO 256 + 1] = piCol.
        mEatenRow[(EatenSerial - 1) MODULO 256 + 1] = piRow.
    END METHOD.

    /* The column and row of the tile eaten when EatenSerial was piSerial: the last 256 are kept. Throws GridException for any other. */
    METHOD PUBLIC INTEGER EatenColAt(INPUT piSerial AS INTEGER):
        IF piSerial < 1 OR piSerial > EatenSerial OR piSerial <= EatenSerial - 256 THEN UNDO, THROW NEW GridException("That tile is no longer remembered").
        RETURN mEatenCol[(piSerial - 1) MODULO 256 + 1].
    END METHOD.

    METHOD PUBLIC INTEGER EatenRowAt(INPUT piSerial AS INTEGER):
        IF piSerial < 1 OR piSerial > EatenSerial OR piSerial <= EatenSerial - 256 THEN UNDO, THROW NEW GridException("That tile is no longer remembered").
        RETURN mEatenRow[(piSerial - 1) MODULO 256 + 1].
    END METHOD.

    /* What eating a bit or a commit token does: the points, the counts, a commit token's rollback and the bonus items that come
       out at 70 and 170 things eaten. */
    METHOD PRIVATE VOID WasEaten(INPUT poKind AS TileKind):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF poKind = TileKind:Commit THEN DO:
            AddScore(ForEachRules:CommitPoints()).
            CommitsEatenTotal = CommitsEatenTotal + 1.
            Rollback().
        END.
        ELSE DO:
            AddScore(ForEachRules:BitPoints()).
            BitsEatenTotal = BitsEatenTotal + 1.
        END.
        BitsEaten = BitsEaten + 1.
        IF BitsEaten >= ForEachRules:ItemBitCount(1) AND NOT mItem1 THEN DO:
            mItem1 = TRUE.
            ShowItem().
        END.
        IF BitsEaten >= ForEachRules:ItemBitCount(2) AND NOT mItem2 THEN DO:
            mItem2 = TRUE.
            ShowItem().
        END.
        mIdle = 0.
        IF mGlobalOn THEN mGlobalCount = mGlobalCount + 1.
        /* the count that lets the next phantom out is the one of the first that is still waiting */
        DO i = 1 TO 4:
            IF mPresent[ListOrder(i)] AND mPMode[ListOrder(i)] = PhantomMode:Waiting THEN DO:
                mPersonal[ListOrder(i)] = mPersonal[ListOrder(i)] + 1.
                LEAVE.
            END.
        END.
    END METHOD.

    /* The order phantoms are let out of the lobby: Rich, Brian, Chip and (if it ever waits) Mary. */
    METHOD PRIVATE INTEGER ListOrder(INPUT piNth AS INTEGER):
        CASE piNth:
            WHEN 1 THEN RETURN INTEGER(PhantomKind:Rich).
            WHEN 2 THEN RETURN INTEGER(PhantomKind:Brian).
            WHEN 3 THEN RETURN INTEGER(PhantomKind:Chip).
            OTHERWISE RETURN INTEGER(PhantomKind:Mary).
        END CASE.
    END METHOD.

    /* Eats this many bits (never a commit token) as if Dibby had walked over them: the points, the counts, the items and the
       phantoms let out. Throws GridException for a number below 0 or more than there are. */
    METHOD PUBLIC VOID EatBits(INPUT piCount AS INTEGER):
        DEFINE VARIABLE cc   AS INTEGER NO-UNDO.
        DEFINE VARIABLE rr   AS INTEGER NO-UNDO.
        DEFINE VARIABLE n    AS INTEGER NO-UNDO.
        DEFINE VARIABLE spare AS INTEGER NO-UNDO.
        IF piCount = ? OR piCount < 0 THEN UNDO, THROW NEW GridException("A number of bits cannot be below 0").
        DO rr = 0 TO mMaze:Rows - 1:
            DO cc = 0 TO mMaze:Cols - 1:
                IF mMaze:KindAt(cc, rr) = TileKind:Bit THEN spare = spare + 1.
            END.
        END.
        IF piCount > spare THEN UNDO, THROW NEW GridException("There are only " + STRING(spare) + " bits left").
        DO rr = 0 TO mMaze:Rows - 1:
            DO cc = 0 TO mMaze:Cols - 1:
                IF n < piCount AND mMaze:KindAt(cc, rr) = TileKind:Bit THEN DO:
                    mMaze:Take(cc, rr).
                    Noted(cc, rr).
                    WasEaten(TileKind:Bit).
                    n = n + 1.
                END.
            END.
        END.
    END METHOD.

    /* Adds to the score. The best score follows it, and a life comes at 10000, once. Throws GridException for a number below 0. */
    METHOD PUBLIC VOID AddScore(INPUT piPoints AS INTEGER):
        IF piPoints = ? OR piPoints < 0 THEN UNDO, THROW NEW GridException("Points cannot be below 0").
        Score = Score + piPoints.
        IF Score > HiScore THEN HiScore = Score.
        IF NOT mExtraGiven AND Score >= ForEachRules:ExtraLifeScore() THEN DO:
            mExtraGiven = TRUE.
            Lives = Lives + 1.
        END.
    END METHOD.

    /* Puts Dibby at a place facing a way, without eating anything there. */
    METHOD PUBLIC VOID PlaceDibby(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT poDir AS MazeDir):
        IF poDir = ? THEN UNDO, THROW NEW GridException("Dibby must face some way").
        ASSIGN mDx = Wrapped(piX)
               mDy = piY
               mDir = poDir
               mDAcc = 0
               mMoving = TRUE
               mCornering = FALSE
               mEatPause = 0
               mLastCol = DibbyCol
               mLastRow = DibbyRow.
    END METHOD.

    /* ---------------------------------- the phantoms ---------------------------------- */

    METHOD PUBLIC LOGICAL PhantomPresent(INPUT poKind AS PhantomKind):
        RETURN mPresent[INTEGER(poKind)].
    END METHOD.

    METHOD PUBLIC INTEGER PhantomX(INPUT poKind AS PhantomKind):
        RETURN mPx[INTEGER(poKind)].
    END METHOD.

    METHOD PUBLIC INTEGER PhantomY(INPUT poKind AS PhantomKind):
        RETURN mPy[INTEGER(poKind)].
    END METHOD.

    METHOD PUBLIC INTEGER PhantomCol(INPUT poKind AS PhantomKind):
        RETURN ColOf(mPx[INTEGER(poKind)]).
    END METHOD.

    METHOD PUBLIC INTEGER PhantomRow(INPUT poKind AS PhantomKind):
        RETURN RowOf(mPy[INTEGER(poKind)]).
    END METHOD.

    METHOD PUBLIC MazeDir PhantomDir(INPUT poKind AS PhantomKind):
        RETURN mPDir[INTEGER(poKind)].
    END METHOD.

    /* What a phantom is doing. */
    METHOD PUBLIC PhantomMode ModeOf(INPUT poKind AS PhantomKind):
        RETURN mPMode[INTEGER(poKind)].
    END METHOD.

    /* The tile a phantom is heading for, or unknown when it is not heading for one (waiting, leaving or rolled back). */
    METHOD PUBLIC INTEGER PhantomTargetCol(INPUT poKind AS PhantomKind):
        DEFINE VARIABLE target AS Coord NO-UNDO.
        target = TargetOf(INTEGER(poKind)).
        RETURN (IF VALID-OBJECT(target) THEN target:X ELSE ?).
    END METHOD.

    METHOD PUBLIC INTEGER PhantomTargetRow(INPUT poKind AS PhantomKind):
        DEFINE VARIABLE target AS Coord NO-UNDO.
        target = TargetOf(INTEGER(poKind)).
        RETURN (IF VALID-OBJECT(target) THEN target:Y ELSE ?).
    END METHOD.

    METHOD PRIVATE Coord TargetOf(INPUT piIdx AS INTEGER):
        DEFINE VARIABLE kind AS PhantomKind NO-UNDO.
        DEFINE VARIABLE mary AS INTEGER     NO-UNDO.
        kind = PhantomKind:GetEnum(piIdx).
        CASE mPMode[piIdx]:
            WHEN PhantomMode:Scatter THEN RETURN PhantomTargeting:ScatterTarget(kind).
            WHEN PhantomMode:Chase THEN DO:
                mary = (IF mPresent[INTEGER(PhantomKind:Mary)] THEN INTEGER(PhantomKind:Mary) ELSE piIdx).
                RETURN PhantomTargeting:ChaseTarget(kind, ColOf(mPx[piIdx]), RowOf(mPy[piIdx]), DibbyCol, DibbyRow, mDir,
                                                    ColOf(mPx[mary]), RowOf(mPy[mary])).
            END.
            WHEN PhantomMode:Returning THEN RETURN PhantomTargeting:ReturningTarget().
            OTHERWISE RETURN ?.
        END CASE.
    END METHOD.

    /* Puts a phantom at a place facing a way in a mode, bringing it into play if the maze has no start for it. */
    METHOD PUBLIC VOID PlacePhantom(INPUT poKind AS PhantomKind, INPUT piX AS INTEGER, INPUT piY AS INTEGER,
                                    INPUT poDir AS MazeDir, INPUT poMode AS PhantomMode):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF poDir = ? OR poMode = ? THEN UNDO, THROW NEW GridException("A phantom must face some way and be doing something").
        i = INTEGER(poKind).
        ASSIGN mPresent[i] = TRUE
               mPx[i] = Wrapped(piX)
               mPy[i] = piY
               mPDir[i] = poDir
               mPMode[i] = poMode
               mPAcc[i] = 0
               mDescend[i] = FALSE.
    END METHOD.

    /* The mode of a phantom going out into the maze: the mode of the wave, or rolled back while the others are. */
    METHOD PRIVATE PhantomMode OutMode():
        IF RollbackFramesLeft > 0 THEN RETURN PhantomMode:RolledBack.
        RETURN (IF ForEachRules:IsScatterWave(WaveNumber) THEN PhantomMode:Scatter ELSE PhantomMode:Chase).
    END METHOD.

    /* What eating a commit token does to the phantoms in the maze: every one turns round, and for the time of the level they are
       rolled back (from level 19 they only turn round). A phantom in the lobby or running home is left alone. */
    METHOD PUBLIC VOID Rollback():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE frames AS INTEGER NO-UNDO.
        mChain = 0.
        frames = ForEachRules:RollbackFrames(Level).
        DO i = 1 TO 4:
            IF mPresent[i] AND (mPMode[i] = PhantomMode:Scatter OR mPMode[i] = PhantomMode:Chase OR mPMode[i] = PhantomMode:RolledBack) THEN DO:
                mPDir[i] = MazeDirs:Opposite(mPDir[i]).
                IF frames > 0 THEN mPMode[i] = PhantomMode:RolledBack.
            END.
        END.
        IF frames > 0 THEN RollbackFramesLeft = frames.
    END METHOD.

    /* The time of rolling back is up: the phantoms go back to the mode of the wave. */
    METHOD PRIVATE VOID EndRollback():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 4:
            IF mPresent[i] AND mPMode[i] = PhantomMode:RolledBack THEN mPMode[i] = OutMode().
        END.
    END METHOD.

    /* The wave is over: the next one starts and the phantoms in the maze change mode and turn round. The last wave does not end. */
    METHOD PUBLIC VOID SwitchWave():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF WaveNumber >= 8 THEN RETURN.
        WaveNumber = WaveNumber + 1.
        SetWaveTimer().
        DO i = 1 TO 4:
            IF mPresent[i] AND (mPMode[i] = PhantomMode:Scatter OR mPMode[i] = PhantomMode:Chase) THEN DO:
                mPMode[i] = (IF ForEachRules:IsScatterWave(WaveNumber) THEN PhantomMode:Scatter ELSE PhantomMode:Chase).
                mPDir[i] = MazeDirs:Opposite(mPDir[i]).
            END.
        END.
    END METHOD.

    /* Makes Mary wind up to a stage (0, 1 or 2) at once, whatever the bits left. Throws GridException for any other number. */
    METHOD PUBLIC VOID SetRage(INPUT piStage AS INTEGER):
        IF piStage = ? OR piStage < 0 OR piStage > 2 THEN UNDO, THROW NEW GridException("Rage has stages 0, 1 and 2").
        mRageForce = piStage.
    END METHOD.

    /* The speed of a phantom as a percentage of full speed. */
    METHOD PRIVATE INTEGER SpeedOf(INPUT piIdx AS INTEGER):
        DEFINE VARIABLE tunnel AS LOGICAL NO-UNDO.
        tunnel = mMaze:IsTunnel(ColOf(mPx[piIdx]), RowOf(mPy[piIdx])).
        CASE mPMode[piIdx]:
            WHEN PhantomMode:Returning THEN RETURN {&RETURNING-SPEED}.
            WHEN PhantomMode:Leaving THEN RETURN {&LEAVING-SPEED}.
            WHEN PhantomMode:RolledBack THEN RETURN (IF tunnel THEN ForEachRules:TunnelSpeed(Level) ELSE ForEachRules:PhantomRollbackSpeed(Level)).
            OTHERWISE DO:
                IF tunnel THEN RETURN ForEachRules:TunnelSpeed(Level).
                IF piIdx = INTEGER(PhantomKind:Mary) AND RageStage > 0 THEN RETURN ForEachRules:RageSpeed(Level, RageStage).
                RETURN ForEachRules:PhantomSpeed(Level).
            END.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID MovePhantom(INPUT piIdx AS INTEGER):
        DEFINE VARIABLE steps AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        IF NOT mPresent[piIdx] OR mPMode[piIdx] = PhantomMode:Waiting THEN RETURN.
        mPAcc[piIdx] = mPAcc[piIdx] + INTEGER(SpeedOf(piIdx) * 16 / 5).
        steps = INTEGER(TRUNCATE(mPAcc[piIdx] / {&UNIT}, 0)).
        mPAcc[piIdx] = mPAcc[piIdx] MODULO {&UNIT}.
        DO i = 1 TO steps:
            StepPhantom(piIdx).
        END.
    END METHOD.

    /* One pixel of a phantom. Leaving and returning phantoms use the door by a fixed path, the rest steer along the lanes. */
    METHOD PRIVATE VOID StepPhantom(INPUT piIdx AS INTEGER):
        DEFINE VARIABLE dir AS MazeDir NO-UNDO.
        DEFINE VARIABLE tc AS INTEGER NO-UNDO.
        DEFINE VARIABLE rw  AS INTEGER NO-UNDO.
        CASE mPMode[piIdx]:
            WHEN PhantomMode:Leaving THEN DO:
                IF mPx[piIdx] < {&DOOR-X} THEN mPx[piIdx] = mPx[piIdx] + 1.
                ELSE IF mPx[piIdx] > {&DOOR-X} THEN mPx[piIdx] = mPx[piIdx] - 1.
                ELSE IF mPy[piIdx] > {&OUTSIDE-Y} THEN mPy[piIdx] = mPy[piIdx] - 1.
                ELSE DO:
                    mPMode[piIdx] = OutMode().
                    mPDir[piIdx] = MazeDir:Left.
                    IF piIdx = INTEGER(PhantomKind:Chip) THEN mRageHeld = FALSE.
                END.
                RETURN.
            END.
            WHEN PhantomMode:Returning THEN DO:
                tc = ColOf(mPx[piIdx]).
                rw = RowOf(mPy[piIdx]).
                IF mDescend[piIdx] THEN DO:
                    IF mPy[piIdx] < {&INSIDE-Y} THEN mPy[piIdx] = mPy[piIdx] + 1.
                    ELSE ASSIGN mDescend[piIdx] = FALSE
                                mPMode[piIdx] = PhantomMode:Leaving.
                    RETURN.
                END.
                /* above the door: go to the middle of it and down */
                IF rw = 11 AND (tc = 13 OR tc = 14) AND mPy[piIdx] = {&OUTSIDE-Y} THEN DO:
                    IF mPx[piIdx] < {&DOOR-X} THEN mPx[piIdx] = mPx[piIdx] + 1.
                    ELSE IF mPx[piIdx] > {&DOOR-X} THEN mPx[piIdx] = mPx[piIdx] - 1.
                    ELSE mDescend[piIdx] = TRUE.
                    RETURN.
                END.
            END.
        END CASE.
        IF AtMiddle(mPx[piIdx], mPy[piIdx]) THEN DO:
            dir = ChooseWay(piIdx).
            mPDir[piIdx] = dir.
        END.
        ASSIGN mPx[piIdx] = Wrapped(mPx[piIdx] + MazeDirs:Dx(mPDir[piIdx]))
               mPy[piIdx] = mPy[piIdx] + MazeDirs:Dy(mPDir[piIdx]).
    END METHOD.

    /* Which way a phantom at the middle of a tile goes on. */
    METHOD PRIVATE MazeDir ChooseWay(INPUT piIdx AS INTEGER):
        DEFINE VARIABLE target AS Coord NO-UNDO.
        DEFINE VARIABLE tc    AS INTEGER NO-UNDO.
        DEFINE VARIABLE rw     AS INTEGER NO-UNDO.
        tc = ColOf(mPx[piIdx]).
        rw = RowOf(mPy[piIdx]).
        IF mPMode[piIdx] = PhantomMode:RolledBack THEN RETURN PhantomSteering:ChooseAtRandom(mMaze, tc, rw, mPDir[piIdx], mRandom).
        target = TargetOf(piIdx).
        RETURN PhantomSteering:Choose(mMaze, tc, rw, mPDir[piIdx], target:X, target:Y,
                                      mPMode[piIdx] <> PhantomMode:Returning, mPMode[piIdx] = PhantomMode:Returning).
    END METHOD.

    /* ---------------------------------- the lobby ---------------------------------- */

    /* Lets the first phantom waiting in the lobby out when its count is reached: its own count of bits eaten (which starts when
       the phantom before it is gone) or, after a life is lost, the count shared between them. */
    METHOD PRIVATE VOID ReleaseCheck():
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE k    AS INTEGER NO-UNDO.
        DEFINE VARIABLE done AS LOGICAL NO-UNDO.
        DO WHILE NOT done:
            done = TRUE.
            DO i = 1 TO 4:
                k = ListOrder(i).
                IF mPresent[k] AND mPMode[k] = PhantomMode:Waiting THEN DO:
                    IF (mGlobalOn AND mGlobalCount >= ForEachRules:GlobalLimit(PhantomKind:GetEnum(k)))
                       OR (NOT mGlobalOn AND mPersonal[k] >= ForEachRules:LobbyLimit(Level, PhantomKind:GetEnum(k))) THEN DO:
                        LetOut(k).
                        done = FALSE.
                    END.
                    LEAVE.
                END.
            END.
        END.
    END METHOD.

    /* Lets the first phantom waiting out, whatever its count: Dibby has not eaten for a while. */
    METHOD PRIVATE VOID ReleaseNext():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 4:
            IF mPresent[ListOrder(i)] AND mPMode[ListOrder(i)] = PhantomMode:Waiting THEN DO:
                LetOut(ListOrder(i)).
                RETURN.
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID LetOut(INPUT piIdx AS INTEGER):
        mPMode[piIdx] = PhantomMode:Leaving.
        mPAcc[piIdx] = 0.
        mPersonal[piIdx] = 0.
        IF piIdx = INTEGER(PhantomKind:Chip) THEN mGlobalOn = FALSE.
    END METHOD.

    /* ---------------------------------- touching ---------------------------------- */

    /* A phantom rolled back that touches Dibby is eaten, one that is hunting him catches him. Phantoms in the lobby and running
       home are harmless. */
    METHOD PRIVATE VOID Collide():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE caught AS LOGICAL NO-UNDO.
        DO i = 1 TO 4:
            IF mPresent[i] AND ABSOLUTE(mPx[i] - mDx) < {&TOUCH} AND ABSOLUTE(mPy[i] - mDy) < {&TOUCH} THEN DO:
                CASE mPMode[i]:
                    WHEN PhantomMode:RolledBack THEN EatPhantom(i).
                    WHEN PhantomMode:Scatter OR WHEN PhantomMode:Chase THEN caught = TRUE.
                END CASE.
            END.
        END.
        IF ItemActive AND ABSOLUTE(mMaze:ItemX - mDx) < {&TOUCH} AND ABSOLUTE(mMaze:ItemY - mDy) < {&TOUCH} THEN DO:
            AddScore(ForEachRules:ItemPoints(ItemOnShow)).
            ASSIGN PopupPoints = ForEachRules:ItemPoints(ItemOnShow)
                   PopupX = mMaze:ItemX
                   PopupY = mMaze:ItemY
                   PopupIsItem = TRUE
                   PopupFramesLeft = 120
                   ItemActive = FALSE.
            ItemsEatenTotal = ItemsEatenTotal + 1.
        END.
        IF caught THEN DO:
            Phase = ForEachPhase:Caught.
            mPhaseFrames = {&CAUGHT-FRAMES}.
            ItemActive = FALSE.
        END.
    END METHOD.

    METHOD PRIVATE VOID EatPhantom(INPUT piIdx AS INTEGER):
        mChain = MINIMUM(4, mChain + 1).
        LastPhantomPoints = ForEachRules:PhantomPoints(mChain).
        AddScore(LastPhantomPoints).
        ASSIGN PopupPoints = LastPhantomPoints
               PopupX = mPx[piIdx]
               PopupY = mPy[piIdx]
               PopupIsItem = FALSE
               PopupFramesLeft = {&EATEN-FRAMES}.
        mPMode[piIdx] = PhantomMode:Returning.
        mPAcc[piIdx] = 0.
        PhantomsEatenTotal = PhantomsEatenTotal + 1.
        FreezeFramesLeft = {&EATEN-FRAMES}.
    END METHOD.

    /* ---------------------------------- the bonus item ---------------------------------- */

    /* Puts out the bonus item of the level, as if the count of things eaten had been reached, if the maze has a spot for it. */
    METHOD PUBLIC VOID ShowItem():
        IF NOT mMaze:HasItemSpot THEN RETURN.
        ItemsShownTotal = ItemsShownTotal + 1.
        ASSIGN ItemActive = TRUE
               ItemOnShow = ForEachRules:ItemFor(Level)
               ItemFramesLeft = ForEachRules:ItemFrames().
    END METHOD.

END CLASS.
