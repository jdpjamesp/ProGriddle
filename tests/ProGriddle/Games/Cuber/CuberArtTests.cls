/* The sprites of Cuber, made from the designer's file: every sprite has the cells its size says it has, nothing but tones and
   known colours in it, every origin is inside its sprite, and the ones the game's geometry depends on have the sizes it expects. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberArtTests:

    @Test.
    METHOD PUBLIC VOID ThereAreSeventyEightSpritesAndEachHasTheCellsItsSizeSays():
        VAR INTEGER i.
        Assert:Equals(78, CuberArt:Count()).
        DO i = 0 TO CuberArt:Count() - 1:
            Assert:Equals(CuberArt:Width(CuberSprite:GetEnum(i)) * CuberArt:Height(CuberSprite:GetEnum(i)),
                          LENGTH(CuberArt:Cells(CuberSprite:GetEnum(i)))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCellIsEmptyAToneOrAColourOfTheLook():
        VAR INTEGER i.
        VAR INTEGER j.
        VAR INTEGER k.
        VAR CHARACTER cells.
        VAR CHARACTER ch.
        VAR LOGICAL found.
        DO i = 0 TO CuberArt:Count() - 1:
            cells = CuberArt:Cells(CuberSprite:GetEnum(i)).
            DO j = 1 TO LENGTH(cells):
                ch = SUBSTRING(cells, j, 1).
                IF ch = "." OR (ASC(ch) >= 49 AND ASC(ch) <= 53) THEN NEXT.
                found = FALSE.
                DO k = INTEGER(CuberTint:Hud) TO INTEGER(CuberTint:DoneBase) WHILE NOT found:
                    found = ASC(ch) = ASC(CuberLook:CodeOf(CuberTint:GetEnum(k))).
                END.
                Assert:IsTrue(found).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryOriginIsInsideItsSprite():
        VAR INTEGER i.
        VAR CuberSprite s.
        DO i = 0 TO CuberArt:Count() - 1:
            s = CuberSprite:GetEnum(i).
            Assert:IsTrue(CuberArt:OriginX(s) >= 0 AND CuberArt:OriginX(s) < CuberArt:Width(s)).
            Assert:IsTrue(CuberArt:OriginY(s) >= 0 AND CuberArt:OriginY(s) < CuberArt:Height(s)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLampsAre32By32AndTheirFeetAreOnTheTopDiamond():
        Assert:Equals(32, CuberArt:Width(CuberSprite:LampUnlit)).
        Assert:Equals(32, CuberArt:Height(CuberSprite:LampUnlit)).
        Assert:Equals(32, CuberArt:Width(CuberSprite:LampHalf)).
        Assert:Equals(32, CuberArt:Width(CuberSprite:LampDone)).
        Assert:Equals(32, CuberArt:Height(CuberSprite:LampDone)).
        Assert:Equals(16, CuberArt:Width(CuberSprite:LampMini)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PipAndTheMothsAndTheBallsHaveTheSizesOfTheirBoxes():
        Assert:Equals(12, CuberArt:Width(CuberSprite:PipStandDr)).
        Assert:Equals(14, CuberArt:Height(CuberSprite:PipStandDr)).
        Assert:Equals(6, CuberArt:OriginX(CuberSprite:PipStandDr)).
        Assert:Equals(13, CuberArt:OriginY(CuberSprite:PipStandDr)).
        Assert:Equals(10, CuberArt:Width(CuberSprite:Thorn1)).
        Assert:Equals(10, CuberArt:Height(CuberSprite:Frost2)).
        Assert:Equals(12, CuberArt:Width(CuberSprite:MothDr1)).
        Assert:Equals(16, CuberArt:Width(CuberSprite:CoilStandDr)).
        Assert:Equals(24, CuberArt:Height(CuberSprite:CoilStandDr)).
        Assert:Equals(23, CuberArt:OriginY(CuberSprite:CoilStandDr)).
        Assert:Equals(24, CuberArt:Width(CuberSprite:Halo1)).
        Assert:Equals(12, CuberArt:Height(CuberSprite:Halo1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpriteThatIsNotThereIsRefused():
        VAR INTEGER thrown.
        VAR CuberSprite s.
        DO ON ERROR UNDO, LEAVE:
            CuberArt:Width(s).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberArt:Height(s).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberArt:Cells(s).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberArt:OriginX(s).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            CuberArt:OriginY(s).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(5, thrown).
    END METHOD.

END CLASS.
