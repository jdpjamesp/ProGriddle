/* When the sounds of FOR EACH happen: a cue source (ICueSource) and loop source (ILoopSource) that look at the game after each change
   of the picture. They compare the game's own running counts with the ones last seen (bits and commit tokens eaten, phantoms eaten,
   items eaten and deaths, which only go up during a game, and the lives), so two events in the same millisecond are still two.

   Nothing sounds on the title screen: the first look takes the state as it is, and a game that starts again with its counts back at
   nothing makes no noise for the old ones. A new game from the title or the game over screen sounds the start jingle. Eating
   alternates two crunches (several bits in one look make one). The cues come most important first: death, an extra life, a phantom
   eaten, an item eaten, an item coming out, a crunch.

   The loops are states: the alarm sounds all through play and gets faster as the bits run out (Alarm1 above 150 left, Alarm2 above
   100, Alarm3 above 50, Alarm4 above 20, then Alarm5); phantoms rolled back silence it with their drone; a phantom running home
   silences both. A paused game, a title screen and a finished game have no loops. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachCues FINAL IMPLEMENTS ICueSource, ILoopSource:

    DEFINE PRIVATE VARIABLE mPhase    AS ForEachPhase NO-UNDO.
    DEFINE PRIVATE VARIABLE mLives    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mEaten    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mPhantoms AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mItems    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mShown    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mDeaths   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mScore    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSecond   AS LOGICAL NO-UNDO.

    /* Throws GridException for a game that is not a FOR EACH game. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS ForEachGame NO-UNDO.
        DEFINE VARIABLE cues  AS CHARACTER   NO-UNDO.
        DEFINE VARIABLE eaten AS INTEGER     NO-UNDO.
        IF NOT TYPE-OF(poGame, ForEachGame) THEN UNDO, THROW NEW GridException("The cues of FOR EACH need a FOR EACH game").
        oGame = CAST(poGame, ForEachGame).
        /* the first look and the title screen: take the state as it is, and say nothing */
        IF NOT VALID-OBJECT(mPhase) OR mPhase = ForEachPhase:Title THEN DO:
            cues = (IF VALID-OBJECT(mPhase) AND oGame:Phase = ForEachPhase:Ready THEN STRING(INTEGER(ForEachCue:Start)) ELSE "").
            Remember(oGame).
            RETURN cues.
        END.
        /* a new game after the end */
        IF mPhase = ForEachPhase:GameOver AND oGame:Phase = ForEachPhase:Ready THEN DO:
            Remember(oGame).
            RETURN STRING(INTEGER(ForEachCue:Start)).
        END.
        eaten = oGame:BitsEatenTotal + oGame:CommitsEatenTotal.
        /* a game that started again has its counts back at nothing: nothing sounds for the old ones */
        IF eaten < mEaten OR oGame:DeathCount < mDeaths OR oGame:PhantomsEatenTotal < mPhantoms OR oGame:ItemsEatenTotal < mItems OR oGame:ItemsShownTotal < mShown THEN DO:
            Remember(oGame).
            RETURN "".
        END.
        IF oGame:DeathCount > mDeaths THEN cues = WithCue(cues, INTEGER(ForEachCue:Death)).
        IF oGame:Lives > mLives AND oGame:Score > mScore THEN cues = WithCue(cues, INTEGER(ForEachCue:ExtraLife)).
        IF oGame:PhantomsEatenTotal > mPhantoms THEN cues = WithCue(cues, INTEGER(ForEachCue:PhantomEaten)).
        IF oGame:ItemsEatenTotal > mItems THEN cues = WithCue(cues, INTEGER(ForEachCue:ItemEaten)).
        IF oGame:ItemsShownTotal > mShown THEN cues = WithCue(cues, INTEGER(ForEachCue:ItemAppears)).
        IF eaten > mEaten THEN DO:
            cues = WithCue(cues, (IF mSecond THEN INTEGER(ForEachCue:Crunch2) ELSE INTEGER(ForEachCue:Crunch1))).
            mSecond = NOT mSecond.
        END.
        Remember(oGame).
        RETURN cues.
    END METHOD.

    /* The death, the extra life, a phantom or an item eaten, and the crunches are one group each, except that the two crunches
       share one: only the first of a group that comes in the same poll is played. */
    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        CASE piCue:
            WHEN INTEGER(ForEachCue:Crunch1) OR WHEN INTEGER(ForEachCue:Crunch2) THEN RETURN 1.
            WHEN INTEGER(ForEachCue:PhantomEaten) THEN RETURN 2.
            WHEN INTEGER(ForEachCue:ItemEaten) THEN RETURN 3.
            WHEN INTEGER(ForEachCue:ItemAppears) THEN RETURN 7.
            WHEN INTEGER(ForEachCue:Death) THEN RETURN 4.
            WHEN INTEGER(ForEachCue:ExtraLife) THEN RETURN 5.
            OTHERWISE RETURN 6.
        END CASE.
    END METHOD.

    /* The loop that should be sounding in a game that is being played and is not paused: one of the alarms, the drone of rolled back
       phantoms, or the sound of one running home. */
    METHOD PUBLIC CHARACTER Loops(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS ForEachGame NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER     NO-UNDO.
        DEFINE VARIABLE spare AS INTEGER     NO-UNDO.
        IF NOT TYPE-OF(poGame, ForEachGame) THEN UNDO, THROW NEW GridException("The cues of FOR EACH need a FOR EACH game").
        oGame = CAST(poGame, ForEachGame).
        IF oGame:Phase <> ForEachPhase:Playing OR oGame:Paused THEN RETURN "".
        DO i = 1 TO 4:
            IF oGame:PhantomPresent(PhantomKind:GetEnum(i)) AND oGame:ModeOf(PhantomKind:GetEnum(i)) = PhantomMode:Returning THEN
                RETURN STRING(INTEGER(ForEachCue:ReturningLoop)).
        END.
        IF oGame:RollbackFramesLeft > 0 THEN RETURN STRING(INTEGER(ForEachCue:RollbackLoop)).
        spare = oGame:BitsLeft.
        IF spare > 150 THEN RETURN STRING(INTEGER(ForEachCue:Alarm1)).
        IF spare > 100 THEN RETURN STRING(INTEGER(ForEachCue:Alarm2)).
        IF spare > 50 THEN RETURN STRING(INTEGER(ForEachCue:Alarm3)).
        IF spare > 20 THEN RETURN STRING(INTEGER(ForEachCue:Alarm4)).
        RETURN STRING(INTEGER(ForEachCue:Alarm5)).
    END METHOD.

    METHOD PRIVATE CHARACTER WithCue(INPUT pcCues AS CHARACTER, INPUT piCue AS INTEGER):
        RETURN (IF pcCues = "" THEN "" ELSE pcCues + ",") + STRING(piCue).
    END METHOD.

    /* Takes the game as it is now as the last thing seen. */
    METHOD PRIVATE VOID Remember(INPUT poGame AS ForEachGame):
        ASSIGN mPhase = poGame:Phase
               mLives = poGame:Lives
               mEaten = poGame:BitsEatenTotal + poGame:CommitsEatenTotal
               mPhantoms = poGame:PhantomsEatenTotal
               mItems = poGame:ItemsEatenTotal
               mShown = poGame:ItemsShownTotal
               mDeaths = poGame:DeathCount
               mScore = poGame:Score.
    END METHOD.

END CLASS.
