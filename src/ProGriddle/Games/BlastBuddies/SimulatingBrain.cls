/* The computer player of Blast Buddies. At the start of its turn it tries shots: from where it stands and from a few places it could walk to,
   at the nearest enemies, over a ladder of aims and powers, flying each one through the ground with a ShotSimulator and scoring the blast
   where it lands (the damage to the enemy, with a bonus for a kill, less the damage to its own team and itself). It does a few flights every
   frame, never more, so the window never waits, and it shows the thought bubble for at least a second. Then it walks to the place, aims,
   charges and fires with the same controls a person has. The skill is the size of the mistake it makes in the aim and the power it picks:
   none on Hard (which also looks closer round the best shot), a little on Normal and a lot on Easy. All its choices come from the
   random source it is given, so a seeded game plays the same every time. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.SimulatingBrain FINAL IMPLEMENTS IBuddyBrain:

    /* places to shoot from (the first is where it stands) and enemies to shoot at */
    &SCOPED-DEFINE CANDIDATES 5
    &SCOPED-DEFINE TARGETS 2
    /* the fewest frames it thinks for, so the bubble can be seen */
    &SCOPED-DEFINE LEAST-THOUGHT 60

    DEFINE PRIVATE VARIABLE mRandom  AS IRandom        NO-UNDO.
    DEFINE PRIVATE VARIABLE mSkill   AS BuddySkill     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSim     AS ShotSimulator  NO-UNDO.
    DEFINE PRIVATE VARIABLE mPhysics AS BuddyPhysics   NO-UNDO.
    DEFINE PRIVATE VARIABLE mFrames  AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mCandX   AS INTEGER        NO-UNDO EXTENT {&CANDIDATES}.
    DEFINE PRIVATE VARIABLE mCandY   AS INTEGER        NO-UNDO EXTENT {&CANDIDATES}.
    DEFINE PRIVATE VARIABLE mCands   AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mTgtX    AS INTEGER        NO-UNDO EXTENT {&TARGETS}.
    DEFINE PRIVATE VARIABLE mTargets AS INTEGER        NO-UNDO.
    /* where the ladder of tries has got to: place, target, aim and power */
    DEFINE PRIVATE VARIABLE mCi      AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mTi      AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mEi      AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mPi      AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mRefine  AS INTEGER        NO-UNDO.
    DEFINE PRIVATE VARIABLE mScanned AS LOGICAL        NO-UNDO.
    /* the best try so far */
    DEFINE PRIVATE VARIABLE mBestScore AS INTEGER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mBestCand  AS INTEGER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mBestFace  AS INTEGER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mBestElev  AS INTEGER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mBestPower AS INTEGER      NO-UNDO.
    /* what it has decided to do */
    DEFINE PRIVATE VARIABLE mGoalX     AS INTEGER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mGoalFace  AS INTEGER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mGoalElev  AS INTEGER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mGoalPower AS INTEGER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mLastX     AS INTEGER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mStuck     AS INTEGER      NO-UNDO.

    DEFINE PUBLIC PROPERTY Stage AS BrainStage NO-UNDO GET. PRIVATE SET.

    DEFINE PUBLIC PROPERTY Thinking AS LOGICAL NO-UNDO
        GET():
            RETURN Stage = BrainStage:Thinking.
        END GET.

    /* How many flights it has tried so far this game. */
    DEFINE PUBLIC PROPERTY Flights AS INTEGER NO-UNDO
        GET():
            RETURN mSim:Flights.
        END GET.

    /* The decision, once it has made it: where to stand (a column), which way to face (-1 or 1), the aim (0 up to 32 down) and the power in percent. */
    DEFINE PUBLIC PROPERTY GoalX AS INTEGER NO-UNDO
        GET():
            RETURN mGoalX.
        END GET.

    DEFINE PUBLIC PROPERTY GoalFacing AS INTEGER NO-UNDO
        GET():
            RETURN mGoalFace.
        END GET.

    DEFINE PUBLIC PROPERTY GoalAim AS INTEGER NO-UNDO
        GET():
            RETURN mGoalElev.
        END GET.

    DEFINE PUBLIC PROPERTY GoalPower AS INTEGER NO-UNDO
        GET():
            RETURN mGoalPower.
        END GET.

    CONSTRUCTOR PUBLIC SimulatingBrain(INPUT poRandom AS IRandom, INPUT poSkill AS BuddySkill):
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("The computer player needs a random source").
        IF NOT VALID-OBJECT(poSkill) THEN UNDO, THROW NEW GridException("The computer player needs a skill").
        mRandom = poRandom.
        mSkill = poSkill.
        mSim = NEW ShotSimulator().
        mPhysics = NEW BuddyPhysics().
        Stage = BrainStage:Idle.
    END CONSTRUCTOR.

    METHOD PUBLIC VOID Reset():
        Stage = BrainStage:Idle.
        mFrames = 0.
        mScanned = FALSE.
    END METHOD.

    /* The aims it tries, from straight up to nearly straight down, and the powers by the skill. */
    METHOD PRIVATE INTEGER ElevationAt(INPUT piIndex AS INTEGER):
        RETURN 4 * piIndex.
    END METHOD.

    METHOD PRIVATE INTEGER Elevations():
        RETURN 7.
    END METHOD.

    METHOD PRIVATE INTEGER PowerAt(INPUT piIndex AS INTEGER):
        IF mSkill = BuddySkill:Easy THEN RETURN 40 + 20 * piIndex.
        RETURN 30 + 10 * piIndex.
    END METHOD.

    METHOD PRIVATE INTEGER Powers():
        IF mSkill = BuddySkill:Easy THEN RETURN 4.
        RETURN 7.
    END METHOD.

    METHOD PUBLIC VOID Drive(INPUT poGame AS BlastBuddiesGame):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("The computer player needs a game").
        IF poGame:Phase <> BuddyPhase:Turn OR NOT VALID-OBJECT(poGame:CurrentBuddy) THEN RETURN.
        CASE Stage:
            WHEN BrainStage:Idle THEN BeginThinking(poGame).
            WHEN BrainStage:Thinking THEN DO:
                mFrames = mFrames + 1.
                Think(poGame, 6).
                IF mScanned AND mFrames >= {&LEAST-THOUGHT} THEN Decide().
            END.
            WHEN BrainStage:Walking THEN Walk(poGame).
            WHEN BrainStage:Aiming THEN AimAt(poGame).
            WHEN BrainStage:Charging THEN ChargeUp(poGame).
            OTHERWISE.
        END CASE.
    END METHOD.

    /* The places it could shoot from (here, and where 15 and 30 steps of walking either way would take it) and the enemies nearest to it. */
    METHOD PRIVATE VOID BeginThinking(INPUT poGame AS BlastBuddiesGame):
        DEFINE VARIABLE me      AS Buddy NO-UNDO.
        DEFINE VARIABLE scratch AS Buddy NO-UNDO.
        DEFINE VARIABLE dir     AS INTEGER NO-UNDO.
        DEFINE VARIABLE step    AS INTEGER NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE j       AS INTEGER NO-UNDO.
        DEFINE VARIABLE b       AS Buddy NO-UNDO.
        DEFINE VARIABLE best    AS INTEGER NO-UNDO.
        DEFINE VARIABLE bestD   AS INTEGER NO-UNDO.
        DEFINE VARIABLE d       AS INTEGER NO-UNDO.
        me = poGame:CurrentBuddy.
        mCands = 1.
        mCandX[1] = me:X().
        mCandY[1] = me:Y().
        scratch = NEW Buddy("SCRATCH", me:Team, me:X(), me:Y()).
        DO dir = -1 TO 1 BY 2:
            scratch:PlaceAt(me:X(), me:Y()).
            DO step = 1 TO 30:
                IF NOT mPhysics:Walk(scratch, poGame:Land, dir) OR scratch:State <> BuddyState:Standing THEN LEAVE.
                IF step MODULO 15 = 0 AND mCands < {&CANDIDATES} THEN ASSIGN mCands = mCands + 1
                                                                          mCandX[mCands] = scratch:X()
                                                                          mCandY[mCands] = scratch:Y().
            END.
        END.
        /* the nearest enemies, nearest first */
        mTargets = 0.
        DO j = 1 TO {&TARGETS}:
            best = ?.
            bestD = 0.
            DO i = 1 TO poGame:Plan:TeamCount():
                IF i = me:Team THEN NEXT.
                DO d = 1 TO poGame:Plan:TeamAt(i):Count():
                    b = poGame:Plan:TeamAt(i):BuddyAt(d).
                    IF b:IsDead() THEN NEXT.
                    IF b:X() = ? THEN NEXT.
                    IF best = ? OR ABSOLUTE(b:X() - me:X()) < bestD THEN DO:
                        /* not one already taken */
                        IF j = 2 AND mTgtX[1] = b:X() THEN NEXT.
                        best = b:X().
                        bestD = ABSOLUTE(b:X() - me:X()).
                    END.
                END.
            END.
            IF best <> ? THEN ASSIGN mTargets = mTargets + 1
                                     mTgtX[mTargets] = best.
        END.
        mCi = 1.
        mTi = 1.
        mEi = 1.
        mPi = 1.
        mRefine = 0.
        mScanned = (mTargets = 0).
        mBestScore = -1000000.
        mBestCand = 1.
        mBestFace = (IF mTargets > 0 AND mTgtX[1] < me:X() THEN -1 ELSE 1).
        mBestElev = 12.
        mBestPower = 70.
        Stage = BrainStage:Thinking.
        mFrames = 0.
    END METHOD.

    /* Tries up to piMax flights. */
    METHOD PRIVATE VOID Think(INPUT poGame AS BlastBuddiesGame, INPUT piMax AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO WHILE n < piMax AND NOT mScanned:
            n = n + 1.
            IF mCi <= mCands THEN DO:
                TryShot(poGame, mCi, (IF mTgtX[mTi] >= mCandX[mCi] THEN 1 ELSE -1), ElevationAt(mEi), PowerAt(mPi)).
                /* the next power, then the next aim, then the next enemy, then the next place */
                mPi = mPi + 1.
                IF mPi > Powers() THEN ASSIGN mPi = 1 mEi = mEi + 1.
                IF mEi > Elevations() THEN ASSIGN mEi = 1 mTi = mTi + 1.
                IF mTi > mTargets THEN ASSIGN mTi = 1 mCi = mCi + 1.
            END.
            ELSE IF mSkill = BuddySkill:Hard AND mRefine < 25 THEN DO:
                /* round the best so far: 5 aims either side by 5 powers either side */
                TryShot(poGame, mBestCand, mBestFace, MAXIMUM(0, MINIMUM(32, mBestElev - 2 + (mRefine MODULO 5))),
                        MAXIMUM(5, MINIMUM(100, mBestPower - 6 + 3 * INTEGER(TRUNCATE(mRefine / 5, 0))))).
                mRefine = mRefine + 1.
            END.
            ELSE mScanned = TRUE.
        END.
    END METHOD.

    /* One flight from a place, scored and kept if it is the best. */
    METHOD PRIVATE VOID TryShot(INPUT poGame AS BlastBuddiesGame, INPUT piCand AS INTEGER, INPUT piFace AS INTEGER, INPUT piElev AS INTEGER, INPUT piPower AS INTEGER):
        DEFINE VARIABLE hd    AS INTEGER NO-UNDO.
        DEFINE VARIABLE speed AS INTEGER NO-UNDO.
        DEFINE VARIABLE hx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE hy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE score AS INTEGER NO-UNDO.
        hd = (IF piFace > 0 THEN piElev ELSE Heading:Wrap(64 - piElev)).
        speed = BuddyRules:ShotSpeedMin() + INTEGER(TRUNCATE((BuddyRules:ShotSpeedMax() - BuddyRules:ShotSpeedMin()) * piPower / 100, 0)).
        IF NOT mSim:Fly(poGame:Land, mCandX[piCand] * 256 + INTEGER(TRUNCATE(Heading:DirX(hd) * 3 / 2, 0)),
                        (mCandY[piCand] - 6) * 256 + INTEGER(TRUNCATE(Heading:DirY(hd) * 3 / 2, 0)),
                        INTEGER(TRUNCATE(Heading:DirX(hd) * speed / Heading:Scale(), 0)), INTEGER(TRUNCATE(Heading:DirY(hd) * speed / Heading:Scale(), 0)),
                        poGame:Wind, OUTPUT hx, OUTPUT hy) THEN RETURN.
        score = ScoreBlast(poGame, hx, hy, mCandX[piCand], mCandY[piCand]).
        IF score > mBestScore THEN ASSIGN mBestScore = score
                                          mBestCand = piCand
                                          mBestFace = piFace
                                          mBestElev = piElev
                                          mBestPower = piPower.
    END METHOD.

    /* What a bazooka blast at a pixel is worth to the buddy in turn, standing at (piMeX, piMeY): the damage to enemies, with a bonus for each kill,
       less 1.2 times the damage to its own team and itself. */
    METHOD PRIVATE INTEGER ScoreBlast(INPUT poGame AS BlastBuddiesGame, INPUT piHitX AS INTEGER, INPUT piHitY AS INTEGER, INPUT piMeX AS INTEGER, INPUT piMeY AS INTEGER):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER NO-UNDO.
        DEFINE VARIABLE b     AS Buddy   NO-UNDO.
        DEFINE VARIABLE reach AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE d     AS DECIMAL NO-UNDO.
        DEFINE VARIABLE dmg   AS INTEGER NO-UNDO.
        DEFINE VARIABLE total AS DECIMAL NO-UNDO.
        reach = BuddyRules:BazookaRadius() + BuddyRules:BlastReach().
        DO i = 1 TO poGame:Plan:TeamCount():
            DO j = 1 TO poGame:Plan:TeamAt(i):Count():
                b = poGame:Plan:TeamAt(i):BuddyAt(j).
                IF b:IsDead() THEN NEXT.
                IF b = poGame:CurrentBuddy THEN ASSIGN dx = piMeX - piHitX
                                                       dy = piMeY - 5 - piHitY.
                ELSE ASSIGN dx = b:X() - piHitX
                            dy = b:Y() - 5 - piHitY.
                d = SQRT(DECIMAL(dx * dx + dy * dy)).
                IF d >= reach THEN NEXT.
                dmg = INTEGER(TRUNCATE(BuddyRules:BazookaDamage() * (reach - d) / reach, 0)).
                IF b:Team = poGame:CurrentBuddy:Team THEN total = total - 1.2 * dmg.
                ELSE total = total + dmg + (IF dmg >= b:Health THEN 25 ELSE 0).
            END.
        END.
        RETURN INTEGER(ROUND(total, 0)).
    END METHOD.

    /* Settles on the best shot, with the mistake of its skill in the aim and the power. */
    METHOD PRIVATE VOID Decide():
        DEFINE VARIABLE elevErr  AS INTEGER NO-UNDO.
        DEFINE VARIABLE powerErr AS INTEGER NO-UNDO.
        CASE mSkill:
            WHEN BuddySkill:Easy THEN ASSIGN elevErr = 3 powerErr = 12.
            WHEN BuddySkill:Normal THEN ASSIGN elevErr = 1 powerErr = 5.
            OTHERWISE ASSIGN elevErr = 0 powerErr = 0.
        END CASE.
        mGoalX = mCandX[mBestCand].
        mGoalFace = mBestFace.
        mGoalElev = MAXIMUM(0, MINIMUM(32, mBestElev + (IF elevErr > 0 THEN mRandom:NextInt(2 * elevErr + 1) - elevErr ELSE 0))).
        mGoalPower = MAXIMUM(5, MINIMUM(100, mBestPower + (IF powerErr > 0 THEN mRandom:NextInt(2 * powerErr + 1) - powerErr ELSE 0))).
        mStuck = 0.
        mLastX = ?.
        Stage = BrainStage:Walking.
    END METHOD.

    /* Walks to the place it chose, and gives up on it if it makes no headway for a second and a half. */
    METHOD PRIVATE VOID Walk(INPUT poGame AS BlastBuddiesGame):
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        b = poGame:CurrentBuddy.
        IF b:State <> BuddyState:Standing THEN RETURN.
        IF b:X() = mGoalX THEN DO:
            poGame:SetWalk(0).
            Stage = BrainStage:Aiming.
            RETURN.
        END.
        IF b:X() = mLastX THEN mStuck = mStuck + 1.
        ELSE mStuck = 0.
        mLastX = b:X().
        IF mStuck > 90 THEN DO:
            poGame:SetWalk(0).
            Stage = BrainStage:Aiming.
            RETURN.
        END.
        poGame:SetWalk(IF mGoalX > b:X() THEN 1 ELSE -1).
    END METHOD.

    /* Turns to face the way it chose and moves the aim to the aim it chose, then starts to charge. */
    METHOD PRIVATE VOID AimAt(INPUT poGame AS BlastBuddiesGame):
        poGame:Face(mGoalFace).
        IF poGame:Aim < mGoalElev THEN poGame:SetAim(1).
        ELSE IF poGame:Aim > mGoalElev THEN poGame:SetAim(-1).
        ELSE DO:
            poGame:SetAim(0).
            poGame:StartCharge().
            Stage = BrainStage:Charging.
        END.
    END METHOD.

    /* Holds the fire key until the power is right, and lets go. */
    METHOD PRIVATE VOID ChargeUp(INPUT poGame AS BlastBuddiesGame):
        IF NOT poGame:Charging THEN DO:
            poGame:StartCharge().
            RETURN.
        END.
        IF poGame:PowerPercent >= mGoalPower THEN DO:
            poGame:ReleaseCharge().
            Stage = BrainStage:Done.
        END.
    END METHOD.

END CLASS.
