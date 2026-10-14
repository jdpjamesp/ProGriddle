USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersLookTests:

    {ProGriddle/Games/SpaceInvaders/Colours.i}

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
        DO i = 1 TO InvadersLook:Count():
            Assert:IsTrue(InvadersLook:Colour(i) >= 0 AND InvadersLook:Colour(i) <= 16777215).
        END.
        Assert:IsTrue(ColourMath:Green(InvadersLook:Colour({&C-SKY-TOP})) <= ColourMath:Green(InvadersLook:Colour({&C-SKY-BOTTOM})) OR
                      ColourMath:Blue(InvadersLook:Colour({&C-SKY-TOP})) < ColourMath:Blue(InvadersLook:Colour({&C-SKY-BOTTOM}))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheThreeInvaderColoursAreDifferent():
        Assert:IsTrue(InvadersLook:Colour({&C-SQUID}) <> InvadersLook:Colour({&C-CRAB})).
        Assert:IsTrue(InvadersLook:Colour({&C-CRAB}) <> InvadersLook:Colour({&C-OCTOPUS})).
        Assert:IsTrue(InvadersLook:Colour({&C-SQUID}) <> InvadersLook:Colour({&C-OCTOPUS})).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFiveRowColoursRotateByOneEachWave():
        Assert:Equals(InvadersLook:Colour({&C-INV1-MAIN}), InvadersLook:InvaderColour(0, 1, 1)).
        Assert:Equals(InvadersLook:Colour({&C-INV5-MAIN}), InvadersLook:InvaderColour(4, 1, 1)).
        Assert:Equals(InvadersLook:Colour({&C-INV2-LIGHT}), InvadersLook:InvaderColour(0, 2, 2)).
        Assert:Equals(InvadersLook:Colour({&C-INV1-DEEP}), InvadersLook:InvaderColour(4, 2, 3)).
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
    METHOD PUBLIC VOID ABadColourNumberIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            InvadersLook:Colour(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvadersLook:Colour(InvadersLook:Count() + 1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvadersLook:Colour(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
