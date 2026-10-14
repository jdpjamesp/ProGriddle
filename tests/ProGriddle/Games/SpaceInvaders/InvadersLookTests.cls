USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersLookTests:


    @Test.
    METHOD PUBLIC VOID ColoursAreReadFromSixHexDigits():
        Assert:Equals(0, ColourMath:FromHex("000000")).
        Assert:Equals(16777215, ColourMath:FromHex("FFFFFF")).
        Assert:Equals(16744448, ColourMath:FromHex("FF8000")).
        Assert:Equals(255, ColourMath:FromHex("0000ff")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryColourOfTheLookIsThereAndTheSkyGetsLighterTowardsTheHorizon():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:IsTrue(InvadersLook:Count() > 25).
        DO i = 0 TO InvadersLook:Count() - 1:
            Assert:IsTrue(InvadersLook:Colour(Palette:GetEnum(i)) >= 0 AND InvadersLook:Colour(Palette:GetEnum(i)) <= 16777215).
        END.
        Assert:IsTrue(ColourMath:Green(InvadersLook:Colour(Palette:SkyTop)) <= ColourMath:Green(InvadersLook:Colour(Palette:SkyBottom)) OR
                      ColourMath:Blue(InvadersLook:Colour(Palette:SkyTop)) < ColourMath:Blue(InvadersLook:Colour(Palette:SkyBottom))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheThreeInvaderColoursAreDifferent():
        Assert:IsTrue(InvadersLook:Colour(Palette:Squid) <> InvadersLook:Colour(Palette:Crab)).
        Assert:IsTrue(InvadersLook:Colour(Palette:Crab) <> InvadersLook:Colour(Palette:Octopus)).
        Assert:IsTrue(InvadersLook:Colour(Palette:Squid) <> InvadersLook:Colour(Palette:Octopus)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFiveRowColoursRotateByOneEachWave():
        Assert:Equals(InvadersLook:Colour(Palette:Inv1Main), InvadersLook:InvaderColour(0, 1, 1)).
        Assert:Equals(InvadersLook:Colour(Palette:Inv5Main), InvadersLook:InvaderColour(4, 1, 1)).
        Assert:Equals(InvadersLook:Colour(Palette:Inv2Light), InvadersLook:InvaderColour(0, 2, 2)).
        Assert:Equals(InvadersLook:Colour(Palette:Inv1Deep), InvadersLook:InvaderColour(4, 2, 3)).
        Assert:Equals(InvadersLook:InvaderColour(0, 1, 1), InvadersLook:InvaderColour(0, 6, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadRowWaveOrToneOfAnInvaderIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            InvadersLook:InvaderColour(5, 1, 1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvadersLook:InvaderColour(0, 0, 1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvadersLook:InvaderColour(0, 1, 4).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownColourIsRefused():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            InvadersLook:Colour(?).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

END CLASS.
