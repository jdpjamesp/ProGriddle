/* Teams, the order of play, the setup and the names of Blast Buddies. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.TurnPlanTests:

    METHOD PRIVATE Team MakeTeam(INPUT piNumber AS INTEGER, INPUT piBuddies AS INTEGER):
        DEFINE VARIABLE t AS Team NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        t = NEW Team(piNumber, FALSE).
        DO i = 1 TO piBuddies:
            t:Add(NEW Buddy("B" + STRING(piNumber) + STRING(i), piNumber, i * 10, 100)).
        END.
        RETURN t.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATeamHoldsItsBuddiesAndCountsTheLivingAndTheirHealth():
        DEFINE VARIABLE t AS Team NO-UNDO.
        t = MakeTeam(2, 3).
        Assert:Equals(2, t:Number).
        Assert:IsFalse(t:IsComputer).
        Assert:Equals(3, t:Count()).
        Assert:Equals("B22", t:BuddyAt(2):BuddyName).
        Assert:Equals(3, t:AliveCount()).
        Assert:Equals(300, t:TotalHealth()).
        t:BuddyAt(1):Hurt(100).
        t:BuddyAt(2):Hurt(40).
        Assert:Equals(2, t:AliveCount()).
        Assert:Equals(160, t:TotalHealth()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATeamRefusesAWrongBuddyAFifthBuddyAndABadNumber():
        DEFINE VARIABLE t       AS Team    NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        t = MakeTeam(1, 4).
        DO ON ERROR UNDO, LEAVE:
            t:Add(NEW Buddy("FIVE", 1, 1, 1)).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        t = NEW Team(1, TRUE).
        Assert:IsTrue(t:IsComputer).
        DO ON ERROR UNDO, LEAVE:
            t:Add(NEW Buddy("OTHER", 2, 1, 1)).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            t = NEW Team(5, FALSE).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            t:BuddyAt(1).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATeamPlaysItsBuddiesInRotaAndSkipsTheDead():
        DEFINE VARIABLE t AS Team NO-UNDO.
        t = MakeTeam(1, 3).
        Assert:Equals("B11", t:NextBuddy():BuddyName).
        Assert:Equals("B12", t:NextBuddy():BuddyName).
        t:BuddyAt(3):Hurt(100).
        Assert:Equals("B11", t:NextBuddy():BuddyName).
        t:BuddyAt(1):Hurt(100).
        Assert:Equals("B12", t:NextBuddy():BuddyName).
        Assert:Equals("B12", t:NextBuddy():BuddyName).
        t:BuddyAt(2):Hurt(100).
        Assert:IsTrue(t:NextBuddy() = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTeamsTakeTurnsInOrderAndEachRotatesItsOwnBuddies():
        DEFINE VARIABLE p AS TurnPlan NO-UNDO.
        p = NEW TurnPlan().
        p:Add(MakeTeam(1, 3)).
        p:Add(MakeTeam(2, 3)).
        Assert:Equals(2, p:TeamCount()).
        Assert:Equals(2, p:TeamAt(2):Number).
        Assert:Equals("B11", p:NextBuddy():BuddyName).
        Assert:Equals("B21", p:NextBuddy():BuddyName).
        Assert:Equals("B12", p:NextBuddy():BuddyName).
        Assert:Equals("B22", p:NextBuddy():BuddyName).
        Assert:Equals("B13", p:NextBuddy():BuddyName).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeadTeamIsSkippedAndTeamsAliveCountsTheRest():
        DEFINE VARIABLE p AS TurnPlan NO-UNDO.
        DEFINE VARIABLE i AS INTEGER  NO-UNDO.
        p = NEW TurnPlan().
        p:Add(MakeTeam(1, 3)).
        p:Add(MakeTeam(2, 3)).
        p:Add(MakeTeam(3, 3)).
        Assert:Equals(3, p:TeamsAlive()).
        DO i = 1 TO 3:
            p:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        Assert:Equals(2, p:TeamsAlive()).
        Assert:Equals(1, p:NextBuddy():Team).
        Assert:Equals(3, p:NextBuddy():Team).
        Assert:Equals(1, p:NextBuddy():Team).
        DO i = 1 TO 3:
            p:TeamAt(1):BuddyAt(i):Hurt(100).
            p:TeamAt(3):BuddyAt(i):Hurt(100).
        END.
        Assert:Equals(0, p:TeamsAlive()).
        Assert:IsTrue(p:NextBuddy() = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlanRefusesAFifthTeamAndAnUnknownTeam():
        DEFINE VARIABLE p       AS TurnPlan NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL  NO-UNDO.
        p = NEW TurnPlan().
        p:Add(MakeTeam(1, 3)).
        p:Add(MakeTeam(2, 3)).
        p:Add(MakeTeam(3, 3)).
        p:Add(MakeTeam(4, 3)).
        DO ON ERROR UNDO, LEAVE:
            p:Add(MakeTeam(1, 3)).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            p:TeamAt(5).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASetupChecksItsNumbersAndHasADefault():
        DEFINE VARIABLE s       AS BuddySetup NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL    NO-UNDO.
        s = NEW BuddySetup(3, 4, 2, Theme:Candy).
        Assert:Equals(3, s:Teams).
        Assert:Equals(4, s:BuddiesEach).
        Assert:Equals(2, s:ComputerTeams).
        Assert:IsTrue(s:LandTheme = Theme:Candy).
        s = BuddySetup:Default().
        Assert:Equals(2, s:Teams).
        Assert:Equals(3, s:BuddiesEach).
        Assert:Equals(1, s:ComputerTeams).
        DO ON ERROR UNDO, LEAVE:
            s = NEW BuddySetup(1, 3, 0, Theme:Meadow).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            s = NEW BuddySetup(2, 5, 0, Theme:Meadow).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            s = NEW BuddySetup(2, 3, 2, Theme:Meadow).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            s = NEW BuddySetup(2, 3, 0, ?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheNamesAreShortCapitalsTheFontCanDrawAndAllDifferent():
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE j       AS INTEGER NO-UNDO.
        DEFINE VARIABLE k       AS INTEGER NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        Assert:IsTrue(BuddyNames:Count() >= 16).
        DO i = 1 TO BuddyNames:Count():
            Assert:IsTrue(LENGTH(BuddyNames:NameAt(i)) >= 2 AND LENGTH(BuddyNames:NameAt(i)) <= 8, BuddyNames:NameAt(i)).
            DO k = 1 TO LENGTH(BuddyNames:NameAt(i)):
                Assert:IsTrue(ASC(SUBSTRING(BuddyNames:NameAt(i), k, 1)) >= 65 AND ASC(SUBSTRING(BuddyNames:NameAt(i), k, 1)) <= 90, BuddyNames:NameAt(i)).
            END.
            DO j = i + 1 TO BuddyNames:Count():
                Assert:IsTrue(BuddyNames:NameAt(i) <> BuddyNames:NameAt(j)).
            END.
        END.
        DO ON ERROR UNDO, LEAVE:
            BuddyNames:NameAt(0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

END CLASS.
