/* What the sounds of Tetris sound like, in one place (as TetrisArt and TetrisLook are for the picture). The look is Lantern Glass,
   soft and warm, so every sound is a triangle wave with a gentle decay and none is loud: a muffled thud for a lock, a rising
   run of notes for a clear (longer for a Tetris and for a level up), a falling slide for the end, a low double note for the danger.
   Recipes are written as ToneSynth reads them (see there). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisSounds FINAL:

    /* The recipe of a cue. Throws GridException for an unknown cue. */
    METHOD PUBLIC STATIC CHARACTER Recipe(INPUT poCue AS TetrisCue):
        IF poCue = TetrisCue:Lock THEN RETURN "t180>90:70:60".
        IF poCue = TetrisCue:Clear THEN RETURN "t440:45:40,t587:45:40,t784:110:70".
        IF poCue = TetrisCue:Tetris THEN RETURN "t523:60:30,t659:60:30,t784:60:30,t1047:60:30,t784:50:30,t1047:50:30,t1319:220:70".
        IF poCue = TetrisCue:LevelUp THEN RETURN "t659:55:30,t784:55:30,t988:55:30,t1319:55:30,t1568:55:30,t1319:55:30,t1976:200:70".
        IF poCue = TetrisCue:GameOver THEN RETURN "t392>196:160:20,t330>147:160:20,t262>65:460:70".
        IF poCue = TetrisCue:Danger THEN RETURN "t110:90:40,r:30,t98:110:60".
        UNDO, THROW NEW GridException("Tetris has no sound for cue " + STRING(poCue)).
    END METHOD.

    /* How loud a cue is made, 1 to 100 percent: the lock is quiet, the rest are a little louder. */
    METHOD PUBLIC STATIC INTEGER VolumeOf(INPUT poCue AS TetrisCue):
        IF poCue = TetrisCue:Lock THEN RETURN 60.
        IF poCue = TetrisCue:Danger THEN RETURN 55.
        RETURN 70.
    END METHOD.

    /* Makes the sound of every cue into a bank, under the cue's number. */
    METHOD PUBLIC STATIC VOID Fill(INPUT poBank AS SoundBank):
        DEFINE VARIABLE i   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cue AS TetrisCue NO-UNDO.
        DO i = INTEGER(TetrisCue:Lock) TO INTEGER(TetrisCue:Danger):
            cue = TetrisCue:GetEnum(i).
            poBank:Define(i, Recipe(cue), VolumeOf(cue)).
        END.
    END METHOD.

END CLASS.
