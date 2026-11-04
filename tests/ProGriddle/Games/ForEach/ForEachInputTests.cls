/* What the FOR EACH window can do: the arrow keys and W A S D steer (a press is kept until the way opens, so letting go changes
   nothing), Space or Return starts a game from the title and after the end, the plus and minus keys change the speed (50 to
   150 percent, 100 is full speed) and T shows where each phantom is heading. P and Space during play are the window's own pause
   keys, so the game does not take them. The status line shows the score, the best score, the lives and the level, the best score
   is kept in the settings as foreach.hiscore and the speed as foreach.speed. The painter draws the words (READY!, GAME OVER), so the
   banner is always empty, and there is nothing to click. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS ForEachGame     NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS ForEachInput    NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mGame = ForEachFactory:Create(NEW SeededRandom(3)).
        mSettings = NEW MemorySettings().
        mInput = NEW ForEachInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE other AS ForEachInput NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN other = NEW ForEachInput(?, mSettings).
                WHEN 2 THEN other = NEW ForEachInput(mGame, ?).
                WHEN 3 THEN mInput:Perform("nothing").
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInputNeedsAGameAndSettingsAndKnowsNoCommands():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
        Assert:Equals("", mInput:CommandNames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoPickerNoBannerNoExtraScreenAndNothingToClick():
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:BannerText).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
        mInput:PrimaryAction(5, 5).
        mInput:SecondaryAction(5, 5).
        mInput:TertiaryAction(5, 5).
        Assert:Equals(ForEachPhase:Title, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGamesNoticesAreHandedOnOnceAndThenItIsQuiet():
        Assert:Equals("", mInput:TakeNotice()).
        mInput:HandleKey("T").
        Assert:IsTrue(mInput:TakeNotice() <> "").
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    /* ---------------------------------- keys ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheArrowKeysAndWASDSteerDibby():
        Assert:IsTrue(mInput:HandleKey("Up")).
        Assert:Equals(MazeDir:Up, mGame:WantedDir).
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:Equals(MazeDir:Left, mGame:WantedDir).
        Assert:IsTrue(mInput:HandleKey("Down")).
        Assert:Equals(MazeDir:Down, mGame:WantedDir).
        Assert:IsTrue(mInput:HandleKey("Right")).
        Assert:Equals(MazeDir:Right, mGame:WantedDir).
        Assert:IsTrue(mInput:HandleKey("W")).
        Assert:Equals(MazeDir:Up, mGame:WantedDir).
        Assert:IsTrue(mInput:HandleKey("A")).
        Assert:Equals(MazeDir:Left, mGame:WantedDir).
        Assert:IsTrue(mInput:HandleKey("S")).
        Assert:Equals(MazeDir:Down, mGame:WantedDir).
        Assert:IsTrue(mInput:HandleKey("D")).
        Assert:Equals(MazeDir:Right, mGame:WantedDir).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LettingGoOfAKeyKeepsTheDirectionSoDibbyKeepsGoing():
        mInput:HandleKey("Up").
        mInput:ReleaseKey("Up").
        Assert:Equals(MazeDir:Up, mGame:WantedDir).
        mInput:ReleaseKey("").
        Assert:Equals(MazeDir:Up, mGame:WantedDir).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OtherKeysAreNotTakenSoTheWindowKeepsItsOwnMeaningForThem():
        Assert:IsFalse(mInput:HandleKey("P")).
        Assert:IsFalse(mInput:HandleKey("X")).
        Assert:IsFalse(mInput:HandleKey("F2")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceAndReturnStartAGameFromTheTitleScreen():
        Assert:IsTrue(mInput:HandleKey("Space")).
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
        mGame:Dispose().
        mGame = ForEachFactory:Create(NEW SeededRandom(3)).
        mInput = NEW ForEachInput(mGame, mSettings).
        Assert:IsTrue(mInput:HandleKey("Return")).
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceDuringPlayIsLeftToTheWindowToPause():
        ForEachKit:Play(mGame).
        Assert:IsFalse(mInput:HandleKey("Space")).
        Assert:Equals(ForEachPhase:Playing, mGame:Phase).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceAfterGameOverStartsANewGame():
        ForEachKit:Play(mGame).
        mGame:Lives = 1.
        mGame:PlacePhantom(PhantomKind:Mary, mGame:DibbyX, mGame:DibbyY, MazeDir:Left, PhantomMode:Chase).
        ForEachKit:RunUntil(mGame, ForEachPhase:GameOver, 900).
        Assert:IsTrue(mInput:HandleKey("Space")).
        Assert:Equals(ForEachPhase:Ready, mGame:Phase).
        Assert:Equals(3, mGame:Lives).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TWithTheGameInPlayShowsAndHidesThePhantomTargets():
        Assert:IsTrue(mInput:HandleKey("T")).
        Assert:IsTrue(mGame:ShowTargets).
        Assert:IsTrue(mInput:HandleKey("T")).
        Assert:IsFalse(mGame:ShowTargets).
    END METHOD.

    /* ---------------------------------- speed ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheGameStartsAtFullSpeed():
        Assert:Equals(100, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePlusAndMinusKeysChangeTheSpeedByTenPercentAndItIsKept():
        Assert:IsTrue(mInput:HandleKey("Subtract")).
        Assert:Equals(90, mGame:SpeedPercent).
        Assert:Equals(90, mSettings:GetInteger("foreach.speed", 0)).
        Assert:IsTrue(mInput:HandleKey("OemMinus")).
        Assert:Equals(80, mGame:SpeedPercent).
        Assert:IsTrue(mInput:HandleKey("Add")).
        Assert:IsTrue(mInput:HandleKey("Oemplus")).
        Assert:Equals(100, mGame:SpeedPercent).
        Assert:Equals(100, mSettings:GetInteger("foreach.speed", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedStaysBetweenFiftyAndOneHundredAndFifty():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO n = 1 TO 20:
            mInput:HandleKey("Subtract").
        END.
        Assert:Equals(50, mGame:SpeedPercent).
        DO n = 1 TO 20:
            mInput:HandleKey("Add").
        END.
        Assert:Equals(150, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASavedSpeedIsGivenToTheGame():
        DEFINE VARIABLE game2  AS ForEachGame  NO-UNDO.
        DEFINE VARIABLE input2 AS ForEachInput NO-UNDO.
        mSettings:SetInteger("foreach.speed", 70).
        game2 = ForEachFactory:Create(NEW SeededRandom(3)).
        input2 = NEW ForEachInput(game2, mSettings).
        Assert:Equals(70, game2:SpeedPercent).
        game2:Dispose().
    END METHOD.

    /* ---------------------------------- score ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheStatusLineShowsScoreBestScoreLivesAndLevel():
        mGame:StartGame().
        mGame:AddScore(120).
        Assert:IsTrue(INDEX(mInput:StatusText, "Score 120") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Hi 120") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Lives 3") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Level 1") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSavedBestScoreIsGivenToTheGame():
        DEFINE VARIABLE game2  AS ForEachGame  NO-UNDO.
        DEFINE VARIABLE input2 AS ForEachInput NO-UNDO.
        mSettings:SetInteger("foreach.hiscore", 4200).
        game2 = ForEachFactory:Create(NEW SeededRandom(3)).
        input2 = NEW ForEachInput(game2, mSettings).
        Assert:Equals(4200, game2:HiScore).
        game2:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABetterScoreIsWrittenToTheSettingsAndALowerOneIsNot():
        mGame:HiScore = 900.
        Assert:IsTrue(INDEX(mInput:StatusText, "Hi 900") > 0).
        Assert:Equals(900, mSettings:GetInteger("foreach.hiscore", 0)).
        mGame:HiScore = 100.
        mInput:StatusText.
        Assert:Equals(900, mSettings:GetInteger("foreach.hiscore", 0)).
    END METHOD.

END CLASS.
