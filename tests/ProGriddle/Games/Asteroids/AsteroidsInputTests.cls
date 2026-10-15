/* What the Asteroids window can do: the keys, as held states, the status line and the saved best score and speed. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS AsteroidsGame  NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS AsteroidsInput NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mGame = AsteroidsFactory:Create(NEW SeededRandom(3)).
        mSettings = NEW MemorySettings().
        mInput = NEW AsteroidsInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE other AS AsteroidsInput NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN other = NEW AsteroidsInput(?, mSettings).
                WHEN 2 THEN other = NEW AsteroidsInput(mGame, ?).
                WHEN 3 THEN mInput:Perform("nothing").
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    /* a game in play, with the keys all up */
    METHOD PRIVATE VOID Play():
        mGame:StartGame().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LeftAndAAndRightAndDTurnTheShipWhileTheyAreHeld():
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:Equals(-1, mGame:TurnDirection).
        mInput:ReleaseKey("Left").
        Assert:Equals(0, mGame:TurnDirection).
        Assert:IsTrue(mInput:HandleKey("D")).
        Assert:Equals(1, mGame:TurnDirection).
        mInput:ReleaseKey("D").
        Assert:IsTrue(mInput:HandleKey("A")).
        Assert:Equals(-1, mGame:TurnDirection).
        mInput:ReleaseKey("A").
        Assert:IsTrue(mInput:HandleKey("Right")).
        Assert:Equals(1, mGame:TurnDirection).
        mInput:ReleaseKey("Right").
        Assert:Equals(0, mGame:TurnDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithBothTurnKeysDownTheOneThatWentDownLastWins():
        mInput:HandleKey("Left").
        mInput:HandleKey("Right").
        Assert:Equals(1, mGame:TurnDirection).
        mInput:ReleaseKey("Right").
        Assert:Equals(-1, mGame:TurnDirection).
        mInput:HandleKey("Right").
        mInput:ReleaseKey("Left").
        Assert:Equals(1, mGame:TurnDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID UpAndWThrustAndTheThrustStaysOnWhileEitherIsHeld():
        mInput:HandleKey("Up").
        Assert:IsTrue(mGame:ThrustHeld).
        mInput:HandleKey("W").
        mInput:ReleaseKey("Up").
        Assert:IsTrue(mGame:ThrustHeld).
        mInput:ReleaseKey("W").
        Assert:IsFalse(mGame:ThrustHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceAndZFireAndAKeyThatRepeatsWhileHeldIsStillOneKey():
        Assert:IsTrue(mInput:HandleKey("Space")).
        Assert:IsTrue(mGame:FireHeld).
        mInput:HandleKey("Space").
        mInput:HandleKey("Space").
        mInput:ReleaseKey("Space").
        Assert:IsFalse(mGame:FireHeld).
        mInput:HandleKey("Z").
        Assert:IsTrue(mGame:FireHeld).
        mInput:HandleKey("Space").
        mInput:ReleaseKey("Z").
        Assert:IsTrue(mGame:FireHeld).
        mInput:ReleaseKey("Space").
        Assert:IsFalse(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TurningThrustingAndFiringWorkAtTheSameTime():
        mInput:HandleKey("Left").
        mInput:HandleKey("Up").
        mInput:HandleKey("Space").
        Assert:Equals(-1, mGame:TurnDirection).
        Assert:IsTrue(mGame:ThrustHeld).
        Assert:IsTrue(mGame:FireHeld).
        mInput:ReleaseKey("Up").
        Assert:Equals(-1, mGame:TurnDirection).
        Assert:IsFalse(mGame:ThrustHeld).
        Assert:IsTrue(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyKeyNameLetsGoOfEveryKeyBecauseTheWindowLostTheKeyboard():
        mInput:HandleKey("Left").
        mInput:HandleKey("Up").
        mInput:HandleKey("Space").
        mInput:ReleaseKey("").
        Assert:Equals(0, mGame:TurnDirection).
        Assert:IsFalse(mGame:ThrustHeld).
        Assert:IsFalse(mGame:FireHeld).
        mInput:HandleKey("Right").
        mInput:HandleKey("Z").
        mInput:ReleaseKey(?).
        Assert:Equals(0, mGame:TurnDirection).
        Assert:IsFalse(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OtherKeysAreNotTheGamesAndLettingGoOfThemDoesNothing():
        Assert:IsFalse(mInput:HandleKey("P")).
        Assert:IsFalse(mInput:HandleKey("F2")).
        Assert:IsFalse(mInput:HandleKey("Enter")).
        Assert:IsFalse(mInput:HandleKey(?)).
        mInput:HandleKey("Left").
        mInput:ReleaseKey("P").
        Assert:Equals(-1, mGame:TurnDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DownAndSAreHyperspaceAndAreTheGamesKeys():
        Assert:IsTrue(mInput:HandleKey("Down")).
        Assert:IsTrue(mInput:HandleKey("S")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysWhatToDoOnTheTitleScreen():
        Assert:IsTrue(INDEX(mInput:StatusText, "Press Space") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Asteroids") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineShowsScoreHiScoreShipsWaveAndSpeedInPlay():
        Play().
        Assert:IsTrue(INDEX(mInput:StatusText, "Score 0") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Ships 3") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Wave 1") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Speed 80%") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWindowBannerIsAlwaysEmptyBecauseTheGameDrawsItsOwnPausedScreen():
        Assert:Equals("", mInput:BannerText).
        mGame:Paused = TRUE.
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
        mInput:PrimaryAction(5, 5).
        mInput:SecondaryAction(5, 5).
        mInput:TertiaryAction(5, 5).
        Assert:Equals(0, mGame:TurnDirection).
        Assert:IsFalse(mGame:ThrustHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGamesNoticesAreHandedOn():
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSavedBestScoreIsGivenToTheGame():
        DEFINE VARIABLE game2 AS AsteroidsGame  NO-UNDO.
        DEFINE VARIABLE input2 AS AsteroidsInput NO-UNDO.
        mSettings:SetInteger("asteroids.hiscore", 4200).
        game2 = AsteroidsFactory:Create(NEW SeededRandom(3)).
        input2 = NEW AsteroidsInput(game2, mSettings).
        Assert:Equals(4200, game2:HiScore).
        game2:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABetterScoreIsWrittenToTheSettingsAndALowerOneIsNot():
        mGame:HiScore = 900.
        Assert:IsTrue(INDEX(mInput:StatusText, "Hi 900") > 0).
        Assert:Equals(900, mSettings:GetInteger("asteroids.hiscore", 0)).
        mGame:HiScore = 100.
        mInput:StatusText.
        Assert:Equals(900, mSettings:GetInteger("asteroids.hiscore", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameStartsAtEightyPercentSpeed():
        Assert:Equals(80, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePlusAndMinusKeysChangeTheSpeedByTenPercentAndItIsKept():
        Assert:IsTrue(mInput:HandleKey("Add")).
        Assert:Equals(90, mGame:SpeedPercent).
        Assert:Equals(90, mSettings:GetInteger("asteroids.speed", 0)).
        Assert:IsTrue(mInput:HandleKey("Subtract")).
        Assert:IsTrue(mInput:HandleKey("OemMinus")).
        Assert:Equals(70, mGame:SpeedPercent).
        Assert:IsTrue(mInput:HandleKey("Oemplus")).
        Assert:Equals(80, mGame:SpeedPercent).
        Assert:Equals(80, mSettings:GetInteger("asteroids.speed", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedStaysBetweenTwentyAndOneHundredPercent():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 12:
            mInput:HandleKey("Subtract").
        END.
        Assert:Equals(20, mGame:SpeedPercent).
        DO i = 1 TO 12:
            mInput:HandleKey("Add").
        END.
        Assert:Equals(100, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASavedSpeedIsPutBack():
        DEFINE VARIABLE game2 AS AsteroidsGame NO-UNDO.
        DEFINE VARIABLE input2 AS AsteroidsInput NO-UNDO.
        mSettings:SetInteger("asteroids.speed", 60).
        game2 = AsteroidsFactory:Create(NEW SeededRandom(3)).
        input2 = NEW AsteroidsInput(game2, mSettings).
        Assert:Equals(60, game2:SpeedPercent).
        game2:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInputNeedsAGameAndSettingsAndKnowsNoCommands():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SoundIsOfferedOnlyWithAWorkingPlayerAndSwitchesItAndRemembersIt():
        DEFINE VARIABLE oPlayer AS RecordingSoundPlayer NO-UNDO.
        oPlayer = NEW RecordingSoundPlayer().
        mInput = NEW AsteroidsInput(mGame, mSettings, oPlayer).
        Assert:Equals("Sound:M", mInput:CommandNames).
        mInput:Perform("Sound").
        Assert:IsTrue(oPlayer:Muted).
        Assert:IsFalse(mSettings:GetLogical("sound.on", TRUE)).
        Assert:Equals("Sound off", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
        mInput:Perform("Sound").
        Assert:IsFalse(oPlayer:Muted).
        Assert:Equals("Sound on", mInput:TakeNotice()).
        /* a player that cannot sound has no command */
        oPlayer:Working = FALSE.
        Assert:Equals("", mInput:CommandNames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInputNeedsASoundPlayer():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW AsteroidsInput(mGame, mSettings, ?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
