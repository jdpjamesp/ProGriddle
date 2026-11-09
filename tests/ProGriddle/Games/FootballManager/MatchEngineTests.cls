/* The match engine: when a side earns an attack, who attacks when one side is far stronger, the extra attacks of a 0 to 0 match, and the result of a match. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.MatchEngineTests:

    VAR PRIVATE INTEGER[5] mOwn.
    VAR PRIVATE INTEGER[5] mOpp.

    /* Both sides' five numbers set to the same pair of values. */
    METHOD PRIVATE VOID Strengths(INPUT piOwn AS INTEGER, INPUT piOpp AS INTEGER):
        VAR INTEGER i.
        DO i = 1 TO 5:
            mOwn[i] = piOwn.
            mOpp[i] = piOpp.
        END.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            Strengths(10, 10).
            CASE pcWhat:
                WHEN "side0" THEN MatchEngine:Play(mOwn, mOpp, 0, NEW ScriptedRandom("0")).
                WHEN "side3" THEN MatchEngine:Play(mOwn, mOpp, 3, NEW ScriptedRandom("0")).
                WHEN "random" THEN MatchEngine:Play(mOwn, mOpp, 1, ?).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARollEarnsAnAttackWhenItReachesSeventyFiveWithFivePerPointOfDifference():
        Assert:IsTrue(MatchEngine:Attacks(75, 10, 10)).
        Assert:IsFalse(MatchEngine:Attacks(74, 10, 10)).
        /* five points up is worth 25 */
        Assert:IsTrue(MatchEngine:Attacks(50, 15, 10)).
        Assert:IsFalse(MatchEngine:Attacks(49, 15, 10)).
        /* five points down costs 25, so only a 100 will do */
        Assert:IsTrue(MatchEngine:Attacks(100, 10, 15)).
        Assert:IsFalse(MatchEngine:Attacks(99, 10, 15)).
        Assert:IsFalse(MatchEngine:Attacks(100, 10, 16)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASideFarAheadInEveryNumberHasTwoAttacksForEachAndTheOtherNone():
        VAR INTEGER seed.
        VAR INTEGER a.
        VAR MatchResult result.
        Strengths(20, 1).
        DO seed = 1 TO 20:
            result = MatchEngine:Play(mOwn, mOpp, 1, NEW SeededRandom(seed)).
            /* ten attacks, all the manager's side (the home side), and two more if they were all fruitless */
            Assert:IsTrue(result:AttackCount = 10 OR result:AttackCount = 12).
            DO a = 1 TO 10:
                Assert:Equals(1, result:AttackAt(a):Team).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOtherSideAttacksWhenItIsFarAheadAndTheManagerIsAway():
        VAR INTEGER seed.
        VAR INTEGER a.
        VAR MatchResult result.
        Strengths(1, 20).
        DO seed = 1 TO 20:
            result = MatchEngine:Play(mOwn, mOpp, 2, NEW SeededRandom(seed)).
            Assert:IsTrue(result:AttackCount = 10 OR result:AttackCount = 12).
            /* the manager is team 2, so the strong opposition is team 1 */
            DO a = 1 TO 10:
                Assert:Equals(1, result:AttackAt(a):Team).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreIsTheGoalsOfTheAttacksAndNoMatchHasMoreThanTwentyTwoAttacks():
        VAR INTEGER seed.
        VAR INTEGER a.
        VAR INTEGER home.
        VAR INTEGER away.
        VAR MatchResult result.
        Strengths(12, 12).
        DO seed = 1 TO 60:
            result = MatchEngine:Play(mOwn, mOpp, 1 + (seed MODULO 2), NEW SeededRandom(seed)).
            Assert:IsTrue(result:AttackCount <= 22).
            home = 0.
            away = 0.
            DO a = 1 TO result:AttackCount:
                IF result:AttackAt(a):Scored THEN
                DO:
                    IF result:AttackAt(a):Team = 1 THEN home = home + 1.
                    ELSE away = away + 1.
                END.
            END.
            Assert:Equals(home, result:HomeGoals).
            Assert:Equals(away, result:AwayGoals).
            Assert:Equals(home, result:GoalsOf(1)).
            Assert:Equals(away, result:GoalsOf(2)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMatchWithNoAttacksAtAllGetsOneEachWithTheHomeSideFirst():
        VAR INTEGER seed.
        VAR MatchResult result.
        VAR LOGICAL found.
        Strengths(10, 10).
        DO seed = 1 TO 600:
            result = MatchEngine:Play(mOwn, mOpp, 1, NEW SeededRandom(seed)).
            /* attacks in the five rounds come in pairs for one team, so two attacks for different teams can only be the extra pair */
            IF result:AttackCount = 2 AND result:AttackAt(1):Team <> result:AttackAt(2):Team THEN
            DO:
                found = TRUE.
                Assert:Equals(1, result:AttackAt(1):Team).
                Assert:Equals(2, result:AttackAt(2):Team).
                LEAVE.
            END.
        END.
        Assert:IsTrue(found).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatAreNotAllowedAreRefused():
        Assert:IsTrue(Refused("side0")).
        Assert:IsTrue(Refused("side3")).
        Assert:IsTrue(Refused("random")).
    END METHOD.

END CLASS.
