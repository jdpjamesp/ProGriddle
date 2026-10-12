/* What is particular to JsonFileSettings: the file itself. The shared behaviour is in
   SettingsContractTests. Test files live in build/test-settings, which git ignores. */
USING OpenEdge.Core.Assert.
USING Prolif.Engine.JsonFileSettings.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Engine.JsonFileSettingsTests:

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
    METHOD PUBLIC VOID TheDefaultPathIsInAProLificFolder():
        Assert:IsTrue(JsonFileSettings:DefaultPath() MATCHES "*~\ProLific~\settings.json").
    END METHOD.

    @Test (expected="Prolif.Core.GridException").
    METHOD PUBLIC VOID ANewObjectNeedsAPath():
        NEW JsonFileSettings("").
    END METHOD.

END CLASS.
