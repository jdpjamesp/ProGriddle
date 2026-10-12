/* Shared behaviour of the settings implementations: key checking and typed values held in
   a JSON object. A subclass decides where the values come from and go to (Save). The
   native Progress.Json classes are used, so nothing here needs .NET. */
USING Progress.Json.ObjectModel.*.
USING Progress.Lang.*.
USING Prolif.Core.GridException.
USING Prolif.Engine.AbstractSettings.
USING Prolif.Engine.ISettings.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Engine.AbstractSettings ABSTRACT IMPLEMENTS ISettings:

    /* The key and value pairs. A subclass may replace this object when it loads. */
    DEFINE PROTECTED VARIABLE mValues AS JsonObject NO-UNDO.

    CONSTRUCTOR PROTECTED AbstractSettings():
        mValues = NEW JsonObject().
    END CONSTRUCTOR.

    METHOD PUBLIC LOGICAL Has(INPUT pcKey AS CHARACTER):
        CheckKey(pcKey).
        RETURN mValues:Has(pcKey).
    END METHOD.

    METHOD PUBLIC CHARACTER GetString(INPUT pcKey AS CHARACTER, INPUT pcDefault AS CHARACTER):
        CheckKey(pcKey).
        IF mValues:Has(pcKey) AND mValues:GetType(pcKey) = JsonDataType:STRING THEN
            RETURN mValues:GetCharacter(pcKey).
        RETURN pcDefault.
    END METHOD.

    METHOD PUBLIC INTEGER GetInteger(INPUT pcKey AS CHARACTER, INPUT piDefault AS INTEGER):
        DEFINE VARIABLE d AS DECIMAL NO-UNDO.
        CheckKey(pcKey).
        IF mValues:Has(pcKey) AND mValues:GetType(pcKey) = JsonDataType:NUMBER THEN DO:
            d = mValues:GetDecimal(pcKey).
            IF d = TRUNCATE(d, 0) AND d >= -2147483647 AND d <= 2147483647 THEN RETURN INTEGER(d).
        END.
        RETURN piDefault.
    END METHOD.

    METHOD PUBLIC DECIMAL GetDecimal(INPUT pcKey AS CHARACTER, INPUT pdDefault AS DECIMAL):
        CheckKey(pcKey).
        IF mValues:Has(pcKey) AND mValues:GetType(pcKey) = JsonDataType:NUMBER THEN
            RETURN mValues:GetDecimal(pcKey).
        RETURN pdDefault.
    END METHOD.

    METHOD PUBLIC LOGICAL GetLogical(INPUT pcKey AS CHARACTER, INPUT plDefault AS LOGICAL):
        CheckKey(pcKey).
        IF mValues:Has(pcKey) AND mValues:GetType(pcKey) = JsonDataType:BOOLEAN THEN
            RETURN mValues:GetLogical(pcKey).
        RETURN plDefault.
    END METHOD.

    METHOD PUBLIC VOID SetString(INPUT pcKey AS CHARACTER, INPUT pcValue AS CHARACTER):
        CheckKey(pcKey).
        IF pcValue = ? THEN UNDO, THROW NEW GridException("A setting cannot be the unknown value: " + pcKey).
        Forget(pcKey).
        mValues:Add(pcKey, pcValue).
    END METHOD.

    METHOD PUBLIC VOID SetInteger(INPUT pcKey AS CHARACTER, INPUT piValue AS INTEGER):
        CheckKey(pcKey).
        IF piValue = ? THEN UNDO, THROW NEW GridException("A setting cannot be the unknown value: " + pcKey).
        Forget(pcKey).
        mValues:Add(pcKey, piValue).
    END METHOD.

    METHOD PUBLIC VOID SetDecimal(INPUT pcKey AS CHARACTER, INPUT pdValue AS DECIMAL):
        CheckKey(pcKey).
        IF pdValue = ? THEN UNDO, THROW NEW GridException("A setting cannot be the unknown value: " + pcKey).
        Forget(pcKey).
        mValues:Add(pcKey, pdValue).
    END METHOD.

    METHOD PUBLIC VOID SetLogical(INPUT pcKey AS CHARACTER, INPUT plValue AS LOGICAL):
        CheckKey(pcKey).
        IF plValue = ? THEN UNDO, THROW NEW GridException("A setting cannot be the unknown value: " + pcKey).
        Forget(pcKey).
        mValues:Add(pcKey, plValue).
    END METHOD.

    METHOD PUBLIC ABSTRACT VOID Save().

    /* Throws GridException unless the key is made of letters, digits, dot, underscore and
       hyphen, and is not empty. */
    METHOD PROTECTED VOID CheckKey(INPUT pcKey AS CHARACTER):
        DEFINE VARIABLE i  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE ch AS CHARACTER NO-UNDO.
        IF pcKey = ? OR pcKey = "" THEN
            UNDO, THROW NEW GridException("A setting key cannot be empty").
        DO i = 1 TO LENGTH(pcKey):
            ch = SUBSTRING(pcKey, i, 1).
            IF NOT ((ch >= "a" AND ch <= "z") OR (ch >= "A" AND ch <= "Z") OR (ch >= "0" AND ch <= "9")
                    OR ch = "." OR ch = "_" OR ch = "-") THEN
                UNDO, THROW NEW GridException("Invalid setting key: " + pcKey).
        END.
    END METHOD.

    /* Removes the key if it is there, so a value of another type can take its place. */
    METHOD PRIVATE VOID Forget(INPUT pcKey AS CHARACTER):
        IF mValues:Has(pcKey) THEN mValues:Remove(pcKey).
    END METHOD.

END CLASS.
