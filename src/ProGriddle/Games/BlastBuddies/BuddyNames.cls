/* The names buddies are given, short ones that the 5 x 7 font can draw (capital letters only, 8 or fewer). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddyNames FINAL:

    DEFINE PRIVATE STATIC VARIABLE sNames AS CHARACTER NO-UNDO INITIAL
        "BOLT,TAD,LOU,MAX,ZIP,DOT,GUS,PIP,NED,FLO,RUFUS,COG,BUD,TOT,KIP,MOE,ROY,SAL,VIC,WALT,YORK,ZED,BOO,JAX".

    /* How many names there are. */
    METHOD PUBLIC STATIC INTEGER Count():
        RETURN NUM-ENTRIES(sNames).
    END METHOD.

    /* The name at a place in the list, 1 to Count(). */
    METHOD PUBLIC STATIC CHARACTER NameAt(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > Count() THEN UNDO, THROW NEW GridException("There is no buddy name " + STRING(piIndex)).
        RETURN ENTRY(piIndex, sNames).
    END METHOD.

END CLASS.
