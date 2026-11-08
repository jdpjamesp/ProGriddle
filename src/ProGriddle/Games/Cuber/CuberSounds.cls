/* What the sounds of Cuber sound like, in one place (as CuberLook is for the colours). Soft triangle waves, like glass lamps being
   lit: a short blip for a hop, a chime when a lamp lights and a lower note for the ring and for a lamp put out, a long falling
   note for a fall, a thud for a hit, a rising arpeggio when a halo lifts Pip, a splintering drop for the Coil falling, a bright
   ping for a Frost, a three note scoop for a caught moth, a pop for a seed hatching and fanfares for a round, a level, an extra
   Pip and a new game. Recipes are written as ToneSynth reads them (see there). Nothing loops. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberSounds FINAL:

    /* The recipe of a cue. Throws GridException for an unknown cue. */
    METHOD PUBLIC STATIC CHARACTER Recipe(INPUT poCue AS CuberCue):
        CASE poCue:
            WHEN CuberCue:Hop THEN RETURN "t330>440:70:40".
            WHEN CuberCue:LampDone THEN RETURN "t784:50:20,t1047:110:50".
            WHEN CuberCue:LampHalf THEN RETURN "t523:70:40".
            WHEN CuberCue:LampOut THEN RETURN "t392>262:110:40".
            WHEN CuberCue:Fall THEN RETURN "t700>120:450:20".
            WHEN CuberCue:Hit THEN RETURN "n:60:20,t300>80:260:60".
            WHEN CuberCue:HaloRide THEN RETURN "t440:70:20,t523:70:20,t659:70:20,t880:70:20,t1047:220:60".
            WHEN CuberCue:CoilFalls THEN RETURN "t900>200:300:30,n:130:60".
            WHEN CuberCue:FrostPop THEN RETURN "t1568:50:30,t2093:130:60".
            WHEN CuberCue:MothCaught THEN RETURN "t659:50:20,t880:50:20,t1175:150:60".
            WHEN CuberCue:Hatch THEN RETURN "n:40:30,t200>400:130:30".
            WHEN CuberCue:RoundClear THEN RETURN "t523:70:20,t659:70:20,t784:70:20,t1047:70:20,t784:70:20,t1047:260:60".
            WHEN CuberCue:LevelClear THEN RETURN "t392:70:20,t523:70:20,t659:70:20,t784:70:20,t1047:70:20,t1319:70:20,t1568:300:60".
            WHEN CuberCue:ExtraLife THEN RETURN "t523:60:20,t659:60:20,t784:60:20,t1047:240:60".
            WHEN CuberCue:GameStart THEN RETURN "t392:80:20,t523:80:20,t659:170:50".
            OTHERWISE UNDO, THROW NEW GridException("Cuber has no sound for cue " + STRING(poCue)).
        END CASE.
    END METHOD.

    /* How loud a cue is made, 1 to 100 percent: a hop sits under everything else. */
    METHOD PUBLIC STATIC INTEGER VolumeOf(INPUT poCue AS CuberCue):
        CASE poCue:
            WHEN CuberCue:Hop THEN RETURN 35.
            WHEN CuberCue:LampHalf OR WHEN CuberCue:LampOut THEN RETURN 50.
            OTHERWISE RETURN 65.
        END CASE.
    END METHOD.

    /* Makes the sound of every cue into a bank, under the cue's number. */
    METHOD PUBLIC STATIC VOID Fill(INPUT poBank AS SoundBank):
        VAR INTEGER i.
        VAR CuberCue cue.
        DO i = INTEGER(CuberCue:Hop) TO INTEGER(CuberCue:GameStart):
            cue = CuberCue:GetEnum(i).
            poBank:Define(i, Recipe(cue), VolumeOf(cue)).
        END.
    END METHOD.

END CLASS.
