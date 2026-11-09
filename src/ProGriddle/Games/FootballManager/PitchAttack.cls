/* One attack on goal, worked out cell by cell on the 32 x 22 pitch of the original, and kept so that a picture can replay it. Three attackers (the first has the ball), three defenders and a keeper are placed at random, the attacker dribbles 1, 3 or 5 cells toward goal (everyone moving up with him), then the ball is struck: it travels two columns at a time, drifting toward the middle rows, and is turned back by any defender or the keeper it meets, or carried on by a team mate. It ends when it leaves the pitch, and it is a goal if it left through the goal mouth.

   Team 1 is the home side and attacks the goal on the right, team 2 attacks the goal on the left. The rules are worked out in one frame (attacking toward column 0) and the columns are mirrored for team 1, so every answer here is in real pitch columns 0 to 31 and rows 0 to 21 (row 0 at the top).
   Players are numbered 1 to 7: 1 the attacker with the ball, 2 and 3 his team mates, 4 to 6 the defenders, 7 the keeper.

   An attack always ends: a ball still on the pitch after MaxBallSteps steps is counted as wide. A player that cannot be given a free cell after SetupTries tries is put where the last try fell (only a source of random numbers that never changes its mind can do that). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.PitchAttack FINAL:

    VAR PRIVATE INTEGER[7] mStartCol.
    VAR PRIVATE INTEGER[7] mStartRow.
    VAR PRIVATE INTEGER[7] mShotCol.
    VAR PRIVATE INTEGER[7] mShotRow.
    VAR PRIVATE INTEGER[42] mBallCol.
    VAR PRIVATE INTEGER[42] mBallRow.
    VAR PRIVATE INTEGER[42] mKeeperCol.
    VAR PRIVATE INTEGER[42] mKeeperRow.
    /* the working state, in the frame where the attack runs toward column 0 */
    VAR PRIVATE INTEGER[7] mCol.
    VAR PRIVATE INTEGER[7] mRow.
    VAR PRIVATE INTEGER[704] mCell.
    VAR PRIVATE INTEGER mBx.
    VAR PRIVATE INTEGER mBy.
    VAR PRIVATE INTEGER mDx.
    VAR PRIVATE INTEGER mDy.
    VAR PRIVATE INTEGER mBallStartCol.
    VAR PRIVATE LOGICAL mOut.
    VAR PRIVATE LOGICAL mKeeperHit.
    VAR PRIVATE INTEGER mKeeperHitAt.
    VAR PRIVATE LOGICAL mDefenderHit.
    VAR PRIVATE IRandom mRandom.

    /* 1 if the home side attacked (toward the goal on the right), 2 if the away side did. */
    DEFINE PUBLIC PROPERTY Team AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Outcome AS AttackOutcome NO-UNDO
        GET.
        PRIVATE SET.

    /* How many cells the attacker dribbled: 1, 3 or 5. */
    DEFINE PUBLIC PROPERTY DribbleSteps AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The points of the ball's flight after the dribble: point 1 is where the ball is struck, the last is where it left the pitch. */
    DEFINE PUBLIC PROPERTY PathLength AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many points of the ball's flight are shown on the pitch before the close up: all of them, except for a save, where the flight ends at the keeper
       (the ball that bounces back off him is not shown). */
    DEFINE PUBLIC PROPERTY FlightPoints AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Scored AS LOGICAL NO-UNDO
        GET():
            RETURN VALID-OBJECT(Outcome) AND Outcome = AttackOutcome:Goal.
        END GET.

    METHOD PRIVATE INTEGER Roll(INPUT piMost AS INTEGER):
        RETURN mRandom:NextInt(piMost) + 1.
    END METHOD.

    /* The real column for a column of the working frame. */
    METHOD PRIVATE INTEGER Mirror(INPUT piCol AS INTEGER):
        IF Team = 1 THEN RETURN FootballRules:PitchWidth() - 1 - piCol.
        RETURN piCol.
    END METHOD.

    METHOD PRIVATE INTEGER CellIndex(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        RETURN piRow * 32 + piCol + 1.
    END METHOD.

    METHOD PRIVATE LOGICAL OnPitch(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        RETURN piCol >= 0 AND piCol < FootballRules:PitchWidth() AND piRow >= 0 AND piRow < FootballRules:PitchHeight().
    END METHOD.

    METHOD PRIVATE INTEGER CellAt(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        IF NOT OnPitch(piCol, piRow) THEN RETURN INTEGER(PitchCell:Vacant).
        RETURN mCell[CellIndex(piCol, piRow)].
    END METHOD.

    METHOD PRIVATE VOID SetCell(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT piWhat AS INTEGER):
        IF OnPitch(piCol, piRow) THEN mCell[CellIndex(piCol, piRow)] = piWhat.
    END METHOD.

    /* Whether the attacking row or a row of a player already placed is piRow, for the players from piFrom to piTo. */
    METHOD PRIVATE LOGICAL RowTaken(INPUT piRow AS INTEGER, INPUT piFrom AS INTEGER, INPUT piTo AS INTEGER):
        VAR INTEGER i.
        DO i = piFrom TO piTo:
            IF mRow[i] = piRow THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* A team mate of the attacker (2 or 3): a column 11 to 30, a row 1 to 21, at least 25 along the diagonal and 4 columns clear of the attacker, in a row of his own. */
    METHOD PRIVATE VOID PlaceMate(INPUT piWho AS INTEGER):
        VAR INTEGER tries.
        VAR INTEGER c.
        VAR INTEGER r.
        VAR LOGICAL ok.
        DO WHILE tries < FootballRules:SetupTries():
            c = 10 + Roll(20).
            r = Roll(21).
            tries = tries + 1.
            ok = c + r >= 25 AND c <= mCol[1] - 4 AND NOT RowTaken(r, 1, piWho - 1).
            IF ok THEN LEAVE.
        END.
        mCol[piWho] = c.
        mRow[piWho] = r.
    END METHOD.

    /* A defender (4 to 6): a column 11 to 20, a row 1 to 18, at least 24 along the diagonal and 4 columns clear of the attacker, in a row that no attacker or defender placed so far has. */
    METHOD PRIVATE VOID PlaceDefender(INPUT piWho AS INTEGER):
        VAR INTEGER tries.
        VAR INTEGER c.
        VAR INTEGER r.
        VAR LOGICAL ok.
        DO WHILE tries < FootballRules:SetupTries():
            c = 10 + Roll(10).
            r = Roll(18).
            tries = tries + 1.
            ok = c + r >= 24 AND c <= mCol[1] - 4 AND NOT RowTaken(r, 1, piWho - 1).
            IF ok THEN LEAVE.
        END.
        mCol[piWho] = c.
        mRow[piWho] = r.
    END METHOD.

    /* Puts the seven players on the pitch and the ball beside the attacker. */
    METHOD PRIVATE VOID PlacePlayers():
        VAR INTEGER i.
        VAR INTEGER k.
        DO i = 1 TO 704:
            mCell[i] = INTEGER(PitchCell:Vacant).
        END.
        mRow[1] = 3 + Roll(18).
        mCol[1] = 25 + Roll(6).
        /* the keeper stands on the diagonal where column + row is 23, on the side of the goal the attacker is not */
        k = 11 + Roll(2).
        IF mRow[1] < 11 THEN k = k + 2.
        IF mRow[1] > 10 THEN k = k - 2.
        mCol[7] = k.
        mRow[7] = 23 - k.
        PlaceMate(2).
        PlaceMate(3).
        PlaceDefender(4).
        PlaceDefender(5).
        PlaceDefender(6).
        DO i = 1 TO 3:
            SetCell(mCol[i], mRow[i], INTEGER(PitchCell:Attacker)).
        END.
        DO i = 4 TO 6:
            SetCell(mCol[i], mRow[i], INTEGER(PitchCell:Defender)).
        END.
        SetCell(mCol[7], mRow[7], INTEGER(PitchCell:Keeper)).
        DO i = 1 TO 7:
            mStartCol[i] = Mirror(mCol[i]).
            mStartRow[i] = mRow[i].
        END.
    END METHOD.

    /* Everyone but the attacker moves a column toward goal and a row toward the middle (row 9 or 10), if the cell is free and still inside the drawn pitch. */
    METHOD PRIVATE VOID MoveFollowers():
        VAR INTEGER i.
        VAR INTEGER px.
        VAR INTEGER py.
        VAR INTEGER edge.
        DO i = 2 TO 6:
            IF mRow[i] < 10 THEN py = mRow[i] + 1.
            ELSE py = mRow[i] - 1.
            px = mCol[i] - 1.
            /* the mates must stay beyond the diagonal 24, the defenders beyond 23 */
            IF i < 4 THEN edge = 24.
            ELSE edge = 23.
            IF px + py > edge AND CellAt(px, py) = INTEGER(PitchCell:Vacant) THEN
            DO:
                SetCell(mCol[i], mRow[i], INTEGER(PitchCell:Vacant)).
                mCol[i] = px.
                mRow[i] = py.
                IF i < 4 THEN SetCell(px, py, INTEGER(PitchCell:Attacker)).
                ELSE SetCell(px, py, INTEGER(PitchCell:Defender)).
            END.
        END.
    END METHOD.

    /* The attacker carries the ball 1, 3 or 5 cells toward goal. */
    METHOD PRIVATE VOID Dribble():
        VAR INTEGER e.
        DribbleSteps = Roll(3) * 2 - 1.
        mBx = mCol[1] - 1.
        mBy = mRow[1].
        mBallStartCol = mBx.
        SetCell(mBx, mBy, INTEGER(PitchCell:Ball)).
        DO e = 1 TO DribbleSteps:
            SetCell(mBx, mBy, INTEGER(PitchCell:Vacant)).
            mBx = mBx - 1.
            SetCell(mBx, mBy, INTEGER(PitchCell:Ball)).
            SetCell(mCol[1], mRow[1], INTEGER(PitchCell:Vacant)).
            mCol[1] = mCol[1] - 1.
            SetCell(mCol[1], mRow[1], INTEGER(PitchCell:Attacker)).
            MoveFollowers().
        END.
        SetCell(mBx, mBy, INTEGER(PitchCell:Vacant)).
        DO e = 1 TO 7:
            mShotCol[e] = Mirror(mCol[e]).
            mShotRow[e] = mRow[e].
        END.
    END METHOD.

    /* The keeper steps a row toward the ball's row (and stays put when the ball is within a row of him and not running straight), keeping to his diagonal. */
    METHOD PRIVATE VOID MoveKeeper():
        VAR INTEGER move.
        VAR INTEGER slack.
        IF mDy <> 0 THEN slack = 1.
        IF mBy > mRow[7] + slack THEN move = 1.
        ELSE IF mBy < mRow[7] - slack THEN move = -1.
        SetCell(mCol[7], mRow[7], INTEGER(PitchCell:Vacant)).
        mRow[7] = mRow[7] + move.
        mCol[7] = 23 - mRow[7].
        SetCell(mCol[7], mRow[7], INTEGER(PitchCell:Keeper)).
    END METHOD.

    /* The ball has left the pitch where it is: it is a goal if it went out between the posts, which are columns 7 to 14 and rows 5 to 13 (and not by the corner of the near post going upward). */
    METHOD PRIVATE LOGICAL InGoalMouth():
        RETURN mBx + mBy < 22 AND mBy < 14 AND mBy > 4 AND mBx < 15 AND mBx > 6 AND NOT (mBx = 7 AND mBy = 13 AND mDy < 0).
    END METHOD.

    /* Adds the ball and the keeper to the path. */
    METHOD PRIVATE VOID Remember():
        IF PathLength < 42 THEN
        DO:
            PathLength = PathLength + 1.
            mBallCol[PathLength] = Mirror(mBx).
            mBallRow[PathLength] = mBy.
            mKeeperCol[PathLength] = Mirror(mCol[7]).
            mKeeperRow[PathLength] = mRow[7].
        END.
    END METHOD.

    /* One step of the ball: it looks at the cell it is about to enter before the keeper moves, then the keeper moves if the ball is near, then the ball moves in. A player in that cell turns it round (a defender or the keeper) or lets it run on (a team mate), with a new drift. */
    METHOD PRIVATE VOID StepBall():
        VAR INTEGER px.
        VAR INTEGER py.
        VAR INTEGER seen.
        px = mBx + mDx.
        py = mBy + mDy.
        seen = CellAt(px, py).
        IF px + py >= 24 AND px + py <= 27 AND py > 7 AND py < 14 THEN MoveKeeper().
        IF px + py < 22 OR NOT OnPitch(px, py) THEN
        DO:
            mOut = TRUE.
            mBx = px.
            mBy = py.
        END.
        ELSE
        DO:
            IF seen <> INTEGER(PitchCell:Vacant) THEN
            DO:
                IF seen = INTEGER(PitchCell:Attacker) THEN
                DO:
                    mDx = -2.
                    mDy = Roll(2) - 2.
                END.
                ELSE
                DO:
                    mDx = 2.
                    mDy = Roll(3) - 2.
                    IF seen = INTEGER(PitchCell:Keeper) THEN mKeeperHit = TRUE.
                    ELSE mDefenderHit = TRUE.
                END.
            END.
            mBx = px.
            mBy = py.
        END.
        Remember().
        IF mKeeperHit AND mKeeperHitAt = 0 THEN mKeeperHitAt = PathLength.
    END METHOD.

    /* The shot: the ball drifts toward the middle rows (down from rows above 8, up from rows below 15, either way from 13 to 15) and runs until it leaves the pitch. */
    METHOD PRIVATE VOID Shoot():
        VAR INTEGER steps.
        IF mBy < 8 THEN mDy = 1.
        IF mBy > 15 THEN mDy = -1.
        IF mBy > 12 AND mBy < 16 THEN mDy = Roll(2) - 2.
        mDx = -2.
        Remember().
        DO WHILE NOT mOut AND steps < FootballRules:MaxBallSteps():
            StepBall().
            steps = steps + 1.
        END.
        IF mOut AND InGoalMouth() THEN Outcome = AttackOutcome:Goal.
        ELSE IF mKeeperHit THEN Outcome = AttackOutcome:Saved.
        ELSE IF mDefenderHit THEN Outcome = AttackOutcome:Blocked.
        ELSE Outcome = AttackOutcome:Wide.
        FlightPoints = (IF Outcome = AttackOutcome:Saved AND mKeeperHitAt > 0 THEN mKeeperHitAt ELSE PathLength).
    END METHOD.

    /* Works out a new attack for piTeam (1 attacks the goal on the right, 2 the goal on the left), drawing every random number from poRandom. Any earlier attack held here is replaced. Throws GridException for another team or no random source. */
    METHOD PUBLIC VOID Run(INPUT piTeam AS INTEGER, INPUT poRandom AS IRandom):
        IF piTeam <> 1 AND piTeam <> 2 THEN UNDO, THROW NEW GridException("A team is 1 (home) or 2 (away), not " + STRING(piTeam)).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("An attack needs a random source").
        mRandom = poRandom.
        Team = piTeam.
        mOut = FALSE.
        mKeeperHit = FALSE.
        mKeeperHitAt = 0.
        mDefenderHit = FALSE.
        PathLength = 0.
        mDx = 0.
        mDy = 0.
        PlacePlayers().
        Dribble().
        Shoot().
        mRandom = ?.
    END METHOD.

    METHOD PRIVATE VOID CheckPlayer(INPUT piWho AS INTEGER):
        IF piWho = ? OR piWho < 1 OR piWho > 7 THEN UNDO, THROW NEW GridException("A pitch has players 1 to 7, not " + STRING(piWho)).
    END METHOD.

    METHOD PRIVATE VOID CheckPoint(INPUT piPoint AS INTEGER):
        IF piPoint = ? OR piPoint < 1 OR piPoint > PathLength THEN
            UNDO, THROW NEW GridException("The ball's flight has points 1 to " + STRING(PathLength) + ", not " + STRING(piPoint)).
    END METHOD.

    /* Where a player stood when the attack began (column 0 to 31, row 0 to 21). */
    METHOD PUBLIC INTEGER StartCol(INPUT piWho AS INTEGER):
        CheckPlayer(piWho).
        RETURN mStartCol[piWho].
    END METHOD.

    METHOD PUBLIC INTEGER StartRow(INPUT piWho AS INTEGER):
        CheckPlayer(piWho).
        RETURN mStartRow[piWho].
    END METHOD.

    /* Where the ball was before the dribble: one cell ahead of the attacker. */
    METHOD PUBLIC INTEGER BallStartCol():
        RETURN Mirror(mBallStartCol).
    END METHOD.

    /* Where a player stood when the ball was struck, after the dribble. */
    METHOD PUBLIC INTEGER ShotCol(INPUT piWho AS INTEGER):
        CheckPlayer(piWho).
        RETURN mShotCol[piWho].
    END METHOD.

    METHOD PUBLIC INTEGER ShotRow(INPUT piWho AS INTEGER):
        CheckPlayer(piWho).
        RETURN mShotRow[piWho].
    END METHOD.

    /* The ball at a point of its flight (1 is where it is struck). */
    METHOD PUBLIC INTEGER BallCol(INPUT piPoint AS INTEGER):
        CheckPoint(piPoint).
        RETURN mBallCol[piPoint].
    END METHOD.

    METHOD PUBLIC INTEGER BallRow(INPUT piPoint AS INTEGER):
        CheckPoint(piPoint).
        RETURN mBallRow[piPoint].
    END METHOD.

    /* The keeper at that point of the flight: he moves to meet the ball. */
    METHOD PUBLIC INTEGER KeeperCol(INPUT piPoint AS INTEGER):
        CheckPoint(piPoint).
        RETURN mKeeperCol[piPoint].
    END METHOD.

    METHOD PUBLIC INTEGER KeeperRow(INPUT piPoint AS INTEGER):
        CheckPoint(piPoint).
        RETURN mKeeperRow[piPoint].
    END METHOD.

END CLASS.
