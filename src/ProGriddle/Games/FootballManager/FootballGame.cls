/* Football Manager as a game the window can play: a turn based game that moves from screen to screen (Phase) as the manager acts, in the order of the original's week:

     Setup      StartNewGame (name, club, level, kit) starts a game and goes to the Menu
     Menu       Borrow, Repay, SetLevel, OfferSale (sell a player), or Continue to the next fixture
     Selling    AcceptSale or TurnDownSale, back to the Menu
     PickTeam   PickPlayer and DropPlayer, then KickOff (the match is played and its highlights are kept)
     Match      Proceed after the highlights (the score)
     FullTime   Proceed: a drawn cup tie goes back to PickTeam for the replay, a league match goes on to Results, a cup tie to Accounts
     Results    Proceed to the Table (the other clubs' scores)
     Table      Proceed to Accounts
     Accounts   Proceed: over the loan limit is Sacked, the end of the season is SeasonEnd, otherwise Transfer
     SeasonEnd  Proceed to the Menu of the new season
     Transfer   Bid or Pass (a player is on offer after each match), then the Menu
     Sacked     the game is over

   The game knows nothing of keys or pictures. All its random numbers come from the source it is given, so a seeded one plays the same game every time. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballGame FINAL INHERITS AbstractGame IMPLEMENTS ITurnBasedGame:

    VAR PRIVATE FootballWorld mWorld.
    VAR PRIVATE IRandom mRandom.

    DEFINE PUBLIC PROPERTY World AS FootballWorld NO-UNDO
        GET():
            RETURN mWorld.
        END GET.

    DEFINE PUBLIC PROPERTY Phase AS FootballPhase NO-UNDO
        GET.
        PRIVATE SET.

    /* The fixture being played or just played. */
    DEFINE PUBLIC PROPERTY ThisFixture AS Fixture NO-UNDO
        GET.
        PRIVATE SET.

    /* The match just played: its score and its attacks, for the highlights. */
    DEFINE PUBLIC PROPERTY Played AS MatchResult NO-UNDO
        GET.
        PRIVATE SET.

    /* The other clubs' scores of the league week just played. */
    DEFINE PUBLIC PROPERTY OtherResults AS WeekResults NO-UNDO
        GET.
        PRIVATE SET.

    /* The week's bills (read them when the phase is Accounts) and the change in cash minus loan since the last report. */
    DEFINE PUBLIC PROPERTY WageBill AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY RentBill AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY InterestBill AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Balance AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* What the season's end did to the manager's club (read it when the phase is SeasonEnd). */
    DEFINE PUBLIC PROPERTY SeasonResult AS SeasonMove NO-UNDO
        GET.
        PRIVATE SET.

    /* The place the manager's club finished in, and the prize it was paid. */
    DEFINE PUBLIC PROPERTY FinalPlace AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY SeasonPrize AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The player on offer in the Transfer phase, or in the Selling phase the player being sold, and the club making the offer (a slot) and the money offered. */
    DEFINE PUBLIC PROPERTY OfferedPlayer AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY SaleAmount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY SaleBuyer AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* True in the Transfer phase when the squad is full, so that there is no bid to make. */
    DEFINE PUBLIC PROPERTY TransferBlocked AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    /* The fixtures played so far. */
    DEFINE PUBLIC PROPERTY Turn AS INTEGER NO-UNDO
        GET():
            RETURN Generation.
        END GET.

    /* The grid is not used (the game has no board of cells) but every game has one. Throws GridException for no random source. */
    CONSTRUCTOR PUBLIC FootballGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        SUPER("Football Manager", poGrid).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("Football Manager needs a random source").
        mRandom = poRandom.
        mWorld = NEW FootballWorld().
        Initialise().
    END CONSTRUCTOR.

    /* Back to the set up screens with a new world. */
    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        mWorld = NEW FootballWorld().
        Phase = FootballPhase:Setup.
        ThisFixture = ?.
        Played = ?.
        OtherResults = ?.
        SeasonResult = SeasonMove:Stayed.
        TransferBlocked = FALSE.
    END METHOD.

    METHOD PRIVATE VOID Need(INPUT poPhase AS FootballPhase):
        IF Phase <> poPhase THEN
            UNDO, THROW NEW GridException("That cannot be done now: the game is at " + STRING(Phase:ToString()) + ", not " + STRING(poPhase:ToString())).
    END METHOD.

    /* Starts a game for a manager with the club in slot piClub (1 to 64), at level piLevel (1 to 7), with a kit of piKit (0 black, 7 white). Goes to the Menu. See FootballWorld:NewGame for what is refused. */
    METHOD PUBLIC VOID StartNewGame(INPUT pcManager AS CHARACTER, INPUT piClub AS INTEGER, INPUT piLevel AS INTEGER, INPUT piKit AS INTEGER):
        Need(FootballPhase:Setup).
        mWorld:NewGame(pcManager, piClub, piLevel, piKit, mRandom).
        Phase = FootballPhase:Menu.
    END METHOD.

    /* Takes a loan, which the bank refuses (false) if it would go over the limit. */
    METHOD PUBLIC LOGICAL Borrow(INPUT piAmount AS INTEGER):
        Need(FootballPhase:Menu).
        RETURN Bank:Borrow(mWorld, piAmount).
    END METHOD.

    /* Pays some of the loan back, refused (false) if it is more than the loan or the cash. */
    METHOD PUBLIC LOGICAL Repay(INPUT piAmount AS INTEGER):
        Need(FootballPhase:Menu).
        RETURN Bank:Repay(mWorld, piAmount).
    END METHOD.

    /* Changes the skill level, 1 to 7. */
    METHOD PUBLIC VOID SetLevel(INPUT piLevel AS INTEGER):
        Need(FootballPhase:Menu).
        IF piLevel = ? OR piLevel < 1 OR piLevel > FootballRules:LevelCount() THEN
            UNDO, THROW NEW GridException("The level runs from 1 to 7, not " + STRING(piLevel)).
        mWorld:Level = piLevel.
    END METHOD.

    /* Another club offers for a player in the squad (not an injured one): the phase becomes Selling and OfferedPlayer, SaleBuyer and SaleAmount say what is on offer. */
    METHOD PUBLIC VOID OfferSale(INPUT piPlayer AS INTEGER):
        Need(FootballPhase:Menu).
        SaleAmount = Market:SaleOffer(mWorld, piPlayer, mRandom).
        SaleBuyer = Market:BuyerSlot(mRandom).
        OfferedPlayer = piPlayer.
        Phase = FootballPhase:Selling.
    END METHOD.

    /* Sells the player for the offer and goes back to the Menu. */
    METHOD PUBLIC VOID AcceptSale():
        Need(FootballPhase:Selling).
        Market:Sell(mWorld, OfferedPlayer, SaleAmount).
        Phase = FootballPhase:Menu.
    END METHOD.

    /* Turns the offer down and goes back to the Menu. Returns true when the player was injured by it. */
    METHOD PUBLIC LOGICAL TurnDownSale():
        VAR LOGICAL injured.
        Need(FootballPhase:Selling).
        injured = Market:TurnDown(mWorld, OfferedPlayer, mRandom).
        Phase = FootballPhase:Menu.
        RETURN injured.
    END METHOD.

    /* Goes on to the next fixture: it is drawn, the squad is updated for it and the team is to be picked. */
    METHOD PUBLIC VOID Continue():
        Need(FootballPhase:Menu).
        ThisFixture = MatchDay:Begin(mWorld, mRandom).
        Generation = Generation + 1.
        Squad:Prepare(mWorld, mRandom).
        Phase = FootballPhase:PickTeam.
    END METHOD.

    /* Picks a player in reserve for the team. */
    METHOD PUBLIC VOID PickPlayer(INPUT piPlayer AS INTEGER):
        Need(FootballPhase:PickTeam).
        Squad:Pick(mWorld, piPlayer).
    END METHOD.

    /* Takes a player out of the team. */
    METHOD PUBLIC VOID DropPlayer(INPUT piPlayer AS INTEGER):
        Need(FootballPhase:PickTeam).
        Squad:Drop(mWorld, piPlayer).
    END METHOD.

    /* The team is picked: the match is played (the gate is paid) and the phase is Match. */
    METHOD PUBLIC VOID KickOff():
        Need(FootballPhase:PickTeam).
        Played = MatchDay:Play(mWorld, ThisFixture, mRandom).
        Phase = FootballPhase:Match.
    END METHOD.

    /* Pays the week's bills: the phase is Accounts and the bills can be read. */
    METHOD PRIVATE VOID EnterAccounts():
        WageBill = Bank:Wages(mWorld).
        RentBill = mWorld:Rent.
        InterestBill = Bank:Interest(mWorld).
        Balance = Bank:PayWeek(mWorld).
        Phase = FootballPhase:Accounts.
    END METHOD.

    /* After the match the week goes on: Proceed moves from the highlights to the score, and from there through the other results, the table, the accounts, the end of the season if it is one, and the transfer offer, to the Menu. A drawn cup tie is replayed instead (back to PickTeam). The manager is Sacked if the loan is over the limit once the bills are paid. */
    METHOD PUBLIC VOID Proceed():
        VAR INTEGER place.
        CASE Phase:
            WHEN FootballPhase:Match THEN Phase = FootballPhase:FullTime.
            WHEN FootballPhase:FullTime THEN
            DO:
                IF MatchDay:NeedsReplay(ThisFixture, Played) THEN
                DO:
                    MatchDay:Replay(mWorld, ThisFixture).
                    Squad:Prepare(mWorld, mRandom).
                    Phase = FootballPhase:PickTeam.
                END.
                ELSE
                DO:
                    OtherResults = MatchDay:Finish(mWorld, ThisFixture, Played, mRandom).
                    IF ThisFixture:Kind = FixtureKind:League THEN Phase = FootballPhase:Results.
                    ELSE EnterAccounts().
                END.
            END.
            WHEN FootballPhase:Results THEN Phase = FootballPhase:Table.
            WHEN FootballPhase:Table THEN EnterAccounts().
            WHEN FootballPhase:Accounts THEN
            DO:
                IF Bank:OverLimit(mWorld) THEN
                DO:
                    Phase = FootballPhase:Sacked.
                    IsOver = TRUE.
                END.
                ELSE IF LeagueTable:SeasonOver(mWorld) THEN
                DO:
                    place = mWorld:PlaceOf(mWorld:Slot - mWorld:DivisionBase).
                    FinalPlace = place.
                    SeasonPrize = (FootballRules:ClubsPerDivision() + 1 - place) * FootballRules:ValueUnit() * mWorld:Multiplier.
                    SeasonResult = LeagueTable:EndSeason(mWorld, mRandom).
                    Phase = FootballPhase:SeasonEnd.
                END.
                ELSE EnterTransfer().
            END.
            WHEN FootballPhase:SeasonEnd THEN Phase = FootballPhase:Menu.
            OTHERWISE UNDO, THROW NEW GridException("There is nothing to proceed to from " + Phase:ToString()).
        END CASE.
    END METHOD.

    /* After a match a player the club does not own is put on offer (a full squad cannot buy, which TransferBlocked says). */
    METHOD PRIVATE VOID EnterTransfer():
        OfferedPlayer = Market:Offer(mWorld, mRandom).
        TransferBlocked = NOT Market:CanSign(mWorld).
        Phase = FootballPhase:Transfer.
    END METHOD.

    /* Bids for the player on offer. Accepted goes to the Menu. Refused (the price is up a fifth) and NoMoney leave the offer open for another bid. SquadFull cannot be bid at all and goes to the Menu. */
    METHOD PUBLIC BidResult Bid(INPUT piAmount AS INTEGER):
        VAR BidResult answer.
        Need(FootballPhase:Transfer).
        IF TransferBlocked THEN
        DO:
            Phase = FootballPhase:Menu.
            RETURN BidResult:SquadFull.
        END.
        answer = Market:Bid(mWorld, OfferedPlayer, piAmount, mRandom).
        IF answer = BidResult:Accepted THEN Phase = FootballPhase:Menu.
        RETURN answer.
    END METHOD.

    /* Lets the player on offer go and returns to the Menu. */
    METHOD PUBLIC VOID Pass():
        Need(FootballPhase:Transfer).
        Phase = FootballPhase:Menu.
    END METHOD.

END CLASS.
