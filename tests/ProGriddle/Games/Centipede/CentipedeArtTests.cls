/* The sprites of Centipede, made from the designer's file: every sprite has the size it is said to have, nothing but known colours in
   it, and the ones the game's boxes depend on have the sizes the game expects. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeArtTests:

    @Test.
    METHOD PUBLIC VOID ThereAreFiftyTwoSpritesAndEachHasTheCellsItsSizeSays():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(52, CentipedeArt:Count()).
        DO i = 0 TO CentipedeArt:Count() - 1:
            Assert:Equals(CentipedeArt:Width(CentipedeSprite:GetEnum(i)) * CentipedeArt:Height(CentipedeSprite:GetEnum(i)),
                          LENGTH(CentipedeArt:Cells(CentipedeSprite:GetEnum(i)))).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCellIsEmptyOrAColourOfTheLook():
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE k     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cells AS CHARACTER NO-UNDO.
        DEFINE VARIABLE known AS CHARACTER NO-UNDO.
        DEFINE VARIABLE ch    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE found AS LOGICAL   NO-UNDO.
        DO i = 0 TO CentipedeArt:Count() - 1:
            cells = CentipedeArt:Cells(CentipedeSprite:GetEnum(i)).
            DO j = 1 TO LENGTH(cells):
                ch = SUBSTRING(cells, j, 1).
                IF ch = "." THEN NEXT.
                found = FALSE.
                DO k = INTEGER(CentipedeTint:Night) TO INTEGER(CentipedeTint:FamilyDeep) WHILE NOT found:
                    found = ASC(ch) = ASC(CentipedeLook:CodeOf(CentipedeTint:GetEnum(k))).
                END.
                Assert:IsTrue(found).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpritesTheGamesBoxesDependOnHaveTheirSizes():
        Assert:Equals(8, CentipedeArt:Width(CentipedeSprite:Bulb4)).
        Assert:Equals(8, CentipedeArt:Height(CentipedeSprite:Bulb4)).
        Assert:Equals(8, CentipedeArt:Width(CentipedeSprite:Head1)).
        Assert:Equals(8, CentipedeArt:Width(CentipedeSprite:Bead1)).
        Assert:Equals(8, CentipedeArt:Width(CentipedeSprite:Wick1)).
        Assert:Equals(8, CentipedeArt:Width(CentipedeSprite:Sower1)).
        Assert:Equals(16, CentipedeArt:Width(CentipedeSprite:Skitterjack1)).
        Assert:Equals(8, CentipedeArt:Height(CentipedeSprite:Skitterjack1)).
        Assert:Equals(16, CentipedeArt:Width(CentipedeSprite:Moonsnail1)).
        Assert:Equals(2, CentipedeArt:Width(CentipedeSprite:Spark)).
        Assert:Equals(8, CentipedeArt:Height(CentipedeSprite:Spark)).
        Assert:Equals(16, CentipedeArt:Width(CentipedeSprite:WickBreak1)).
        Assert:Equals(16, CentipedeArt:Height(CentipedeSprite:WickBreak6)).
        Assert:Equals(7, CentipedeArt:Width(CentipedeSprite:Moon1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABulbKeepsItsTipInEveryState():
        /* the tip is at column 4 of the top row of every bulb, whole, worn or blighted */
        Assert:IsTrue(SUBSTRING(CentipedeArt:Cells(CentipedeSprite:Bulb4), 5, 1) <> ".").
        Assert:IsTrue(SUBSTRING(CentipedeArt:Cells(CentipedeSprite:Bulb1), 5, 1) <> ".").
        Assert:IsTrue(SUBSTRING(CentipedeArt:Cells(CentipedeSprite:Blight4), 5, 1) <> ".").
        Assert:IsTrue(SUBSTRING(CentipedeArt:Cells(CentipedeSprite:Blight1), 5, 1) <> ".").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASpriteThatIsNotThereIsRefused():
        DEFINE VARIABLE thrown AS INTEGER        NO-UNDO.
        DEFINE VARIABLE none   AS CentipedeSprite NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CentipedeArt:Cells(none).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeArt:Width(none).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            CentipedeArt:Height(none).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
