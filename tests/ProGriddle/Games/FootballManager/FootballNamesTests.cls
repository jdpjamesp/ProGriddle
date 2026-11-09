/* The club, player and level names of FootballManager: every slot has a name, the divisions run in order, the positions of the pool and the refusals. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballNamesTests:

    METHOD PRIVATE LOGICAL Refuses(INPUT piNumber AS INTEGER, INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "club" THEN FootballNames:Club(piNumber).
                WHEN "player" THEN FootballNames:Player(piNumber).
                WHEN "position" THEN FootballNames:PositionOf(piNumber).
                OTHERWISE FootballNames:Level(piNumber).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstAndLastClubOfEachDivisionAreTheOriginalsOnes():
        Assert:Equals("Arsenal", FootballNames:Club(1)).
        Assert:Equals("West Ham", FootballNames:Club(16)).
        Assert:Equals("Blackburn", FootballNames:Club(17)).
        Assert:Equals("Sheff.Wed", FootballNames:Club(32)).
        Assert:Equals("Bradford", FootballNames:Club(33)).
        Assert:Equals("Walsall", FootballNames:Club(48)).
        Assert:Equals("Blackpool", FootballNames:Club(49)).
        Assert:Equals("York City", FootballNames:Club(64)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EverySlotHasANameOfAtMostTenCharacters():
        VAR INTEGER i.
        DO i = 1 TO 64:
            Assert:IsTrue(LENGTH(FootballNames:Club(i)) >= 3 AND LENGTH(FootballNames:Club(i)) <= 10).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayerIsNamedByItsNumberInTheThreeBlocksOfEight():
        Assert:Equals("P.Parkes", FootballNames:Player(1)).
        Assert:Equals("S.Foster", FootballNames:Player(8)).
        Assert:Equals("B.Robson", FootballNames:Player(9)).
        Assert:Equals("S.Hunt", FootballNames:Player(12)).
        Assert:Equals("S.McCall", FootballNames:Player(16)).
        Assert:Equals("C.Regis", FootballNames:Player(17)).
        Assert:Equals("G.Shaw", FootballNames:Player(24)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlayersOneToEightDefendNineToSixteenPlayMidfieldAndTheRestAttack():
        Assert:Equals(INTEGER(FootballPosition:Defender), INTEGER(FootballNames:PositionOf(1))).
        Assert:Equals(INTEGER(FootballPosition:Defender), INTEGER(FootballNames:PositionOf(8))).
        Assert:Equals(INTEGER(FootballPosition:Midfielder), INTEGER(FootballNames:PositionOf(9))).
        Assert:Equals(INTEGER(FootballPosition:Midfielder), INTEGER(FootballNames:PositionOf(16))).
        Assert:Equals(INTEGER(FootballPosition:Forward), INTEGER(FootballNames:PositionOf(17))).
        Assert:Equals(INTEGER(FootballPosition:Forward), INTEGER(FootballNames:PositionOf(24))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSevenLevelsRunFromBeginnerToGenius():
        Assert:Equals("Beginner", FootballNames:Level(1)).
        Assert:Equals("Average", FootballNames:Level(3)).
        Assert:Equals("Super Expert", FootballNames:Level(6)).
        Assert:Equals("Genius", FootballNames:Level(7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANumberOutOfRangeIsRefused():
        Assert:IsTrue(Refuses(0, "club")).
        Assert:IsTrue(Refuses(65, "club")).
        Assert:IsTrue(Refuses(0, "player")).
        Assert:IsTrue(Refuses(25, "player")).
        Assert:IsTrue(Refuses(0, "position")).
        Assert:IsTrue(Refuses(25, "position")).
        Assert:IsTrue(Refuses(0, "level")).
        Assert:IsTrue(Refuses(8, "level")).
    END METHOD.

END CLASS.
