/* Compiles every file named in build/compile-list.txt (one PROPATH relative path per line)
   and writes the problems to build/compile-errors.txt, one line per message. Run it through
   tools/compile.ps1, which builds the list and sets PROPATH via tools/launch.p. Compiled
   r-code goes to build/rcode so nothing is left beside the source. */
DEFINE VARIABLE cFile  AS CHARACTER NO-UNDO.
DEFINE VARIABLE cLine  AS CHARACTER NO-UNDO.
DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
DEFINE VARIABLE nBad   AS INTEGER   NO-UNDO.
DEFINE VARIABLE nTotal AS INTEGER   NO-UNDO.

OS-CREATE-DIR VALUE("build/rcode").
OS-CREATE-DIR VALUE("build/rcode/run").
OUTPUT TO VALUE("build/compile-errors.txt").
INPUT FROM VALUE("build/compile-list.txt").
REPEAT:
    IMPORT UNFORMATTED cLine.
    cFile = TRIM(cLine).
    IF cFile = "" THEN NEXT.
    nTotal = nTotal + 1.
    COMPILE VALUE(cFile) SAVE INTO VALUE("build/rcode") NO-ERROR.
    IF COMPILER:ERROR OR COMPILER:WARNING THEN DO:
        nBad = nBad + 1.
        DO i = 1 TO ERROR-STATUS:NUM-MESSAGES:
            PUT UNFORMATTED cFile ": " ERROR-STATUS:GET-MESSAGE(i) SKIP.
        END.
        IF ERROR-STATUS:NUM-MESSAGES = 0 THEN PUT UNFORMATTED cFile ": compile failed" SKIP.
    END.
END.
INPUT CLOSE.
PUT UNFORMATTED "SUMMARY " nTotal " files, " nBad " with problems" SKIP.
OUTPUT CLOSE.
QUIT.
