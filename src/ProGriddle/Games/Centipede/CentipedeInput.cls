/* What a Centipede window can do. All play is on the keyboard:

     Arrow keys or W A S D   move the shooter, up and down as well as across, but only in the bottom rows (held)
     Space, Z or X           fire (hold it to fire again the moment the shot is gone)

   P pauses and R or F2 starts a new game (the window's own keys). + and - make the game faster and slower, in steps of 10 percent
   of the real speed (see CentipedeGame:SpeedPercent), and the speed is kept. The title screen and the game over screen both wait for
   the fire key. There is nothing to click and no picker.

   Movement and fire are STATES, not events: a key held down is a shooter that keeps moving, and the shooter needs to move and fire at
   the same time. The keyboard cannot be trusted to repeat a key while another is pressed, so this class does not use the repeats.
   It remembers which keys are down (HandleKey when one goes down, ReleaseKey when it comes up, and an empty name when the window loses
   focus) and gives the game the direction and the fire state each time. When both keys of an axis are down the one pressed last wins.

   Sound (M) switches the sound on or off, when there is a sound device, and the window remembers the choice as sound.on.

   The best score is kept in the settings as centipede.hiscore, and the window saves it when it closes. The speed is kept as
   centipede.speed, and starts at 70 percent. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeInput FINAL IMPLEMENTS IGameInput:

    VAR PRIVATE CentipedeGame mGame.
    VAR PRIVATE ISettings mSettings.
    VAR PRIVATE ISoundPlayer mPlayer.
    VAR PRIVATE CHARACTER mNotice.
    VAR PRIVATE LOGICAL mLeft.
    VAR PRIVATE LOGICAL mRight.
    VAR PRIVATE LOGICAL mUp.
    VAR PRIVATE LOGICAL mDown.
    /* the key of each axis that went down last (1 or -1), which wins when both are down */
    VAR PRIVATE INTEGER mLatestX.
    VAR PRIVATE INTEGER mLatestY.
    /* the fire keys that are down now, as ",Space,Z," */
    VAR PRIVATE CHARACTER mFireKeys = ",".
    VAR PRIVATE INTEGER mSavedHi.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            SaveHiScore().
            CASE mGame:Phase:
                WHEN GamePhase:Title THEN RETURN SUBSTITUTE("Centipede   Hi &1   Press Space to play", mGame:HiScore).
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
            RETURN (IF mPlayer:Working THEN "Sound:M" ELSE "").
        END GET.

    /* Always empty: the painter draws the words (PAUSED, GAME OVER, PRESS SPACE) into the picture. */
    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
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

    /* A game with no sound. */
    CONSTRUCTOR PUBLIC CentipedeInput(INPUT poGame AS CentipedeGame, INPUT poSettings AS ISettings):
        THIS-OBJECT(poGame, poSettings, NEW NullSoundPlayer()).
    END CONSTRUCTOR.

    /* A game whose sound is played by poPlayer. The Sound command and the M key are offered only when the player is working. */
    CONSTRUCTOR PUBLIC CentipedeInput(INPUT poGame AS CentipedeGame, INPUT poSettings AS ISettings, INPUT poPlayer AS ISoundPlayer):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Centipede input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Centipede input needs settings").
        IF NOT VALID-OBJECT(poPlayer) THEN UNDO, THROW NEW GridException("Centipede input needs a sound player").
        mGame = poGame.
        mSettings = poSettings.
        mPlayer = poPlayer.
        mSavedHi = MAXIMUM(0, mSettings:GetInteger("centipede.hiscore", 0)).
        mGame:HiScore = mSavedHi.
        mGame:SpeedPercent = mSettings:GetInteger("centipede.speed", 70).
    END CONSTRUCTOR.

    /* The game's own notices: an extra shooter, a new wave. */
    METHOD PUBLIC CHARACTER TakeNotice():
        VAR CHARACTER notice.
        notice = mGame:TakeNotice().
        IF mNotice <> "" THEN ASSIGN
            notice = mNotice
            mNotice = "".
        RETURN notice.
    END METHOD.

    /* A key went down. Returns true for the keys of the game, which the window then leaves alone. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        IF pcKey = ? THEN RETURN FALSE.
        CASE pcKey:
            WHEN "Left" OR WHEN "A" THEN DO:
                mLeft = TRUE.
                mLatestX = -1.
            END.
            WHEN "Right" OR WHEN "D" THEN DO:
                mRight = TRUE.
                mLatestX = 1.
            END.
            WHEN "Up" OR WHEN "W" THEN DO:
                mUp = TRUE.
                mLatestY = -1.
            END.
            WHEN "Down" OR WHEN "S" THEN DO:
                mDown = TRUE.
                mLatestY = 1.
            END.
            WHEN "Space" OR WHEN "Z" OR WHEN "X" THEN DO:
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
            ASSIGN mLeft = FALSE
                   mRight = FALSE
                   mUp = FALSE
                   mDown = FALSE
                   mLatestX = 0
                   mLatestY = 0
                   mFireKeys = ",".
        END.
        ELSE CASE pcKey:
            WHEN "Left" OR WHEN "A" THEN mLeft = FALSE.
            WHEN "Right" OR WHEN "D" THEN mRight = FALSE.
            WHEN "Up" OR WHEN "W" THEN mUp = FALSE.
            WHEN "Down" OR WHEN "S" THEN mDown = FALSE.
            WHEN "Space" OR WHEN "Z" OR WHEN "X" THEN mFireKeys = REPLACE(mFireKeys, "," + pcKey + ",", ",").
            OTHERWISE RETURN.
        END CASE.
        PassOn().
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        IF pcCommand = "Sound" THEN mNotice = SoundSettings:Toggle(mPlayer, mSettings).
        ELSE UNDO, THROW NEW GridException("Unknown Centipede command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* Tells the game which way the shooter is being steered and whether the fire key is down. */
    METHOD PRIVATE VOID PassOn():
        mGame:MoveX = (IF mLeft AND mRight THEN mLatestX ELSE IF mLeft THEN -1 ELSE IF mRight THEN 1 ELSE 0).
        mGame:MoveY = (IF mUp AND mDown THEN mLatestY ELSE IF mUp THEN -1 ELSE IF mDown THEN 1 ELSE 0).
        mGame:FireHeld = (mFireKeys <> ",").
    END METHOD.

    /* Faster or slower by a number of percent, kept for next time. */
    METHOD PRIVATE VOID ChangeSpeed(INPUT piBy AS INTEGER):
        mGame:SpeedPercent = mGame:SpeedPercent + piBy.
        mSettings:SetInteger("centipede.speed", mGame:SpeedPercent).
    END METHOD.

    /* A better hi-score goes into the settings at once, and is saved when the window closes. */
    METHOD PRIVATE VOID SaveHiScore():
        IF mGame:HiScore > mSavedHi THEN DO:
            mSavedHi = mGame:HiScore.
            mSettings:SetInteger("centipede.hiscore", mSavedHi).
        END.
    END METHOD.

END CLASS.
