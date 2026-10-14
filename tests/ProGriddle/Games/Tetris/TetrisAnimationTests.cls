/* What the game says to a painter that draws effects: the time, what just locked, the rows that are clearing (and the
   freeze on a line clear when it is wanted), the level up, the end of the game, the danger of a high stack and whether
   anything is animating. All of it is off by default, so the rules tests are not affected. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisAnimationTests:

    DEFINE PRIVATE VARIABLE mGame AS TetrisGame NO-UNDO.

    METHOD PRIVATE VOID NewGame(INPUT pcPieces AS CHARACTER):
        mGame = TetrisFactory:Create(NEW SeededRandom(1)).
        mGame:StartWith(pcPieces).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* n rows, each full but for a gap at column 7, as one string for LoadLocked. */
    METHOD PRIVATE CHARACTER GappedRows(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DO i = 1 TO piCount:
            result = result + (IF i > 1 THEN "/" ELSE "") + "IIIIIII.II".
        END.
        RETURN result.
    END METHOD.

    /* An I piece stood up in column 7, dropped on the gapped rows: it fills the gaps and clears every row there is. */
    METHOD PRIVATE VOID DropIntoTheGap():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mGame:RotateClockwise().
        DO i = 1 TO 3:
            mGame:MoveRight().
        END.
        mGame:HardDrop().
    END METHOD.

    /* ---------------------------------- the clock ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheGameCountsTheTimeItIsGivenWhetherOrNotItIsAnimated():
        NewGame("I,O,T").
        Assert:Equals(0, mGame:ElapsedMs).
        mGame:Tick(100).
        mGame:Tick(250).
        Assert:Equals(350, mGame:ElapsedMs).
        /* paused time is not counted */
        mGame:Paused = TRUE.
        mGame:Tick(500).
        Assert:Equals(350, mGame:ElapsedMs).
        Assert:IsFalse(mGame:Animated).
        Assert:IsFalse(mGame:Animating).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSerialOfAGameGoesUpWithEveryNewGame():
        DEFINE VARIABLE first1 AS INTEGER NO-UNDO.
        NewGame("I,O,T").
        first1 = mGame:GameSerial.
        mGame:Initialise().
        Assert:Equals(first1 + 1, mGame:GameSerial).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBestScoreIsKeptForThePainterAndRefusesAnythingBelowZero():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        NewGame("I,O,T").
        Assert:Equals(0, mGame:BestScore).
        mGame:BestScore = 38250.
        Assert:Equals(38250, mGame:BestScore).
        DO ON ERROR UNDO, THROW:
            mGame:BestScore = -1.
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    /* ---------------------------------- locking ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ThePieceThatLastLockedIsRememberedWithWhereItCameFromWhenItWasHardDropped():
        NewGame("I,O,T").
        mGame:Tick(40).
        mGame:HardDrop().
        Assert:Equals(1, mGame:LastLockPiece).
        Assert:Equals(0, mGame:LastLockTurn).
        Assert:IsTrue(mGame:LastLockHard).
        Assert:Equals(0, mGame:LastLockFromY).
        Assert:Equals(19, mGame:LastLockY).
        Assert:Equals(3, mGame:LastLockX).
        Assert:Equals(40, mGame:LastLockMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceThatGravitySettlesIsNotAHardDrop():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("O,I,T").
        /* 800 ms a row at level 1: the O (2 high) reaches the floor after 18 steps and settles on the next */
        DO i = 1 TO 19:
            mGame:Tick(800).
        END.
        Assert:Equals(1, mGame:PiecesPlaced).
        Assert:Equals(2, mGame:LastLockPiece).
        Assert:IsFalse(mGame:LastLockHard).
        Assert:Equals(18, mGame:LastLockY).
        Assert:Equals(18, mGame:LastLockFromY).
    END METHOD.

    /* ---------------------------------- clearing lines ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID WithNoClearDelayLinesGoAtOnceButTheGameRemembersWhichRows():
        NewGame("I,I,I").
        mGame:LoadLocked(GappedRows(2)).
        mGame:Tick(10).
        DropIntoTheGap().
        Assert:IsFalse(mGame:Clearing).
        Assert:Equals(2, mGame:LinesCleared).
        Assert:Equals(0, mGame:LockedAt(0, 19)).
        Assert:Equals("18,19", mGame:ClearRows).
        Assert:Equals(2, mGame:LastClearCount).
        Assert:Equals(10, mGame:LastClearMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithAClearDelayTheRowsStayForThreeHundredMillisecondsAndThenGo():
        NewGame("I,I,I").
        mGame:ClearDelayMs = 300.
        mGame:LoadLocked(GappedRows(2)).
        DropIntoTheGap().
        /* the score and the lines are counted at once, the blocks stay, and nothing falls or moves */
        Assert:IsTrue(mGame:Clearing).
        Assert:Equals(2, mGame:LinesCleared).
        Assert:Equals(332, mGame:Score).
        Assert:Equals("18,19", mGame:ClearRows).
        Assert:Equals(1, mGame:LockedAt(0, 19)).
        Assert:Equals(0, mGame:CurrentPiece).
        Assert:IsFalse(mGame:MoveLeft()).
        Assert:IsFalse(mGame:HardDrop()).
        Assert:IsTrue(mGame:Tick(299)).
        Assert:IsTrue(mGame:Clearing).
        Assert:Equals(1, mGame:LockedAt(0, 19)).
        Assert:IsTrue(mGame:Tick(1)).
        Assert:IsFalse(mGame:Clearing).
        Assert:Equals(0, mGame:LockedAt(0, 19)).
        /* what was above the rows (the rest of the piece) has dropped, and the next piece is in the air */
        Assert:Equals(1, mGame:LockedAt(7, 19)).
        Assert:IsTrue(mGame:CurrentPiece > 0).
        Assert:IsTrue(mGame:MoveLeft()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFourLineClearTakesAFortyPercentLongerFreeze():
        NewGame("I,I,I").
        mGame:ClearDelayMs = 300.
        mGame:LoadLocked(GappedRows(4)).
        DropIntoTheGap().
        Assert:IsTrue(mGame:Clearing).
        Assert:Equals(800 * 1, mGame:Score - 32).
        mGame:Tick(419).
        Assert:IsTrue(mGame:Clearing).
        mGame:Tick(1).
        Assert:IsFalse(mGame:Clearing).
        Assert:Equals(0, mGame:LockedAt(7, 19)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TimeThatIsPausedDuringAClearDoesNotCount():
        NewGame("I,I,I").
        mGame:ClearDelayMs = 300.
        mGame:LoadLocked(GappedRows(1)).
        DropIntoTheGap().
        mGame:Tick(200).
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:Tick(1000)).
        mGame:Paused = FALSE.
        Assert:IsTrue(mGame:Clearing).
        mGame:Tick(100).
        Assert:IsFalse(mGame:Clearing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClearDelayIsBetweenZeroAndTwoSeconds():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        NewGame("I,O,T").
        mGame:ClearDelayMs = 2000.
        Assert:Equals(2000, mGame:ClearDelayMs).
        DO ON ERROR UNDO, THROW:
            mGame:ClearDelayMs = -1.
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:ClearDelayMs = 2001.
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TenLinesRaiseTheLevelAndTheGameRemembersWhen():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,I,I,I,I,I,I,I,I,I,I,I").
        Assert:Equals(-1, mGame:LevelUpMs).
        DO i = 1 TO 10:
            mGame:Tick(5).
            mGame:LoadLocked(GappedRows(1)).
            DropIntoTheGap().
        END.
        Assert:Equals(2, mGame:Level).
        Assert:Equals(50, mGame:LevelUpMs).
    END METHOD.

    /* ---------------------------------- animating ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID AnAnimatedGameIsAnimatingForTheStartUpAndAfterEachLockAndThenStopsBeingSo():
        NewGame("I,O,T").
        mGame:Animated = TRUE.
        mGame:Initialise().
        Assert:IsTrue(mGame:Animating).
        mGame:Tick(399).
        Assert:IsTrue(mGame:Animating).
        mGame:Tick(2).
        Assert:IsFalse(mGame:Animating).
        mGame:HardDrop().
        Assert:IsTrue(mGame:Animating).
        mGame:Tick(499).
        Assert:IsTrue(mGame:Animating).
        mGame:Tick(2).
        Assert:IsFalse(mGame:Animating).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TickKeepsSayingSomethingChangedWhileAnimatingEvenWhenNothingMoved():
        NewGame("I,O,T").
        mGame:Animated = TRUE.
        mGame:Initialise().
        Assert:IsTrue(mGame:Tick(10)).
        mGame:Tick(600).
        Assert:IsFalse(mGame:Animating).
        /* 790 of the 800 ms before gravity moves the piece: nothing changes */
        Assert:IsFalse(mGame:Tick(10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADangerouslyHighStackKeepsTheGameAnimatingUntilItDrops():
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE rows AS CHARACTER NO-UNDO.
        NewGame("I,O,T").
        mGame:Animated = TRUE.
        mGame:Initialise().
        mGame:Tick(1000).
        Assert:IsFalse(mGame:Animating).
        Assert:IsFalse(mGame:Danger).
        /* a block in the fourth row from the top (the falling piece, a long way off in the middle, is not in its way) */
        DO i = 1 TO 20:
            rows = rows + (IF i > 1 THEN "/" ELSE "") + (IF i = 4 THEN "I........." ELSE "..........").
        END.
        mGame:LoadLocked(rows).
        Assert:IsTrue(mGame:Danger).
        Assert:IsTrue(mGame:Animating).
        mGame:LoadLocked("........../..........").
        Assert:IsFalse(mGame:Danger).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsOverKeepsAnimatingForAboutThreeAndAHalfSecondsAndRemembersWhenItEnded():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("O,O,O,O,O,O,O,O,O,O,O,O").
        mGame:Animated = TRUE.
        mGame:Initialise().
        mGame:Tick(1000).
        Assert:Equals(-1, mGame:OverMs).
        DO i = 1 TO 12 WHILE NOT mGame:IsOver:
            mGame:HardDrop().
        END.
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(1000, mGame:OverMs).
        Assert:IsTrue(mGame:Animating).
        Assert:IsTrue(mGame:Tick(3000)).
        Assert:IsTrue(mGame:Animating).
        Assert:IsTrue(mGame:Tick(599)).
        Assert:IsFalse(mGame:Tick(2)).
        Assert:IsFalse(mGame:Animating).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithoutAnimationAGameThatIsOverIsQuietAsBefore():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("O,O,O,O,O,O,O,O,O,O,O,O").
        DO i = 1 TO 12 WHILE NOT mGame:IsOver:
            mGame:HardDrop().
        END.
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mGame:Animating).
        Assert:IsFalse(mGame:Tick(100)).
    END METHOD.

END CLASS.
