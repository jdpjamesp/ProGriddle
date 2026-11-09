/* Who the manager meets, in the league and the cup, and the opposition's five numbers. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.OppositionTests:

    VAR PRIVATE FootballWorld mWorld.

    @Setup.
    METHOD PUBLIC VOID BuildWorld():
        mWorld = NEW FootballWorld().
        mWorld:NewGame("Bob", 1, 3, 0, NEW ScriptedRandom("0")).
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "league0" THEN
                DO:
                    mWorld:LeagueMatch = 0.
                    Opposition:LeagueSlot(mWorld).
                END.
                WHEN "league16" THEN
                DO:
                    mWorld:LeagueMatch = 16.
                    Opposition:LeagueSlot(mWorld).
                END.
                WHEN "cup0" THEN Opposition:CupSlot(mWorld, NEW ScriptedRandom("0")).
                WHEN "cup9" THEN
                DO:
                    mWorld:CupRound = 9.
                    Opposition:CupSlot(mWorld, NEW ScriptedRandom("0")).
                END.
                WHEN "cuprandom" THEN
                DO:
                    mWorld:CupRound = 1.
                    Opposition:CupSlot(mWorld, ?).
                END.
                WHEN "numberleague0" THEN
                DO:
                    mWorld:LeagueMatch = 0.
                    Opposition:Number(mWorld, NEW ScriptedRandom("0"), FixtureKind:League, 49).
                END.
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLeagueOpponentIsTheClubInTheSlotOfTheMatchNumber():
        mWorld:LeagueMatch = 1.
        Assert:Equals(49, Opposition:LeagueSlot(mWorld)).
        mWorld:LeagueMatch = 15.
        Assert:Equals(63, Opposition:LeagueSlot(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSixteenthClubStandsInForTheManagersOwnSlot():
        mWorld:Slot = 50.
        mWorld:LeagueMatch = 1.
        Assert:Equals(49, Opposition:LeagueSlot(mWorld)).
        mWorld:LeagueMatch = 2.
        Assert:Equals(64, Opposition:LeagueSlot(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCupOpponentComesFromTheBandOfEightForTheRound():
        mWorld:CupRound = 1.
        Assert:Equals(57, Opposition:CupSlot(mWorld, NEW ScriptedRandom("0"))).
        mWorld:Slot = 3.
        Assert:Equals(64, Opposition:CupSlot(mWorld, NEW ScriptedRandom("7"))).
        mWorld:CupRound = 4.
        Assert:Equals(33, Opposition:CupSlot(mWorld, NEW ScriptedRandom("0"))).
        mWorld:CupRound = 7.
        Assert:Equals(12, Opposition:CupSlot(mWorld, NEW ScriptedRandom("3"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFinalIsAgainstOneOfTheTopEightAndNeverTheManagersOwnClub():
        mWorld:CupRound = 8.
        mWorld:Slot = 3.
        Assert:Equals(1, Opposition:CupSlot(mWorld, NEW ScriptedRandom("0"))).
        Assert:Equals(2, Opposition:CupSlot(mWorld, NEW ScriptedRandom("1"))).
        /* the choice of seven skips over slot 3 */
        Assert:Equals(4, Opposition:CupSlot(mWorld, NEW ScriptedRandom("2"))).
        Assert:Equals(8, Opposition:CupSlot(mWorld, NEW ScriptedRandom("6"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACupOpponentIsNeverTheManagersOwnClubInRoundOne():
        VAR INTEGER i.
        mWorld:CupRound = 1.
        DO i = 0 TO 6:
            Assert:IsTrue(Opposition:CupSlot(mWorld, NEW ScriptedRandom(STRING(i))) <> 64).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALeagueNumberIsADrawPlusTheLevelPlusTheClubsPointsAMatch():
        mWorld:LeagueMatch = 2.
        mWorld:AddResult(1, 4, 0, 0).
        /* level 3, points a match 2, and a scripted 0 is a one on the 14 sided draw */
        Assert:Equals(6, Opposition:Number(mWorld, NEW ScriptedRandom("0"), FixtureKind:League, 49)).
        Assert:Equals(19, Opposition:Number(mWorld, NEW ScriptedRandom("13"), FixtureKind:League, 49)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALeagueNumberIsKeptBetweenOneAndTwenty():
        mWorld:LeagueMatch = 2.
        mWorld:Level = 7.
        mWorld:AddResult(1, 4, 0, 0).
        Assert:Equals(20, Opposition:Number(mWorld, NEW ScriptedRandom("13"), FixtureKind:League, 49)).
        mWorld:Level = 1.
        Assert:Equals(4, Opposition:Number(mWorld, NEW ScriptedRandom("0"), FixtureKind:League, 49)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACupNumberLeansOnTheDivisionsOfTheTwoClubs():
        mWorld:CupRound = 1.
        /* level 3, a draw of 1, the manager's club (slot 64) 63/16 up and the other (slot 60) 59/16 + 1 up: 1 + 3 + 3.9375 - 4.6875 */
        Assert:Equals(3, Opposition:Number(mWorld, NEW ScriptedRandom("0"), FixtureKind:Cup, 60)).
        Assert:Equals(18, Opposition:Number(mWorld, NEW ScriptedRandom("15"), FixtureKind:Cup, 60)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACupNumberAgainstAClubInTheFirstDivisionIsHigherThanOneInTheFourth():
        mWorld:CupRound = 1.
        /* level 3: 1 + 3 + 3.9375 - 1.25 */
        Assert:Equals(6, Opposition:Number(mWorld, NEW ScriptedRandom("0"), FixtureKind:Cup, 5)).
        Assert:Equals(3, Opposition:Number(mWorld, NEW ScriptedRandom("0"), FixtureKind:Cup, 60)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACupNumberNeverFallsBelowOne():
        mWorld:Slot = 1.
        mWorld:Level = 1.
        Assert:Equals(1, Opposition:Number(mWorld, NEW ScriptedRandom("0"), FixtureKind:Cup, 64)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatAreNotAllowedAreRefused():
        Assert:IsTrue(Refused("league0")).
        Assert:IsTrue(Refused("league16")).
        Assert:IsTrue(Refused("cup0")).
        Assert:IsTrue(Refused("cup9")).
        Assert:IsTrue(Refused("cuprandom")).
        Assert:IsTrue(Refused("numberleague0")).
    END METHOD.

END CLASS.
