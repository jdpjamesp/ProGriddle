/* A player that is not a person: it is given every frame of its turn and uses the same controls a person has (walk, aim, charge, release).
   The game runs it for the teams the computer plays. */
USING ProGriddle.Games.BlastBuddies.*.

INTERFACE ProGriddle.Games.BlastBuddies.IBuddyBrain:

    /* True while it is trying shots, which the picture shows as a thought bubble over the buddy. */
    DEFINE PUBLIC PROPERTY Thinking AS LOGICAL NO-UNDO
        GET.

    /* What it is doing now. */
    DEFINE PUBLIC PROPERTY Stage AS BrainStage NO-UNDO
        GET.

    /* How well it plays. It can be changed between turns. */
    DEFINE PUBLIC PROPERTY Skill AS BuddySkill NO-UNDO
        GET.
        SET.

    /* A new turn: forget the last one. */
    METHOD PUBLIC VOID Reset().

    /* One frame of the turn of the buddy in play. Does only a small slice of work, so the window never waits for it. */
    METHOD PUBLIC VOID Drive(INPUT poGame AS BlastBuddiesGame).

END INTERFACE.
