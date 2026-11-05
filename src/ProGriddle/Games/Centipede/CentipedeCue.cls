/* The sounds of Centipede, by name. INTEGER(CentipedeCue:Fire) is the cue number a sound player and a sound bank know it by
   (1 to 64). SpiderLoop and ScorpionLoop are the sounds that loop, for as long as that creature is out. CentipedeSounds says
   what each one sounds like and CentipedeCues says when each one happens. */
ENUM ProGriddle.Games.Centipede.CentipedeCue:

    DEFINE ENUM Fire = 1
                MushroomBreak
                SegmentKill
                HeadKill
                FleaHit
                FleaKill
                SpiderKill
                ScorpionKill
                PlayerDies
                ExtraLife
                WaveClear
                SpiderLoop
                ScorpionLoop.

END ENUM.
