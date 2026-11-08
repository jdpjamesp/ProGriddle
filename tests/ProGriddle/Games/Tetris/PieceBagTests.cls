USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.PieceBagTests:

    /* Deals n pieces from a bag seeded with piSeed into the array. */
    METHOD PRIVATE VOID Deal(INPUT piSeed AS INTEGER, INPUT piCount AS INTEGER, OUTPUT piPieces AS INTEGER EXTENT):
        VAR PieceBag bag.
        VAR INTEGER i.
        bag = NEW PieceBag(NEW SeededRandom(piSeed)).
        EXTENT(piPieces) = piCount.
        DO i = 1 TO piCount:
            piPieces[i] = bag:Next().
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EverySevenPiecesFromTheStartAreEachPieceOnce():
        VAR INTEGER seed.
        VAR INTEGER bagNo.
        VAR INTEGER i.
        VAR LOGICAL[7] seen.
        VAR INTEGER[] pieces.
        VAR INTEGER bad.
        DO seed = 1 TO 12:
            Deal(seed, 140, OUTPUT pieces).
            DO bagNo = 0 TO 19:
                DO i = 1 TO 7:
                    seen[i] = FALSE.
                END.
                DO i = 1 TO 7:
                    seen[pieces[bagNo * 7 + i]] = TRUE.
                END.
                DO i = 1 TO 7:
                    IF NOT seen[i] THEN bad = bad + 1.
                END.
            END.
        END.
        Assert:Equals(0, bad).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceNeverComesThreeTimesInARowAndNeverHasMoreThanTwelveOthersBetweenTwoOfAKind():
        VAR INTEGER seed.
        VAR INTEGER i.
        VAR INTEGER p.
        VAR INTEGER[] pieces.
        VAR INTEGER[7] lastSeen.
        VAR INTEGER runs.
        VAR INTEGER waits.
        DO seed = 1 TO 12:
            Deal(seed, 700, OUTPUT pieces).
            DO p = 1 TO 7:
                lastSeen[p] = 0.
            END.
            DO i = 1 TO 700:
                IF i >= 3 AND pieces[i] = pieces[i - 1] AND pieces[i] = pieces[i - 2] THEN runs = runs + 1.
                IF lastSeen[pieces[i]] > 0 AND i - lastSeen[pieces[i]] > 13 THEN waits = waits + 1.
                lastSeen[pieces[i]] = i.
            END.
        END.
        Assert:Equals(0, runs).
        Assert:Equals(0, waits).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameSeedDealsTheSamePiecesAndAnotherSeedDealsDifferentOnes():
        VAR INTEGER[] a.
        VAR INTEGER[] b.
        VAR INTEGER[] c.
        VAR INTEGER i.
        VAR LOGICAL sameAB = TRUE.
        VAR LOGICAL sameAC = TRUE.
        Deal(5, 70, OUTPUT a).
        Deal(5, 70, OUTPUT b).
        Deal(6, 70, OUTPUT c).
        DO i = 1 TO 70:
            IF a[i] <> b[i] THEN sameAB = FALSE.
            IF a[i] <> c[i] THEN sameAC = FALSE.
        END.
        Assert:IsTrue(sameAB).
        Assert:IsFalse(sameAC).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPieceIsInTheRangeOneToSeven():
        VAR INTEGER[] pieces.
        VAR INTEGER i.
        VAR INTEGER bad.
        Deal(3, 100, OUTPUT pieces).
        DO i = 1 TO 100:
            IF pieces[i] < 1 OR pieces[i] > 7 THEN bad = bad + 1.
        END.
        Assert:Equals(0, bad).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PresetPiecesComeFirstInOrderAndThenTheBagCarriesOn():
        VAR PieceBag bag = NEW PieceBag(NEW SeededRandom(1)).
        bag:Preset("L,I,T").
        Assert:Equals(7, bag:Next()).
        Assert:Equals(1, bag:Next()).
        Assert:Equals(3, bag:Next()).
        Assert:IsTrue(bag:Next() >= 1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APresetGoesInFrontOfAnEarlierPreset():
        VAR PieceBag bag = NEW PieceBag(NEW SeededRandom(1)).
        bag:Preset("O,O").
        bag:Preset("I").
        Assert:Equals(1, bag:Next()).
        Assert:Equals(2, bag:Next()).
        Assert:Equals(2, bag:Next()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APresetDoesNotUseUpABagThatWasAlreadyStarted():
        VAR PieceBag bag.
        VAR INTEGER i.
        VAR LOGICAL[7] seen.
        VAR INTEGER missed.
        bag = NEW PieceBag(NEW SeededRandom(2)).
        bag:Next().
        bag:Next().
        bag:Preset("Z").
        bag:Next().
        /* five pieces of the first bag are left, and then a second bag: seven in all from the first bag */
        DO i = 1 TO 5:
            seen[bag:Next()] = TRUE.
        END.
        DO i = 1 TO 7:
            IF NOT seen[i] THEN missed = missed + 1.
        END.
        Assert:Equals(2, missed).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID APresetWithAnUnknownPieceThrows():
        VAR PieceBag bag = NEW PieceBag(NEW SeededRandom(1)).
        bag:Preset("I,Q").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABagNeedsARandomSource():
        VAR PieceBag bag = NEW PieceBag(?).
    END METHOD.

END CLASS.
