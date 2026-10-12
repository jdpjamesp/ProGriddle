/* The high score list: the ten best scores, best first. It is kept in the settings under "tetris.scores"
   as a comma separated string of score:lines pairs, for example "12400:32,9800:25,300:3". A score
   that ties an older one ranks below it. Only a score of 1 or more can be on the list. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisHighScores FINAL:

    DEFINE PRIVATE VARIABLE mSettings AS ISettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mScore    AS INTEGER   NO-UNDO EXTENT 10.
    DEFINE PRIVATE VARIABLE mLines    AS INTEGER   NO-UNDO EXTENT 10.
    DEFINE PRIVATE VARIABLE mCount    AS INTEGER   NO-UNDO.

    /* How many scores the list keeps. */
    METHOD PUBLIC STATIC INTEGER ListSize():
        RETURN 10.
    END METHOD.

    CONSTRUCTOR PUBLIC TetrisHighScores(INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("High scores need settings").
        mSettings = poSettings.
    END CONSTRUCTOR.

    /* How many scores are on the list, 0 to 10. */
    METHOD PUBLIC INTEGER Count():
        Load().
        RETURN mCount.
    END METHOD.

    /* The best score, or 0 when the list is empty. */
    METHOD PUBLIC INTEGER Best():
        Load().
        IF mCount = 0 THEN RETURN 0.
        RETURN mScore[1].
    END METHOD.

    /* The score at a place, 1 for the best. Throws GridException for a place that is not on the list. */
    METHOD PUBLIC INTEGER ScoreAt(INPUT piPlace AS INTEGER):
        Load().
        CheckPlace(piPlace).
        RETURN mScore[piPlace].
    END METHOD.

    /* The lines cleared in the game at a place. */
    METHOD PUBLIC INTEGER LinesAt(INPUT piPlace AS INTEGER):
        Load().
        CheckPlace(piPlace).
        RETURN mLines[piPlace].
    END METHOD.

    /* Adds a score. Returns its place, 1 for a new best, or 0 when it did not make the list: it is
       under 1, or no better than the lowest score of a full list. */
    METHOD PUBLIC INTEGER Record(INPUT piScore AS INTEGER, INPUT piLines AS INTEGER):
        DEFINE VARIABLE place AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        IF piScore = ? OR piScore < 1 THEN RETURN 0.
        Load().
        /* the place is after every score that is the same or better */
        place = mCount + 1.
        DO i = 1 TO mCount:
            IF mScore[i] < piScore THEN DO:
                place = i.
                LEAVE.
            END.
        END.
        IF place > ListSize() THEN RETURN 0.
        DO i = MINIMUM(mCount + 1, ListSize()) TO place + 1 BY -1:
            mScore[i] = mScore[i - 1].
            mLines[i] = mLines[i - 1].
        END.
        mScore[place] = piScore.
        mLines[place] = MAXIMUM(0, (IF piLines = ? THEN 0 ELSE piLines)).
        mCount = MINIMUM(mCount + 1, ListSize()).
        Store().
        RETURN place.
    END METHOD.

    /* Reads the settings. Anything that is not a score:lines pair with a score of 1 or more is dropped
       and the rest is put in order, so a hand edited file cannot break the list. */
    METHOD PRIVATE VOID Load():
        DEFINE VARIABLE raw   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE item  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE s     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE l     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER   NO-UNDO.
        mCount = 0.
        raw = mSettings:GetString("tetris.scores", "").
        DO i = 1 TO NUM-ENTRIES(raw):
            item = TRIM(ENTRY(i, raw)).
            IF NUM-ENTRIES(item, ":") <> 2 THEN NEXT.
            s = INTEGER(ENTRY(1, item, ":")) NO-ERROR.
            IF ERROR-STATUS:ERROR OR s = ? OR s < 1 THEN NEXT.
            l = INTEGER(ENTRY(2, item, ":")) NO-ERROR.
            IF ERROR-STATUS:ERROR OR l = ? OR l < 0 THEN NEXT.
            IF mCount >= ListSize() AND s <= mScore[mCount] THEN NEXT.
            IF mCount < ListSize() THEN mCount = mCount + 1.
            /* insert after any equal score */
            j = mCount.
            DO WHILE j > 1 AND mScore[j - 1] < s:
                mScore[j] = mScore[j - 1].
                mLines[j] = mLines[j - 1].
                j = j - 1.
            END.
            mScore[j] = s.
            mLines[j] = l.
        END.
    END METHOD.

    METHOD PRIVATE VOID Store():
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DO i = 1 TO mCount:
            result = result + (IF i > 1 THEN "," ELSE "") + SUBSTITUTE("&1:&2", mScore[i], mLines[i]).
        END.
        mSettings:SetString("tetris.scores", result).
    END METHOD.

    METHOD PRIVATE VOID CheckPlace(INPUT piPlace AS INTEGER):
        IF piPlace = ? OR piPlace < 1 OR piPlace > mCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("There is no score at place &1", piPlace)).
    END METHOD.

END CLASS.
