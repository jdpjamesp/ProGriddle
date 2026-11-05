/* The rules of Centipede, as a real time game that runs frame by frame (a frame is a sixtieth of a second: Advance makes one, and
   Tick turns the milliseconds a clock gives it into frames, scaled by SpeedPercent). A centipede crawls down a field of
   mushrooms towards a shooter that moves about in the bottom rows. Everything works in pixels, 8 to a tile, on a board of 30 x 30
   tiles, and the game knows nothing about drawing.

   The grid holds the mushrooms, on two layers: "mushroom" (0 for none, else the hit points left, 1 to 4) and "poison" (1 when a
   scorpion has poisoned it). The game owns its grid, and Dispose releases it.

   Rules and numbers:
   - The shooter moves 3 pixels a frame in the player zone (the bottom 6 rows) and cannot move into a mushroom. It fires one
     shot at a time, which flies 8 pixels a frame, so holding the fire key fires again the moment the shot is gone.
   - A mushroom takes four hits and is worth 1 point when it goes. A shot stops at the first thing it hits.
   - The centipede has 12 segments in wave 1. Each segment crawls a pixel at a time (2 pixels a frame, 3 from wave 4) along its row,
     and when the next tile is a mushroom or the edge it drops one row and turns round. At the bottom it climbs back up the
     player zone to the top of it, and down again. A segment that touches a poisoned mushroom dives straight to the bottom.
   - Shooting a segment leaves a mushroom where it was and the segment behind it becomes a head. A body segment is worth 10 and a
     head 100. From wave 2 a wave has loose heads (one more each wave, to 8) that come in from the left in the player zone,
     instead of body: a wave is always 12 segments.
   - The flea falls down a column, dropping mushrooms as it goes, once there are fewer than 5 mushrooms in the player zone. It
     takes two hits (the second makes it quicker) and is worth 200. The spider zigzags across the lower rows, eating mushrooms,
     and is worth 300, 600 or 900 by how close it is when shot. The scorpion, from wave 2, crosses the upper rows poisoning every
     mushroom it passes and is worth 1000. The flea, the spider and the centipede kill the shooter by touching it.
   - After a shooter is lost the field is mended (5 points for each mushroom made whole) and the wave starts again. A shooter is
     added at every 12000 points. Three at the start.
   - The title and game over screens wait for the fire key, which has to be let go and pressed again.

   Counters (ShotsFired, SegmentsKilled, MushroomsDestroyed and so on) only go up, so a cue source can compare them with the ones
   it last saw. Frames counts every frame ever made and PhaseFrames the frames of the current phase, so a painter can animate as
   a function of them. Randomness comes from the IRandom given to the constructor. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    /* the most time one Tick will count, and the most frames it will make for it */
    &SCOPED-DEFINE MOST-MS 100
    &SCOPED-DEFINE MOST-FRAMES 6
    /* the layers of the grid */
    &SCOPED-DEFINE HP-LAYER 1
    &SCOPED-DEFINE POISON-LAYER 2
    /* room for the segments: a wave is 12 */
    &SCOPED-DEFINE MAX-SEGS 16

    DEFINE PRIVATE VARIABLE mRandom    AS IRandom NO-UNDO.
    DEFINE PRIVATE VARIABLE mAcc       AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice    AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE mFireReady AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mNextExtra AS INTEGER NO-UNDO.
    /* the shooter and its shot, in pixels */
    DEFINE PRIVATE VARIABLE mPlayerX   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlayerY   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mShotOn    AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mShotX     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mShotY     AS INTEGER NO-UNDO.
    /* the segments in the order of the train: where (pixels), the way along the row (1 or -1), the way down the rows (1 or -1),
       the pixels still to fall to the next row, whether it leads, whether it is diving and whether it has reached the bottom */
    DEFINE PRIVATE VARIABLE mSegN      AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSegX      AS INTEGER NO-UNDO EXTENT {&MAX-SEGS}.
    DEFINE PRIVATE VARIABLE mSegY      AS INTEGER NO-UNDO EXTENT {&MAX-SEGS}.
    DEFINE PRIVATE VARIABLE mSegDx     AS INTEGER NO-UNDO EXTENT {&MAX-SEGS}.
    DEFINE PRIVATE VARIABLE mSegDy     AS INTEGER NO-UNDO EXTENT {&MAX-SEGS}.
    DEFINE PRIVATE VARIABLE mSegFall   AS INTEGER NO-UNDO EXTENT {&MAX-SEGS}.
    DEFINE PRIVATE VARIABLE mSegHead   AS LOGICAL NO-UNDO EXTENT {&MAX-SEGS}.
    DEFINE PRIVATE VARIABLE mSegDive   AS LOGICAL NO-UNDO EXTENT {&MAX-SEGS}.
    DEFINE PRIVATE VARIABLE mSegZone   AS LOGICAL NO-UNDO EXTENT {&MAX-SEGS}.
    /* loose heads still to come in this wave, and the frames until the next one */
    DEFINE PRIVATE VARIABLE mHeadsToCome AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeadTimer AS INTEGER NO-UNDO.
    /* the flea, the spider and the scorpion: whether out, where (pixels), and the frames until the next one comes (-1 for never) */
    DEFINE PRIVATE VARIABLE mFleaOn    AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mFleaX     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mFleaY     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mFleaHp    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mFleaTimer AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpiderOn  AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpiderX   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpiderY   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpiderDx  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpiderDy  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpiderT   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpiderTimer AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mScorpOn   AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mScorpX    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mScorpY    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mScorpDx   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mScorpTimer AS INTEGER NO-UNDO.

    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    /* How fast the game runs, as a percentage of the real 60 frames a second: 20 to 100. Everything slows together,
       so the game stays the same game and is only easier to play. */
    DEFINE PUBLIC PROPERTY SpeedPercent AS INTEGER NO-UNDO INITIAL 70
        GET.
        SET(INPUT piValue AS INTEGER):
            SpeedPercent = MINIMUM(100, MAXIMUM(20, piValue)).
        END SET.

    DEFINE PUBLIC PROPERTY Phase AS GamePhase NO-UNDO
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

    /* Shooters left, not counting the one in play after a game has started. */
    DEFINE PUBLIC PROPERTY Lives AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Wave AS INTEGER NO-UNDO INITIAL 1
        GET.
        PRIVATE SET.

    /* Frames made since the game was built, and frames since the phase began. */
    DEFINE PUBLIC PROPERTY Frames AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY PhaseFrames AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The way the shooter is being steered, from the input: -1, 0 or 1 across and down. */
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

    /* True while the fire key is down. */
    DEFINE PUBLIC PROPERTY FireHeld AS LOGICAL NO-UNDO
        GET.
        SET.

    /* The counters, which only go up. */
    DEFINE PUBLIC PROPERTY ShotsFired AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY SegmentsKilled AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY HeadsKilled AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY MushroomsDestroyed AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY FleaHits AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY FleaKills AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY SpiderKills AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ScorpionKills AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Deaths AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ExtraLives AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY WavesCleared AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The points of the last thing shot that paid points a pop-up can show (a spider, a flea, a scorpion), and where it was. */
    DEFINE PUBLIC PROPERTY LastBonus AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastBonusX AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastBonusY AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The frame (Frames) the last bonus was won on, -1 for none. */
    DEFINE PUBLIC PROPERTY LastBonusFrame AS INTEGER NO-UNDO INITIAL -1
        GET.
        PRIVATE SET.

    /* The shooter's place in pixels (its top left), and the shot's. */
    DEFINE PUBLIC PROPERTY PlayerX AS INTEGER NO-UNDO
        GET():
            RETURN mPlayerX.
        END GET.

    DEFINE PUBLIC PROPERTY PlayerY AS INTEGER NO-UNDO
        GET():
            RETURN mPlayerY.
        END GET.

    DEFINE PUBLIC PROPERTY ShotActive AS LOGICAL NO-UNDO
        GET():
            RETURN mShotOn.
        END GET.

    DEFINE PUBLIC PROPERTY ShotX AS INTEGER NO-UNDO
        GET():
            RETURN mShotX.
        END GET.

    DEFINE PUBLIC PROPERTY ShotY AS INTEGER NO-UNDO
        GET():
            RETURN mShotY.
        END GET.

    /* True while the shooter is in play (not breaking up, not between games). */
    DEFINE PUBLIC PROPERTY PlayerAlive AS LOGICAL NO-UNDO
        GET():
            RETURN Phase = GamePhase:Playing OR Phase = GamePhase:Cleared.
        END GET.

    /* A number that goes up whenever a mushroom changes (placed, hit, poisoned, mended, taken away), so a painter redraws the field
       only when it has to. */
    DEFINE PUBLIC PROPERTY FieldVersion AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The segments on the field now. */
    DEFINE PUBLIC PROPERTY SegmentCount AS INTEGER NO-UNDO
        GET():
            RETURN mSegN.
        END GET.

    /* Loose heads that have still to come into this wave. */
    DEFINE PUBLIC PROPERTY HeadsToCome AS INTEGER NO-UNDO
        GET():
            RETURN mHeadsToCome.
        END GET.

    DEFINE PUBLIC PROPERTY FleaActive AS LOGICAL NO-UNDO
        GET():
            RETURN mFleaOn.
        END GET.

    DEFINE PUBLIC PROPERTY FleaX AS INTEGER NO-UNDO
        GET():
            RETURN mFleaX.
        END GET.

    DEFINE PUBLIC PROPERTY FleaY AS INTEGER NO-UNDO
        GET():
            RETURN mFleaY.
        END GET.

    /* Hits the flea can still take: 2, then 1. */
    DEFINE PUBLIC PROPERTY FleaHp AS INTEGER NO-UNDO
        GET():
            RETURN mFleaHp.
        END GET.

    DEFINE PUBLIC PROPERTY SpiderActive AS LOGICAL NO-UNDO
        GET():
            RETURN mSpiderOn.
        END GET.

    DEFINE PUBLIC PROPERTY SpiderX AS INTEGER NO-UNDO
        GET():
            RETURN mSpiderX.
        END GET.

    DEFINE PUBLIC PROPERTY SpiderY AS INTEGER NO-UNDO
        GET():
            RETURN mSpiderY.
        END GET.

    DEFINE PUBLIC PROPERTY ScorpionActive AS LOGICAL NO-UNDO
        GET():
            RETURN mScorpOn.
        END GET.

    DEFINE PUBLIC PROPERTY ScorpionX AS INTEGER NO-UNDO
        GET():
            RETURN mScorpX.
        END GET.

    DEFINE PUBLIC PROPERTY ScorpionY AS INTEGER NO-UNDO
        GET():
            RETURN mScorpY.
        END GET.

    /* 1 when the scorpion crosses to the right, -1 to the left. */
    DEFINE PUBLIC PROPERTY ScorpionDirection AS INTEGER NO-UNDO
        GET():
            RETURN mScorpDx.
        END GET.

    /* Mushrooms on the field now. */
    DEFINE PUBLIC PROPERTY MushroomCount AS INTEGER NO-UNDO
        GET():
            RETURN CountMushrooms(0).
        END GET.

    /* Mushrooms in the player zone now. */
    DEFINE PUBLIC PROPERTY ZoneMushroomCount AS INTEGER NO-UNDO
        GET():
            RETURN CountMushrooms(CentipedeRules:PlayerTop()).
        END GET.

    /* The grid must be 30 x 30 with exactly two layers, "mushroom" and "poison". */
    CONSTRUCTOR PUBLIC CentipedeGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        SUPER("Centipede", poGrid).
        IF poGrid:Width <> CentipedeRules:Cols() OR poGrid:Height <> CentipedeRules:Rows() THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A Centipede grid is &1 x &2", CentipedeRules:Cols(), CentipedeRules:Rows())).
        IF poGrid:Store:LayerCount <> 2 OR poGrid:Store:LayerName({&HP-LAYER}) <> "mushroom" OR poGrid:Store:LayerName({&POISON-LAYER}) <> "poison" THEN
            UNDO, THROW NEW GridException("A Centipede grid has two layers, mushroom and poison").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Centipede game needs a random source").
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

    /* Starts a new game from any phase: no score, three shooters, wave 1 and a field of 30 mushrooms. */
    METHOD PUBLIC VOID StartGame():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Score = 0.
        Lives = CentipedeRules:StartLives().
        Wave = 1.
        mNotice = "".
        mNextExtra = CentipedeRules:ExtraLifeEvery().
        mFireReady = FALSE.
        ClearField().
        DO i = 1 TO 30:
            PlaceMushroom(mRandom:NextInt(CentipedeRules:Cols()), 1 + mRandom:NextInt(CentipedeRules:PlayerTop() - 2), CentipedeRules:MushroomHp()).
        END.
        ClearCreatures().
        PlacePlayer(112, 224).
        StartWave().
        SetPhase(GamePhase:Playing).
    END METHOD.

    /* A few words about what just happened (an extra shooter, a new wave), or "" for nothing. Taking them clears them. */
    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    /* ============================== the field ============================== */

    /* The hit points of the mushroom in a tile, 0 for none. Throws GridException for a tile off the board. */
    METHOD PUBLIC INTEGER MushroomAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckTile(piX, piY).
        RETURN Hp(piX, piY).
    END METHOD.

    /* True when the mushroom in a tile is poisoned. Throws GridException for a tile off the board. */
    METHOD PUBLIC LOGICAL PoisonedAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckTile(piX, piY).
        RETURN Poison(piX, piY).
    END METHOD.

    /* Puts a mushroom with piHp hit points (0 takes it away) in a tile, and makes it healthy. Throws GridException for a tile off the
       board or hit points outside 0 to 4. */
    METHOD PUBLIC VOID PlaceMushroom(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piHp AS INTEGER):
        CheckTile(piX, piY).
        IF piHp = ? OR piHp < 0 OR piHp > CentipedeRules:MushroomHp() THEN UNDO, THROW NEW GridException("A mushroom has 0 to 4 hit points, not " + STRING(piHp)).
        Grid:Store:SetCellAt({&HP-LAYER}, piY * CentipedeRules:Cols() + piX, piHp).
        Grid:Store:SetCellAt({&POISON-LAYER}, piY * CentipedeRules:Cols() + piX, 0).
        FieldVersion = FieldVersion + 1.
    END METHOD.

    /* Poisons the mushroom in a tile. A tile with no mushroom is left alone. Throws GridException for a tile off the board. */
    METHOD PUBLIC VOID PoisonMushroom(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckTile(piX, piY).
        IF Hp(piX, piY) > 0 AND NOT Poison(piX, piY) THEN DO:
            Grid:Store:SetCellAt({&POISON-LAYER}, piY * CentipedeRules:Cols() + piX, 1).
            FieldVersion = FieldVersion + 1.
        END.
    END METHOD.

    /* Takes every mushroom off the field. */
    METHOD PUBLIC VOID ClearField():
        Grid:Store:FillLayer({&HP-LAYER}, 0).
        Grid:Store:FillLayer({&POISON-LAYER}, 0).
        FieldVersion = FieldVersion + 1.
    END METHOD.

    /* ============================== the segments ============================== */

    /* The place of a segment (its top left, in pixels), from the head of the train (0) to the last one. Throws GridException for any
       other number. */
    METHOD PUBLIC INTEGER SegmentX(INPUT piIndex AS INTEGER):
        CheckSegment(piIndex).
        RETURN mSegX[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER SegmentY(INPUT piIndex AS INTEGER):
        CheckSegment(piIndex).
        RETURN mSegY[piIndex + 1].
    END METHOD.

    /* True when a segment leads a train (it has a head). */
    METHOD PUBLIC LOGICAL SegmentIsHead(INPUT piIndex AS INTEGER):
        CheckSegment(piIndex).
        RETURN mSegHead[piIndex + 1].
    END METHOD.

    /* 1 when a segment is crawling to the right, -1 to the left. */
    METHOD PUBLIC INTEGER SegmentDirection(INPUT piIndex AS INTEGER):
        CheckSegment(piIndex).
        RETURN mSegDx[piIndex + 1].
    END METHOD.

    /* True when a segment is dropping to the next row, so a painter can show it turning. */
    METHOD PUBLIC LOGICAL SegmentFalling(INPUT piIndex AS INTEGER):
        CheckSegment(piIndex).
        RETURN mSegFall[piIndex + 1] > 0.
    END METHOD.

    /* True when a segment is diving straight down because it touched a poisoned mushroom, so a painter can show the tell. */
    METHOD PUBLIC LOGICAL SegmentDiving(INPUT piIndex AS INTEGER):
        CheckSegment(piIndex).
        RETURN mSegDive[piIndex + 1].
    END METHOD.

    /* Takes every segment, and the loose heads still to come, off the field. */
    METHOD PUBLIC VOID ClearCentipede():
        mSegN = 0.
        mHeadsToCome = 0.
    END METHOD.

    /* Adds a segment in tile piX, piY crawling the way piDirection says (1 right, -1 left), at the end of the train. A segment that is
       not a head follows the one added before it. Throws GridException for a tile off the board (a segment may be put off the
       right edge to come on from there), a direction that is not 1 or -1, or a field that is full. */
    METHOD PUBLIC VOID AddSegment(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piDirection AS INTEGER, INPUT plHead AS LOGICAL):
        IF piY = ? OR piY < 0 OR piY >= CentipedeRules:Rows() OR piX = ? OR piX < -1 OR piX > 60 THEN UNDO, THROW NEW GridException("A segment cannot be put at " + STRING(piX) + ", " + STRING(piY)).
        IF piDirection <> 1 AND piDirection <> -1 THEN UNDO, THROW NEW GridException("A segment goes 1 or -1 along its row, not " + STRING(piDirection)).
        IF mSegN >= {&MAX-SEGS} THEN UNDO, THROW NEW GridException("The field is full of segments").
        mSegN = mSegN + 1.
        ASSIGN mSegX[mSegN] = piX * CentipedeRules:Tile()
               mSegY[mSegN] = piY * CentipedeRules:Tile()
               mSegDx[mSegN] = piDirection
               mSegDy[mSegN] = 1
               mSegFall[mSegN] = 0
               mSegHead[mSegN] = plHead
               mSegDive[mSegN] = FALSE
               mSegZone[mSegN] = piY >= CentipedeRules:Rows() - 1.
    END METHOD.

    /* ============================== the creatures ============================== */

    /* Sends the flea, the spider and the scorpion away, and starts their waiting again. */
    METHOD PUBLIC VOID ClearCreatures():
        mFleaOn = FALSE.
        mSpiderOn = FALSE.
        mScorpOn = FALSE.
        mFleaTimer = 300.
        mSpiderTimer = 900 + mRandom:NextInt(600).
        mScorpTimer = (IF Wave >= 2 THEN 1200 + mRandom:NextInt(900) ELSE -1).
    END METHOD.

    /* Puts a flea at the top of column piX, on the board. Throws GridException for a column off the board. */
    METHOD PUBLIC VOID SpawnFlea(INPUT piX AS INTEGER):
        IF piX = ? OR piX < 0 OR piX >= CentipedeRules:Cols() THEN UNDO, THROW NEW GridException("A flea falls down a column from 0 to 29, not " + STRING(piX)).
        ASSIGN mFleaOn = TRUE
               mFleaX = piX * CentipedeRules:Tile()
               mFleaY = 0
               mFleaHp = 2.
    END METHOD.

    /* Puts a spider in row piY (20 to 29) coming in from the left or the right. Throws GridException for any other row. */
    METHOD PUBLIC VOID SpawnSpider(INPUT plFromLeft AS LOGICAL, INPUT piY AS INTEGER):
        IF piY = ? OR piY < 20 OR piY >= CentipedeRules:Rows() THEN UNDO, THROW NEW GridException("A spider crawls in rows 20 to 29, not " + STRING(piY)).
        ASSIGN mSpiderOn = TRUE
               mSpiderX = (IF plFromLeft THEN -16 ELSE CentipedeRules:BoardPixels())
               mSpiderY = piY * CentipedeRules:Tile()
               mSpiderDx = (IF plFromLeft THEN 2 ELSE -2)
               mSpiderDy = 0
               mSpiderT = 12 + mRandom:NextInt(24).
    END METHOD.

    /* Puts a scorpion in row piY (1 to 22) coming in from the left or the right. Throws GridException for any other row. */
    METHOD PUBLIC VOID SpawnScorpion(INPUT piY AS INTEGER, INPUT plFromLeft AS LOGICAL):
        IF piY = ? OR piY < 1 OR piY >= CentipedeRules:PlayerTop() - 1 THEN UNDO, THROW NEW GridException("A scorpion crawls in rows 1 to 22, not " + STRING(piY)).
        ASSIGN mScorpOn = TRUE
               mScorpX = (IF plFromLeft THEN -16 ELSE CentipedeRules:BoardPixels())
               mScorpY = piY * CentipedeRules:Tile()
               mScorpDx = (IF plFromLeft THEN 1 ELSE -1).
    END METHOD.

    /* ============================== the shooter ============================== */

    /* Puts the shooter's top left at piX, piY pixels, brought inside the player zone. */
    METHOD PUBLIC VOID PlacePlayer(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        mPlayerX = MINIMUM(CentipedeRules:BoardPixels() - CentipedeRules:Tile(), MAXIMUM(0, piX)).
        mPlayerY = MINIMUM(CentipedeRules:BoardPixels() - CentipedeRules:Tile(), MAXIMUM(CentipedeRules:PlayerTop() * CentipedeRules:Tile(), piY)).
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        Score = 0.
        Lives = CentipedeRules:StartLives().
        Wave = 1.
        mNotice = "".
        mAcc = 0.
        mFireReady = FALSE.
        mShotOn = FALSE.
        ClearField().
        ClearCentipede().
        ClearCreatures().
        PlacePlayer(112, 224).
        SetPhase(GamePhase:Title).
    END METHOD.

    /* ============================== one frame ============================== */

    METHOD PRIVATE VOID Step():
        Frames = Frames + 1.
        PhaseFrames = PhaseFrames + 1.
        CASE Phase:
            WHEN GamePhase:Title OR WHEN GamePhase:GameOver THEN StepWaiting().
            WHEN GamePhase:Playing THEN StepPlaying().
            WHEN GamePhase:Dying THEN IF PhaseFrames >= 100 THEN AfterDeath().
            WHEN GamePhase:Cleared THEN IF PhaseFrames >= 90 THEN NextWave().
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID SetPhase(INPUT poPhase AS GamePhase):
        Phase = poPhase.
        PhaseFrames = 0.
    END METHOD.

    /* The title and game over screens: the fire key, let go and pressed again, goes on. */
    METHOD PRIVATE VOID StepWaiting():
        IF NOT FireHeld THEN DO:
            mFireReady = TRUE.
            RETURN.
        END.
        IF NOT mFireReady OR (Phase = GamePhase:GameOver AND PhaseFrames < 90) THEN RETURN.
        mFireReady = FALSE.
        IF Phase = GamePhase:Title THEN StartGame().
        ELSE DO:
            Initialise().
            mFireReady = FALSE.
        END.
    END METHOD.

    METHOD PRIVATE VOID StepPlaying():
        MovePlayer().
        IF FireHeld AND NOT mShotOn THEN DO:
            ASSIGN mShotOn = TRUE
                   mShotX = mPlayerX + 3
                   mShotY = mPlayerY
                   ShotsFired = ShotsFired + 1.
        END.
        IF mShotOn THEN MoveShot().
        MoveSegments().
        BringHeads().
        StepFlea().
        StepSpider().
        StepScorpion().
        IF Phase = GamePhase:Playing AND PlayerTouched() THEN Die().
        IF Phase = GamePhase:Playing AND mSegN = 0 AND mHeadsToCome = 0 THEN WaveDone().
    END METHOD.

    /* ============================== the shooter and its shot ============================== */

    METHOD PRIVATE VOID MovePlayer():
        DEFINE VARIABLE nx AS INTEGER NO-UNDO.
        DEFINE VARIABLE ny AS INTEGER NO-UNDO.
        IF MoveX <> 0 THEN DO:
            nx = MINIMUM(CentipedeRules:BoardPixels() - CentipedeRules:Tile(), MAXIMUM(0, mPlayerX + MoveX * CentipedeRules:PlayerSpeed())).
            IF NOT Blocked(nx, mPlayerY) THEN mPlayerX = nx.
        END.
        IF MoveY <> 0 THEN DO:
            ny = MINIMUM(CentipedeRules:BoardPixels() - CentipedeRules:Tile(), MAXIMUM(CentipedeRules:PlayerTop() * CentipedeRules:Tile(), mPlayerY + MoveY * CentipedeRules:PlayerSpeed())).
            IF NOT Blocked(mPlayerX, ny) THEN mPlayerY = ny.
        END.
    END METHOD.

    /* True when the shooter, with its top left at piX, piY, would be inside a mushroom. The shooter's box is the inner 6 x 6 pixels. */
    METHOD PRIVATE LOGICAL Blocked(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        DO cy = Cell(piY + 1) TO Cell(piY + 6):
            DO cx = Cell(piX + 1) TO Cell(piX + 6):
                IF Hp(cx, cy) > 0 THEN RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* The shot flies up, a pixel at a time so nothing is skipped, and stops at the first thing it hits or at the top. */
    METHOD PRIVATE VOID MoveShot():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO n = 1 TO CentipedeRules:ShotSpeed():
            mShotY = mShotY - 1.
            IF mShotY < 0 THEN DO:
                mShotOn = FALSE.
                RETURN.
            END.
            IF ShotHits() THEN DO:
                mShotOn = FALSE.
                RETURN.
            END.
        END.
    END METHOD.

    /* Looks for something at the tip of the shot and, if there is, deals with it. Returns true when the shot hit. */
    METHOD PRIVATE LOGICAL ShotHits():
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        DO i = 1 TO mSegN:
            IF Overlaps(mShotX, mShotY, 2, 1, mSegX[i], mSegY[i], 8, 8) THEN DO:
                KillSegment(i).
                RETURN TRUE.
            END.
        END.
        IF mFleaOn AND Overlaps(mShotX, mShotY, 2, 1, mFleaX, mFleaY, 8, 8) THEN DO:
            HitFlea().
            RETURN TRUE.
        END.
        IF mSpiderOn AND Overlaps(mShotX, mShotY, 2, 1, mSpiderX, mSpiderY, 16, 8) THEN DO:
            KillSpider().
            RETURN TRUE.
        END.
        IF mScorpOn AND Overlaps(mShotX, mShotY, 2, 1, mScorpX, mScorpY, 16, 8) THEN DO:
            KillScorpion().
            RETURN TRUE.
        END.
        cx = Cell(mShotX).
        cy = Cell(mShotY).
        IF Hp(cx, cy) > 0 THEN DO:
            DamageMushroom(cx, cy).
            RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE VOID DamageMushroom(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE hp AS INTEGER NO-UNDO.
        hp = Hp(piX, piY) - 1.
        Grid:Store:SetCellAt({&HP-LAYER}, piY * CentipedeRules:Cols() + piX, hp).
        FieldVersion = FieldVersion + 1.
        IF hp = 0 THEN DO:
            Grid:Store:SetCellAt({&POISON-LAYER}, piY * CentipedeRules:Cols() + piX, 0).
            MushroomsDestroyed = MushroomsDestroyed + 1.
            AddScore(CentipedeRules:PointsMushroom()).
        END.
    END METHOD.

    /* ============================== the centipede ============================== */

    /* Makes the segments of the wave: the body comes in from the right in row 0, and the loose heads follow in the player zone. */
    METHOD PRIVATE VOID StartWave():
        DEFINE VARIABLE extras AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        extras = MINIMUM(Wave - 1, CentipedeRules:MostExtraHeads()).
        ClearCentipede().
        DO i = 1 TO CentipedeRules:SegmentsPerWave() - extras:
            AddSegment(CentipedeRules:Cols() - 1 + (i - 1), 0, -1, i = 1).
        END.
        mHeadsToCome = extras.
        mHeadTimer = 240.
    END METHOD.

    METHOD PRIVATE VOID MoveSegments():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO n = 1 TO CentipedeRules:SegmentSpeed(Wave):
            DO i = 1 TO mSegN:
                StepSegment(i).
            END.
        END.
    END METHOD.

    /* A segment moves a pixel: down or up when it is on its way to the next row, else along its row, and it decides what to do at
       each tile. */
    METHOD PRIVATE VOID StepSegment(INPUT piSeg AS INTEGER):
        IF mSegFall[piSeg] > 0 THEN DO:
            mSegY[piSeg] = mSegY[piSeg] + mSegDy[piSeg].
            mSegFall[piSeg] = mSegFall[piSeg] - 1.
            IF mSegFall[piSeg] = 0 THEN Landed(piSeg).
            RETURN.
        END.
        mSegX[piSeg] = mSegX[piSeg] + mSegDx[piSeg].
        IF mSegX[piSeg] MODULO CentipedeRules:Tile() = 0 THEN Decide(piSeg).
    END METHOD.

    /* A segment has fallen onto a row. A diving one carries on down to the bottom; any other looks at what is in its way. */
    METHOD PRIVATE VOID Landed(INPUT piSeg AS INTEGER):
        IF mSegDive[piSeg] THEN DO:
            IF Cell(mSegY[piSeg]) >= CentipedeRules:Rows() - 1 THEN ASSIGN
                mSegDive[piSeg] = FALSE
                mSegZone[piSeg] = TRUE
                mSegDy[piSeg] = -1.
            ELSE ASSIGN
                mSegDy[piSeg] = 1
                mSegFall[piSeg] = CentipedeRules:Tile().
            RETURN.
        END.
        Decide(piSeg).
    END METHOD.

    /* A segment is on a tile boundary: if the way ahead is blocked by the edge or a mushroom it drops a row and turns round, and
       if the mushroom is poisoned it dives. A tile off the right edge is not in the way of a segment coming on from there. */
    METHOD PRIVATE VOID Decide(INPUT piSeg AS INTEGER):
        DEFINE VARIABLE cy      AS INTEGER NO-UNDO.
        DEFINE VARIABLE ahead   AS INTEGER NO-UNDO.
        DEFINE VARIABLE blocked AS LOGICAL NO-UNDO.
        DEFINE VARIABLE poison  AS LOGICAL NO-UNDO.
        cy = Cell(mSegY[piSeg]).
        ahead = Cell(mSegX[piSeg]) + mSegDx[piSeg].
        IF ahead < 0 OR (ahead >= CentipedeRules:Cols() AND mSegDx[piSeg] > 0) THEN blocked = TRUE.
        ELSE IF ahead < CentipedeRules:Cols() AND Hp(ahead, cy) > 0 THEN ASSIGN
            blocked = TRUE
            poison = Poison(ahead, cy).
        IF blocked THEN TurnRound(piSeg, poison).
    END METHOD.

    /* Drops a segment to the next row and sends it back the way it came. In the player zone it climbs once it has been to the bottom,
       and comes down again at the top of the zone. */
    METHOD PRIVATE VOID TurnRound(INPUT piSeg AS INTEGER, INPUT plPoison AS LOGICAL):
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        cy = Cell(mSegY[piSeg]).
        mSegDx[piSeg] = - mSegDx[piSeg].
        IF plPoison AND cy < CentipedeRules:Rows() - 1 THEN ASSIGN
            mSegDive[piSeg] = TRUE
            mSegDy[piSeg] = 1.
        ELSE IF mSegDy[piSeg] = 1 AND cy >= CentipedeRules:Rows() - 1 THEN ASSIGN
            mSegDy[piSeg] = -1
            mSegZone[piSeg] = TRUE.
        ELSE IF mSegDy[piSeg] = -1 AND cy <= CentipedeRules:PlayerTop() THEN mSegDy[piSeg] = 1.
        mSegFall[piSeg] = CentipedeRules:Tile().
    END METHOD.

    /* Shoots a segment: points, a mushroom where it was, and the segment behind it leads. */
    METHOD PRIVATE VOID KillSegment(INPUT piSeg AS INTEGER):
        DEFINE VARIABLE i  AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        cx = Cell(mSegX[piSeg] + 4).
        cy = Cell(mSegY[piSeg] + 4).
        SegmentsKilled = SegmentsKilled + 1.
        IF mSegHead[piSeg] THEN DO:
            HeadsKilled = HeadsKilled + 1.
            AddScore(CentipedeRules:PointsHead()).
        END.
        ELSE AddScore(CentipedeRules:PointsSegment()).
        IF piSeg < mSegN THEN mSegHead[piSeg + 1] = TRUE.
        DO i = piSeg TO mSegN - 1:
            ASSIGN mSegX[i] = mSegX[i + 1]
                   mSegY[i] = mSegY[i + 1]
                   mSegDx[i] = mSegDx[i + 1]
                   mSegDy[i] = mSegDy[i + 1]
                   mSegFall[i] = mSegFall[i + 1]
                   mSegHead[i] = mSegHead[i + 1]
                   mSegDive[i] = mSegDive[i + 1]
                   mSegZone[i] = mSegZone[i + 1].
        END.
        mSegN = mSegN - 1.
        IF cx >= 0 AND cx < CentipedeRules:Cols() AND cy >= 0 AND cy < CentipedeRules:Rows() AND NOT TouchesPlayer(cx, cy) THEN
            PlaceMushroom(cx, cy, CentipedeRules:MushroomHp()).
    END METHOD.

    /* The loose heads of a wave come in from the left of the top row of the player zone, one after another. */
    METHOD PRIVATE VOID BringHeads():
        IF mHeadsToCome <= 0 THEN RETURN.
        IF mSegN = 0 THEN mHeadTimer = MINIMUM(mHeadTimer, 30).
        mHeadTimer = mHeadTimer - 1.
        IF mHeadTimer > 0 THEN RETURN.
        AddSegment(-1, CentipedeRules:PlayerTop(), 1, TRUE).
        mSegX[mSegN] = - CentipedeRules:Tile().
        mHeadsToCome = mHeadsToCome - 1.
        mHeadTimer = 180.
    END METHOD.

    /* ============================== the creatures ============================== */

    METHOD PRIVATE VOID StepFlea():
        DEFINE VARIABLE n  AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        IF NOT mFleaOn THEN DO:
            IF mSegN = 0 THEN RETURN.
            mFleaTimer = mFleaTimer - 1.
            IF mFleaTimer > 0 THEN RETURN.
            IF ZoneMushroomCount < 5 THEN SpawnFlea(mRandom:NextInt(CentipedeRules:Cols())).
            ELSE mFleaTimer = 120.
            RETURN.
        END.
        DO n = 1 TO (IF mFleaHp = 1 THEN 4 ELSE 2):
            mFleaY = mFleaY + 1.
            IF mFleaY MODULO CentipedeRules:Tile() = 0 THEN DO:
                cx = Cell(mFleaX).
                cy = Cell(mFleaY).
                IF cy >= 1 AND cy < CentipedeRules:Rows() AND Hp(cx, cy) = 0 AND NOT TouchesPlayer(cx, cy) AND mRandom:NextInt(4) = 0 THEN
                    PlaceMushroom(cx, cy, CentipedeRules:MushroomHp()).
            END.
        END.
        IF mFleaY >= CentipedeRules:BoardPixels() THEN DO:
            mFleaOn = FALSE.
            mFleaTimer = 300.
        END.
    END METHOD.

    /* A shot hits the flea: the first hit makes it quicker, the second kills it. */
    METHOD PRIVATE VOID HitFlea():
        FleaHits = FleaHits + 1.
        mFleaHp = mFleaHp - 1.
        IF mFleaHp > 0 THEN RETURN.
        FleaKills = FleaKills + 1.
        Bonus(CentipedeRules:PointsFlea(), mFleaX, mFleaY).
        mFleaOn = FALSE.
        mFleaTimer = 300.
    END METHOD.

    METHOD PRIVATE VOID StepSpider():
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        IF NOT mSpiderOn THEN DO:
            IF mSegN = 0 THEN RETURN.
            mSpiderTimer = mSpiderTimer - 1.
            IF mSpiderTimer <= 0 THEN DO:
                SpawnSpider(mRandom:NextInt(2) = 0, 20 + mRandom:NextInt(10)).
                mSpiderTimer = 900 + mRandom:NextInt(900).
            END.
            RETURN.
        END.
        mSpiderX = mSpiderX + mSpiderDx.
        mSpiderY = MINIMUM(232, MAXIMUM(160, mSpiderY + mSpiderDy)).
        mSpiderT = mSpiderT - 1.
        IF mSpiderT <= 0 THEN ASSIGN
            mSpiderDy = (mRandom:NextInt(3) - 1) * 2
            mSpiderT = 12 + mRandom:NextInt(24).
        IF mSpiderY = 160 AND mSpiderDy < 0 THEN mSpiderDy = 2.
        IF mSpiderY = 232 AND mSpiderDy > 0 THEN mSpiderDy = -2.
        /* the spider eats the mushroom under its middle */
        cx = Cell(mSpiderX + 8).
        cy = Cell(mSpiderY + 4).
        IF cx >= 0 AND cx < CentipedeRules:Cols() AND Hp(cx, cy) > 0 THEN PlaceMushroom(cx, cy, 0).
        IF (mSpiderDx > 0 AND mSpiderX >= CentipedeRules:BoardPixels()) OR (mSpiderDx < 0 AND mSpiderX <= -16) THEN mSpiderOn = FALSE.
    END METHOD.

    METHOD PRIVATE VOID KillSpider():
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        dx = ABSOLUTE(mSpiderX + 8 - (mPlayerX + 4)).
        dy = ABSOLUTE(mSpiderY + 4 - (mPlayerY + 4)).
        SpiderKills = SpiderKills + 1.
        Bonus(CentipedeRules:PointsSpider(dx + dy), mSpiderX, mSpiderY).
        mSpiderOn = FALSE.
    END METHOD.

    METHOD PRIVATE VOID StepScorpion():
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        IF NOT mScorpOn THEN DO:
            IF mSegN = 0 OR mScorpTimer < 0 THEN RETURN.
            mScorpTimer = mScorpTimer - 1.
            IF mScorpTimer <= 0 THEN DO:
                SpawnScorpion(3 + mRandom:NextInt(14), mRandom:NextInt(2) = 0).
                mScorpTimer = 900 + mRandom:NextInt(900).
            END.
            RETURN.
        END.
        mScorpX = mScorpX + mScorpDx.
        cx = Cell(mScorpX + 8).
        IF cx >= 0 AND cx < CentipedeRules:Cols() THEN PoisonMushroom(cx, Cell(mScorpY)).
        IF (mScorpDx > 0 AND mScorpX >= CentipedeRules:BoardPixels()) OR (mScorpDx < 0 AND mScorpX <= -16) THEN mScorpOn = FALSE.
    END METHOD.

    METHOD PRIVATE VOID KillScorpion():
        ScorpionKills = ScorpionKills + 1.
        Bonus(CentipedeRules:PointsScorpion(), mScorpX, mScorpY).
        mScorpOn = FALSE.
    END METHOD.

    /* Points for a creature, kept with where and when for a pop-up. */
    METHOD PRIVATE VOID Bonus(INPUT piPoints AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        ASSIGN LastBonus = piPoints
               LastBonusX = piX
               LastBonusY = piY
               LastBonusFrame = Frames.
        AddScore(piPoints).
    END METHOD.

    /* ============================== lives and waves ============================== */

    /* True when the centipede, the flea or the spider touches the shooter. */
    METHOD PRIVATE LOGICAL PlayerTouched():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mSegN:
            IF Overlaps(mPlayerX + 1, mPlayerY + 1, 6, 6, mSegX[i], mSegY[i], 8, 8) THEN RETURN TRUE.
        END.
        IF mFleaOn AND Overlaps(mPlayerX + 1, mPlayerY + 1, 6, 6, mFleaX, mFleaY, 8, 8) THEN RETURN TRUE.
        IF mSpiderOn AND Overlaps(mPlayerX + 1, mPlayerY + 1, 6, 6, mSpiderX, mSpiderY, 16, 8) THEN RETURN TRUE.
        RETURN FALSE.
    END METHOD.

    /* The shooter is hit and breaks up. */
    METHOD PRIVATE VOID Die():
        Lives = Lives - 1.
        Deaths = Deaths + 1.
        mShotOn = FALSE.
        SetPhase(GamePhase:Dying).
    END METHOD.

    /* The breaking up is over: the game ends, or the field is mended and the wave starts again. */
    METHOD PRIVATE VOID AfterDeath():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF Lives <= 0 THEN DO:
            mFireReady = FALSE.
            SetPhase(GamePhase:GameOver).
            RETURN.
        END.
        DO i = 0 TO Grid:CellCount - 1:
            IF Grid:Store:GetCellAt({&HP-LAYER}, i) > 0 AND (Grid:Store:GetCellAt({&HP-LAYER}, i) < CentipedeRules:MushroomHp() OR Grid:Store:GetCellAt({&POISON-LAYER}, i) > 0) THEN DO:
                Grid:Store:SetCellAt({&HP-LAYER}, i, CentipedeRules:MushroomHp()).
                Grid:Store:SetCellAt({&POISON-LAYER}, i, 0).
                AddScore(CentipedeRules:PointsRepair()).
            END.
        END.
        FieldVersion = FieldVersion + 1.
        ClearCreatures().
        PlacePlayer(112, 224).
        StartWave().
        SetPhase(GamePhase:Playing).
    END METHOD.

    /* The last segment is gone. */
    METHOD PRIVATE VOID WaveDone():
        WavesCleared = WavesCleared + 1.
        mShotOn = FALSE.
        mFleaOn = FALSE.
        mSpiderOn = FALSE.
        mScorpOn = FALSE.
        SetPhase(GamePhase:Cleared).
    END METHOD.

    METHOD PRIVATE VOID NextWave():
        Wave = Wave + 1.
        mNotice = SUBSTITUTE("Wave &1", Wave).
        ClearCreatures().
        StartWave().
        SetPhase(GamePhase:Playing).
    END METHOD.

    /* Adds points, raises the best score and gives an extra shooter at each multiple of 12000. The game calls it for everything shot;
       it is public so that a scripted scene can reach a score without playing for it. Throws GridException for fewer than 0 points. */
    METHOD PUBLIC VOID AddScore(INPUT piPoints AS INTEGER):
        IF piPoints = ? OR piPoints < 0 THEN UNDO, THROW NEW GridException("Points are 0 or more, not " + STRING(piPoints)).
        Score = Score + piPoints.
        IF Score > HiScore THEN HiScore = Score.
        DO WHILE Score >= mNextExtra AND mNextExtra > 0:
            Lives = Lives + 1.
            ExtraLives = ExtraLives + 1.
            mNextExtra = mNextExtra + CentipedeRules:ExtraLifeEvery().
            mNotice = "Extra shooter".
        END.
    END METHOD.

    /* ============================== small helpers ============================== */

    /* The tile a pixel is in. */
    METHOD PRIVATE INTEGER Cell(INPUT piPixel AS INTEGER):
        RETURN INTEGER(TRUNCATE(piPixel / CentipedeRules:Tile(), 0)).
    END METHOD.

    /* Hit points of a mushroom, 0 for none and for a tile off the board. */
    METHOD PRIVATE INTEGER Hp(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= CentipedeRules:Cols() OR piY < 0 OR piY >= CentipedeRules:Rows() THEN RETURN 0.
        RETURN Grid:Store:GetCellAt({&HP-LAYER}, piY * CentipedeRules:Cols() + piX).
    END METHOD.

    METHOD PRIVATE LOGICAL Poison(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= CentipedeRules:Cols() OR piY < 0 OR piY >= CentipedeRules:Rows() THEN RETURN FALSE.
        RETURN Grid:Store:GetCellAt({&POISON-LAYER}, piY * CentipedeRules:Cols() + piX) > 0.
    END METHOD.

    /* True when the shooter's box overlaps a tile. */
    METHOD PRIVATE LOGICAL TouchesPlayer(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Overlaps(mPlayerX + 1, mPlayerY + 1, 6, 6, piX * CentipedeRules:Tile(), piY * CentipedeRules:Tile(), 8, 8).
    END METHOD.

    /* Mushrooms in the rows from piFromRow down. */
    METHOD PRIVATE INTEGER CountMushrooms(INPUT piFromRow AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = piFromRow * CentipedeRules:Cols() TO Grid:CellCount - 1:
            IF Grid:Store:GetCellAt({&HP-LAYER}, i) > 0 THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    METHOD PRIVATE LOGICAL Overlaps(INPUT piAX AS INTEGER, INPUT piAY AS INTEGER, INPUT piAW AS INTEGER, INPUT piAH AS INTEGER,
                                    INPUT piBX AS INTEGER, INPUT piBY AS INTEGER, INPUT piBW AS INTEGER, INPUT piBH AS INTEGER):
        RETURN piAX < piBX + piBW AND piBX < piAX + piAW AND piAY < piBY + piBH AND piBY < piAY + piAH.
    END METHOD.

    METHOD PRIVATE VOID CheckTile(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX = ? OR piY = ? OR piX < 0 OR piX >= CentipedeRules:Cols() OR piY < 0 OR piY >= CentipedeRules:Rows() THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Tile &1, &2 is not on the board", piX, piY)).
    END METHOD.

    METHOD PRIVATE VOID CheckSegment(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= mSegN THEN UNDO, THROW NEW GridException(SUBSTITUTE("The centipede has segments 0 to &1, not &2", mSegN - 1, piIndex)).
    END METHOD.

END CLASS.
