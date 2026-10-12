/* The high score list for each of the three standard levels: the ten fastest winning times,
   in seconds, fastest first. Each list is kept in the settings as a comma separated string
   under "minesweeper.scores.beginner", "minesweeper.scores.intermediate" and
   "minesweeper.scores.expert", for example "47,52,52,96". Custom games keep no list, as in
   Windows. A time that ties an older one ranks below it. The best time is the head of the list. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperBestTimes FINAL:

    DEFINE PRIVATE VARIABLE mSettings AS ISettings NO-UNDO.

    /* How many sorted a level keeps. */
    METHOD PUBLIC STATIC INTEGER ListSize():
        RETURN 10.
    END METHOD.

    CONSTRUCTOR PUBLIC MinesweeperBestTimes(INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Best sorted need settings").
        mSettings = poSettings.
    END CONSTRUCTOR.

    /* The fastest time for a level, or 0 when there is none yet or the level is Custom. Throws
       GridException for a level that does not exist. */
    METHOD PUBLIC INTEGER Best(INPUT pcLevel AS CHARACTER):
        DEFINE VARIABLE entries AS CHARACTER NO-UNDO.
        entries = Scores(pcLevel).
        IF entries = "" THEN RETURN 0.
        RETURN INTEGER(ENTRY(1, entries)).
    END METHOD.

    /* The high score list of a level as comma separated seconds, fastest first, or an empty
       string when it is empty or the level is Custom. Anything in the settings that is not a
       time from 1 to 999 is dropped and the rest is put in order. Throws GridException for a
       level that does not exist. */
    METHOD PUBLIC CHARACTER Scores(INPUT pcLevel AS CHARACTER):
        DEFINE VARIABLE raw    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE sorted AS INTEGER   NO-UNDO EXTENT 10.
        DEFINE VARIABLE n      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE t  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        CheckLevel(pcLevel).
        IF NOT MinesweeperLevels:IsStandard(pcLevel) THEN RETURN "".
        raw = mSettings:GetString(KeyOf(pcLevel), "").
        DO i = 1 TO NUM-ENTRIES(raw):
            t = INTEGER(TRIM(ENTRY(i, raw))) NO-ERROR.
            IF ERROR-STATUS:ERROR OR t = ? OR t < 1 OR t > 999 OR n >= ListSize() THEN NEXT.
            /* insert in order, after any equal time */
            n = n + 1.
            j = n.
            DO WHILE j > 1 AND sorted[j - 1] > t:
                sorted[j] = sorted[j - 1].
                j = j - 1.
            END.
            sorted[j] = t.
        END.
        DO i = 1 TO n:
            result = result + (IF i > 1 THEN "," ELSE "") + STRING(sorted[i]).
        END.
        RETURN result.
    END METHOD.

    /* How many sorted are on a level's scores. */
    METHOD PUBLIC INTEGER Count(INPUT pcLevel AS CHARACTER):
        DEFINE VARIABLE entries AS CHARACTER NO-UNDO.
        entries = Scores(pcLevel).
        IF entries = "" THEN RETURN 0.
        RETURN NUM-ENTRIES(entries).
    END METHOD.

    /* Adds a winning time to the scores. Returns its place, 1 for a new best, or 0 when it did
       not make the list: a Custom game, a time outside 1 to 999 seconds, or one that is no
       faster than the slowest of a full scores. Throws GridException for an unknown level. */
    METHOD PUBLIC INTEGER Record(INPUT pcLevel AS CHARACTER, INPUT piSeconds AS INTEGER):
        DEFINE VARIABLE entries  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE place AS INTEGER   NO-UNDO.
        DEFINE VARIABLE merged  AS CHARACTER NO-UNDO.
        CheckLevel(pcLevel).
        IF NOT MinesweeperLevels:IsStandard(pcLevel) THEN RETURN 0.
        IF piSeconds = ? OR piSeconds < 1 OR piSeconds > 999 THEN RETURN 0.
        entries = Scores(pcLevel).
        /* the place is after every time that is the same or faster */
        place = 1.
        DO i = 1 TO (IF entries = "" THEN 0 ELSE NUM-ENTRIES(entries)):
            IF INTEGER(ENTRY(i, entries)) <= piSeconds THEN place = i + 1.
        END.
        IF place > ListSize() THEN RETURN 0.
        DO i = 1 TO MINIMUM(ListSize(), (IF entries = "" THEN 0 ELSE NUM-ENTRIES(entries)) + 1):
            IF i < place THEN merged = merged + (IF i > 1 THEN "," ELSE "") + ENTRY(i, entries).
            ELSE IF i = place THEN merged = merged + (IF i > 1 THEN "," ELSE "") + STRING(piSeconds).
            ELSE merged = merged + "," + ENTRY(i - 1, entries).
        END.
        mSettings:SetString(KeyOf(pcLevel), merged).
        RETURN place.
    END METHOD.

    METHOD PRIVATE CHARACTER KeyOf(INPUT pcLevel AS CHARACTER):
        RETURN "minesweeper.scores." + LC(MinesweeperLevels:Canonical(pcLevel)).
    END METHOD.

    METHOD PRIVATE VOID CheckLevel(INPUT pcLevel AS CHARACTER):
        IF MinesweeperLevels:Canonical(pcLevel) = "" THEN
            UNDO, THROW NEW GridException("Unknown Minesweeper level: " + STRING(pcLevel)).
    END METHOD.

END CLASS.
