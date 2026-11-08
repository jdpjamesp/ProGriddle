/* The tables, as the game reads them: speeds (a percentage of full speed), the rolled back time, the scatter and chase
   waves, the bit counts that let the phantoms out of the lobby and wind Mary up, the item and the points. Frame counts are at
   60 frames a second. Only some levels are tested, the ones where a table changes and the ones just either side. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachRulesTests:

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        VAR INTEGER n.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN n = ForEachRules:DibbySpeed(0).
                WHEN 2 THEN n = ForEachRules:RollbackFrames(0).
                WHEN 3 THEN n = ForEachRules:RageSpeed(1, 0).
                WHEN 4 THEN n = ForEachRules:RageSpeed(1, 3).
                WHEN 5 THEN n = ForEachRules:RageBits(1, 3).
                WHEN 6 THEN n = ForEachRules:WaveFrames(1, 0).
                WHEN 7 THEN n = ForEachRules:WaveFrames(1, 9).
                WHEN 8 THEN n = ForEachRules:PhantomPoints(0).
                WHEN 9 THEN n = ForEachRules:PhantomPoints(5).
                WHEN 10 THEN n = INTEGER(ForEachRules:ItemFor(0)).
                WHEN 11 THEN n = ForEachRules:ItemBitCount(3).
                WHEN 12 THEN n = ForEachRules:LobbyLimit(0, PhantomKind:Brian).
                WHEN 13 THEN n = ForEachRules:IntermissionAfter(0).
                WHEN 14 THEN n = ForEachRules:LobbyIdleFrames(0).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayerStartsWithThreeLivesAndGetsAnotherAt10000():
        Assert:Equals(3, ForEachRules:StartLives()).
        Assert:Equals(10000, ForEachRules:ExtraLifeScore()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABitIsWorth10AndACommitIs50():
        Assert:Equals(10, ForEachRules:BitPoints()).
        Assert:Equals(50, ForEachRules:CommitPoints()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EatingABitCostsOneFrameAndEatingACommitCostsThree():
        Assert:Equals(1, ForEachRules:EatPauseFrames(TileKind:Bit)).
        Assert:Equals(3, ForEachRules:EatPauseFrames(TileKind:Commit)).
        Assert:Equals(0, ForEachRules:EatPauseFrames(TileKind:Path)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DibbyRunsAt80PercentOnLevelOne90OnLevelsTwoToFour100FromFiveAnd90Again21On():
        Assert:Equals(80, ForEachRules:DibbySpeed(1)).
        Assert:Equals(90, ForEachRules:DibbySpeed(2)).
        Assert:Equals(90, ForEachRules:DibbySpeed(4)).
        Assert:Equals(100, ForEachRules:DibbySpeed(5)).
        Assert:Equals(100, ForEachRules:DibbySpeed(20)).
        Assert:Equals(90, ForEachRules:DibbySpeed(21)).
        Assert:Equals(90, ForEachRules:DibbySpeed(255)).
        Assert:IsTrue(ThrowsGridException(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePhantomsRunAt70PercentOnLevelOne80OnLevelsTwoToFourAnd90From5():
        Assert:Equals(70, ForEachRules:PhantomSpeed(1)).
        Assert:Equals(80, ForEachRules:PhantomSpeed(2)).
        Assert:Equals(80, ForEachRules:PhantomSpeed(4)).
        Assert:Equals(90, ForEachRules:PhantomSpeed(5)).
        Assert:Equals(85, ForEachRules:PhantomSpeed(21)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePhantomsSlowInTheTunnelTo40PercentThen45ThenHalf():
        Assert:Equals(40, ForEachRules:TunnelSpeed(1)).
        Assert:Equals(45, ForEachRules:TunnelSpeed(2)).
        Assert:Equals(45, ForEachRules:TunnelSpeed(4)).
        Assert:Equals(50, ForEachRules:TunnelSpeed(5)).
        Assert:Equals(50, ForEachRules:TunnelSpeed(21)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhilePhantomsAreRolledBackDibbyIsFasterAndTheyAreSlow():
        Assert:Equals(90, ForEachRules:DibbyRollbackSpeed(1)).
        Assert:Equals(95, ForEachRules:DibbyRollbackSpeed(2)).
        Assert:Equals(100, ForEachRules:DibbyRollbackSpeed(5)).
        Assert:Equals(50, ForEachRules:PhantomRollbackSpeed(1)).
        Assert:Equals(55, ForEachRules:PhantomRollbackSpeed(2)).
        Assert:Equals(60, ForEachRules:PhantomRollbackSpeed(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MaryRunsFasterInTwoStagesAsTheBitsRunOut():
        Assert:Equals(75, ForEachRules:RageSpeed(1, 1)).
        Assert:Equals(80, ForEachRules:RageSpeed(1, 2)).
        Assert:Equals(85, ForEachRules:RageSpeed(2, 1)).
        Assert:Equals(90, ForEachRules:RageSpeed(2, 2)).
        Assert:Equals(95, ForEachRules:RageSpeed(5, 1)).
        Assert:Equals(100, ForEachRules:RageSpeed(5, 2)).
        Assert:IsTrue(ThrowsGridException(3)).
        Assert:IsTrue(ThrowsGridException(4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MaryWindsUpWhen20ThenTenBitsAreLeftOnLevelOneAndEarlierAsTheLevelsGoUp():
        Assert:Equals(20, ForEachRules:RageBits(1, 1)).
        Assert:Equals(10, ForEachRules:RageBits(1, 2)).
        Assert:Equals(30, ForEachRules:RageBits(2, 1)).
        Assert:Equals(15, ForEachRules:RageBits(2, 2)).
        Assert:Equals(40, ForEachRules:RageBits(3, 1)).
        Assert:Equals(40, ForEachRules:RageBits(5, 1)).
        Assert:Equals(50, ForEachRules:RageBits(6, 1)).
        Assert:Equals(60, ForEachRules:RageBits(9, 1)).
        Assert:Equals(80, ForEachRules:RageBits(12, 1)).
        Assert:Equals(100, ForEachRules:RageBits(15, 1)).
        Assert:Equals(120, ForEachRules:RageBits(19, 1)).
        Assert:Equals(60, ForEachRules:RageBits(21, 2)).
        Assert:IsTrue(ThrowsGridException(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PhantomsStayRolledBackForSixSecondsOnLevelOneThenLessAndNoneFromLevel19():
        Assert:Equals(360, ForEachRules:RollbackFrames(1)).
        Assert:Equals(300, ForEachRules:RollbackFrames(2)).
        Assert:Equals(120, ForEachRules:RollbackFrames(5)).
        Assert:Equals(60, ForEachRules:RollbackFrames(9)).
        Assert:Equals(0, ForEachRules:RollbackFrames(17)).
        Assert:Equals(0, ForEachRules:RollbackFrames(19)).
        Assert:Equals(0, ForEachRules:RollbackFrames(21)).
        Assert:IsTrue(ThrowsGridException(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePhantomsFlashFiveTimesOnLevelOneThreeOnLevelNineAndNotAtAllOnLevel17():
        Assert:Equals(5, ForEachRules:FlashCount(1)).
        Assert:Equals(3, ForEachRules:FlashCount(9)).
        Assert:Equals(0, ForEachRules:FlashCount(17)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LevelOneAlternatesSevenAndTwentySecondsAndThenChasesForGood():
        Assert:Equals(420, ForEachRules:WaveFrames(1, 1)).
        Assert:Equals(1200, ForEachRules:WaveFrames(1, 2)).
        Assert:Equals(420, ForEachRules:WaveFrames(1, 3)).
        Assert:Equals(1200, ForEachRules:WaveFrames(1, 4)).
        Assert:Equals(300, ForEachRules:WaveFrames(1, 5)).
        Assert:Equals(1200, ForEachRules:WaveFrames(1, 6)).
        Assert:Equals(300, ForEachRules:WaveFrames(1, 7)).
        Assert:IsTrue(ForEachRules:WaveFrames(1, 8) = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LevelsTwoToFourChaseForNearlySeventeenMinutesAndScatterForOneFrame():
        Assert:Equals(420, ForEachRules:WaveFrames(2, 1)).
        Assert:Equals(300, ForEachRules:WaveFrames(2, 5)).
        Assert:Equals(61980, ForEachRules:WaveFrames(2, 6)).
        Assert:Equals(1, ForEachRules:WaveFrames(2, 7)).
        Assert:IsTrue(ForEachRules:WaveFrames(4, 8) = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LevelFiveOnScattersForFiveSecondsAtATime():
        Assert:Equals(300, ForEachRules:WaveFrames(5, 1)).
        Assert:Equals(300, ForEachRules:WaveFrames(5, 3)).
        Assert:Equals(62220, ForEachRules:WaveFrames(5, 6)).
        Assert:Equals(1, ForEachRules:WaveFrames(5, 7)).
        Assert:IsTrue(ForEachRules:WaveFrames(21, 8) = ?).
        Assert:IsTrue(ThrowsGridException(6)).
        Assert:IsTrue(ThrowsGridException(7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOddWavesScatterAndTheEvenOnesChase():
        Assert:IsTrue(ForEachRules:IsScatterWave(1)).
        Assert:IsFalse(ForEachRules:IsScatterWave(2)).
        Assert:IsTrue(ForEachRules:IsScatterWave(3)).
        Assert:IsTrue(ForEachRules:IsScatterWave(7)).
        Assert:IsFalse(ForEachRules:IsScatterWave(8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheItemIsAFloppyOnLevelOneAndAServerFromLevelThirteenOn():
        Assert:Equals(ItemKind:Floppy, ForEachRules:ItemFor(1)).
        Assert:Equals(ItemKind:Tape, ForEachRules:ItemFor(2)).
        Assert:Equals(ItemKind:Key, ForEachRules:ItemFor(3)).
        Assert:Equals(ItemKind:Key, ForEachRules:ItemFor(4)).
        Assert:Equals(ItemKind:Table, ForEachRules:ItemFor(5)).
        Assert:Equals(ItemKind:Table, ForEachRules:ItemFor(6)).
        Assert:Equals(ItemKind:Query, ForEachRules:ItemFor(7)).
        Assert:Equals(ItemKind:Query, ForEachRules:ItemFor(8)).
        Assert:Equals(ItemKind:Trigger, ForEachRules:ItemFor(9)).
        Assert:Equals(ItemKind:Trigger, ForEachRules:ItemFor(10)).
        Assert:Equals(ItemKind:Lock, ForEachRules:ItemFor(11)).
        Assert:Equals(ItemKind:Lock, ForEachRules:ItemFor(12)).
        Assert:Equals(ItemKind:Server, ForEachRules:ItemFor(13)).
        Assert:Equals(ItemKind:Server, ForEachRules:ItemFor(99)).
        Assert:IsTrue(ThrowsGridException(10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachItemHasItsOwnPoints():
        Assert:Equals(100, ForEachRules:ItemPoints(ItemKind:Floppy)).
        Assert:Equals(300, ForEachRules:ItemPoints(ItemKind:Tape)).
        Assert:Equals(500, ForEachRules:ItemPoints(ItemKind:Key)).
        Assert:Equals(700, ForEachRules:ItemPoints(ItemKind:Table)).
        Assert:Equals(1000, ForEachRules:ItemPoints(ItemKind:Query)).
        Assert:Equals(2000, ForEachRules:ItemPoints(ItemKind:Trigger)).
        Assert:Equals(3000, ForEachRules:ItemPoints(ItemKind:Lock)).
        Assert:Equals(5000, ForEachRules:ItemPoints(ItemKind:Server)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheItemComesAfterThe70thAndThe170thThingEatenAndStaysAboutTenSeconds():
        Assert:Equals(70, ForEachRules:ItemBitCount(1)).
        Assert:Equals(170, ForEachRules:ItemBitCount(2)).
        Assert:IsTrue(ForEachRules:ItemFrames() >= 540 AND ForEachRules:ItemFrames() <= 600).
        Assert:IsTrue(ThrowsGridException(11)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PhantomsEatenOnOneCommitAreWorth200400800AndThen1600():
        Assert:Equals(200, ForEachRules:PhantomPoints(1)).
        Assert:Equals(400, ForEachRules:PhantomPoints(2)).
        Assert:Equals(800, ForEachRules:PhantomPoints(3)).
        Assert:Equals(1600, ForEachRules:PhantomPoints(4)).
        Assert:IsTrue(ThrowsGridException(8)).
        Assert:IsTrue(ThrowsGridException(9)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnLevelOneMaryAndRichLeaveAtOnceBrianAfter30BitsAndChipAfter60():
        Assert:Equals(0, ForEachRules:LobbyLimit(1, PhantomKind:Mary)).
        Assert:Equals(0, ForEachRules:LobbyLimit(1, PhantomKind:Rich)).
        Assert:Equals(30, ForEachRules:LobbyLimit(1, PhantomKind:Brian)).
        Assert:Equals(60, ForEachRules:LobbyLimit(1, PhantomKind:Chip)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnLevelTwoOnlyChipWaitsAndFromLevelThreeNobodyDoes():
        Assert:Equals(0, ForEachRules:LobbyLimit(2, PhantomKind:Brian)).
        Assert:Equals(50, ForEachRules:LobbyLimit(2, PhantomKind:Chip)).
        Assert:Equals(0, ForEachRules:LobbyLimit(3, PhantomKind:Chip)).
        Assert:Equals(0, ForEachRules:LobbyLimit(21, PhantomKind:Brian)).
        Assert:IsTrue(ThrowsGridException(12)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AfterALifeIsLostThePhantomsLeaveOnASharedCountOf7Then17Then32():
        Assert:Equals(7, ForEachRules:GlobalLimit(PhantomKind:Rich)).
        Assert:Equals(17, ForEachRules:GlobalLimit(PhantomKind:Brian)).
        Assert:Equals(32, ForEachRules:GlobalLimit(PhantomKind:Chip)).
        Assert:Equals(0, ForEachRules:GlobalLimit(PhantomKind:Mary)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayerWhoEatsNothingForFourSecondsOnLevelsOneToFourAndThreeAfterwardsReleasesTheNextPhantom():
        Assert:Equals(240, ForEachRules:LobbyIdleFrames(1)).
        Assert:Equals(240, ForEachRules:LobbyIdleFrames(4)).
        Assert:Equals(180, ForEachRules:LobbyIdleFrames(5)).
        Assert:IsTrue(ThrowsGridException(14)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACartoonPlaysAfterLevels2And5And9And13And17():
        Assert:Equals(0, ForEachRules:IntermissionAfter(1)).
        Assert:Equals(1, ForEachRules:IntermissionAfter(2)).
        Assert:Equals(0, ForEachRules:IntermissionAfter(3)).
        Assert:Equals(2, ForEachRules:IntermissionAfter(5)).
        Assert:Equals(3, ForEachRules:IntermissionAfter(9)).
        Assert:Equals(3, ForEachRules:IntermissionAfter(13)).
        Assert:Equals(3, ForEachRules:IntermissionAfter(17)).
        Assert:Equals(0, ForEachRules:IntermissionAfter(18)).
        Assert:IsTrue(ThrowsGridException(13)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomIsNeverFasterThanDibbyOnTheSameLevelNotEvenMaryAtHerWorst():
        VAR INTEGER level.
        DO level = 1 TO 30:
            Assert:IsTrue(ForEachRules:PhantomSpeed(level) < ForEachRules:DibbySpeed(level)).
            Assert:IsTrue(ForEachRules:RageSpeed(level, 2) <= ForEachRules:DibbySpeed(level)).
        END.
    END METHOD.

END CLASS.
