/* Test double: an opponent that fires the shots it is told to, in order, and records what it was
   told. Not a test class itself (the name does not end in Tests). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.ScriptedOpponent IMPLEMENTS IBattleshipsOpponent:

    DEFINE PRIVATE VARIABLE mShots AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE mNext  AS INTEGER   NO-UNDO INITIAL 1.

    DEFINE PUBLIC PROPERTY ResetCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ShotCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY ObserveCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastHit AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastSunk AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Width AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Height AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* pcShots is "x,y;x,y;..." in the order to fire them. */
    CONSTRUCTOR PUBLIC ScriptedOpponent(INPUT pcShots AS CHARACTER):
        mShots = pcShots.
    END CONSTRUCTOR.

    METHOD PUBLIC VOID Reset(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        ResetCount = ResetCount + 1.
        Width = piWidth.
        Height = piHeight.
        mNext = 1.
    END METHOD.

    METHOD PUBLIC VOID NextShot(OUTPUT piX AS INTEGER, OUTPUT piY AS INTEGER):
        IF mShots = "" OR mNext > NUM-ENTRIES(mShots, ";") THEN UNDO, THROW NEW GridException("The script has run out of shots").
        piX = INTEGER(ENTRY(1, ENTRY(mNext, mShots, ";"))).
        piY = INTEGER(ENTRY(2, ENTRY(mNext, mShots, ";"))).
        mNext = mNext + 1.
        ShotCount = ShotCount + 1.
    END METHOD.

    METHOD PUBLIC VOID Observe(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plHit AS LOGICAL, INPUT plSunk AS LOGICAL):
        ObserveCount = ObserveCount + 1.
        LastHit = plHit.
        LastSunk = plSunk.
    END METHOD.

    METHOD PUBLIC VOID Dispose():
    END METHOD.

END CLASS.
