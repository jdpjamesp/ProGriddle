/* What a Rogue window can do: keys become commands, the buttons work, the keys can be switched between vi and the number pad, and a game
   that ends goes on the list of scores once. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS RogueGame   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings   NO-UNDO.
    DEFINE PRIVATE VARIABLE mScores   AS RogueScores NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS RogueInput  NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mGame = NEW RogueGame(LevelMap:CreateGrid(), NEW SeededRandom(9)).
        mGame:Initialise().
        mGame:World:ClearLevel().
        mGame:World:CarveRoom(5, 5, 10, 4).
        mGame:World:PlaceHero(6, 6).
        mSettings = NEW MemorySettings().
        mScores = NEW RogueScores(mSettings).
        mInput = NEW RogueInput(mGame, mSettings, mScores).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseInput():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheViKeysAreOnByDefaultAndMoveTheHero():
        Assert:IsTrue(mInput:ViKeys).
        Assert:IsTrue(mInput:HandleKey("L")).
        Assert:Equals(7, mGame:World:Hero:X).
        Assert:IsTrue(mInput:HandleKey("H")).
        Assert:Equals(6, mGame:World:Hero:X).
        Assert:IsTrue(mInput:HandleKey("J")).
        Assert:Equals(7, mGame:World:Hero:Y).
        Assert:IsTrue(mInput:HandleKey("K")).
        Assert:Equals(6, mGame:World:Hero:Y).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShiftRuns():
        mInput:ShiftDown = TRUE.
        Assert:IsTrue(mInput:HandleKey("L")).
        Assert:Equals(14, mGame:World:Hero:X).
        mInput:ShiftDown = FALSE.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheArrowsAndTheNumberPadMoveInBothSettings():
        Assert:IsTrue(mInput:HandleKey("Right")).
        Assert:Equals(7, mGame:World:Hero:X).
        Assert:IsTrue(mInput:HandleKey("NumPad4")).
        Assert:Equals(6, mGame:World:Hero:X).
        mInput:Perform("Keys").
        Assert:IsFalse(mInput:ViKeys).
        Assert:IsTrue(mInput:HandleKey("Down")).
        Assert:Equals(7, mGame:World:Hero:Y).
        Assert:IsTrue(mInput:HandleKey("NumPad8")).
        Assert:Equals(6, mGame:World:Hero:Y).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithTheNumberPadTheViLettersDoNotMove():
        mInput:Perform("Keys").
        Assert:IsTrue(mInput:HandleKey("L")).
        Assert:Equals(6, mGame:World:Hero:X).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheKeysButtonSwitchesAndRemembersAndSaysSo():
        Assert:Equals("", mInput:TakeNotice()).
        mInput:Perform("Keys").
        Assert:IsFalse(mInput:ViKeys).
        Assert:Equals("numpad", mSettings:GetString("rogue.keys", "vi")).
        Assert:IsTrue(INDEX(mInput:TakeNotice(), "number pad") > 0).
        Assert:Equals("", mInput:TakeNotice()).
        mInput:Perform("Keys").
        Assert:IsTrue(mInput:ViKeys).
        Assert:Equals("vi", mSettings:GetString("rogue.keys", "numpad")).
        Assert:IsTrue(INDEX(mInput:TakeNotice(), "vi") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSavedSettingChoosesTheKeys():
        DEFINE VARIABLE oOther AS RogueInput NO-UNDO.
        mSettings:SetString("rogue.keys", "numpad").
        oOther = NEW RogueInput(mGame, mSettings, mScores).
        Assert:IsFalse(oOther:ViKeys).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID KeysTheGameHasNoUseForAreLeftToTheWindow():
        Assert:IsFalse(mInput:HandleKey("F2")).
        Assert:IsFalse(mInput:HandleKey("F5")).
        Assert:IsFalse(mInput:HandleKey(?)).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACommandThatNeedsAnItemTakesTheLettersAsLetters():
        mInput:HandleKey("Q").
        Assert:Equals(RogueMode:PickItem, mGame:Mode).
        mInput:HandleKey("Escape").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        mInput:ShiftDown = TRUE.
        mInput:HandleKey("T").
        mInput:ShiftDown = FALSE.
        Assert:Equals(-1, mGame:World:Pack:WornSlot).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShiftedSymbolsReachTheGame():
        mGame:World:Cave:SetTerrain(6, 6, Terrain:Stairs).
        mInput:ShiftDown = TRUE.
        mInput:HandleKey("OemPeriod").
        mInput:ShiftDown = FALSE.
        Assert:Equals(2, mGame:World:Depth).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheButtonsOpenTheScreens():
        mInput:Perform("Inventory").
        Assert:Equals(RogueOverlay:Inventory, mGame:Showing).
        mInput:HandleKey("Escape").
        mInput:Perform("Help").
        Assert:Equals(RogueOverlay:Help, mGame:Showing).
        mInput:HandleKey("Escape").
        mInput:Perform("Messages").
        Assert:Equals(RogueOverlay:Messages, mGame:Showing).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownButtonIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mInput:Perform("Dance").
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWindowHasFourButtonsAndNoPickerOrBanner():
        Assert:Equals("Inventory,Messages,Help,Keys", mInput:CommandNames).
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        mInput:Choice = "x".
        Assert:Equals("", mInput:BannerText).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineGivesTheNumbersOfTheHero():
        Assert:Equals("Level 1  Gold 0  Hp 12(12)  Str 16(16)  Arm 6  Exp 1/0", mInput:StatusText).
        mGame:World:Hero:Gold = 45.
        mGame:World:Hero:Hp = 9.
        Assert:IsTrue(INDEX(mInput:StatusText, "Gold 45  Hp 9(12)") > 0).
        Assert:Equals(RogueInput:Summary(mGame), mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PressingKeysAndTheOtherActionsOfAMouseDoNothing():
        mInput:PrimaryAction(7, 6).
        mInput:SecondaryAction(7, 6).
        mInput:TertiaryAction(7, 6).
        mInput:ReleaseKey("L").
        mInput:ReleaseKey("").
        Assert:Equals(6, mGame:World:Hero:X).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatEndsIsPutOnTheListOnce():
        mGame:World:Hero:Gold = 250.
        mInput:ShiftDown = TRUE.
        mInput:HandleKey("Q").
        mInput:ShiftDown = FALSE.
        Assert:Equals(RogueMode:Confirm, mGame:Mode).
        mInput:HandleKey("Y").
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(1, mScores:Count).
        Assert:Equals(250, mScores:ScoreAt(1)).
        Assert:Equals("quit", mScores:CauseAt(1)).
        mInput:HandleKey("L").
        Assert:IsTrue(mInput:StatusText <> "").
        Assert:Equals(1, mScores:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameCanBeRecordedAgain():
        mInput:ShiftDown = TRUE.
        mInput:HandleKey("Q").
        mInput:ShiftDown = FALSE.
        mInput:HandleKey("Y").
        mInput:HandleKey("Return").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        mGame:World:ClearLevel().
        mGame:World:CarveRoom(5, 5, 10, 4).
        mGame:World:PlaceHero(6, 6).
        mInput:ShiftDown = TRUE.
        mInput:HandleKey("Q").
        mInput:ShiftDown = FALSE.
        mInput:HandleKey("Y").
        Assert:Equals(2, mScores:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoGameNoSettingsOrNoScoresIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW RogueInput(?, mSettings, mScores).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW RogueInput(mGame, ?, mScores).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW RogueInput(mGame, mSettings, ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
