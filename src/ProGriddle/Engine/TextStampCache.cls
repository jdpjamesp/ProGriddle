/* A handful of text stamps kept ready, so a game that draws the same words and numbers every frame makes each one once. Get
   gives the stamp for some text at a scale in a colour (top to bottom, with an edge or -1 for none), making it the first
   time it is asked for. When the cache is full the oldest stamp is freed to make room for a new one. A game whose numbers
   change (a score) simply asks for the new number: the old one ages out. The owner calls Dispose, which frees every
   stamp (a stamp owns memory), and must not draw a stamp after the cache that gave it has been disposed of or has
   dropped it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.TextStampCache FINAL:

    DEFINE PRIVATE VARIABLE mStamp AS TextStamp NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mKey   AS CHARACTER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mSlots AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mNext  AS INTEGER   NO-UNDO.

    /* How many stamps are kept now. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO mSlots:
                IF VALID-OBJECT(mStamp[i]) THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* Throws GridException for fewer than one slot. */
    CONSTRUCTOR PUBLIC TextStampCache(INPUT piSlots AS INTEGER):
        IF piSlots = ? OR piSlots < 1 THEN UNDO, THROW NEW GridException("A text stamp cache has 1 slot or more, not " + STRING(piSlots)).
        mSlots = piSlots.
        EXTENT(mStamp) = piSlots.
        EXTENT(mKey) = piSlots.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC TextStampCache():
        Dispose().
    END DESTRUCTOR.

    /* The stamp for some text, made if there is not one already. See TextStamp for the arguments. */
    METHOD PUBLIC TextStamp Get(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT piTop AS INTEGER, INPUT piBottom AS INTEGER, INPUT piEdge AS INTEGER):
        DEFINE VARIABLE key AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER   NO-UNDO.
        key = SUBSTITUTE("&1|&2|&3|&4|&5", pcText, piScale, piTop, piBottom, piEdge).
        DO i = 1 TO mSlots:
            IF mKey[i] = key AND VALID-OBJECT(mStamp[i]) THEN RETURN mStamp[i].
        END.
        mNext = mNext MODULO mSlots + 1.
        IF VALID-OBJECT(mStamp[mNext]) THEN mStamp[mNext]:Dispose().
        mStamp[mNext] = NEW TextStamp(pcText, piScale, piTop, piBottom, piEdge).
        mKey[mNext] = key.
        RETURN mStamp[mNext].
    END METHOD.

    /* Frees every stamp. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mSlots:
            IF VALID-OBJECT(mStamp[i]) THEN mStamp[i]:Dispose().
            mStamp[i] = ?.
            mKey[i] = "".
        END.
    END METHOD.

END CLASS.
