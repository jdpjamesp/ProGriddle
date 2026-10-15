/* What an Asteroids window can do. All play is on the keyboard:

     Left or A          turn the ship left        (as long as the key is held)
     Right or D         turn the ship right       (as long as the key is held)
     Up or W            thrust                    (as long as the key is held)
     Space or Z         fire                      (hold it to keep firing)
     Down or S          hyperspace: jump to a random place, with a small chance of blowing up

   P pauses and R or F2 starts a new game (the window's own keys). + and - make the game faster and slower, in steps
   of 10 percent of the real speed (see AsteroidsGame:SpeedPercent), and the speed is kept. The title screen and the
   game over screen both wait for the fire key. There is nothing to click and no picker.

   Turning, thrust and fire are STATES, not events: a key held down is a ship that keeps turning, and the game needs
   all three at once. The keyboard cannot be trusted to repeat a key while another is pressed, so this class does not
   use the repeats. It remembers which keys are down (HandleKey when one goes down, ReleaseKey when it comes up, and an
   empty name when the window loses focus) and gives the game the state each time. When both turn keys are down the
   one pressed last wins.

   Sound (M) switches the sound on or off, when there is a sound device, and the window remembers the choice as sound.on.

   The best score is kept in the settings as asteroids.hiscore, and the window saves it when it closes. The speed is
   kept as asteroids.speed, and starts at 80 percent. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsInput FINAL IMPLEMENTS IGameInput:


    DEFINE PRIVATE VARIABLE mGame     AS AsteroidsGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings     NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlayer   AS ISoundPlayer  NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice   AS CHARACTER     NO-UNDO.
    DEFINE PRIVATE VARIABLE mLeft     AS LOGICAL       NO-UNDO.
    DEFINE PRIVATE VARIABLE mRight    AS LOGICAL       NO-UNDO.
    /* the turn key that went down last, 1 or -1, which wins when both are down */
    DEFINE PRIVATE VARIABLE mLatest   AS INTEGER       NO-UNDO.
    /* the keys that are down now, as ",Up,W," for thrust and ",Space," for fire */
    DEFINE PRIVATE VARIABLE mThrustKeys AS CHARACTER   NO-UNDO INITIAL ",".
    DEFINE PRIVATE VARIABLE mFireKeys   AS CHARACTER   NO-UNDO INITIAL ",".
    DEFINE PRIVATE VARIABLE mSavedHi    AS INTEGER     NO-UNDO.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            SaveHiScore().
            CASE mGame:Phase:
                WHEN GamePhase:Title THEN RETURN SUBSTITUTE("Asteroids   Hi &1   Press Space to play", mGame:HiScore).
                WHEN GamePhase:GameOver THEN RETURN SUBSTITUTE("Game over   Score &1   Hi &2   Press Space", mGame:Score, mGame:HiScore).
            END CASE.
            RETURN SUBSTITUTE("Score &1   Hi &2   Ships &3   Wave &4   Speed &5%", mGame:Score, mGame:HiScore, mGame:Lives, mGame:Wave, mGame:SpeedPercent).
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

    /* Always empty: the game draws its own words (GAME OVER, PRESS SPACE, and PAUSED over a dimmed picture) into the
       picture, so the window has no banner to add. */
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
    CONSTRUCTOR PUBLIC AsteroidsInput(INPUT poGame AS AsteroidsGame, INPUT poSettings AS ISettings):
        THIS-OBJECT(poGame, poSettings, NEW NullSoundPlayer()).
    END CONSTRUCTOR.

    /* A game whose sound is played by poPlayer. The Sound command and the M key are offered only when the player is working. */
    CONSTRUCTOR PUBLIC AsteroidsInput(INPUT poGame AS AsteroidsGame, INPUT poSettings AS ISettings, INPUT poPlayer AS ISoundPlayer):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Asteroids input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Asteroids input needs settings").
        IF NOT VALID-OBJECT(poPlayer) THEN UNDO, THROW NEW GridException("Asteroids input needs a sound player").
        mGame = poGame.
        mSettings = poSettings.
        mPlayer = poPlayer.
        mSavedHi = MAXIMUM(0, mSettings:GetInteger("asteroids.hiscore", 0)).
        mGame:HiScore = mSavedHi.
        mGame:SpeedPercent = mSettings:GetInteger("asteroids.speed", 80).
    END CONSTRUCTOR.

    /* The game's own notices: an extra ship, a new wave. */
    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
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
                mLatest = -1.
            END.
            WHEN "Right" OR WHEN "D" THEN DO:
                mRight = TRUE.
                mLatest = 1.
            END.
            WHEN "Up" OR WHEN "W" THEN DO:
                IF INDEX(mThrustKeys, "," + pcKey + ",") = 0 THEN mThrustKeys = mThrustKeys + pcKey + ",".
            END.
            WHEN "Space" OR WHEN "Z" THEN DO:
                IF INDEX(mFireKeys, "," + pcKey + ",") = 0 THEN mFireKeys = mFireKeys + pcKey + ",".
            END.
            WHEN "Down" OR WHEN "S" THEN DO:
                mGame:Hyperspace().
                RETURN TRUE.
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
            mThrustKeys = ",".
            mFireKeys = ",".
        END.
        ELSE CASE pcKey:
            WHEN "Left" OR WHEN "A" THEN mLeft = FALSE.
            WHEN "Right" OR WHEN "D" THEN mRight = FALSE.
            WHEN "Up" OR WHEN "W" THEN mThrustKeys = REPLACE(mThrustKeys, "," + pcKey + ",", ",").
            WHEN "Space" OR WHEN "Z" THEN mFireKeys = REPLACE(mFireKeys, "," + pcKey + ",", ",").
            OTHERWISE RETURN.
        END CASE.
        PassOn().
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        IF pcCommand = "Sound" THEN mNotice = SoundSettings:Toggle(mPlayer, mSettings).
        ELSE UNDO, THROW NEW GridException("Unknown Asteroids command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* Tells the game which way the ship is being turned, whether the thrust is on and whether the fire key is down. */
    METHOD PRIVATE VOID PassOn():
        mGame:TurnDirection = (IF mLeft AND mRight THEN mLatest ELSE IF mLeft THEN -1 ELSE IF mRight THEN 1 ELSE 0).
        mGame:ThrustHeld = (mThrustKeys <> ",").
        mGame:FireHeld = (mFireKeys <> ",").
    END METHOD.

    /* Faster or slower by a number of percent, kept for next time. */
    METHOD PRIVATE VOID ChangeSpeed(INPUT piBy AS INTEGER):
        mGame:SpeedPercent = mGame:SpeedPercent + piBy.
        mSettings:SetInteger("asteroids.speed", mGame:SpeedPercent).
    END METHOD.

    /* A better hi-score goes into the settings at once, and is saved when the window closes. */
    METHOD PRIVATE VOID SaveHiScore():
        IF mGame:HiScore > mSavedHi THEN DO:
            mSavedHi = mGame:HiScore.
            mSettings:SetInteger("asteroids.hiscore", mSavedHi).
        END.
    END METHOD.

END CLASS.
