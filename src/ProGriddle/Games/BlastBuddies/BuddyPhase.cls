/* The phases of a Blast Buddies game, as the values of BlastBuddiesGame:Phase.

     Arrival   the buddies come down onto the land at the start (a few seconds)
     Banner    the name of the team and buddy whose turn is next is shown, and the wind is rolled
     Turn      the buddy in turn walks, aims and fires, against the turn clock
     Retreat   after a shot the buddy has a few seconds to get away before it ends
     Resolve   shots and blasts finish, buddies fall and die, until everything is still
     Winner    one team is left standing
     Draw      nobody is left standing */
ENUM ProGriddle.Games.BlastBuddies.BuddyPhase:

    DEFINE ENUM Arrival = 0
                Banner
                Turn
                Retreat
                Resolve
                Winner
                Draw.

END ENUM.
