/* What a Life window can do besides stepping: left click toggles a cell, right click places
   the chosen pattern, and the Random and Clear commands start a new board. Both commands go
   back to generation 0 first, so the new board becomes the start that Reset returns to.

   A pattern that would hang off the board is moved back so it fits; a pattern bigger than
   the board is ignored. */
USING Progress.Lang.*.
USING Prolif.Core.*.
USING Prolif.Engine.*.
USING Prolif.Games.Life.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Games.Life.LifeInput FINAL IMPLEMENTS IGameInput:

    DEFINE PRIVATE VARIABLE mGame    AS LifeGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mRandom  AS IRandom  NO-UNDO.
    DEFINE PRIVATE VARIABLE mDensity AS DECIMAL  NO-UNDO INITIAL 0.25.
    DEFINE PRIVATE VARIABLE mChoice  AS CHARACTER NO-UNDO INITIAL "Glider".

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            RETURN SUBSTITUTE("Generation &1   Alive &2   Rules &3   &4 x &5 &6",
                mGame:Generation, mGame:AliveCount, mGame:Rules:Notation,
                mGame:Grid:Width, mGame:Grid:Height, (IF mGame:Grid:Topology:Wraps THEN "wrapped" ELSE "bounded")).
        END GET.

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

    /* poRandom decides what Random draws, so a seeded one gives a repeatable board. */
    CONSTRUCTOR PUBLIC LifeInput(INPUT poGame AS LifeGame, INPUT poRandom AS IRandom):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Life input needs a game").
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("Life input needs a random source").
        mGame = poGame.
        mRandom = poRandom.
    END CONSTRUCTOR.

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

END CLASS.
