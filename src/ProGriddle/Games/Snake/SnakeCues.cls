/* When the sounds of Snake happen: a cue source (ICueSource) that looks at the game after each change of the picture and says what
   is new since the last look. It compares the game's own counters with the ones it saw (the food eaten, whether the game is over),
   so two events in the same millisecond are still two. A game that starts again is noticed by its GameSerial and its old events
   are forgotten. A game that is waiting for its first turn key makes no sound.

   The end of the game comes before the food that caused it, and the three cues are one priority group, so only the end is heard
   when the last piece of food fills the board. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeCues FINAL IMPLEMENTS ICueSource:

    DEFINE PRIVATE VARIABLE mSerial AS INTEGER NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mEaten  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mOver   AS LOGICAL NO-UNDO.

    /* Throws GridException for a game that is not a SnakeGame. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS SnakeGame NO-UNDO.
        DEFINE VARIABLE cues  AS CHARACTER NO-UNDO.
        IF NOT TYPE-OF(poGame, SnakeGame) THEN UNDO, THROW NEW GridException("The cues of Snake need a Snake game").
        oGame = CAST(poGame, SnakeGame).
        IF oGame:GameSerial <> mSerial THEN DO:
            /* a new game, or the first look: take its state as it is and say nothing */
            mSerial = oGame:GameSerial.
            mEaten = oGame:FoodEaten.
            mOver = oGame:IsOver.
            RETURN "".
        END.
        IF oGame:IsOver AND NOT mOver THEN cues = STRING(IF oGame:HasWon THEN INTEGER(SnakeCue:Win) ELSE INTEGER(SnakeCue:Crash)).
        IF oGame:FoodEaten > mEaten THEN cues = cues + (IF cues = "" THEN "" ELSE ",") + STRING(INTEGER(SnakeCue:Eat)).
        mEaten = oGame:FoodEaten.
        mOver = oGame:IsOver.
        RETURN cues.
    END METHOD.

    /* All three cues are one group: the end of the game covers the last bite. */
    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        RETURN 1.
    END METHOD.

END CLASS.
