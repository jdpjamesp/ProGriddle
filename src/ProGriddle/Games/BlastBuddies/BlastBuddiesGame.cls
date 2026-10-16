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
    DEFINE PRIVATE VARIABLE mShells  AS ShellPool      NO-UNDO.
    DEFINE PRIVATE VARIABLE mExplosion AS Explosion    NO-UNDO.
    DEFINE PRIVATE VARIABLE mDeathT  AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mBrain   AS IBuddyBrain    NO-UNDO.
    DEFINE PRIVATE VARIABLE mWalkAcc AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mAimAcc  AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mJumpAt  AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mJumpWas AS INTEGER        NO-UNDO.

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

    /* The time the game has run, from its own clock of 60 frames a second: what the pictures that move on their own are functions of. */
    DEFINE PUBLIC PROPERTY ElapsedMs AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(FrameCount * 1000 / 60, 0)).
        END GET.

    /* Counts up with every new map, so the painter knows to start again. */
    DEFINE PUBLIC PROPERTY MapSerial AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* How many blasts there have been, where the last one was (the pixel and the radius), and how many shells have fallen in the water. */
    DEFINE PUBLIC PROPERTY BlastCount AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY LastBlastX AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY LastBlastY AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY LastBlastRadius AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY WaterHits AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* The shells in the air, for the painter and the sound. */
    DEFINE PUBLIC PROPERTY Shells AS ShellPool NO-UNDO
        GET():
            RETURN mShells.
        END GET.

    /* What the last blast hurt (for the damage numbers). */
    DEFINE PUBLIC PROPERTY LastBlast AS Explosion NO-UNDO
        GET():
            RETURN mExplosion.
        END GET.

    /* The buddy being shown dying now, in the Resolve phase, or unknown. Buddies die one at a time, team 1 first. */
    DEFINE PUBLIC PROPERTY DyingBuddy AS Buddy NO-UNDO GET. PRIVATE SET.

    /* How many buddies have died and been buried so far. */
    DEFINE PUBLIC PROPERTY DeathCount AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* How far through its death the dying buddy is, 0 to 100 percent. */
    DEFINE PUBLIC PROPERTY DeathPercent AS INTEGER NO-UNDO
        GET():
            IF NOT VALID-OBJECT(DyingBuddy) THEN RETURN 0.
            RETURN 100 - INTEGER(TRUNCATE(mDeathT * 100 / BuddyRules:DeathFrames(), 0)).
        END GET.

    /* The way the buddy in turn is being walked, -1 for left, 1 for right, 0 for not at all (see SetWalk). */
    DEFINE PUBLIC PROPERTY WalkDirection AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* The way the aim is being moved: -1 raises it, 1 lowers it, 0 leaves it. */
    DEFINE PUBLIC PROPERTY AimDirection AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* The aim of the buddy in turn: steps from straight up (0), through level (16), to straight down (32), on the side it faces. */
    DEFINE PUBLIC PROPERTY Aim AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* True while the fire key is held, building up power. */
    DEFINE PUBLIC PROPERTY Charging AS LOGICAL NO-UNDO GET. PRIVATE SET.

    /* Frames the fire key has been held, 0 to 90. */
    DEFINE PUBLIC PROPERTY Charge AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* How many shots have been fired, and the power (percent) of the last one. */
    DEFINE PUBLIC PROPERTY ShotsFired AS INTEGER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY LastPower AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* The power now, 0 to 100 percent of the charge. */
    DEFINE PUBLIC PROPERTY PowerPercent AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(MINIMUM(Charge, BuddyRules:ChargeFrames()) * 100 / BuddyRules:ChargeFrames(), 0)).
        END GET.

    /* The aim as one of the 64 headings of Heading (0 up, 16 right, 32 down, 48 left), taking the way the buddy faces into account. */
    DEFINE PUBLIC PROPERTY AimHeading AS INTEGER NO-UNDO
        GET():
            IF NOT VALID-OBJECT(CurrentBuddy) THEN RETURN 0.
            RETURN (IF CurrentBuddy:Facing >= 0 THEN Aim ELSE Heading:Wrap(64 - Aim)).
        END GET.

    /* True when a person controls the buddy in turn: the turn is on and the team is not played by the computer. */
    DEFINE PUBLIC PROPERTY HumanTurn AS LOGICAL NO-UNDO
        GET():
            RETURN VALID-OBJECT(CurrentBuddy) AND (Phase = BuddyPhase:Turn OR Phase = BuddyPhase:Retreat)
                   AND NOT mPlan:TeamAt(CurrentBuddy:Team):IsComputer.
        END GET.

    /* The computer player that plays the teams the computer plays, or unknown for a game of people only. */
    DEFINE PUBLIC PROPERTY Brain AS IBuddyBrain NO-UNDO
        GET():
            RETURN mBrain.
        END GET.
        SET(INPUT poBrain AS IBuddyBrain):
            mBrain = poBrain.
        END SET.

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
        mShells = NEW ShellPool().
        mExplosion = NEW Explosion().
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

    /* Walks the buddy in turn in a direction (-1, 0, 1) for as long as it is set: one pixel every 40 ms. Works in the Turn and Retreat
       phases. The window leaves it alone on a computer team (see HumanTurn), and the computer calls it itself. */
    METHOD PUBLIC VOID SetWalk(INPUT piDirection AS INTEGER):
        IF piDirection < -1 OR piDirection > 1 THEN UNDO, THROW NEW GridException("A walk direction is -1, 0 or 1").
        WalkDirection = piDirection.
        IF piDirection = 0 THEN mWalkAcc = 0.
    END METHOD.

    /* Moves the aim for as long as it is set: -1 raises it, 1 lowers it, 0 stops. */
    METHOD PUBLIC VOID SetAim(INPUT piDirection AS INTEGER):
        IF piDirection < -1 OR piDirection > 1 THEN UNDO, THROW NEW GridException("An aim direction is -1, 0 or 1").
        AimDirection = piDirection.
        IF piDirection = 0 THEN mAimAcc = 0.
    END METHOD.

    /* The fire key went down: power builds up while it is held. Only in the Turn phase, before a shot. */
    METHOD PUBLIC VOID StartCharge():
        IF Phase <> BuddyPhase:Turn OR Paused OR Charging THEN RETURN.
        Charging = TRUE.
        Charge = 0.
    END METHOD.

    /* The fire key came up: the shot goes with the power built up so far. Does nothing if no charge was started. */
    METHOD PUBLIC VOID ReleaseCharge():
        IF NOT Charging OR Paused THEN RETURN.
        FireShot().
    END METHOD.

    /* Turns the buddy in turn to face a way (-1 or 1), if it is standing. The computer uses it, a person turns by walking. */
    METHOD PUBLIC VOID Face(INPUT piDirection AS INTEGER):
        IF piDirection <> -1 AND piDirection <> 1 THEN UNDO, THROW NEW GridException("A direction is -1 or 1, not " + STRING(piDirection)).
        IF NOT (Phase = BuddyPhase:Turn OR Phase = BuddyPhase:Retreat) OR NOT VALID-OBJECT(CurrentBuddy) THEN RETURN.
        IF CurrentBuddy:State = BuddyState:Standing THEN CurrentBuddy:Facing = piDirection.
    END METHOD.

    /* The jump key: a hop the way the buddy faces; a second press within 250 ms turns it into a backflip. */
    METHOD PUBLIC VOID Jump():
        IF Paused OR (Phase <> BuddyPhase:Turn AND Phase <> BuddyPhase:Retreat) OR NOT VALID-OBJECT(CurrentBuddy) THEN RETURN.
        IF CurrentBuddy:IsDead() THEN RETURN.
        IF mJumpWas = 1 AND FrameCount - mJumpAt <= BuddyRules:DoubleJumpFrames() AND CurrentBuddy:State = BuddyState:Airborne THEN DO:
            mPhysics:Launch(CurrentBuddy, - CurrentBuddy:Facing * BuddyRules:FlipBack(), - BuddyRules:FlipLift()).
            mJumpWas = 2.
            RETURN.
        END.
        IF mPhysics:Hop(CurrentBuddy) THEN DO:
            mJumpWas = 1.
            mJumpAt = FrameCount.
        END.
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
        MapSerial = MapSerial + 1.
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
        mWalkAcc = 0.
        mAimAcc = 0.
        mJumpWas = 0.
        mShells:Clear().
        DyingBuddy = ?.
        DeathCount = 0.
        mDeathT = 0.
        BlastCount = 0.
        LastBlastX = 0.
        LastBlastY = 0.
        LastBlastRadius = 0.
        WaterHits = 0.
        WalkDirection = 0.
        AimDirection = 0.
        Charging = FALSE.
        Charge = 0.
        ShotsFired = 0.
        LastPower = 0.
        Aim = BuddyRules:AimStart().
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
        IF Phase = BuddyPhase:Turn AND VALID-OBJECT(mBrain) AND VALID-OBJECT(CurrentBuddy) THEN DO:
            IF mPlan:TeamAt(CurrentBuddy:Team):IsComputer AND NOT CurrentBuddy:IsDead() THEN mBrain:Drive(THIS-OBJECT).
        END.
        ApplyControls().
        StepShells().
        IF (Phase = BuddyPhase:Turn OR Phase = BuddyPhase:Retreat) AND VALID-OBJECT(CurrentBuddy) THEN DO:
            /* the buddy in turn has died, perhaps by its own rocket: the turn is over */
            IF CurrentBuddy:IsDead() AND mShells:Count() = 0 THEN EndTurn().
        END.
        CASE Phase:
            WHEN BuddyPhase:Arrival OR WHEN BuddyPhase:Banner OR WHEN BuddyPhase:Turn OR WHEN BuddyPhase:Retreat THEN DO:
                mTimer = mTimer - 1.
                IF mTimer <= 0 THEN PhaseEnded().
            END.
            WHEN BuddyPhase:Resolve THEN DO:
                IF VALID-OBJECT(DyingBuddy) THEN BuryTheDying().
                ELSE DO:
                    IF AnyoneInTheAir() OR mShells:Count() > 0 THEN mSettle = 0.
                    ELSE mSettle = mSettle + 1.
                    IF mSettle >= BuddyRules:SettleFrames() THEN NextDeathOrBanner().
                END.
            END.
            OTHERWISE.
        END CASE.
    END METHOD.

    /* What the player has asked of the buddy in turn this frame: a pixel walked, a step of aim, power built up. */
    METHOD PRIVATE VOID ApplyControls():
        IF NOT (Phase = BuddyPhase:Turn OR Phase = BuddyPhase:Retreat) THEN DO:
            mWalkAcc = 0.
            Charging = FALSE.
            RETURN.
        END.
        IF NOT VALID-OBJECT(CurrentBuddy) OR CurrentBuddy:IsDead() THEN RETURN.
        IF WalkDirection <> 0 AND CurrentBuddy:State = BuddyState:Standing THEN DO:
            mWalkAcc = mWalkAcc + BuddyRules:WalkGain().
            IF mWalkAcc >= BuddyRules:WalkNeeded() THEN DO:
                mWalkAcc = mWalkAcc - BuddyRules:WalkNeeded().
                mPhysics:Walk(CurrentBuddy, mTerrain, WalkDirection).
            END.
        END.
        IF Phase <> BuddyPhase:Turn THEN RETURN.
        IF AimDirection <> 0 THEN DO:
            mAimAcc = mAimAcc + 1.
            IF mAimAcc >= BuddyRules:AimRepeatFrames() THEN DO:
                mAimAcc = 0.
                Aim = MAXIMUM(0, MINIMUM(32, Aim + AimDirection)).
            END.
        END.
        IF Charging THEN DO:
            Charge = Charge + 1.
            IF Charge >= BuddyRules:ChargeFrames() THEN FireShot().
        END.
    END METHOD.

    /* The shot goes, with the power built up: a bazooka rocket leaves the muzzle, 6 pixels from the buddy along the aim, at a speed that
       grows with the power, and the retreat begins. */
    METHOD PRIVATE VOID FireShot():
        DEFINE VARIABLE aimStep AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed   AS INTEGER NO-UNDO.
        LastPower = PowerPercent.
        ShotsFired = ShotsFired + 1.
        Charging = FALSE.
        Charge = 0.
        aimStep = AimHeading.
        speed = BuddyRules:ShotSpeedMin() + INTEGER(TRUNCATE((BuddyRules:ShotSpeedMax() - BuddyRules:ShotSpeedMin()) * LastPower / 100, 0)).
        mShells:Launch(WeaponKind:Bazooka, CurrentBuddy:Team,
                       CurrentBuddy:X256 + INTEGER(TRUNCATE(Heading:DirX(aimStep) * 3 / 2, 0)),
                       CurrentBuddy:Y256 - 6 * 256 + INTEGER(TRUNCATE(Heading:DirY(aimStep) * 3 / 2, 0)),
                       INTEGER(TRUNCATE(Heading:DirX(aimStep) * speed / Heading:Scale(), 0)),
                       INTEGER(TRUNCATE(Heading:DirY(aimStep) * speed / Heading:Scale(), 0))).
        BeginRetreat().
    END METHOD.

    /* One frame of flight for every shell: gravity and the wind bend its path, and it is moved a pixel at a time so nothing is skipped
       over. It blows up on ground or on a buddy, and is gone in the water or past the sides of the map. */
    METHOD PRIVATE VOID StepShells():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO ShellPool:Capacity():
            IF mShells:Active(i) THEN StepShell(i).
        END.
    END METHOD.

    METHOD PRIVATE VOID StepShell(INPUT piSlot AS INTEGER):
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE vx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE vy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER NO-UNDO.
        DEFINE VARIABLE k     AS INTEGER NO-UNDO.
        DEFINE VARIABLE px    AS INTEGER NO-UNDO.
        DEFINE VARIABLE py    AS INTEGER NO-UNDO.
        DEFINE VARIABLE age   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x0    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y0    AS INTEGER NO-UNDO.
        mShells:Grow(piSlot).
        age = mShells:Age(piSlot).
        vx = mShells:VX(piSlot) + Wind.
        vy = mShells:VY(piSlot) + BuddyRules:Gravity().
        x0 = mShells:X(piSlot).
        y0 = mShells:Y(piSlot).
        x = x0.
        y = y0.
        n = INTEGER(TRUNCATE(MAXIMUM(ABSOLUTE(vx), ABSOLUTE(vy)) / 256, 0)) + 1.
        DO k = 1 TO n:
            x = x0 + INTEGER(TRUNCATE(vx * k / n, 0)).
            y = y0 + INTEGER(TRUNCATE(vy * k / n, 0)).
            px = BuddyRules:Pixel(x).
            py = BuddyRules:Pixel(y).
            IF px < 0 OR px >= Terrain:Width() OR age > BuddyRules:ShotMaxFrames() THEN DO:
                mShells:Release(piSlot).
                RETURN.
            END.
            IF py >= BuddyRules:WaterRow() THEN DO:
                WaterHits = WaterHits + 1.
                mShells:Release(piSlot).
                RETURN.
            END.
            IF mTerrain:IsSolid(px, py) OR ShellHitsBuddy(piSlot, px, py) THEN DO:
                mShells:Release(piSlot).
                Detonate(px, py, BuddyRules:BazookaRadius(), BuddyRules:BazookaDamage()).
                RETURN.
            END.
        END.
        mShells:Move(piSlot, x, y, vx, vy).
    END METHOD.

    /* Whether a shell at a pixel is inside a buddy that is not out of it: a buddy standing or flying, living or not. The buddy that fired it
       is safe for the first few frames, while the shell leaves it. */
    METHOD PRIVATE LOGICAL ShellHitsBuddy(INPUT piSlot AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS Buddy   NO-UNDO.
        DO i = 1 TO mPlan:TeamCount():
            DO j = 1 TO mPlan:TeamAt(i):Count():
                b = mPlan:TeamAt(i):BuddyAt(j).
                IF b:IsDead() THEN NEXT.
                IF b = CurrentBuddy AND mShells:Age(piSlot) <= BuddyRules:ShotSafeFrames() THEN NEXT.
                IF ABSOLUTE(piX - b:X()) <= 4 AND piY >= b:Y() - BuddyRules:BuddyHeight() AND piY < b:Y() THEN RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* A blast: the hole, the damage, the throwing, and the counts and place that the painter and the sound read. */
    METHOD PRIVATE VOID Detonate(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piRadius AS INTEGER, INPUT piDamage AS INTEGER):
        mExplosion:Detonate(mTerrain, mPlan, mPhysics, piX, piY, piRadius, piDamage).
        BlastCount = BlastCount + 1.
        LastBlastX = piX.
        LastBlastY = piY.
        LastBlastRadius = piRadius.
    END METHOD.

    /* The clock of the phase has run out. */
    METHOD PRIVATE VOID PhaseEnded():
        CASE Phase:
            WHEN BuddyPhase:Arrival THEN BeginBanner().
            WHEN BuddyPhase:Banner THEN DO:
                Phase = BuddyPhase:Turn.
                mTimer = BuddyRules:TurnFrames().
                IF VALID-OBJECT(mBrain) THEN mBrain:Reset().
                WalkDirection = 0.
                AimDirection = 0.
            END.
            OTHERWISE EndTurn().
        END CASE.
    END METHOD.

    /* Everything is still: the next buddy that has died is shown dying, or if there is none the next turn begins. */
    METHOD PRIVATE VOID NextDeathOrBanner():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS Buddy   NO-UNDO.
        DO i = 1 TO mPlan:TeamCount():
            DO j = 1 TO mPlan:TeamAt(i):Count():
                b = mPlan:TeamAt(i):BuddyAt(j).
                IF b:IsDead() AND NOT b:Buried THEN DO:
                    DyingBuddy = b.
                    mDeathT = BuddyRules:DeathFrames().
                    RETURN.
                END.
            END.
        END.
        BeginBanner().
    END METHOD.

    /* Counts down the death being shown; at the end the buddy is buried and everything is looked at again. */
    METHOD PRIVATE VOID BuryTheDying():
        mDeathT = mDeathT - 1.
        IF mDeathT > 0 THEN RETURN.
        DyingBuddy:Buried = TRUE.
        DyingBuddy = ?.
        DeathCount = DeathCount + 1.
        mSettle = 0.
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
                Aim = BuddyRules:AimStart().
                mJumpWas = 0.
                WalkDirection = 0.
                AimDirection = 0.
                mWalkAcc = 0.
                mAimAcc = 0.
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
