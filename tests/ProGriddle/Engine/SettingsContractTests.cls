/* What every ISettings must do. Each test runs once per implementation (memory and JSON
   file) and a failure names which. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SettingsContractTests:

    METHOD PRIVATE INTEGER KindCount():
        RETURN 2.
    END METHOD.

    METHOD PRIVATE CHARACTER KindName(INPUT piKind AS INTEGER):
        RETURN (IF piKind = 1 THEN "MemorySettings" ELSE "JsonFileSettings").
    END METHOD.

    METHOD PRIVATE ISettings Make(INPUT piKind AS INTEGER):
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        IF piKind = 1 THEN RETURN NEW MemorySettings().
        OS-CREATE-DIR VALUE("build/test-settings").
        path = "build/test-settings/contract.json".
        IF SEARCH(path) <> ? THEN OS-DELETE VALUE(path).
        RETURN NEW JsonFileSettings(path).
    END METHOD.

    METHOD PRIVATE VOID Rethrow(INPUT piKind AS INTEGER, INPUT poError AS Progress.Lang.Error):
        UNDO, THROW NEW AppError(SUBSTITUTE("[&1] &2", KindName(piKind), poError:GetMessage(1)), 0).
    END METHOD.

    /* True when setting the key to a value (or reading it) throws GridException. */
    METHOD PRIVATE LOGICAL KeyIsRejected(INPUT poSettings AS ISettings, INPUT pcKey AS CHARACTER):
        DO ON ERROR UNDO, THROW:
            poSettings:SetInteger(pcKey, 1).
            CATCH ge AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
        RETURN FALSE.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMissingKeyGivesTheDefaultOfEachType():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            Assert:Equals("fallback", s:GetString("life.pattern", "fallback")).
            Assert:Equals(7, s:GetInteger("life.speed", 7)).
            Assert:Equals(0.25, s:GetDecimal("life.density", 0.25)).
            Assert:IsTrue(s:GetLogical("life.wrap", TRUE)).
            Assert:IsFalse(s:GetLogical("life.wrap", FALSE)).
            Assert:IsFalse(s:Has("life.speed")).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASetValueIsReadBackOfEachType():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            s:SetString("life.pattern", "Glider").
            s:SetInteger("life.speed", 4).
            s:SetDecimal("life.density", 0.35).
            s:SetLogical("life.wrap", TRUE).
            Assert:Equals("Glider", s:GetString("life.pattern", "x")).
            Assert:Equals(4, s:GetInteger("life.speed", 0)).
            Assert:Equals(0.35, s:GetDecimal("life.density", 0)).
            Assert:IsTrue(s:GetLogical("life.wrap", FALSE)).
            Assert:IsTrue(s:Has("life.pattern")).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NegativeZeroAndFalseValuesAreRealValuesNotMissing():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            s:SetInteger("window.x", -12).
            s:SetInteger("life.generation", 0).
            s:SetLogical("life.wrap", FALSE).
            s:SetString("life.note", "").
            Assert:Equals(-12, s:GetInteger("window.x", 99)).
            Assert:Equals(0, s:GetInteger("life.generation", 99)).
            Assert:IsFalse(s:GetLogical("life.wrap", TRUE)).
            Assert:Equals("", s:GetString("life.note", "default")).
            Assert:IsTrue(s:Has("life.generation")).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SettingAgainReplacesTheValueEvenWithAnotherType():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            s:SetInteger("life.speed", 4).
            s:SetInteger("life.speed", 5).
            Assert:Equals(5, s:GetInteger("life.speed", 0)).
            s:SetString("life.speed", "fast").
            Assert:Equals("fast", s:GetString("life.speed", "")).
            Assert:Equals(0, s:GetInteger("life.speed", 0)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AValueOfAnotherTypeGivesTheDefaultInsteadOfFailing():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            s:SetString("life.speed", "fast").
            s:SetInteger("life.pattern", 3).
            s:SetLogical("life.density", TRUE).
            Assert:Equals(11, s:GetInteger("life.speed", 11)).
            Assert:Equals("none", s:GetString("life.pattern", "none")).
            Assert:Equals(0.5, s:GetDecimal("life.density", 0.5)).
            Assert:IsFalse(s:GetLogical("life.pattern", FALSE)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFractionalNumberIsNotAnInteger():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            s:SetDecimal("life.density", 2.5).
            Assert:Equals(9, s:GetInteger("life.density", 9)).
            Assert:Equals(2.5, s:GetDecimal("life.density", 0)).
            s:SetDecimal("life.whole", 3.0).
            Assert:Equals(3, s:GetInteger("life.whole", 9)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID KeysAreIndependentOfEachOther():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            s:SetInteger("life.speed", 2).
            s:SetInteger("tetris.speed", 8).
            Assert:Equals(2, s:GetInteger("life.speed", 0)).
            Assert:Equals(8, s:GetInteger("tetris.speed", 0)).
            Assert:IsFalse(s:Has("life.size")).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStringsKeepQuotesBackslashesAndAccents():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DEFINE VARIABLE v AS CHARACTER NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            v = 'say "hi" c:~\temp~\file é'.
            s:SetString("life.note", v).
            Assert:Equals(v, s:GetString("life.note", "")).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BadKeysAreRejected():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            Assert:IsTrue(KeyIsRejected(s, "")).
            Assert:IsTrue(KeyIsRejected(s, "has space")).
            Assert:IsTrue(KeyIsRejected(s, "slash/key")).
            Assert:IsTrue(KeyIsRejected(s, "quote~"key")).
            Assert:IsTrue(KeyIsRejected(s, "colon:key")).
            Assert:IsFalse(KeyIsRejected(s, "life.speed-2_b")).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReadingWithABadKeyThrowsToo():
        DEFINE VARIABLE k      AS INTEGER NO-UNDO.
        DEFINE VARIABLE s      AS ISettings NO-UNDO.
        DEFINE VARIABLE caught AS LOGICAL NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:GetInteger("bad key", 1).
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            caught = FALSE.
            DO ON ERROR UNDO, THROW:
                s:Has("").
                CATCH ge AS GridException:
                    caught = TRUE.
                END CATCH.
            END.
            Assert:IsTrue(caught).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID UnknownValuesAreRejected():
        DEFINE VARIABLE k      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE s      AS ISettings NO-UNDO.
        DEFINE VARIABLE c      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE d      AS DECIMAL   NO-UNDO.
        DEFINE VARIABLE l      AS LOGICAL   NO-UNDO.
        DEFINE VARIABLE caught AS INTEGER   NO-UNDO.
        /* variables start as empty or zero, not unknown, so set them unknown on purpose */
        ASSIGN c = ? i = ? d = ? l = ?.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            caught = 0.
            DO ON ERROR UNDO, THROW:
                s:SetString("life.a", c).
                CATCH ge AS GridException:
                    caught = caught + 1.
                END CATCH.
            END.
            DO ON ERROR UNDO, THROW:
                s:SetInteger("life.b", i).
                CATCH ge AS GridException:
                    caught = caught + 1.
                END CATCH.
            END.
            DO ON ERROR UNDO, THROW:
                s:SetDecimal("life.c", d).
                CATCH ge AS GridException:
                    caught = caught + 1.
                END CATCH.
            END.
            DO ON ERROR UNDO, THROW:
                s:SetLogical("life.d", l).
                CATCH ge AS GridException:
                    caught = caught + 1.
                END CATCH.
            END.
            Assert:Equals(4, caught).
            Assert:IsFalse(s:Has("life.a")).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SaveIsSafeToCallAnyTime():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE s AS ISettings NO-UNDO.
        DO k = 1 TO KindCount() ON ERROR UNDO, THROW:
            s = Make(k).
            s:Save().
            s:SetInteger("life.speed", 3).
            s:Save().
            s:Save().
            Assert:Equals(3, s:GetInteger("life.speed", 0)).
            CATCH e AS Progress.Lang.Error:
                Rethrow(k, e).
            END CATCH.
        END.
    END METHOD.

END CLASS.
