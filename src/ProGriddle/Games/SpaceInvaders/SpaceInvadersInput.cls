/* What a Space Invaders window can do. All play is on the keyboard:

     Left or A          move the cannon left     (as long as the key is held)
     Right or D         move the cannon right    (as long as the key is held)
     Space, Up, W or Z  fire                     (hold it to fire again the moment the shot is gone)

   P pauses and R or F2 starts a new game (the window's own keys). + and - make the game faster and slower, in
   steps of 10 percent of the arcade's speed (see SpaceInvadersGame:SpeedPercent), and the speed is kept. The
   title screen and the game over screen both wait for the fire key. There is nothing to click and no picker.

   Movement and fire are STATES, not events: a key held down is a cannon that keeps moving, and the arcade
   needs the cannon to move and fire at the same time. The keyboard cannot be trusted to repeat a key while
   another is pressed, so this class does not use the repeats. It remembers which keys are down (HandleKey
   when one goes down, ReleaseKey when it comes up, and an empty name when the window loses focus) and gives
   the game the direction and the fire state each time. When both direction keys are down the one pressed last wins.

   The best score is kept in the settings as spaceinvaders.hiscore, and the window saves it when it closes. The
   speed is kept as spaceinvaders.speed, and starts at 70 percent: the arcade's own speed is a lot to ask of a
   first game. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.SpaceInvadersInput FINAL IMPLEMENTS IGameInput:


    DEFINE PRIVATE VARIABLE mGame     AS SpaceInvadersGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings         NO-UNDO.
    DEFINE PRIVATE VARIABLE mLeft     AS LOGICAL           NO-UNDO.
    DEFINE PRIVATE VARIABLE mRight    AS LOGICAL           NO-UNDO.
    /* the direction key that went down last, 1 or -1, which wins when both are down */
    DEFINE PRIVATE VARIABLE mLatest   AS INTEGER           NO-UNDO.
    /* the fire keys that are down now, as ",Space,Up," */
    DEFINE PRIVATE VARIABLE mFireKeys AS CHARACTER         NO-UNDO INITIAL ",".
    DEFINE PRIVATE VARIABLE mSavedHi  AS INTEGER           NO-UNDO.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            SaveHiScore().
            CASE mGame:Phase:
                WHEN GamePhase:Title THEN RETURN SUBSTITUTE("Space Invaders   Hi &1   Press Space to play", mGame:HiScore).
                WHEN GamePhase:GameOver THEN RETURN SUBSTITUTE("Game over   Score &1   Hi &2   Press Space", mGame:Score, mGame:HiScore).
            END CASE.
            RETURN SUBSTITUTE("Score &1   Hi &2   Lives &3   Wave &4   Speed &5%", mGame:Score, mGame:HiScore, mGame:Lives, mGame:Wave, mGame:SpeedPercent).
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

    /* The game draws its own words (GAME OVER, PRESS SPACE) into the picture, so the banner is only for pause. */
    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
            RETURN (IF mGame:Paused THEN "PAUSED" ELSE "").
        END GET.

    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    CONSTRUCTOR PUBLIC SpaceInvadersInput(INPUT poGame AS SpaceInvadersGame, INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Space Invaders input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Space Invaders input needs settings").
        mGame = poGame.
        mSettings = poSettings.
        mSavedHi = MAXIMUM(0, mSettings:GetInteger("spaceinvaders.hiscore", 0)).
        mGame:HiScore = mSavedHi.
        mGame:SpeedPercent = mSettings:GetInteger("spaceinvaders.speed", 70).
    END CONSTRUCTOR.

    /* The game's own notices: an extra cannon, a new wave. */
    METHOD PUBLIC CHARACTER TakeNotice():
        RETURN mGame:TakeNotice().
    END METHOD.

    /* A key went down. Returns true for the keys of the game, which the window then leaves alone. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        IF pcKey = ? THEN RETURN FALSE.
        CASE pcKey:
            WHEN "Left" OR WHEN "A" THEN DO:
                mLeft = TRUE.
                mLatest = -1.
            END.
            WHEN "Right" OR WHEN "D" THEN DO:
                mRight = TRUE.
                mLatest = 1.
            END.
            WHEN "Space" OR WHEN "Up" OR WHEN "W" OR WHEN "Z" THEN DO:
                IF INDEX(mFireKeys, "," + pcKey + ",") = 0 THEN mFireKeys = mFireKeys + pcKey + ",".
            END.
            WHEN "Add" OR WHEN "Oemplus" THEN DO:
                ChangeSpeed(10).
                RETURN TRUE.
            END.
            WHEN "Subtract" OR WHEN "OemMinus" THEN DO:
                ChangeSpeed(-10).
                RETURN TRUE.
            END.
            OTHERWISE RETURN FALSE.
        END CASE.
        PassOn().
        RETURN TRUE.
    END METHOD.

    /* A key came up, or (an empty name) every key did, because the window lost the keyboard and the key ups
       of the keys that were down are never sent. */
    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
        IF pcKey = ? OR pcKey = "" THEN DO:
            mLeft = FALSE.
            mRight = FALSE.
            mLatest = 0.
            mFireKeys = ",".
        END.
        ELSE CASE pcKey:
            WHEN "Left" OR WHEN "A" THEN mLeft = FALSE.
            WHEN "Right" OR WHEN "D" THEN mRight = FALSE.
            WHEN "Space" OR WHEN "Up" OR WHEN "W" OR WHEN "Z" THEN mFireKeys = REPLACE(mFireKeys, "," + pcKey + ",", ",").
            OTHERWISE RETURN.
        END CASE.
        PassOn().
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        UNDO, THROW NEW GridException("Unknown Space Invaders command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* Tells the game which way the cannon is being steered and whether the fire key is down. */
    METHOD PRIVATE VOID PassOn():
        mGame:MoveDirection = (IF mLeft AND mRight THEN mLatest ELSE IF mLeft THEN -1 ELSE IF mRight THEN 1 ELSE 0).
        mGame:FireHeld = (mFireKeys <> ",").
    END METHOD.

    /* Faster or slower by a number of percent, kept for next time. */
    METHOD PRIVATE VOID ChangeSpeed(INPUT piBy AS INTEGER):
        mGame:SpeedPercent = mGame:SpeedPercent + piBy.
        mSettings:SetInteger("spaceinvaders.speed", mGame:SpeedPercent).
    END METHOD.

    /* A better hi-score goes into the settings at once, and is saved when the window closes. */
    METHOD PRIVATE VOID SaveHiScore():
        IF mGame:HiScore > mSavedHi THEN DO:
            mSavedHi = mGame:HiScore.
            mSettings:SetInteger("spaceinvaders.hiscore", mSavedHi).
        END.
    END METHOD.

END CLASS.
