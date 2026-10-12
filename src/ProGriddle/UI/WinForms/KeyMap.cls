/* Turns key presses into game commands. It works on key NAMES (the text of a .NET Keys value,
   such as "Space", "S", "Oemplus") so it needs no UI types and the window decides where the
   names come from.

     Space              start, or pause when running
     S or Right         one step
     R                  reset
     + or Up            faster
     - or Down          slower
     a letter           an extra command of the game whose key letter it is

   Extra commands come from IGameInput:CommandNames ("Random:G,Clear:C"). */
USING Progress.Lang.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.KeyMap FINAL:

    /* The command for a key, or the unknown value when the key does nothing. plRunning decides
       whether Space starts or pauses. */
    METHOD PUBLIC GameCommand CommandFor(INPUT pcKey AS CHARACTER, INPUT plRunning AS LOGICAL):
        CASE pcKey:
            WHEN "Space" THEN RETURN (IF plRunning THEN GameCommand:PauseGame ELSE GameCommand:Start).
            WHEN "S" OR WHEN "Right" THEN RETURN GameCommand:StepOnce.
            WHEN "R" THEN RETURN GameCommand:Reset.
            WHEN "Oemplus" OR WHEN "Add" OR WHEN "Up" THEN RETURN GameCommand:SpeedUp.
            WHEN "OemMinus" OR WHEN "Subtract" OR WHEN "Down" THEN RETURN GameCommand:SlowDown.
        END CASE.
        RETURN ?.
    END METHOD.

    /* The name of the extra command whose key letter is pcKey, or an empty string. pcCommands
       is the text from IGameInput:CommandNames. Letters are compared ignoring case. */
    METHOD PUBLIC CHARACTER ExtraFor(INPUT pcKey AS CHARACTER, INPUT pcCommands AS CHARACTER):
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE item AS CHARACTER NO-UNDO.
        IF pcKey = ? OR LENGTH(pcKey) <> 1 OR pcCommands = ? OR pcCommands = "" THEN RETURN "".
        DO i = 1 TO NUM-ENTRIES(pcCommands):
            item = TRIM(ENTRY(i, pcCommands)).
            IF NUM-ENTRIES(item, ":") = 2 AND ENTRY(2, item, ":") = pcKey THEN RETURN ENTRY(1, item, ":").
        END.
        RETURN "".
    END METHOD.

    /* The name part of an extra command item: "Random:G" gives "Random". */
    METHOD PUBLIC CHARACTER NameOf(INPUT pcEntry AS CHARACTER):
        RETURN ENTRY(1, TRIM(pcEntry), ":").
    END METHOD.

    /* The key letter of an extra command item: "Random:G" gives "G", "Random" gives "". */
    METHOD PUBLIC CHARACTER KeyOf(INPUT pcEntry AS CHARACTER):
        IF NUM-ENTRIES(TRIM(pcEntry), ":") < 2 THEN RETURN "".
        RETURN ENTRY(2, TRIM(pcEntry), ":").
    END METHOD.

END CLASS.
