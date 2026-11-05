/* The sounds of Centipede: every cue has a recipe that ToneSynth makes into sound, and Fill puts all of them in a bank. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeSoundsTests:

    @Test.
    METHOD PUBLIC VOID EveryCueHasARecipeThatMakesSoundNotSilence():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oSynth AS ToneSynth NO-UNDO.
        DEFINE VARIABLE mData  AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE loud   AS INTEGER   NO-UNDO.
        oSynth = NEW ToneSynth().
        DO i = INTEGER(CentipedeCue:Fire) TO INTEGER(CentipedeCue:ScorpionLoop):
            oSynth:Make(CentipedeSounds:Recipe(CentipedeCue:GetEnum(i)), 100, OUTPUT mData).
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
    METHOD PUBLIC VOID TheTwoLoopsAreRecipesThatLoop():
        Assert:IsTrue(CentipedeSounds:Recipe(CentipedeCue:SpiderLoop) BEGINS "@").
        Assert:IsTrue(CentipedeSounds:Recipe(CentipedeCue:ScorpionLoop) BEGINS "@").
        Assert:IsFalse(CentipedeSounds:Recipe(CentipedeCue:Fire) BEGINS "@").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCueHasAVolumeFromOneToOneHundredAndTheLoopsAreQuiet():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = INTEGER(CentipedeCue:Fire) TO INTEGER(CentipedeCue:ScorpionLoop):
            Assert:IsTrue(CentipedeSounds:VolumeOf(CentipedeCue:GetEnum(i)) >= 1).
            Assert:IsTrue(CentipedeSounds:VolumeOf(CentipedeCue:GetEnum(i)) <= 100).
        END.
        Assert:IsTrue(CentipedeSounds:VolumeOf(CentipedeCue:SpiderLoop) < CentipedeSounds:VolumeOf(CentipedeCue:PlayerDies)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownCueIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE c      AS CentipedeCue NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CentipedeSounds:Recipe(c).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillMakesEveryCueInABankInUnderASecond():
        DEFINE VARIABLE oBank AS SoundBank NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE start AS INTEGER   NO-UNDO.
        DEFINE VARIABLE took  AS INTEGER   NO-UNDO.
        oBank = NEW SoundBank().
        start = ETIME.
        CentipedeSounds:Fill(oBank).
        took = ETIME - start.
        Assert:IsTrue(took < 1000).
        DO i = INTEGER(CentipedeCue:Fire) TO INTEGER(CentipedeCue:ScorpionLoop):
            Assert:IsTrue(oBank:Has(i)).
        END.
        oBank:Dispose().
    END METHOD.

END CLASS.
