/* What a FOR EACH window can do. All play is on the keyboard:

     Left, Right, Up, Down or A, D, W, S   steer Dibby (he turns at the next opening, and keeps going when the key is let go)
     Space or Return                        start a game, from the title screen and after the end
     T                                      show or hide the tile each phantom is heading for
     + and -                                make the game faster and slower, in steps of 10 percent (50 to 150, 100 is full speed)

   P and Space during play pause the game (the window's own keys, so the game does not take them) and R or F2 start a new game.
   There is nothing to click and no picker. Sound (M) switches the sound on or off, when there is a sound device, and the window
   remembers the choice as sound.on.

   The status line shows the score, the best score, the lives, the level and the speed. The best score is kept in the settings as
   foreach.hiscore, and the window saves it when it closes. The speed is kept as foreach.speed, and starts at 100 percent. The
   banner is always empty: the picture draws its own words (READY!, GAME OVER, PAUSED). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachInput FINAL IMPLEMENTS IGameInput:

    VAR PRIVATE ForEachGame mGame.
    VAR PRIVATE ISettings mSettings.
    VAR PRIVATE ISoundPlayer mPlayer.
    VAR PRIVATE CHARACTER mNotice.
    VAR PRIVATE INTEGER mSavedHi.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            SaveHiScore().
            IF mGame:Phase = ForEachPhase:Title THEN RETURN SUBSTITUTE("FOR EACH   Hi &1   Press Space to play", mGame:HiScore).
            RETURN SUBSTITUTE("Score &1   Hi &2   Lives &3   Level &4   Speed &5%", mGame:Score, mGame:HiScore, mGame:Lives, mGame:Level, mGame:SpeedPercent).
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
    CONSTRUCTOR PUBLIC ForEachInput(INPUT poGame AS ForEachGame, INPUT poSettings AS ISettings):
        THIS-OBJECT(poGame, poSettings, NEW NullSoundPlayer()).
    END CONSTRUCTOR.

    /* A game whose sound is played by poPlayer. The Sound command and the M key are offered only when the player is working. */
    CONSTRUCTOR PUBLIC ForEachInput(INPUT poGame AS ForEachGame, INPUT poSettings AS ISettings, INPUT poPlayer AS ISoundPlayer):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("FOR EACH input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("FOR EACH input needs settings").
        IF NOT VALID-OBJECT(poPlayer) THEN UNDO, THROW NEW GridException("FOR EACH input needs a sound player").
        mGame = poGame.
        mSettings = poSettings.
        mPlayer = poPlayer.
        mSavedHi = MAXIMUM(0, mSettings:GetInteger("foreach.hiscore", 0)).
        mGame:HiScore = mSavedHi.
        mGame:SpeedPercent = MAXIMUM(50, MINIMUM(150, mSettings:GetInteger("foreach.speed", 100))).
    END CONSTRUCTOR.

    /* What the last key said, once. */
    METHOD PUBLIC CHARACTER TakeNotice():
        VAR CHARACTER notice.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    /* A key went down. Returns true for the keys of the game, which the window then leaves alone. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        IF pcKey = ? THEN RETURN FALSE.
        CASE pcKey:
            WHEN "Up" OR WHEN "W" THEN mGame:Steer(MazeDir:Up).
            WHEN "Left" OR WHEN "A" THEN mGame:Steer(MazeDir:Left).
            WHEN "Down" OR WHEN "S" THEN mGame:Steer(MazeDir:Down).
            WHEN "Right" OR WHEN "D" THEN mGame:Steer(MazeDir:Right).
            WHEN "Space" OR WHEN "Return" THEN DO:
                IF mGame:Phase <> ForEachPhase:Title AND mGame:Phase <> ForEachPhase:GameOver THEN RETURN FALSE.
                mGame:StartGame().
            END.
            WHEN "T" THEN DO:
                mGame:ShowTargets = NOT mGame:ShowTargets.
                mNotice = (IF mGame:ShowTargets THEN "Phantom targets on" ELSE "Phantom targets off").
            END.
            WHEN "Add" OR WHEN "Oemplus" THEN ChangeSpeed(10).
            WHEN "Subtract" OR WHEN "OemMinus" THEN ChangeSpeed(-10).
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    /* A key came up. Dibby keeps going the way he was asked to, so nothing changes. */
    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        IF pcCommand = "Sound" THEN mNotice = SoundSettings:Toggle(mPlayer, mSettings).
        ELSE UNDO, THROW NEW GridException("Unknown FOR EACH command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* Faster or slower by a number of percent, between 50 and 150, kept for next time. */
    METHOD PRIVATE VOID ChangeSpeed(INPUT piStep AS INTEGER):
        mGame:SpeedPercent = MAXIMUM(50, MINIMUM(150, mGame:SpeedPercent + piStep)).
        mSettings:SetInteger("foreach.speed", mGame:SpeedPercent).
    END METHOD.

    /* A new best score is written to the settings. */
    METHOD PRIVATE VOID SaveHiScore():
        IF mGame:HiScore > mSavedHi THEN DO:
            mSavedHi = mGame:HiScore.
            mSettings:SetInteger("foreach.hiscore", mSavedHi).
        END.
    END METHOD.

END CLASS.
