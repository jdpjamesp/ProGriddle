/* The shells in the air in Blast Buddies, kept in a fixed set of slots so no object is made while a shell flies. A slot has a place and a
   speed in 256ths of a pixel (a speed is that much a frame), a kind, the team that fired it and how many frames it has flown. Slots are
   numbered 1 to Capacity, and a slot that is not Active is free. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.ShellPool FINAL:

    &SCOPED-DEFINE SLOTS 8

    DEFINE PRIVATE VARIABLE mActive AS LOGICAL    NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mX      AS INTEGER    NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mY      AS INTEGER    NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mVX     AS INTEGER    NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mVY     AS INTEGER    NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mAge    AS INTEGER    NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mTeam   AS INTEGER    NO-UNDO EXTENT {&SLOTS}.
    DEFINE PRIVATE VARIABLE mKind   AS WeaponKind NO-UNDO EXTENT {&SLOTS}.

    /* How many shells can be in the air at once. */
    METHOD PUBLIC STATIC INTEGER Capacity():
        RETURN {&SLOTS}.
    END METHOD.

    /* How many shells are in the air. */
    METHOD PUBLIC INTEGER Count():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 1 TO {&SLOTS}:
            IF mActive[i] THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* Puts a shell in the air in a free slot and returns the slot. Throws when every slot is taken. */
    METHOD PUBLIC INTEGER Launch(INPUT poKind AS WeaponKind, INPUT piTeam AS INTEGER, INPUT piX256 AS INTEGER, INPUT piY256 AS INTEGER,
                                 INPUT piVx AS INTEGER, INPUT piVy AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poKind) THEN UNDO, THROW NEW GridException("A shell needs a kind").
        DO i = 1 TO {&SLOTS}:
            IF NOT mActive[i] THEN DO:
                mActive[i] = TRUE.
                mKind[i] = poKind.
                mTeam[i] = piTeam.
                mX[i] = piX256.
                mY[i] = piY256.
                mVX[i] = piVx.
                mVY[i] = piVy.
                mAge[i] = 0.
                RETURN i.
            END.
        END.
        UNDO, THROW NEW GridException("There is no room for another shell").
    END METHOD.

    METHOD PRIVATE VOID CheckSlot(INPUT piSlot AS INTEGER):
        IF piSlot < 1 OR piSlot > {&SLOTS} THEN UNDO, THROW NEW GridException("There is no shell slot " + STRING(piSlot)).
    END METHOD.

    /* Whether a slot holds a shell in the air. */
    METHOD PUBLIC LOGICAL Active(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mActive[piSlot].
    END METHOD.

    /* The place of the shell, in 256ths of a pixel. */
    METHOD PUBLIC INTEGER X(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mX[piSlot].
    END METHOD.

    METHOD PUBLIC INTEGER Y(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mY[piSlot].
    END METHOD.

    /* The speed of the shell, in 256ths of a pixel a frame. */
    METHOD PUBLIC INTEGER VX(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mVX[piSlot].
    END METHOD.

    METHOD PUBLIC INTEGER VY(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mVY[piSlot].
    END METHOD.

    /* How many frames the shell has flown. */
    METHOD PUBLIC INTEGER Age(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mAge[piSlot].
    END METHOD.

    /* The team that fired the shell. */
    METHOD PUBLIC INTEGER Team(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mTeam[piSlot].
    END METHOD.

    METHOD PUBLIC WeaponKind Kind(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mKind[piSlot].
    END METHOD.

    /* Moves the shell to a place with a speed. */
    METHOD PUBLIC VOID Move(INPUT piSlot AS INTEGER, INPUT piX256 AS INTEGER, INPUT piY256 AS INTEGER, INPUT piVx AS INTEGER, INPUT piVy AS INTEGER):
        CheckSlot(piSlot).
        mX[piSlot] = piX256.
        mY[piSlot] = piY256.
        mVX[piSlot] = piVx.
        mVY[piSlot] = piVy.
    END METHOD.

    /* Counts a frame of flight. */
    METHOD PUBLIC VOID Grow(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        mAge[piSlot] = mAge[piSlot] + 1.
    END METHOD.

    /* Takes the shell out of the air. */
    METHOD PUBLIC VOID Release(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        mActive[piSlot] = FALSE.
    END METHOD.

    /* Takes every shell out of the air. */
    METHOD PUBLIC VOID Clear():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO {&SLOTS}:
            mActive[i] = FALSE.
        END.
    END METHOD.

END CLASS.
