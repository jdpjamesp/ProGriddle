USING OpenEdge.Core.Assert.
USING Progress.Lang.*.
USING Prolif.Core.IRandom.
USING Prolif.Core.SeededRandom.
USING Prolif.Engine.IGameInput.
USING Prolif.Games.Life.LifeFactory.
USING Prolif.Games.Life.LifeGame.
USING Prolif.Games.Life.LifeInput.
USING Prolif.Games.Life.LifePatterns.
USING Prolif.Games.Life.LifeRules.
USING Prolif.Games.Life.LifeTestKit.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Games.Life.LifeInputTests:

    DEFINE PRIVATE VARIABLE mGame  AS LifeGame  NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput AS IGameInput NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = LifeFactory:Create(12, 8, FALSE, LifeRules:Conway(), 0.5).
        mInput = NEW LifeInput(mGame, NEW SeededRandom(42)).
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

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ChoosingAnUnknownPatternThrows():
        mInput:Choice = "nope".
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFailedChoiceKeepsThePreviousOne():
        DEFINE VARIABLE caught AS LOGICAL NO-UNDO.
        mInput:Choice = "Toad".
        DO ON ERROR UNDO, THROW:
            mInput:Choice = "nope".
            CATCH ge AS Prolif.Core.GridException:
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

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID AnUnknownCommandThrows():
        mInput:Perform("Explode").
    END METHOD.

    /* ---- construction ---- */

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ItNeedsAGame():
        DEFINE VARIABLE g AS LifeGame NO-UNDO.
        NEW LifeInput(g, NEW SeededRandom(1)).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ItNeedsARandomSource():
        DEFINE VARIABLE r AS IRandom NO-UNDO.
        NEW LifeInput(mGame, r).
    END METHOD.

END CLASS.
