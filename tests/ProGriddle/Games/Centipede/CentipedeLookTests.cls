/* The colours of the Centipede look: every named colour has a number, they are all different where the picture needs them to be, and
   the cap of a mushroom follows its hit points. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeLookTests:

    @Test.
    METHOD PUBLIC VOID ANamedColourIsItsNumber():
        Assert:Equals(0x0B0E1A, CentipedeLook:Colour(CentipedeTint:Night)).
        Assert:Equals(0xFF4FA3, CentipedeLook:Colour(CentipedeTint:Cap4)).
        Assert:Equals(0xC8FF4D, CentipedeLook:Colour(CentipedeTint:HeadMain)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryTintHasAColourAndNoColourIsBlack():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = INTEGER(CentipedeTint:Night) TO INTEGER(CentipedeTint:Outline):
            Assert:IsTrue(CentipedeLook:Colour(CentipedeTint:GetEnum(i)) > 0).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCapOfAMushroomDarkensWithEachHit():
        Assert:Equals(CentipedeLook:Colour(CentipedeTint:Cap4), CentipedeLook:CapColour(4, FALSE)).
        Assert:Equals(CentipedeLook:Colour(CentipedeTint:Cap3), CentipedeLook:CapColour(3, FALSE)).
        Assert:Equals(CentipedeLook:Colour(CentipedeTint:Cap2), CentipedeLook:CapColour(2, FALSE)).
        Assert:Equals(CentipedeLook:Colour(CentipedeTint:Cap1), CentipedeLook:CapColour(1, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APoisonedMushroomHasACyanCap():
        Assert:Equals(CentipedeLook:Colour(CentipedeTint:PoisonCap), CentipedeLook:CapColour(4, TRUE)).
        Assert:Equals(CentipedeLook:Colour(CentipedeTint:PoisonDark), CentipedeLook:CapColour(1, TRUE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownColourOrHitPointsAreRefused():
        DEFINE VARIABLE thrown AS INTEGER      NO-UNDO.
        DEFINE VARIABLE t      AS CentipedeTint NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:Colour(t).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:CapColour(0, FALSE).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:CapColour(5, TRUE).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
