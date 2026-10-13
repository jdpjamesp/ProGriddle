/* What is particular to JsonFileSettings: the file itself. The shared behaviour is in
   SettingsContractTests. Test files live in build/test-settings, which git ignores. */
USING OpenEdge.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.JsonFileSettingsTests:

    /* A path inside the test folder, with any old file removed. */
    METHOD PRIVATE CHARACTER FreshPath(INPUT pcName AS CHARACTER):
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        OS-CREATE-DIR VALUE("build/test-settings").
        path = "build/test-settings/" + pcName.
        IF SEARCH(path) <> ? THEN OS-DELETE VALUE(path).
        IF SEARCH(path + ".tmp") <> ? THEN OS-DELETE VALUE(path + ".tmp").
        RETURN path.
    END METHOD.

    METHOD PRIVATE VOID WriteFile(INPUT pcPath AS CHARACTER, INPUT pcContent AS CHARACTER):
        OUTPUT TO VALUE(pcPath).
        PUT UNFORMATTED pcContent.
        OUTPUT CLOSE.
    END METHOD.

    METHOD PRIVATE CHARACTER ReadFile(INPUT pcPath AS CHARACTER):
        DEFINE VARIABLE content AS LONGCHAR NO-UNDO.
        COPY-LOB FROM FILE pcPath TO content.
        RETURN STRING(content).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMissingFileGivesAnEmptyNewSettingsObject():
        DEFINE VARIABLE s AS JsonFileSettings NO-UNDO.
        s = NEW JsonFileSettings(FreshPath("missing.json")).
        Assert:Equals("new", s:LoadStatus).
        Assert:Equals(5, s:GetInteger("life.speed", 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ValuesComeBackAfterSavingAndLoadingAgain():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        DEFINE VARIABLE a    AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE b    AS JsonFileSettings NO-UNDO.
        path = FreshPath("roundtrip.json").
        a = NEW JsonFileSettings(path).
        a:SetString("life.pattern", "Glider").
        a:SetInteger("life.speed", 4).
        a:SetDecimal("life.density", 0.35).
        a:SetLogical("life.wrap", TRUE).
        a:SetInteger("window.x", -20).
        a:Save().
        b = NEW JsonFileSettings(path).
        Assert:Equals("loaded", b:LoadStatus).
        Assert:Equals("Glider", b:GetString("life.pattern", "")).
        Assert:Equals(4, b:GetInteger("life.speed", 0)).
        Assert:Equals(0.35, b:GetDecimal("life.density", 0)).
        Assert:IsTrue(b:GetLogical("life.wrap", FALSE)).
        Assert:Equals(-20, b:GetInteger("window.x", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SettingsNotTouchedInASessionSurviveIt():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        DEFINE VARIABLE a    AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE b    AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE c    AS JsonFileSettings NO-UNDO.
        path = FreshPath("keep.json").
        a = NEW JsonFileSettings(path).
        a:SetInteger("life.speed", 4).
        a:SetInteger("tetris.speed", 9).
        a:Save().
        b = NEW JsonFileSettings(path).
        b:SetInteger("life.speed", 6).
        b:Save().
        c = NEW JsonFileSettings(path).
        Assert:Equals(6, c:GetInteger("life.speed", 0)).
        Assert:Equals(9, c:GetInteger("tetris.speed", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFileCarriesASchemaVersionAndAValuesObject():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        DEFINE VARIABLE s    AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE body AS CHARACTER NO-UNDO.
        path = FreshPath("shape.json").
        s = NEW JsonFileSettings(path).
        s:SetInteger("life.speed", 4).
        s:Save().
        body = ReadFile(path).
        Assert:IsTrue(INDEX(body, '"schemaVersion"') > 0).
        Assert:IsTrue(INDEX(body, '"values"') > 0).
        Assert:IsTrue(INDEX(body, '"life.speed"') > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SaveLeavesNoTemporaryFileBehind():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        DEFINE VARIABLE s    AS JsonFileSettings NO-UNDO.
        path = FreshPath("tidy.json").
        s = NEW JsonFileSettings(path).
        s:SetInteger("life.speed", 4).
        s:Save().
        Assert:IsTrue(SEARCH(path) <> ?).
        Assert:IsTrue(SEARCH(path + ".tmp") = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SaveCreatesTheFolderWhenItIsMissing():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        DEFINE VARIABLE s    AS JsonFileSettings NO-UNDO.
        OS-CREATE-DIR VALUE("build/test-settings").
        path = "build/test-settings/made-by-save/settings.json".
        IF SEARCH(path) <> ? THEN OS-DELETE VALUE(path).
        s = NEW JsonFileSettings(path).
        s:SetInteger("life.speed", 4).
        s:Save().
        Assert:IsTrue(SEARCH(path) <> ?).
        Assert:Equals(4, NEW JsonFileSettings(path):GetInteger("life.speed", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGarbageFileIsCorruptAndIgnoredThenOverwrittenBySave():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        DEFINE VARIABLE s    AS JsonFileSettings NO-UNDO.
        path = FreshPath("garbage.json").
        WriteFile(path, "this is not json ~{~{~{").
        s = NEW JsonFileSettings(path).
        Assert:Equals("corrupt", s:LoadStatus).
        Assert:Equals(5, s:GetInteger("life.speed", 5)).
        s:SetInteger("life.speed", 7).
        s:Save().
        Assert:Equals("loaded", NEW JsonFileSettings(path):LoadStatus).
        Assert:Equals(7, NEW JsonFileSettings(path):GetInteger("life.speed", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyFileIsCorrupt():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        path = FreshPath("empty.json").
        WriteFile(path, "").
        Assert:Equals("corrupt", NEW JsonFileSettings(path):LoadStatus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID JsonThatIsNotAnObjectIsCorrupt():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        path = FreshPath("array.json").
        WriteFile(path, "[1, 2, 3]").
        Assert:Equals("corrupt", NEW JsonFileSettings(path):LoadStatus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnObjectWithoutASchemaVersionIsCorrupt():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        path = FreshPath("noversion.json").
        WriteFile(path, '~{"values": ~{"life.speed": 4~}~}').
        Assert:Equals("corrupt", NEW JsonFileSettings(path):LoadStatus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AValuesEntryThatIsNotAnObjectIsCorrupt():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        path = FreshPath("badvalues.json").
        WriteFile(path, '~{"schemaVersion": 1, "values": 5~}').
        Assert:Equals("corrupt", NEW JsonFileSettings(path):LoadStatus).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewerSchemaVersionIsUnsupportedAndIgnored():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        DEFINE VARIABLE s    AS JsonFileSettings NO-UNDO.
        path = FreshPath("future.json").
        WriteFile(path, '~{"schemaVersion": 2, "values": ~{"life.speed": 4~}~}').
        s = NEW JsonFileSettings(path).
        Assert:Equals("unsupported", s:LoadStatus).
        Assert:Equals(5, s:GetInteger("life.speed", 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHandWrittenValidFileLoads():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        DEFINE VARIABLE s    AS JsonFileSettings NO-UNDO.
        path = FreshPath("handwritten.json").
        WriteFile(path, '~{"schemaVersion": 1, "values": ~{"life.speed": 3, "life.wrap": true, "life.pattern": "Blinker"~}~}').
        s = NEW JsonFileSettings(path).
        Assert:Equals("loaded", s:LoadStatus).
        Assert:Equals(3, s:GetInteger("life.speed", 0)).
        Assert:IsTrue(s:GetLogical("life.wrap", FALSE)).
        Assert:Equals("Blinker", s:GetString("life.pattern", "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePathIsKept():
        Assert:Equals("build/test-settings/p.json", NEW JsonFileSettings(FreshPath("p.json")):Path).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDefaultPathIsInAProGriddleFolder():
        Assert:IsTrue(JsonFileSettings:DefaultPath() MATCHES "*~\ProGriddle~\settings.json").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ANewObjectNeedsAPath():
        NEW JsonFileSettings("").
    END METHOD.

    /* ---- several programs sharing the one file ---- */

    @Test.
    METHOD PUBLIC VOID ASaveKeepsWhatAnotherProgramSavedInTheMeantime():
        DEFINE VARIABLE path   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE tetris AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE life   AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE again  AS JsonFileSettings NO-UNDO.
        path = FreshPath("shared.json").
        /* both windows open and read the file, as two games started from the Cookoff do */
        tetris = NEW JsonFileSettings(path).
        life = NEW JsonFileSettings(path).
        tetris:SetString("tetris.scores", "1200:8").
        tetris:Save().
        life:SetString("life.ruleset", "HighLife").
        life:Save().
        again = NEW JsonFileSettings(path).
        Assert:Equals("1200:8", again:GetString("tetris.scores", "")).
        Assert:Equals("HighLife", again:GetString("life.ruleset", "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheProgramThatSavesLastSeesTheOthersChangesAfterwards():
        DEFINE VARIABLE path AS CHARACTER NO-UNDO.
        DEFINE VARIABLE a    AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE b    AS JsonFileSettings NO-UNDO.
        path = FreshPath("seen.json").
        a = NEW JsonFileSettings(path).
        b = NEW JsonFileSettings(path).
        a:SetInteger("a.value", 1).
        a:Save().
        b:SetInteger("b.value", 2).
        b:Save().
        Assert:Equals(1, b:GetInteger("a.value", 0)).
        Assert:Equals(2, b:GetInteger("b.value", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenBothSetTheSameKeyTheLaterSaveWins():
        DEFINE VARIABLE path  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE a     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE b     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE again AS JsonFileSettings NO-UNDO.
        path = FreshPath("same-key.json").
        a = NEW JsonFileSettings(path).
        b = NEW JsonFileSettings(path).
        a:SetInteger("window.width", 800).
        b:SetInteger("window.width", 900).
        a:Save().
        b:Save().
        again = NEW JsonFileSettings(path).
        Assert:Equals(900, again:GetInteger("window.width", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ValuesThisProgramLoadedButDidNotChangeAreNotWrittenOverNewerOnes():
        DEFINE VARIABLE path  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE earlier AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE a     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE b     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE again AS JsonFileSettings NO-UNDO.
        path = FreshPath("untouched.json").
        earlier = NEW JsonFileSettings(path).
        earlier:SetInteger("tetris.best", 100).
        earlier:Save().
        a = NEW JsonFileSettings(path).
        b = NEW JsonFileSettings(path).
        /* b improves the score and saves. a only changes something else, and must not put 100 back */
        b:SetInteger("tetris.best", 500).
        b:Save().
        a:SetInteger("window.x", 10).
        a:Save().
        again = NEW JsonFileSettings(path).
        Assert:Equals(500, again:GetInteger("tetris.best", 0)).
        Assert:Equals(10, again:GetInteger("window.x", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AllFourTypesSurviveTheMerge():
        DEFINE VARIABLE path  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE a     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE b     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE again AS JsonFileSettings NO-UNDO.
        path = FreshPath("types.json").
        a = NEW JsonFileSettings(path).
        b = NEW JsonFileSettings(path).
        b:SetString("o.text", "x").
        b:Save().
        a:SetString("m.text", "hello").
        a:SetInteger("m.int", -7).
        a:SetDecimal("m.dec", 0.25).
        a:SetLogical("m.flag", TRUE).
        a:Save().
        again = NEW JsonFileSettings(path).
        Assert:Equals("hello", again:GetString("m.text", "")).
        Assert:Equals(-7, again:GetInteger("m.int", 0)).
        Assert:Equals(0.25, again:GetDecimal("m.dec", 0)).
        Assert:IsTrue(again:GetLogical("m.flag", FALSE)).
        Assert:Equals("x", again:GetString("o.text", "")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASettingChangedTypeIsReplacedInTheMerge():
        DEFINE VARIABLE path  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE a     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE again AS JsonFileSettings NO-UNDO.
        path = FreshPath("retype.json").
        a = NEW JsonFileSettings(path).
        a:SetString("k.value", "text").
        a:Save().
        a:SetInteger("k.value", 3).
        a:Save().
        again = NEW JsonFileSettings(path).
        Assert:Equals(3, again:GetInteger("k.value", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IfTheFileWasDeletedMeanwhileEverythingThisProgramHoldsIsWrittenAgain():
        DEFINE VARIABLE path  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE a     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE b     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE again AS JsonFileSettings NO-UNDO.
        path = FreshPath("deleted.json").
        a = NEW JsonFileSettings(path).
        a:SetInteger("life.speed", 4).
        a:Save().
        b = NEW JsonFileSettings(path).
        OS-DELETE VALUE(path).
        b:SetInteger("window.x", 5).
        b:Save().
        again = NEW JsonFileSettings(path).
        Assert:Equals(4, again:GetInteger("life.speed", 0)).
        Assert:Equals(5, again:GetInteger("window.x", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IfTheFileWasCorruptedMeanwhileTheSaveWritesAGoodOne():
        DEFINE VARIABLE path  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE a     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE again AS JsonFileSettings NO-UNDO.
        path = FreshPath("corrupted-later.json").
        a = NEW JsonFileSettings(path).
        a:SetInteger("life.speed", 4).
        a:Save().
        WriteFile(path, "this is not json").
        a:SetInteger("window.x", 5).
        a:Save().
        again = NEW JsonFileSettings(path).
        Assert:Equals("loaded", again:LoadStatus).
        Assert:Equals(4, again:GetInteger("life.speed", 0)).
        Assert:Equals(5, again:GetInteger("window.x", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SavingTwiceInARowLeavesTheSameFile():
        DEFINE VARIABLE path  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE a     AS JsonFileSettings NO-UNDO.
        DEFINE VARIABLE earlier AS CHARACTER NO-UNDO.
        path = FreshPath("twice.json").
        a = NEW JsonFileSettings(path).
        a:SetInteger("life.speed", 4).
        a:Save().
        earlier = ReadFile(path).
        a:Save().
        Assert:Equals(earlier, ReadFile(path)).
    END METHOD.

END CLASS.
