/* The glyphs of AsciiFont that are not ASCII characters, by name. Use INTEGER(AsciiExtra:Dot) for the code to give AsciiPen.

     WallAcross, WallDown                       lines that run edge to edge of the cell, so a room's walls join up
     CornerTopLeft ... CornerBottomRight        the four corners of a room
     Dot                                        a floor dot in the middle of the cell (the ASCII full stop sits low)
     Block, Shade                               a solid cell, and a cell half filled in a checker */
ENUM ProGriddle.Engine.AsciiExtra:

    DEFINE ENUM WallAcross = 127
                WallDown = 128
                CornerTopLeft = 129
                CornerTopRight = 130
                CornerBottomLeft = 131
                CornerBottomRight = 132
                Dot = 133
                Block = 134
                Shade = 135.

END ENUM.
