/* The seven bag randomiser: the seven pieces are shuffled and dealt one at a time, and when the bag
   is empty a freshly shuffled one takes its place. So every piece comes round once in every seven,
   at most 12 other pieces come between two of the same, and the same piece never comes more than twice in a row. The
   shuffle uses the IRandom it is given, so a seeded one deals the same pieces every time.

   Preset puts named pieces in front of the bag, for tests. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.PieceBag FINAL:

    DEFINE PRIVATE VARIABLE mRandom AS IRandom NO-UNDO.
    DEFINE PRIVATE VARIABLE mBag    AS INTEGER NO-UNDO EXTENT 7.
    /* the next piece to deal is mBag[mPos], and 8 means the bag is empty */
    DEFINE PRIVATE VARIABLE mPos    AS INTEGER NO-UNDO INITIAL 8.
    DEFINE PRIVATE VARIABLE mPreset AS CHARACTER NO-UNDO.

    CONSTRUCTOR PUBLIC PieceBag(INPUT poRandom AS IRandom):
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A piece bag needs a random source").
        mRandom = poRandom.
    END CONSTRUCTOR.

    /* The next piece, 1 to 7. */
    METHOD PUBLIC INTEGER Next():
        DEFINE VARIABLE piece AS INTEGER NO-UNDO.
        IF mPreset <> "" THEN DO:
            piece = INTEGER(ENTRY(1, mPreset)).
            mPreset = (IF NUM-ENTRIES(mPreset) > 1 THEN SUBSTRING(mPreset, INDEX(mPreset, ",") + 1) ELSE "").
            RETURN piece.
        END.
        IF mPos > 7 THEN Refill().
        piece = mBag[mPos].
        mPos = mPos + 1.
        RETURN piece.
    END METHOD.

    /* Puts these pieces, named as in "I,O,T", in front of everything else, in order. Throws
       GridException for a name that is not a piece. */
    METHOD PUBLIC VOID Preset(INPUT pcNames AS CHARACTER):
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE added AS CHARACTER NO-UNDO.
        IF pcNames = ? OR pcNames = "" THEN RETURN.
        DO i = 1 TO NUM-ENTRIES(pcNames):
            added = added + (IF i > 1 THEN "," ELSE "") + STRING(Tetrominoes:PieceOf(ENTRY(i, pcNames))).
        END.
        mPreset = (IF mPreset = "" THEN added ELSE added + "," + mPreset).
    END METHOD.

    /* Shuffles the seven pieces into the bag, a Fisher-Yates shuffle. */
    METHOD PRIVATE VOID Refill():
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE j    AS INTEGER NO-UNDO.
        DEFINE VARIABLE swap AS INTEGER NO-UNDO.
        DO i = 1 TO 7:
            mBag[i] = i.
        END.
        DO i = 7 TO 2 BY -1:
            j = mRandom:NextInt(i) + 1.
            swap = mBag[i].
            mBag[i] = mBag[j].
            mBag[j] = swap.
        END.
        mPos = 1.
    END METHOD.

END CLASS.
