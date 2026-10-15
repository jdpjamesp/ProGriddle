/* The tiles of Snake, copied exactly from docs/design/snake-art.md: their sizes, a few pixels that show they are the right
   drawings, and that a size or a food frame that does not exist is refused. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeArtTests:

    @Test.
    METHOD PUBLIC VOID EveryTileIsSquareAtBothSizes():
        DEFINE VARIABLE size AS INTEGER NO-UNDO.
        DEFINE VARIABLE f    AS INTEGER NO-UNDO.
        DO size = 8 TO 16 BY 8:
            Assert:Equals(size, SnakeArt:Head(size):Width).
            Assert:Equals(size, SnakeArt:Head(size):Height).
            Assert:Equals(size, SnakeArt:HeadTongue(size):Width).
            Assert:Equals(size, SnakeArt:BodyStraight(size):Height).
            Assert:Equals(size, SnakeArt:BodyCorner(size):Width).
            Assert:Equals(size, SnakeArt:Tail(size):Height).
            DO f = 0 TO 3:
                Assert:Equals(size, SnakeArt:Food(size, f):Width).
                Assert:Equals(size, SnakeArt:Food(size, f):Height).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeadHasItsEyesAndTheTongueTileAddsATongue():
        /* the sixteen pixel head: the eye white at 8, 3 and the pupil at 9, 4; the tongue is 4 pixels at the right edge */
        Assert:Equals("A", SnakeArt:Head(16):PixelAt(8, 3)).
        Assert:Equals("B", SnakeArt:Head(16):PixelAt(9, 4)).
        Assert:Equals(".", SnakeArt:Head(16):PixelAt(15, 6)).
        Assert:Equals("T", SnakeArt:HeadTongue(16):PixelAt(15, 6)).
        Assert:Equals("T", SnakeArt:HeadTongue(8):PixelAt(7, 3)).
        Assert:Equals(".", SnakeArt:Head(8):PixelAt(7, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBodyIsATubeWithAnEdgeAndTheTailTapersToATip():
        Assert:Equals(".", SnakeArt:BodyStraight(16):PixelAt(0, 0)).
        Assert:Equals("5", SnakeArt:BodyStraight(16):PixelAt(0, 2)).
        Assert:Equals("2", SnakeArt:Tail(16):PixelAt(0, 7)).
        Assert:Equals(".", SnakeArt:Tail(16):PixelAt(15, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFoodHasAStemAndALeafAndTheLastFrameHasAGlint():
        Assert:Equals("W", SnakeArt:Food(16, 3):PixelAt(4, 5)).
        Assert:IsFalse(SnakeArt:Food(16, 0):PixelAt(4, 5) = "W").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASizeOrAFrameThatDoesNotExistIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            SnakeArt:Head(12).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SnakeArt:Food(16, 4).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            SnakeArt:Food(16, -1).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
