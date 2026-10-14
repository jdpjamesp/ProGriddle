USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SpriteTests:

    METHOD PRIVATE LOGICAL Refused(INPUT pcRows AS CHARACTER):
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW Sprite(pcRows).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        RETURN thrown.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpriteHasTheSizeOfItsPicture():
        DEFINE VARIABLE s AS Sprite NO-UNDO.
        s = NEW Sprite("..#../.###./#####").
        Assert:Equals(5, s:Width).
        Assert:Equals(3, s:Height).
        Assert:Equals(9, s:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCellsAreListedRowByRowFromTheTopLeft():
        DEFINE VARIABLE s AS Sprite NO-UNDO.
        s = NEW Sprite(".#./#.#").
        Assert:Equals(3, s:Count).
        Assert:Equals(1, s:CellX(0)).
        Assert:Equals(0, s:CellY(0)).
        Assert:Equals(0, s:CellX(1)).
        Assert:Equals(1, s:CellY(1)).
        Assert:Equals(2, s:CellX(2)).
        Assert:Equals(1, s:CellY(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheThreeTonesAreReadFromHashPlusAndStar():
        DEFINE VARIABLE s AS Sprite NO-UNDO.
        s = NEW Sprite("#+*").
        Assert:Equals(1, s:CellTone(0)).
        Assert:Equals(2, s:CellTone(1)).
        Assert:Equals(3, s:CellTone(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToneAtGivesTheToneOfAPositionAndZeroForEmptyOrOutside():
        DEFINE VARIABLE s AS Sprite NO-UNDO.
        s = NEW Sprite("#.+/.*.").
        Assert:Equals(1, s:ToneAt(0, 0)).
        Assert:Equals(0, s:ToneAt(1, 0)).
        Assert:Equals(2, s:ToneAt(2, 0)).
        Assert:Equals(3, s:ToneAt(1, 1)).
        Assert:Equals(0, s:ToneAt(5, 5)).
        Assert:Equals(0, s:ToneAt(-1, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShortRowIsEmptyToTheRight():
        DEFINE VARIABLE s AS Sprite NO-UNDO.
        s = NEW Sprite("###/#").
        Assert:Equals(3, s:Width).
        Assert:Equals(4, s:Count).
        Assert:Equals(0, s:ToneAt(2, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ToStringWritesThePictureBackWithEveryRowAsWideAsTheWidest():
        DEFINE VARIABLE s AS Sprite NO-UNDO.
        s = NEW Sprite("#+*/#").
        Assert:Equals("#+*/#..", s:ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePictureOfTheArcadeSquidRoundTrips():
        DEFINE VARIABLE picture AS CHARACTER NO-UNDO.
        picture = "...##.../..####../.######./##.##.##/########/..#..#../.#.##.#./#.#..#.#".
        Assert:Equals("...##.../..####../.######./##.##.##/########/..#..#../.#.##.#./#.#..#.#", NEW Sprite(picture):ToString()).
        Assert:Equals(8, NEW Sprite(picture):Width).
        Assert:Equals(8, NEW Sprite(picture):Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadPictureIsRefused():
        Assert:IsTrue(Refused("")).
        Assert:IsTrue(Refused(?)).
        Assert:IsTrue(Refused("...")).
        Assert:IsTrue(Refused("#x#")).
        Assert:IsTrue(Refused("#%#")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACellIndexOutOfRangeIsRefused():
        DEFINE VARIABLE s      AS Sprite  NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        s = NEW Sprite("##").
        DO ON ERROR UNDO, THROW:
            s:CellX(2).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            s:CellY(-1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            s:CellTone(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
