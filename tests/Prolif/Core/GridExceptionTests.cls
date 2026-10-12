USING OpenEdge.Core.Assert.
USING Progress.Lang.AppError.
USING Prolif.Core.GridException.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.GridExceptionTests:

    @Test.
    METHOD PUBLIC VOID CarriesItsMessage():
        DEFINE VARIABLE e AS GridException NO-UNDO.
        e = NEW GridException("cell out of range").
        Assert:Equals("cell out of range", e:GetMessage(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IsAnAppError():
        Assert:IsTrue(TYPE-OF(NEW GridException("x"), AppError)).
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID CanBeThrownAndCaughtByType():
        UNDO, THROW NEW GridException("boom").
    END METHOD.

END CLASS.
