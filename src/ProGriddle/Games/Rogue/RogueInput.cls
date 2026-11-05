/* What a Rogue window can do. Every key is turned into a token for the game (see RogueKeys): the keys the game has a use for are taken
   (HandleKey says true), and the window keeps the rest (F2 starts a new game). The window's buttons are Inventory, Messages, Help and Keys;
   Keys switches the movement keys between vi (h j k l y u b n) and the number pad and arrows, and the choice is kept as rogue.keys. The
   arrow keys and the number pad work in both. Shift with a movement key runs.

   When a game ends (the hero dies or climbs out with the amulet) it is put on the list of the ten best, kept as rogue.scores (see
   RogueScores), once. The status line is the two status lines of the original: level, gold, hit points, strength, armour class and
   experience, and what is wrong with the hero. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueInput FINAL IMPLEMENTS IGameInput, IModifierKeys:

    DEFINE PRIVATE VARIABLE mGame     AS RogueGame   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings   NO-UNDO.
    DEFINE PRIVATE VARIABLE mScores   AS RogueScores NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice   AS CHARACTER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mRecorded AS LOGICAL     NO-UNDO.

    /* True while Shift is held (the window says so before each key). */
    DEFINE PUBLIC PROPERTY ShiftDown AS LOGICAL NO-UNDO
        GET.
        SET.

    /* True for the vi movement keys, false for the number pad and arrows only. */
    DEFINE PUBLIC PROPERTY ViKeys AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            RETURN StatusLine().
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
            RETURN "Inventory,Messages,Help,Keys".
        END GET.

    /* Always empty: the painter draws the messages, the prompts and the end of the game in the picture. */
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

    /* Throws GridException for no game, settings or scores. The movement keys come from rogue.keys ("vi", the default, or "numpad"). */
    CONSTRUCTOR PUBLIC RogueInput(INPUT poGame AS RogueGame, INPUT poSettings AS ISettings, INPUT poScores AS RogueScores):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Rogue input needs a game").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Rogue input needs settings").
        IF NOT VALID-OBJECT(poScores) THEN UNDO, THROW NEW GridException("Rogue input needs the list of scores").
        mGame = poGame.
        mSettings = poSettings.
        mScores = poScores.
        ViKeys = mSettings:GetString("rogue.keys", "vi") <> "numpad".
    END CONSTRUCTOR.

    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    /* A key went down: the game gets its token. Gives true when the key meant something to the game. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        DEFINE VARIABLE token AS CHARACTER NO-UNDO.
        token = RogueKeys:Token(pcKey, ShiftDown, ViKeys, mGame:Mode = RogueMode:PickItem).
        IF token = "" THEN RETURN FALSE.
        mGame:Command(token).
        KeepScore().
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
    END METHOD.

    /* Runs one of the buttons: Inventory, Messages, Help, or Keys, which changes the movement keys. */
    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        CASE pcCommand:
            WHEN "Inventory" THEN mGame:Command("i").
            WHEN "Messages" THEN mGame:Command("S-m").
            WHEN "Help" THEN mGame:Command("?").
            WHEN "Keys" THEN DO:
                ViKeys = NOT ViKeys.
                mSettings:SetString("rogue.keys", (IF ViKeys THEN "vi" ELSE "numpad")).
                mNotice = (IF ViKeys THEN "Movement keys: vi (h j k l y u b n)" ELSE "Movement keys: number pad and arrows").
            END.
            OTHERWISE UNDO, THROW NEW GridException("Rogue has no command called " + pcCommand).
        END CASE.
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* The status line: the level and the numbers of the hero, and what is wrong. */
    METHOD PUBLIC STATIC CHARACTER Summary(INPUT poGame AS RogueGame):
        DEFINE VARIABLE w AS RogueWorld NO-UNDO.
        w = poGame:World.
        RETURN SUBSTITUTE("Level &1  Gold &2  Hp &3(&4)  Str &5(&6)  Arm &7  Exp &8/&9",
                          w:Depth, w:Hero:Gold, w:Hero:Hp, w:Hero:MaxHp, Fighting:EffectiveStrength(w), w:Hero:MaxStrength, Fighting:ArmourClass(w),
                          w:Hero:Rank, w:Hero:Experience).
    END METHOD.

    /* Puts the game on the list of scores, once, when it has ended. A new game lets the next one be recorded. */
    METHOD PRIVATE VOID KeepScore():
        IF mGame:Mode = RogueMode:Play THEN mRecorded = FALSE.
        IF mGame:IsOver AND NOT mRecorded THEN DO:
            mRecorded = TRUE.
            mScores:Add(mGame:World:Score, mGame:World:DeepestDepth, mGame:World:Cause, mGame:World:Won).
        END.
    END METHOD.

    METHOD PRIVATE CHARACTER StatusLine():
        KeepScore().
        RETURN Summary(mGame).
    END METHOD.

END CLASS.
