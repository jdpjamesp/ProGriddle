/* The sounds of Asteroids: every cue has a recipe that ToneSynth makes into sound, the three loops are loops and nothing else is,
   and Fill puts all twelve in a bank. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsSoundsTests:

    @Test.
    METHOD PUBLIC VOID EveryCueHasARecipeThatMakesSoundNotSilence():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oSynth AS ToneSynth NO-UNDO.
        DEFINE VARIABLE mData  AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE loud   AS INTEGER   NO-UNDO.
        oSynth = NEW ToneSynth().
        DO i = INTEGER(AsteroidsCue:Fire) TO INTEGER(AsteroidsCue:SaucerSmallHum):
            oSynth:Make(AsteroidsSounds:Recipe(AsteroidsCue:GetEnum(i)), 100, OUTPUT mData).
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
    METHOD PUBLIC VOID TheThrustAndTheTwoHumsAreLoopsAndNoOtherSoundIs():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = INTEGER(AsteroidsCue:Fire) TO INTEGER(AsteroidsCue:SaucerSmallHum):
            IF i >= INTEGER(AsteroidsCue:ThrustLoop) THEN Assert:Equals("@", SUBSTRING(AsteroidsSounds:Recipe(AsteroidsCue:GetEnum(i)), 1, 1)).
            ELSE Assert:IsFalse(SUBSTRING(AsteroidsSounds:Recipe(AsteroidsCue:GetEnum(i)), 1, 1) = "@").
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALargeRockBoomsLowerThanASmallOne():
        DEFINE VARIABLE oSynth AS ToneSynth NO-UNDO.
        DEFINE VARIABLE mLarge AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE mSmall AS MEMPTR    NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE large  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE small  AS INTEGER   NO-UNDO.
        oSynth = NEW ToneSynth().
        oSynth:Make(AsteroidsSounds:Recipe(AsteroidsCue:RockLarge), 100, OUTPUT mLarge).
        oSynth:Make(AsteroidsSounds:Recipe(AsteroidsCue:RockSmall), 100, OUTPUT mSmall).
        /* the tone after the burst of noise: the large rock is a longer sound with fewer rising edges to the second */
        Assert:IsTrue(GET-SIZE(mLarge) > GET-SIZE(mSmall)).
        DO i = 1 TO GET-SIZE(mLarge) - 1:
            IF GET-BYTE(mLarge, i) < 128 AND GET-BYTE(mLarge, i + 1) >= 128 THEN large = large + 1.
        END.
        DO i = 1 TO GET-SIZE(mSmall) - 1:
            IF GET-BYTE(mSmall, i) < 128 AND GET-BYTE(mSmall, i + 1) >= 128 THEN small = small + 1.
        END.
        Assert:IsTrue(large * GET-SIZE(mSmall) < small * GET-SIZE(mLarge)).
        FINALLY:
            SET-SIZE(mLarge) = 0.
            SET-SIZE(mSmall) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCueHasAVolumeFromOneToOneHundred():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = INTEGER(AsteroidsCue:Fire) TO INTEGER(AsteroidsCue:SaucerSmallHum):
            Assert:IsTrue(AsteroidsSounds:VolumeOf(AsteroidsCue:GetEnum(i)) >= 1).
            Assert:IsTrue(AsteroidsSounds:VolumeOf(AsteroidsCue:GetEnum(i)) <= 100).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FillMakesAllTwelveCuesInABankInUnderHalfASecond():
        DEFINE VARIABLE oBank AS SoundBank NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE start AS INTEGER   NO-UNDO.
        DEFINE VARIABLE took  AS INTEGER   NO-UNDO.
        oBank = NEW SoundBank().
        start = ETIME.
        AsteroidsSounds:Fill(oBank).
        took = ETIME - start.
        MESSAGE "AsteroidsSounds:Fill took " + STRING(took) + " ms" VIEW-AS ALERT-BOX INFORMATION.
        Assert:Equals(12, oBank:Count).
        DO i = INTEGER(AsteroidsCue:Fire) TO INTEGER(AsteroidsCue:SaucerSmallHum):
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
            AsteroidsSounds:Recipe(?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
