USING OpenEdge.Core.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeRulesTests:

    @Test.
    METHOD PUBLIC VOID ConwayIsBirthOnThreeAndSurvivalOnTwoOrThree():
        DEFINE VARIABLE r AS LifeRules NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        r = LifeRules:Conway().
        Assert:Equals("B3/S23", r:Notation).
        DO n = 0 TO 8:
            Assert:Equals(n = 3, r:Births(n)).
            Assert:Equals(n = 2 OR n = 3, r:Survives(n)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HighLifeAlsoGivesBirthOnSix():
        DEFINE VARIABLE r AS LifeRules NO-UNDO.
        r = LifeRules:HighLife().
        Assert:Equals("B36/S23", r:Notation).
        Assert:IsTrue(r:Births(3)).
        Assert:IsTrue(r:Births(6)).
        Assert:IsFalse(r:Births(2)).
        Assert:IsFalse(r:Births(7)).
        Assert:IsTrue(r:Survives(2)).
        Assert:IsTrue(r:Survives(3)).
        Assert:IsFalse(r:Survives(6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NextStateAppliesBirthToDeadCellsAndSurvivalToLiveOnes():
        DEFINE VARIABLE r AS LifeRules NO-UNDO.
        r = LifeRules:Conway().
        Assert:Equals(1, r:NextState(0, 3)).
        Assert:Equals(0, r:NextState(0, 2)).
        Assert:Equals(0, r:NextState(0, 4)).
        Assert:Equals(1, r:NextState(1, 2)).
        Assert:Equals(1, r:NextState(1, 3)).
        Assert:Equals(0, r:NextState(1, 1)).
        Assert:Equals(0, r:NextState(1, 4)).
        Assert:Equals(0, r:NextState(1, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnyNonZeroStateCountsAsAlive():
        DEFINE VARIABLE r AS LifeRules NO-UNDO.
        r = LifeRules:Conway().
        Assert:Equals(1, r:NextState(5, 2)).
        Assert:Equals(0, r:NextState(-1, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CountsOutsideZeroToEightNeverGiveBirthOrSurvival():
        DEFINE VARIABLE r AS LifeRules NO-UNDO.
        r = NEW LifeRules("B012345678/S012345678").
        Assert:IsFalse(r:Births(-1)).
        Assert:IsFalse(r:Births(9)).
        Assert:IsFalse(r:Survives(-1)).
        Assert:IsFalse(r:Survives(100)).
        Assert:IsTrue(r:Births(0)).
        Assert:IsTrue(r:Survives(8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NotationIsCheckedUpperCasedAndSorted():
        Assert:Equals("B36/S23", NEW LifeRules("b63/s32"):Notation).
        Assert:Equals("B3/S23", NEW LifeRules("  B3/S23  "):Notation).
        Assert:Equals("B2/S", NEW LifeRules("B2/S"):Notation).
        Assert:Equals("B/S", NEW LifeRules("B/S"):Notation).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EmptyListsMeanNothingIsBornAndNothingSurvives():
        DEFINE VARIABLE r AS LifeRules NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        r = NEW LifeRules("B/S").
        DO n = 0 TO 8:
            Assert:IsFalse(r:Births(n)).
            Assert:IsFalse(r:Survives(n)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EqualsComparesTheRules():
        Assert:IsTrue(LifeRules:Conway():Equals(NEW LifeRules("b3/s32"))).
        Assert:IsFalse(LifeRules:Conway():Equals(LifeRules:HighLife())).
        Assert:IsFalse(LifeRules:Conway():Equals(NEW Progress.Lang.Object())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToStringIsTheNotation():
        Assert:Equals("B36/S23", LifeRules:HighLife():ToString()).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsNotationWithoutASlash():
        NEW LifeRules("B3S23").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsNotationWithoutTheLetters():
        NEW LifeRules("3/23").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsTheLettersInTheWrongOrder():
        NEW LifeRules("S23/B3").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsACountAboveEight():
        NEW LifeRules("B9/S23").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsANonDigit():
        NEW LifeRules("B3/S2x").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsARepeatedBirthCount():
        NEW LifeRules("B33/S23").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsARepeatedSurvivalCount():
        NEW LifeRules("B3/S233").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RejectsUnknownNotation():
        DEFINE VARIABLE s AS CHARACTER NO-UNDO.
        NEW LifeRules(s).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWellKnownRuleSetsAreOfferedByName():
        Assert:Equals("Conway,HighLife,Seeds,Day and Night,Life without Death,Maze", LifeRules:PresetNames()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPresetHasANotationThatLifeRulesAccepts():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(LifeRules:PresetNames()):
            Assert:IsTrue(LifeRules:PresetNotation(ENTRY(i, LifeRules:PresetNames())) <> "").
            Assert:Equals(LifeRules:PresetNotation(ENTRY(i, LifeRules:PresetNames())),
                          NEW LifeRules(LifeRules:PresetNotation(ENTRY(i, LifeRules:PresetNames()))):Notation).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePresetNotationsAreTheUsualOnes():
        Assert:Equals("B3/S23", LifeRules:PresetNotation("Conway")).
        Assert:Equals("B36/S23", LifeRules:PresetNotation("HighLife")).
        Assert:Equals("B2/S", LifeRules:PresetNotation("Seeds")).
        Assert:Equals("B3678/S34678", LifeRules:PresetNotation("Day and Night")).
        Assert:Equals("B3/S012345678", LifeRules:PresetNotation("Life without Death")).
        Assert:Equals("B3/S12345", LifeRules:PresetNotation("Maze")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANameThatIsNotAPresetHasNoNotation():
        Assert:Equals("", LifeRules:PresetNotation("Nonsense")).
        Assert:Equals("", LifeRules:PresetNotation("")).
        Assert:Equals("", LifeRules:PresetNotation(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APresetIsRecognisedFromAnySpellingOfItsNotation():
        Assert:Equals("Conway", LifeRules:PresetNameOf("B3/S23")).
        Assert:Equals("Conway", LifeRules:PresetNameOf("b3/s32")).
        Assert:Equals("HighLife", LifeRules:PresetNameOf("B63/S32")).
        Assert:Equals("Seeds", LifeRules:PresetNameOf("B2/S")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARuleThatIsNoPresetHasNoName():
        Assert:Equals("", LifeRules:PresetNameOf("B1/S1")).
        Assert:Equals("", LifeRules:PresetNameOf("junk")).
        Assert:Equals("", LifeRules:PresetNameOf(?)).
    END METHOD.

END CLASS.
