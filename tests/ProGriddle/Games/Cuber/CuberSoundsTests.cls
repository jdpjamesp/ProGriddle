/* The sounds of Cuber: every cue has a recipe that ToneSynth makes into sound, nothing loops, and Fill puts all of them in a bank. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberSoundsTests:

    @Test.
    METHOD PUBLIC VOID EveryCueHasARecipeThatMakesSoundNotSilence():
        VAR INTEGER i.
        VAR INTEGER j.
        VAR ToneSynth oSynth.
        VAR MEMPTR mData.
        VAR INTEGER loud.
        oSynth = NEW ToneSynth().
        DO i = INTEGER(CuberCue:Hop) TO INTEGER(CuberCue:GameStart):
            oSynth:Make(CuberSounds:Recipe(CuberCue:GetEnum(i)), 100, OUTPUT mData).
            loud = 0.
            DO j = 1 TO GET-SIZE(mData):
                IF ABSOLUTE(GET-BYTE(mData, j) - 128) > 10 THEN loud = loud + 1.
            END.
            Assert:IsTrue(loud > 100).
            SET-SIZE(mData) = 0.
        END.
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingInCuberLoops():
        VAR INTEGER i.
        DO i = INTEGER(CuberCue:Hop) TO INTEGER(CuberCue:GameStart):
            Assert:IsFalse(CuberSounds:Recipe(CuberCue:GetEnum(i)) BEGINS "@").
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCueHasAVolumeFromOneToOneHundredAndTheHopIsTheQuietest():
        VAR INTEGER i.
        DO i = INTEGER(CuberCue:Hop) TO INTEGER(CuberCue:GameStart):
            Assert:IsTrue(CuberSounds:VolumeOf(CuberCue:GetEnum(i)) >= 1).
            Assert:IsTrue(CuberSounds:VolumeOf(CuberCue:GetEnum(i)) <= 100).
            Assert:IsTrue(CuberSounds:VolumeOf(CuberCue:Hop) <= CuberSounds:VolumeOf(CuberCue:GetEnum(i))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownCueIsRefused():
        VAR LOGICAL thrown.
        VAR CuberCue c.
        DO ON ERROR UNDO, LEAVE:
            CuberSounds:Recipe(c).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillPutsEveryCueInTheBankUnderItsNumber():
        VAR SoundBank oBank.
        VAR INTEGER i.
        oBank = NEW SoundBank().
        CuberSounds:Fill(oBank).
        DO i = INTEGER(CuberCue:Hop) TO INTEGER(CuberCue:GameStart):
            Assert:IsTrue(oBank:Has(i)).
        END.
        FINALLY:
            IF VALID-OBJECT(oBank) THEN oBank:Dispose().
        END FINALLY.
    END METHOD.

END CLASS.
