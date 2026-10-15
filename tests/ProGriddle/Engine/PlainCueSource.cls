/* Test double: a cue source that has no loops and never has a cue. Not a test class itself (the name does not end in Tests). */
USING Progress.Lang.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.PlainCueSource IMPLEMENTS ICueSource:

    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        RETURN "".
    END METHOD.

    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        RETURN 1.
    END METHOD.

END CLASS.
