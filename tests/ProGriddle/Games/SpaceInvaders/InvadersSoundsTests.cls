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
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oSynth AS ToneSynth NO-UNDO.
        DEFINE VARIABLE mData  AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE loud   AS INTEGER   NO-UNDO.
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
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals("@", SUBSTRING(InvadersSounds:Recipe(InvadersCue:SaucerHum), 1, 1)).
        DO i = INTEGER(InvadersCue:Shoot) TO INTEGER(InvadersCue:WaveCleared):
            Assert:IsFalse(SUBSTRING(InvadersSounds:Recipe(InvadersCue:GetEnum(i)), 1, 1) = "@").
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFourMarchNotesGetLowerOneAfterAnother():
        DEFINE VARIABLE oSynth AS ToneSynth NO-UNDO.
        DEFINE VARIABLE mData  AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE edges  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE prior   AS INTEGER   NO-UNDO INITIAL 1000.
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
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = INTEGER(InvadersCue:Shoot) TO INTEGER(InvadersCue:SaucerHum):
            Assert:IsTrue(InvadersSounds:VolumeOf(InvadersCue:GetEnum(i)) >= 1).
            Assert:IsTrue(InvadersSounds:VolumeOf(InvadersCue:GetEnum(i)) <= 100).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillMakesAllElevenCuesInABankInUnderHalfASecond():
        DEFINE VARIABLE oBank AS SoundBank NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE start AS INTEGER   NO-UNDO.
        DEFINE VARIABLE took  AS INTEGER   NO-UNDO.
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
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            InvadersSounds:Recipe(?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
