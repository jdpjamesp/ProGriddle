/* The colours of the Snake look: the named colours, the rows of five tones made from a base colour (checked against the
   rows the designer wrote out in docs/design/snake-art.md), the flash and the crash fade. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeLookTests:

    @Test.
    METHOD PUBLIC VOID ANamedColourIsItsNumberAndItsHex():
        Assert:Equals(ColourMath:FromHex("FFA24A"), SnakeLook:Colour(SnakeTint:Accent)).
        Assert:Equals("0D1420", SnakeLook:Hex(SnakeTint:FloorA)).
        Assert:Equals("101826", SnakeLook:Hex(SnakeTint:FloorB)).
        Assert:Equals("4A5C80", SnakeLook:Hex(SnakeTint:RingHigh)).
        Assert:Equals("CrashEnd", STRING(SnakeTint:CrashEnd)).
        Assert:Equals("2A3345", SnakeLook:Hex(SnakeTint:CrashEnd)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownColourIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE t      AS SnakeTint NO-UNDO.
        DO ON ERROR UNDO, THROW:
            SnakeLook:Colour(t).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SnakeLook:Hex(t).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheToneRowsMatchTheRowsInTheDesign():
        Assert:Equals("CAF3E2,84E2BC,4FD6A0,379472,205243", SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:HeadBase))).
        Assert:Equals("C1E8DA,6DCAA8,2FB383,227C5E,144639", SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:BodyBase))).
        Assert:Equals("BEE0D4,68B89A,27996F,1C6B50,113C32", SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:TailBase))).
        Assert:Equals("DDFAEE,B1F4D8,8FF0C8,63A68D,375C52", SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:BodyBright))).
        Assert:Equals("F7CBC5,ED8777,E5533D,9D3B2E,562320", SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:Apple))).
        Assert:Equals("FFEECD,FFD889,FFC857,AF8B40,5F4D29", SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:Gold))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlendRoundsHalvesToTheEvenNumberAndRefusesNonsense():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        /* half way from 0 to 1 is 0.5, which rounds to 0; from 1 to 2 is 1.5, which rounds to 2 */
        Assert:Equals(0, SnakeLook:Blend(0, 1, 50)).
        Assert:Equals(2, SnakeLook:Blend(1, 2, 50)).
        Assert:Equals(ColourMath:Rgb(100, 150, 200), SnakeLook:Blend(ColourMath:Rgb(100, 150, 200), 0, 0)).
        Assert:Equals(0, SnakeLook:Blend(ColourMath:Rgb(100, 150, 200), 0, 100)).
        DO ON ERROR UNDO, THROW:
            SnakeLook:Blend(0, 0, 101).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AToneRowNeedsAColour():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE c      AS INTEGER NO-UNDO.
        c = ?.
        DO ON ERROR UNDO, THROW:
            SnakeLook:ToneRow(c).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFlashIsWhiteDownToAColdGrey():
        Assert:Equals("FFFFFF,FFFFFF,F4F7FB,D8DEE9,AEB8CB", SnakeLook:FlashTones()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCrashFadeGoesFromTheBodyTowardsTheColourItFadesToInFiveSteps():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        /* a fifth of the way from 2FB383 to 2A3345 is 2E9977 */
        Assert:Equals("2E9977", ENTRY(3, SnakeLook:CrashTones(1))).
        Assert:Equals(SnakeLook:ToneRow(SnakeLook:Colour(SnakeTint:CrashEnd)), SnakeLook:CrashTones(5)).
        DO ON ERROR UNDO, THROW:
            SnakeLook:CrashTones(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SnakeLook:CrashTones(6).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
