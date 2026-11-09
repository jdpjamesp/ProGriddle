/* What a player of the pool is to the club: NotOwned (on the market), Reserve (in the squad, not playing), Starter (picked to play) or Injured (in the squad but cannot play or be sold). */
ENUM ProGriddle.Games.FootballManager.SquadRole:

    DEFINE ENUM NotOwned = 0
                Reserve
                Starter
                Injured.

END ENUM.
