/* The transfer market: the player on offer, bids (accepted, refused, no money, a full squad), and selling or turning down an offer. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.MarketTests:

    VAR PRIVATE FootballWorld mWorld.

    /* A fourth division club with players 1 to 12 (skill 1, value 5000), 20000 in cash. Player 13 is on the market. */
    @Setup.
    METHOD PUBLIC VOID BuildWorld():
        mWorld = NEW FootballWorld().
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
        mWorld:Cash = 20000.
    END METHOD.

    METHOD PRIVATE VOID FillSquad():
        VAR INTEGER i.
        DO i = 13 TO 16:
            mWorld:SetRole(i, SquadRole:Reserve).
        END.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "bidowned" THEN Market:Bid(mWorld, 1, 100, NEW ScriptedRandom("0")).
                WHEN "bidnegative" THEN Market:Bid(mWorld, 13, -1, NEW ScriptedRandom("0")).
                WHEN "bidrandom" THEN Market:Bid(mWorld, 13, 100, ?).
                WHEN "offerrandom" THEN Market:Offer(mWorld, ?).
                WHEN "saleoutsider" THEN Market:SaleOffer(mWorld, 13, NEW ScriptedRandom("0")).
                WHEN "saleinjured" THEN
                DO:
                    mWorld:SetRole(1, SquadRole:Injured).
                    Market:SaleOffer(mWorld, 1, NEW ScriptedRandom("0")).
                END.
                WHEN "sellinjured" THEN
                DO:
                    mWorld:SetRole(1, SquadRole:Injured).
                    Market:Sell(mWorld, 1, 100).
                END.
                WHEN "sellnegative" THEN Market:Sell(mWorld, 1, -5).
                WHEN "turndownoutsider" THEN Market:TurnDown(mWorld, 13, NEW ScriptedRandom("0")).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOfferIsOneOfThePlayersTheClubDoesNotOwn():
        /* twelve are not owned: 13 to 24 */
        Assert:Equals(13, Market:Offer(mWorld, NEW ScriptedRandom("0"))).
        Assert:Equals(24, Market:Offer(mWorld, NEW ScriptedRandom("11"))).
        Assert:Equals(18, Market:Offer(mWorld, NEW ScriptedRandom("5"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSquadHoldsAtMostSixteen():
        Assert:IsTrue(Market:CanSign(mWorld)).
        mWorld:SetRole(13, SquadRole:Reserve).
        mWorld:SetRole(14, SquadRole:Reserve).
        mWorld:SetRole(15, SquadRole:Reserve).
        Assert:IsTrue(Market:CanSign(mWorld)).
        mWorld:SetRole(16, SquadRole:Reserve).
        Assert:IsFalse(Market:CanSign(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABidOfTheValueIsAcceptedWhenTheRollIsFiveOrMore():
        /* ten times a scripted 4 is a roll of 5: 5 * 5000 >= 5 * 5000 */
        Assert:Equals(INTEGER(BidResult:Accepted), INTEGER(Market:Bid(mWorld, 13, 5000, NEW ScriptedRandom("4")))).
        Assert:Equals(15000, mWorld:Cash).
        Assert:Equals(INTEGER(SquadRole:Reserve), INTEGER(mWorld:RoleOf(13))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABidOfTheValueIsRefusedWhenTheRollIsFourOrLessAndThePriceGoesUpAFifth():
        Assert:Equals(INTEGER(BidResult:Refused), INTEGER(Market:Bid(mWorld, 13, 5000, NEW ScriptedRandom("3")))).
        Assert:Equals(20000, mWorld:Cash).
        Assert:Equals(INTEGER(SquadRole:NotOwned), INTEGER(mWorld:RoleOf(13))).
        Assert:Equals(6000, mWorld:WorthOf(13)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnAcceptedPlayerIsWorthWhatHisSkillIsWorthAgain():
        mWorld:SetWorth(13, 9999).
        mWorld:SetSkill(13, 3).
        Market:Bid(mWorld, 13, 20000, NEW ScriptedRandom("9")).
        Assert:Equals(15000, mWorld:WorthOf(13)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABidOfFiveTimesTheValueIsAlwaysAcceptedAndOneUnderHalfNever():
        mWorld:Cash = 30000.
        Assert:Equals(INTEGER(BidResult:Accepted), INTEGER(Market:Bid(mWorld, 13, 25000, NEW ScriptedRandom("0")))).
        mWorld:Cash = 20000.
        Assert:Equals(INTEGER(BidResult:Refused), INTEGER(Market:Bid(mWorld, 14, 2499, NEW ScriptedRandom("9")))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABidAboveTheCashIsNoMoneyAndChangesNothing():
        Assert:Equals(INTEGER(BidResult:NoMoney), INTEGER(Market:Bid(mWorld, 13, 20001, NEW ScriptedRandom("9")))).
        Assert:Equals(20000, mWorld:Cash).
        Assert:Equals(5000, mWorld:WorthOf(13)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABidWithAFullSquadIsSquadFull():
        FillSquad().
        mWorld:SetRole(17, SquadRole:NotOwned).
        Assert:Equals(INTEGER(BidResult:SquadFull), INTEGER(Market:Bid(mWorld, 17, 5000, NEW ScriptedRandom("9")))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayerWhoCanBeSoldIsInTheSquadAndNotInjured():
        Assert:IsTrue(Market:CanSell(mWorld, 1)).
        Assert:IsTrue(Market:CanSell(mWorld, 12)).
        Assert:IsFalse(Market:CanSell(mWorld, 13)).
        mWorld:SetRole(1, SquadRole:Injured).
        Assert:IsFalse(Market:CanSell(mWorld, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaleOfferRunsFromEightTenthsToJustUnderThirteenTenthsOfTheValue():
        /* value 5000 */
        Assert:Equals(4000, Market:SaleOffer(mWorld, 1, NEW ScriptedRandom("0"))).
        Assert:Equals(5000, Market:SaleOffer(mWorld, 1, NEW ScriptedRandom("2000"))).
        Assert:Equals(6499, Market:SaleOffer(mWorld, 1, NEW ScriptedRandom("4999"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBuyerIsAClubOfTheSixtyFour():
        Assert:Equals(1, Market:BuyerSlot(NEW ScriptedRandom("0"))).
        Assert:Equals(64, Market:BuyerSlot(NEW ScriptedRandom("63"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SellingBringsInTheOfferAndTheLeavesTheSquad():
        Market:Sell(mWorld, 5, 4500).
        Assert:Equals(24500, mWorld:Cash).
        Assert:Equals(INTEGER(SquadRole:NotOwned), INTEGER(mWorld:RoleOf(5))).
        Assert:Equals(11, mWorld:OwnedCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TurningAnOfferDownIsHarmlessOneTimeInThreeAndOtherwiseInjuresThePlayer():
        Assert:IsFalse(Market:TurnDown(mWorld, 1, NEW ScriptedRandom("0"))).
        Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mWorld:RoleOf(1))).
        Assert:IsTrue(Market:TurnDown(mWorld, 1, NEW ScriptedRandom("1"))).
        Assert:Equals(INTEGER(SquadRole:Injured), INTEGER(mWorld:RoleOf(1))).
        Assert:IsTrue(Market:TurnDown(mWorld, 2, NEW ScriptedRandom("2"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatAreNotAllowedAreRefused():
        Assert:IsTrue(Refused("bidowned")).
        Assert:IsTrue(Refused("bidnegative")).
        Assert:IsTrue(Refused("bidrandom")).
        Assert:IsTrue(Refused("offerrandom")).
        Assert:IsTrue(Refused("saleoutsider")).
        Assert:IsTrue(Refused("saleinjured")).
        Assert:IsTrue(Refused("sellinjured")).
        Assert:IsTrue(Refused("sellnegative")).
        Assert:IsTrue(Refused("turndownoutsider")).
    END METHOD.

END CLASS.
