/* The colours of Asteroids: all there, and the ones that must differ do. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsLookTests:

    {ProGriddle/Games/Asteroids/Colours.i}

    @Test.
    METHOD PUBLIC VOID EveryColourIsAnRgbNumber():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:IsTrue(AsteroidsLook:Count() >= 60).
        DO i = 1 TO AsteroidsLook:Count():
            Assert:IsTrue(AsteroidsLook:Colour(i) >= 0 AND AsteroidsLook:Colour(i) <= 16777215).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ColoursKeepTheDesignersHexValues():
        Assert:Equals(ColourMath:FromHex("7F8EA3"), AsteroidsLook:Colour({&C-ROCK-LARGE})).
        Assert:Equals(ColourMath:FromHex("FFF4DC"), AsteroidsLook:Colour({&C-SHIP-CORE})).
        Assert:Equals(ColourMath:FromHex("FF7A4D"), AsteroidsLook:Colour({&C-SAUCER-L-CORE})).
        Assert:Equals(ColourMath:FromHex("FF4040"), AsteroidsLook:Colour({&C-SAUCER-S-CORE})).
        Assert:Equals(ColourMath:FromHex("030508"), AsteroidsLook:Colour({&C-VOID-EDGE})).
        Assert:Equals(ColourMath:FromHex("222831"), AsteroidsLook:Colour({&C-ROCK-DEBRIS-1} + 5)).
        Assert:Equals(ColourMath:FromHex("5E4318"), AsteroidsLook:Colour({&C-EXHAUST-1} + 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRocksGetBrighterAsTheyShrinkSoTheDangerousOnesShow():
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour({&C-ROCK-LARGE})) < ColourMath:Red(AsteroidsLook:Colour({&C-ROCK-MEDIUM}))).
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour({&C-ROCK-MEDIUM})) < ColourMath:Red(AsteroidsLook:Colour({&C-ROCK-SMALL}))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipTheRocksAndTheSaucersAreThreeFamiliesOfColour():
        /* the ship is warm (red above blue), the rocks are cool (blue above red), the saucers are ember (red far above blue) */
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour({&C-SHIP-CORE})) > ColourMath:Blue(AsteroidsLook:Colour({&C-SHIP-CORE}))).
        Assert:IsTrue(ColourMath:Blue(AsteroidsLook:Colour({&C-ROCK-LARGE})) > ColourMath:Red(AsteroidsLook:Colour({&C-ROCK-LARGE}))).
        Assert:IsTrue(ColourMath:Blue(AsteroidsLook:Colour({&C-ROCK-SMALL})) > ColourMath:Red(AsteroidsLook:Colour({&C-ROCK-SMALL}))).
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour({&C-SAUCER-L-CORE})) - ColourMath:Blue(AsteroidsLook:Colour({&C-SAUCER-L-CORE})) > 100).
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour({&C-SAUCER-S-CORE})) - ColourMath:Blue(AsteroidsLook:Colour({&C-SAUCER-S-CORE})) > 100).
        Assert:IsTrue(AsteroidsLook:Colour({&C-SAUCER-L-CORE}) <> AsteroidsLook:Colour({&C-SAUCER-S-CORE})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatCanOverlapAreNotTheSameColour():
        Assert:IsTrue(AsteroidsLook:Colour({&C-ROCK-SMALL}) <> AsteroidsLook:Colour({&C-TEXT-WHITE})).
        Assert:IsTrue(AsteroidsLook:Colour({&C-ROCK-LARGE}) <> AsteroidsLook:Colour({&C-LABEL})).
        Assert:IsTrue(AsteroidsLook:Colour({&C-SHIP-CORE}) <> AsteroidsLook:Colour({&C-SHOT-HEAD})).
        Assert:IsTrue(AsteroidsLook:Colour({&C-SHIP-CORE}) <> AsteroidsLook:Colour({&C-TEXT-WHITE})).
        Assert:IsTrue(AsteroidsLook:Colour({&C-DUST-BRIGHT}) <> AsteroidsLook:Colour({&C-ROCK-DEBRIS-1} + 5)).
        Assert:IsTrue(AsteroidsLook:Colour({&C-SHIP-HALO}) <> AsteroidsLook:Colour({&C-SHIP-SPINE})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADebrisRampFadesFromBrightToDark():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 4:
            Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour({&C-ROCK-DEBRIS-1} + i)) >= ColourMath:Red(AsteroidsLook:Colour({&C-ROCK-DEBRIS-1} + i + 1))).
            Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour({&C-SHIP-DEBRIS-1} + i)) >= ColourMath:Red(AsteroidsLook:Colour({&C-SHIP-DEBRIS-1} + i + 1))).
            Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour({&C-EMBER-1} + i)) >= ColourMath:Red(AsteroidsLook:Colour({&C-EMBER-1} + i + 1))).
            Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour({&C-RED-1} + i)) >= ColourMath:Red(AsteroidsLook:Colour({&C-RED-1} + i + 1))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadColourNumberIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:Colour(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:Colour(AsteroidsLook:Count() + 1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:Colour(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
