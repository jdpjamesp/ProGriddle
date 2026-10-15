/* The cue source of Snake, with real games driven by hand: each event is reported once, the end covers the last bite, a waiting game
   is silent and a new game forgets the old one. Cue numbers are INTEGER(SnakeCue:...). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeCuesTests:

    DEFINE PRIVATE VARIABLE mGame AS SnakeGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mCues AS SnakeCues NO-UNDO.

    /* On an 8 x 8 board a new game has the snake in row 4, the tail at x 2 and the head at x 4, facing right. */
    @Setup.
    METHOD PUBLIC VOID BuildCues():
        mGame = NEW SnakeGame(SnakeFactory:CreateGrid(8, 8), NEW ScriptedRandom("0")).
        mCues = NEW SnakeCues().
        /* the first look takes the game as it is */
        mCues:Poll(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCues():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
        mCues = ?.
    END METHOD.

    METHOD PRIVATE CHARACTER N(INPUT poCue AS SnakeCue):
        RETURN STRING(INTEGER(poCue)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStepThatEatsNothingIsSilent():
        mGame:SetFood(0, 0).
        mGame:Tick(mGame:StepMs).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EatingGivesOneEatCueAndItIsReportedOnce():
        mGame:SetFood(5, 4).
        mGame:Tick(mGame:StepMs).
        mGame:Tick(mGame:StepMs).
        Assert:Equals(1, mGame:FoodEaten).
        Assert:Equals(N(SnakeCue:Eat), mCues:Poll(mGame)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RunningIntoTheWallGivesOneCrashCue():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cues   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE crashes AS INTEGER  NO-UNDO.
        mGame:SetFood(0, 0).
        DO i = 1 TO 10:
            mGame:Tick(mGame:StepMs).
            cues = mCues:Poll(mGame).
            IF cues = N(SnakeCue:Crash) THEN crashes = crashes + 1.
            ELSE Assert:Equals("", cues).
        END.
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mGame:HasWon).
        Assert:Equals(1, crashes).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillingTheBoardGivesAWinAndTheLastBiteIsLeftToTheGroup():
        DEFINE VARIABLE body AS CHARACTER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER   NO-UNDO.
        DO y = 0 TO 7:
            DO x = 0 TO 7:
                IF y = 7 AND x > 6 THEN NEXT.
                body = body + (IF body = "" THEN "" ELSE ";") + SUBSTITUTE("&1,&2", (IF y MODULO 2 = 0 THEN x ELSE 7 - x), y).
            END.
        END.
        mGame:StartWith(body, "Left").
        mGame:SetFood(0, 7).
        mCues:Poll(mGame).
        mGame:Tick(mGame:StepMs).
        Assert:IsTrue(mGame:HasWon).
        Assert:Equals(N(SnakeCue:Win) + "," + N(SnakeCue:Eat), mCues:Poll(mGame)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameWaitingForItsFirstKeyIsSilent():
        mGame:WaitForKey = TRUE.
        Assert:IsTrue(mGame:Waiting).
        mGame:Tick(1000).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameForgetsTheOldOneAndSoundsAgain():
        mGame:SetFood(5, 4).
        mGame:Tick(mGame:StepMs).
        mGame:Tick(mGame:StepMs).
        mGame:StartWith("2,4;3,4;4,4", "Right").
        /* the bite of the old game does not sound, and the new game starts quiet */
        Assert:Equals("", mCues:Poll(mGame)).
        mGame:SetFood(5, 4).
        mGame:Tick(mGame:StepMs).
        mGame:Tick(mGame:StepMs).
        Assert:Equals(N(SnakeCue:Eat), mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AllThreeCuesAreOneGroup():
        Assert:Equals(mCues:GroupOf(INTEGER(SnakeCue:Eat)), mCues:GroupOf(INTEGER(SnakeCue:Crash))).
        Assert:Equals(mCues:GroupOf(INTEGER(SnakeCue:Eat)), mCues:GroupOf(INTEGER(SnakeCue:Win))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsNotSnakeThrowsGridException():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE oOther AS CountingGame NO-UNDO.
        oOther = NEW CountingGame(NEW Grid(NEW ArrayStore(2, 2, "state")), 0).
        DO ON ERROR UNDO, THROW:
            mCues:Poll(oOther).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    /* End to end: the cues of a real game, through the renderer, reach the player. */
    @Test.
    METHOD PUBLIC VOID TheSoundRendererPlaysTheBiteOfARealGame():
        DEFINE VARIABLE oPlayer   AS RecordingSoundPlayer NO-UNDO.
        DEFINE VARIABLE oRenderer AS SoundRenderer        NO-UNDO.
        oPlayer = NEW RecordingSoundPlayer().
        oRenderer = NEW SoundRenderer(NEW RecordingRenderer(), mCues, oPlayer).
        mGame:SetFood(5, 4).
        mGame:Tick(mGame:StepMs).
        mGame:Tick(mGame:StepMs).
        oRenderer:Render(mGame:Grid, mGame).
        Assert:Equals(N(SnakeCue:Eat), oPlayer:Played).
    END METHOD.

END CLASS.
