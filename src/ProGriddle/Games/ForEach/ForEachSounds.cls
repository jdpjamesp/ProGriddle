/* What the sounds of FOR EACH sound like, in one place (as ForEachArt and ForEachLook are for the picture). The game is a data centre at
   night, so the sounds are small machine noises in chiptune: a rising boot-up jingle, a two note crunch for every bit, a quick sweep
   up for a phantom, a bright three note arpeggio for an item, a long slide down for a crash. The loops (recipes that start with @) are
   the alarm, which beeps faster as the bits run out, a low throb while phantoms are rolled back and a high twitter while one runs
   home. Recipes are written as ToneSynth reads them (see there). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachSounds FINAL:

    /* The recipe of a cue. Throws GridException for an unknown cue. */
    METHOD PUBLIC STATIC CHARACTER Recipe(INPUT poCue AS ForEachCue):
        CASE poCue:
            WHEN ForEachCue:Start THEN RETURN "t392:90:30,t523:90:30,t659:90:30,t784:90:30,t1047:90:30,t784:90:30,t1047:300:70".
            WHEN ForEachCue:Crunch1 THEN RETURN "t330:35:30,t440:50:60".
            WHEN ForEachCue:Crunch2 THEN RETURN "t440:35:30,t330:50:60".
            WHEN ForEachCue:PhantomEaten THEN RETURN "t250>1400:170:40".
            WHEN ForEachCue:ItemEaten THEN RETURN "t660:60:20,t880:60:20,t1320:140:60".
            WHEN ForEachCue:Death THEN RETURN "t520>70:760:80,n:120:80".
            WHEN ForEachCue:ExtraLife THEN RETURN "t659:70:20,t880:70:20,t1175:70:20,t1568:260:60".
            WHEN ForEachCue:Alarm1 THEN RETURN "@t200>260:240:0,260>200:240:0".
            WHEN ForEachCue:Alarm2 THEN RETURN "@t220>290:200:0,290>220:200:0".
            WHEN ForEachCue:Alarm3 THEN RETURN "@t240>320:160:0,320>240:160:0".
            WHEN ForEachCue:Alarm4 THEN RETURN "@t260>350:125:0,350>260:125:0".
            WHEN ForEachCue:Alarm5 THEN RETURN "@t280>380:95:0,380>280:95:0".
            WHEN ForEachCue:RollbackLoop THEN RETURN "@t110>170:70:0,170>110:70:0".
            WHEN ForEachCue:ReturningLoop THEN RETURN "@t900>600:60:0,600>900:60:0".
            WHEN ForEachCue:ItemAppears THEN RETURN "t1320:60:20,t1760:60:20,t1320:60:20,t1760:140:60".
            OTHERWISE UNDO, THROW NEW GridException("FOR EACH has no sound for cue " + STRING(poCue)).
        END CASE.
    END METHOD.

    /* How loud a cue is made, 1 to 100 percent: the loops sit under everything else. */
    METHOD PUBLIC STATIC INTEGER VolumeOf(INPUT poCue AS ForEachCue):
        CASE poCue:
            WHEN ForEachCue:Alarm1 OR WHEN ForEachCue:Alarm2 OR WHEN ForEachCue:Alarm3 OR WHEN ForEachCue:Alarm4 OR WHEN ForEachCue:Alarm5
                OR WHEN ForEachCue:RollbackLoop OR WHEN ForEachCue:ReturningLoop THEN RETURN 28.
            WHEN ForEachCue:Crunch1 OR WHEN ForEachCue:Crunch2 THEN RETURN 45.
            OTHERWISE RETURN 65.
        END CASE.
    END METHOD.

    /* Makes the sound of every cue into a bank, under the cue's number. */
    METHOD PUBLIC STATIC VOID Fill(INPUT poBank AS SoundBank):
        DEFINE VARIABLE i   AS INTEGER     NO-UNDO.
        DEFINE VARIABLE cue AS ForEachCue  NO-UNDO.
        DO i = INTEGER(ForEachCue:Start) TO INTEGER(ForEachCue:ItemAppears):
            cue = ForEachCue:GetEnum(i).
            poBank:Define(i, Recipe(cue), VolumeOf(cue)).
        END.
    END METHOD.

END CLASS.
