/* The week of Football Manager from screen to screen: set up, the menu, selling, picking the team, the match, the results, the table, the accounts, the season's end, the transfer offer, the replay of a drawn cup tie and the sack. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballGameTests:

    VAR PRIVATE FootballGame mGame.

    METHOD PRIVATE FootballGame NewGameWith(INPUT piSeed AS INTEGER):
        RETURN NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(piSeed)).
    END METHOD.

    /* A game at the Menu for a fourth division club with plenty of cash (so that nothing gets in the way). */
    METHOD PRIVATE VOID StartedGame(INPUT piSeed AS INTEGER):
        mGame = NewGameWith(piSeed).
        mGame:StartNewGame("Bob", 1, 3, 0).
        mGame:World:Cash = 10000000.
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* From the Menu through one whole week (every screen of it, picking the team as dealt, passing on the transfer) back to the Menu, or to Sacked. */
    METHOD PRIVATE VOID PlayWeek():
        VAR INTEGER guard.
        mGame:Continue().
        DO WHILE mGame:Phase <> FootballPhase:Menu AND mGame:Phase <> FootballPhase:Sacked AND guard < 60:
            guard = guard + 1.
            CASE mGame:Phase:
                WHEN FootballPhase:PickTeam THEN mGame:KickOff().
                WHEN FootballPhase:Transfer THEN mGame:Pass().
                OTHERWISE mGame:Proceed().
            END CASE.
        END.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            StartedGame(1).
            CASE pcWhat:
                WHEN "twice" THEN mGame:StartNewGame("Ann", 2, 1, 7).
                WHEN "proceed" THEN mGame:Proceed().
                WHEN "kickoff" THEN mGame:KickOff().
                WHEN "pick" THEN mGame:PickPlayer(12).
                WHEN "drop" THEN mGame:DropPlayer(1).
                WHEN "accept" THEN mGame:AcceptSale().
                WHEN "turndown" THEN mGame:TurnDownSale().
                WHEN "bid" THEN mGame:Bid(100).
                WHEN "pass" THEN mGame:Pass().
                WHEN "level0" THEN mGame:SetLevel(0).
                WHEN "level8" THEN mGame:SetLevel(8).
                WHEN "sellinjured" THEN
                DO:
                    mGame:World:SetRole(1, SquadRole:Injured).
                    mGame:OfferSale(1).
                END.
                WHEN "borrowinmatch" THEN
                DO:
                    mGame:Continue().
                    mGame:Borrow(10).
                END.
                WHEN "continuetwice" THEN
                DO:
                    mGame:Continue().
                    mGame:Continue().
                END.
                WHEN "ticknegative" THEN mGame:Tick(-1).
                WHEN "skipnotinmatch" THEN mGame:SkipHighlights().
                WHEN "overnotinmatch" THEN mGame:HighlightsOver().
                WHEN "norandom" THEN NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), ?).
                WHEN "setupborrow" THEN
                DO:
                    mGame = NewGameWith(1).
                    mGame:Borrow(10).
                END.
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameIsNamedAndWaitsAtSetup():
        mGame = NewGameWith(1).
        Assert:Equals("Football Manager", mGame:Name).
        Assert:Equals(INTEGER(FootballPhase:Setup), INTEGER(mGame:Phase)).
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingAGameTakesTheClubAndGoesToTheMenu():
        StartedGame(1).
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(mGame:Phase)).
        Assert:Equals("Bob", mGame:World:ManagerName).
        Assert:Equals("Arsenal", mGame:World:ClubName(64)).
        Assert:Equals(3, mGame:World:Level).
        Assert:Equals(12, mGame:World:OwnedCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMenuLendsRepaysAndChangesTheLevel():
        StartedGame(1).
        mGame:World:Cash = 0.
        Assert:IsTrue(mGame:Borrow(100000)).
        Assert:IsFalse(mGame:Borrow(200000)).
        Assert:Equals(100000, mGame:World:Loan).
        Assert:IsTrue(mGame:Repay(40000)).
        Assert:IsFalse(mGame:Repay(70000)).
        Assert:Equals(60000, mGame:World:Loan).
        mGame:SetLevel(6).
        Assert:Equals(6, mGame:World:Level).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnOfferForAPlayerCanBeAcceptedAndTheMoneyAndTheSquadChange():
        VAR INTEGER before.
        StartedGame(1).
        before = mGame:World:Cash.
        mGame:OfferSale(3).
        Assert:Equals(INTEGER(FootballPhase:Selling), INTEGER(mGame:Phase)).
        Assert:Equals(3, mGame:OfferedPlayer).
        Assert:IsTrue(mGame:SaleAmount > 0).
        Assert:IsTrue(mGame:SaleBuyer >= 1 AND mGame:SaleBuyer <= 64).
        mGame:AcceptSale().
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(mGame:Phase)).
        Assert:Equals(11, mGame:World:OwnedCount()).
        Assert:IsTrue(mGame:World:Cash > before).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnOfferThatIsTurnedDownLeavesThePlayerInTheSquadOrInjured():
        VAR LOGICAL injured.
        StartedGame(1).
        mGame:OfferSale(3).
        injured = mGame:TurnDownSale().
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(mGame:Phase)).
        Assert:Equals(12, mGame:World:OwnedCount()).
        IF injured THEN Assert:Equals(INTEGER(SquadRole:Injured), INTEGER(mGame:World:RoleOf(3))).
        ELSE Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mGame:World:RoleOf(3))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ContinuingDrawsTheFirstLeagueMatchAndGoesToPickTheTeam():
        StartedGame(1).
        mGame:Continue().
        Assert:Equals(INTEGER(FootballPhase:PickTeam), INTEGER(mGame:Phase)).
        Assert:Equals(1, mGame:Turn).
        Assert:Equals(INTEGER(FixtureKind:League), INTEGER(mGame:ThisFixture:Kind)).
        Assert:Equals(49, mGame:ThisFixture:OpponentSlot).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTeamCanBeChangedBeforeKickOff():
        VAR INTEGER p.
        StartedGame(1).
        mGame:Continue().
        /* the squad is dealt at random, so find a player who is picked */
        DO p = 1 TO 24:
            IF mGame:World:RoleOf(p) = SquadRole:Starter THEN LEAVE.
        END.
        mGame:DropPlayer(p).
        Assert:Equals(10, mGame:World:StarterCount()).
        mGame:PickPlayer(p).
        Assert:Equals(11, mGame:World:StarterCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID KickOffPlaysTheMatchAndPaysTheGate():
        VAR INTEGER before.
        StartedGame(1).
        mGame:Continue().
        before = mGame:World:Cash.
        mGame:KickOff().
        Assert:Equals(INTEGER(FootballPhase:Match), INTEGER(mGame:Phase)).
        Assert:Equals(before + mGame:ThisFixture:Gate, mGame:World:Cash).
        Assert:IsTrue(mGame:Played:AttackCount >= 2).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHighlightsRunOnATickAndStopAtTheEndOrWhenSkipped():
        VAR INTEGER total.
        StartedGame(1).
        mGame:Continue().
        mGame:KickOff().
        total = Highlights:TotalMs(mGame:Played).
        Assert:Equals(0, mGame:MatchMs).
        Assert:IsFalse(mGame:HighlightsOver()).
        Assert:IsTrue(mGame:Tick(500)).
        Assert:Equals(500, mGame:MatchMs).
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:Tick(500)).
        Assert:Equals(500, mGame:MatchMs).
        mGame:Paused = FALSE.
        mGame:Tick(total * 2).
        Assert:Equals(total, mGame:MatchMs).
        Assert:IsTrue(mGame:HighlightsOver()).
        Assert:IsFalse(mGame:Tick(100)).
        mGame:Proceed().
        Assert:IsFalse(mGame:Tick(100)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameAlwaysAsksForTheClockSoASackedGameCanStartAgainWithHighlights():
        StartedGame(1).
        Assert:IsTrue(mGame:Animating).
        mGame:World:Cash = 0.
        mGame:World:Loan = 1000000.
        PlayWeek().
        Assert:IsTrue(mGame:IsOver).
        Assert:IsTrue(mGame:Animating).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SkippingJumpsToTheEndOfTheHighlights():
        StartedGame(1).
        mGame:Continue().
        mGame:KickOff().
        mGame:SkipHighlights().
        Assert:IsTrue(mGame:HighlightsOver()).
        Assert:Equals(Highlights:TotalMs(mGame:Played), mGame:MatchMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALeagueMatchGoesThroughTheScoreTheResultsTheTableAndTheAccounts():
        StartedGame(1).
        mGame:Continue().
        mGame:KickOff().
        mGame:Proceed().
        Assert:Equals(INTEGER(FootballPhase:FullTime), INTEGER(mGame:Phase)).
        mGame:Proceed().
        Assert:Equals(INTEGER(FootballPhase:Results), INTEGER(mGame:Phase)).
        Assert:Equals(7, mGame:OtherResults:Count).
        mGame:Proceed().
        Assert:Equals(INTEGER(FootballPhase:Table), INTEGER(mGame:Phase)).
        mGame:Proceed().
        Assert:Equals(INTEGER(FootballPhase:Accounts), INTEGER(mGame:Phase)).
        /* 12 players of skill 1 to 5 at 100 each, and the ground rent */
        Assert:IsTrue(mGame:WageBill >= 1200 AND mGame:WageBill <= 6000).
        Assert:Equals(500, mGame:RentBill).
        Assert:Equals(0, mGame:InterestBill).
        mGame:Proceed().
        Assert:Equals(INTEGER(FootballPhase:Transfer), INTEGER(mGame:Phase)).
        Assert:IsFalse(mGame:World:RoleOf(mGame:OfferedPlayer) <> SquadRole:NotOwned).
        mGame:Pass().
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACupTieSkipsTheResultsAndTheTable():
        VAR INTEGER guard.
        StartedGame(1).
        PlayWeek().
        mGame:Continue().
        Assert:Equals(INTEGER(FixtureKind:Cup), INTEGER(mGame:ThisFixture:Kind)).
        mGame:KickOff().
        mGame:Proceed().
        /* a drawn tie is replayed, anything else goes straight to the accounts */
        IF mGame:Phase = FootballPhase:FullTime THEN
        DO:
            mGame:Proceed().
            Assert:IsTrue(mGame:Phase = FootballPhase:Accounts OR mGame:Phase = FootballPhase:PickTeam).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADrawnCupTieIsReplayedWithTheSidesChangedOver():
        VAR INTEGER seed.
        VAR INTEGER side.
        VAR LOGICAL found.
        DO seed = 1 TO 120:
            StartedGame(seed).
            PlayWeek().
            mGame:Continue().
            mGame:KickOff().
            mGame:Proceed().
            IF MatchDay:NeedsReplay(mGame:ThisFixture, mGame:Played) THEN
            DO:
                found = TRUE.
                side = mGame:ThisFixture:ManagerSide.
                mGame:Proceed().
                Assert:Equals(INTEGER(FootballPhase:PickTeam), INTEGER(mGame:Phase)).
                Assert:Equals(3 - side, mGame:ThisFixture:ManagerSide).
                mGame:KickOff().
                Assert:Equals(INTEGER(FootballPhase:Match), INTEGER(mGame:Phase)).
                LEAVE.
            END.
        END.
        Assert:IsTrue(found).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWholeSeasonEndsWithAPrizeAFreshTableAndTheMenu():
        VAR INTEGER guard.
        StartedGame(3).
        DO WHILE mGame:World:Seasons = 0 AND guard < 40:
            guard = guard + 1.
            PlayWeek().
        END.
        Assert:Equals(1, mGame:World:Seasons).
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(mGame:Phase)).
        Assert:Equals(0, mGame:World:LeagueMatch).
        Assert:IsTrue(mGame:Turn >= 15).
        Assert:IsTrue(mGame:FinalPlace >= 1 AND mGame:FinalPlace <= 16).
        Assert:Equals((17 - mGame:FinalPlace) * 5000, mGame:SeasonPrize).
        /* the fourth division has no relegation, and promotion is the top three */
        IF mGame:FinalPlace <= 3 THEN Assert:Equals(INTEGER(SeasonMove:Promoted), INTEGER(mGame:SeasonResult)).
        ELSE Assert:Equals(INTEGER(SeasonMove:Stayed), INTEGER(mGame:SeasonResult)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnOfferingOfThePlayerOnOfferCanBeBidForAndRefusedWithTheNumberKept():
        StartedGame(1).
        mGame:Continue().
        mGame:KickOff().
        mGame:Proceed().
        mGame:Proceed().
        mGame:Proceed().
        mGame:Proceed().
        mGame:Proceed().
        Assert:Equals(INTEGER(FootballPhase:Transfer), INTEGER(mGame:Phase)).
        Assert:IsFalse(mGame:TransferBlocked).
        /* a bid of nothing is always refused and the offer stays open */
        Assert:Equals(INTEGER(BidResult:Refused), INTEGER(mGame:Bid(0))).
        Assert:Equals(INTEGER(FootballPhase:Transfer), INTEGER(mGame:Phase)).
        Assert:Equals(INTEGER(BidResult:NoMoney), INTEGER(mGame:Bid(99999999))).
        Assert:Equals(INTEGER(FootballPhase:Transfer), INTEGER(mGame:Phase)).
        /* five times his value is always accepted */
        Assert:Equals(INTEGER(BidResult:Accepted), INTEGER(mGame:Bid(5 * mGame:World:WorthOf(mGame:OfferedPlayer)))).
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(mGame:Phase)).
        Assert:Equals(13, mGame:World:OwnedCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFullSquadCannotBuyAndTheBidReturnsToTheMenu():
        VAR INTEGER i.
        StartedGame(1).
        DO i = 1 TO 24:
            IF mGame:World:OwnedCount() < 16 AND mGame:World:RoleOf(i) = SquadRole:NotOwned THEN mGame:World:SetRole(i, SquadRole:Reserve).
        END.
        mGame:Continue().
        mGame:KickOff().
        DO i = 1 TO 5:
            mGame:Proceed().
        END.
        Assert:IsTrue(mGame:TransferBlocked).
        Assert:Equals(INTEGER(BidResult:SquadFull), INTEGER(mGame:Bid(1000))).
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALoanOverTheLimitAfterTheBillsIsTheSack():
        StartedGame(1).
        mGame:World:Cash = 0.
        mGame:World:Loan = 1000000.
        mGame:Continue().
        mGame:KickOff().
        mGame:Proceed().
        mGame:Proceed().
        mGame:Proceed().
        mGame:Proceed().
        Assert:Equals(INTEGER(FootballPhase:Accounts), INTEGER(mGame:Phase)).
        mGame:Proceed().
        Assert:Equals(INTEGER(FootballPhase:Sacked), INTEGER(mGame:Phase)).
        Assert:IsTrue(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseGoesBackToTheSetupWithANewWorld():
        StartedGame(1).
        PlayWeek().
        mGame:Initialise().
        Assert:Equals(INTEGER(FootballPhase:Setup), INTEGER(mGame:Phase)).
        Assert:Equals(0, mGame:World:OwnedCount()).
        Assert:IsFalse(mGame:IsOver).
        mGame:StartNewGame("Ann", 5, 2, 7).
        Assert:Equals("Ann", mGame:World:ManagerName).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsOutOfTurnAreRefused():
        Assert:IsTrue(Refused("twice")).
        Assert:IsTrue(Refused("proceed")).
        Assert:IsTrue(Refused("kickoff")).
        Assert:IsTrue(Refused("pick")).
        Assert:IsTrue(Refused("drop")).
        Assert:IsTrue(Refused("accept")).
        Assert:IsTrue(Refused("turndown")).
        Assert:IsTrue(Refused("bid")).
        Assert:IsTrue(Refused("pass")).
        Assert:IsTrue(Refused("level0")).
        Assert:IsTrue(Refused("level8")).
        Assert:IsTrue(Refused("sellinjured")).
        Assert:IsTrue(Refused("borrowinmatch")).
        Assert:IsTrue(Refused("continuetwice")).
        Assert:IsTrue(Refused("ticknegative")).
        Assert:IsTrue(Refused("skipnotinmatch")).
        Assert:IsTrue(Refused("overnotinmatch")).
        Assert:IsTrue(Refused("norandom")).
        Assert:IsTrue(Refused("setupborrow")).
    END METHOD.

END CLASS.
