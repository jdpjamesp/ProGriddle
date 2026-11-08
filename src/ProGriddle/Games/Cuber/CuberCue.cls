/* The sounds of Cuber, by name. INTEGER(CuberCue:Hop) is the cue number a sound player and a sound bank know it by (1 to 64).
   CuberSounds says what each one sounds like and CuberCues says when each one happens. */
ENUM ProGriddle.Games.Cuber.CuberCue:
    DEFINE ENUM Hop = 1
                LampDone
                LampHalf
                LampOut
                Fall
                Hit
                HaloRide
                CoilFalls
                FrostPop
                MothCaught
                Hatch
                RoundClear
                LevelClear
                ExtraLife
                GameStart.
END ENUM.
