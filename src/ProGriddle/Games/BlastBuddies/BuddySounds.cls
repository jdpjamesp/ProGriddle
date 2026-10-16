/* What the sounds of Blast Buddies sound like, in one place (as BuddiesArt and BuddiesLook are for the picture). Cheerful chiptune for
   a cartoon war: little blips for walking, hopping and aiming, four rising ticks while the power builds, a whoosh for the rocket and a
   quiet hiss that loops while it flies, three sizes of explosion (noise with a falling note), a bend for a buddy that squeals, a long
   fall for one that dies, a burst of noise for the water, a two note call at the start of a turn and a tick in the last ten seconds,
   and a fanfare for the winner and a falling pair for a draw. Recipes are written as ToneSynth reads them (see there); the one that
   starts with @ is the loop. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddySounds FINAL:

    /* The recipe of a cue. Throws GridException for an unknown cue. */
    METHOD PUBLIC STATIC CHARACTER Recipe(INPUT poCue AS BuddyCue):
        CASE poCue:
            WHEN BuddyCue:WalkTick THEN RETURN "t260:22:60".
            WHEN BuddyCue:Hop THEN RETURN "300>620:90:60".
            WHEN BuddyCue:Flip THEN RETURN "300>980:150:60".
            WHEN BuddyCue:Land THEN RETURN "n:30:30,160>70:90:70".
            WHEN BuddyCue:AimTick THEN RETURN "t1100:12:50".
            WHEN BuddyCue:ChargeA THEN RETURN "t400:40:40".
            WHEN BuddyCue:ChargeB THEN RETURN "t520:40:40".
            WHEN BuddyCue:ChargeC THEN RETURN "t680:40:40".
            WHEN BuddyCue:ChargeD THEN RETURN "t880:40:40".
            WHEN BuddyCue:Fire THEN RETURN "n:70:30,900>200:220:70".
            WHEN BuddyCue:FlightLoop THEN RETURN "@m:160:0".
            WHEN BuddyCue:BlastSmall THEN RETURN "n:90:30,320>90:200:70".
            WHEN BuddyCue:BlastMedium THEN RETURN "n:140:30,m:340:75".
            WHEN BuddyCue:BlastLarge THEN RETURN "n:220:30,m:640:85".
            WHEN BuddyCue:Squeal THEN RETURN "900>1600:70:30,1600>700:100:50".
            WHEN BuddyCue:Death THEN RETURN "800>100:380:40".
            WHEN BuddyCue:Splash THEN RETURN "n:140:60".
            WHEN BuddyCue:TurnStart THEN RETURN "t523:70:30,t784:150:70".
            WHEN BuddyCue:Countdown THEN RETURN "1000:40:60".
            WHEN BuddyCue:Winner THEN RETURN "523:100:20,659:100:20,784:100:20,1047:340:60".
            WHEN BuddyCue:Draw THEN RETURN "400>300:170:20,300>200:260:60".
            OTHERWISE UNDO, THROW NEW GridException("Blast Buddies has no sound for cue " + STRING(poCue)).
        END CASE.
    END METHOD.

    /* How loud a cue is made, 1 to 100 percent: the loop and the little ticks sit under everything else. */
    METHOD PUBLIC STATIC INTEGER VolumeOf(INPUT poCue AS BuddyCue):
        CASE poCue:
            WHEN BuddyCue:FlightLoop THEN RETURN 25.
            WHEN BuddyCue:WalkTick OR WHEN BuddyCue:AimTick OR WHEN BuddyCue:Countdown THEN RETURN 30.
            WHEN BuddyCue:ChargeA OR WHEN BuddyCue:ChargeB OR WHEN BuddyCue:ChargeC OR WHEN BuddyCue:ChargeD THEN RETURN 35.
            WHEN BuddyCue:Hop OR WHEN BuddyCue:Flip OR WHEN BuddyCue:Land THEN RETURN 45.
            WHEN BuddyCue:BlastLarge OR WHEN BuddyCue:BlastMedium OR WHEN BuddyCue:BlastSmall THEN RETURN 80.
            OTHERWISE RETURN 60.
        END CASE.
    END METHOD.

    /* Makes the sound of every cue into a bank, under the cue's number. */
    METHOD PUBLIC STATIC VOID Fill(INPUT poBank AS SoundBank):
        DEFINE VARIABLE i   AS INTEGER  NO-UNDO.
        DEFINE VARIABLE cue AS BuddyCue NO-UNDO.
        DO i = INTEGER(BuddyCue:WalkTick) TO INTEGER(BuddyCue:Draw):
            cue = BuddyCue:GetEnum(i).
            poBank:Define(i, Recipe(cue), VolumeOf(cue)).
        END.
    END METHOD.

END CLASS.
