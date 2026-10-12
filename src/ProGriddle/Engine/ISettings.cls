/* Named settings that outlive a session: window size, cell size, speed, last pattern and so
   on. Reading never fails: a missing key, or a key holding a different type, returns the
   default the caller supplies. Keys are namespaced by game with a dot, for example
   "life.speed", and may use letters, digits, dot, underscore and hyphen. A bad key throws
   GridException. */
USING ProGriddle.Engine.*.

INTERFACE ProGriddle.Engine.ISettings:

    /* True when the key holds a value of any type. */
    METHOD PUBLIC LOGICAL Has(INPUT pcKey AS CHARACTER).

    METHOD PUBLIC CHARACTER GetString(INPUT pcKey AS CHARACTER, INPUT pcDefault AS CHARACTER).

    /* A whole number, or the default when the key is missing, is not a number or has a
       fractional part. */
    METHOD PUBLIC INTEGER GetInteger(INPUT pcKey AS CHARACTER, INPUT piDefault AS INTEGER).

    METHOD PUBLIC DECIMAL GetDecimal(INPUT pcKey AS CHARACTER, INPUT pdDefault AS DECIMAL).

    METHOD PUBLIC LOGICAL GetLogical(INPUT pcKey AS CHARACTER, INPUT plDefault AS LOGICAL).

    /* Setting replaces any earlier value of any type. Values cannot be the unknown value. */
    METHOD PUBLIC VOID SetString(INPUT pcKey AS CHARACTER, INPUT pcValue AS CHARACTER).

    METHOD PUBLIC VOID SetInteger(INPUT pcKey AS CHARACTER, INPUT piValue AS INTEGER).

    METHOD PUBLIC VOID SetDecimal(INPUT pcKey AS CHARACTER, INPUT pdValue AS DECIMAL).

    METHOD PUBLIC VOID SetLogical(INPUT pcKey AS CHARACTER, INPUT plValue AS LOGICAL).

    /* Writes the settings to wherever they live. A no-op for in-memory settings. */
    METHOD PUBLIC VOID Save().

END INTERFACE.
