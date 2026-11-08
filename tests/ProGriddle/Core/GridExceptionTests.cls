USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Core.GridExceptionTests:

    @Test.
    METHOD PUBLIC VOID CarriesItsMessage():
        VAR GridException e = NEW GridException("cell out of range").
        Assert:Equals("cell out of range", e:GetMessage(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IsAnAppError():
        Assert:IsTrue(TYPE-OF(NEW GridException("x"), AppError)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID CanBeThrownAndCaughtByType():
        UNDO, THROW NEW GridException("boom").
    END METHOD.

END CLASS.
