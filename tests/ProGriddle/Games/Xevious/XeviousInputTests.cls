/* The Xevious window input: the keys are states the game is told about, the speed and the best score are kept in the settings, and
   the sound command is offered only with a working player. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS XeviousGame    NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS XeviousInput   NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mSettings = NEW MemorySettings().
        mGame = XeviousFactory:Create(NEW ScriptedRandom("1")).
        mInput = NEW XeviousInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheArrowKeysAndTheLettersSteerTheShip():
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:Equals(-1, mGame:MoveX).
        mInput:ReleaseKey("Left").
        Assert:Equals(0, mGame:MoveX).
        Assert:IsTrue(mInput:HandleKey("D")).
        Assert:Equals(1, mGame:MoveX).
        mInput:ReleaseKey("D").
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
    METHOD PUBLIC VOID TheZapperAndTheBlasterHaveKeysOfTheirOwnAndCanBothBeHeld():
        mInput:HandleKey("Space").
        Assert:IsTrue(mGame:ZapHeld).
        Assert:IsFalse(mGame:BombHeld).
        mInput:HandleKey("X").
        Assert:IsTrue(mGame:BombHeld).
        mInput:ReleaseKey("Space").
        Assert:IsFalse(mGame:ZapHeld).
        Assert:IsTrue(mGame:BombHeld).
        mInput:ReleaseKey("X").
        Assert:IsFalse(mGame:BombHeld).
        mInput:HandleKey("Z").
        mInput:HandleKey("B").
        Assert:IsTrue(mGame:ZapHeld).
        Assert:IsTrue(mGame:BombHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFireStateLastsAsLongAsAnyKeyOfItIsDown():
        mInput:HandleKey("Space").
        mInput:HandleKey("Z").
        mInput:ReleaseKey("Space").
        Assert:IsTrue(mGame:ZapHeld).
        mInput:ReleaseKey("Z").
        Assert:IsFalse(mGame:ZapHeld).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyKeyNameLetsGoOfEveryKey():
        mInput:HandleKey("Left").
        mInput:HandleKey("Down").
        mInput:HandleKey("Space").
        mInput:HandleKey("X").
        mInput:ReleaseKey("").
        Assert:Equals(0, mGame:MoveX).
        Assert:Equals(0, mGame:MoveY).
        Assert:IsFalse(mGame:ZapHeld).
        Assert:IsFalse(mGame:BombHeld).
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
        Assert:Equals(80, mGame:SpeedPercent).
        Assert:IsTrue(mInput:HandleKey("Add")).
        Assert:Equals(90, mGame:SpeedPercent).
        Assert:Equals(90, mSettings:GetInteger("xevious.speed", 0)).
        Assert:IsTrue(mInput:HandleKey("Subtract")).
        Assert:IsTrue(mInput:HandleKey("OemMinus")).
        Assert:Equals(70, mGame:SpeedPercent).
        Assert:IsTrue(mInput:HandleKey("Oemplus")).
        Assert:Equals(80, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedAndTheBestScoreComeFromTheSettings():
        DEFINE VARIABLE oSettings AS MemorySettings NO-UNDO.
        DEFINE VARIABLE oGame     AS XeviousGame    NO-UNDO.
        DEFINE VARIABLE oInput    AS XeviousInput   NO-UNDO.
        oSettings = NEW MemorySettings().
        oSettings:SetInteger("xevious.speed", 50).
        oSettings:SetInteger("xevious.hiscore", 1234).
        oGame = XeviousFactory:Create(NEW ScriptedRandom("1")).
        oInput = NEW XeviousInput(oGame, oSettings).
        Assert:Equals(50, oGame:SpeedPercent).
        Assert:Equals(1234, oGame:HiScore).
        oGame:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABetterBestScoreIsKeptInTheSettingsAtOnce():
        mGame:StartGame().
        mGame:AddScore(777).
        Assert:IsTrue(mInput:StatusText <> "").
        Assert:Equals(777, mSettings:GetInteger("xevious.hiscore", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysWhatIsGoingOn():
        Assert:IsTrue(INDEX(mInput:StatusText, "Press Space") > 0).
        mGame:StartGame().
        Assert:IsTrue(INDEX(mInput:StatusText, "Stage 1") > 0).
        Assert:IsTrue(INDEX(mInput:StatusText, "Ships 3") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSoundCommandIsOfferedOnlyWithAWorkingPlayer():
        Assert:Equals("", mInput:CommandNames).
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        mInput:Choice = "x".
        Assert:Equals("", mInput:BannerText).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownCommandIsRefusedAndTheOtherActionsDoNothing():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mInput:Perform("Dance").
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(1, 1).
        mInput:TertiaryAction(1, 1).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGamesNoticesAreHandedOn():
        mGame:StartGame().
        mGame:AddScore(20000).
        Assert:Equals("EXTRA SHIP", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItNeedsAGameSettingsAndAPlayer():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE oOther AS XeviousInput NO-UNDO.
        DO ON ERROR UNDO, THROW:
            oOther = NEW XeviousInput(?, mSettings).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW XeviousInput(mGame, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW XeviousInput(mGame, mSettings, ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
