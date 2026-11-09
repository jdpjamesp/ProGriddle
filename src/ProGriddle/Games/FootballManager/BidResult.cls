/* The answer to a bid for a player: Accepted (he joins the squad as a reserve), Refused (the club wants more, and his price has gone up), NoMoney (the manager has not the cash bid) or SquadFull (the squad already holds the 16 players the rules allow). */
ENUM ProGriddle.Games.FootballManager.BidResult:

    DEFINE ENUM Accepted = 1
                Refused
                NoMoney
                SquadFull.

END ENUM.
