/* One team of buddies in Blast Buddies: up to 4 buddies, and whether a person or the computer plays them. The team keeps its own place in
   the rota, so each turn it plays the next living buddy after the one that played last. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.Team FINAL:

    DEFINE PRIVATE VARIABLE mBuddies AS Buddy   NO-UNDO EXTENT 4.
    DEFINE PRIVATE VARIABLE mCount   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLast    AS INTEGER NO-UNDO.

    /* 1 to 4. */
    DEFINE PUBLIC PROPERTY Number AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* True when the computer plays this team. */
    DEFINE PUBLIC PROPERTY IsComputer AS LOGICAL NO-UNDO GET. PRIVATE SET.

    CONSTRUCTOR PUBLIC Team(INPUT piIndex AS INTEGER, INPUT plComputer AS LOGICAL):
        IF piIndex < 1 OR piIndex > 4 THEN UNDO, THROW NEW GridException("A team is 1 to 4, not " + STRING(piIndex)).
        Number = piIndex.
        IsComputer = plComputer.
    END CONSTRUCTOR.

    /* Adds a buddy to the team. Throws when it is full or the buddy plays for another team. */
    METHOD PUBLIC VOID Add(INPUT poBuddy AS Buddy):
        IF NOT VALID-OBJECT(poBuddy) THEN UNDO, THROW NEW GridException("A team needs a buddy to add").
        IF poBuddy:Team <> Number THEN UNDO, THROW NEW GridException("This buddy is in team " + STRING(poBuddy:Team) + ", not " + STRING(Number)).
        IF mCount = 4 THEN UNDO, THROW NEW GridException("A team holds 4 buddies").
        mCount = mCount + 1.
        mBuddies[mCount] = poBuddy.
    END METHOD.

    /* How many buddies the team started with. */
    METHOD PUBLIC INTEGER Count():
        RETURN mCount.
    END METHOD.

    /* A buddy of the team, 1 to Count(). */
    METHOD PUBLIC Buddy BuddyAt(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > mCount THEN UNDO, THROW NEW GridException("There is no buddy " + STRING(piIndex) + " in team " + STRING(Number)).
        RETURN mBuddies[piIndex].
    END METHOD.

    /* How many of its buddies are still alive. */
    METHOD PUBLIC INTEGER AliveCount():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 1 TO mCount:
            IF NOT mBuddies[i]:IsDead() THEN n = n + 1.
        END.
        RETURN n.
    END METHOD.

    /* The sum of the health of the living buddies, which the team bars show. */
    METHOD PUBLIC INTEGER TotalHealth():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO i = 1 TO mCount:
            IF NOT mBuddies[i]:IsDead() THEN n = n + mBuddies[i]:Health.
        END.
        RETURN n.
    END METHOD.

    /* The next living buddy in the rota, after the one that played last. Unknown when the whole team is dead. */
    METHOD PUBLIC Buddy NextBuddy():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DO i = 1 TO mCount:
            k = ((mLast + i - 1) MODULO mCount) + 1.
            IF NOT mBuddies[k]:IsDead() THEN DO:
                mLast = k.
                RETURN mBuddies[k].
            END.
        END.
        RETURN ?.
    END METHOD.

END CLASS.
