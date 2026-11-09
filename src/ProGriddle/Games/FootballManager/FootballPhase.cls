/* What the game is waiting for: Setup (a new game's choices), Menu (the manager's office), Selling (an offer for a player), PickTeam, Match (the highlights are being shown), FullTime (the score), Results (the other clubs' scores), Table, Accounts (the week's money), SeasonEnd, Transfer (a player on offer) or Sacked (the loan went over the limit). */
ENUM ProGriddle.Games.FootballManager.FootballPhase:

    DEFINE ENUM Setup = 0
                Menu
                Selling
                PickTeam
                Match
                FullTime
                Results
                Table
                Accounts
                SeasonEnd
                Transfer
                Sacked.

END ENUM.
