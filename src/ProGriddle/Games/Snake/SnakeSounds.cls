/* What the sounds of Snake sound like, in one place (as SnakeArt and SnakeLook are for the picture). The look is Lantern Glass, soft
   and warm, so every sound is a triangle wave with a gentle decay: a small rising blip for a bite, a slow falling slide for the
   crash, a rising run that ends on a long bright note for a win. Recipes are written as ToneSynth reads them (see there). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeSounds FINAL:

    /* The recipe of a cue. Throws GridException for an unknown cue. */
    METHOD PUBLIC STATIC CHARACTER Recipe(INPUT poCue AS SnakeCue):
        IF poCue = SnakeCue:Eat THEN RETURN "t523:40:30,t784:90:70".
        IF poCue = SnakeCue:Crash THEN RETURN "t196>65:320:70".
        IF poCue = SnakeCue:Win THEN RETURN "t392:80:30,t523:80:30,t659:80:30,t784:80:30,t1047:320:70".
        UNDO, THROW NEW GridException("Snake has no sound for cue " + STRING(poCue)).
    END METHOD.

    /* How loud a cue is made, 1 to 100 percent. */
    METHOD PUBLIC STATIC INTEGER VolumeOf(INPUT poCue AS SnakeCue):
        IF poCue = SnakeCue:Eat THEN RETURN 60.
        RETURN 70.
    END METHOD.

    /* Makes the sound of every cue into a bank, under the cue's number. */
    METHOD PUBLIC STATIC VOID Fill(INPUT poBank AS SoundBank):
        DEFINE VARIABLE i   AS INTEGER  NO-UNDO.
        DEFINE VARIABLE cue AS SnakeCue NO-UNDO.
        DO i = INTEGER(SnakeCue:Eat) TO INTEGER(SnakeCue:Win):
            cue = SnakeCue:GetEnum(i).
            poBank:Define(i, Recipe(cue), VolumeOf(cue)).
        END.
    END METHOD.

END CLASS.
