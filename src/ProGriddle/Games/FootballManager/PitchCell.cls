/* What a cell of the pitch holds while an attack is worked out: Vacant (nothing), Attacker, Defender, Ball (only while the attacker is dribbling) or Keeper. */
ENUM ProGriddle.Games.FootballManager.PitchCell:

    DEFINE ENUM Vacant = 0
                Attacker
                Defender
                Ball
                Keeper.

END ENUM.
