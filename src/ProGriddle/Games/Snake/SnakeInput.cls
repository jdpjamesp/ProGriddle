/* What a Snake window can do. All play is on the keyboard: the arrow keys or W A S D steer the
   snake. A turn is made at the next step, so a quick pair of presses (up, then left) makes both
   turns, and a key that would send the snake straight back on itself is ignored. P or Space pauses
   and F2 or R starts a new game (the window's own keys). There is nothing to click.

   Sound (M) switches the sound on or off, when there is a sound device, and the window remembers the choice as sound.on.

   The one option, a drop down list called Board, chooses the size of the board (see SnakeSizes). Choosing
   a size starts a new game on a board of that size, and the window remembers the choice as snake.size.

   The status line shows the score, the length, the level (the snake speeds up with every piece of
   food) and the best score. When a game ends, its score becomes the best score if it beats it, and
   the line says so. The best score is kept in the settings as snake.best, and the window saves the
   settings when it closes.

   The banner says PAUSED while paused, GAME OVER when the snake has crashed and YOU WIN when it has
   filled the board. When the game is set to wait for a key (SnakeGame:WaitForKey, as the run file does),
   a new game shows PRESS AN ARROW KEY until the first turn. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeInput FINAL IMPLEMENTS IGameInput, IGameOptions:

    DEFINE PRIVATE VARIABLE mGame     AS SnakeGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlayer   AS ISoundPlayer NO-UNDO.
    DEFINE PRIVATE VARIABLE mBest    AS INTEGER   NO-UNDO.
    /* the game that has just ended has been counted for the best score, and it was a new best */
    DEFINE PRIVATE VARIABLE mRecorded AS LOGICAL   NO-UNDO.
    DEFINE PRIVATE VARIABLE mNewBest  AS LOGICAL   NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice   AS CHARACTER NO-UNDO.

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
            RETURN (IF mPlayer:Working THEN "Sound:M" ELSE "").
        END GET.

    /* Always empty: the painter draws PRESS AN ARROW KEY, PAUSED, GAME OVER and YOU WIN into the picture. Asking still notes the
       end of a game. */
    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
            NoteEnd().
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

    /* One option: the board size. */
    DEFINE PUBLIC PROPERTY OptionCount AS INTEGER NO-UNDO
        GET():
            RETURN 1.
        END GET.

    /* A game with no sound. */
    CONSTRUCTOR PUBLIC SnakeInput(INPUT poGame AS SnakeGame, INPUT poSettings AS ISettings):
        THIS-OBJECT(poGame, poSettings, NEW NullSoundPlayer()).
    END CONSTRUCTOR.

    /* A game whose sound is played by poPlayer. The Sound command and the M key are offered only when the player is working. */
    CONSTRUCTOR PUBLIC SnakeInput(INPUT poGame AS SnakeGame, INPUT poSettings AS ISettings, INPUT poPlayer AS ISoundPlayer):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Snake input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Snake input needs settings").
        IF NOT VALID-OBJECT(poPlayer) THEN UNDO, THROW NEW GridException("Snake input needs a sound player").
        mGame = poGame.
        mSettings = poSettings.
        mPlayer = poPlayer.
        mBest = MAX(0, mSettings:GetInteger("snake.best", 0)).
        mGame:BestScore = mBest.
    END CONSTRUCTOR.

    /* What the last change of board size said, once. */
    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
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
        IF pcCommand = "Sound" THEN mNotice = SoundSettings:Toggle(mPlayer, mSettings).
        ELSE UNDO, THROW NEW GridException("Unknown Snake command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* ---- options (IGameOptions) ---- */

    METHOD PUBLIC CHARACTER OptionLabel(INPUT piOption AS INTEGER):
        CheckOption(piOption).
        RETURN "Board".
    END METHOD.

    METHOD PUBLIC CHARACTER OptionKey(INPUT piOption AS INTEGER):
        CheckOption(piOption).
        RETURN "size".
    END METHOD.

    /* The usual sizes, and the game's own as well when it is not one of them (the settings can ask for any). */
    METHOD PUBLIC CHARACTER OptionNames(INPUT piOption AS INTEGER):
        DEFINE VARIABLE names AS CHARACTER NO-UNDO.
        CheckOption(piOption).
        names = SnakeSizes:Names().
        IF LOOKUP(OptionValue(1), names) = 0 THEN names = names + "," + OptionValue(1).
        RETURN names.
    END METHOD.

    /* The size of the board, as "20 x 20". */
    METHOD PUBLIC CHARACTER OptionValue(INPUT piOption AS INTEGER):
        CheckOption(piOption).
        RETURN SnakeSizes:Label(mGame:Grid:Width, mGame:Grid:Height).
    END METHOD.

    /* A size such as "30 x 20": starts a new game on a board of that size. Throws GridException for
       anything else. Choosing the size the board is already gives no new game. */
    METHOD PUBLIC VOID SetOption(INPUT piOption AS INTEGER, INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE w AS INTEGER NO-UNDO.
        DEFINE VARIABLE h AS INTEGER NO-UNDO.
        CheckOption(piOption).
        IF pcValue = ? THEN UNDO, THROW NEW GridException("An option cannot be set to the unknown value").
        w = SnakeSizes:WidthOf(pcValue).
        h = SnakeSizes:HeightOf(pcValue).
        IF w = mGame:Grid:Width AND h = mGame:Grid:Height THEN RETURN.
        SnakeFactory:Rebuild(mGame, w, h).
        mNotice = "Board: " + OptionValue(1).
    END METHOD.

    METHOD PRIVATE VOID CheckOption(INPUT piOption AS INTEGER):
        IF piOption = ? OR piOption <> 1 THEN
            UNDO, THROW NEW GridException("Snake has one option, number 1, not " + STRING(piOption)).
    END METHOD.

    /* Counts the game that has just ended towards the best score, once. The window asks for the
       status line and the banner after every tick and key, so this is where the end of a game is
       noticed. A new game clears it. */
    METHOD PRIVATE VOID NoteEnd():
        IF NOT mGame:IsOver THEN DO:
            mRecorded = FALSE.
            mNewBest = FALSE.
            /* the painter shows the best from before this game, so it can tell when this one beats it */
            mGame:BestScore = mBest.
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
