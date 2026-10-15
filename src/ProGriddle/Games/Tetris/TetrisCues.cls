/* When the sounds of Tetris happen: a cue source (ICueSource) that looks at the game after each change of the picture and says what
   is new since the last look. It compares the game's own counters with the ones it saw (the pieces placed, the lines cleared, the
   level, whether the game is over, whether the stack is dangerously high), so two events in the same millisecond are still two.
   A game that starts again is noticed by its GameSerial and its old events are forgotten, so nothing sounds for them.

   The cues come most important first: the end of the game, then a Tetris or a clear, then the lock, then the level up, then the
   danger. A lock and a clear (or the end) are one priority group, so only the strongest of them is heard; a level up and the danger
   each have a group of their own and sound with it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisCues FINAL IMPLEMENTS ICueSource:

    DEFINE PRIVATE VARIABLE mSerial AS INTEGER NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mPlaced AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLines  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLevel  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mOver   AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mDanger AS LOGICAL NO-UNDO.

    /* Throws GridException for a game that is not a TetrisGame. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS TetrisGame NO-UNDO.
        DEFINE VARIABLE cues  AS CHARACTER  NO-UNDO.
        IF NOT TYPE-OF(poGame, TetrisGame) THEN UNDO, THROW NEW GridException("The cues of Tetris need a Tetris game").
        oGame = CAST(poGame, TetrisGame).
        IF oGame:GameSerial <> mSerial THEN DO:
            /* a new game, or the first look: take its state as it is and say nothing */
            mSerial = oGame:GameSerial.
            Remember(oGame).
            RETURN "".
        END.
        IF oGame:IsOver AND NOT mOver THEN cues = WithCue(cues, INTEGER(TetrisCue:GameOver)).
        IF oGame:LinesCleared <> mLines THEN
            cues = WithCue(cues, (IF oGame:LastClearCount = 4 THEN INTEGER(TetrisCue:Tetris) ELSE INTEGER(TetrisCue:Clear))).
        IF oGame:PiecesPlaced <> mPlaced THEN cues = WithCue(cues, INTEGER(TetrisCue:Lock)).
        IF oGame:Level > mLevel THEN cues = WithCue(cues, INTEGER(TetrisCue:LevelUp)).
        IF oGame:Danger AND NOT mDanger THEN cues = WithCue(cues, INTEGER(TetrisCue:Danger)).
        Remember(oGame).
        RETURN cues.
    END METHOD.

    /* 1 for the lock, the clears and the end of the game (the impact), 2 for the level up, 3 for the danger. */
    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        CASE piCue:
            WHEN INTEGER(TetrisCue:LevelUp) THEN RETURN 2.
            WHEN INTEGER(TetrisCue:Danger) THEN RETURN 3.
            OTHERWISE RETURN 1.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID Remember(INPUT poGame AS TetrisGame):
        mPlaced = poGame:PiecesPlaced.
        mLines = poGame:LinesCleared.
        mLevel = poGame:Level.
        mOver = poGame:IsOver.
        mDanger = poGame:Danger.
    END METHOD.

    METHOD PRIVATE CHARACTER WithCue(INPUT pcCues AS CHARACTER, INPUT piCue AS INTEGER):
        RETURN pcCues + (IF pcCues = "" THEN "" ELSE ",") + STRING(piCue).
    END METHOD.

END CLASS.
