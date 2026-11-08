/* What the sounds of Centipede sound like, in one place (as CentipedeLook is for the colours). Chiptune: a quick falling zap for
   the shot, a pop for a mushroom, a crunch for a segment and a longer one for a head, a rising chirp for the flea, a wobbling
   swoop for the spider, a little fanfare for the scorpion, noise and a rumble for the shooter, and two loops: the spider's
   skittering warble and the scorpion's low growl. Recipes are written as ToneSynth reads them (see there); the two that start
   with @ are the loops. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeSounds FINAL:

    /* The recipe of a cue. Throws GridException for an unknown cue. */
    METHOD PUBLIC STATIC CHARACTER Recipe(INPUT poCue AS CentipedeCue):
        CASE poCue:
            WHEN CentipedeCue:Fire THEN RETURN "1500>500:70:70".
            WHEN CentipedeCue:MushroomBreak THEN RETURN "n:25:30,420>180:60:70".
            WHEN CentipedeCue:SegmentKill THEN RETURN "900>300:70:60,n:45:60".
            WHEN CentipedeCue:HeadKill THEN RETURN "1300>350:90:50,n:90:70".
            WHEN CentipedeCue:FleaHit THEN RETURN "700>1300:70:30".
            WHEN CentipedeCue:FleaKill THEN RETURN "1300>250:150:40,n:90:80".
            WHEN CentipedeCue:SpiderKill THEN RETURN "t300>900:90:30,t900>200:170:60".
            WHEN CentipedeCue:ScorpionKill THEN RETURN "t523:60:20,t659:60:20,t784:60:20,t1047:180:50".
            WHEN CentipedeCue:PlayerDies THEN RETURN "n:230:20,m:620:85".
            WHEN CentipedeCue:ExtraLife THEN RETURN "523:60:20,659:60:20,784:60:20,1047:220:60".
            WHEN CentipedeCue:WaveClear THEN RETURN "t392:70:30,t523:70:30,t659:70:30,t784:220:60".
            WHEN CentipedeCue:SpiderLoop THEN RETURN "@500>800:70:0,800>500:70:0".
            WHEN CentipedeCue:ScorpionLoop THEN RETURN "@130>190:120:0,190>130:120:0".
            OTHERWISE UNDO, THROW NEW GridException("Centipede has no sound for cue " + STRING(poCue)).
        END CASE.
    END METHOD.

    /* How loud a cue is made, 1 to 100 percent: the loops sit under everything else. */
    METHOD PUBLIC STATIC INTEGER VolumeOf(INPUT poCue AS CentipedeCue):
        CASE poCue:
            WHEN CentipedeCue:SpiderLoop OR WHEN CentipedeCue:ScorpionLoop THEN RETURN 28.
            WHEN CentipedeCue:Fire THEN RETURN 40.
            WHEN CentipedeCue:MushroomBreak THEN RETURN 50.
            OTHERWISE RETURN 65.
        END CASE.
    END METHOD.

    /* Makes the sound of every cue into a bank, under the cue's number. */
    METHOD PUBLIC STATIC VOID Fill(INPUT poBank AS SoundBank):
        VAR INTEGER i.
        VAR CentipedeCue cue.
        DO i = INTEGER(CentipedeCue:Fire) TO INTEGER(CentipedeCue:ScorpionLoop):
            cue = CentipedeCue:GetEnum(i).
            poBank:Define(i, Recipe(cue), VolumeOf(cue)).
        END.
    END METHOD.

END CLASS.
