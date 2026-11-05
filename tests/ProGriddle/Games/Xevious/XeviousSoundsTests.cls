/* The sounds of Xevious: every cue has a recipe that ToneSynth makes into sound, and Fill puts all of them in a bank. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousSoundsTests:

    @Test.
    METHOD PUBLIC VOID EveryCueHasARecipeThatMakesSoundNotSilence():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oSynth AS ToneSynth NO-UNDO.
        DEFINE VARIABLE mData  AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE loud   AS INTEGER   NO-UNDO.
        oSynth = NEW ToneSynth().
        DO i = INTEGER(XeviousCue:Zap) TO INTEGER(XeviousCue:BossLoop):
            oSynth:Make(XeviousSounds:Recipe(XeviousCue:GetEnum(i)), 100, OUTPUT mData).
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
    METHOD PUBLIC VOID OnlyTheMothershipsHumLoopsAndItIsQuietest():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = INTEGER(XeviousCue:Zap) TO INTEGER(XeviousCue:StageClear):
            Assert:IsFalse(XeviousSounds:Recipe(XeviousCue:GetEnum(i)) BEGINS "@").
            Assert:IsTrue(XeviousSounds:VolumeOf(XeviousCue:GetEnum(i)) > XeviousSounds:VolumeOf(XeviousCue:BossLoop)).
        END.
        Assert:IsTrue(XeviousSounds:Recipe(XeviousCue:BossLoop) BEGINS "@").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillPutsEveryCueInTheBank():
        DEFINE VARIABLE oBank AS SoundBank NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        oBank = NEW SoundBank().
        XeviousSounds:Fill(oBank).
        DO i = INTEGER(XeviousCue:Zap) TO INTEGER(XeviousCue:BossLoop):
            Assert:IsTrue(oBank:Has(i)).
            Assert:IsTrue(oBank:SizeOf(i) > 0).
        END.
        oBank:Dispose().
    END METHOD.

END CLASS.
