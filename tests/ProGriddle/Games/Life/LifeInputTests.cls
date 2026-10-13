USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeInputTests:

    DEFINE PRIVATE VARIABLE mGame  AS LifeGame  NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput AS IGameInput NO-UNDO.
    DEFINE PRIVATE VARIABLE mOptions AS IGameOptions NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = LifeFactory:Create(12, 8, FALSE, LifeRules:Conway(), 0.5).
        mInput = NEW LifeInput(mGame, NEW SeededRandom(42)).
        mOptions = CAST(mInput, IGameOptions).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* ---- status ---- */

    @Test.
    METHOD PUBLIC VOID StatusTextShowsGenerationAliveRulesAndBoard():
        mGame:Place(LifePatterns:Block(), 1, 1).
        Assert:Equals("Generation 0   Alive 4   Rules B3/S23   12 x 8 bounded", mInput:StatusText).
        mGame:Step().
        Assert:Equals("Generation 1   Alive 4   Rules B3/S23   12 x 8 bounded", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StatusTextSaysWrappedForATorus():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(6, 6, TRUE, LifeRules:HighLife(), 0.5).
            Assert:Equals("Generation 0   Alive 0   Rules B36/S23   6 x 6 wrapped", NEW LifeInput(g, NEW SeededRandom(1)):StatusText).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- picker ---- */

    @Test.
    METHOD PUBLIC VOID ThePickerOffersEveryLifePatternAndStartsOnGlider():
        Assert:Equals("Pattern", mInput:ChoiceLabel).
        Assert:Equals(LifePatterns:Names(), mInput:ChoiceNames).
        Assert:Equals("Glider", mInput:Choice).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingAPatternIsRememberedAndIgnoresCase():
        mInput:Choice = "beacon".
        Assert:Equals("Beacon", mInput:Choice).
        mInput:Choice = "GosperGliderGun".
        Assert:Equals("GosperGliderGun", mInput:Choice).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ChoosingAnUnknownPatternThrows():
        mInput:Choice = "nope".
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFailedChoiceKeepsThePreviousOne():
        DEFINE VARIABLE caught AS LOGICAL NO-UNDO.
        mInput:Choice = "Toad".
        DO ON ERROR UNDO, THROW:
            mInput:Choice = "nope".
            CATCH ge AS ProGriddle.Core.GridException:
                caught = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(caught).
        Assert:Equals("Toad", mInput:Choice).
    END METHOD.

    /* ---- clicks ---- */

    @Test.
    METHOD PUBLIC VOID ALeftClickTogglesTheCell():
        mInput:PrimaryAction(3, 2).
        Assert:IsTrue(mGame:IsAlive(3, 2)).
        mInput:PrimaryAction(3, 2).
        Assert:IsFalse(mGame:IsAlive(3, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALeftClickOffTheBoardIsIgnored():
        mInput:PrimaryAction(-1, 0).
        mInput:PrimaryAction(12, 0).
        mInput:PrimaryAction(0, 8).
        Assert:Equals(0, mGame:AliveCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARightClickPlacesTheChosenPatternWithItsCornerAtTheCell():
        mInput:Choice = "Blinker".
        mInput:SecondaryAction(2, 3).
        Assert:Equals(3, mGame:AliveCount).
        Assert:IsTrue(mGame:IsAlive(2, 3)).
        Assert:IsTrue(mGame:IsAlive(3, 3)).
        Assert:IsTrue(mGame:IsAlive(4, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARightClickNearTheEdgeMovesThePatternBackSoItFits():
        mInput:Choice = "Block".
        mInput:SecondaryAction(11, 7).
        Assert:Equals(4, mGame:AliveCount).
        Assert:IsTrue(mGame:IsAlive(10, 6)).
        Assert:IsTrue(mGame:IsAlive(11, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARightClickWithAPatternBiggerThanTheBoardIsIgnored():
        mInput:Choice = "GosperGliderGun".
        mInput:SecondaryAction(0, 0).
        Assert:Equals(0, mGame:AliveCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARightClickOffTheBoardIsIgnored():
        mInput:SecondaryAction(-3, 4).
        mInput:SecondaryAction(4, 99).
        Assert:Equals(0, mGame:AliveCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LifeHasNoInfoScreen():
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LifeUsesNoKeysAndShowsNoBanner():
        Assert:IsFalse(mInput:HandleKey("Left")).
        Assert:IsFalse(mInput:HandleKey("Space")).
        mInput:ReleaseKey("Left").
        mInput:ReleaseKey("").
        Assert:Equals("", mInput:BannerText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BothButtonsTogetherDoNothing():
        mGame:Place(LifePatterns:Block(), 1, 1).
        mInput:TertiaryAction(1, 1).
        Assert:Equals(4, mGame:AliveCount).
    END METHOD.

    /* ---- commands ---- */

    @Test.
    METHOD PUBLIC VOID TheExtraCommandsAreRandomAndClearWithKeyLetters():
        Assert:Equals("Random:G,Clear:C", mInput:CommandNames).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RandomFillsTheBoardAndGoesBackToGenerationZero():
        mGame:Place(LifePatterns:Blinker(), 1, 1).
        mGame:Step().
        mGame:Step().
        mInput:Perform("Random").
        Assert:Equals(0, mGame:Generation).
        Assert:IsTrue(mGame:AliveCount > 10 AND mGame:AliveCount < 45).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RandomWithTheSameSeedGivesTheSameBoard():
        DEFINE VARIABLE a AS LifeGame NO-UNDO.
        DEFINE VARIABLE b AS LifeGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = LifeFactory:Create(12, 8, FALSE, LifeRules:Conway(), 0.5).
            b = LifeFactory:Create(12, 8, FALSE, LifeRules:Conway(), 0.5).
            NEW LifeInput(a, NEW SeededRandom(7)):Perform("Random").
            NEW LifeInput(b, NEW SeededRandom(7)):Perform("Random").
            Assert:Equals(LifeTestKit:Board(a), LifeTestKit:Board(b)).
            FINALLY:
                IF VALID-OBJECT(b) THEN b:Dispose().
                IF VALID-OBJECT(a) THEN a:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearEmptiesTheBoardAndGoesBackToGenerationZero():
        mGame:Place(LifePatterns:Glider(), 1, 1).
        mGame:Step().
        mInput:Perform("Clear").
        Assert:Equals(0, mGame:Generation).
        Assert:Equals(0, mGame:AliveCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterRandomResetReturnsToTheRandomBoard():
        DEFINE VARIABLE random AS CHARACTER NO-UNDO.
        mInput:Perform("Random").
        random = LifeTestKit:Board(mGame).
        mGame:Step().
        mGame:Step().
        mGame:Initialise().
        Assert:Equals(random, LifeTestKit:Board(mGame)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownCommandThrows():
        mInput:Perform("Explode").
    END METHOD.

    /* ---- construction ---- */

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ItNeedsAGame():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        NEW LifeInput(g, NEW SeededRandom(1)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ItNeedsARandomSource():
        DEFINE VARIABLE r AS IRandom NO-UNDO.
        NEW LifeInput(mGame, r).
    END METHOD.

    /* ---- options: the rules and the board size ---- */

    @Test.
    METHOD PUBLIC VOID ThereAreTwoOptionsRulesAndBoard():
        Assert:Equals(2, mOptions:OptionCount).
        Assert:Equals("Rules", mOptions:OptionLabel(1)).
        Assert:Equals("Board", mOptions:OptionLabel(2)).
        Assert:Equals("ruleset", mOptions:OptionKey(1)).
        Assert:Equals("size", mOptions:OptionKey(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRulesOptionOffersEveryPresetAndShowsTheGamesOwn():
        Assert:Equals(LifeRules:PresetNames(), mOptions:OptionNames(1)).
        Assert:Equals("Conway", mOptions:OptionValue(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARuleSetThatIsNoPresetIsOfferedToo():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        DEFINE VARIABLE o AS IGameOptions NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = LifeFactory:Create(10, 10, FALSE, NEW LifeRules("B1/S1"), 0.5).
            o = CAST(NEW LifeInput(g, NEW SeededRandom(1)), IGameOptions).
            Assert:Equals("B1/S1", o:OptionValue(1)).
            Assert:Equals(LifeRules:PresetNames() + ",B1/S1", o:OptionNames(1)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBoardOptionOffersTheSizesAndTheGamesOwnWhenItIsNotOne():
        Assert:Equals("12 x 8", mOptions:OptionValue(2)).
        Assert:Equals(LifeSizes:Names() + ",12 x 8", mOptions:OptionNames(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingARulesPresetChangesTheRulesAndKeepsTheBoard():
        mGame:Place(LifePatterns:Block(), 1, 1).
        mOptions:SetOption(1, "HighLife").
        Assert:Equals("B36/S23", mGame:Rules:Notation).
        Assert:Equals("HighLife", mOptions:OptionValue(1)).
        Assert:Equals(4, mGame:AliveCount).
        Assert:IsTrue(INDEX(mInput:StatusText, "Rules B36/S23") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingNotationAsTheRulesWorksToo():
        mOptions:SetOption(1, "B1/S1").
        Assert:Equals("B1/S1", mGame:Rules:Notation).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingABoardSizeChangesTheGridAndTheStatusLine():
        mOptions:SetOption(2, "50 x 35").
        Assert:Equals(50, mGame:Grid:Width).
        Assert:Equals(35, mGame:Grid:Height).
        Assert:Equals("50 x 35", mOptions:OptionValue(2)).
        Assert:IsTrue(INDEX(mInput:StatusText, "50 x 35 bounded") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNoticeSaysWhatWasChosenOnceOnly():
        mOptions:SetOption(1, "Seeds").
        Assert:Equals("Rules: Seeds (B2/S)", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
        mOptions:SetOption(2, "75 x 50").
        Assert:Equals("Board: 75 x 50", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingWhatIsChosenAlreadyChangesNothing():
        mGame:Place(LifePatterns:Block(), 1, 1).
        mGame:Step().
        mOptions:SetOption(1, "Conway").
        mOptions:SetOption(2, "12 x 8").
        Assert:Equals(1, mGame:Generation).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameStillStepsAfterBothOptionsChange():
        mGame:Place(LifePatterns:Blinker(), 3, 3).
        mOptions:SetOption(2, "30 x 20").
        mOptions:SetOption(1, "Conway").
        mGame:Step().
        Assert:IsTrue(mGame:IsAlive(4, 2)).
        Assert:IsTrue(mGame:IsAlive(4, 4)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ARulesNameThatIsNeitherAPresetNorNotationIsRefused():
        mOptions:SetOption(1, "Nonsense").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABoardSizeThatIsNotASizeIsRefused():
        mOptions:SetOption(2, "huge").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnOptionThatDoesNotExistIsRefused():
        mOptions:SetOption(3, "x").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheUnknownValueIsRefusedAsAnOption():
        mOptions:SetOption(1, ?).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheLabelOfAnOptionThatDoesNotExistThrows():
        mOptions:OptionLabel(0).
    END METHOD.

END CLASS.
