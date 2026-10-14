/* What the Space Invaders window can do: the keys, as held states, the status line and the saved best score. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.SpaceInvadersInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS SpaceInvadersGame  NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings     NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS SpaceInvadersInput NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mGame = SpaceInvadersFactory:Create(NEW SeededRandom(3)).
        mSettings = NEW MemorySettings().
        mInput = NEW SpaceInvadersInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE other AS SpaceInvadersInput NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN other = NEW SpaceInvadersInput(?, mSettings).
                WHEN 2 THEN other = NEW SpaceInvadersInput(mGame, ?).
                WHEN 3 THEN mInput:Perform("nothing").
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    /* ---------------------------------- steering ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID LeftAndAAndRightAndDSteerTheCannonWhileTheyAreHeld():
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:Equals(-1, mGame:MoveDirection).
        mInput:ReleaseKey("Left").
        Assert:Equals(0, mGame:MoveDirection).
        Assert:IsTrue(mInput:HandleKey("Right")).
        Assert:Equals(1, mGame:MoveDirection).
        mInput:ReleaseKey("Right").
        mInput:HandleKey("A").
        Assert:Equals(-1, mGame:MoveDirection).
        mInput:ReleaseKey("A").
        mInput:HandleKey("D").
        Assert:Equals(1, mGame:MoveDirection).
        mInput:ReleaseKey("D").
        Assert:Equals(0, mGame:MoveDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithBothDirectionKeysDownTheOneThatWentDownLastWins():
        mInput:HandleKey("Left").
        mInput:HandleKey("Right").
        Assert:Equals(1, mGame:MoveDirection).
        mInput:ReleaseKey("Right").
        Assert:Equals(-1, mGame:MoveDirection).
        mInput:HandleKey("Right").
        mInput:HandleKey("Left").
        Assert:Equals(-1, mGame:MoveDirection).
        mInput:ReleaseKey("Left").
        Assert:Equals(1, mGame:MoveDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKeyThatRepeatsWhileHeldChangesNothing():
        mInput:HandleKey("Right").
        mInput:HandleKey("Right").
        mInput:HandleKey("Right").
        Assert:Equals(1, mGame:MoveDirection).
        mInput:ReleaseKey("Right").
        Assert:Equals(0, mGame:MoveDirection).
    END METHOD.

    /* ---------------------------------- firing ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID SpaceUpWAndZAllFireAndFireStaysOnWhileAnyOfThemIsHeld():
        Assert:IsFalse(mGame:FireHeld).
        Assert:IsTrue(mInput:HandleKey("Space")).
        Assert:IsTrue(mGame:FireHeld).
        mInput:HandleKey("Up").
        mInput:ReleaseKey("Space").
        Assert:IsTrue(mGame:FireHeld).
        mInput:ReleaseKey("Up").
        Assert:IsFalse(mGame:FireHeld).
        mInput:HandleKey("W").
        Assert:IsTrue(mGame:FireHeld).
        mInput:ReleaseKey("W").
        mInput:HandleKey("Z").
        Assert:IsTrue(mGame:FireHeld).
        mInput:ReleaseKey("Z").
        Assert:IsFalse(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARepeatedFireKeyIsOneKeyAndOneReleaseLetsGo():
        mInput:HandleKey("Space").
        mInput:HandleKey("Space").
        mInput:ReleaseKey("Space").
        Assert:IsFalse(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MovingAndFiringWorkAtTheSameTime():
        mInput:HandleKey("Left").
        mInput:HandleKey("Space").
        Assert:Equals(-1, mGame:MoveDirection).
        Assert:IsTrue(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyKeyNameLetsGoOfEveryKeyBecauseTheWindowLostTheKeyboard():
        mInput:HandleKey("Left").
        mInput:HandleKey("Right").
        mInput:HandleKey("Space").
        mInput:ReleaseKey("").
        Assert:Equals(0, mGame:MoveDirection).
        Assert:IsFalse(mGame:FireHeld).
        mInput:HandleKey("Right").
        mInput:ReleaseKey(?).
        Assert:Equals(0, mGame:MoveDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OtherKeysAreNotTheGamesAndLettingGoOfThemDoesNothing():
        Assert:IsFalse(mInput:HandleKey("Q")).
        Assert:IsFalse(mInput:HandleKey("P")).
        Assert:IsFalse(mInput:HandleKey(?)).
        mInput:HandleKey("Left").
        mInput:ReleaseKey("Q").
        Assert:Equals(-1, mGame:MoveDirection).
    END METHOD.

    /* ---------------------------------- the words ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysWhatToDoOnTheTitleScreen():
        Assert:Equals("Space Invaders   Hi 0   Press Space to play", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineShowsScoreHiScoreLivesAndWaveInPlay():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        mGame:SkipIntro().
        mGame:AddScore(120).
        Assert:Equals("Score 120   Hi 120   Lives 3   Wave 1", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineOnTheGameOverScreenAsksForSpace():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        mGame:SkipIntro().
        mGame:AddScore(30).
        DO t = 1 TO 3:
            mGame:DropBomb(0, mGame:PlayerX, 205).
            DO n = 1 TO 40:
                IF mGame:Phase <> 2 THEN LEAVE.
                mGame:Advance().
            END.
            DO n = 1 TO 130:
                IF mGame:Phase <> 3 THEN LEAVE.
                mGame:Advance().
            END.
        END.
        Assert:Equals("Game over   Score 30   Hi 30   Press Space", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBannerSaysPausedOnlyWhilePaused():
        Assert:Equals("", mInput:BannerText).
        mGame:Paused = TRUE.
        Assert:Equals("PAUSED", mInput:BannerText).
        mGame:Paused = FALSE.
        Assert:Equals("", mInput:BannerText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoPickerNoCommandsAndNoInfoPanel():
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        mInput:Choice = "anything".
        Assert:Equals("", mInput:Choice).
        Assert:Equals("", mInput:CommandNames).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMouseDoesNothing():
        mInput:PrimaryAction(10, 10).
        mInput:SecondaryAction(10, 10).
        mInput:TertiaryAction(10, 10).
        Assert:Equals(0, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGamesNoticesAreHandedOnOnce():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:AddScore(1500).
        Assert:Equals("Extra cannon", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    /* ---------------------------------- the best score ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheSavedBestScoreIsGivenToTheGame():
        mSettings:SetInteger("spaceinvaders.hiscore", 900).
        mInput = NEW SpaceInvadersInput(mGame, mSettings).
        Assert:Equals(900, mGame:HiScore).
        Assert:Equals("Space Invaders   Hi 900   Press Space to play", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABetterScoreIsWrittenToTheSettingsAndALowerOneIsNot():
        mGame:Advance().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:AddScore(70).
        Assert:Equals(0, mSettings:GetInteger("spaceinvaders.hiscore", 0)).
        mInput:StatusText.
        Assert:Equals(70, mSettings:GetInteger("spaceinvaders.hiscore", 0)).
        mGame:StartGame().
        mGame:AddScore(20).
        mInput:StatusText.
        Assert:Equals(70, mSettings:GetInteger("spaceinvaders.hiscore", 0)).
    END METHOD.

    /* ---------------------------------- contract errors ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheInputNeedsAGameAndSettingsAndKnowsNoCommands():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
    END METHOD.

END CLASS.
