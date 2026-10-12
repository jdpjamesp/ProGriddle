USING Progress.Lang.*.
USING OpenEdge.Core.Assert.
USING Prolif.Smoke.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.SmokeTests:
    @Test.
    METHOD PUBLIC VOID AddsTwoNumbers():
        DEFINE VARIABLE s AS Smoke NO-UNDO.
        s = NEW Smoke().
        Assert:Equals(5, s:Add(2, 3)).
    END METHOD.
END CLASS.
