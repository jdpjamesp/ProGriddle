/* How a 2048 board is drawn: a colour and a glyph for each value of the "view" layer, which is the
   power of two of the tile (0 empty, 1 a 2, 2 a 4, up to 20 for a 1048576). The lists are in
   value order, so a window gives them straight to its view. The colours are the familiar ones,
   from the pale 2 through orange and red to gold, and then a dark tile for anything beyond 2048. */
USING Progress.Lang.*.
USING ProGriddle.Games.2048.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.2048.TilesLook FINAL:

    /* Cell colours, empty cell first. */
    METHOD PUBLIC STATIC CHARACTER Palette():
        RETURN "2A313A,EEE4DA,EDE0C8,F2B179,F59563,F67C5F,F65E3B,EDCF72,EDCC61,EDC850,EDC53F,EDC22E,3C3A32,3C3A32,3C3A32,3C3A32,3C3A32,3C3A32,3C3A32,3C3A32,3C3A32".
    END METHOD.

    /* The number on each tile. An empty cell has none. */
    METHOD PUBLIC STATIC CHARACTER Glyphs():
        RETURN ",2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,1048576".
    END METHOD.

    /* The colour of each number: dark on the two palest tiles, white on the rest. */
    METHOD PUBLIC STATIC CHARACTER GlyphColors():
        RETURN "FFFFFF,776E65,776E65,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2,F9F6F2".
    END METHOD.

    /* One character per value, for drawing a board as text in tests: . empty, 1 to 9 for the
       powers up to 512, then A for 1024, B for 2048, and so on up to K. */
    METHOD PUBLIC STATIC CHARACTER TextSymbols():
        RETURN ".123456789ABCDEFGHIJK".
    END METHOD.

END CLASS.
