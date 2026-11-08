/* The ten best games, kept in the settings as rogue.scores: one entry for each, "score|depth|cause|won" with 1 for a game that ended with
   the hero out of the dungeon, joined by semicolons and highest first. A game is added when it ends (Add gives its place, 1 to 10, or 0
   when it was not good enough) and the list is saved at once. The text of the list is what the tombstone screen shows. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueScores FINAL:

    VAR PRIVATE ISettings mSettings.
    VAR PRIVATE INTEGER[10] mScore.
    VAR PRIVATE INTEGER[10] mDepth.
    VAR PRIVATE CHARACTER[10] mCause.
    VAR PRIVATE LOGICAL[10] mWon.

    /* How many games are on the list. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Throws GridException for no settings. Reads the list, ignoring any entry that is damaged. */
    CONSTRUCTOR PUBLIC RogueScores(INPUT poSettings AS ISettings):
        VAR CHARACTER raw.
        VAR INTEGER i.
        VAR CHARACTER parts.
        VAR INTEGER score.
        VAR INTEGER depth.
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("The scores need settings to be kept in").
        mSettings = poSettings.
        raw = mSettings:GetString("rogue.scores", "").
        DO i = 1 TO NUM-ENTRIES(raw, ";"):
            parts = ENTRY(i, raw, ";").
            IF NUM-ENTRIES(parts, "|") = 4 AND Count < 10 THEN DO:
                score = INTEGER(ENTRY(1, parts, "|")) NO-ERROR.
                IF ERROR-STATUS:ERROR OR score = ? THEN NEXT.
                depth = INTEGER(ENTRY(2, parts, "|")) NO-ERROR.
                IF ERROR-STATUS:ERROR OR depth = ? THEN NEXT.
                Count = Count + 1.
                mScore[Count] = score.
                mDepth[Count] = depth.
                mCause[Count] = ENTRY(3, parts, "|").
                mWon[Count] = ENTRY(4, parts, "|") = "1".
            END.
        END.
    END CONSTRUCTOR.

    METHOD PUBLIC INTEGER ScoreAt(INPUT piPlace AS INTEGER):
        Require(piPlace).
        RETURN mScore[piPlace].
    END METHOD.

    METHOD PUBLIC INTEGER DepthAt(INPUT piPlace AS INTEGER):
        Require(piPlace).
        RETURN mDepth[piPlace].
    END METHOD.

    METHOD PUBLIC CHARACTER CauseAt(INPUT piPlace AS INTEGER):
        Require(piPlace).
        RETURN mCause[piPlace].
    END METHOD.

    METHOD PUBLIC LOGICAL WonAt(INPUT piPlace AS INTEGER):
        Require(piPlace).
        RETURN mWon[piPlace].
    END METHOD.

    /* A game as a line: "1.   1234  level 5  killed by a bat" (or "escaped with the amulet", "quit", "starved"). */
    METHOD PUBLIC CHARACTER Line(INPUT piPlace AS INTEGER):
        Require(piPlace).
        RETURN SUBSTITUTE("&1. &2  level &3  &4", STRING(piPlace, ">9"), STRING(mScore[piPlace], ">>>>>>9"), mDepth[piPlace], Ending(mWon[piPlace], mCause[piPlace])).
    END METHOD.

    /* How a game ended in words. */
    METHOD PUBLIC STATIC CHARACTER Ending(INPUT plWon AS LOGICAL, INPUT pcCause AS CHARACTER):
        IF plWon THEN RETURN "escaped with the Amulet of Yendor".
        IF pcCause = "quit" THEN RETURN "quit".
        IF pcCause = "starvation" THEN RETURN "starved to death".
        RETURN "killed by " + pcCause.
    END METHOD.

    /* Puts a game on the list if it is good enough, and saves the list. Gives the place (1 to 10), or 0 when it did not make it. */
    METHOD PUBLIC INTEGER Add(INPUT piScore AS INTEGER, INPUT piDepth AS INTEGER, INPUT pcCause AS CHARACTER, INPUT plWon AS LOGICAL):
        VAR INTEGER place.
        VAR INTEGER i.
        place = Count + 1.
        DO i = 1 TO Count:
            IF piScore > mScore[i] THEN DO:
                place = i.
                LEAVE.
            END.
        END.
        IF place > 10 THEN RETURN 0.
        DO i = MINIMUM(Count + 1, 10) TO place + 1 BY -1:
            mScore[i] = mScore[i - 1].
            mDepth[i] = mDepth[i - 1].
            mCause[i] = mCause[i - 1].
            mWon[i] = mWon[i - 1].
        END.
        mScore[place] = piScore.
        mDepth[place] = piDepth.
        mCause[place] = REPLACE(REPLACE(pcCause, "|", " "), ";", " ").
        mWon[place] = plWon.
        Count = MINIMUM(Count + 1, 10).
        Keep().
        RETURN place.
    END METHOD.

    /* The whole list as lines, one for each game, separated by CHR(10). Empty when nothing is on it. */
    METHOD PUBLIC CHARACTER Text():
        VAR INTEGER i.
        VAR CHARACTER result.
        DO i = 1 TO Count:
            result = result + (IF i > 1 THEN CHR(10) ELSE "") + Line(i).
        END.
        RETURN result.
    END METHOD.

    METHOD PRIVATE VOID Keep():
        VAR INTEGER i.
        VAR CHARACTER raw.
        DO i = 1 TO Count:
            raw = raw + (IF i > 1 THEN ";" ELSE "") + SUBSTITUTE("&1|&2|&3|&4", mScore[i], mDepth[i], mCause[i], (IF mWon[i] THEN "1" ELSE "0")).
        END.
        mSettings:SetString("rogue.scores", raw).
        mSettings:Save().
    END METHOD.

    METHOD PRIVATE VOID Require(INPUT piPlace AS INTEGER):
        IF piPlace = ? OR piPlace < 1 OR piPlace > Count THEN UNDO, THROW NEW GridException("There is no place " + STRING(piPlace) + " on the list of " + STRING(Count)).
    END METHOD.

END CLASS.
