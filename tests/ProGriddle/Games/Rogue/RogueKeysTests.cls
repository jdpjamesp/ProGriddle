/* From a key to a token: the vi letters or the number pad, the arrows, shifted letters and symbols. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueKeysTests:

    @Test.
    METHOD PUBLIC VOID TheViLettersAreTheEightDirections():
        Assert:Equals("4", RogueKeys:Token("H", FALSE, TRUE, FALSE)).
        Assert:Equals("2", RogueKeys:Token("J", FALSE, TRUE, FALSE)).
        Assert:Equals("8", RogueKeys:Token("K", FALSE, TRUE, FALSE)).
        Assert:Equals("6", RogueKeys:Token("L", FALSE, TRUE, FALSE)).
        Assert:Equals("7", RogueKeys:Token("Y", FALSE, TRUE, FALSE)).
        Assert:Equals("9", RogueKeys:Token("U", FALSE, TRUE, FALSE)).
        Assert:Equals("1", RogueKeys:Token("B", FALSE, TRUE, FALSE)).
        Assert:Equals("3", RogueKeys:Token("N", FALSE, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShiftedViLettersRun():
        Assert:Equals("run4", RogueKeys:Token("H", TRUE, TRUE, FALSE)).
        Assert:Equals("run9", RogueKeys:Token("U", TRUE, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithoutTheViKeysThoseLettersAreJustLetters():
        Assert:Equals("h", RogueKeys:Token("H", FALSE, FALSE, FALSE)).
        Assert:Equals("n", RogueKeys:Token("N", FALSE, FALSE, FALSE)).
        Assert:Equals("S-h", RogueKeys:Token("H", TRUE, FALSE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheArrowsAndTheNumberPadWorkWithEitherSetting():
        VAR INTEGER vi.
        DO vi = 0 TO 1:
            Assert:Equals("4", RogueKeys:Token("Left", FALSE, vi = 1, FALSE)).
            Assert:Equals("6", RogueKeys:Token("Right", FALSE, vi = 1, FALSE)).
            Assert:Equals("8", RogueKeys:Token("Up", FALSE, vi = 1, FALSE)).
            Assert:Equals("2", RogueKeys:Token("Down", FALSE, vi = 1, FALSE)).
            Assert:Equals("7", RogueKeys:Token("Home", FALSE, vi = 1, FALSE)).
            Assert:Equals("9", RogueKeys:Token("PageUp", FALSE, vi = 1, FALSE)).
            Assert:Equals("9", RogueKeys:Token("Prior", FALSE, vi = 1, FALSE)).
            Assert:Equals("1", RogueKeys:Token("End", FALSE, vi = 1, FALSE)).
            Assert:Equals("3", RogueKeys:Token("PageDown", FALSE, vi = 1, FALSE)).
            Assert:Equals("3", RogueKeys:Token("Next", FALSE, vi = 1, FALSE)).
            Assert:Equals("1", RogueKeys:Token("NumPad1", FALSE, vi = 1, FALSE)).
            Assert:Equals("2", RogueKeys:Token("NumPad2", FALSE, vi = 1, FALSE)).
            Assert:Equals("3", RogueKeys:Token("NumPad3", FALSE, vi = 1, FALSE)).
            Assert:Equals("4", RogueKeys:Token("NumPad4", FALSE, vi = 1, FALSE)).
            Assert:Equals("6", RogueKeys:Token("NumPad6", FALSE, vi = 1, FALSE)).
            Assert:Equals("7", RogueKeys:Token("NumPad7", FALSE, vi = 1, FALSE)).
            Assert:Equals("8", RogueKeys:Token("NumPad8", FALSE, vi = 1, FALSE)).
            Assert:Equals("9", RogueKeys:Token("NumPad9", FALSE, vi = 1, FALSE)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShiftWithAnArrowRuns():
        Assert:Equals("run6", RogueKeys:Token("Right", TRUE, FALSE, FALSE)).
        Assert:Equals("run8", RogueKeys:Token("NumPad8", TRUE, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMiddleOfTheNumberPadAndTheDotRest():
        Assert:Equals("5", RogueKeys:Token("NumPad5", FALSE, TRUE, FALSE)).
        Assert:Equals("5", RogueKeys:Token("Clear", FALSE, TRUE, FALSE)).
        Assert:Equals(".", RogueKeys:Token("Decimal", FALSE, TRUE, FALSE)).
        Assert:Equals(".", RogueKeys:Token("OemPeriod", FALSE, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LettersAreLowerCaseAndShiftedLettersAreMarked():
        Assert:Equals("q", RogueKeys:Token("Q", FALSE, TRUE, FALSE)).
        Assert:Equals("S-q", RogueKeys:Token("Q", TRUE, TRUE, FALSE)).
        Assert:Equals("w", RogueKeys:Token("W", FALSE, TRUE, FALSE)).
        Assert:Equals("S-w", RogueKeys:Token("W", TRUE, TRUE, FALSE)).
        Assert:Equals("S-d", RogueKeys:Token("D", TRUE, TRUE, FALSE)).
        Assert:Equals("s", RogueKeys:Token("S", FALSE, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhilePickingAPackLetterEveryLetterIsALetterInEitherSetting():
        Assert:Equals("h", RogueKeys:Token("H", FALSE, TRUE, TRUE)).
        Assert:Equals("n", RogueKeys:Token("N", FALSE, TRUE, TRUE)).
        Assert:Equals("b", RogueKeys:Token("B", FALSE, FALSE, TRUE)).
        Assert:Equals("4", RogueKeys:Token("Left", FALSE, TRUE, TRUE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSymbolsAreMadeWithShiftTheWayAKeyboardMakesThem():
        Assert:Equals(">", RogueKeys:Token("OemPeriod", TRUE, TRUE, FALSE)).
        Assert:Equals("<", RogueKeys:Token("Oemcomma", TRUE, TRUE, FALSE)).
        Assert:Equals(",", RogueKeys:Token("Oemcomma", FALSE, TRUE, FALSE)).
        Assert:Equals("?", RogueKeys:Token("OemQuestion", TRUE, TRUE, FALSE)).
        Assert:Equals("/", RogueKeys:Token("OemQuestion", FALSE, TRUE, FALSE)).
        Assert:Equals("^", RogueKeys:Token("D6", TRUE, TRUE, FALSE)).
        Assert:Equals("", RogueKeys:Token("D6", FALSE, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpecialKeysAreNamed():
        Assert:Equals("ESC", RogueKeys:Token("Escape", FALSE, TRUE, FALSE)).
        Assert:Equals("ENTER", RogueKeys:Token("Return", FALSE, TRUE, FALSE)).
        Assert:Equals("ENTER", RogueKeys:Token("Enter", FALSE, TRUE, FALSE)).
        Assert:Equals("SPACE", RogueKeys:Token("Space", FALSE, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OtherKeysHaveNoTokenSoTheWindowKeepsThem():
        Assert:Equals("", RogueKeys:Token("F2", FALSE, TRUE, FALSE)).
        Assert:Equals("", RogueKeys:Token("F1", TRUE, TRUE, FALSE)).
        Assert:Equals("", RogueKeys:Token("D1", FALSE, TRUE, FALSE)).
        Assert:Equals("", RogueKeys:Token("", FALSE, TRUE, FALSE)).
        Assert:Equals("", RogueKeys:Token(?, FALSE, TRUE, FALSE)).
        Assert:Equals("", RogueKeys:Token("Tab", FALSE, TRUE, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADirectionIsFoundByKeyAndSetting():
        Assert:Equals("4", RogueKeys:Direction("H", TRUE)).
        Assert:Equals("", RogueKeys:Direction("H", FALSE)).
        Assert:Equals("2", RogueKeys:Direction("Down", FALSE)).
        Assert:Equals("", RogueKeys:Direction("Q", TRUE)).
    END METHOD.

END CLASS.
