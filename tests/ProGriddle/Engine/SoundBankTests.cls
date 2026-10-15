/* The sound bank: the made sounds of a game, kept by cue number (the integer of a cue enum, 1 to 64), freed together. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SoundBankTests:

    DEFINE PRIVATE VARIABLE mBank AS SoundBank NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildBank():
        mBank = NEW SoundBank().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseBank():
        IF VALID-OBJECT(mBank) THEN mBank:Dispose().
        mBank = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADefinedSoundHasItsRecipesLengthAndAnAddress():
        mBank:Define(3, "440:100,n:50", 80).
        Assert:IsTrue(mBank:Has(3)).
        Assert:Equals(1, mBank:Count).
        Assert:Equals(1653, mBank:SizeOf(3)).
        Assert:IsTrue(mBank:PointerOf(3) <> 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACueThatWasNeverDefinedIsNotThere():
        Assert:IsFalse(mBank:Has(5)).
        Assert:IsFalse(mBank:Has(0)).
        Assert:IsFalse(mBank:Has(65)).
        Assert:IsFalse(mBank:Has(?)).
        Assert:Equals(0, mBank:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DefiningACueAgainReplacesItsSound():
        mBank:Define(2, "440:100", 80).
        mBank:Define(2, "440:200", 80).
        Assert:Equals(1, mBank:Count).
        Assert:Equals(2205, mBank:SizeOf(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeFreesEverythingAndCanBeCalledAgain():
        mBank:Define(1, "440:100", 80).
        mBank:Define(2, "n:100", 80).
        mBank:Dispose().
        Assert:Equals(0, mBank:Count).
        Assert:IsFalse(mBank:Has(1)).
        mBank:Dispose().
        /* and it is usable again afterwards */
        mBank:Define(1, "440:100", 80).
        Assert:IsTrue(mBank:Has(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadCueNumberAnUnknownCueOrABadRecipeThrowsGridException():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mBank:Define(0, "440:100", 80).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mBank:Define(65, "440:100", 80).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mBank:Define(1, "nonsense", 80).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mBank:SizeOf(7).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mBank:PointerOf(7).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(5, thrown).
        Assert:Equals(0, mBank:Count).
    END METHOD.

END CLASS.
