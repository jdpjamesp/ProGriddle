/* The colours of the Centipede look: every named colour has a number, the six families of the nights pair up so the crawler is never on
   bulbs of its own colour, and the wave picks its night. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeLookTests:

    @Test.
    METHOD PUBLIC VOID ANamedColourIsItsNumber():
        Assert:Equals(0x0A0E22, CentipedeLook:Colour(CentipedeTint:Night)).
        Assert:Equals(0xFFD040, CentipedeLook:Colour(CentipedeTint:Wick)).
        Assert:Equals(0xFF4030, CentipedeLook:Colour(CentipedeTint:Ember)).
        Assert:Equals(0xDCD0F8, CentipedeLook:Colour(CentipedeTint:Blight)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryRealTintHasAColourAndNoColourIsBlack():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = INTEGER(CentipedeTint:Night) TO INTEGER(CentipedeTint:FamilyLight) - 1:
            Assert:IsTrue(CentipedeLook:Colour(CentipedeTint:GetEnum(i)) > 0).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFamilyPlacesHaveNoColourOfTheirOwn():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:Colour(CentipedeTint:FamilyBody).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:Colour(CentipedeTint:FamilyLight).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownColourIsRefused():
        DEFINE VARIABLE thrown AS INTEGER       NO-UNDO.
        DEFINE VARIABLE t      AS CentipedeTint NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:Colour(t).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryColourHasItsOwnCharacterInASprite():
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE j    AS INTEGER NO-UNDO.
        DEFINE VARIABLE lastTint AS INTEGER NO-UNDO.
        lastTint = INTEGER(CentipedeTint:FamilyDeep).
        DO i = INTEGER(CentipedeTint:Night) TO lastTint:
            Assert:IsTrue(CentipedeLook:CodeOf(CentipedeTint:GetEnum(i)) <> ".").
            DO j = i + 1 TO lastTint:
                /* ASC tells upper and lower case apart, which a plain comparison does not */
                Assert:IsTrue(ASC(CentipedeLook:CodeOf(CentipedeTint:GetEnum(i))) <> ASC(CentipedeLook:CodeOf(CentipedeTint:GetEnum(j)))).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAreSixFamiliesWithALightABodyAndADeepColour():
        DEFINE VARIABLE f AS INTEGER NO-UNDO.
        Assert:Equals(6, CentipedeLook:Families()).
        DO f = 1 TO 6:
            Assert:IsTrue(CentipedeLook:FamilyColour(f, 1) <> CentipedeLook:FamilyColour(f, 2)).
            Assert:IsTrue(CentipedeLook:FamilyColour(f, 2) <> CentipedeLook:FamilyColour(f, 3)).
            Assert:IsTrue(CentipedeLook:FamilyName(f) <> "").
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstNightIsANewMoonWithAnOrchidCrawlerOnJadeBulbs():
        Assert:Equals("NEW MOON", CentipedeLook:NightName(1)).
        Assert:Equals("Orchid", CentipedeLook:FamilyName(CentipedeLook:CrawlerFamily(1))).
        Assert:Equals("Jade", CentipedeLook:FamilyName(CentipedeLook:BulbFamily(1))).
        Assert:Equals(0xDA4EC6, CentipedeLook:FamilyColour(CentipedeLook:CrawlerFamily(1), 2)).
        Assert:Equals(0x2EB06A, CentipedeLook:FamilyColour(CentipedeLook:BulbFamily(1), 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCrawlerIsNeverOnBulbsOfItsOwnColourAndTheNightsRepeatEverySixWaves():
        DEFINE VARIABLE w AS INTEGER NO-UNDO.
        Assert:Equals(6, CentipedeLook:Nights()).
        DO w = 1 TO 12:
            Assert:IsTrue(CentipedeLook:CrawlerFamily(w) <> CentipedeLook:BulbFamily(w)).
            Assert:Equals(CentipedeLook:CrawlerFamily(w), CentipedeLook:CrawlerFamily(w + 6)).
            Assert:Equals(CentipedeLook:BulbFamily(w), CentipedeLook:BulbFamily(w + 6)).
            Assert:Equals(CentipedeLook:NightName(w), CentipedeLook:NightName(w + 6)).
        END.
        Assert:Equals("WANING", CentipedeLook:NightName(6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryFamilyTakesBothJobsInTheCycle():
        DEFINE VARIABLE w       AS INTEGER NO-UNDO.
        DEFINE VARIABLE crawler AS INTEGER NO-UNDO.
        DEFINE VARIABLE bulbs   AS INTEGER NO-UNDO.
        DEFINE VARIABLE f       AS INTEGER NO-UNDO.
        DO f = 1 TO 6:
            crawler = 0.
            bulbs = 0.
            DO w = 1 TO 6:
                IF CentipedeLook:CrawlerFamily(w) = f THEN crawler = crawler + 1.
                IF CentipedeLook:BulbFamily(w) = f THEN bulbs = bulbs + 1.
            END.
            Assert:Equals(1, crawler).
            Assert:Equals(1, bulbs).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadFamilyShadeOrWaveIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:FamilyColour(0, 1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:FamilyColour(1, 4).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:FamilyName(7).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:CrawlerFamily(0).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:BulbFamily(?).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeLook:NightName(-1).
            CATCH e6 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(6, thrown).
    END METHOD.

END CLASS.
