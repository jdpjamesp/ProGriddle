/* What a Minesweeper window can do: a left click opens a cell, a right click cycles flag and
   question mark, and a middle click or both buttons together chord. The picker chooses the
   level (Beginner, Intermediate, Expert or Custom) and choosing one starts a new game on it.
   Marks switches the question mark step of the right click on or off.

   Settings it reads, all optional:
     minesweeper.marks          true for question marks (default true, as in Windows)
     minesweeper.customWidth    Custom width, 9 to 30 (default 9)
     minesweeper.customHeight   Custom height, 9 to 24 (default 9)
     minesweeper.customMines    Custom mines, 10 to (width - 1) * (height - 1) (default 10)
   Values outside the range are brought back into it. A win on a standard level is added to
   that level's high score list (ten times, kept in the settings) by
   MinesweeperBestTimes, and the best time is shown in the status line. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperInput FINAL IMPLEMENTS IGameInput:

    DEFINE PRIVATE VARIABLE mGame     AS MinesweeperGame      NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings            NO-UNDO.
    DEFINE PRIVATE VARIABLE mBest     AS MinesweeperBestTimes NO-UNDO.
    DEFINE PRIVATE VARIABLE mChoice   AS CHARACTER            NO-UNDO.
    DEFINE PRIVATE VARIABLE mCustomW  AS INTEGER              NO-UNDO.
    DEFINE PRIVATE VARIABLE mCustomH  AS INTEGER              NO-UNDO.
    DEFINE PRIVATE VARIABLE mCustomM  AS INTEGER              NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice   AS CHARACTER            NO-UNDO.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            DEFINE VARIABLE state AS CHARACTER NO-UNDO.
            DEFINE VARIABLE best  AS INTEGER   NO-UNDO.
            IF mGame:IsWon THEN state = "You win!".
            ELSE IF mGame:IsLost THEN state = "Game over".
            ELSE IF mGame:Started THEN state = "Playing".
            ELSE state = "Ready".
            best = mBest:Best(mChoice).
            RETURN SUBSTITUTE("&1 &2 x &3   Mines &4   Time &5   &6   Best &7   Marks &8",
                mChoice, mGame:Grid:Width, mGame:Grid:Height, Counter(mGame:MinesLeft), Counter(mGame:Seconds), state,
                (IF best > 0 THEN STRING(best) + "s" ELSE "-"), (IF mGame:UseMarks THEN "on" ELSE "off")).
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "Level".
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceNames AS CHARACTER NO-UNDO
        GET():
            RETURN MinesweeperLevels:Names().
        END GET.

    /* The level. Setting it starts a new game of that level, even when it is the same one. */
    DEFINE PUBLIC PROPERTY Choice AS CHARACTER NO-UNDO
        GET():
            RETURN mChoice.
        END GET.
        SET(INPUT pcValue AS CHARACTER):
            IF MinesweeperLevels:Canonical(pcValue) = "" THEN
                UNDO, THROW NEW GridException("Unknown Minesweeper level: " + STRING(pcValue)).
            mChoice = MinesweeperLevels:Canonical(pcValue).
            IF mChoice = "Custom" THEN mGame:Configure(mCustomW, mCustomH, mCustomM).
            ELSE mGame:Configure(MinesweeperLevels:WidthOf(mChoice), MinesweeperLevels:HeightOf(mChoice), MinesweeperLevels:MinesOf(mChoice)).
        END SET.

    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "Scores:H".
        END GET.

    /* The high scores of the three standard levels, each a ranked list of winning times. */
    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET():
            DEFINE VARIABLE level  AS INTEGER   NO-UNDO.
            DEFINE VARIABLE rank   AS INTEGER   NO-UNDO.
            DEFINE VARIABLE name   AS CHARACTER NO-UNDO.
            DEFINE VARIABLE scores AS CHARACTER NO-UNDO.
            DEFINE VARIABLE result AS CHARACTER NO-UNDO.
            DO level = 1 TO 3:
                name = ENTRY(level, MinesweeperLevels:Names()).
                scores = mBest:Scores(name).
                result = result + (IF level > 1 THEN CHR(10) + CHR(10) ELSE "")
                       + SUBSTITUTE("&1  (&2 x &3, &4 mines)", name, MinesweeperLevels:WidthOf(name),
                                    MinesweeperLevels:HeightOf(name), MinesweeperLevels:MinesOf(name)).
                IF scores = "" THEN result = result + CHR(10) + "   No wins yet".
                ELSE DO rank = 1 TO NUM-ENTRIES(scores):
                    result = result + CHR(10) + SUBSTITUTE("  &1.  &2 s", STRING(rank, ">9"), STRING(INTEGER(ENTRY(rank, scores)), ">>9")).
                END.
            END.
            RETURN result.
        END GET.

    DEFINE PUBLIC PROPERTY CommandNames AS CHARACTER NO-UNDO
        GET():
            RETURN "Marks:M".
        END GET.

    /* poGame is the game to drive, in whatever size it starts. The level shown first is the
       standard one that matches its size, or Custom. */
    CONSTRUCTOR PUBLIC MinesweeperInput(INPUT poGame AS MinesweeperGame, INPUT poSettings AS ISettings):
        DEFINE VARIABLE level     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE levelName AS CHARACTER NO-UNDO.
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Minesweeper input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Minesweeper input needs settings").
        mGame = poGame.
        mSettings = poSettings.
        mBest = NEW MinesweeperBestTimes(poSettings).
        mGame:UseMarks = mSettings:GetLogical("minesweeper.marks", TRUE).
        mCustomW = MinesweeperLevels:ClampWidth(mSettings:GetInteger("minesweeper.customWidth", 9)).
        mCustomH = MinesweeperLevels:ClampHeight(mSettings:GetInteger("minesweeper.customHeight", 9)).
        mCustomM = MinesweeperLevels:ClampMines(mCustomW, mCustomH, mSettings:GetInteger("minesweeper.customMines", 10)).
        mChoice = "Custom".
        DO level = 1 TO 3:
            levelName = ENTRY(level, MinesweeperLevels:Names()).
            IF mGame:Grid:Width = MinesweeperLevels:WidthOf(levelName) AND mGame:Grid:Height = MinesweeperLevels:HeightOf(levelName)
               AND mGame:MineCount = MinesweeperLevels:MinesOf(levelName) THEN mChoice = levelName.
        END.
    END CONSTRUCTOR.

    /* What the Marks command just did, "Question marks on" or "Question marks off". */
    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    /* Minesweeper uses no keys of its own. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        RETURN FALSE.
    END METHOD.

    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        CASE pcCommand:
            WHEN "Marks" THEN DO:
                mGame:UseMarks = NOT mGame:UseMarks.
                mSettings:SetLogical("minesweeper.marks", mGame:UseMarks).
                mNotice = "Question marks " + (IF mGame:UseMarks THEN "on" ELSE "off").
            END.
            OTHERWISE UNDO, THROW NEW GridException("Unknown Minesweeper command: " + STRING(pcCommand)).
        END CASE.
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE wasWon AS LOGICAL NO-UNDO.
        IF NOT mGame:Grid:InBounds(piX, piY) THEN RETURN.
        wasWon = mGame:IsWon.
        mGame:Reveal(piX, piY).
        NoteWin(wasWon).
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT mGame:Grid:InBounds(piX, piY) THEN RETURN.
        mGame:ToggleFlag(piX, piY).
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE wasWon AS LOGICAL NO-UNDO.
        IF NOT mGame:Grid:InBounds(piX, piY) THEN RETURN.
        wasWon = mGame:IsWon.
        mGame:Chord(piX, piY).
        NoteWin(wasWon).
    END METHOD.

    /* Saves the time when this move just won the game. */
    METHOD PRIVATE VOID NoteWin(INPUT plWasWon AS LOGICAL):
        IF mGame:IsWon AND NOT plWasWon THEN DO:
            mBest:Record(mChoice, mGame:Seconds).
        END.
    END METHOD.

    /* Three digits, as on the classic counters: 007, or -07 below zero. Capped at 999. */
    METHOD PRIVATE CHARACTER Counter(INPUT piValue AS INTEGER):
        IF piValue < 0 THEN RETURN "-" + STRING(MINIMUM(99, - piValue), "99").
        RETURN STRING(MINIMUM(999, piValue), "999").
    END METHOD.

END CLASS.
