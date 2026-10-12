USING OpenEdge.Core.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperLevelsTests:

    @Test.
    METHOD PUBLIC VOID TheStandardLevelsAreTheClassicOnes():
        Assert:Equals(9, MinesweeperLevels:WidthOf("Beginner")).
        Assert:Equals(9, MinesweeperLevels:HeightOf("Beginner")).
        Assert:Equals(10, MinesweeperLevels:MinesOf("Beginner")).
        Assert:Equals(16, MinesweeperLevels:WidthOf("Intermediate")).
        Assert:Equals(16, MinesweeperLevels:HeightOf("Intermediate")).
        Assert:Equals(40, MinesweeperLevels:MinesOf("Intermediate")).
        Assert:Equals(30, MinesweeperLevels:WidthOf("Expert")).
        Assert:Equals(16, MinesweeperLevels:HeightOf("Expert")).
        Assert:Equals(99, MinesweeperLevels:MinesOf("Expert")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NamesAreInPickerOrder():
        Assert:Equals("Beginner,Intermediate,Expert,Custom", MinesweeperLevels:Names()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CanonicalFixesTheCaseAndRejectsUnknownNames():
        Assert:Equals("Expert", MinesweeperLevels:Canonical("expert")).
        Assert:Equals("Custom", MinesweeperLevels:Canonical("CUSTOM")).
        Assert:Equals("", MinesweeperLevels:Canonical("Nightmare")).
        Assert:Equals("", MinesweeperLevels:Canonical(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyTheThreeStandardLevelsAreStandard():
        Assert:IsTrue(MinesweeperLevels:IsStandard("Beginner")).
        Assert:IsTrue(MinesweeperLevels:IsStandard("expert")).
        Assert:IsFalse(MinesweeperLevels:IsStandard("Custom")).
        Assert:IsFalse(MinesweeperLevels:IsStandard("Nightmare")).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID WidthOfCustomThrows():
        MinesweeperLevels:WidthOf("Custom").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID HeightOfAnUnknownLevelThrows():
        MinesweeperLevels:HeightOf("Nightmare").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID MinesOfCustomThrows():
        MinesweeperLevels:MinesOf("Custom").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACustomWidthIsKeptFrom9To30():
        Assert:Equals(9, MinesweeperLevels:ClampWidth(2)).
        Assert:Equals(9, MinesweeperLevels:ClampWidth(9)).
        Assert:Equals(17, MinesweeperLevels:ClampWidth(17)).
        Assert:Equals(30, MinesweeperLevels:ClampWidth(30)).
        Assert:Equals(30, MinesweeperLevels:ClampWidth(99)).
        Assert:Equals(9, MinesweeperLevels:ClampWidth(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACustomHeightIsKeptFrom9To24():
        Assert:Equals(9, MinesweeperLevels:ClampHeight(0)).
        Assert:Equals(24, MinesweeperLevels:ClampHeight(24)).
        Assert:Equals(24, MinesweeperLevels:ClampHeight(25)).
        Assert:Equals(9, MinesweeperLevels:ClampHeight(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACustomMineCountIsKeptFrom10ToOneLessThanEachSideProduct():
        Assert:Equals(10, MinesweeperLevels:ClampMines(9, 9, 3)).
        Assert:Equals(25, MinesweeperLevels:ClampMines(9, 9, 25)).
        Assert:Equals(64, MinesweeperLevels:ClampMines(9, 9, 500)).
        Assert:Equals(667, MinesweeperLevels:ClampMines(30, 24, 9999)).
        Assert:Equals(10, MinesweeperLevels:ClampMines(9, 9, ?)).
    END METHOD.

END CLASS.
