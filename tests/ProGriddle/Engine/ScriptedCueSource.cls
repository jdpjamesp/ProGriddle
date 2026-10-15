/* Test double: a cue source that returns the cues a test has put in Next on the next poll (and then none), and remembers the
   game it was given. Its priority group of a cue is the cue divided by ten, so 11 and 12 share a group and 21 has another. Not a
   test class itself (the name does not end in Tests). */
USING Progress.Lang.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.ScriptedCueSource IMPLEMENTS ICueSource, ILoopSource:

    /* The comma list the next poll returns. */
    DEFINE PUBLIC PROPERTY NextCues AS CHARACTER NO-UNDO
        GET.
        SET.

    /* The comma list Loops returns every time, until it is changed. */
    DEFINE PUBLIC PROPERTY WantedLoops AS CHARACTER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY PollCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastGame AS IGame NO-UNDO
        GET.
        PRIVATE SET.

    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        PollCount = PollCount + 1.
        LastGame = poGame.
        result = NextCues.
        NextCues = "".
        RETURN result.
    END METHOD.

    METHOD PUBLIC CHARACTER Loops(INPUT poGame AS IGame):
        RETURN WantedLoops.
    END METHOD.

    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        RETURN INTEGER(TRUNCATE(piCue / 10, 0)).
    END METHOD.

END CLASS.
