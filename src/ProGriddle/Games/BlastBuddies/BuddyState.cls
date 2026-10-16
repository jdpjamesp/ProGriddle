/* What a buddy is doing as far as the ground is concerned.

     Standing   on the ground (the painter picks a standing or walking frame from what the player is doing)
     Airborne   in the air: hopping, flipping, falling or thrown by a blast
     Drowned    gone into the water, or off a side of the map */
ENUM ProGriddle.Games.BlastBuddies.BuddyState:

    DEFINE ENUM Standing = 0
                Airborne
                Drowned.

END ENUM.
