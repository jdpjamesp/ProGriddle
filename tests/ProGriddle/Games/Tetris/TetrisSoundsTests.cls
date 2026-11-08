/* The sounds of Tetris: every cue has a recipe that ToneSynth makes into sound, and Fill puts all of them in a bank. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisSoundsTests:

    @Test.
    METHOD PUBLIC VOID EveryCueHasARecipeThatMakesSoundNotSilence():
        VAR INTEGER i.
        VAR INTEGER j.
        VAR ToneSynth oSynth.
        VAR MEMPTR mData.
        VAR INTEGER loud.
        oSynth = NEW ToneSynth().
        DO i = INTEGER(TetrisCue:Lock) TO INTEGER(TetrisCue:Danger):
            oSynth:Make(TetrisSounds:Recipe(TetrisCue:GetEnum(i)), 100, OUTPUT mData).
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
        DO i = INTEGER(TetrisCue:Lock) TO INTEGER(TetrisCue:Danger):
            Assert:IsTrue(TetrisSounds:VolumeOf(TetrisCue:GetEnum(i)) >= 1).
            Assert:IsTrue(TetrisSounds:VolumeOf(TetrisCue:GetEnum(i)) <= 100).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillMakesAllSixCuesInABankInUnderHalfASecond():
        VAR SoundBank oBank.
        VAR INTEGER i.
        VAR INTEGER start.
        VAR INTEGER took.
        oBank = NEW SoundBank().
        start = ETIME.
        TetrisSounds:Fill(oBank).
        took = ETIME - start.
        MESSAGE "TetrisSounds:Fill took " + STRING(took) + " ms" VIEW-AS ALERT-BOX INFORMATION.
        Assert:Equals(6, oBank:Count).
        DO i = INTEGER(TetrisCue:Lock) TO INTEGER(TetrisCue:Danger):
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
            TetrisSounds:Recipe(?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
