/* The best winning time, in seconds, for each of the three standard levels, kept in the
   settings as "minesweeper.best.beginner", "minesweeper.best.intermediate" and
   "minesweeper.best.expert". Custom games keep no record, as in Windows. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Minesweeper.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Minesweeper.MinesweeperBestTimes FINAL:

    DEFINE PRIVATE VARIABLE mSettings AS ISettings NO-UNDO.

    CONSTRUCTOR PUBLIC MinesweeperBestTimes(INPUT poSettings AS ISettings):
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("Best times need settings").
        mSettings = poSettings.
    END CONSTRUCTOR.

    /* The best time for a level, or 0 when there is none yet or the level is Custom. Throws
       GridException for a level that does not exist. */
    METHOD PUBLIC INTEGER Best(INPUT pcLevel AS CHARACTER):
        CheckLevel(pcLevel).
        IF NOT MinesweeperLevels:IsStandard(pcLevel) THEN RETURN 0.
        RETURN MAXIMUM(0, mSettings:GetInteger(KeyOf(pcLevel), 0)).
    END METHOD.

    /* Notes a winning time. Returns true when it is a new best and was saved, which needs a
       standard level and a time from 1 to 999 seconds that beats the old one. */
    METHOD PUBLIC LOGICAL Record(INPUT pcLevel AS CHARACTER, INPUT piSeconds AS INTEGER):
        CheckLevel(pcLevel).
        IF NOT MinesweeperLevels:IsStandard(pcLevel) THEN RETURN FALSE.
        IF piSeconds = ? OR piSeconds < 1 OR piSeconds > 999 THEN RETURN FALSE.
        IF Best(pcLevel) > 0 AND Best(pcLevel) <= piSeconds THEN RETURN FALSE.
        mSettings:SetInteger(KeyOf(pcLevel), piSeconds).
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE CHARACTER KeyOf(INPUT pcLevel AS CHARACTER):
        RETURN "minesweeper.best." + LC(MinesweeperLevels:Canonical(pcLevel)).
    END METHOD.

    METHOD PRIVATE VOID CheckLevel(INPUT pcLevel AS CHARACTER):
        IF MinesweeperLevels:Canonical(pcLevel) = "" THEN
            UNDO, THROW NEW GridException("Unknown Minesweeper level: " + STRING(pcLevel)).
    END METHOD.

END CLASS.
