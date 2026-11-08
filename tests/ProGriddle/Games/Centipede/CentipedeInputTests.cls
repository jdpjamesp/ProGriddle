/* The Centipede window input: the keys are states the game is told about, the speed and the best score are kept in the settings, and
   the sound command is offered only with a working player. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeInputTests:

    VAR PRIVATE CentipedeGame mGame.
    VAR PRIVATE MemorySettings mSettings.
    VAR PRIVATE CentipedeInput mInput.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mSettings = NEW MemorySettings().
        mGame = CentipedeFactory:Create(NEW ScriptedRandom("1")).
        mInput = NEW CentipedeInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* ---- the keys ---- */

    @Test.
    METHOD PUBLIC VOID TheArrowKeysAndTheLettersSteerTheShooter():
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:Equals(-1, mGame:MoveX).
        mInput:ReleaseKey("Left").
        Assert:Equals(0, mGame:MoveX).
        Assert:IsTrue(mInput:HandleKey("D")).
        Assert:Equals(1, mGame:MoveX).
        mInput:ReleaseKey("D").
        Assert:IsTrue(mInput:HandleKey("Up")).
        Assert:Equals(-1, mGame:MoveY).
        mInput:ReleaseKey("Up").
        Assert:IsTrue(mInput:HandleKey("S")).
        Assert:Equals(1, mGame:MoveY).
        mInput:ReleaseKey("S").
        Assert:IsTrue(mInput:HandleKey("A")).
        Assert:Equals(-1, mGame:MoveX).
        mInput:ReleaseKey("A").
        Assert:IsTrue(mInput:HandleKey("Right")).
        Assert:Equals(1, mGame:MoveX).
        mInput:ReleaseKey("Right").
        Assert:IsTrue(mInput:HandleKey("W")).
        Assert:Equals(-1, mGame:MoveY).
        mInput:ReleaseKey("W").
        Assert:IsTrue(mInput:HandleKey("Down")).
        Assert:Equals(1, mGame:MoveY).
        mInput:ReleaseKey("Down").
        Assert:Equals(0, mGame:MoveY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenBothKeysOfAnAxisAreDownTheLastOneWins():
        mInput:HandleKey("Left").
        mInput:HandleKey("Right").
        Assert:Equals(1, mGame:MoveX).
        mInput:ReleaseKey("Right").
        Assert:Equals(-1, mGame:MoveX).
        mInput:ReleaseKey("Left").
        mInput:HandleKey("Down").
        mInput:HandleKey("Up").
        Assert:Equals(-1, mGame:MoveY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShooterCanMoveAcrossAndUpAtTheSameTimeAndFire():
        mInput:HandleKey("Left").
        mInput:HandleKey("Up").
        mInput:HandleKey("Space").
        Assert:Equals(-1, mGame:MoveX).
        Assert:Equals(-1, mGame:MoveY).
        Assert:IsTrue(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FireIsHeldWhileAnyFireKeyIsDown():
        mInput:HandleKey("Space").
        mInput:HandleKey("Z").
        mInput:HandleKey("Space").
        Assert:IsTrue(mGame:FireHeld).
        mInput:ReleaseKey("Space").
        Assert:IsTrue(mGame:FireHeld).
        mInput:ReleaseKey("Z").
        Assert:IsFalse(mGame:FireHeld).
        mInput:HandleKey("X").
        Assert:IsTrue(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyKeyNameLetsGoOfEveryKey():
        mInput:HandleKey("Left").
        mInput:HandleKey("Down").
        mInput:HandleKey("Space").
        mInput:ReleaseKey("").
        Assert:Equals(0, mGame:MoveX).
        Assert:Equals(0, mGame:MoveY).
        Assert:IsFalse(mGame:FireHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OtherKeysAreLeftToTheWindow():
        Assert:IsFalse(mInput:HandleKey("P")).
        Assert:IsFalse(mInput:HandleKey("F2")).
        Assert:IsFalse(mInput:HandleKey(?)).
        mInput:ReleaseKey("P").
        Assert:Equals(0, mGame:MoveX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlusAndMinusChangeTheSpeedInTensAndItIsKept():
        Assert:Equals(70, mGame:SpeedPercent).
        Assert:IsTrue(mInput:HandleKey("Add")).
        Assert:Equals(80, mGame:SpeedPercent).
        Assert:IsTrue(mInput:HandleKey("OemMinus")).
        Assert:IsTrue(mInput:HandleKey("Subtract")).
        Assert:Equals(60, mGame:SpeedPercent).
        Assert:Equals(60, mSettings:GetInteger("centipede.speed", 0)).
        mInput:HandleKey("Oemplus").
        Assert:Equals(70, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedAndTheBestScoreAreReadFromTheSettings():
        VAR CentipedeGame oGame.
        VAR CentipedeInput oInput.
        mSettings:SetInteger("centipede.speed", 90).
        mSettings:SetInteger("centipede.hiscore", 4321).
        oGame = CentipedeFactory:Create(NEW ScriptedRandom("1")).
        oInput = NEW CentipedeInput(oGame, mSettings).
        Assert:Equals(90, oGame:SpeedPercent).
        Assert:Equals(4321, oGame:HiScore).
        oGame:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABetterScoreGoesIntoTheSettingsAtOnce():
        mGame:StartGame().
        mGame:AddScore(777).
        Assert:IsTrue(mInput:StatusText BEGINS "Score 777").
        Assert:Equals(777, mSettings:GetInteger("centipede.hiscore", 0)).
    END METHOD.

    /* ---- what the window shows ---- */

    @Test.
    METHOD PUBLIC VOID TheStatusLineFollowsThePhase():
        Assert:IsTrue(mInput:StatusText BEGINS "Centipede").
        Assert:IsTrue(INDEX(mInput:StatusText, "Press Space") > 0).
        mGame:StartGame().
        Assert:Equals("Score 0   Hi 0   Lives 3   Wave 1   Speed 70%", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameOverStatusSaysSo():
        VAR INTEGER i.
        mGame:StartGame().
        DO i = 1 TO 3:
            mGame:ClearCentipede().
            mGame:PlacePlayer(112, 224).
            mGame:AddSegment(14, 28, -1, TRUE).
            mGame:Advance().
            DO WHILE mGame:Phase = GamePhase:Dying:
                mGame:Advance().
            END.
        END.
        Assert:IsTrue(mInput:StatusText BEGINS "Game over").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBannerIsAlwaysEmptyBecauseThePainterDrawsTheWords():
        Assert:Equals("", mInput:BannerText).
        mGame:Paused = TRUE.
        Assert:Equals("", mInput:BannerText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoPickerNoInfoScreenAndNothingToClick():
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        mInput:Choice = "anything".
        Assert:Equals("", mInput:Choice).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(1, 1).
        mInput:TertiaryAction(1, 1).
        Assert:Equals(0, mGame:MoveX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGamesOwnNoticeIsPassedOn():
        mGame:StartGame().
        mGame:AddScore(12000).
        Assert:Equals("Extra shooter", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SoundIsOfferedOnlyWithAWorkingPlayerAndSwitchesItAndRemembersIt():
        VAR RecordingSoundPlayer oPlayer.
        Assert:Equals("", mInput:CommandNames).
        oPlayer = NEW RecordingSoundPlayer().
        mInput = NEW CentipedeInput(mGame, mSettings, oPlayer).
        Assert:Equals("Sound:M", mInput:CommandNames).
        mInput:Perform("Sound").
        Assert:IsTrue(oPlayer:Muted).
        Assert:Equals("Sound off", mInput:TakeNotice()).
        Assert:IsFalse(mSettings:GetLogical("sound.on", TRUE)).
        mInput:Perform("Sound").
        Assert:Equals("Sound on", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownCommandIsRefused():
        VAR INTEGER thrown.
        DO ON ERROR UNDO, THROW:
            mInput:Perform("Nonsense").
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInputNeedsAGameSettingsAndASoundPlayer():
        VAR INTEGER thrown.
        VAR CentipedeInput oOther.
        DO ON ERROR UNDO, THROW:
            oOther = NEW CentipedeInput(?, mSettings).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW CentipedeInput(mGame, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW CentipedeInput(mGame, mSettings, ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
