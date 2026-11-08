USING OpenEdge.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.DirectoryGameCatalogTests:

    VAR PRIVATE CHARACTER mFolder.

    @Setup.
    METHOD PUBLIC VOID MakeFolder():
        mFolder = "build/test-catalog".
        OS-DELETE VALUE(mFolder) RECURSIVE.
        OS-CREATE-DIR VALUE(mFolder).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID RemoveFolder():
        OS-DELETE VALUE(mFolder) RECURSIVE.
    END METHOD.

    /* Writes a run file whose header comment has the given lines. */
    METHOD PRIVATE VOID WriteRunFile(INPUT pcName AS CHARACTER, INPUT pcHeaderLines AS CHARACTER):
        VAR INTEGER i.
        OUTPUT TO VALUE(mFolder + "/" + pcName).
        PUT UNFORMATTED "/* A composition root." SKIP.
        DO i = 1 TO NUM-ENTRIES(pcHeaderLines, "~n"):
            IF ENTRY(i, pcHeaderLines, "~n") <> "" THEN PUT UNFORMATTED "   " ENTRY(i, pcHeaderLines, "~n") SKIP.
        END.
        PUT UNFORMATTED "*/" SKIP "QUIT." SKIP.
        OUTPUT CLOSE.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFolderWithNoRunFilesIsAnEmptyCatalog():
        Assert:Equals(0, NEW DirectoryGameCatalog(mFolder):Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFolderThatDoesNotExistIsAnEmptyCatalog():
        Assert:Equals(0, NEW DirectoryGameCatalog("build/no-such-folder"):Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleAndBlurbComeFromTheArcadeLine():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-tetris.p", "Arcade: Tetris | Falling blocks. Seven bag pieces.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals(1, c:Count).
        Assert:Equals("Tetris", c:TitleAt(1)).
        Assert:Equals("Falling blocks. Seven bag pieces.", c:BlurbAt(1)).
        Assert:Equals("build/test-catalog/run-tetris.p", c:ProgramAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithoutTheLineTheTitleComesFromTheFileName():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-battleships.p", "No tag here.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("Battleships", c:TitleAt(1)).
        Assert:Equals("", c:BlurbAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATitleWithNoBarHasNoBlurb():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-snake.p", "Arcade: Snake Pit").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("Snake Pit", c:TitleAt(1)).
        Assert:Equals("", c:BlurbAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHiddenFileIsLeftOut():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-arcade.p", "Arcade: hidden").
        WriteRunFile("run-life.p", "Arcade: Life | Cells.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals(1, c:Count).
        Assert:Equals("Life", c:TitleAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyRunFilesCount():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-life.p", "Arcade: Life | Cells.").
        WriteRunFile("helper.p", "Arcade: Not a game | Ignored.").
        WriteRunFile("run-notes.txt", "Arcade: Not a game | Ignored.").
        OS-CREATE-DIR VALUE(mFolder + "/run-folder.p").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals(1, c:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGamesAreListedByTitleIgnoringCase():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-z.p", "Arcade: zebra | Last.").
        WriteRunFile("run-m.p", "Arcade: Mouse | Middle.").
        WriteRunFile("run-a.p", "Arcade: aardvark | First.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals(3, c:Count).
        Assert:Equals("aardvark", c:TitleAt(1)).
        Assert:Equals("Mouse", c:TitleAt(2)).
        Assert:Equals("zebra", c:TitleAt(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewRunFileShowsUpInANewCatalog():
        WriteRunFile("run-life.p", "Arcade: Life | Cells.").
        Assert:Equals(1, NEW DirectoryGameCatalog(mFolder):Count).
        WriteRunFile("run-snake.p", "Arcade: Snake | Eat.").
        Assert:Equals(2, NEW DirectoryGameCatalog(mFolder):Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFolderNameWithABackslashAndATrailingSlashWorks():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-life.p", "Arcade: Life | Cells.").
        c = NEW DirectoryGameCatalog("build~\test-catalog/").
        Assert:Equals(1, c:Count).
        Assert:Equals("build/test-catalog/run-life.p", c:ProgramAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRealRunFolderHasEveryGameButNotTheArcade():
        VAR DirectoryGameCatalog c.
        VAR INTEGER i.
        VAR CHARACTER titles.
        c = NEW DirectoryGameCatalog("run").
        DO i = 1 TO c:Count:
            titles = titles + "," + c:TitleAt(i).
        END.
        Assert:IsTrue(LOOKUP("Life", titles) > 0).
        Assert:IsTrue(LOOKUP("Minesweeper", titles) > 0).
        Assert:IsTrue(LOOKUP("Battleships", titles) > 0).
        Assert:IsTrue(LOOKUP("Tetris", titles) > 0).
        Assert:Equals(0, LOOKUP("Arcade", titles)).
        Assert:Equals(0, INDEX(titles, "hidden")).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID APlaceOffTheListThrows():
        VAR DirectoryGameCatalog c = NEW DirectoryGameCatalog(mFolder).
        c:TitleAt(1).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheConstructorNeedsAFolder():
        VAR DirectoryGameCatalog c = NEW DirectoryGameCatalog("").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATitleBlurbAndColourAreReadFromTheThreePartsOfTheLine():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-tetris.p", "Arcade: Tetris | Falling blocks. | Purple").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("Tetris", c:TitleAt(1)).
        Assert:Equals("Falling blocks.", c:BlurbAt(1)).
        Assert:Equals("purple", c:AccentAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithoutAThirdPartThereIsNoColour():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-a.p", "Arcade: Alpha | The first.").
        WriteRunFile("run-b.p", "Arcade: Beta").
        WriteRunFile("run-c.p", "No tag here.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("", c:AccentAt(1)).
        Assert:Equals("", c:AccentAt(2)).
        Assert:Equals("", c:AccentAt(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AColourWithAnEmptyBlurbIsStillRead():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-a.p", "Arcade: Alpha | | teal").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("Alpha", c:TitleAt(1)).
        Assert:Equals("", c:BlurbAt(1)).
        Assert:Equals("teal", c:AccentAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFourGamesAskForTheColoursOfTheArtwork():
        VAR DirectoryGameCatalog c.
        VAR INTEGER i.
        c = NEW DirectoryGameCatalog("run").
        DO i = 1 TO c:Count:
            IF c:TitleAt(i) = "Battleships" THEN Assert:Equals("red", c:AccentAt(i)).
            IF c:TitleAt(i) = "Life" THEN Assert:Equals("orange", c:AccentAt(i)).
            IF c:TitleAt(i) = "Minesweeper" THEN Assert:Equals("blue", c:AccentAt(i)).
            IF c:TitleAt(i) = "Tetris" THEN Assert:Equals("purple", c:AccentAt(i)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCategoryComesFromItsOwnLine():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-a.p", "Arcade: Alpha | The first. | teal~nCategory: Puzzle").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("Alpha", c:TitleAt(1)).
        Assert:Equals("teal", c:AccentAt(1)).
        Assert:Equals("Puzzle", c:CategoryAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCategoryLineMayComeBeforeTheArcadeLine():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-a.p", "Category:   Strategy  ~nArcade: Alpha | The first.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("Alpha", c:TitleAt(1)).
        Assert:Equals("The first.", c:BlurbAt(1)).
        Assert:Equals("Strategy", c:CategoryAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithoutACategoryLineTheCategoryIsEmpty():
        VAR DirectoryGameCatalog c.
        WriteRunFile("run-a.p", "Arcade: Alpha | The first.").
        WriteRunFile("run-b.p", "No tag here.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("", c:CategoryAt(1)).
        Assert:Equals("", c:CategoryAt(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryRealGameHasACategory():
        VAR DirectoryGameCatalog c.
        VAR INTEGER i.
        c = NEW DirectoryGameCatalog("run").
        DO i = 1 TO c:Count:
            Assert:IsTrue(c:CategoryAt(i) <> "").
        END.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID CategoryAtAPlaceOffTheListThrows():
        VAR DirectoryGameCatalog c = NEW DirectoryGameCatalog(mFolder).
        c:CategoryAt(1).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AccentAtAPlaceOffTheListThrows():
        VAR DirectoryGameCatalog c = NEW DirectoryGameCatalog(mFolder).
        c:AccentAt(1).
    END METHOD.

END CLASS.
