/* The sounds of Space Invaders: every cue has a recipe that ToneSynth makes into sound, the hum is a loop and Fill puts all
   eleven in a bank. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersSoundsTests:

    @Test.
    METHOD PUBLIC VOID EveryCueHasARecipeThatMakesSoundNotSilence():
        VAR INTEGER i.
        VAR INTEGER j.
        VAR ToneSynth oSynth.
        VAR MEMPTR mData.
        VAR INTEGER loud.
        oSynth = NEW ToneSynth().
        DO i = INTEGER(InvadersCue:Shoot) TO INTEGER(InvadersCue:SaucerHum):
            oSynth:Make(InvadersSounds:Recipe(InvadersCue:GetEnum(i)), 100, OUTPUT mData).
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
    METHOD PUBLIC VOID TheHumIsALoopAndNoOtherSoundIs():
        VAR INTEGER i.
        Assert:Equals("@", SUBSTRING(InvadersSounds:Recipe(InvadersCue:SaucerHum), 1, 1)).
        DO i = INTEGER(InvadersCue:Shoot) TO INTEGER(InvadersCue:WaveCleared):
            Assert:IsFalse(SUBSTRING(InvadersSounds:Recipe(InvadersCue:GetEnum(i)), 1, 1) = "@").
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFourMarchNotesGetLowerOneAfterAnother():
        VAR ToneSynth oSynth.
        VAR MEMPTR mData.
        VAR INTEGER i.
        VAR INTEGER j.
        VAR INTEGER edges.
        VAR INTEGER prior = 1000.
        oSynth = NEW ToneSynth().
        /* the number of rising edges in the sound is the number of cycles: a lower note has fewer */
        DO i = INTEGER(InvadersCue:March1) TO INTEGER(InvadersCue:March4):
            oSynth:Make(InvadersSounds:Recipe(InvadersCue:GetEnum(i)), 100, OUTPUT mData).
            edges = 0.
            DO j = 1 TO GET-SIZE(mData) - 1:
                IF GET-BYTE(mData, j) < 128 AND GET-BYTE(mData, j + 1) >= 128 THEN edges = edges + 1.
            END.
            Assert:IsTrue(edges < prior).
            prior = edges.
            SET-SIZE(mData) = 0.
        END.
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCueHasAVolumeFromOneToOneHundred():
        VAR INTEGER i.
        DO i = INTEGER(InvadersCue:Shoot) TO INTEGER(InvadersCue:SaucerHum):
            Assert:IsTrue(InvadersSounds:VolumeOf(InvadersCue:GetEnum(i)) >= 1).
            Assert:IsTrue(InvadersSounds:VolumeOf(InvadersCue:GetEnum(i)) <= 100).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillMakesAllElevenCuesInABankInUnderHalfASecond():
        VAR SoundBank oBank.
        VAR INTEGER i.
        VAR INTEGER start.
        VAR INTEGER took.
        oBank = NEW SoundBank().
        start = ETIME.
        InvadersSounds:Fill(oBank).
        took = ETIME - start.
        MESSAGE "InvadersSounds:Fill took " + STRING(took) + " ms" VIEW-AS ALERT-BOX INFORMATION.
        Assert:Equals(11, oBank:Count).
        DO i = INTEGER(InvadersCue:Shoot) TO INTEGER(InvadersCue:SaucerHum):
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
            InvadersSounds:Recipe(?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
