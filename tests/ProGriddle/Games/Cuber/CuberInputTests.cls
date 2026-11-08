/* The Cuber window input: the arrow keys and their companions ask for hops, the fire keys are states the game is told about, the
   speed and the best score are kept in the settings, and the sound command is offered only with a working player. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberInputTests:

    VAR PRIVATE CuberGame mGame.
    VAR PRIVATE MemorySettings mSettings.
    VAR PRIVATE CuberInput mInput.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mSettings = NEW MemorySettings().
        mGame = CuberFactory:Create(NEW ScriptedRandom("1")).
        mInput = NEW CuberInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* A game in play with Pip on the apex and no enemies, and the number of frames a hop takes. */
    METHOD PRIVATE VOID Play():
        VAR INTEGER i.
        mGame:StartGame().
        DO i = 1 TO CuberRules:ReadyFrames():
            mGame:Advance().
        END.
        mGame:StopSpawns().
    END METHOD.

    METHOD PRIVATE VOID HopFor(INPUT pcKey AS CHARACTER):
        VAR INTEGER i.
        Play().
        Assert:IsTrue(mInput:HandleKey(pcKey)).
        DO i = 1 TO 13:
            mGame:Advance().
        END.
    END METHOD.

    /* ---- the keys ---- */

    @Test.
    METHOD PUBLIC VOID TheArrowKeysHopAlongTheDiagonalsOfThePyramidAsItIsSeen():
        HopFor("Right").
        Assert:Equals(2, mGame:PipRow).
        Assert:Equals(1, mGame:PipCol).
        HopFor("Down").
        Assert:Equals(2, mGame:PipRow).
        Assert:Equals(0, mGame:PipCol).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID UpAndLeftHopOffTheTopOfThePyramid():
        HopFor("Up").
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLettersHopLikeTheArrows():
        HopFor("D").
        Assert:Equals(2, mGame:PipRow).
        Assert:Equals(1, mGame:PipCol).
        HopFor("S").
        Assert:Equals(2, mGame:PipRow).
        Assert:Equals(0, mGame:PipCol).
        HopFor("W").
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
        HopFor("A").
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNumberPadAndTheCornerKeysHopToTheirCorners():
        HopFor("NumPad3").
        Assert:Equals(1, mGame:PipCol).
        HopFor("NumPad1").
        Assert:Equals(0, mGame:PipCol).
        HopFor("C").
        Assert:Equals(1, mGame:PipCol).
        HopFor("Z").
        Assert:Equals(0, mGame:PipCol).
        HopFor("NumPad9").
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
        HopFor("E").
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
        HopFor("NumPad7").
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
        HopFor("Q").
        Assert:Equals(STRING(CuberPipMode:Falling), STRING(mGame:PipMode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKeyThatIsNotTheGamesIsLeftToTheWindow():
        Assert:IsFalse(mInput:HandleKey("F7")).
        Assert:IsFalse(mInput:HandleKey(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceAndReturnAreTheFireKeysAndStayDownUntilReleased():
        Assert:IsTrue(mInput:HandleKey("Space")).
        Assert:IsTrue(mGame:FireHeld).
        Assert:IsTrue(mInput:HandleKey("Return")).
        mInput:ReleaseKey("Space").
        Assert:IsTrue(mGame:FireHeld).
        mInput:ReleaseKey("Return").
        Assert:IsFalse(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyKeyNameReleasesEverything():
        mInput:HandleKey("Space").
        mInput:ReleaseKey("").
        Assert:IsFalse(mGame:FireHeld).
        mInput:HandleKey("Space").
        mInput:ReleaseKey(?).
        Assert:IsFalse(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReleasingAKeyThatIsNotAFireKeyChangesNothing():
        mInput:HandleKey("Space").
        mInput:ReleaseKey("Left").
        Assert:IsTrue(mGame:FireHeld).
    END METHOD.

    /* ---- the speed and the best score ---- */

    @Test.
    METHOD PUBLIC VOID PlusAndMinusChangeTheSpeedByTenAndItIsKept():
        Assert:Equals(80, mGame:SpeedPercent).
        Assert:IsTrue(mInput:HandleKey("Add")).
        Assert:Equals(90, mGame:SpeedPercent).
        Assert:Equals(90, mSettings:GetInteger("cuber.speed", 0)).
        Assert:IsTrue(mInput:HandleKey("OemMinus")).
        Assert:IsTrue(mInput:HandleKey("Subtract")).
        Assert:Equals(70, mGame:SpeedPercent).
        Assert:IsTrue(mInput:HandleKey("Oemplus")).
        Assert:Equals(80, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSavedSpeedAndHiScoreAreReadWhenTheInputIsBuilt():
        VAR CuberInput other.
        mSettings:SetInteger("cuber.speed", 40).
        mSettings:SetInteger("cuber.hiscore", 1234).
        other = NEW CuberInput(mGame, mSettings).
        Assert:Equals(40, mGame:SpeedPercent).
        Assert:Equals(1234, mGame:HiScore).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABetterScoreGoesIntoTheSettingsAtOnce():
        mGame:AddScore(777).
        Assert:IsTrue(INDEX(mInput:StatusText, "Hi 777") > 0).
        Assert:Equals(777, mSettings:GetInteger("cuber.hiscore", 0)).
    END METHOD.

    /* ---- the words ---- */

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysWhatToDoOnTheTitleAndWhatIsGoingOnInPlay():
        Assert:IsTrue(INDEX(mInput:StatusText, "Press Space") > 0).
        Play().
        Assert:IsTrue(INDEX(mInput:StatusText, "Level 1") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Pips 3") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Speed 80%") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineOfAFinishedGameSaysGameOver():
        VAR INTEGER i.
        Play().
        mGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
        DO i = 1 TO 59:
            mGame:Advance().
        END.
        DO i = 1 TO 90:
            mGame:Advance().
        END.
        mGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
        DO i = 1 TO 59:
            mGame:Advance().
        END.
        DO i = 1 TO 90:
            mGame:Advance().
        END.
        mGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
        DO i = 1 TO 59:
            mGame:Advance().
        END.
        Assert:IsTrue(INDEX(mInput:StatusText, "Game over") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBannerIsAlwaysEmptyBecauseThePainterDrawsTheWords():
        Assert:Equals("", mInput:BannerText).
        Play().
        Assert:Equals("", mInput:BannerText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoPickerAndNoInfoScreen():
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        mInput:Choice = "anything".
        Assert:Equals("", mInput:Choice).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TakeNoticePassesOnTheGamesWords():
        mGame:AddScore(CuberRules:ExtraLifeEvery()).
        Assert:Equals("Extra Pip", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    /* ---- the sound command ---- */

    @Test.
    METHOD PUBLIC VOID TheSoundCommandIsOfferedOnlyWithAWorkingPlayer():
        Assert:Equals("", mInput:CommandNames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownCommandThrows():
        VAR LOGICAL thrown.
        DO ON ERROR UNDO, LEAVE:
            mInput:Perform("Dance").
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSoundCommandSwitchesTheSettingAndSaysSo():
        mInput:Perform("Sound").
        Assert:IsTrue(mInput:TakeNotice() <> "").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClicksDoNothing():
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(1, 1).
        mInput:TertiaryAction(1, 1).
        Assert:Equals(STRING(CuberPhase:Title), STRING(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInputRefusesNoGameNoSettingsAndNoPlayer():
        VAR LOGICAL thrown.
        VAR CuberInput other.
        DO ON ERROR UNDO, LEAVE:
            other = NEW CuberInput(?, mSettings).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
        thrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            other = NEW CuberInput(mGame, ?).
            CATCH e2 AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
        thrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            other = NEW CuberInput(mGame, mSettings, ?).
            CATCH e3 AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

END CLASS.
