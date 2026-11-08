/* Finds the games by looking in a folder for composition roots: the files named run-*.p. Nothing is
   registered anywhere, so a new game shows up as soon as its run file is in the folder.

   A run file can describe itself with one line inside its header comment:
       Arcade: Tetris | Falling blocks. Seven bag pieces, ghost piece and a high score list.
   The words before the bar are the title, the words after it the blurb, and an optional third part after a
   second bar names the colour of the game's button: Arcade: Tetris | Falling blocks. | purple (red, orange,
   blue, purple, green, yellow or teal). Without the line the title
   comes from the file name (run-battleships.p is Battleships) and there is no blurb. A file that is
   not a game for the arcade says "Arcade: hidden" and is left out. The first 60 lines are read.

   A second optional line puts the game in a group, which the arcade shows as a tab:
       Category: Puzzle
   A game with no Category line has an empty category.

   The games are listed by title, ignoring case. The folder is read once, when the catalog is built. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.DirectoryGameCatalog FINAL IMPLEMENTS IGameCatalog:

    DEFINE PRIVATE TEMP-TABLE ttGame NO-UNDO
        FIELD pos     AS INTEGER
        FIELD caption AS CHARACTER
        FIELD blurb   AS CHARACTER
        FIELD accent  AS CHARACTER
        FIELD category AS CHARACTER
        FIELD runFile AS CHARACTER
        INDEX ixPos pos
        INDEX ixCaption caption.

    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The folder is given as it is passed to tools/launch.p, normally "run", relative to where the
       program runs from. A folder that does not exist is an empty catalog. */
    CONSTRUCTOR PUBLIC DirectoryGameCatalog(INPUT pcFolder AS CHARACTER):
        VAR CHARACTER fileName.
        VAR CHARACTER fullPath.
        VAR CHARACTER attrs.
        VAR CHARACTER gameTitle.
        VAR CHARACTER gameBlurb.
        VAR CHARACTER gameAccent.
        VAR CHARACTER gameCategory.
        VAR CHARACTER folder.
        VAR INTEGER n.
        IF pcFolder = ? OR pcFolder = "" THEN UNDO, THROW NEW GridException("A game catalog needs a folder").
        folder = RIGHT-TRIM(REPLACE(pcFolder, "~\", "/"), "/").
        FILE-INFORMATION:FILE-NAME = folder.
        IF FILE-INFORMATION:FULL-PATHNAME = ? THEN RETURN.

        INPUT FROM OS-DIR(FILE-INFORMATION:FULL-PATHNAME).
        REPEAT:
            IMPORT fileName fullPath attrs.
            IF INDEX(attrs, "F") = 0 OR NOT (fileName MATCHES "run-*.p") THEN NEXT.
            ReadHeader(fullPath, fileName, OUTPUT gameTitle, OUTPUT gameBlurb, OUTPUT gameAccent, OUTPUT gameCategory).
            IF gameTitle = ? THEN NEXT.
            CREATE ttGame.
            ASSIGN ttGame.caption   = gameTitle
                   ttGame.blurb   = gameBlurb
                   ttGame.accent  = gameAccent
                   ttGame.category = gameCategory
                   ttGame.runFile = folder + "/" + fileName.
        END.
        INPUT CLOSE.

        /* number them in order of title */
        FOR EACH ttGame BY ttGame.caption:
            n = n + 1.
            ttGame.pos = n.
        END.
        Count = n.
    END CONSTRUCTOR.

    METHOD PUBLIC CHARACTER TitleAt(INPUT piPlace AS INTEGER):
        Locate(piPlace).
        RETURN ttGame.caption.
    END METHOD.

    METHOD PUBLIC CHARACTER BlurbAt(INPUT piPlace AS INTEGER):
        Locate(piPlace).
        RETURN ttGame.blurb.
    END METHOD.

    METHOD PUBLIC CHARACTER AccentAt(INPUT piPlace AS INTEGER):
        Locate(piPlace).
        RETURN ttGame.accent.
    END METHOD.

    METHOD PUBLIC CHARACTER CategoryAt(INPUT piPlace AS INTEGER):
        Locate(piPlace).
        RETURN ttGame.category.
    END METHOD.

    METHOD PUBLIC CHARACTER ProgramAt(INPUT piPlace AS INTEGER):
        Locate(piPlace).
        RETURN ttGame.runFile.
    END METHOD.

    METHOD PRIVATE VOID Locate(INPUT piPlace AS INTEGER):
        IF piPlace = ? OR piPlace < 1 OR piPlace > Count THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("There is no game at place &1 of &2", piPlace, Count)).
        FIND FIRST ttGame WHERE ttGame.pos = piPlace.
    END METHOD.

    /* Reads the Arcade line of a run file. The title comes back unknown for a hidden file. */
    METHOD PRIVATE VOID ReadHeader(INPUT pcPath AS CHARACTER, INPUT pcFile AS CHARACTER,
                                   OUTPUT pcTitle AS CHARACTER, OUTPUT pcBlurb AS CHARACTER, OUTPUT pcAccent AS CHARACTER, OUTPUT pcCategory AS CHARACTER):
        VAR CHARACTER rawLine.
        VAR CHARACTER tagText.
        VAR INTEGER readCount.
        VAR LOGICAL seenArcade.
        VAR LOGICAL seenCategory.
        pcTitle = "".
        pcBlurb = "".
        pcAccent = "".
        pcCategory = "".
        INPUT FROM VALUE(pcPath).
        REPEAT:
            IMPORT UNFORMATTED rawLine.
            readCount = readCount + 1.
            IF readCount > 60 THEN LEAVE.
            rawLine = TRIM(rawLine).
            IF NOT seenArcade AND rawLine BEGINS "Arcade:" THEN DO:
                seenArcade = TRUE.
                tagText = TRIM(SUBSTRING(rawLine, 8)).
                pcTitle = TRIM(ENTRY(1, tagText, "|")).
                IF NUM-ENTRIES(tagText, "|") >= 2 THEN pcBlurb = TRIM(ENTRY(2, tagText, "|")).
                IF NUM-ENTRIES(tagText, "|") >= 3 THEN pcAccent = LC(TRIM(ENTRY(3, tagText, "|"))).
            END.
            ELSE IF NOT seenCategory AND rawLine BEGINS "Category:" THEN DO:
                seenCategory = TRUE.
                pcCategory = TRIM(SUBSTRING(rawLine, 10)).
            END.
            IF seenArcade AND seenCategory THEN LEAVE.
        END.
        INPUT CLOSE.
        IF pcTitle = "hidden" THEN DO:
            pcTitle = ?.
            RETURN.
        END.
        IF pcTitle = "" THEN pcTitle = TitleFromFile(pcFile).
    END METHOD.

    /* run-battleships.p is Battleships. */
    METHOD PRIVATE CHARACTER TitleFromFile(INPUT pcFile AS CHARACTER):
        VAR CHARACTER baseName.
        baseName = SUBSTRING(pcFile, 5, LENGTH(pcFile) - 6).
        RETURN CAPS(SUBSTRING(baseName, 1, 1)) + SUBSTRING(baseName, 2).
    END METHOD.

END CLASS.
