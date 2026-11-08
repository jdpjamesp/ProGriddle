/* The real maze played for a long time with random steering, looking at every frame: Dibby is always on a tile he may enter, a phantom out in the
   maze is always on a lane (never in a wall, the lobby or the door), the phantoms keep moving (none is stuck in a corner or turns on the spot),
   and the game gets through lives and levels. Whatever the individual rules say, these must hold in play. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachPlayTests:

    VAR PRIVATE ForEachGame mGame.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = ForEachFactory:Create(NEW SeededRandom(3)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* The tile a phantom is on is one it may be on for what it is doing. Returns the name of the problem, or "" for none. */
    METHOD PRIVATE CHARACTER Problem(INPUT poKind AS PhantomKind):
        VAR TileKind kind.
        IF NOT mGame:PhantomPresent(poKind) THEN RETURN "".
        kind = mGame:Maze:KindAt(mGame:PhantomCol(poKind), mGame:PhantomRow(poKind)).
        IF kind = TileKind:Wall THEN RETURN STRING(poKind) + " in a wall at " + STRING(mGame:PhantomX(poKind)) + "," + STRING(mGame:PhantomY(poKind)) + " " + STRING(mGame:ModeOf(poKind)).
        CASE mGame:ModeOf(poKind):
            WHEN PhantomMode:Scatter OR WHEN PhantomMode:Chase OR WHEN PhantomMode:RolledBack THEN
                IF kind = TileKind:Lobby OR kind = TileKind:Door THEN
                    RETURN STRING(poKind) + " in the lobby in mode " + STRING(mGame:ModeOf(poKind)) + " at " + STRING(mGame:PhantomX(poKind)) + "," + STRING(mGame:PhantomY(poKind)).
        END CASE.
        RETURN "".
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DibbyAndThePhantomsStayOnTheirLanesThroughAHundredThousandFramesOfRandomPlay():
        VAR INTEGER n.
        VAR INTEGER i.
        VAR SeededRandom random.

        VAR CHARACTER issue.
        VAR CHARACTER bad.
        random = NEW SeededRandom(21).
        mGame:StartGame().
        DO n = 1 TO 100000:
            IF n MODULO 17 = 0 THEN mGame:Steer(MazeDir:GetEnum(random:NextInt(4) + 1)).
            IF n MODULO 6000 = 0 THEN mGame:EatBits(50).
            mGame:Advance().
            IF mGame:Phase = ForEachPhase:GameOver THEN mGame:StartGame().
            IF mGame:Phase = ForEachPhase:Playing THEN DO:
                IF NOT mGame:Maze:CanEnter(mGame:DibbyCol, mGame:DibbyRow, FALSE) THEN bad = "Dibby at " + STRING(mGame:DibbyX) + "," + STRING(mGame:DibbyY) + " frame " + STRING(n).
                DO i = 1 TO 4:
                    issue = Problem(PhantomKind:GetEnum(i)).
                    IF issue <> "" AND bad = "" THEN bad = issue + " frame " + STRING(n).
                END.
                IF bad <> "" THEN LEAVE.
            END.
        END.
        Assert:Equals("", bad).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheChaserKeepsMovingAndGoesAllOverTheMaze():
        VAR INTEGER n.
        VAR INTEGER lastX.
        VAR INTEGER lastY.
        VAR INTEGER still.
        VAR INTEGER worst.
        VAR INTEGER[28] cols.
        VAR INTEGER visited.
        mGame:StartGame().
        ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
        /* Dibby stands still in his corner, so the chaser has the maze to itself to wander in, and is not stopped by catching him */
        mGame:PlaceDibby(12, 28, MazeDir:Left).
        DO n = 1 TO 4000:
            mGame:PlaceDibby(12, 28, MazeDir:Left).
            mGame:Advance().
            IF mGame:Phase <> ForEachPhase:Playing THEN LEAVE.
            IF mGame:PhantomX(PhantomKind:Mary) = lastX AND mGame:PhantomY(PhantomKind:Mary) = lastY THEN still = still + 1.
            ELSE still = 0.
            worst = MAXIMUM(worst, still).
            ASSIGN lastX = mGame:PhantomX(PhantomKind:Mary)
                   lastY = mGame:PhantomY(PhantomKind:Mary).
            IF cols[mGame:PhantomCol(PhantomKind:Mary) + 1] = 0 THEN visited = visited + 1.
            cols[mGame:PhantomCol(PhantomKind:Mary) + 1] = 1.
        END.
        /* it is never still for a second, and it has been to a good number of the 28 columns */
        Assert:IsTrue(worst < 60).
        Assert:IsTrue(visited >= 10).
    END METHOD.

END CLASS.
