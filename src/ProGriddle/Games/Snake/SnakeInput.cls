/* What a Snake window can do. All play is on the keyboard: the arrow keys or W A S D steer the
   snake. A turn is made at the next step, so a quick pair of presses (up, then left) makes both
   turns, and a key that would send the snake straight back on itself is ignored. P or Space pauses
   and F2 or R starts a new game (the window's own keys). There is nothing to click and no picker.

   The status line shows the score, the length, the level (the snake speeds up with every piece of
   food) and the best score. When a game ends, its score becomes the best score if it beats it, and
   the line says so. The best score is kept in the settings as snake.best, and the window saves the
   settings when it closes.

   The banner says PAUSED while paused, GAME OVER when the snake has crashed and YOU WIN when it has
   filled the board. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeInput FINAL IMPLEMENTS IGameInput:

    DEFINE PRIVATE VARIABLE mGame     AS SnakeGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mBest     AS INTEGER   NO-UNDO.
    /* the game that has just ended has been counted for the best score, and it was a new best */
    DEFINE PRIVATE VARIABLE mRecorded AS LOGICAL   NO-UNDO.
    DEFINE PRIVATE VARIABLE mNewBest  AS LOGICAL   NO-UNDO.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            DEFINE VARIABLE result AS CHARACTER NO-UNDO.
            NoteEnd().
            IF mGame:IsOver THEN DO:
                result = SUBSTITUTE("&1   Score &2   Length &3   Best &4", (IF mGame:HasWon THEN "You win" ELSE "Game over"),
                                    mGame:Score, mGame:Length, mBest).
                IF mNewBest THEN result = result + "   New best score".
                RETURN result.
            END.
            RETURN SUBSTITUTE("Score &1   Length &2   Level &3   Best &4", mGame:Score, mGame:Length, mGame:Level, MAX(mBest, mGame:Score)).
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
            NoteEnd().
            IF mGame:IsOver THEN RETURN (IF mGame:HasWon THEN "YOU WIN" ELSE "GAME OVER").
            IF mGame:Paused THEN RETURN "PAUSED".
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    CONSTRUCTOR PUBLIC SnakeInput(INPUT poGame AS SnakeGame, INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Snake input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Snake input needs settings").
        mGame = poGame.
        mSettings = poSettings.
        mBest = MAX(0, mSettings:GetInteger("snake.best", 0)).
    END CONSTRUCTOR.

    /* Snake has nothing to say between moves. */
    METHOD PUBLIC CHARACTER TakeNotice():
        RETURN "".
    END METHOD.

    /* The arrow keys and W A S D steer. Returns true for those keys, even when the turn is refused or
       the game is over, so the window never gives them a second meaning. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        IF pcKey = ? THEN RETURN FALSE.
        NoteEnd().
        CASE pcKey:
            WHEN "Left"  OR WHEN "A" THEN mGame:TurnLeft().
            WHEN "Right" OR WHEN "D" THEN mGame:TurnRight().
            WHEN "Up"    OR WHEN "W" THEN mGame:TurnUp().
            WHEN "Down"  OR WHEN "S" THEN mGame:TurnDown().
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        UNDO, THROW NEW GridException("Unknown Snake command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* Counts the game that has just ended towards the best score, once. The window asks for the
       status line and the banner after every tick and key, so this is where the end of a game is
       noticed. A new game clears it. */
    METHOD PRIVATE VOID NoteEnd():
        IF NOT mGame:IsOver THEN DO:
            mRecorded = FALSE.
            mNewBest = FALSE.
        END.
        ELSE IF NOT mRecorded THEN DO:
            mRecorded = TRUE.
            IF mGame:Score > mBest THEN DO:
                mBest = mGame:Score.
                mNewBest = TRUE.
                mSettings:SetInteger("snake.best", mBest).
            END.
        END.
    END METHOD.

END CLASS.
