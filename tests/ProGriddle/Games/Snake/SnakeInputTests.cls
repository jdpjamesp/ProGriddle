USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS SnakeGame      NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS SnakeInput     NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mSettings = NEW MemorySettings().
        mGame = NEW SnakeGame(SnakeFactory:CreateGrid(8, 8), NEW ScriptedRandom("0")).
        mInput = NEW SnakeInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* Runs the game until the snake crashes into the right wall. */
    METHOD PRIVATE VOID Crash():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 6:
            mGame:Tick(150).
        END.
    END METHOD.

    /* ---- the keys ---- */

    @Test.
    METHOD PUBLIC VOID TheArrowKeysSteerTheSnake():
        Assert:IsTrue(mInput:HandleKey("Up")).
        mGame:Tick(150).
        Assert:Equals(0, mGame:Direction).
        Assert:IsTrue(mInput:HandleKey("Left")).
        mGame:Tick(150).
        Assert:Equals(3, mGame:Direction).
        Assert:IsTrue(mInput:HandleKey("Down")).
        mGame:Tick(150).
        Assert:Equals(2, mGame:Direction).
        Assert:IsTrue(mInput:HandleKey("Right")).
        mGame:Tick(150).
        Assert:Equals(1, mGame:Direction).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLettersSteerTheSnakeLikeTheirArrows():
        Assert:IsTrue(mInput:HandleKey("W")).
        mGame:Tick(150).
        Assert:Equals(0, mGame:Direction).
        Assert:IsTrue(mInput:HandleKey("A")).
        mGame:Tick(150).
        Assert:Equals(3, mGame:Direction).
        Assert:IsTrue(mInput:HandleKey("S")).
        mGame:Tick(150).
        Assert:Equals(2, mGame:Direction).
        Assert:IsTrue(mInput:HandleKey("D")).
        mGame:Tick(150).
        Assert:Equals(1, mGame:Direction).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKeyThatSteersNowhereIsStillUsedByTheGame():
        /* facing right, so Left would reverse the snake, and Right repeats the way it is going */
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:IsTrue(mInput:HandleKey("Right")).
        mGame:Tick(150).
        Assert:Equals(1, mGame:Direction).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OtherKeysAreLeftToTheWindow():
        Assert:IsFalse(mInput:HandleKey("Space")).
        Assert:IsFalse(mInput:HandleKey("P")).
        Assert:IsFalse(mInput:HandleKey("R")).
        Assert:IsFalse(mInput:HandleKey("Escape")).
        Assert:IsFalse(mInput:HandleKey(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReleasingAKeyDoesNothing():
        mInput:ReleaseKey("Left").
        mInput:ReleaseKey("").
        Assert:Equals(1, mGame:Direction).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterTheGameIsOverTheKeysAreUsedButChangeNothing():
        Crash().
        Assert:IsTrue(mInput:HandleKey("Up")).
        mGame:Tick(150).
        Assert:Equals(1, mGame:Direction).
    END METHOD.

    /* ---- the status line ---- */

    @Test.
    METHOD PUBLIC VOID TheStatusLineShowsTheScoreTheLengthTheLevelAndTheBest():
        Assert:Equals("Score 0   Length 3   Level 1   Best 0", mInput:StatusText).
        mGame:SetFood(5, 4).
        mGame:Tick(150).
        Assert:Equals("Score 10   Length 4   Level 2   Best 10", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysWhenTheSnakeHasCrashed():
        Crash().
        Assert:IsTrue(INDEX(mInput:StatusText, "Game over   Score 0   Length 3") = 1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysWhenTheSnakeHasWon():
        DEFINE VARIABLE body AS CHARACTER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER   NO-UNDO.
        mGame:Dispose().
        mGame = NEW SnakeGame(SnakeFactory:CreateGrid(5, 5), NEW ScriptedRandom("0")).
        mInput = NEW SnakeInput(mGame, mSettings).
        DO y = 0 TO 4:
            DO x = 0 TO 4:
                IF y = 4 AND x = 4 THEN LEAVE.
                body = body + (IF body = "" THEN "" ELSE ";") + SUBSTITUTE("&1,&2", (IF y MODULO 2 = 0 THEN x ELSE 4 - x), y).
            END.
        END.
        mGame:StartWith(body, "Right").
        mGame:Tick(150).
        Assert:IsTrue(INDEX(mInput:StatusText, "You win   Score 10   Length 25") = 1).
        Assert:Equals("YOU WIN", mInput:BannerText).
    END METHOD.

    /* ---- the banner ---- */

    @Test.
    METHOD PUBLIC VOID TheBannerSaysPAUSEDWhilePausedAndGAMEOVERWhenTheSnakeHasCrashed():
        Assert:Equals("", mInput:BannerText).
        mGame:Paused = TRUE.
        Assert:Equals("PAUSED", mInput:BannerText).
        mGame:Paused = FALSE.
        Assert:Equals("", mInput:BannerText).
        Crash().
        Assert:Equals("GAME OVER", mInput:BannerText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GAMEOVERIsShownEvenIfThePausedFlagIsSet():
        Crash().
        mGame:Paused = TRUE.
        Assert:Equals("GAME OVER", mInput:BannerText).
    END METHOD.

    /* ---- the best score ---- */

    @Test.
    METHOD PUBLIC VOID ABetterScoreBecomesTheBestWhenTheGameEndsAndIsKeptInTheSettings():
        mGame:SetFood(5, 4).
        mGame:Tick(150).
        Assert:Equals(0, mSettings:GetInteger("snake.best", 0)).
        mGame:Tick(150).
        mGame:Tick(150).
        mGame:Tick(150).
        Assert:IsTrue(mGame:IsOver).
        Assert:IsTrue(INDEX(mInput:StatusText, "Best 10   New best score") > 0).
        Assert:Equals(10, mSettings:GetInteger("snake.best", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWorseScoreDoesNotLowerTheBestAndSaysNothingAboutIt():
        mSettings:SetInteger("snake.best", 500).
        mInput = NEW SnakeInput(mGame, mSettings).
        mGame:SetFood(5, 4).
        Crash().
        Assert:IsTrue(INDEX(mInput:StatusText, "Best 500") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "New best score") = 0).
        Assert:Equals(500, mSettings:GetInteger("snake.best", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBestScoreIsCountedOncePerGame():
        mGame:SetFood(5, 4).
        Crash().
        mInput:StatusText.
        Assert:Equals(10, mSettings:GetInteger("snake.best", 0)).
        mSettings:SetInteger("snake.best", 3).
        mInput:StatusText.
        Assert:Equals(3, mSettings:GetInteger("snake.best", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameCanSetANewBestAgain():
        mGame:SetFood(5, 4).
        Crash().
        mInput:StatusText.
        mGame:Initialise().
        Assert:IsTrue(INDEX(mInput:StatusText, "New best score") = 0).
        mGame:SetFood(5, 4).
        mGame:Tick(150).
        mGame:SetFood(6, 4).
        mGame:Tick(150).
        Crash().
        Assert:IsTrue(INDEX(mInput:StatusText, "Best 20   New best score") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANegativeBestInTheSettingsIsTreatedAsZero():
        mSettings:SetInteger("snake.best", -4).
        mInput = NEW SnakeInput(mGame, mSettings).
        Assert:IsTrue(INDEX(mInput:StatusText, "Best 0") > 0).
    END METHOD.

    /* ---- waiting for the first key ---- */

    @Test.
    METHOD PUBLIC VOID TheBannerAsksForAnArrowKeyWhileTheGameWaits():
        mGame:WaitForKey = TRUE.
        mGame:Initialise().
        Assert:Equals("PRESS AN ARROW KEY", mInput:BannerText).
        Assert:IsTrue(mInput:HandleKey("Up")).
        Assert:Equals("", mInput:BannerText).
        mGame:Tick(150).
        Assert:Equals(3, mGame:HeadY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PausedComesBeforeWaitingInTheBanner():
        mGame:WaitForKey = TRUE.
        mGame:Initialise().
        mGame:Paused = TRUE.
        Assert:Equals("PAUSED", mInput:BannerText).
    END METHOD.

    /* ---- the board size option ---- */

    @Test.
    METHOD PUBLIC VOID ThereIsOneOptionCalledBoardSavedAsSize():
        Assert:Equals(1, mInput:OptionCount).
        Assert:Equals("Board", mInput:OptionLabel(1)).
        Assert:Equals("size", mInput:OptionKey(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOptionOffersTheUsualSizesAndShowsTheCurrentOne():
        Assert:Equals("8 x 8", mInput:OptionValue(1)).
        Assert:IsTrue(LOOKUP("20 x 20", mInput:OptionNames(1)) > 0).
        Assert:IsTrue(LOOKUP("8 x 8", mInput:OptionNames(1)) > 0).
        Assert:Equals("8 x 8", ENTRY(NUM-ENTRIES(mInput:OptionNames(1)), mInput:OptionNames(1))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASizeThatIsOfferedIsNotAddedAgain():
        mInput:SetOption(1, "20 x 20").
        Assert:Equals(NUM-ENTRIES(SnakeSizes:Names()), NUM-ENTRIES(mInput:OptionNames(1))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingASizeStartsANewGameOnABoardOfThatSize():
        mGame:SetFood(5, 4).
        mGame:Tick(150).
        mInput:SetOption(1, "30 x 20").
        Assert:Equals(30, mGame:Grid:Width).
        Assert:Equals(20, mGame:Grid:Height).
        Assert:Equals("30 x 20", mInput:OptionValue(1)).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(3, mGame:Length).
        Assert:Equals("Board: 30 x 20", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingTheSizeTheBoardAlreadyIsChangesNothing():
        mGame:SetFood(5, 4).
        mGame:Tick(150).
        mInput:SetOption(1, "8 x 8").
        Assert:Equals(10, mGame:Score).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingASizeAfterAGameOverBeginsAFreshGame():
        Crash().
        Assert:IsTrue(mGame:IsOver).
        mInput:SetOption(1, "10 x 10").
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals("", mInput:BannerText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASizeThatIsNotASizeOrIsOutOfRangeIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mInput:SetOption(1, "huge").
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mInput:SetOption(1, "41 x 20").
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mInput:SetOption(1, "20 x 4").
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mInput:SetOption(1, ?).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(4, thrown).
        Assert:Equals("8 x 8", mInput:OptionValue(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyOptionNumberOneExists():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mInput:OptionLabel(2).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mInput:OptionKey(0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mInput:OptionNames(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mInput:OptionValue(3).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mInput:SetOption(2, "10 x 10").
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(5, thrown).
    END METHOD.

    /* ---- what the window does not get ---- */

    @Test.
    METHOD PUBLIC VOID ThereIsNoPickerNoCommandsNoInfoScreenAndNoNoticeToStartWith():
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        mInput:Choice = "anything".
        Assert:Equals("", mInput:CommandNames).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClicksDoNothing():
        mInput:PrimaryAction(0, 0).
        mInput:SecondaryAction(1, 1).
        mInput:TertiaryAction(2, 2).
        Assert:Equals(0, mGame:Generation).
        Assert:Equals(1, mGame:Direction).
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
            NEW SnakeInput(?, mSettings).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW SnakeInput(mGame, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
