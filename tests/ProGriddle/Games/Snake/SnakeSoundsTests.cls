/* The sounds of Snake: every cue has a recipe that ToneSynth makes into sound, and Fill puts all of them in a bank. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeSoundsTests:

    @Test.
    METHOD PUBLIC VOID EveryCueHasARecipeThatMakesSoundNotSilence():
        VAR INTEGER i.
        VAR INTEGER j.
        VAR ToneSynth oSynth.
        VAR MEMPTR mData.
        VAR INTEGER loud.
        oSynth = NEW ToneSynth().
        DO i = INTEGER(SnakeCue:Eat) TO INTEGER(SnakeCue:Win):
            oSynth:Make(SnakeSounds:Recipe(SnakeCue:GetEnum(i)), 100, OUTPUT mData).
            loud = 0.
            DO j = 1 TO GET-SIZE(mData):
                IF ABSOLUTE(GET-BYTE(mData, j) - 128) > 20 THEN loud = loud + 1.
            END.
            Assert:IsTrue(loud > 100).
            SET-SIZE(mData) = 0.
        END.
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCueHasAVolumeFromOneToOneHundred():
        VAR INTEGER i.
        DO i = INTEGER(SnakeCue:Eat) TO INTEGER(SnakeCue:Win):
            Assert:IsTrue(SnakeSounds:VolumeOf(SnakeCue:GetEnum(i)) >= 1).
            Assert:IsTrue(SnakeSounds:VolumeOf(SnakeCue:GetEnum(i)) <= 100).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillMakesAllThreeCuesInABankInUnderHalfASecond():
        VAR SoundBank oBank.
        VAR INTEGER i.
        VAR INTEGER start.
        VAR INTEGER took.
        oBank = NEW SoundBank().
        start = ETIME.
        SnakeSounds:Fill(oBank).
        took = ETIME - start.
        MESSAGE "SnakeSounds:Fill took " + STRING(took) + " ms" VIEW-AS ALERT-BOX INFORMATION.
        Assert:Equals(3, oBank:Count).
        DO i = INTEGER(SnakeCue:Eat) TO INTEGER(SnakeCue:Win):
            Assert:IsTrue(oBank:Has(i)).
        END.
        Assert:IsTrue(took < 500).
        FINALLY:
            IF VALID-OBJECT(oBank) THEN oBank:Dispose().
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownCueThrowsGridException():
        VAR INTEGER thrown.
        DO ON ERROR UNDO, THROW:
            SnakeSounds:Recipe(?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
