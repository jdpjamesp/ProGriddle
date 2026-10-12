/* The birth and survival rule of a Life-like game, kept as data so other rule sets are
   just a different string. Written in the usual B/S notation: B3/S23 is Conway's Life (a
   dead cell with exactly 3 live neighbours is born, a live cell with 2 or 3 survives).
   HighLife is B36/S23.

   Each digit is a neighbour count from 0 to 8. Counts outside that range never give a birth
   or a survival. The notation is checked, upper cased and sorted, so "b63/s32" is stored
   as "B36/S23". */
USING Progress.Lang.*.
USING Prolif.Core.GridException.
USING Prolif.Games.Life.LifeRules.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Games.Life.LifeRules FINAL:

    DEFINE PRIVATE VARIABLE mBirth   AS LOGICAL NO-UNDO EXTENT 9.
    DEFINE PRIVATE VARIABLE mSurvive AS LOGICAL NO-UNDO EXTENT 9.

    /* Canonical notation, for example "B3/S23". */
    DEFINE PUBLIC PROPERTY Notation AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    /* Throws GridException unless the notation is "B" digits "/" "S" digits, with digits 0 to 8
       that do not repeat. Either list of digits may be empty, as in "B/S". */
    CONSTRUCTOR PUBLIC LifeRules(INPUT pcNotation AS CHARACTER):
        DEFINE VARIABLE norm AS CHARACTER NO-UNDO.
        DEFINE VARIABLE b    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE s    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE d    AS INTEGER   NO-UNDO.

        IF pcNotation = ? THEN UNDO, THROW NEW GridException("Life rules cannot be unknown").
        norm = CAPS(TRIM(pcNotation)).
        IF NUM-ENTRIES(norm, "/") <> 2 THEN
            UNDO, THROW NEW GridException("Life rules must look like B3/S23, not " + pcNotation).
        b = ENTRY(1, norm, "/").
        s = ENTRY(2, norm, "/").
        IF SUBSTRING(b, 1, 1) <> "B" OR SUBSTRING(s, 1, 1) <> "S" THEN
            UNDO, THROW NEW GridException("Life rules must look like B3/S23, not " + pcNotation).
        b = SUBSTRING(b, 2).
        s = SUBSTRING(s, 2).

        DO i = 1 TO LENGTH(b):
            d = ToCount(SUBSTRING(b, i, 1), pcNotation).
            IF mBirth[d + 1] THEN UNDO, THROW NEW GridException("A birth count repeats in " + pcNotation).
            mBirth[d + 1] = TRUE.
        END.
        DO i = 1 TO LENGTH(s):
            d = ToCount(SUBSTRING(s, i, 1), pcNotation).
            IF mSurvive[d + 1] THEN UNDO, THROW NEW GridException("A survival count repeats in " + pcNotation).
            mSurvive[d + 1] = TRUE.
        END.

        b = "".
        s = "".
        DO i = 0 TO 8:
            IF mBirth[i + 1] THEN b = b + STRING(i).
            IF mSurvive[i + 1] THEN s = s + STRING(i).
        END.
        Notation = "B" + b + "/S" + s.
    END CONSTRUCTOR.

    /* Conway's Life, B3/S23. */
    METHOD PUBLIC STATIC LifeRules Conway():
        RETURN NEW LifeRules("B3/S23").
    END METHOD.

    /* HighLife, B36/S23. It has a small replicator that Conway's Life does not. */
    METHOD PUBLIC STATIC LifeRules HighLife():
        RETURN NEW LifeRules("B36/S23").
    END METHOD.

    /* True when a dead cell with this many live neighbours becomes alive. */
    METHOD PUBLIC LOGICAL Births(INPUT piCount AS INTEGER):
        IF piCount < 0 OR piCount > 8 THEN RETURN FALSE.
        RETURN mBirth[piCount + 1].
    END METHOD.

    /* True when a live cell with this many live neighbours stays alive. */
    METHOD PUBLIC LOGICAL Survives(INPUT piCount AS INTEGER):
        IF piCount < 0 OR piCount > 8 THEN RETURN FALSE.
        RETURN mSurvive[piCount + 1].
    END METHOD.

    /* The next state, 1 or 0, of a cell. piState is 0 for dead and anything else for alive. */
    METHOD PUBLIC INTEGER NextState(INPUT piState AS INTEGER, INPUT piCount AS INTEGER):
        IF piState = 0 THEN RETURN (IF Births(piCount) THEN 1 ELSE 0).
        RETURN (IF Survives(piCount) THEN 1 ELSE 0).
    END METHOD.

    METHOD PUBLIC OVERRIDE LOGICAL Equals(INPUT poOther AS Progress.Lang.Object):
        IF NOT VALID-OBJECT(poOther) THEN RETURN FALSE.
        IF NOT TYPE-OF(poOther, LifeRules) THEN RETURN FALSE.
        RETURN Notation = CAST(poOther, LifeRules):Notation.
    END METHOD.

    METHOD PUBLIC OVERRIDE CHARACTER ToString():
        RETURN Notation.
    END METHOD.

    METHOD PRIVATE INTEGER ToCount(INPUT pcDigit AS CHARACTER, INPUT pcNotation AS CHARACTER):
        IF pcDigit < "0" OR pcDigit > "8" OR LENGTH(pcDigit) <> 1 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("'&1' is not a neighbour count from 0 to 8 in &2", pcDigit, pcNotation)).
        RETURN INTEGER(pcDigit).
    END METHOD.

END CLASS.
