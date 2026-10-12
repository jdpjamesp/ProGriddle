/* InfoDialog needs the .NET bridge, so these run under prowin -b (tools/run-tests.ps1 -Gui). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.InfoDialogTests:

    @Test.
    METHOD PUBLIC VOID TheTitleAndTheTextAreShown():
        DEFINE VARIABLE d AS InfoDialog NO-UNDO.
        DO ON ERROR UNDO, THROW:
            d = NEW InfoDialog("Scores", "one" + CHR(10) + "two").
            Assert:Equals("Scores", d:Text).
            Assert:Equals("one" + CHR(13) + CHR(10) + "two", d:Body).
            FINALLY:
                IF VALID-OBJECT(d) THEN d:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnterAndEscapeBothCloseItThroughTheOkButton():
        DEFINE VARIABLE d AS InfoDialog NO-UNDO.
        DO ON ERROR UNDO, THROW:
            d = NEW InfoDialog("Scores", "text").
            Assert:IsTrue(VALID-OBJECT(d:AcceptButton)).
            Assert:IsTrue(VALID-OBJECT(d:CancelButton)).
            Assert:IsTrue(d:AcceptButton = d:CancelButton).
            FINALLY:
                IF VALID-OBJECT(d) THEN d:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EmptyTextIsAllowed():
        DEFINE VARIABLE d AS InfoDialog NO-UNDO.
        DO ON ERROR UNDO, THROW:
            d = NEW InfoDialog("Scores", "").
            Assert:Equals("", d:Body).
            FINALLY:
                IF VALID-OBJECT(d) THEN d:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ADialogNeedsATitle():
        DEFINE VARIABLE d AS InfoDialog NO-UNDO.
        d = NEW InfoDialog("", "text").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ADialogNeedsSomeText():
        DEFINE VARIABLE d AS InfoDialog NO-UNDO.
        d = NEW InfoDialog("Scores", ?).
    END METHOD.

END CLASS.
