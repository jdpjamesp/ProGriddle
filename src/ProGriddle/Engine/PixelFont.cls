/* A small pixel font for text drawn into the grid: the capital letters, the digits and a few marks
   (- < > = ? . : ! + and the space), each 5 cells wide and 7 high, with one empty column between
   letters. Lower case letters are drawn as capitals. A character with no glyph is drawn as a ?. The
   canvas draws text with it, so the score and the title are part of the picture like everything else. */
USING Progress.Lang.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.PixelFont FINAL:

    /* The characters that have a glyph, in the order of the glyph table. */
    &SCOPED-DEFINE CHARS "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-<>=?.:!+ "

    /* Width and height of a glyph, in cells, and the gap between two letters. */
    METHOD PUBLIC STATIC INTEGER GlyphWidth():
        RETURN 5.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER GlyphHeight():
        RETURN 7.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Gap():
        RETURN 1.
    END METHOD.

    /* True when the character has a glyph of its own. Case does not matter. */
    METHOD PUBLIC STATIC LOGICAL HasGlyph(INPUT pcChar AS CHARACTER):
        RETURN pcChar <> ? AND LENGTH(pcChar) = 1 AND INDEX({&CHARS}, CAPS(pcChar)) > 0.
    END METHOD.

    /* The glyph of a character as 7 rows of 5 cells, "#" for a cell, rows separated by "/". A
       character with no glyph gives the glyph of ?. */
    METHOD PUBLIC STATIC CHARACTER Glyph(INPUT pcChar AS CHARACTER):
        DEFINE VARIABLE slot AS INTEGER   NO-UNDO.
        DEFINE VARIABLE bits AS CHARACTER NO-UNDO.
        DEFINE VARIABLE r    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        IF HasGlyph(pcChar) THEN slot = INDEX({&CHARS}, CAPS(pcChar)).
        ELSE slot = INDEX({&CHARS}, "?").
        bits = SUBSTRING(GlyphTable(), (slot - 1) * 35 + 1, 35).
        DO r = 0 TO 6:
            result = result + (IF r > 0 THEN "/" ELSE "") + SUBSTRING(bits, r * 5 + 1, 5).
        END.
        RETURN result.
    END METHOD.

    /* Width in cells of a piece of text: the glyphs and the gaps between them, 0 for no text. */
    METHOD PUBLIC STATIC INTEGER WidthOf(INPUT pcText AS CHARACTER):
        IF pcText = ? OR pcText = "" THEN RETURN 0.
        RETURN LENGTH(pcText) * GlyphWidth() + (LENGTH(pcText) - 1) * Gap().
    END METHOD.

    /* The glyph table: 35 characters (7 rows of 5) for each character of CHARS, in that order. */
    METHOD PRIVATE STATIC CHARACTER GlyphTable():
        RETURN ".###.#...##...#######...##...##...#####.#...##...#####.#...##...#####." +
            ".###.#...##....#....#....#...#.###.####.#...##...##...##...##...#####." +
            "######....#....####.#....#....###########....#....####.#....#....#...." +
            ".###.#...##....#.####...##...#.###.#...##...##...#######...##...##...#" +
            ".###...#....#....#....#....#...###...###...#....#....#....#.#..#..##.." +
            "#...##..#.#.#..##...#.#..#..#.#...##....#....#....#....#....#....#####" +
            "#...###.###.#.##.#.##...##...##...##...###..##.#.##..###...##...##...#" +
            ".###.#...##...##...##...##...#.###.####.#...##...#####.#....#....#...." +
            ".###.#...##...##...##.#.##..#..##.#####.#...##...#####.#.#..#..#.#...#" +
            ".#####....#.....###.....#....#####.#####..#....#....#....#....#....#.." +
            "#...##...##...##...##...##...#.###.#...##...##...##...##...#.#.#...#.." +
            "#...##...##...##.#.##.#.###.###...##...##...#.#.#...#...#.#.#...##...#" +
            "#...##...#.#.#...#....#....#....#..#####....#...#...#...#...#....#####" +
            ".###.#...##..###.#.###..##...#.###...#...##....#....#....#....#...###." +
            ".###.#...#....#...#...#...#...#####.###.#...#....#..##.....##...#.###." +
            "...#...##..#.#.#..#.#####...#....#.######....####.....#....##...#.###." +
            "..##..#...#....####.#...##...#.###.#####....#...#...#...#....#....#..." +
            ".###.#...##...#.###.#...##...#.###..###.#...##...#.####....#...#..##.." +
            "................###...................#...#...#...#.....#.....#.....#." +
            ".#.....#.....#.....#...#...#...#.............#####.....#####.........." +
            ".###.#...#....#...#...#.........#............................##...##.." +
            ".......#....#.........#....#.........#....#....#....#....#.........#.." +
            ".......#....#..#####..#....#..........................................".
    END METHOD.

END CLASS.
