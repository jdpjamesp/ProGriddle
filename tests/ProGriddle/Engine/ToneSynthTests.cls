/* The tone synthesiser: a recipe such as "880>440:80,n:120" becomes 8 bit unsigned mono sound at 11025 Hz, 128 being silence.
   The tests read the bytes. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.ToneSynthTests:

    DEFINE PRIVATE VARIABLE mSynth AS ToneSynth NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildSynth():
        mSynth = NEW ToneSynth().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseSynth():
        mSynth = ?.
    END METHOD.

    /* the cycle length in samples of a square wave: from the first rising edge at or after piFrom to the next one */
    METHOD PRIVATE INTEGER PeriodAt(INPUT pmData AS MEMPTR, INPUT piFrom AS INTEGER):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE edge AS INTEGER NO-UNDO.
        DO i = piFrom TO GET-SIZE(pmData) - 1:
            IF GET-BYTE(pmData, i) < 128 AND GET-BYTE(pmData, i + 1) >= 128 THEN DO:
                IF edge = 0 THEN edge = i.
                ELSE RETURN i - edge.
            END.
        END.
        RETURN 0.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSampleRateIs11025():
        Assert:Equals(11025, ToneSynth:SampleRate()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SampleCountAddsTheWholeSamplesOfEachPart():
        /* 200 ms = 2205, 100 ms = 1102 and 50 ms = 551 samples, each part cut to whole samples */
        Assert:Equals(3858, mSynth:SampleCount("440:200,r:100,n:50")).
        Assert:Equals(11025, mSynth:SampleCount("880>440:1000")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MakeGivesExactlyThatManySamplesAndSilenceAtBothEnds():
        DEFINE VARIABLE mData AS MEMPTR NO-UNDO.
        mSynth:Make("440:200,880:100", 100, OUTPUT mData).
        Assert:Equals(mSynth:SampleCount("440:200,880:100"), GET-SIZE(mData)).
        Assert:Equals(128, GET-BYTE(mData, 1)).
        Assert:Equals(128, GET-BYTE(mData, GET-SIZE(mData))).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARecipeThatStartsWithAtHasNoFadeAtItsVeryStartAndEndSoItCanLoop():
        DEFINE VARIABLE mData AS MEMPTR NO-UNDO.
        mSynth:Make("@440:100:0", 100, OUTPUT mData).
        Assert:Equals(mSynth:SampleCount("440:100:0"), GET-SIZE(mData)).
        Assert:Equals(mSynth:SampleCount("440:100:0"), mSynth:SampleCount("@440:100:0")).
        /* a square wave at full swing from the first sample to the last */
        Assert:IsTrue(ABSOLUTE(GET-BYTE(mData, 1) - 128) > 100).
        Assert:IsTrue(ABSOLUTE(GET-BYTE(mData, GET-SIZE(mData)) - 128) > 100).
        SET-SIZE(mData) = 0.
        /* the part joined in the middle still fades, so the middle is quiet */
        mSynth:Make("@440:100:0,440:100:0", 100, OUTPUT mData).
        Assert:Equals(128, GET-BYTE(mData, 1102)).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AToneWithNoDecayIsASquareWaveOfTwoLevelsAroundSilence():
        DEFINE VARIABLE mData AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE high  AS INTEGER NO-UNDO.
        DEFINE VARIABLE low   AS INTEGER NO-UNDO.
        DEFINE VARIABLE other AS INTEGER NO-UNDO.
        mSynth:Make("440:200:0", 100, OUTPUT mData).
        /* past the rise at the start and before the fall at the end: only 255 (128 + 127) and 1 (128 - 127) */
        DO i = 100 TO 2000:
            IF GET-BYTE(mData, i) = 255 THEN high = high + 1.
            ELSE IF GET-BYTE(mData, i) = 1 THEN low = low + 1.
            ELSE other = other + 1.
        END.
        Assert:Equals(0, other).
        Assert:IsTrue(high > 700).
        Assert:IsTrue(low > 700).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheVolumeIsAPercentageOfTheFullSwingAndZeroIsSilent():
        DEFINE VARIABLE mData AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE top   AS INTEGER NO-UNDO.
        DEFINE VARIABLE other AS INTEGER NO-UNDO.
        mSynth:Make("440:200:0", 50, OUTPUT mData).
        DO i = 100 TO 2000:
            top = MAXIMUM(top, GET-BYTE(mData, i)).
        END.
        /* half of 127 is 63 */
        Assert:Equals(128 + 63, top).
        SET-SIZE(mData) = 0.
        mSynth:Make("440:200:0", 0, OUTPUT mData).
        DO i = 1 TO GET-SIZE(mData):
            IF GET-BYTE(mData, i) <> 128 THEN other = other + 1.
        END.
        Assert:Equals(0, other).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADecayMakesTheToneFadeAcrossItsPart():
        DEFINE VARIABLE mData AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE early AS INTEGER NO-UNDO.
        DEFINE VARIABLE late  AS INTEGER NO-UNDO.
        /* a tone that loses 80 percent of its swing: loud near the start, quiet near the end */
        mSynth:Make("440:400:80", 100, OUTPUT mData).
        DO i = 100 TO 400:
            early = MAXIMUM(early, GET-BYTE(mData, i) - 128).
        END.
        DO i = 3800 TO 4200:
            late = MAXIMUM(late, GET-BYTE(mData, i) - 128).
        END.
        Assert:IsTrue(early >= 115).
        Assert:IsTrue(late <= 40).
        Assert:IsTrue(late > 0).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASlideUpGetsShorterCyclesAndASlideDownGetsLongerOnes():
        DEFINE VARIABLE mData AS MEMPTR NO-UNDO.
        DEFINE VARIABLE early AS INTEGER NO-UNDO.
        DEFINE VARIABLE late  AS INTEGER NO-UNDO.
        mSynth:Make("200>800:400:0", 100, OUTPUT mData).
        early = PeriodAt(mData, 100).
        late = PeriodAt(mData, 4000).
        Assert:IsTrue(early > 0).
        Assert:IsTrue(late > 0).
        Assert:IsTrue(late < early).
        SET-SIZE(mData) = 0.
        mSynth:Make("800>200:400:0", 100, OUTPUT mData).
        early = PeriodAt(mData, 100).
        late = PeriodAt(mData, 4000).
        Assert:IsTrue(late > early).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFixedToneHasTheCycleLengthOfItsPitch():
        DEFINE VARIABLE mData AS MEMPTR NO-UNDO.
        DEFINE VARIABLE cycle AS INTEGER NO-UNDO.
        /* 11025 / 441 = 25 samples */
        mSynth:Make("441:200:0", 100, OUTPUT mData).
        cycle = PeriodAt(mData, 100).
        Assert:IsTrue(cycle >= 24 AND cycle <= 26).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATrianglePartHasManyLevelsAndARestIsSilent():
        DEFINE VARIABLE mData   AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE levels  AS INTEGER NO-UNDO.
        DEFINE VARIABLE other   AS INTEGER NO-UNDO.
        DEFINE VARIABLE seen    AS LOGICAL NO-UNDO EXTENT 256.
        mSynth:Make("t220:200:0", 100, OUTPUT mData).
        DO i = 100 TO 2000:
            seen[GET-BYTE(mData, i) + 1] = TRUE.
        END.
        DO i = 1 TO 256:
            IF seen[i] THEN levels = levels + 1.
        END.
        Assert:IsTrue(levels > 20).
        SET-SIZE(mData) = 0.
        mSynth:Make("r:50", 100, OUTPUT mData).
        Assert:Equals(mSynth:SampleCount("r:50"), GET-SIZE(mData)).
        DO i = 1 TO GET-SIZE(mData):
            IF GET-BYTE(mData, i) <> 128 THEN other = other + 1.
        END.
        Assert:Equals(0, other).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoiseSwitchesBetweenItsLevelsAtIrregularTimes():
        DEFINE VARIABLE mData       AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE i           AS INTEGER NO-UNDO.
        DEFINE VARIABLE changes     AS INTEGER NO-UNDO.
        DEFINE VARIABLE shortRuns   AS INTEGER NO-UNDO.
        DEFINE VARIABLE longRuns    AS INTEGER NO-UNDO.
        DEFINE VARIABLE runLength   AS INTEGER NO-UNDO.
        mSynth:Make("n:300:0", 100, OUTPUT mData).
        runLength = 1.
        DO i = 101 TO 3000:
            IF GET-BYTE(mData, i) <> GET-BYTE(mData, i - 1) THEN DO:
                changes = changes + 1.
                IF runLength <= 3 THEN shortRuns = shortRuns + 1.
                ELSE longRuns = longRuns + 1.
                runLength = 1.
            END.
            ELSE runLength = runLength + 1.
        END.
        Assert:IsTrue(changes > 100).
        /* a wave would change at regular times: noise has runs of one step and of several */
        Assert:IsTrue(shortRuns > 10).
        Assert:IsTrue(longRuns > 10).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameRecipeGivesTheSameBytes():
        DEFINE VARIABLE mFirst  AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE mSecond AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE differ  AS INTEGER NO-UNDO.
        mSynth:Make("880>440:80,n:120,t330:60:30", 80, OUTPUT mFirst).
        mSynth:Make("880>440:80,n:120,t330:60:30", 80, OUTPUT mSecond).
        Assert:Equals(GET-SIZE(mFirst), GET-SIZE(mSecond)).
        DO i = 1 TO GET-SIZE(mFirst):
            IF GET-BYTE(mFirst, i) <> GET-BYTE(mSecond, i) THEN differ = differ + 1.
        END.
        Assert:Equals(0, differ).
        FINALLY:
            SET-SIZE(mFirst) = 0.
            SET-SIZE(mSecond) = 0.
        END FINALLY.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadRecipeOrVolumeThrowsGridException():
        DEFINE VARIABLE mData  AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE bad    AS CHARACTER NO-UNDO EXTENT 11.
        bad[1] = "".
        bad[2] = "abc".
        bad[3] = "440".
        bad[4] = "440:0".
        bad[5] = "440:abc".
        bad[6] = "9999:100".
        bad[7] = "10:100".
        bad[8] = "440:100:101".
        bad[9] = "x440:100".
        bad[10] = "440>:100".
        bad[11] = "440:20000".
        DO i = 1 TO 11:
            DO ON ERROR UNDO, THROW:
                mSynth:Make(bad[i], 100, OUTPUT mData).
                CATCH e1 AS GridException:
                    thrown = thrown + 1.
                END CATCH.
            END.
        END.
        Assert:Equals(11, thrown).
        DO ON ERROR UNDO, THROW:
            mSynth:Make("440:100", 101, OUTPUT mData).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mSynth:Make("440:100", -1, OUTPUT mData).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mSynth:SampleCount("440").
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(14, thrown).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

    /* Start up cost: a game makes all its cues at once, so a second of sound must not take long. The measured time is in
       docs/framework/sound.md, this only guards against a slow down. */
    @Test.
    METHOD PUBLIC VOID AboutASecondOfMixedSoundIsMadeInWellUnderAHalfSecond():
        DEFINE VARIABLE mData  AS MEMPTR  NO-UNDO.
        DEFINE VARIABLE start  AS INTEGER NO-UNDO.
        DEFINE VARIABLE took   AS INTEGER NO-UNDO.
        start = ETIME.
        mSynth:Make("523:60,659:60,784:60,1047:60,784:50,1047:50,1319:200", 80, OUTPUT mData).
        SET-SIZE(mData) = 0.
        mSynth:Make("392>196:160,330>147:160,t262>65:420,n:160", 80, OUTPUT mData).
        took = ETIME - start.
        MESSAGE "ToneSynth: " + STRING(mSynth:SampleCount("523:60,659:60,784:60,1047:60,784:50,1047:50,1319:200") + mSynth:SampleCount("392>196:160,330>147:160,t262>65:420,n:160")) + " samples in " + STRING(took) + " ms" VIEW-AS ALERT-BOX INFORMATION.
        Assert:IsTrue(took < 500).
        FINALLY:
            SET-SIZE(mData) = 0.
        END FINALLY.
    END METHOD.

END CLASS.
