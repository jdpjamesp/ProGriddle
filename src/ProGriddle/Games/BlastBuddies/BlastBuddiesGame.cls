/* Blast Buddies: a turn based artillery game on destructible ground, run by a real time controller. The game keeps its own time: Tick adds
   up the time it is given and makes a frame for every sixtieth of a second (at the speed chosen), so a test drives it frame by frame with
   Advance. Teams of buddies take turns in order; the buddy in turn walks, aims and fires against the turn clock.

   The phases are in BuddyPhase: Arrival (a few seconds), then for each turn Banner, Turn (and Retreat after a shot), Resolve (everything
   falls and settles), and at the end Winner or Draw. Buddies are moved by BuddyPhysics every frame whatever the phase. The wind is a whole
   number from minus 10 to 10, rolled at the start of each turn. The game owns its grid and its terrain. Dispose releases them. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BlastBuddiesGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    /* the most frames one Tick will make, and the most time it will count: a stall must not make a burst */
    &SCOPED-DEFINE MOST-FRAMES 4
    &SCOPED-DEFINE MOST-MS 100

    DEFINE PRIVATE VARIABLE mRandom  AS IRandom        NO-UNDO.
    DEFINE PRIVATE VARIABLE mSetup   AS BuddySetup     NO-UNDO.
    DEFINE PRIVATE VARIABLE mPhysics AS BuddyPhysics   NO-UNDO.
    DEFINE PRIVATE VARIABLE mTerrain AS Terrain        NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlan    AS TurnPlan       NO-UNDO.
    DEFINE PRIVATE VARIABLE mAcc     AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mTimer   AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettle  AS INTEGER        NO-UNDO.

    /* True while the game is stopped: the clock and the moves do nothing. */
    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO GET. SET.

    /* How fast time runs as a percentage of the real 60 frames a second. */
    DEFINE PUBLIC PROPERTY SpeedPercent AS INTEGER NO-UNDO INITIAL 100 GET. SET.

    DEFINE PUBLIC PROPERTY Phase AS BuddyPhase NO-UNDO GET. PRIVATE SET.

    /* Frames made since the game started. */
    DEFINE PUBLIC PROPERTY FrameCount AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* The wind of this turn, from minus 10 (blowing left) to 10 (blowing right). */
    DEFINE PUBLIC PROPERTY Wind AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* The buddy whose turn it is, or unknown before the first turn. */
    DEFINE PUBLIC PROPERTY CurrentBuddy AS Buddy NO-UNDO GET. PRIVATE SET.

    /* The team that won (1 to 4) in the Winner phase, else 0. */
    DEFINE PUBLIC PROPERTY WinnerTeam AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* The order of play, with the teams. */
    DEFINE PUBLIC PROPERTY Plan AS TurnPlan NO-UNDO
        GET():
            RETURN mPlan.
        END GET.

    /* The ground. */
    DEFINE PUBLIC PROPERTY Land AS Terrain NO-UNDO
        GET():
            RETURN mTerrain.
        END GET.

    DEFINE PUBLIC PROPERTY Setup AS BuddySetup NO-UNDO
        GET():
            RETURN mSetup.
        END GET.

    /* Milliseconds left of the phase clock (the turn clock in the Turn phase). */
    DEFINE PUBLIC PROPERTY TimeLeftMs AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(MAXIMUM(mTimer, 0) * 1000 / 60, 0)).
        END GET.

    CONSTRUCTOR PUBLIC BlastBuddiesGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom, INPUT poSetup AS BuddySetup):
        SUPER("Blast Buddies", poGrid).
        IF poGrid:Width <> Terrain:Width() OR poGrid:Height <> Terrain:Height() THEN
            UNDO, THROW NEW GridException("A Blast Buddies grid is " + STRING(Terrain:Width()) + " x " + STRING(Terrain:Height())).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Blast Buddies game needs a random source").
        IF NOT VALID-OBJECT(poSetup) THEN UNDO, THROW NEW GridException("A Blast Buddies game needs a setup").
        mRandom = poRandom.
        mSetup = poSetup.
        mPhysics = NEW BuddyPhysics().
        Initialise().
    END CONSTRUCTOR.

    /* Moves time on by piElapsedMs milliseconds and makes the frames that are due at the speed, up to 4. Returns true when a frame was
       made. Does nothing while Paused. */
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
        RETURN made > 0.
    END METHOD.

    /* One sixtieth of a second of the game. Does nothing while Paused. */
    METHOD PUBLIC VOID Advance():
        IF Paused THEN RETURN.
        Step().
    END METHOD.

    /* Ends the turn of the buddy in play, from the Turn or Retreat phase: everything now settles (Resolve). */
    METHOD PUBLIC VOID EndTurn():
        IF Phase <> BuddyPhase:Turn AND Phase <> BuddyPhase:Retreat THEN UNDO, THROW NEW GridException("There is no turn to end in the phase " + STRING(Phase)).
        Phase = BuddyPhase:Resolve.
        mSettle = 0.
    END METHOD.

    /* After a shot the buddy has the retreat time to get away; then the turn ends. Only from the Turn phase. */
    METHOD PUBLIC VOID BeginRetreat():
        IF Phase <> BuddyPhase:Turn THEN UNDO, THROW NEW GridException("A retreat follows a shot in the Turn phase, not " + STRING(Phase)).
        Phase = BuddyPhase:Retreat.
        mTimer = BuddyRules:RetreatFrames().
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID Dispose():
        IF VALID-OBJECT(mTerrain) THEN mTerrain:Dispose().
        SUPER:Dispose().
    END METHOD.

    /* A new game: new land, new buddies, the arrival. */
    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        DEFINE VARIABLE total  AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER NO-UNDO.
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE tmp    AS INTEGER NO-UNDO.
        DEFINE VARIABLE xs     AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys     AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE order  AS INTEGER NO-UNDO EXTENT 24.
        DEFINE VARIABLE gen    AS TerrainGenerator NO-UNDO.
        DEFINE VARIABLE team   AS Team    NO-UNDO.
        DEFINE VARIABLE buddy  AS Buddy   NO-UNDO.
        DEFINE VARIABLE teams  AS Team    NO-UNDO EXTENT 4.
        IF VALID-OBJECT(mTerrain) THEN mTerrain:Dispose().
        mTerrain = NEW Terrain(mSetup:LandTheme).
        gen = NEW TerrainGenerator().
        gen:Generate(mTerrain, mRandom).
        total = mSetup:Teams * mSetup:BuddiesEach.
        gen:FindSpots(mTerrain, mRandom, total, 14, OUTPUT xs, OUTPUT ys).
        /* the names are dealt from a shuffled list */
        DO i = 1 TO BuddyNames:Count():
            order[i] = i.
        END.
        DO i = BuddyNames:Count() TO 2 BY -1:
            j = mRandom:NextInt(i) + 1.
            tmp = order[i].
            order[i] = order[j].
            order[j] = tmp.
        END.
        mPlan = NEW TurnPlan().
        DO i = 1 TO mSetup:Teams:
            teams[i] = NEW Team(i, i > mSetup:Teams - mSetup:ComputerTeams).
            mPlan:Add(teams[i]).
        END.
        DO k = 1 TO total:
            i = ((k - 1) MODULO mSetup:Teams) + 1.
            buddy = NEW Buddy(BuddyNames:NameAt(order[k]), i, xs[k], ys[k]).
            buddy:Facing = (IF xs[k] < Terrain:Width() / 2 THEN 1 ELSE -1).
            teams[i]:Add(buddy).
        END.
        mAcc = 0.
        mSettle = 0.
        FrameCount = 0.
        Wind = 0.
        WinnerTeam = 0.
        CurrentBuddy = ?.
        Paused = FALSE.
        Phase = BuddyPhase:Arrival.
        mTimer = BuddyRules:ArrivalFrames().
    END METHOD.

    /* One frame: every buddy moves under physics, and the phase clock runs. */
    METHOD PRIVATE VOID Step():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        FrameCount = FrameCount + 1.
        DO i = 1 TO mPlan:TeamCount():
            DO j = 1 TO mPlan:TeamAt(i):Count():
                mPhysics:Step(mPlan:TeamAt(i):BuddyAt(j), mTerrain).
            END.
        END.
        CASE Phase:
            WHEN BuddyPhase:Arrival OR WHEN BuddyPhase:Banner OR WHEN BuddyPhase:Turn OR WHEN BuddyPhase:Retreat THEN DO:
                mTimer = mTimer - 1.
                IF mTimer <= 0 THEN PhaseEnded().
            END.
            WHEN BuddyPhase:Resolve THEN DO:
                IF AnyoneInTheAir() THEN mSettle = 0.
                ELSE mSettle = mSettle + 1.
                IF mSettle >= BuddyRules:SettleFrames() THEN BeginBanner().
            END.
            OTHERWISE.
        END CASE.
    END METHOD.

    /* The clock of the phase has run out. */
    METHOD PRIVATE VOID PhaseEnded():
        CASE Phase:
            WHEN BuddyPhase:Arrival THEN BeginBanner().
            WHEN BuddyPhase:Banner THEN DO:
                Phase = BuddyPhase:Turn.
                mTimer = BuddyRules:TurnFrames().
            END.
            OTHERWISE EndTurn().
        END CASE.
    END METHOD.

    /* Starts the next turn's banner with the next buddy and the wind, or ends the game if one team or none is left. */
    METHOD PRIVATE VOID BeginBanner():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        CASE mPlan:TeamsAlive():
            WHEN 0 THEN DO:
                Phase = BuddyPhase:Draw.
                IsOver = TRUE.
            END.
            WHEN 1 THEN DO:
                DO i = 1 TO mPlan:TeamCount():
                    IF mPlan:TeamAt(i):AliveCount() > 0 THEN WinnerTeam = mPlan:TeamAt(i):Number.
                END.
                Phase = BuddyPhase:Winner.
                IsOver = TRUE.
            END.
            OTHERWISE DO:
                CurrentBuddy = mPlan:NextBuddy().
                Wind = mRandom:NextInt(2 * BuddyRules:WindMax() + 1) - BuddyRules:WindMax().
                Generation = Generation + 1.
                Phase = BuddyPhase:Banner.
                mTimer = BuddyRules:BannerFrames().
            END.
        END CASE.
    END METHOD.

    /* Whether any living buddy is off the ground. */
    METHOD PRIVATE LOGICAL AnyoneInTheAir():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DO i = 1 TO mPlan:TeamCount():
            DO j = 1 TO mPlan:TeamAt(i):Count():
                IF mPlan:TeamAt(i):BuddyAt(j):State = BuddyState:Airborne THEN RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

END CLASS.
