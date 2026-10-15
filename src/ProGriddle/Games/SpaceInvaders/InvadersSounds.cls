/* What the sounds of Space Invaders sound like, in one place (as InvadersArt and InvadersLook are for the picture). The look is the
   arcade's neon, so the sounds are the arcade's: square waves and noise. A zap for the cannon's shot, a crunch of noise and a
   falling note for an invader, a long burst of noise for the cannon, the four low notes of the march, a hum that rises and falls
   as long as the saucer is out. Recipes are written as ToneSynth reads them (see there). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersSounds FINAL:

    /* The recipe of a cue. Throws GridException for an unknown cue. */
    METHOD PUBLIC STATIC CHARACTER Recipe(INPUT poCue AS InvadersCue):
        CASE poCue:
            WHEN InvadersCue:Shoot THEN RETURN "1400>250:130:60".
            WHEN InvadersCue:InvaderKilled THEN RETURN "n:50:30,500>90:110:70".
            WHEN InvadersCue:PlayerDies THEN RETURN "n:300:20,n:500:80".
            WHEN InvadersCue:March1 THEN RETURN "110:90:40".
            WHEN InvadersCue:March2 THEN RETURN "98:90:40".
            WHEN InvadersCue:March3 THEN RETURN "87:90:40".
            WHEN InvadersCue:March4 THEN RETURN "82:90:40".
            WHEN InvadersCue:SaucerHit THEN RETURN "1300>300:130:30,n:200:80".
            WHEN InvadersCue:ExtraLife THEN RETURN "523:60:20,659:60:20,784:60:20,1047:220:60".
            WHEN InvadersCue:WaveCleared THEN RETURN "392:70:20,523:70:20,659:70:20,784:160:60".
            WHEN InvadersCue:SaucerHum THEN RETURN "@900>1100:100:0,1100>900:100:0".
            OTHERWISE UNDO, THROW NEW GridException("Space Invaders has no sound for cue " + STRING(poCue)).
        END CASE.
    END METHOD.

    /* How loud a cue is made, 1 to 100 percent: the march is steady, the hum sits under everything else. */
    METHOD PUBLIC STATIC INTEGER VolumeOf(INPUT poCue AS InvadersCue):
        CASE poCue:
            WHEN InvadersCue:SaucerHum THEN RETURN 30.
            WHEN InvadersCue:Shoot THEN RETURN 45.
            WHEN InvadersCue:March1 OR WHEN InvadersCue:March2 OR WHEN InvadersCue:March3 OR WHEN InvadersCue:March4 THEN RETURN 70.
            OTHERWISE RETURN 60.
        END CASE.
    END METHOD.

    /* Makes the sound of every cue into a bank, under the cue's number. */
    METHOD PUBLIC STATIC VOID Fill(INPUT poBank AS SoundBank):
        DEFINE VARIABLE i   AS INTEGER     NO-UNDO.
        DEFINE VARIABLE cue AS InvadersCue NO-UNDO.
        DO i = INTEGER(InvadersCue:Shoot) TO INTEGER(InvadersCue:SaucerHum):
            cue = InvadersCue:GetEnum(i).
            poBank:Define(i, Recipe(cue), VolumeOf(cue)).
        END.
    END METHOD.

END CLASS.
