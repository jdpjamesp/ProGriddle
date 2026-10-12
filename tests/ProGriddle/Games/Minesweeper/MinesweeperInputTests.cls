USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Minesweeper.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS MinesweeperGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock    AS FakeClock       NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings  NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS MinesweeperInput NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mClock = NEW FakeClock().
        mSettings = NEW MemorySettings().
        mGame = MinesweeperFactory:Create(9, 9, 10, NEW SeededRandom(1), mClock).
        mInput = NEW MinesweeperInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* ---- the picker ---- */

    @Test.
    METHOD PUBLIC VOID TheLevelPickerOffersTheFourLevels():
        Assert:Equals("Level", mInput:ChoiceLabel).
        Assert:Equals("Beginner,Intermediate,Expert,Custom", mInput:ChoiceNames).
        Assert:Equals("Beginner", mInput:Choice).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStartingLevelIsTheOneThatMatchesTheGame():
        DEFINE VARIABLE g AS MinesweeperGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = MinesweeperFactory:Create(16, 16, 40, NEW SeededRandom(1), NEW FakeClock()).
            Assert:Equals("Intermediate", NEW MinesweeperInput(g, mSettings):Choice).
            g:Dispose().
            g = MinesweeperFactory:Create(12, 10, 15, NEW SeededRandom(1), NEW FakeClock()).
            Assert:Equals("Custom", NEW MinesweeperInput(g, mSettings):Choice).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingALevelStartsANewGameOfThatLevel():
        mGame:Reveal(4, 4).
        mInput:Choice = "Expert".
        Assert:Equals("Expert", mInput:Choice).
        Assert:Equals(30, mGame:Grid:Width).
        Assert:Equals(16, mGame:Grid:Height).
        Assert:Equals(99, mGame:MineCount).
        Assert:Equals(0, mGame:Turn).
        mInput:Choice = "intermediate".
        Assert:Equals("Intermediate", mInput:Choice).
        Assert:Equals(16, mGame:Grid:Width).
        Assert:Equals(40, mGame:MineCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingTheSameLevelAgainStillStartsANewGame():
        mGame:Reveal(4, 4).
        mInput:Choice = "Beginner".
        Assert:Equals(0, mGame:Turn).
        Assert:IsFalse(mGame:Started).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CustomUsesTheSizeFromTheSettings():
        mSettings:SetInteger("minesweeper.customWidth", 20).
        mSettings:SetInteger("minesweeper.customHeight", 12).
        mSettings:SetInteger("minesweeper.customMines", 30).
        mInput = NEW MinesweeperInput(mGame, mSettings).
        mInput:Choice = "Custom".
        Assert:Equals(20, mGame:Grid:Width).
        Assert:Equals(12, mGame:Grid:Height).
        Assert:Equals(30, mGame:MineCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CustomValuesOutOfRangeAreBroughtBackIn():
        mSettings:SetInteger("minesweeper.customWidth", 2).
        mSettings:SetInteger("minesweeper.customHeight", 100).
        mSettings:SetInteger("minesweeper.customMines", 5000).
        mInput = NEW MinesweeperInput(mGame, mSettings).
        mInput:Choice = "Custom".
        Assert:Equals(9, mGame:Grid:Width).
        Assert:Equals(24, mGame:Grid:Height).
        Assert:Equals(8 * 23, mGame:MineCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CustomWithNothingInTheSettingsIsNineByNineWithTenMines():
        mInput:Choice = "Expert".
        mInput:Choice = "Custom".
        Assert:Equals(9, mGame:Grid:Width).
        Assert:Equals(9, mGame:Grid:Height).
        Assert:Equals(10, mGame:MineCount).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownLevelThrows():
        mInput:Choice = "Nightmare".
    END METHOD.

    /* ---- clicks ---- */

    @Test.
    METHOD PUBLIC VOID ALeftClickOpensACell():
        mGame:LoadBoard("*../.../...").
        mInput:PrimaryAction(1, 1).
        Assert:IsTrue(mGame:RevealedAt(1, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARightClickCyclesTheFlag():
        mGame:LoadBoard("*../.../...").
        mInput:SecondaryAction(2, 2).
        Assert:Equals(1, mGame:FlagAt(2, 2)).
        mInput:SecondaryAction(2, 2).
        Assert:Equals(2, mGame:FlagAt(2, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BothButtonsChord():
        mGame:LoadBoard("*../.../...").
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(0, 0).
        mInput:TertiaryAction(1, 1).
        Assert:IsTrue(mGame:IsWon).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AClickOffTheBoardIsIgnored():
        mInput:PrimaryAction(-1, 0).
        mInput:PrimaryAction(9, 9).
        mInput:SecondaryAction(0, -3).
        mInput:SecondaryAction(40, 0).
        mInput:TertiaryAction(-5, -5).
        mInput:TertiaryAction(0, 12).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    /* ---- the status line ---- */

    @Test.
    METHOD PUBLIC VOID TheStatusLineBeforeAnyMove():
        Assert:Equals("Beginner 9 x 9   Mines 010   Time 000   Ready   Best -   Marks on", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineWhilePlayingShowsFlagsAndTime():
        mGame:LoadBoard("*../.../..*").
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(0, 0).
        mClock:Advance(6000).
        Assert:Equals("Beginner 3 x 3   Mines 001   Time 007   Playing   Best -   Marks on", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMineCounterGoesNegativeInTheStatusLine():
        mGame:LoadBoard("*../.../..*").
        mInput:SecondaryAction(0, 1).
        mInput:SecondaryAction(1, 0).
        mInput:SecondaryAction(2, 0).
        Assert:Equals("Beginner 3 x 3   Mines -01   Time 000   Ready   Best -   Marks on", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysGameOverOnALoss():
        mGame:LoadBoard("*../.../..*").
        mInput:PrimaryAction(1, 1).
        mInput:PrimaryAction(0, 0).
        Assert:Equals("Beginner 3 x 3   Mines 002   Time 001   Game over   Best -   Marks on", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysYouWinOnAWinAndShowsTheBestTime():
        mGame:LoadBoard("*../.../...").
        mInput:PrimaryAction(1, 1).
        mClock:Advance(11000).
        mInput:PrimaryAction(2, 2).
        Assert:Equals("Beginner 3 x 3   Mines 000   Time 012   You win!   Best 12s   Marks on", mInput:StatusText).
    END METHOD.

    /* ---- best times ---- */

    @Test.
    METHOD PUBLIC VOID AWinOnAStandardLevelSavesTheTimeInTheSettings():
        mGame:LoadBoard("*../.../...").
        mInput:PrimaryAction(1, 1).
        mClock:Advance(4000).
        mInput:PrimaryAction(2, 2).
        Assert:Equals("5", mSettings:GetString("minesweeper.scores.beginner", "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWinByChordingSavesTheTimeToo():
        mGame:LoadBoard("*../.../...").
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(0, 0).
        mClock:Advance(2000).
        mInput:TertiaryAction(1, 1).
        Assert:IsTrue(mGame:IsWon).
        Assert:Equals("3", mSettings:GetString("minesweeper.scores.beginner", "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASlowerWinJoinsTheListBelowTheBestTime():
        mSettings:SetString("minesweeper.scores.beginner", "4").
        mGame:LoadBoard("*../.../...").
        mInput:PrimaryAction(1, 1).
        mClock:Advance(9000).
        mInput:PrimaryAction(2, 2).
        Assert:Equals("4,10", mSettings:GetString("minesweeper.scores.beginner", "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALossSavesNoTime():
        mGame:LoadBoard("*../.../..*").
        mInput:PrimaryAction(1, 1).
        mInput:PrimaryAction(0, 0).
        Assert:IsFalse(mSettings:Has("minesweeper.scores.beginner")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACustomWinSavesNoTime():
        mInput:Choice = "Custom".
        mGame:LoadBoard("*../.../...").
        mInput:PrimaryAction(1, 1).
        mInput:PrimaryAction(2, 2).
        Assert:IsTrue(mGame:IsWon).
        Assert:IsFalse(mSettings:Has("minesweeper.scores.custom")).
        Assert:IsFalse(mSettings:Has("minesweeper.scores.beginner")).
    END METHOD.

    /* ---- the Marks command ---- */

    @Test.
    METHOD PUBLIC VOID MarksIsTheOnlyCommandAndHasAKey():
        Assert:Equals("Marks:M", mInput:CommandNames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MarksSwitchesQuestionMarksOffAndOnAndRemembersIt():
        Assert:IsTrue(mGame:UseMarks).
        mInput:Perform("Marks").
        Assert:IsFalse(mGame:UseMarks).
        Assert:IsFalse(mSettings:GetLogical("minesweeper.marks", TRUE)).
        Assert:Equals("Beginner 9 x 9   Mines 010   Time 000   Ready   Best -   Marks off", mInput:StatusText).
        mInput:Perform("Marks").
        Assert:IsTrue(mGame:UseMarks).
        Assert:IsTrue(mSettings:GetLogical("minesweeper.marks", FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSavedMarksSettingIsReadWhenTheInputIsBuilt():
        mSettings:SetLogical("minesweeper.marks", FALSE).
        mInput = NEW MinesweeperInput(mGame, mSettings).
        Assert:IsFalse(mGame:UseMarks).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownCommandThrows():
        mInput:Perform("Cheat").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInputNeedsAGameAndSettings():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS MinesweeperInput NO-UNDO.
        DO ON ERROR UNDO, THROW:
            i = NEW MinesweeperInput(?, mSettings).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            i = NEW MinesweeperInput(mGame, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
