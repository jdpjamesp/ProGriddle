/* Settings kept in a small JSON file:

     { "schemaVersion": 1, "values": { "life.speed": 4, "life.pattern": "Glider" } }

   The path is passed in, so tests use a temp file, and DefaultPath gives the usual place for
   a player, %APPDATA%\ProLific\settings.json. Loading never fails: a missing, unreadable,
   corrupt or newer-than-known file just leaves the settings empty, and LoadStatus says
   which. Save then writes a fresh, valid file. Save writes to a temporary file first, so a
   crash part way cannot leave a half written settings file. */
USING Progress.Json.ObjectModel.*.
USING Progress.Lang.*.
USING Prolif.Core.*.
USING Prolif.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Engine.JsonFileSettings FINAL INHERITS AbstractSettings:

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

    /* %APPDATA%\ProLific\settings.json, or the temp directory when there is no APPDATA. */
    METHOD PUBLIC STATIC CHARACTER DefaultPath():
        DEFINE VARIABLE base AS CHARACTER NO-UNDO.
        base = OS-GETENV("APPDATA").
        IF base = ? OR base = "" THEN base = SESSION:TEMP-DIRECTORY.
        RETURN RIGHT-TRIM(base, "~\/") + "~\ProLific~\settings.json".
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

        root = NEW JsonObject().
        root:Add("schemaVersion", 1).
        root:Add("values", mValues).
        tmp = mPath + ".tmp".
        root:WriteFile(tmp, TRUE).
        OS-COPY VALUE(tmp) VALUE(mPath).
        IF OS-ERROR <> 0 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cannot write the settings file &1 (error &2)", mPath, OS-ERROR)).
        OS-DELETE VALUE(tmp).
    END METHOD.

    METHOD PRIVATE VOID Load():
        DEFINE VARIABLE parser AS ObjectModelParser NO-UNDO.
        DEFINE VARIABLE parsed AS JsonConstruct     NO-UNDO.
        DEFINE VARIABLE root   AS JsonObject        NO-UNDO.

        LoadStatus = "new".
        IF SEARCH(mPath) = ? THEN RETURN.

        LoadStatus = "corrupt".
        DO ON ERROR UNDO, THROW:
            parser = NEW ObjectModelParser().
            parsed = parser:ParseFile(mPath).
            IF NOT TYPE-OF(parsed, JsonObject) THEN RETURN.
            root = CAST(parsed, JsonObject).
            IF NOT root:Has("schemaVersion") OR root:GetType("schemaVersion") <> JsonDataType:NUMBER THEN RETURN.
            IF root:GetInteger("schemaVersion") <> 1 THEN DO:
                LoadStatus = "unsupported".
                RETURN.
            END.
            IF NOT root:Has("values") OR root:GetType("values") <> JsonDataType:OBJECT THEN RETURN.
            mValues = root:GetJsonObject("values").
            LoadStatus = "loaded".
            CATCH e AS Progress.Lang.Error:
                mValues = NEW JsonObject().
                LoadStatus = "corrupt".
            END CATCH.
        END.
    END METHOD.

END CLASS.
