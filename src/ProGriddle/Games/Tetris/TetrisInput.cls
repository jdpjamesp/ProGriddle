/* What a Tetris window can do. All play is on the keyboard:

     Left or A           move left              (repeats while held)
     Right or D          move right             (repeats while held)
     Down or S           soft drop              (repeats while held)
     Up, W or X          turn clockwise         (once per press)
     Z                   turn anticlockwise     (once per press)
     Space               hard drop              (once per press)

   P pauses and F2 or R starts a new game (the window's own keys). The picker chooses the level a new
   game starts at, and Ghost switches the ghost piece, which shows where the piece will land, on or off.
   Help shows these keys and the scoring.

   A key held down keeps arriving. The movement keys use that as key repeat, as every Tetris does. The
   turn and hard drop keys would be a mistake to repeat, so while one is held its repeats are swallowed
   until the key comes up (ReleaseKey).

   Settings it reads, all optional: tetris.ghost, true for the ghost piece (default true). The window
   saves the chosen start level as tetris.choice. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisInput FINAL IMPLEMENTS IGameInput:

    DEFINE PRIVATE VARIABLE mGame     AS TetrisGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings  NO-UNDO.
    DEFINE PRIVATE VARIABLE mChoice   AS INTEGER    NO-UNDO INITIAL 1.
    DEFINE PRIVATE VARIABLE mNotice   AS CHARACTER  NO-UNDO.
    /* keys that are down now, as ",Up,Space," */
    DEFINE PRIVATE VARIABLE mHeld     AS CHARACTER  NO-UNDO INITIAL ",".

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            IF mGame:IsOver THEN
                RETURN SUBSTITUTE("Game over   Score &1   Lines &2   Level &3", mGame:Score, mGame:LinesCleared, mGame:Level).
            RETURN SUBSTITUTE("Score &1   Lines &2   Level &3   Next &4", mGame:Score, mGame:LinesCleared, mGame:Level, Tetrominoes:NameOf(mGame:NextPiece)).
        END GET.

    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
            IF mGame:IsOver THEN RETURN "GAME OVER".
            IF mGame:Paused THEN RETURN "PAUSED".
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "Start level".
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceNames AS CHARACTER NO-UNDO
        GET():
            RETURN "1,2,3,4,5,6,7,8,9,10".
        END GET.

    /* The level a new game starts at, "1" to "10". Before the first piece has settled it applies at once
       and the game starts again at that level. After that it applies to the next new game. */
    DEFINE PUBLIC PROPERTY Choice AS CHARACTER NO-UNDO
        GET():
            RETURN STRING(mChoice).
        END GET.
        SET(INPUT pcValue AS CHARACTER):
            IF pcValue = ? OR LOOKUP(pcValue, ChoiceNames) = 0 THEN UNDO, THROW NEW GridException("Unknown start level: " + STRING(pcValue)).
            mChoice = INTEGER(pcValue).
            mGame:StartLevel = mChoice.
            IF mGame:PiecesPlaced = 0 AND mGame:Score = 0 THEN mGame:Initialise().
            ELSE mNotice = SUBSTITUTE("Level &1 from the next new game (F2)", mChoice).
        END SET.

    DEFINE PUBLIC PROPERTY CommandNames AS CHARACTER NO-UNDO
        GET():
            RETURN "Ghost:G".
        END GET.

    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "Help:H".
        END GET.

    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET():
            /* the help window is about 40 characters wide, so keep every line short */
            RETURN "Keys" + CHR(10)
                 + "  Left, Right  move, hold to repeat" + CHR(10)
                 + "  Down         soft drop, repeats" + CHR(10)
                 + "  Up, W, X     turn clockwise" + CHR(10)
                 + "  Z            turn anticlockwise" + CHR(10)
                 + "  Space        hard drop" + CHR(10)
                 + "  P            pause" + CHR(10)
                 + "  F2, R        new game" + CHR(10)
                 + "  G            ghost on or off"
                 + CHR(10) + CHR(10)
                 + "Scoring" + CHR(10)
                 + "  Soft drop    1 point a row" + CHR(10)
                 + "  Hard drop    2 points a row" + CHR(10)
                 + "  Lines        100 300 500 800" + CHR(10)
                 + "               for 1 to 4, times level" + CHR(10)
                 + "  Every 10 lines the level rises".
        END GET.

    CONSTRUCTOR PUBLIC TetrisInput(INPUT poGame AS TetrisGame, INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Tetris input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Tetris input needs settings").
        mGame = poGame.
        mSettings = poSettings.
        mGame:ShowGhost = mSettings:GetLogical("tetris.ghost", TRUE).
    END CONSTRUCTOR.

    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        CASE pcCommand:
            WHEN "Ghost" THEN DO:
                mGame:ShowGhost = NOT mGame:ShowGhost.
                mSettings:SetLogical("tetris.ghost", mGame:ShowGhost).
                mNotice = "Ghost piece " + (IF mGame:ShowGhost THEN "on" ELSE "off").
            END.
            OTHERWISE UNDO, THROW NEW GridException("Unknown Tetris command: " + STRING(pcCommand)).
        END CASE.
    END METHOD.

    /* The keys of the game. Returns true for every key it uses, whether or not the move could be made,
       so the window never gives these keys a second meaning. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        DEFINE VARIABLE repeating AS LOGICAL NO-UNDO.
        IF pcKey = ? THEN RETURN FALSE.
        CASE pcKey:
            WHEN "Left" OR WHEN "A" THEN mGame:MoveLeft().
            WHEN "Right" OR WHEN "D" THEN mGame:MoveRight().
            WHEN "Down" OR WHEN "S" THEN mGame:SoftDrop().
            WHEN "Up" OR WHEN "W" OR WHEN "X" OR WHEN "Z" OR WHEN "Space" THEN DO:
                /* a turn or a drop happens once per press, not once per repeat */
                repeating = INDEX(mHeld, "," + pcKey + ",") > 0.
                IF NOT repeating THEN DO:
                    mHeld = mHeld + pcKey + ",".
                    IF pcKey = "Z" THEN mGame:RotateCounterClockwise().
                    ELSE IF pcKey = "Space" THEN mGame:HardDrop().
                    ELSE mGame:RotateClockwise().
                END.
            END.
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    /* A key came up, or (with an empty name) every key did. */
    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
        IF pcKey = ? OR pcKey = "" THEN mHeld = ",".
        ELSE mHeld = REPLACE(mHeld, "," + pcKey + ",", ",").
    END METHOD.

    /* Tetris is played on the keyboard. */
    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

END CLASS.
