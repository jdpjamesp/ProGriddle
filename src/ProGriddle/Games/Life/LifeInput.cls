/* What a Life window can do besides stepping: left click toggles a cell, right click places
   the chosen pattern, and the Random and Clear commands start a new board. Both commands go
   back to generation 0 first, so the new board becomes the start that Reset returns to.

   A pattern that would hang off the board is moved back so it fits; a pattern bigger than
   the board is ignored.

   It also offers two options through IGameOptions, each a drop down list in the window:
     Rules  one of the well known rule sets (LifeRules:PresetNames), or the game's own rules when
            they are none of those, for example one given as B/S notation in the settings.
     Board  one of the sizes in LifeSizes, or the game's chosen size when it is not one of them.
   Choosing either rebuilds the running game (LifeFactory:Rebuild): the live cells stay where they
   are, the rules apply from the next generation, and a smaller board loses the cells outside it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Life.LifeInput FINAL IMPLEMENTS IGameInput, IGameOptions:

    DEFINE PRIVATE VARIABLE mGame    AS LifeGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mRandom  AS IRandom  NO-UNDO.
    DEFINE PRIVATE VARIABLE mDensity AS DECIMAL  NO-UNDO INITIAL 0.25.
    DEFINE PRIVATE VARIABLE mChoice  AS CHARACTER NO-UNDO INITIAL "Glider".
    DEFINE PRIVATE VARIABLE mNotice  AS CHARACTER NO-UNDO.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            RETURN SUBSTITUTE("Generation &1   Alive &2   Rules &3   &4 x &5 &6",
                mGame:Generation, mGame:AliveCount, mGame:Rules:Notation,
                mGame:Grid:Width, mGame:Grid:Height, (IF mGame:Grid:Topology:Wraps THEN "wrapped" ELSE "bounded")).
        END GET.

    /* Short on purpose: it sits in the toolbar. A right click on the board places the pattern. */
    DEFINE PUBLIC PROPERTY ChoiceLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "Pattern".
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceNames AS CHARACTER NO-UNDO
        GET():
            RETURN LifePatterns:Names().
        END GET.

    DEFINE PUBLIC PROPERTY Choice AS CHARACTER NO-UNDO
        GET():
            RETURN mChoice.
        END GET.
        SET(INPUT pcValue AS CHARACTER):
            IF pcValue = ? OR LOOKUP(pcValue, LifePatterns:Names()) = 0 THEN
                UNDO, THROW NEW GridException("Unknown pattern: " + STRING(pcValue)).
            mChoice = ENTRY(LOOKUP(pcValue, LifePatterns:Names()), LifePatterns:Names()).
        END SET.

    DEFINE PUBLIC PROPERTY CommandNames AS CHARACTER NO-UNDO
        GET():
            RETURN "Random:G,Clear:C".
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

    /* Two options: 1 the rules, 2 the board size. */
    DEFINE PUBLIC PROPERTY OptionCount AS INTEGER NO-UNDO
        GET():
            RETURN 2.
        END GET.

    /* poRandom decides what Random draws, so a seeded one gives a repeatable board. */
    CONSTRUCTOR PUBLIC LifeInput(INPUT poGame AS LifeGame, INPUT poRandom AS IRandom):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Life input needs a game").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("Life input needs a random source").
        mGame = poGame.
        mRandom = poRandom.
    END CONSTRUCTOR.

    /* What the last change of rules or size said, once. */
    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    /* Life uses no keys of its own. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        RETURN FALSE.
    END METHOD.

    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        CASE pcCommand:
            WHEN "Random" THEN DO:
                mGame:Initialise().
                mGame:Randomise(mRandom, mDensity).
            END.
            WHEN "Clear" THEN DO:
                mGame:Initialise().
                mGame:ClearBoard().
            END.
            OTHERWISE UNDO, THROW NEW GridException("Unknown Life command: " + STRING(pcCommand)).
        END CASE.
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT mGame:Grid:InBounds(piX, piY) THEN RETURN.
        mGame:ToggleCell(piX, piY).
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE pattern AS Shape   NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER NO-UNDO.
        IF NOT mGame:Grid:InBounds(piX, piY) THEN RETURN.
        pattern = LifePatterns:ByName(mChoice).
        IF pattern:Width > mGame:Grid:Width OR pattern:Height > mGame:Grid:Height THEN RETURN.
        x = MINIMUM(piX, mGame:Grid:Width - pattern:Width).
        y = MINIMUM(piY, mGame:Grid:Height - pattern:Height).
        mGame:Place(pattern, x, y).
    END METHOD.

    /* Life has no use for both buttons together. */
    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* ---- options (IGameOptions) ---- */

    METHOD PUBLIC CHARACTER OptionLabel(INPUT piOption AS INTEGER):
        CheckOption(piOption).
        RETURN (IF piOption = 1 THEN "Rules" ELSE "Board").
    END METHOD.

    METHOD PUBLIC CHARACTER OptionKey(INPUT piOption AS INTEGER):
        CheckOption(piOption).
        RETURN (IF piOption = 1 THEN "ruleset" ELSE "size").
    END METHOD.

    /* The usual choices, and the game's own value as well when it is not one of them. */
    METHOD PUBLIC CHARACTER OptionNames(INPUT piOption AS INTEGER):
        DEFINE VARIABLE names   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE chosen AS CHARACTER NO-UNDO.
        CheckOption(piOption).
        names = (IF piOption = 1 THEN LifeRules:PresetNames() ELSE LifeSizes:Names()).
        chosen = OptionValue(piOption).
        IF LOOKUP(chosen, names) = 0 THEN names = names + "," + chosen.
        RETURN names.
    END METHOD.

    /* The name of the preset the game's rules are, or their notation when they are none of them;
       the size as "100 x 70". */
    METHOD PUBLIC CHARACTER OptionValue(INPUT piOption AS INTEGER):
        DEFINE VARIABLE preset AS CHARACTER NO-UNDO.
        CheckOption(piOption).
        IF piOption = 2 THEN RETURN LifeSizes:Label(mGame:Grid:Width, mGame:Grid:Height).
        preset = LifeRules:PresetNameOf(mGame:Rules:Notation).
        RETURN (IF preset <> "" THEN preset ELSE mGame:Rules:Notation).
    END METHOD.

    /* Rules: a preset name, or B/S notation such as B36/S23. Board: a size such as "150 x 100". Throws
       GridException for anything else. Choosing what is chosen already changes nothing. */
    METHOD PUBLIC VOID SetOption(INPUT piOption AS INTEGER, INPUT pcValue AS CHARACTER):
        DEFINE VARIABLE rules    AS LifeRules NO-UNDO.
        DEFINE VARIABLE notation AS CHARACTER NO-UNDO.
        DEFINE VARIABLE w        AS INTEGER   NO-UNDO.
        DEFINE VARIABLE h        AS INTEGER   NO-UNDO.
        CheckOption(piOption).
        IF pcValue = ? THEN UNDO, THROW NEW GridException("An option cannot be set to the unknown value").
        IF pcValue = OptionValue(piOption) THEN RETURN.
        IF piOption = 1 THEN DO:
            notation = LifeRules:PresetNotation(pcValue).
            IF notation = "" THEN notation = pcValue.
            rules = NEW LifeRules(notation).
            LifeFactory:Rebuild(mGame, mGame:Grid:Width, mGame:Grid:Height, rules).
            mNotice = SUBSTITUTE("Rules: &1 (&2)", OptionValue(1), rules:Notation).
        END.
        ELSE DO:
            w = LifeSizes:WidthOf(pcValue).
            h = LifeSizes:HeightOf(pcValue).
            LifeFactory:Rebuild(mGame, w, h, mGame:Rules).
            mNotice = "Board: " + OptionValue(2).
        END.
    END METHOD.

    METHOD PRIVATE VOID CheckOption(INPUT piOption AS INTEGER):
        IF piOption = ? OR piOption < 1 OR piOption > 2 THEN
            UNDO, THROW NEW GridException("Life has options 1 and 2, not " + STRING(piOption)).
    END METHOD.

END CLASS.
