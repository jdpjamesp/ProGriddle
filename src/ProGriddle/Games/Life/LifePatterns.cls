/* Well known Life patterns as Shapes, a lookup by name, and a loader for the common plain
   text pattern format. Place a pattern on a grid with ICellStore:Stamp.

   Plain text format (as used by .cells files): lines starting with "!" are comments, "." is a
   dead cell, and "O" (also "X", "#" and "*") is a live one. Rows may have different lengths. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifePatterns FINAL:

    /* Comma separated list of the names ByName accepts. */
    METHOD PUBLIC STATIC CHARACTER Names():
        RETURN "Block,Beehive,Blinker,Toad,Beacon,Glider,LightweightSpaceship,RPentomino,Diehard,Acorn,GosperGliderGun".
    END METHOD.

    /* The pattern with this name, ignoring case. Throws GridException when there is none. */
    METHOD PUBLIC STATIC Shape ByName(INPUT pcName AS CHARACTER):
        IF pcName = ? THEN UNDO, THROW NEW GridException("Pattern name cannot be unknown").
        CASE pcName:
            WHEN "Block"                THEN RETURN Block().
            WHEN "Beehive"              THEN RETURN Beehive().
            WHEN "Blinker"              THEN RETURN Blinker().
            WHEN "Toad"                 THEN RETURN Toad().
            WHEN "Beacon"               THEN RETURN Beacon().
            WHEN "Glider"               THEN RETURN Glider().
            WHEN "LightweightSpaceship" THEN RETURN LightweightSpaceship().
            WHEN "RPentomino"           THEN RETURN RPentomino().
            WHEN "Diehard"              THEN RETURN Diehard().
            WHEN "Acorn"                THEN RETURN Acorn().
            WHEN "GosperGliderGun"      THEN RETURN GosperGliderGun().
        END CASE.
        UNDO, THROW NEW GridException("Unknown Life pattern: " + pcName).
    END METHOD.

    /* Still life: a 2 x 2 square. */
    METHOD PUBLIC STATIC Shape Block():
        RETURN Shape:Parse("XX/XX").
    END METHOD.

    /* Still life: six cells. */
    METHOD PUBLIC STATIC Shape Beehive():
        RETURN Shape:Parse(".XX./X..X/.XX.").
    END METHOD.

    /* Oscillator, period 2: three cells in a row. */
    METHOD PUBLIC STATIC Shape Blinker():
        RETURN Shape:Parse("XXX").
    END METHOD.

    /* Oscillator, period 2. */
    METHOD PUBLIC STATIC Shape Toad():
        RETURN Shape:Parse(".XXX/XXX.").
    END METHOD.

    /* Oscillator, period 2. */
    METHOD PUBLIC STATIC Shape Beacon():
        RETURN Shape:Parse("XX../XX../..XX/..XX").
    END METHOD.

    /* Spaceship that moves one cell down and one right every 4 generations. */
    METHOD PUBLIC STATIC Shape Glider():
        RETURN Shape:Parse(".X./..X/XXX").
    END METHOD.

    /* Spaceship that moves two cells to the right every 4 generations. */
    METHOD PUBLIC STATIC Shape LightweightSpaceship():
        RETURN Shape:Parse(".XXXX/X...X/....X/X..X.").
    END METHOD.

    /* Five cells that run for 1103 generations on an open board before settling. */
    METHOD PUBLIC STATIC Shape RPentomino():
        RETURN Shape:Parse(".XX/XX./.X.").
    END METHOD.

    /* Seven cells that vanish completely after 130 generations. */
    METHOD PUBLIC STATIC Shape Diehard():
        RETURN Shape:Parse("......X./XX....../.X...XXX").
    END METHOD.

    /* Seven cells that take 5206 generations to settle. */
    METHOD PUBLIC STATIC Shape Acorn():
        RETURN Shape:Parse(".X...../...X.../XX..XXX").
    END METHOD.

    /* Fires a glider every 30 generations. 36 cells in a 36 x 9 box. */
    METHOD PUBLIC STATIC Shape GosperGliderGun():
        RETURN Shape:Parse("........................X.........../"
                         + "......................X.X.........../"
                         + "............XX......XX............XX/"
                         + "...........X...X....XX............XX/"
                         + "XX........X.....X...XX............../"
                         + "XX........X...X.XX....X.X.........../"
                         + "..........X.....X.......X.........../"
                         + "...........X...X..................../"
                         + "............XX....................").
    END METHOD.

    /* Builds a shape from plain text pattern lines. Throws GridException when there is no live
       cell. */
    METHOD PUBLIC STATIC Shape FromPlainText(INPUT pcText AS CHARACTER):
        DEFINE VARIABLE body   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE oneLine   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE allRows   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE c      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE ch     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE rowText    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE found    AS LOGICAL   NO-UNDO.

        IF pcText = ? THEN UNDO, THROW NEW GridException("Pattern text cannot be unknown").
        body = REPLACE(REPLACE(pcText, CHR(13) + CHR(10), CHR(10)), CHR(13), CHR(10)).
        DO i = 1 TO NUM-ENTRIES(body, CHR(10)):
            oneLine = ENTRY(i, body, CHR(10)).
            IF SUBSTRING(oneLine, 1, 1) = "!" THEN NEXT.
            rowText = "".
            DO c = 1 TO LENGTH(oneLine):
                ch = SUBSTRING(oneLine, c, 1).
                IF ch = "O" OR ch = "o" OR ch = "X" OR ch = "x" OR ch = "#" OR ch = "*" THEN DO:
                    rowText = rowText + "X".
                    found = TRUE.
                END.
                ELSE rowText = rowText + ".".
            END.
            allRows = allRows + (IF allRows = "" THEN "" ELSE "/") + rowText.
        END.
        IF NOT found THEN UNDO, THROW NEW GridException("The pattern text has no live cells").
        RETURN Shape:Parse(allRows).
    END METHOD.

END CLASS.
