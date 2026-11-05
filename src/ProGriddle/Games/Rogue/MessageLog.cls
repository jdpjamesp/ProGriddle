/* The things the game tells the hero. Everything said during one turn is kept together so the message line can show it as one line
   ("You hit the bat.  The bat misses you."), and every message is also kept in a history of the last hundred that can be looked
   through. When the messages of a turn are too long for the line, the oldest are left off (they are still in the history). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.MessageLog FINAL:

    &SCOPED-DEFINE KEEP 100
    &SCOPED-DEFINE PER-TURN 20

    /* the history, newest in the highest slot used, and this turn's messages */
    DEFINE PRIVATE VARIABLE mHistory AS CHARACTER NO-UNDO EXTENT {&KEEP}.
    DEFINE PRIVATE VARIABLE mTurn    AS CHARACTER NO-UNDO EXTENT {&PER-TURN}.
    DEFINE PRIVATE VARIABLE mNext    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mTurnN   AS INTEGER   NO-UNDO.

    /* How many messages the history holds (at most 100). */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* How many messages have been said since BeginTurn. */
    DEFINE PUBLIC PROPERTY TurnCount AS INTEGER NO-UNDO
        GET():
            RETURN mTurnN.
        END GET.

    /* Says a message: it joins this turn's line and the history. An empty message is ignored. */
    METHOD PUBLIC VOID Add(INPUT pcText AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF pcText = ? OR pcText = "" THEN RETURN.
        mNext = mNext MODULO {&KEEP} + 1.
        mHistory[mNext] = pcText.
        Count = MINIMUM(Count + 1, {&KEEP}).
        IF mTurnN >= {&PER-TURN} THEN DO:
            /* the oldest of the turn goes, the rest move up */
            DO i = 1 TO {&PER-TURN} - 1:
                mTurn[i] = mTurn[i + 1].
            END.
            mTurnN = {&PER-TURN} - 1.
        END.
        mTurnN = mTurnN + 1.
        mTurn[mTurnN] = pcText.
    END METHOD.

    /* Starts a new turn: the message line is empty again (the history is kept). */
    METHOD PUBLIC VOID BeginTurn():
        mTurnN = 0.
    END METHOD.

    /* This turn's messages as one line no longer than piWidth: the newest messages that fit whole, separated by two spaces. When even the
       newest does not fit it is cut. Empty when nothing has been said this turn. */
    METHOD PUBLIC CHARACTER Line(INPUT piWidth AS INTEGER):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        IF mTurnN = 0 THEN RETURN "".
        DO i = mTurnN TO 1 BY -1:
            IF result = "" THEN result = mTurn[i].
            ELSE IF LENGTH(mTurn[i]) + 2 + LENGTH(result) <= piWidth THEN result = mTurn[i] + "  " + result.
            ELSE LEAVE.
        END.
        RETURN SUBSTRING(result, 1, piWidth).
    END METHOD.

    /* A message from the history: 0 is the newest, 1 the one before. Throws GridException for a place the history does not reach. */
    METHOD PUBLIC CHARACTER At(INPUT piBack AS INTEGER):
        DEFINE VARIABLE slot AS INTEGER NO-UNDO.
        IF piBack = ? OR piBack < 0 OR piBack >= Count THEN UNDO, THROW NEW GridException("There is no message " + STRING(piBack) + " back").
        slot = (mNext - 1 - piBack) MODULO {&KEEP}.
        IF slot < 0 THEN slot = slot + {&KEEP}.
        RETURN mHistory[slot + 1].
    END METHOD.

    /* Forgets everything: the history and this turn. */
    METHOD PUBLIC VOID Clear():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&KEEP}:
            mHistory[i] = "".
        END.
        mNext = 0.
        Count = 0.
        mTurnN = 0.
    END METHOD.

END CLASS.
