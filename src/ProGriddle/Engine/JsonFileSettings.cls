/* Settings kept in a small JSON file:

     { "schemaVersion": 1, "values": { "life.speed": 4, "life.pattern": "Glider" } }

   The path is passed in, so tests use a temp file, and DefaultPath gives the usual place for
   a player, %APPDATA%\ProGriddle\settings.json. Loading never fails: a missing, unreadable,
   corrupt or newer-than-known file just leaves the settings empty, and LoadStatus says
   which. Save then writes a fresh, valid file. Save writes to a temporary file first, so a
   crash part way cannot leave a half written settings file.

   Several programs share one file (each game window is a program of its own, and the Cookoff can
   run them side by side), so Save does not write what was loaded back over the file. It reads the
   file again, puts in only the keys this object has set, and writes that, so a score another game
   saved in the meantime is kept. When two programs set the same key the later save wins. */
USING Progress.Json.ObjectModel.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.JsonFileSettings FINAL INHERITS AbstractSettings:

    DEFINE PRIVATE VARIABLE mPath AS CHARACTER NO-UNDO.

    /* The file this object reads and writes. */
    DEFINE PUBLIC PROPERTY Path AS CHARACTER NO-UNDO
        GET():
            RETURN mPath.
        END GET.

    /* What loading found: "new" (no file yet), "loaded", "corrupt" (not valid settings JSON)
       or "unsupported" (a schema version this code does not know). */
    DEFINE PUBLIC PROPERTY LoadStatus AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC JsonFileSettings(INPUT pcPath AS CHARACTER):
        IF pcPath = ? OR pcPath = "" THEN
            UNDO, THROW NEW GridException("A settings file needs a path").
        mPath = pcPath.
        Load().
    END CONSTRUCTOR.

    /* %APPDATA%\ProGriddle\settings.json, or the temp directory when there is no APPDATA. */
    METHOD PUBLIC STATIC CHARACTER DefaultPath():
        DEFINE VARIABLE base AS CHARACTER NO-UNDO.
        base = OS-GETENV("APPDATA").
        IF base = ? OR base = "" THEN base = SESSION:TEMP-DIRECTORY.
        RETURN RIGHT-TRIM(base, "~\/") + "~\ProGriddle~\settings.json".
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID Save():
        DEFINE VARIABLE root   AS JsonObject NO-UNDO.
        DEFINE VARIABLE dir    AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE tmp    AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE cut    AS INTEGER    NO-UNDO.

        cut = MAXIMUM(R-INDEX(mPath, "~\"), R-INDEX(mPath, "/")).
        IF cut > 1 THEN DO:
            dir = SUBSTRING(mPath, 1, cut - 1).
            FILE-INFO:FILE-NAME = dir.
            IF FILE-INFO:FULL-PATHNAME = ? THEN DO:
                OS-CREATE-DIR VALUE(dir).
                IF OS-ERROR <> 0 THEN
                    UNDO, THROW NEW GridException(SUBSTITUTE("Cannot create the settings folder &1 (error &2)", dir, OS-ERROR)).
            END.
        END.

        MergeWithFile().
        root = NEW JsonObject().
        root:Add("schemaVersion", 1).
        root:Add("values", mValues).
        /* a name of its own, so two programs saving at once do not write the same temporary file */
        tmp = mPath + "." + STRING(MTIME) + STRING(RANDOM(0, 9999)) + ".tmp".
        root:WriteFile(tmp, TRUE).
        OS-COPY VALUE(tmp) VALUE(mPath).
        IF OS-ERROR <> 0 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cannot write the settings file &1 (error &2)", mPath, OS-ERROR)).
        OS-DELETE VALUE(tmp).
        ClearChanged().
    END METHOD.

    /* Brings in what other programs have saved since this one loaded: the values in the file now,
       with this object's own changes put on top. A file that is missing or unusable is left out,
       and then the values held here are written as they are. */
    METHOD PRIVATE VOID MergeWithFile():
        DEFINE VARIABLE onDisk  AS JsonObject NO-UNDO.
        DEFINE VARIABLE loadState AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE changed AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE keyName AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER    NO-UNDO.
        onDisk = ReadValues(OUTPUT loadState).
        IF NOT VALID-OBJECT(onDisk) THEN RETURN.
        changed = ChangedKeys().
        DO i = 1 TO NUM-ENTRIES(changed):
            keyName = ENTRY(i, changed).
            IF onDisk:Has(keyName) THEN onDisk:Remove(keyName).
            IF mValues:Has(keyName) THEN CopyValue(mValues, onDisk, keyName).
        END.
        mValues = onDisk.
    END METHOD.

    /* Copies a string, number or true or false value from one object to another. */
    METHOD PRIVATE VOID CopyValue(INPUT poFrom AS JsonObject, INPUT poTo AS JsonObject, INPUT pcKey AS CHARACTER):
        CASE poFrom:GetType(pcKey):
            WHEN JsonDataType:STRING THEN poTo:Add(pcKey, poFrom:GetCharacter(pcKey)).
            WHEN JsonDataType:NUMBER THEN poTo:Add(pcKey, poFrom:GetDecimal(pcKey)).
            WHEN JsonDataType:BOOLEAN THEN poTo:Add(pcKey, poFrom:GetLogical(pcKey)).
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID Load():
        DEFINE VARIABLE loaded AS JsonObject NO-UNDO.
        DEFINE VARIABLE loadState AS CHARACTER  NO-UNDO.
        loaded = ReadValues(OUTPUT loadState).
        LoadStatus = loadState.
        IF VALID-OBJECT(loaded) THEN mValues = loaded.
    END METHOD.

    /* The "values" object in the file, with the load status as an output: "new" for no file,
       "loaded", "corrupt" or "unsupported". The object is unknown for all but "loaded". */
    METHOD PRIVATE JsonObject ReadValues(OUTPUT pcStatus AS CHARACTER):
        DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE parsed AS JsonConstruct     NO-UNDO.
        DEFINE VARIABLE root   AS JsonObject        NO-UNDO.

        pcStatus = "new".
        IF SEARCH(mPath) = ? THEN RETURN ?.

        pcStatus = "corrupt".
        DO ON ERROR UNDO, THROW:
            parser = NEW ObjectModelParser().
            parsed = parser:ParseFile(mPath).
            IF NOT TYPE-OF(parsed, JsonObject) THEN RETURN ?.
            root = CAST(parsed, JsonObject).
            IF NOT root:Has("schemaVersion") OR root:GetType("schemaVersion") <> JsonDataType:NUMBER THEN RETURN ?.
            IF root:GetInteger("schemaVersion") <> 1 THEN DO:
                pcStatus = "unsupported".
                RETURN ?.
            END.
            IF NOT root:Has("values") OR root:GetType("values") <> JsonDataType:OBJECT THEN RETURN ?.
            pcStatus = "loaded".
            RETURN root:GetJsonObject("values").
            CATCH e AS Progress.Lang.Error:
                pcStatus = "corrupt".
                RETURN ?.
            END CATCH.
        END.
    END METHOD.

END CLASS.
