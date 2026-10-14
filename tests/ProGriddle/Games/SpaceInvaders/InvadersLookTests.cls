USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersLookTests:

    {ProGriddle/Games/SpaceInvaders/Colours.i}

    METHOD PRIVATE LOGICAL Refused(INPUT pcHex AS CHARACTER):
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            InvadersLook:FromHex(pcHex).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        RETURN thrown.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ColoursAreReadFromSixHexDigits():
        Assert:Equals(0, InvadersLook:FromHex("000000")).
        Assert:Equals(16777215, InvadersLook:FromHex("FFFFFF")).
        Assert:Equals(16744448, InvadersLook:FromHex("FF8000")).
        Assert:Equals(255, InvadersLook:FromHex("0000ff")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TextThatIsNotAColourIsRefused():
        Assert:IsTrue(Refused("FFF")).
        Assert:IsTrue(Refused("FFFFFFF")).
        Assert:IsTrue(Refused("GG0000")).
        Assert:IsTrue(Refused("")).
        Assert:IsTrue(Refused(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePartsOfAColourAreItsRedGreenAndBlue():
        Assert:Equals(255, InvadersLook:Red(16744448)).
        Assert:Equals(128, InvadersLook:Green(16744448)).
        Assert:Equals(0, InvadersLook:Blue(16744448)).
        Assert:Equals(7, InvadersLook:Blue(InvadersLook:FromHex("010207"))).
        Assert:Equals(1, InvadersLook:Red(InvadersLook:FromHex("010207"))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RgbPutsThePartsBackTogetherAndKeepsThemInRange():
        Assert:Equals(16744448, InvadersLook:Rgb(255, 128, 0)).
        Assert:Equals(16777215, InvadersLook:Rgb(300, 255, 999)).
        Assert:Equals(0, InvadersLook:Rgb(-5, -1, -300)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MixGoesFromOneColourToTheOtherInEvenSteps():
        DEFINE VARIABLE black AS INTEGER NO-UNDO.
        DEFINE VARIABLE white AS INTEGER NO-UNDO.
        black = 0.
        white = 16777215.
        Assert:Equals(black, InvadersLook:Mix(black, white, 0, 10)).
        Assert:Equals(white, InvadersLook:Mix(black, white, 10, 10)).
        Assert:Equals(InvadersLook:Rgb(128, 128, 128), InvadersLook:Mix(black, white, 5, 10)).
        Assert:Equals(InvadersLook:Rgb(51, 51, 51), InvadersLook:Mix(black, white, 2, 10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MixKeepsItsPartInRangeAndAZeroStepCountGivesTheFirstColour():
        Assert:Equals(16777215, InvadersLook:Mix(0, 16777215, 99, 10)).
        Assert:Equals(0, InvadersLook:Mix(0, 16777215, -4, 10)).
        Assert:Equals(0, InvadersLook:Mix(0, 16777215, 3, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MixWorksOnEachPartSeparatelyAndGoingDown():
        DEFINE VARIABLE start AS INTEGER NO-UNDO.
        DEFINE VARIABLE dest AS INTEGER NO-UNDO.
        start = InvadersLook:Rgb(200, 100, 0).
        dest = InvadersLook:Rgb(0, 100, 200).
        Assert:Equals(InvadersLook:Rgb(100, 100, 100), InvadersLook:Mix(start, dest, 1, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryColourOfTheLookIsThereAndTheSkyGetsLighterTowardsTheHorizon():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:IsTrue(InvadersLook:Count() > 25).
        DO i = 1 TO InvadersLook:Count():
            Assert:IsTrue(InvadersLook:Colour(i) >= 0 AND InvadersLook:Colour(i) <= 16777215).
        END.
        Assert:IsTrue(InvadersLook:Green(InvadersLook:Colour({&C-SKY-TOP})) <= InvadersLook:Green(InvadersLook:Colour({&C-SKY-BOTTOM})) OR
                      InvadersLook:Blue(InvadersLook:Colour({&C-SKY-TOP})) < InvadersLook:Blue(InvadersLook:Colour({&C-SKY-BOTTOM}))).
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
