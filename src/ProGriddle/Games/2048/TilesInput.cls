/* What a 2048 window can do: the arrow keys, or W A S D, slide the tiles, and R (the window's own
   new game key) starts again. There is no picker, no extra buttons and nothing to click. The
   status line shows the score, the best score, the biggest tile and how the game stands.

   The best score is kept in the settings as 2048.best, and a score that beats it replaces it
   at once (the window saves the settings when it closes). A tile made with a move that does not
   change the board is ignored, with no notice. Reaching 2048 says so once, and the game goes on.
   A game that is over shows GAME OVER over the board and ignores the keys. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.2048.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.2048.TilesInput FINAL IMPLEMENTS IGameInput:

    DEFINE PRIVATE VARIABLE mGame     AS TilesGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mBest     AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice   AS CHARACTER NO-UNDO.
    /* true once the "you made 2048" notice has been given for the game being played */
    DEFINE PRIVATE VARIABLE mToldWon  AS LOGICAL   NO-UNDO.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            DEFINE VARIABLE state AS CHARACTER NO-UNDO.
            IF mGame:IsOver THEN state = "Game over".
            ELSE IF mGame:HasWon THEN state = "You made 2048, keep going".
            ELSE state = "Playing".
            RETURN SUBSTITUTE("Score &1   Best &2   Biggest tile &3   &4",
                mGame:Score, Best(), (IF mGame:TopTile = 0 THEN 0 ELSE INTEGER(EXP(2, mGame:TopTile))), state).
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceNames AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY Choice AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.
        SET(INPUT pcValue AS CHARACTER):
        END SET.

    DEFINE PUBLIC PROPERTY CommandNames AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
            RETURN (IF mGame:IsOver THEN "GAME OVER" ELSE "").
        END GET.

    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    CONSTRUCTOR PUBLIC TilesInput(INPUT poGame AS TilesGame, INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("2048 input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("2048 input needs settings").
        mGame = poGame.
        mSettings = poSettings.
        mBest = MAX(0, mSettings:GetInteger("2048.best", 0)).
        mToldWon = mGame:HasWon.
    END CONSTRUCTOR.

    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        result = mNotice.
        mNotice = "".
        RETURN result.
    END METHOD.

    /* The arrow keys and W A S D slide the tiles. Returns true for those keys, even when the
       move changes nothing or the game is over, so the window does not use them for anything
       else. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        DEFINE VARIABLE direction AS CHARACTER NO-UNDO.
        CASE pcKey:
            WHEN "Left"  OR WHEN "A" THEN direction = "L".
            WHEN "Right" OR WHEN "D" THEN direction = "R".
            WHEN "Up"    OR WHEN "W" THEN direction = "U".
            WHEN "Down"  OR WHEN "S" THEN direction = "D".
            OTHERWISE RETURN FALSE.
        END CASE.
        /* a new game has been started since the last key: the "made 2048" notice is due again */
        IF NOT mGame:HasWon THEN mToldWon = FALSE.
        IF mGame:IsOver THEN RETURN TRUE.
        CASE direction:
            WHEN "L" THEN mGame:MoveLeft().
            WHEN "R" THEN mGame:MoveRight().
            WHEN "U" THEN mGame:MoveUp().
            WHEN "D" THEN mGame:MoveDown().
        END CASE.
        IF mGame:Score > mBest THEN DO:
            mBest = mGame:Score.
            mSettings:SetInteger("2048.best", mBest).
        END.
        IF mGame:HasWon AND NOT mToldWon THEN DO:
            mToldWon = TRUE.
            mNotice = "2048! Keep going".
        END.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        UNDO, THROW NEW GridException("Unknown 2048 command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* The best score so far, this game included. */
    METHOD PRIVATE INTEGER Best():
        RETURN MAX(mBest, mGame:Score).
    END METHOD.

END CLASS.
