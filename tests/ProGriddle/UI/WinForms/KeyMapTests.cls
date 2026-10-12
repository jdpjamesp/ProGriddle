USING OpenEdge.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.KeyMapTests:

    DEFINE PRIVATE VARIABLE mMap AS KeyMap NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildMap():
        mMap = NEW KeyMap().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceStartsWhenStoppedAndPausesWhenRunning():
        Assert:IsTrue(mMap:CommandFor("Space", FALSE) = GameCommand:Start).
        Assert:IsTrue(mMap:CommandFor("Space", TRUE) = GameCommand:PauseGame).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PAlsoStartsAndPauses():
        Assert:IsTrue(mMap:CommandFor("P", FALSE) = GameCommand:Start).
        Assert:IsTrue(mMap:CommandFor("P", TRUE) = GameCommand:PauseGame).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SAndRightArrowStepOnce():
        Assert:IsTrue(mMap:CommandFor("S", FALSE) = GameCommand:StepOnce).
        Assert:IsTrue(mMap:CommandFor("Right", TRUE) = GameCommand:StepOnce).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RResets():
        Assert:IsTrue(mMap:CommandFor("R", FALSE) = GameCommand:Reset).
        Assert:IsTrue(mMap:CommandFor("R", TRUE) = GameCommand:Reset).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID F2AlsoResets():
        Assert:IsTrue(mMap:CommandFor("F2", FALSE) = GameCommand:Reset).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlusAndUpGoFasterMinusAndDownGoSlower():
        Assert:IsTrue(mMap:CommandFor("Oemplus", FALSE) = GameCommand:SpeedUp).
        Assert:IsTrue(mMap:CommandFor("Add", FALSE) = GameCommand:SpeedUp).
        Assert:IsTrue(mMap:CommandFor("Up", FALSE) = GameCommand:SpeedUp).
        Assert:IsTrue(mMap:CommandFor("OemMinus", FALSE) = GameCommand:SlowDown).
        Assert:IsTrue(mMap:CommandFor("Subtract", FALSE) = GameCommand:SlowDown).
        Assert:IsTrue(mMap:CommandFor("Down", FALSE) = GameCommand:SlowDown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OtherKeysMapToNothing():
        Assert:IsTrue(mMap:CommandFor("Q", FALSE) = ?).
        Assert:IsTrue(mMap:CommandFor("F5", TRUE) = ?).
        Assert:IsTrue(mMap:CommandFor("", FALSE) = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID KeyNamesAreMatchedIgnoringCaseLikeAllAblStrings():
        Assert:IsTrue(mMap:CommandFor("space", FALSE) = GameCommand:Start).
        Assert:IsTrue(mMap:CommandFor("s", FALSE) = GameCommand:StepOnce).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExtraCommandsAreFoundByTheirKeyLetter():
        Assert:Equals("Random", mMap:ExtraFor("G", "Random:G,Clear:C")).
        Assert:Equals("Clear", mMap:ExtraFor("C", "Random:G,Clear:C")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKeyThatIsNotAnExtraCommandGivesNothing():
        Assert:Equals("", mMap:ExtraFor("X", "Random:G,Clear:C")).
        Assert:Equals("", mMap:ExtraFor("G", "")).
        Assert:Equals("", mMap:ExtraFor("Space", "Random:G,Clear:C")).
        Assert:Equals("", mMap:ExtraFor("", "Random:G")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExtraCommandsWithoutAKeyLetterAreNeverTriggeredByKeys():
        Assert:Equals("", mMap:ExtraFor("R", "Random,Clear:C")).
        Assert:Equals("Clear", mMap:ExtraFor("C", "Random,Clear:C")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExtraCommandLettersIgnoreCase():
        /* the window passes the .NET key name, which is an upper case letter for a letter key */
        Assert:Equals("Random", mMap:ExtraFor("g", "Random:G")).
        Assert:Equals("Random", mMap:ExtraFor("G", "Random:G")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NameOfAndKeyOfSplitACommandEntry():
        Assert:Equals("Random", mMap:NameOf("Random:G")).
        Assert:Equals("G", mMap:KeyOf("Random:G")).
        Assert:Equals("Clear", mMap:NameOf(" Clear ")).
        Assert:Equals("", mMap:KeyOf("Clear")).
        Assert:Equals("Clear", mMap:NameOf("Clear")).
    END METHOD.

END CLASS.
