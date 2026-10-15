/* The single colours of the "Lantern Glass" look of Snake (docs/design/snake-art.md), by name, in the order of the list in
   SnakeLook. SnakeLook:Colour gives the 0xRRGGBB number of one. The snake's and the apple's rows of five tones are made from
   their base colours: see SnakeLook:ToneRow. */
ENUM ProGriddle.Games.Snake.SnakeTint:

    DEFINE ENUM NightTop = 0
                NightBottom
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
                FloorA
                FloorB
                RingHigh
                RingLow
                Lamp
                Eye
                Pupil
                Tongue
                Stem
                Leaf
                HeadBase
                BodyBase
                TailBase
                BodyBright
                Apple
                Shade
                CrashEnd.

END ENUM.
