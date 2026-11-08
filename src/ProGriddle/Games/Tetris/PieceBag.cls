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

    VAR PRIVATE IRandom mRandom.
    VAR PRIVATE INTEGER[7] mBag.
    /* the next piece to deal is mBag[mPos], and 8 means the bag is empty */
    VAR PRIVATE INTEGER mPos = 8.
    VAR PRIVATE CHARACTER mPreset.

    CONSTRUCTOR PUBLIC PieceBag(INPUT poRandom AS IRandom):
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A piece bag needs a random source").
        mRandom = poRandom.
    END CONSTRUCTOR.

    /* The next piece, 1 to 7. */
    METHOD PUBLIC INTEGER Next():
        VAR INTEGER piece.
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
        VAR INTEGER i.
        VAR CHARACTER added.
        IF pcNames = ? OR pcNames = "" THEN RETURN.
        DO i = 1 TO NUM-ENTRIES(pcNames):
            added = added + (IF i > 1 THEN "," ELSE "") + STRING(Tetrominoes:PieceOf(ENTRY(i, pcNames))).
        END.
        mPreset = (IF mPreset = "" THEN added ELSE added + "," + mPreset).
    END METHOD.

    /* Shuffles the seven pieces into the bag, a Fisher-Yates shuffle. */
    METHOD PRIVATE VOID Refill():
        VAR INTEGER i.
        VAR INTEGER j.
        VAR INTEGER swap.
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
