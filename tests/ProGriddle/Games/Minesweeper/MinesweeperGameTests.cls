USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Minesweeper.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* The classic rules, one at a time. Boards are set up with LoadBoard so every test knows
   where the mines are: "*" is a mine, "." is not, "/" ends a row. A board is read back as
   text with the symbols of MinesweeperLook:TextSymbols(): # hidden, F flag, ? question,
   . blank open cell, 1 to 8, * mine, X exploded mine, ! wrong flag. */
CLASS ProGriddle.Games.Minesweeper.MinesweeperGameTests:

    DEFINE PRIVATE VARIABLE mGame  AS MinesweeperGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock AS FakeClock       NO-UNDO.
    DEFINE PRIVATE VARIABLE mText  AS TextGridRenderer NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mClock = NEW FakeClock().
        mGame = MinesweeperFactory:Create(9, 9, 10, NEW SeededRandom(1), mClock).
        mText = NEW TextGridRenderer("view", MinesweeperLook:TextSymbols()).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* The board as text, rows joined blankY "/". */
    METHOD PRIVATE CHARACTER Board():
        RETURN REPLACE(mText:ToText(mGame:Grid), CHR(10), "/").
    END METHOD.

    /* Number of mines on the current board. */
    METHOD PRIVATE INTEGER MinesOnBoard(INPUT poGame AS MinesweeperGame):
        RETURN poGame:Grid:Store:CountOf(poGame:Grid:Store:LayerIndex("mine"), 1).
    END METHOD.

    /* Opens every cell that is not a mine, in reading order. */
    METHOD PRIVATE VOID RevealAllSafeCells():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = 0 TO mGame:Grid:Height - 1:
            DO x = 0 TO mGame:Grid:Width - 1:
                IF NOT mGame:MineAt(x, y) THEN mGame:Reveal(x, y).
            END.
        END.
    END METHOD.

    /* ---- a new game ---- */

    @Test.
    METHOD PUBLIC VOID ANewGameHasTheRequestedMinesAndNothingOpen():
        Assert:Equals(10, MinesOnBoard(mGame)).
        Assert:Equals(10, mGame:MineCount).
        Assert:Equals(10, mGame:MinesLeft).
        Assert:Equals(0, mGame:FlagCount).
        Assert:Equals(0, mGame:RevealedCount).
        Assert:Equals(0, mGame:Seconds).
        Assert:Equals(0, mGame:Turn).
        Assert:IsFalse(mGame:Started).
        Assert:IsFalse(mGame:IsOver).
        Assert:IsFalse(mGame:IsWon).
        Assert:IsFalse(mGame:IsLost).
        Assert:Equals("#########/#########/#########/#########/#########/#########/#########/#########/#########", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameSeedMakesTheSameBoardAndAnotherSeedADifferentOne():
        DEFINE VARIABLE a AS MinesweeperGame NO-UNDO.
        DEFINE VARIABLE b AS MinesweeperGame NO-UNDO.
        DEFINE VARIABLE c AS MinesweeperGame NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE sameAB AS LOGICAL NO-UNDO INITIAL TRUE.
        DEFINE VARIABLE sameAC AS LOGICAL NO-UNDO INITIAL TRUE.
        DO ON ERROR UNDO, THROW:
            a = MinesweeperFactory:Create(9, 9, 10, NEW SeededRandom(7), NEW FakeClock()).
            b = MinesweeperFactory:Create(9, 9, 10, NEW SeededRandom(7), NEW FakeClock()).
            c = MinesweeperFactory:Create(9, 9, 10, NEW SeededRandom(8), NEW FakeClock()).
            DO y = 0 TO 8:
                DO x = 0 TO 8:
                    IF a:MineAt(x, y) <> b:MineAt(x, y) THEN sameAB = FALSE.
                    IF a:MineAt(x, y) <> c:MineAt(x, y) THEN sameAC = FALSE.
                END.
            END.
            Assert:IsTrue(sameAB).
            Assert:IsFalse(sameAC).
            FINALLY:
                IF VALID-OBJECT(a) THEN a:Dispose().
                IF VALID-OBJECT(b) THEN b:Dispose().
                IF VALID-OBJECT(c) THEN c:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABoardThatIsAlmostAllMinesStillGetsExactlyTheRightNumber():
        DEFINE VARIABLE g AS MinesweeperGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:Create(5, 5, 24, NEW SeededRandom(3), NEW FakeClock()).
            Assert:Equals(24, MinesOnBoard(g)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMoreThanHalfFullBoardHasExactlyTheRightNumberOfMines():
        DEFINE VARIABLE g AS MinesweeperGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:Create(9, 9, 60, NEW SeededRandom(11), NEW FakeClock()).
            Assert:Equals(60, MinesOnBoard(g)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheAdjacentLayerCountsTheNeighbouringMines():
        mGame:LoadBoard("*../.*./..*").
        Assert:Equals(2, mGame:AdjacentAt(1, 0)).
        Assert:Equals(2, mGame:AdjacentAt(1, 1)).
        Assert:Equals(2, mGame:AdjacentAt(2, 1)).
        Assert:Equals(1, mGame:AdjacentAt(0, 0)).
        Assert:Equals(1, mGame:AdjacentAt(2, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LoadBoardResizesTheBoardAndStartsAFreshGame():
        mGame:LoadBoard("*..../...../....*").
        Assert:Equals(5, mGame:Grid:Width).
        Assert:Equals(3, mGame:Grid:Height).
        Assert:Equals(2, mGame:MineCount).
        Assert:IsTrue(mGame:MineAt(0, 0)).
        Assert:IsTrue(mGame:MineAt(4, 2)).
        Assert:IsFalse(mGame:MineAt(1, 1)).
        Assert:Equals("#####/#####/#####", Board()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID LoadBoardWithRaggedRowsThrows():
        mGame:LoadBoard("*../..").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID LoadBoardWithNoMinesThrows():
        mGame:LoadBoard(".../...").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID LoadBoardWithNothingThrows():
        mGame:LoadBoard("").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ConfigureChangesTheSizeAndTheMineCount():
        mGame:Configure(16, 16, 40).
        Assert:Equals(16, mGame:Grid:Width).
        Assert:Equals(16, mGame:Grid:Height).
        Assert:Equals(40, mGame:MineCount).
        Assert:Equals(40, MinesOnBoard(mGame)).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ConfigureWithTheSameSizeKeepsTheGridAndStartsANewGame():
        DEFINE VARIABLE before AS Grid NO-UNDO.
        before = mGame:Grid.
        mGame:ToggleFlag(0, 0).
        mGame:Configure(9, 9, 12).
        Assert:IsTrue(before = mGame:Grid).
        Assert:Equals(12, MinesOnBoard(mGame)).
        Assert:Equals(0, mGame:FlagCount).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConfigureWithNoMinesThrows():
        mGame:Configure(9, 9, 0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConfigureWithAMineOnEveryCellThrows():
        mGame:Configure(3, 3, 9).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConfigureWithAnEmptyBoardThrows():
        mGame:Configure(0, 5, 1).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConfigureWithTooManyCellsThrows():
        mGame:Configure(400, 400, 10).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheConstructorRefusesAnythingThatIsNotAMinesweeperBoard():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE g      AS MinesweeperGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW MinesweeperGame(NEW Grid(NEW TableStore(5, 5, "mine,revealed,flag,adjacent")), 3, NEW SeededRandom(1), NEW FakeClock()).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = NEW MinesweeperGame(NEW Grid(NEW TableStore(5, 5, "mine,revealed,flag,adjacent,other")), 3, NEW SeededRandom(1), NEW FakeClock()).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = NEW MinesweeperGame(NEW Grid(NEW TableStore(5, 5, MinesweeperFactory:Layers()), NEW ToroidalTopology(), NEW MooreNeighbourhood()), 3, NEW SeededRandom(1), NEW FakeClock()).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = NEW MinesweeperGame(NEW Grid(NEW TableStore(5, 5, MinesweeperFactory:Layers()), NEW BoundedTopology(), NEW VonNeumannNeighbourhood()), 3, NEW SeededRandom(1), NEW FakeClock()).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:Create(5, 5, 0, NEW SeededRandom(1), NEW FakeClock()).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:Create(5, 5, 3, ?, NEW FakeClock()).
            CATCH e6 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:Create(5, 5, 3, NEW SeededRandom(1), ?).
            CATCH e7 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(7, thrown).
    END METHOD.

    /* ---- opening cells ---- */

    @Test.
    METHOD PUBLIC VOID RevealingANumberOpensThatOneCellOnly():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(1, 1).
        Assert:Equals("###/#1#/###", Board()).
        Assert:Equals(1, mGame:RevealedCount).
        Assert:Equals(1, mGame:Turn).
        Assert:IsTrue(mGame:RevealedAt(1, 1)).
        Assert:IsFalse(mGame:RevealedAt(0, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RevealingABlankCellFloodsOutAndStopsAtTheNumbers():
        mGame:LoadBoard("*..../...../....*").
        mGame:ToggleFlag(4, 0).
        mGame:Reveal(2, 1).
        Assert:Equals("#1..F/11.11/...1#", Board()).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFloodNeverOpensAFlaggedCell():
        mGame:LoadBoard("*..../...../....*").
        mGame:ToggleFlag(4, 0).
        mGame:ToggleFlag(2, 2).
        mGame:Reveal(2, 1).
        Assert:Equals(1, mGame:FlagAt(4, 0)).
        Assert:Equals(1, mGame:FlagAt(2, 2)).
        Assert:IsFalse(mGame:RevealedAt(2, 2)).
        Assert:IsFalse(mGame:RevealedAt(4, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFloodOpensAQuestionMarkedCellAndClearsTheMark():
        mGame:LoadBoard("*..../...../....*").
        mGame:ToggleFlag(3, 0).
        mGame:ToggleFlag(3, 0).
        Assert:Equals(2, mGame:FlagAt(3, 0)).
        mGame:Reveal(2, 1).
        Assert:IsTrue(mGame:RevealedAt(3, 0)).
        Assert:Equals(0, mGame:FlagAt(3, 0)).
        Assert:Equals(".", SUBSTRING(ENTRY(1, Board(), "/"), 4, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARevealedCellCanBeRevealedDirectlyThroughAQuestionMark():
        mGame:LoadBoard("*../.../...").
        mGame:ToggleFlag(1, 1).
        mGame:ToggleFlag(1, 1).
        Assert:Equals("###/#?#/###", Board()).
        mGame:Reveal(1, 1).
        Assert:Equals("###/#1#/###", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RevealingAFlaggedCellDoesNothing():
        mGame:LoadBoard("*../.../...").
        mGame:ToggleFlag(1, 1).
        mGame:Reveal(1, 1).
        Assert:Equals("###/#F#/###", Board()).
        Assert:Equals(1, mGame:Turn).
        Assert:IsFalse(mGame:Started).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RevealingAnOpenCellDoesNothingAndIsNotAMove():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(1, 1).
        mGame:Reveal(1, 1).
        Assert:Equals(1, mGame:Turn).
        Assert:Equals(1, mGame:RevealedCount).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RevealingOffTheBoardThrows():
        mGame:Reveal(9, 0).
    END METHOD.

    /* ---- the first click ---- */

    @Test.
    METHOD PUBLIC VOID AFirstClickOnAMineMovesTheMineToTheFirstFreeCell():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(0, 0).
        Assert:IsFalse(mGame:IsLost).
        Assert:IsFalse(mGame:MineAt(0, 0)).
        Assert:IsTrue(mGame:MineAt(1, 0)).
        Assert:Equals(1, MinesOnBoard(mGame)).
        Assert:Equals("1##/###/###", Board()).
        Assert:Equals(1, mGame:AdjacentAt(0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMovedMineSkipsCellsThatAlreadyHoldOne():
        mGame:LoadBoard("**./.../...").
        mGame:Reveal(0, 0).
        Assert:IsFalse(mGame:MineAt(0, 0)).
        Assert:IsTrue(mGame:MineAt(1, 0)).
        Assert:IsTrue(mGame:MineAt(2, 0)).
        Assert:Equals(2, MinesOnBoard(mGame)).
        Assert:Equals(1, mGame:AdjacentAt(0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFirstClickOnASafeCellMovesNothing():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        Assert:IsTrue(mGame:MineAt(0, 0)).
        Assert:IsTrue(mGame:MineAt(2, 2)).
        Assert:Equals(2, MinesOnBoard(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNeighboursOfAFirstClickCanStillBeMines():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(1, 1).
        Assert:Equals(1, mGame:AdjacentAt(1, 1)).
        Assert:IsTrue(mGame:MineAt(0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstClickIsNeverAMineOnAnyOfManyBoardsOfEveryLevel():
        DEFINE VARIABLE seed  AS INTEGER NO-UNDO.
        DEFINE VARIABLE level AS INTEGER NO-UNDO.
        DEFINE VARIABLE g     AS MinesweeperGame NO-UNDO.
        DEFINE VARIABLE w     AS INTEGER NO-UNDO.
        DEFINE VARIABLE h     AS INTEGER NO-UNDO.
        DEFINE VARIABLE m     AS INTEGER NO-UNDO.
        DEFINE VARIABLE lost  AS INTEGER NO-UNDO.
        DEFINE VARIABLE wrong AS INTEGER NO-UNDO.
        DO level = 1 TO 3:
            w = (IF level = 1 THEN 9 ELSE IF level = 2 THEN 16 ELSE 30).
            h = (IF level = 1 THEN 9 ELSE 16).
            m = (IF level = 1 THEN 10 ELSE IF level = 2 THEN 40 ELSE 99).
            DO seed = 1 TO 25 ON ERROR UNDO, THROW:
                g = MinesweeperFactory:Create(w, h, m, NEW SeededRandom(seed), NEW FakeClock()).
                /* click in the corner, the busiest place for the move to go wrong, and in the middle */
                g:Reveal(0, 0).
                IF g:IsLost THEN lost = lost + 1.
                IF MinesOnBoard(g) <> m THEN wrong = wrong + 1.
                FINALLY:
                    IF VALID-OBJECT(g) THEN g:Dispose().
                END FINALLY.
            END.
        END.
        Assert:Equals(0, lost).
        Assert:Equals(0, wrong).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFullBoardOfMinesButOneStillGivesASafeFirstClick():
        DEFINE VARIABLE g AS MinesweeperGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:Create(3, 3, 8, NEW SeededRandom(5), NEW FakeClock()).
            g:Reveal(1, 1).
            Assert:IsFalse(g:IsLost).
            Assert:Equals(8, MinesOnBoard(g)).
            Assert:IsTrue(g:IsWon).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- losing ---- */

    @Test.
    METHOD PUBLIC VOID OpeningAMineLosesAndShowsTheOtherMinesAndTheWrongFlags():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        mGame:ToggleFlag(0, 0).
        mGame:ToggleFlag(2, 0).
        mGame:Reveal(2, 2).
        Assert:IsTrue(mGame:IsLost).
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mGame:IsWon).
        Assert:Equals("F#!/#2#/##X", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALostGameShowsEveryUnflaggedMine():
        mGame:LoadBoard("*.*/.../*.*").
        mGame:Reveal(1, 1).
        mGame:Reveal(0, 0).
        Assert:IsTrue(mGame:IsLost).
        Assert:Equals("X#*/#4#/*#*", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALostGameStopsTheClockAndIgnoresFurtherMoves():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        Assert:IsTrue(mClock:IsRunning).
        mGame:Reveal(0, 0).
        Assert:IsFalse(mClock:IsRunning).
        mGame:Reveal(2, 0).
        mGame:ToggleFlag(2, 0).
        mGame:Chord(1, 1).
        Assert:Equals("X##/#2#/##*", Board()).
        Assert:Equals(2, mGame:Turn).
        Assert:Equals(0, mGame:FlagCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AQuestionMarkedMineIsShownAsAMineWhenTheGameIsLost():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        mGame:ToggleFlag(2, 2).
        mGame:ToggleFlag(2, 2).
        mGame:Reveal(0, 0).
        Assert:Equals("X##/#2#/##*", Board()).
    END METHOD.

    /* ---- winning ---- */

    @Test.
    METHOD PUBLIC VOID OpeningEveryCellThatIsNotAMineWinsAndFlagsTheMines():
        mGame:LoadBoard("*../.../..*").
        RevealAllSafeCells().
        Assert:IsTrue(mGame:IsWon).
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mGame:IsLost).
        Assert:Equals("F1./121/.1F", Board()).
        Assert:Equals(2, mGame:FlagCount).
        Assert:Equals(0, mGame:MinesLeft).
        Assert:IsFalse(mClock:IsRunning).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFloodThatOpensTheLastSafeCellsWinsTheGame():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(2, 2).
        Assert:IsTrue(mGame:IsWon).
        Assert:Equals("F1./11./...", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WinningDoesNotNeedAnyFlags():
        mGame:LoadBoard("*../.../...").
        Assert:Equals(0, mGame:FlagCount).
        mGame:Reveal(2, 2).
        Assert:IsTrue(mGame:IsWon).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AQuestionMarkedMineIsFlaggedWhenTheGameIsWon():
        mGame:LoadBoard("*../.../...").
        mGame:ToggleFlag(0, 0).
        mGame:ToggleFlag(0, 0).
        Assert:Equals(2, mGame:FlagAt(0, 0)).
        mGame:Reveal(2, 2).
        Assert:IsTrue(mGame:IsWon).
        Assert:Equals(1, mGame:FlagAt(0, 0)).
        Assert:Equals(0, mGame:MinesLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWonGameIgnoresFurtherMoves():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(2, 2).
        mGame:ToggleFlag(0, 0).
        mGame:Reveal(0, 0).
        Assert:IsTrue(mGame:IsWon).
        Assert:Equals(1, mGame:Turn).
        Assert:Equals(1, mGame:FlagAt(0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WinningWithWrongFlagsOnSafeCellsIsNotPossibleUntilTheyAreOpened():
        mGame:LoadBoard("*../.../...").
        mGame:ToggleFlag(2, 2).
        mGame:Reveal(1, 1).
        mGame:Reveal(1, 0).
        mGame:Reveal(0, 1).
        Assert:IsFalse(mGame:IsOver).
        mGame:ToggleFlag(2, 2).
        mGame:ToggleFlag(2, 2).
        mGame:Reveal(2, 2).
        Assert:IsTrue(mGame:IsWon).
    END METHOD.

    /* ---- flags and question marks ---- */

    @Test.
    METHOD PUBLIC VOID ToggleFlagGoesFromNothingToFlagToQuestionMarkAndBack():
        mGame:LoadBoard("*../.../...").
        Assert:Equals(0, mGame:FlagAt(1, 1)).
        mGame:ToggleFlag(1, 1).
        Assert:Equals(1, mGame:FlagAt(1, 1)).
        Assert:Equals(1, mGame:FlagCount).
        Assert:Equals(0, mGame:MinesLeft).
        mGame:ToggleFlag(1, 1).
        Assert:Equals(2, mGame:FlagAt(1, 1)).
        Assert:Equals(0, mGame:FlagCount).
        Assert:Equals(1, mGame:MinesLeft).
        mGame:ToggleFlag(1, 1).
        Assert:Equals(0, mGame:FlagAt(1, 1)).
        Assert:Equals(0, mGame:FlagCount).
        Assert:Equals("###/###/###", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithQuestionMarksOffAFlagGoesStraightBackToNothing():
        mGame:LoadBoard("*../.../...").
        mGame:UseMarks = FALSE.
        mGame:ToggleFlag(1, 1).
        mGame:ToggleFlag(1, 1).
        Assert:Equals(0, mGame:FlagAt(1, 1)).
        Assert:Equals(0, mGame:FlagCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID QuestionMarksAreOnByDefault():
        Assert:IsTrue(mGame:UseMarks).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMineCounterGoesNegativeWithTooManyFlags():
        mGame:LoadBoard("*../.../...").
        mGame:ToggleFlag(1, 0).
        mGame:ToggleFlag(2, 0).
        mGame:ToggleFlag(0, 1).
        Assert:Equals(3, mGame:FlagCount).
        Assert:Equals(-2, mGame:MinesLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnOpenCellCannotBeFlagged():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(1, 1).
        mGame:ToggleFlag(1, 1).
        Assert:Equals(0, mGame:FlagAt(1, 1)).
        Assert:Equals(0, mGame:FlagCount).
        Assert:Equals(1, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FlaggingBeforeTheFirstRevealDoesNotStartTheTimer():
        mGame:LoadBoard("*../.../...").
        mGame:ToggleFlag(2, 2).
        Assert:IsFalse(mGame:Started).
        Assert:IsFalse(mClock:IsRunning).
        Assert:Equals(0, mGame:Seconds).
        mClock:Advance(5000).
        Assert:Equals(0, mGame:Seconds).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FlagsAndQuestionMarksAreMovesButANoOpIsNot():
        mGame:LoadBoard("*../.../...").
        mGame:ToggleFlag(1, 1).
        mGame:ToggleFlag(1, 1).
        Assert:Equals(2, mGame:Turn).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID FlaggingOffTheBoardThrows():
        mGame:ToggleFlag(-1, 0).
    END METHOD.

    /* ---- chording ---- */

    @Test.
    METHOD PUBLIC VOID AChordWithTheRightNumberOfFlagsOpensTheRestOfTheNeighbours():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(1, 1).
        mGame:ToggleFlag(0, 0).
        mGame:Chord(1, 1).
        Assert:Equals("F1./11./...", Board()).
        Assert:IsTrue(mGame:IsWon).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AChordWithTooFewFlagsDoesNothingAndIsNotAMove():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(1, 1).
        mGame:Chord(1, 1).
        Assert:Equals("###/#1#/###", Board()).
        Assert:Equals(1, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AChordWithTooManyFlagsDoesNothing():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(1, 1).
        mGame:ToggleFlag(0, 0).
        mGame:ToggleFlag(1, 0).
        mGame:Chord(1, 1).
        Assert:Equals("FF#/#1#/###", Board()).
        Assert:IsFalse(mGame:RevealedAt(2, 2)).
        Assert:Equals(3, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID QuestionMarksDoNotCountAsFlagsForAChord():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(1, 1).
        mGame:ToggleFlag(0, 0).
        mGame:ToggleFlag(0, 0).
        mGame:Chord(1, 1).
        Assert:IsFalse(mGame:RevealedAt(2, 2)).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AChordWithAWrongFlagOpensAMineAndLoses():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        mGame:ToggleFlag(1, 0).
        mGame:ToggleFlag(0, 1).
        mGame:Chord(1, 1).
        Assert:IsTrue(mGame:IsLost).
        Assert:Equals(1, mGame:Grid:Store:CountOf(mGame:Grid:Store:LayerIndex("view"), 13)).
        Assert:Equals(2, mGame:Grid:Store:CountOf(mGame:Grid:Store:LayerIndex("view"), 14)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AChordLeavesTheFlaggedMinesClosed():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        mGame:ToggleFlag(0, 0).
        mGame:ToggleFlag(2, 2).
        mGame:Chord(1, 1).
        Assert:IsTrue(mGame:IsWon).
        Assert:IsFalse(mGame:RevealedAt(0, 0)).
        Assert:IsFalse(mGame:RevealedAt(2, 2)).
        Assert:Equals("F1./121/.1F", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AChordOnAClosedCellOrABlankCellDoesNothing():
        mGame:LoadBoard("*..../...../....*").
        mGame:Chord(2, 1).
        Assert:Equals(0, mGame:Turn).
        mGame:ToggleFlag(4, 0).
        mGame:Reveal(2, 1).
        mGame:Chord(2, 1).
        Assert:Equals(2, mGame:Turn).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AChordOffTheBoardThrows():
        mGame:Chord(0, 20).
    END METHOD.

    /* ---- the timer ---- */

    @Test.
    METHOD PUBLIC VOID TheTimerStartsAtOneOnTheFirstRevealAndCountsSeconds():
        mGame:LoadBoard("*../.../..*").
        Assert:Equals(0, mGame:Seconds).
        mGame:Reveal(1, 1).
        Assert:Equals(1, mGame:Seconds).
        Assert:IsTrue(mClock:IsRunning).
        mClock:Advance(3000).
        Assert:Equals(4, mGame:Seconds).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTimerStopsWhenTheGameEnds():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        mClock:Advance(2000).
        mGame:Reveal(0, 0).
        mClock:Advance(5000).
        Assert:Equals(3, mGame:Seconds).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTimerStopsOnAWinToo():
        mGame:LoadBoard("*../.../...").
        mGame:Reveal(1, 1).
        mClock:Advance(4000).
        mGame:Reveal(2, 2).
        mClock:Advance(9000).
        Assert:IsTrue(mGame:IsWon).
        Assert:Equals(5, mGame:Seconds).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTimerStopsAtNineHundredAndNinetyNine():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        mClock:Advance(1500000).
        Assert:Equals(999, mGame:Seconds).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameStopsAndZeroesTheTimer():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        mClock:Advance(5000).
        mGame:Initialise().
        Assert:Equals(0, mGame:Seconds).
        Assert:IsFalse(mClock:IsRunning).
        Assert:IsFalse(mGame:Started).
    END METHOD.

    /* ---- a new game after a game ---- */

    @Test.
    METHOD PUBLIC VOID InitialiseStartsAFreshBoardWithTheSameSizeAndMines():
        mGame:Reveal(4, 4).
        mGame:ToggleFlag(0, 0).
        mGame:Initialise().
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(0, mGame:FlagCount).
        Assert:Equals(0, mGame:RevealedCount).
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(10, MinesOnBoard(mGame)).
        Assert:Equals(9, mGame:Grid:Width).
        Assert:Equals("#########/#########/#########/#########/#########/#########/#########/#########/#########", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseAfterALossMakesAPlayableGameAgain():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        mGame:Reveal(0, 0).
        Assert:IsTrue(mGame:IsLost).
        mGame:Initialise().
        Assert:IsFalse(mGame:IsLost).
        Assert:IsFalse(mGame:IsOver).
        mGame:Reveal(1, 1).
        Assert:IsTrue(mGame:RevealedCount > 0).
    END METHOD.

    /* ---- a whole game on a real size ---- */

    @Test.
    METHOD PUBLIC VOID ABeginnerGameCanBeWonByOpeningEverySafeCell():
        mGame:Reveal(4, 4).
        RevealAllSafeCells().
        Assert:IsTrue(mGame:IsWon).
        Assert:Equals(71, mGame:RevealedCount).
        Assert:Equals(10, mGame:FlagCount).
        Assert:Equals(0, mGame:MinesLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnExpertBoardFloodsWithoutTroubleAndTheCountsAddUp():
        DEFINE VARIABLE g AS MinesweeperGame NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:Create(30, 16, 99, NEW SeededRandom(2), NEW FakeClock()).
            g:Reveal(15, 8).
            DO y = 0 TO 15:
                DO x = 0 TO 29:
                    IF NOT g:MineAt(x, y) AND g:RevealedAt(x, y) THEN
                        Assert:IsTrue(g:ViewAt(x, y) = 3 + g:AdjacentAt(x, y)).
                END.
            END.
            Assert:IsTrue(g:RevealedCount >= 1).
            Assert:IsFalse(g:IsLost).
            Assert:Equals(g:RevealedCount, g:Grid:Store:CountOf(g:Grid:Store:LayerIndex("revealed"), 1)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnOpenBoardFloodsAllTheWayRoundWithoutOverflowingTheStack():
        /* one mine in the middle of a 30 x 24 board: a click in the corner opens every other cell */
        DEFINE VARIABLE y    AS INTEGER NO-UNDO.
        DEFINE VARIABLE rows AS CHARACTER NO-UNDO.
        DO y = 0 TO 23:
            rows = rows + (IF y > 0 THEN "/" ELSE "") + (IF y = 12 THEN FILL(".", 15) + "*" + FILL(".", 14) ELSE FILL(".", 30)).
        END.
        mGame:LoadBoard(rows).
        mGame:Reveal(0, 0).
        Assert:IsTrue(mGame:IsWon).
        Assert:Equals(30 * 24 - 1, mGame:RevealedCount).
        Assert:Equals(1, mGame:Turn).
    END METHOD.

    /* ---- lifetime ---- */

    @Test.
    METHOD PUBLIC VOID TheGameNameAndTurnBasedKind():
        Assert:Equals("Minesweeper", mGame:Name).
        Assert:IsTrue(TYPE-OF(mGame, ITurnBasedGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeStopsListeningToTheClockAndCanBeCalledTwice():
        mGame:LoadBoard("*../.../..*").
        mGame:Reveal(1, 1).
        mGame:Dispose().
        mClock:Advance(5000).
        mGame:Dispose().
        Assert:IsFalse(mClock:IsRunning).
        mGame = ?.
    END METHOD.

END CLASS.
