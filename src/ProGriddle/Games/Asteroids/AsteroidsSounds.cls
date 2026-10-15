/* What the sounds of Asteroids sound like, in one place (as AsteroidsArt and AsteroidsLook are for the picture). The look is a
   vector screen, so the sounds are chiptune: a zap for a shot, a low boom for a large rock and a higher crack for a small one,
   a long burst of noise for the ship, a sweep up and down for hyperspace, a rumble that loops under the thrust and a warbling
   hum that loops while a saucer is out (low for the large one, high for the small one). Recipes are written as ToneSynth reads
   them (see there); the three that start with @ are the loops. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsSounds FINAL:

    /* The recipe of a cue. Throws GridException for an unknown cue. */
    METHOD PUBLIC STATIC CHARACTER Recipe(INPUT poCue AS AsteroidsCue):
        IF poCue = AsteroidsCue:Fire THEN RETURN "1800>500:90:70".
        IF poCue = AsteroidsCue:RockLarge THEN RETURN "m:70:30,130>45:260:70".
        IF poCue = AsteroidsCue:RockMedium THEN RETURN "m:60:30,220>70:200:70".
        IF poCue = AsteroidsCue:RockSmall THEN RETURN "n:40:30,450>150:130:70".
        IF poCue = AsteroidsCue:ShipDies THEN RETURN "n:250:20,m:650:85".
        IF poCue = AsteroidsCue:SaucerFire THEN RETURN "600>1300:90:30".
        IF poCue = AsteroidsCue:SaucerDies THEN RETURN "1300>200:140:30,n:260:80".
        IF poCue = AsteroidsCue:Hyperspace THEN RETURN "300>1600:130:20,1600>250:200:50".
        IF poCue = AsteroidsCue:ExtraShip THEN RETURN "523:60:20,659:60:20,784:60:20,1047:220:60".
        IF poCue = AsteroidsCue:ThrustLoop THEN RETURN "@m:200:0".
        IF poCue = AsteroidsCue:SaucerLargeHum THEN RETURN "@300>400:100:0,400>300:100:0".
        IF poCue = AsteroidsCue:SaucerSmallHum THEN RETURN "@700>900:80:0,900>700:80:0".
        UNDO, THROW NEW GridException("Asteroids has no sound for cue " + STRING(poCue)).
    END METHOD.

    /* How loud a cue is made, 1 to 100 percent: the loops sit under everything else. */
    METHOD PUBLIC STATIC INTEGER VolumeOf(INPUT poCue AS AsteroidsCue):
        IF poCue = AsteroidsCue:ThrustLoop THEN RETURN 35.
        IF poCue = AsteroidsCue:SaucerLargeHum OR poCue = AsteroidsCue:SaucerSmallHum THEN RETURN 30.
        IF poCue = AsteroidsCue:Fire OR poCue = AsteroidsCue:SaucerFire THEN RETURN 45.
        RETURN 65.
    END METHOD.

    /* Makes the sound of every cue into a bank, under the cue's number. */
    METHOD PUBLIC STATIC VOID Fill(INPUT poBank AS SoundBank):
        DEFINE VARIABLE i   AS INTEGER      NO-UNDO.
        DEFINE VARIABLE cue AS AsteroidsCue NO-UNDO.
        DO i = INTEGER(AsteroidsCue:Fire) TO INTEGER(AsteroidsCue:SaucerSmallHum):
            cue = AsteroidsCue:GetEnum(i).
            poBank:Define(i, Recipe(cue), VolumeOf(cue)).
        END.
    END METHOD.

END CLASS.
