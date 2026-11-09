/* The screen the manager is looking at. The set up screens (Name, Club, Kit) and the menu's own screens (Main, Squad, Status, Loan, Repay, Levels) belong to the interface; the others are the phases of the game (Selling, PickTeam, Match, FullTime, Results, Table, Accounts, SeasonEnd, Transfer, Sacked). */
ENUM ProGriddle.Games.FootballManager.FootballMode:

    DEFINE ENUM Name = 0
                Club
                Kit
                Main
                Squad
                Status
                Loan
                Repay
                Levels
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
