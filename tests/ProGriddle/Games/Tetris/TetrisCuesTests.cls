/* The cue source of Tetris, with real games driven by hand: each event is reported once, in the order of importance, and a new game
   forgets the old one. Cue numbers are INTEGER(TetrisCue:...). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisCuesTests:

    DEFINE PRIVATE VARIABLE mGame AS TetrisGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mCues AS TetrisCues NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildCues():
        mGame = TetrisFactory:Create(NEW SeededRandom(1)).
        mGame:StartWith("I,I,I,I,I,I,I,I,I,I,I,I").
        mCues = NEW TetrisCues().
        /* the first look takes the game as it is */
        mCues:Poll(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCues():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
        mCues = ?.
    END METHOD.

    METHOD PRIVATE CHARACTER N(INPUT poCue AS TetrisCue):
        RETURN STRING(INTEGER(poCue)).
    END METHOD.

    /* turns the I piece upright and drops it in the gap at the right of "IIIIIII.II", which fills the bottom row */
    METHOD PRIVATE VOID DropIntoTheGap():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mGame:RotateClockwise().
        DO i = 1 TO 3:
            mGame:MoveRight().
        END.
        mGame:HardDrop().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameAndAQuietTickGiveNoCues():
        Assert:Equals("", mCues:Poll(mGame)).
        mGame:Tick(100).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceSettlingIsOneLockAndIsReportedOnce():
        mGame:HardDrop().
        Assert:Equals(N(TetrisCue:Lock), mCues:Poll(mGame)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TwoPiecesSettlingBetweenLooksAreOneLockCueAndTheNextLockIsAnotherOne():
        mGame:HardDrop().
        mGame:HardDrop().
        /* one look sees two pieces settle: one cue, since a poll says what is new and a lock is a lock */
        Assert:Equals(N(TetrisCue:Lock), mCues:Poll(mGame)).
        mGame:HardDrop().
        Assert:Equals(N(TetrisCue:Lock), mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AClearComesBeforeTheLockThatMadeIt():
        mGame:LoadLocked("IIIIIII.II").
        DropIntoTheGap().
        Assert:Equals(N(TetrisCue:Clear) + "," + N(TetrisCue:Lock), mCues:Poll(mGame)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AClearOfFourRowsIsATetris():
        mGame:LoadLocked("IIIIIIIII./IIIIIIIII./IIIIIIIII./IIIIIIIII.").
        mGame:RotateClockwise().
        mGame:MoveRight().
        mGame:MoveRight().
        mGame:MoveRight().
        mGame:MoveRight().
        mGame:MoveRight().
        mGame:MoveRight().
        mGame:HardDrop().
        Assert:Equals(4, mGame:LastClearCount).
        Assert:Equals(N(TetrisCue:Tetris) + "," + N(TetrisCue:Lock), mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTenthLineGivesALevelUpAfterTheClearAndTheLock():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cues   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE levels AS INTEGER   NO-UNDO.
        DO i = 1 TO 10:
            mGame:Tick(5).
            mGame:LoadLocked("IIIIIII.II").
            DropIntoTheGap().
            cues = mCues:Poll(mGame).
            IF LOOKUP(N(TetrisCue:LevelUp), cues) > 0 THEN levels = levels + 1.
        END.
        Assert:Equals(2, mGame:Level).
        Assert:Equals(1, levels).
        Assert:Equals(N(TetrisCue:Clear) + "," + N(TetrisCue:Lock) + "," + N(TetrisCue:LevelUp), cues).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStackReachingTheTopGivesOneDangerAndTheEndOneGameOverFirst():
        DEFINE VARIABLE drops  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cues   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE dangers AS INTEGER  NO-UNDO.
        DEFINE VARIABLE overs  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE order  AS CHARACTER NO-UNDO.
        mGame:StartWith("O,O,O,O,O,O,O,O,O,O,O,O,O,O,O,O").
        mCues:Poll(mGame).
        DO WHILE NOT mGame:IsOver AND drops < 20:
            mGame:HardDrop().
            drops = drops + 1.
            cues = mCues:Poll(mGame).
            IF LOOKUP(N(TetrisCue:Danger), cues) > 0 THEN dangers = dangers + 1.
            IF LOOKUP(N(TetrisCue:GameOver), cues) > 0 THEN overs = overs + 1.
        END.
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(1, dangers).
        Assert:Equals(1, overs).
        /* the last poll: the end first, then the lock that caused it */
        Assert:Equals(N(TetrisCue:GameOver) + "," + N(TetrisCue:Lock), cues).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameForgetsTheOldOneAndSoundsAgain():
        mGame:HardDrop().
        mGame:StartWith("I,I,I").
        /* the lock of the old game does not sound, and the new game starts quiet */
        Assert:Equals("", mCues:Poll(mGame)).
        mGame:HardDrop().
        Assert:Equals(N(TetrisCue:Lock), mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGroupsPutTheImpactTogetherAndGiveTheLevelUpAndTheDangerTheirOwn():
        Assert:Equals(mCues:GroupOf(INTEGER(TetrisCue:Lock)), mCues:GroupOf(INTEGER(TetrisCue:Clear))).
        Assert:Equals(mCues:GroupOf(INTEGER(TetrisCue:Lock)), mCues:GroupOf(INTEGER(TetrisCue:Tetris))).
        Assert:Equals(mCues:GroupOf(INTEGER(TetrisCue:Lock)), mCues:GroupOf(INTEGER(TetrisCue:GameOver))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(TetrisCue:LevelUp)) <> mCues:GroupOf(INTEGER(TetrisCue:Lock))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(TetrisCue:Danger)) <> mCues:GroupOf(INTEGER(TetrisCue:Lock))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(TetrisCue:Danger)) <> mCues:GroupOf(INTEGER(TetrisCue:LevelUp))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsNotTetrisThrowsGridException():
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
    METHOD PUBLIC VOID TheSoundRendererPlaysTheCuesOfARealGame():
        DEFINE VARIABLE oPlayer   AS RecordingSoundPlayer NO-UNDO.
        DEFINE VARIABLE oRenderer AS SoundRenderer        NO-UNDO.
        oPlayer = NEW RecordingSoundPlayer().
        oRenderer = NEW SoundRenderer(NEW RecordingRenderer(), mCues, oPlayer).
        mGame:LoadLocked("IIIIIII.II").
        DropIntoTheGap().
        oRenderer:Render(mGame:Grid, mGame).
        /* the clear and the lock are one group: only the clear is heard */
        Assert:Equals(N(TetrisCue:Clear), oPlayer:Played).
    END METHOD.

END CLASS.
