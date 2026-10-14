/* The colours of Asteroids: all there, and the ones that must differ do. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsLookTests:


    @Test.
    METHOD PUBLIC VOID EveryColourIsAnRgbNumber():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:IsTrue(AsteroidsLook:Count() >= 60).
        DO i = 0 TO AsteroidsLook:Count() - 1:
            Assert:IsTrue(AsteroidsLook:Colour(Palette:GetEnum(i)) >= 0 AND AsteroidsLook:Colour(Palette:GetEnum(i)) <= 16777215).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheEnumHasAnEntryForEveryColour():
        Assert:Equals(AsteroidsLook:Count() - 1, INTEGER(Palette:ShipDebris6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSparkRampIsFlashThenTheThreeShotTrailColoursAndRampsKnowTheirSteps():
        Assert:Equals(AsteroidsLook:Colour(Palette:Flash), AsteroidsLook:RampColour(Ramp:Spark, 0)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotTrail1), AsteroidsLook:RampColour(Ramp:Spark, 1)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotTrail2), AsteroidsLook:RampColour(Ramp:Spark, 2)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotTrail3), AsteroidsLook:RampColour(Ramp:Spark, 3)).
        Assert:Equals(4, AsteroidsLook:RampSteps(Ramp:Spark)).
        Assert:Equals(4, AsteroidsLook:RampSteps(Ramp:Exhaust)).
        Assert:Equals(6, AsteroidsLook:RampSteps(Ramp:RockDebris)).
        Assert:Equals(6, AsteroidsLook:RampSteps(Ramp:ShipDebris)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSparkInRampRunsTheSparkColoursBackwardsAndTheWarmRampIsTheFirstThreeEmbers():
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotTrail3), AsteroidsLook:RampColour(Ramp:SparkIn, 0)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotTrail2), AsteroidsLook:RampColour(Ramp:SparkIn, 1)).
        Assert:Equals(AsteroidsLook:Colour(Palette:ShotTrail1), AsteroidsLook:RampColour(Ramp:SparkIn, 2)).
        Assert:Equals(AsteroidsLook:Colour(Palette:Flash), AsteroidsLook:RampColour(Ramp:SparkIn, 3)).
        Assert:Equals(4, AsteroidsLook:RampSteps(Ramp:SparkIn)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Ember, 0), AsteroidsLook:RampColour(Ramp:Warm, 0)).
        Assert:Equals(AsteroidsLook:RampColour(Ramp:Ember, 2), AsteroidsLook:RampColour(Ramp:Warm, 2)).
        Assert:Equals(3, AsteroidsLook:RampSteps(Ramp:Warm)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RampsHaveFourOrSixStepsAndRefuseTheRest():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        Assert:Equals(ColourMath:FromHex("FFC24D"), AsteroidsLook:RampColour(Ramp:Exhaust, 0)).
        Assert:Equals(ColourMath:FromHex("5E4318"), AsteroidsLook:RampColour(Ramp:Exhaust, 3)).
        Assert:Equals(ColourMath:FromHex("FFD9B8"), AsteroidsLook:RampColour(Ramp:Ember, 0)).
        Assert:Equals(ColourMath:FromHex("2E0E0E"), AsteroidsLook:RampColour(Ramp:Red, 5)).
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:RampColour(Ramp:Exhaust, 4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:RampColour(Ramp:ShipDebris, 6).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:RampColour(Ramp:Red, -1).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:RampColour(?, 0).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(4, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RocksHaveAColourForEachSizeAndADimOneForTheTitle():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        Assert:Equals(AsteroidsLook:Colour(Palette:RockLarge), AsteroidsLook:SizeColour(FALSE, 1)).
        Assert:Equals(AsteroidsLook:Colour(Palette:RockMedium), AsteroidsLook:SizeColour(FALSE, 2)).
        Assert:Equals(AsteroidsLook:Colour(Palette:RockSmall), AsteroidsLook:SizeColour(FALSE, 3)).
        Assert:Equals(AsteroidsLook:Colour(Palette:AttractLarge), AsteroidsLook:SizeColour(TRUE, 1)).
        Assert:Equals(AsteroidsLook:Colour(Palette:AttractSmall), AsteroidsLook:SizeColour(TRUE, 3)).
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:SizeColour(FALSE, 4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:SizeColour(?, 1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ColoursKeepTheDesignersHexValues():
        Assert:Equals(ColourMath:FromHex("7F8EA3"), AsteroidsLook:Colour(Palette:RockLarge)).
        Assert:Equals(ColourMath:FromHex("FFF4DC"), AsteroidsLook:Colour(Palette:ShipCore)).
        Assert:Equals(ColourMath:FromHex("FF7A4D"), AsteroidsLook:Colour(Palette:SaucerLCore)).
        Assert:Equals(ColourMath:FromHex("FF4040"), AsteroidsLook:Colour(Palette:SaucerSCore)).
        Assert:Equals(ColourMath:FromHex("030508"), AsteroidsLook:Colour(Palette:VoidEdge)).
        Assert:Equals(ColourMath:FromHex("222831"), AsteroidsLook:RampColour(Ramp:RockDebris, 5)).
        Assert:Equals(ColourMath:FromHex("5E4318"), AsteroidsLook:RampColour(Ramp:Exhaust, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRocksGetBrighterAsTheyShrinkSoTheDangerousOnesShow():
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour(Palette:RockLarge)) < ColourMath:Red(AsteroidsLook:Colour(Palette:RockMedium))).
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour(Palette:RockMedium)) < ColourMath:Red(AsteroidsLook:Colour(Palette:RockSmall))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipTheRocksAndTheSaucersAreThreeFamiliesOfColour():
        /* the ship is warm (red above blue), the rocks are cool (blue above red), the saucers are ember (red far above blue) */
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour(Palette:ShipCore)) > ColourMath:Blue(AsteroidsLook:Colour(Palette:ShipCore))).
        Assert:IsTrue(ColourMath:Blue(AsteroidsLook:Colour(Palette:RockLarge)) > ColourMath:Red(AsteroidsLook:Colour(Palette:RockLarge))).
        Assert:IsTrue(ColourMath:Blue(AsteroidsLook:Colour(Palette:RockSmall)) > ColourMath:Red(AsteroidsLook:Colour(Palette:RockSmall))).
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour(Palette:SaucerLCore)) - ColourMath:Blue(AsteroidsLook:Colour(Palette:SaucerLCore)) > 100).
        Assert:IsTrue(ColourMath:Red(AsteroidsLook:Colour(Palette:SaucerSCore)) - ColourMath:Blue(AsteroidsLook:Colour(Palette:SaucerSCore)) > 100).
        Assert:IsTrue(AsteroidsLook:Colour(Palette:SaucerLCore) <> AsteroidsLook:Colour(Palette:SaucerSCore)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatCanOverlapAreNotTheSameColour():
        Assert:IsTrue(AsteroidsLook:Colour(Palette:RockSmall) <> AsteroidsLook:Colour(Palette:TextWhite)).
        Assert:IsTrue(AsteroidsLook:Colour(Palette:RockLarge) <> AsteroidsLook:Colour(Palette:Label)).
        Assert:IsTrue(AsteroidsLook:Colour(Palette:ShipCore) <> AsteroidsLook:Colour(Palette:ShotHead)).
        Assert:IsTrue(AsteroidsLook:Colour(Palette:ShipCore) <> AsteroidsLook:Colour(Palette:TextWhite)).
        Assert:IsTrue(AsteroidsLook:Colour(Palette:DustBright) <> AsteroidsLook:RampColour(Ramp:RockDebris, 5)).
        Assert:IsTrue(AsteroidsLook:Colour(Palette:ShipHalo) <> AsteroidsLook:Colour(Palette:ShipSpine)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADebrisRampFadesFromBrightToDark():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 4:
            Assert:IsTrue(ColourMath:Red(AsteroidsLook:RampColour(Ramp:RockDebris, i)) >= ColourMath:Red(AsteroidsLook:RampColour(Ramp:RockDebris, i + 1))).
            Assert:IsTrue(ColourMath:Red(AsteroidsLook:RampColour(Ramp:ShipDebris, i)) >= ColourMath:Red(AsteroidsLook:RampColour(Ramp:ShipDebris, i + 1))).
            Assert:IsTrue(ColourMath:Red(AsteroidsLook:RampColour(Ramp:Ember, i)) >= ColourMath:Red(AsteroidsLook:RampColour(Ramp:Ember, i + 1))).
            Assert:IsTrue(ColourMath:Red(AsteroidsLook:RampColour(Ramp:Red, i)) >= ColourMath:Red(AsteroidsLook:RampColour(Ramp:Red, i + 1))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownColourIsRefused():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            AsteroidsLook:Colour(?).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

END CLASS.
