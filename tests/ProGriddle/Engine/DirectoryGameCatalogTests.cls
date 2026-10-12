USING OpenEdge.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.DirectoryGameCatalogTests:

    DEFINE PRIVATE VARIABLE mFolder AS CHARACTER NO-UNDO.

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
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
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
        DEFINE VARIABLE c AS DirectoryGameCatalog NO-UNDO.
        WriteRunFile("run-tetris.p", "Arcade: Tetris | Falling blocks. Seven bag pieces.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals(1, c:Count).
        Assert:Equals("Tetris", c:TitleAt(1)).
        Assert:Equals("Falling blocks. Seven bag pieces.", c:BlurbAt(1)).
        Assert:Equals("build/test-catalog/run-tetris.p", c:ProgramAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithoutTheLineTheTitleComesFromTheFileName():
        DEFINE VARIABLE c AS DirectoryGameCatalog NO-UNDO.
        WriteRunFile("run-battleships.p", "No tag here.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("Battleships", c:TitleAt(1)).
        Assert:Equals("", c:BlurbAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATitleWithNoBarHasNoBlurb():
        DEFINE VARIABLE c AS DirectoryGameCatalog NO-UNDO.
        WriteRunFile("run-snake.p", "Arcade: Snake Pit").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals("Snake Pit", c:TitleAt(1)).
        Assert:Equals("", c:BlurbAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHiddenFileIsLeftOut():
        DEFINE VARIABLE c AS DirectoryGameCatalog NO-UNDO.
        WriteRunFile("run-arcade.p", "Arcade: hidden").
        WriteRunFile("run-life.p", "Arcade: Life | Cells.").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals(1, c:Count).
        Assert:Equals("Life", c:TitleAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyRunFilesCount():
        DEFINE VARIABLE c AS DirectoryGameCatalog NO-UNDO.
        WriteRunFile("run-life.p", "Arcade: Life | Cells.").
        WriteRunFile("helper.p", "Arcade: Not a game | Ignored.").
        WriteRunFile("run-notes.txt", "Arcade: Not a game | Ignored.").
        OS-CREATE-DIR VALUE(mFolder + "/run-folder.p").
        c = NEW DirectoryGameCatalog(mFolder).
        Assert:Equals(1, c:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGamesAreListedByTitleIgnoringCase():
        DEFINE VARIABLE c AS DirectoryGameCatalog NO-UNDO.
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
        DEFINE VARIABLE c AS DirectoryGameCatalog NO-UNDO.
        WriteRunFile("run-life.p", "Arcade: Life | Cells.").
        c = NEW DirectoryGameCatalog("build~\test-catalog/").
        Assert:Equals(1, c:Count).
        Assert:Equals("build/test-catalog/run-life.p", c:ProgramAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRealRunFolderHasEveryGameButNotTheArcade():
        DEFINE VARIABLE c      AS DirectoryGameCatalog NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE titles AS CHARACTER NO-UNDO.
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
        DEFINE VARIABLE c AS DirectoryGameCatalog NO-UNDO.
        c = NEW DirectoryGameCatalog(mFolder).
        c:TitleAt(1).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheConstructorNeedsAFolder():
        DEFINE VARIABLE c AS DirectoryGameCatalog NO-UNDO.
        c = NEW DirectoryGameCatalog("").
    END METHOD.

END CLASS.
