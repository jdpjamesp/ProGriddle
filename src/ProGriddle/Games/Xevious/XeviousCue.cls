/* The sounds of Xevious, by name. INTEGER(XeviousCue:Zap) is the cue number a sound player and a sound bank know it by (1 to 64).
   BossLoop is the sound that loops, for as long as the mothership is out. XeviousSounds says what each one sounds like and
   XeviousCues says when each one happens. */
ENUM ProGriddle.Games.Xevious.XeviousCue:

    DEFINE ENUM Zap = 1
                BombDrop
                BombBurst
                AirKill
                GroundKill
                SolFound
                FlagFound
                EnemyFire
                Clang
                BossHit
                BossKill
                PlayerDies
                ExtraLife
                StageClear
                BossLoop.

END ENUM.
