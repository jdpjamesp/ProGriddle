/* The single colours of the "Lantern Glass" look of Tetris (docs/design/tetris-art.md), by name, in the order of the list in
   TetrisLook. TetrisLook:Colour gives the 0xRRGGBB number of one. The pieces' own colours are rows of five tones, not
   names: see TetrisLook:Tones. */
ENUM ProGriddle.Games.Tetris.Tint:

    DEFINE ENUM NightTop = 0
                NightBottom
                Dot
                PanelFill
                FrameOuter
                FrameInner
                Gap
                Text
                Label
                Dim
                Accent
                Gold
                OverTop
                OverBottom
                Outline
                Flash
                FloorTop
                FloorBottom
                WallHigh
                WallLow
                GhostLine
                GhostHatch
                DangerHigh
                DangerLow.

END ENUM.
