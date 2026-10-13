USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.2048.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.2048.TilesInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS TilesGame     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS TilesInput    NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mSettings = NEW MemorySettings().
        mGame = NEW TilesGame(TilesFactory:CreateGrid(4, 4), NEW ScriptedRandom("5,0")).
        mInput = NEW TilesInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* ---- the keys ---- */

    @Test.
    METHOD PUBLIC VOID TheArrowKeysAndWASDAreAllUsedByTheGame():
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:IsTrue(mInput:HandleKey("Right")).
        Assert:IsTrue(mInput:HandleKey("Up")).
        Assert:IsTrue(mInput:HandleKey("Down")).
        Assert:IsTrue(mInput:HandleKey("A")).
        Assert:IsTrue(mInput:HandleKey("D")).
        Assert:IsTrue(mInput:HandleKey("W")).
        Assert:IsTrue(mInput:HandleKey("S")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLettersMoveTheTilesLikeTheirArrows():
        mGame:StartWith("0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("A").
        Assert:Equals(1, mGame:Grid:Store:GetCellAt(1, 4)).
        mGame:StartWith("0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("D").
        Assert:Equals(1, mGame:Grid:Store:GetCellAt(1, 7)).
        mGame:StartWith("0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("W").
        Assert:Equals(1, mGame:Grid:Store:GetCellAt(1, 1)).
        mGame:StartWith("0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("S").
        Assert:Equals(1, mGame:Grid:Store:GetCellAt(1, 13)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachKeyMovesTheTilesTheWayItSays():
        /* a lone 2 in the second row and second column, then the new tile goes in cell 0 */
        mGame:StartWith("0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("Left").
        Assert:Equals(1, mGame:Grid:Store:GetCellAt(1, 4)).
        mGame:StartWith("0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("Right").
        Assert:Equals(1, mGame:Grid:Store:GetCellAt(1, 7)).
        mGame:StartWith("0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("Up").
        Assert:Equals(1, mGame:Grid:Store:GetCellAt(1, 1)).
        mGame:StartWith("0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("Down").
        Assert:Equals(1, mGame:Grid:Store:GetCellAt(1, 13)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKeyThatMovesNothingIsStillUsedByTheGame():
        mGame:StartWith("1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OtherKeysAreLeftToTheWindow():
        Assert:IsFalse(mInput:HandleKey("R")).
        Assert:IsFalse(mInput:HandleKey("Space")).
        Assert:IsFalse(mInput:HandleKey("Escape")).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheGameIsOverTheKeysAreUsedButDoNothing():
        mGame:StartWith("1,2,1,2,2,1,2,1,1,2,1,2,2,1,2,1").
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReleasingAKeyDoesNothing():
        mInput:ReleaseKey("Left").
        mInput:ReleaseKey("").
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    /* ---- the status line, the banner and the notice ---- */

    @Test.
    METHOD PUBLIC VOID TheStatusLineShowsTheScoreTheBestScoreAndTheBiggestTile():
        mGame:StartWith("2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("Left").
        Assert:Equals("Score 8   Best 8   Biggest tile 8   Playing", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyBoardHasNoBiggestTile():
        mGame:StartWith("0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        Assert:Equals("Score 0   Best 0   Biggest tile 0   Playing", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysWhenTheGameIsOver():
        mGame:StartWith("1,2,1,2,2,1,2,1,1,2,1,2,2,1,2,1").
        Assert:IsTrue(INDEX(mInput:StatusText, "Game over") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBannerSaysGAMEOVEROnlyWhenTheGameIsOver():
        Assert:Equals("", mInput:BannerText).
        mGame:StartWith("1,2,1,2,2,1,2,1,1,2,1,2,2,1,2,1").
        Assert:Equals("GAME OVER", mInput:BannerText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MakingA2048TileGivesOneNoticeAndTheGameGoesOn():
        mGame:StartWith("10,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("Left").
        Assert:Equals("2048! Keep going", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
        Assert:IsTrue(INDEX(mInput:StatusText, "keep going") > 0).
        mInput:HandleKey("Down").
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNoticeIsGivenAgainInTheNextGameThatReaches2048():
        mGame:StartWith("10,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("Left").
        mInput:TakeNotice().
        mGame:Initialise().
        mInput:HandleKey("Left").
        mGame:StartWith("10,10,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("Left").
        Assert:Equals("2048! Keep going", mInput:TakeNotice()).
    END METHOD.

    /* ---- the best score ---- */

    @Test.
    METHOD PUBLIC VOID ABetterScoreBecomesTheBestAndIsKeptInTheSettings():
        mGame:StartWith("2,2,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mInput:HandleKey("Left").
        Assert:Equals(8, mSettings:GetInteger("2048.best", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBestScoreIsReadFromTheSettingsAndNotLowered():
        DEFINE VARIABLE other AS TilesInput NO-UNDO.
        mSettings:SetInteger("2048.best", 500).
        other = NEW TilesInput(mGame, mSettings).
        mGame:StartWith("1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        other:HandleKey("Left").
        Assert:Equals(500, mSettings:GetInteger("2048.best", 0)).
        Assert:IsTrue(INDEX(other:StatusText, "Best 500") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANegativeBestInTheSettingsIsTreatedAsZero():
        mSettings:SetInteger("2048.best", -5).
        mInput = NEW TilesInput(mGame, mSettings).
        Assert:IsTrue(INDEX(mInput:StatusText, "Best 0") > 0).
    END METHOD.

    /* ---- what the window does not get ---- */

    @Test.
    METHOD PUBLIC VOID ThereIsNoPickerNoCommandsAndNoInfoScreen():
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        mInput:Choice = "anything".
        Assert:Equals("", mInput:CommandNames).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClicksDoNothing():
        mGame:StartWith("1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0").
        mInput:PrimaryAction(0, 0).
        mInput:SecondaryAction(1, 1).
        mInput:TertiaryAction(2, 2).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(1, mGame:Grid:Store:GetCellAt(1, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownCommandThrows():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mInput:Perform("Nothing").
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInputNeedsAGameAndSettings():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW TilesInput(?, mSettings).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW TilesInput(mGame, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
