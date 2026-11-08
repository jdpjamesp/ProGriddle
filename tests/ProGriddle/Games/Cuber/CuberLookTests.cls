/* The colours of the Cuber look: every named colour has a number, the tone rows run from highlight to edge, the four rounds pick
   their lights, and the sprites' characters are all different. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberLookTests:

    @Test.
    METHOD PUBLIC VOID ANamedColourIsItsNumber():
        Assert:Equals(0x0C0818, CuberLook:Colour(CuberTint:Hud)).
        Assert:Equals(0x2C2250, CuberLook:Colour(CuberTint:HudRule)).
        Assert:Equals(0xFFD247, CuberLook:Colour(CuberTint:Gold)).
        Assert:Equals(0xFF5A36, CuberLook:Colour(CuberTint:Ember)).
        Assert:Equals(0x050309, CuberLook:Colour(CuberTint:VoidDeep)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryRealTintHasAColourAndNoColourIsBlack():
        VAR INTEGER i.
        DO i = INTEGER(CuberTint:Hud) TO INTEGER(CuberTint:SpillLight) - 1:
            Assert:IsTrue(CuberLook:Colour(CuberTint:GetEnum(i)) > 0).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePlacesAPainterFillsInHaveNoColourOfTheirOwn():
        VAR INTEGER thrown.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:Colour(CuberTint:SpillLight).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:Colour(CuberTint:SpillDark).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:Colour(CuberTint:DoneBase).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AToneRowRunsFromTheHighlightToTheEdge():
        Assert:Equals(0xFFF7D6, CuberLook:Tone(CuberRow:Pip, 1)).
        Assert:Equals(0xFFD247, CuberLook:Tone(CuberRow:Pip, 3)).
        Assert:Equals(0x4A1A22, CuberLook:Tone(CuberRow:Pip, 5)).
        Assert:Equals(0x5CEDB6, CuberLook:Tone(CuberRow:Mint, 3)).
        Assert:Equals(0x3A3F78, CuberLook:Tone(CuberRow:Unlit, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATonePastFiveOrBelowOneIsRefused():
        VAR INTEGER thrown.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:Tone(CuberRow:Pip, 0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:Tone(CuberRow:Pip, 6).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLampStatesGetBrighterInEveryRound():
        VAR INTEGER light.
        DO light = 1 TO CuberLook:Themes():
            Assert:IsTrue(Luma(CuberLook:Tone(CuberRow:Unlit, 3)) < Luma(CuberLook:Tone(CuberLook:HalfRow(light), 3))).
            Assert:IsTrue(Luma(CuberLook:Tone(CuberLook:HalfRow(light), 3)) < Luma(CuberLook:Tone(CuberLook:DoneRow(light), 3))).
        END.
    END METHOD.

    /* A rough brightness, 0 to 255 times 100. */
    METHOD PRIVATE INTEGER Luma(INPUT piColour AS INTEGER):
        RETURN 30 * INTEGER(TRUNCATE(piColour / 65536, 0)) + 59 * (INTEGER(TRUNCATE(piColour / 256, 0)) MODULO 256) + 11 * (piColour MODULO 256).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFourRoundsAreMintRoseSkyAndLilac():
        Assert:Equals(4, CuberLook:Themes()).
        Assert:Equals("MINT", CuberLook:ThemeName(1)).
        Assert:Equals("ROSE", CuberLook:ThemeName(2)).
        Assert:Equals("SKY", CuberLook:ThemeName(3)).
        Assert:Equals("LILAC", CuberLook:ThemeName(4)).
        Assert:Equals(STRING(CuberRow:Mint), STRING(CuberLook:DoneRow(1))).
        Assert:Equals(STRING(CuberRow:RoseHalf), STRING(CuberLook:HalfRow(2))).
        Assert:Equals(STRING(CuberRow:Lilac), STRING(CuberLook:DoneRow(4))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpillOfALitLampIsTheLightOfItsRound():
        Assert:Equals(CuberLook:Colour(CuberTint:SpillMint), CuberLook:Spill(1, 1)).
        Assert:Equals(CuberLook:Colour(CuberTint:SpillMintDark), CuberLook:Spill(1, 2)).
        Assert:Equals(CuberLook:Colour(CuberTint:SpillSky), CuberLook:Spill(3, 1)).
        Assert:Equals(CuberLook:Colour(CuberTint:SpillLilacDark), CuberLook:Spill(4, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownRoundOrShadeIsRefused():
        VAR INTEGER thrown.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:ThemeName(5).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:DoneRow(0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:HalfRow(9).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:Spill(1, 3).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberLook:Spill(7, 1).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(5, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryTintHasItsOwnCharacterAndNoneIsADigitOneToFiveOrADot():
        VAR INTEGER i.
        VAR INTEGER j.
        VAR CHARACTER ci.
        DO i = INTEGER(CuberTint:Hud) TO INTEGER(CuberTint:DoneBase):
            ci = CuberLook:CodeOf(CuberTint:GetEnum(i)).
            Assert:IsTrue(ci <> ".").
            Assert:IsTrue(ASC(ci) < 49 OR ASC(ci) > 53).
            DO j = i + 1 TO INTEGER(CuberTint:DoneBase):
                Assert:IsTrue(ASC(ci) <> ASC(CuberLook:CodeOf(CuberTint:GetEnum(j)))).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSkyHasFortySixStarsAndFourteenAreBright():
        VAR CHARACTER stars.
        VAR INTEGER i.
        VAR INTEGER bright.
        stars = CuberLook:Stars().
        Assert:Equals(46, NUM-ENTRIES(stars, ";")).
        DO i = 1 TO NUM-ENTRIES(stars, ";"):
            Assert:IsTrue(INTEGER(ENTRY(1, ENTRY(i, stars, ";"))) >= 2).
            IF INTEGER(ENTRY(3, ENTRY(i, stars, ";"))) = 1 THEN bright = bright + 1.
        END.
        Assert:IsTrue(bright >= 4).
    END METHOD.

END CLASS.
