/* What a Cuber window can do. All play is on the keyboard:

     Arrow keys or W A S D   hop Pip along a diagonal of the pyramid, as the pyramid is seen at 45 degrees:
                             Up (W) hops up and to the right, Right (D) down and to the right,
                             Down (S) down and to the left, Left (A) up and to the left
     Number pad 9 3 1 7      the same four hops, drawn where the keys are (9 up right, 3 down right, 1 down left, 7 up left)
     Q E Z C                 the same four hops, one key to each corner (Q up left, E up right, Z down left, C down right)
     Space or Enter          start, and start again after the game is over

   P pauses and R or F2 starts a new game (the window's own keys). + and - make the game faster and slower, in steps of 10 percent
   of the real speed (see CuberGame:SpeedPercent), and the speed is kept. There is nothing to click and no picker.

   A hop is an EVENT: a key goes down and Pip hops as soon as it is standing. A key held down arrives again and again (key repeat),
   and each one asks for the hop again, so holding a key keeps Pip hopping. The fire keys are STATES (the game wants to know that
   one is down), kept as Centipede does.

   Sound (M) switches the sound on or off, when there is a sound device, and the window remembers the choice as sound.on.

   The best score is kept in the settings as cuber.hiscore, and the window saves it when it closes. The speed is kept as
   cuber.speed, and starts at 80 percent. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberInput FINAL IMPLEMENTS IGameInput:

    VAR PRIVATE CuberGame mGame.
    VAR PRIVATE ISettings mSettings.
    VAR PRIVATE ISoundPlayer mPlayer.
    VAR PRIVATE CHARACTER mNotice.
    /* the fire keys that are down now, as ",Space,Return," */
    VAR PRIVATE CHARACTER mFireKeys = ",".
    VAR PRIVATE INTEGER mSavedHi.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            SaveHiScore().
            CASE mGame:Phase:
                WHEN CuberPhase:Title THEN RETURN SUBSTITUTE("Cuber   Hi &1   Press Space to play", mGame:HiScore).
                WHEN CuberPhase:GameOver THEN RETURN SUBSTITUTE("Game over   Score &1   Hi &2   Press Space", mGame:Score, mGame:HiScore).
            END CASE.
            RETURN SUBSTITUTE("Score &1   Hi &2   Pips &3   Level &4  Round &5   Speed &6%", mGame:Score, mGame:HiScore, mGame:Lives + 1,
                              mGame:LevelNo, mGame:RoundNo, mGame:SpeedPercent).
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
    CONSTRUCTOR PUBLIC CuberInput(INPUT poGame AS CuberGame, INPUT poSettings AS ISettings):
        THIS-OBJECT(poGame, poSettings, NEW NullSoundPlayer()).
    END CONSTRUCTOR.

    /* A game whose sound is played by poPlayer. The Sound command and the M key are offered only when the player is working. */
    CONSTRUCTOR PUBLIC CuberInput(INPUT poGame AS CuberGame, INPUT poSettings AS ISettings, INPUT poPlayer AS ISoundPlayer):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Cuber input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Cuber input needs settings").
        IF NOT VALID-OBJECT(poPlayer) THEN UNDO, THROW NEW GridException("Cuber input needs a sound player").
        mGame = poGame.
        mSettings = poSettings.
        mPlayer = poPlayer.
        mSavedHi = MAXIMUM(0, mSettings:GetInteger("cuber.hiscore", 0)).
        mGame:HiScore = mSavedHi.
        mGame:SpeedPercent = mSettings:GetInteger("cuber.speed", 80).
    END CONSTRUCTOR.

    /* The game's own notices: an extra Pip, a new round. */
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
            WHEN "Up" OR WHEN "W" OR WHEN "NumPad9" OR WHEN "E" THEN mGame:RequestHop(CuberDir:UpRight).
            WHEN "Right" OR WHEN "D" OR WHEN "NumPad3" OR WHEN "C" THEN mGame:RequestHop(CuberDir:DownRight).
            WHEN "Down" OR WHEN "S" OR WHEN "NumPad1" OR WHEN "Z" THEN mGame:RequestHop(CuberDir:DownLeft).
            WHEN "Left" OR WHEN "A" OR WHEN "NumPad7" OR WHEN "Q" THEN mGame:RequestHop(CuberDir:UpLeft).
            WHEN "Space" OR WHEN "Return" THEN DO:
                IF INDEX(mFireKeys, "," + pcKey + ",") = 0 THEN mFireKeys = mFireKeys + pcKey + ",".
                PassOn().
            END.
            WHEN "Add" OR WHEN "Oemplus" THEN ChangeSpeed(10).
            WHEN "Subtract" OR WHEN "OemMinus" THEN ChangeSpeed(-10).
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    /* A key came up, or (an empty name) every key did, because the window lost the keyboard and the key ups
       of the keys that were down are never sent. */
    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
        IF pcKey = ? OR pcKey = "" THEN mFireKeys = ",".
        ELSE CASE pcKey:
            WHEN "Space" OR WHEN "Return" THEN mFireKeys = REPLACE(mFireKeys, "," + pcKey + ",", ",").
            OTHERWISE RETURN.
        END CASE.
        PassOn().
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        IF pcCommand = "Sound" THEN mNotice = SoundSettings:Toggle(mPlayer, mSettings).
        ELSE UNDO, THROW NEW GridException("Unknown Cuber command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* Tells the game whether a fire key is down. */
    METHOD PRIVATE VOID PassOn():
        mGame:FireHeld = (mFireKeys <> ",").
    END METHOD.

    /* Faster or slower by a number of percent, kept for next time. */
    METHOD PRIVATE VOID ChangeSpeed(INPUT piBy AS INTEGER):
        mGame:SpeedPercent = mGame:SpeedPercent + piBy.
        mSettings:SetInteger("cuber.speed", mGame:SpeedPercent).
    END METHOD.

    /* A better hi-score goes into the settings at once, and is saved when the window closes. */
    METHOD PRIVATE VOID SaveHiScore():
        IF mGame:HiScore > mSavedHi THEN DO:
            mSavedHi = mGame:HiScore.
            mSettings:SetInteger("cuber.hiscore", mSavedHi).
        END.
    END METHOD.

END CLASS.
