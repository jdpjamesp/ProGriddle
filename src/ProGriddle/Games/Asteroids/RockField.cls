/* The rocks of an Asteroids game: up to 64 slots, each with a size (1 large, 2 medium, 3 small, 0 for a free slot), a
   position and a velocity in 4096ths of a cell, which outline it has, which way it points and how fast it spins. They
   move on a screen of 320 x 240 cells that wraps on all four edges. A new rock flashes white for its first six frames.
   The field only moves and keeps the rocks: what hits what, and what a rock breaks into, is for the game. A slot
   number is 0 to 63 and stays the same for the life of a rock, so the game can find a rock again. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.RockField FINAL:

    &SCOPED-DEFINE SLOTS 64
    &SCOPED-DEFINE WIDTH-U 1310720
    &SCOPED-DEFINE HEIGHT-U 983040

    DEFINE PRIVATE VARIABLE mSize    AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mX       AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mY       AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mVX      AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mVY      AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mVariant AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mHead    AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mPeriod  AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mSpinDir AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mSpinAcc AS INTEGER NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mFlash   AS INTEGER NO-UNDO EXTENT {&SLOTS}.

    /* How many rocks there are. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The number of slots: the most rocks there can be. A game never has more than 44. */
    METHOD PUBLIC STATIC INTEGER Capacity():
        RETURN {&SLOTS}.
    END METHOD.

    /* Puts a rock in the first free slot and gives the slot number. Size is 1 large, 2 medium or 3 small, the variant
       picks one of its outlines (any number will do), the heading is its first direction, and it turns one step every
       piPeriod frames (1 or more) in the direction piSpinDir (-1 or 1). Throws GridException for anything else, and
       when the field is full. */
    METHOD PUBLIC INTEGER Add(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piVX AS INTEGER, INPUT piVY AS INTEGER,
                              INPUT piSize AS INTEGER, INPUT piVariant AS INTEGER, INPUT piHeading AS INTEGER,
                              INPUT piPeriod AS INTEGER, INPUT piSpinDir AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF piSize = ? OR piSize < 1 OR piSize > 3 THEN UNDO, THROW NEW GridException("A rock size is 1, 2 or 3, not " + STRING(piSize)).
        IF piPeriod = ? OR piPeriod < 1 THEN UNDO, THROW NEW GridException("A rock spins a step every 1 or more frames, not " + STRING(piPeriod)).
        IF piSpinDir <> 1 AND piSpinDir <> -1 THEN UNDO, THROW NEW GridException("A rock spins -1 or 1, not " + STRING(piSpinDir)).
        DO i = 1 TO {&SLOTS}:
            IF mSize[i] = 0 THEN DO:
                mSize[i] = piSize.
                mX[i] = piX.
                mY[i] = piY.
                mVX[i] = piVX.
                mVY[i] = piVY.
                mVariant[i] = (IF piVariant = ? THEN 0 ELSE ABSOLUTE(piVariant)).
                mHead[i] = Heading:Wrap(piHeading).
                mPeriod[i] = piPeriod.
                mSpinDir[i] = piSpinDir.
                mSpinAcc[i] = 0.
                mFlash[i] = 6.
                Count = Count + 1.
                RETURN i - 1.
            END.
        END.
        UNDO, THROW NEW GridException("The field is full: there is no room for another rock").
    END METHOD.

    /* Takes a rock out. The slot is free again. Taking out a free slot does nothing. */
    METHOD PUBLIC VOID Remove(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        IF mSize[piSlot + 1] > 0 THEN DO:
            mSize[piSlot + 1] = 0.
            Count = Count - 1.
        END.
    END METHOD.

    /* Takes every rock out. */
    METHOD PUBLIC VOID Clear():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&SLOTS}:
            mSize[i] = 0.
        END.
        Count = 0.
    END METHOD.

    /* One frame: every rock moves by its velocity and wraps, turns when its turn comes, and its flash runs down. */
    METHOD PUBLIC VOID Move():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        DO i = 1 TO {&SLOTS}:
            IF mSize[i] = 0 THEN NEXT.
            v = (mX[i] + mVX[i]) MODULO {&WIDTH-U}.
            IF v < 0 THEN v = v + {&WIDTH-U}.
            mX[i] = v.
            v = (mY[i] + mVY[i]) MODULO {&HEIGHT-U}.
            IF v < 0 THEN v = v + {&HEIGHT-U}.
            mY[i] = v.
            mSpinAcc[i] = mSpinAcc[i] + 1.
            IF mSpinAcc[i] >= mPeriod[i] THEN DO:
                mSpinAcc[i] = 0.
                mHead[i] = Heading:Wrap(mHead[i] + mSpinDir[i]).
            END.
            IF mFlash[i] > 0 THEN mFlash[i] = mFlash[i] - 1.
        END.
    END METHOD.

    /* True when the slot holds a rock. */
    METHOD PUBLIC LOGICAL Alive(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mSize[piSlot + 1] > 0.
    END METHOD.

    /* The size of the rock in a slot, 1 to 3, or 0 for a free slot. */
    METHOD PUBLIC INTEGER SizeAt(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mSize[piSlot + 1].
    END METHOD.

    /* How many rocks of a size there are. */
    METHOD PUBLIC INTEGER CountOfSize(INPUT piSize AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 1 TO {&SLOTS}:
            IF mSize[i] = piSize THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* The position of a rock in 4096ths of a cell. */
    METHOD PUBLIC INTEGER X(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mX[piSlot + 1].
    END METHOD.

    METHOD PUBLIC INTEGER Y(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mY[piSlot + 1].
    END METHOD.

    /* The velocity of a rock in 4096ths of a cell a frame. */
    METHOD PUBLIC INTEGER VX(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mVX[piSlot + 1].
    END METHOD.

    METHOD PUBLIC INTEGER VY(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mVY[piSlot + 1].
    END METHOD.

    /* Which outline of its size the rock has (any whole number: AsteroidsArt wraps it round). */
    METHOD PUBLIC INTEGER Variant(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mVariant[piSlot + 1].
    END METHOD.

    /* The way the rock is turned now, 0 to 63. */
    METHOD PUBLIC INTEGER HeadingAt(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mHead[piSlot + 1].
    END METHOD.

    /* How many frames of its white flash a new rock has left, 6 down to 0. */
    METHOD PUBLIC INTEGER Flash(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mFlash[piSlot + 1].
    END METHOD.

    METHOD PRIVATE VOID CheckSlot(INPUT piSlot AS INTEGER):
        IF piSlot = ? OR piSlot < 0 OR piSlot >= {&SLOTS} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A rock slot is 0 to &1, not &2", {&SLOTS} - 1, piSlot)).
    END METHOD.

END CLASS.
