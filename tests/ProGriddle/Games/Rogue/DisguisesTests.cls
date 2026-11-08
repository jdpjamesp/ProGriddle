/* The unknown names of one game: a different colour, title, metal and stone for each kind, the same for the same seed, and what has been learnt. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.DisguisesTests:

    METHOD PRIVATE LOGICAL AllDifferent(INPUT poDisguises AS Disguises, INPUT poType AS ItemType):
        VAR INTEGER i.
        VAR INTEGER j.
        DO i = 0 TO 13:
            IF poDisguises:Appearance(poType, i) = "" THEN RETURN FALSE.
            DO j = i + 1 TO 13:
                IF poDisguises:Appearance(poType, i) = poDisguises:Appearance(poType, j) THEN RETURN FALSE.
            END.
        END.
        RETURN TRUE.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryKindOfEverySortHasItsOwnName():
        VAR Disguises oDisguises = NEW Disguises(NEW SeededRandom(1)).
        Assert:IsTrue(AllDifferent(oDisguises, ItemType:Potion)).
        Assert:IsTrue(AllDifferent(oDisguises, ItemType:Scroll)).
        Assert:IsTrue(AllDifferent(oDisguises, ItemType:Wand)).
        Assert:IsTrue(AllDifferent(oDisguises, ItemType:Ring)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ManySeedsAllGiveDistinctNames():
        VAR INTEGER i.
        VAR Disguises oDisguises.
        DO i = 1 TO 12:
            oDisguises = NEW Disguises(NEW SeededRandom(i * 17)).
            Assert:IsTrue(AllDifferent(oDisguises, ItemType:Potion)).
            Assert:IsTrue(AllDifferent(oDisguises, ItemType:Scroll)).
            Assert:IsTrue(AllDifferent(oDisguises, ItemType:Wand)).
            Assert:IsTrue(AllDifferent(oDisguises, ItemType:Ring)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameSeedGivesTheSameNamesAndAnotherSeedOtherOnes():
        VAR Disguises a.
        VAR Disguises b.
        VAR Disguises c.
        VAR INTEGER i.
        VAR LOGICAL differs.
        a = NEW Disguises(NEW SeededRandom(5)).
        b = NEW Disguises(NEW SeededRandom(5)).
        c = NEW Disguises(NEW SeededRandom(6)).
        DO i = 0 TO 13:
            Assert:Equals(a:Appearance(ItemType:Potion, i), b:Appearance(ItemType:Potion, i)).
            Assert:Equals(a:Appearance(ItemType:Scroll, i), b:Appearance(ItemType:Scroll, i)).
            IF a:Appearance(ItemType:Potion, i) <> c:Appearance(ItemType:Potion, i) THEN differs = TRUE.
        END.
        Assert:IsTrue(differs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameStartsWithNothingKnown():
        VAR Disguises oDisguises = NEW Disguises(NEW SeededRandom(2)).
        Assert:Equals(0, oDisguises:KnownCount()).
        Assert:IsFalse(oDisguises:IsKnown(ItemType:Potion, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LearningAKindMakesItKnownAndOnlyThatKind():
        VAR Disguises oDisguises = NEW Disguises(NEW SeededRandom(2)).
        oDisguises:Learn(ItemType:Potion, 3).
        oDisguises:Learn(ItemType:Ring, 0).
        Assert:IsTrue(oDisguises:IsKnown(ItemType:Potion, 3)).
        Assert:IsFalse(oDisguises:IsKnown(ItemType:Potion, 4)).
        Assert:IsFalse(oDisguises:IsKnown(ItemType:Scroll, 3)).
        Assert:IsTrue(oDisguises:IsKnown(ItemType:Ring, 0)).
        Assert:Equals(2, oDisguises:KnownCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShufflingForANewGameForgetsEverything():
        VAR Disguises oDisguises = NEW Disguises(NEW SeededRandom(2)).
        oDisguises:Learn(ItemType:Wand, 5).
        oDisguises:Shuffle(NEW SeededRandom(3)).
        Assert:Equals(0, oDisguises:KnownCount()).
        Assert:IsFalse(oDisguises:IsKnown(ItemType:Wand, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyFourSortsHaveNamesToDisguise():
        Assert:Equals(14, Disguises:Kinds(ItemType:Potion)).
        Assert:Equals(14, Disguises:Kinds(ItemType:Scroll)).
        Assert:Equals(14, Disguises:Kinds(ItemType:Wand)).
        Assert:Equals(14, Disguises:Kinds(ItemType:Ring)).
        Assert:Equals(0, Disguises:Kinds(ItemType:Weapon)).
        Assert:Equals(0, Disguises:Kinds(ItemType:Food)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadSortKindOrRandomSourceIsRefused():
        VAR Disguises oDisguises.
        VAR INTEGER thrown.
        oDisguises = NEW Disguises(NEW SeededRandom(2)).
        DO ON ERROR UNDO, THROW:
            oDisguises:Appearance(ItemType:Weapon, 0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oDisguises:Appearance(ItemType:Potion, 14).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oDisguises:Learn(?, 0).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW Disguises(?).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(4, thrown).
    END METHOD.

END CLASS.
