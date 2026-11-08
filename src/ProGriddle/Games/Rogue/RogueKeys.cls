/* Turns a key into the token RogueGame:Command wants. The window names a key as .NET does ("A", "OemPeriod", "NumPad4", "Left") and the
   input says whether Shift is down. The movement keys are chosen with a setting:

     vi        h j k l y u b n move west, south, north, east and the four diagonals (shifted: run), as in the original
     numpad    the number pad and the arrow keys (shifted: run). The letters h j k l y u b n are then plain letters

   The arrow keys and the number pad (and Home, End, Page Up and Page Down) move in both. A letter is its own token in lower case, and a
   shifted letter is "S-" and the lower case letter ("S-w" is a capital W). While the game is waiting for an item, letters stay letters
   in both settings, because pack letters run from a to w and h j k l y u b n are among them. The symbols the game uses are made the
   way a keyboard makes them: Shift with the full stop is ">", with the comma "<", with the slash "?", and with 6 "^". The other keys,
   such as the function keys, have no token (an empty one). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueKeys FINAL:

    /* The number pad direction of an arrow, a number pad key or one of the vi letters: "1" to "9", or "" for any other key. */
    METHOD PUBLIC STATIC CHARACTER Direction(INPUT pcKey AS CHARACTER, INPUT plVi AS LOGICAL):
        CASE pcKey:
            WHEN "Left" OR WHEN "NumPad4" THEN RETURN "4".
            WHEN "Right" OR WHEN "NumPad6" THEN RETURN "6".
            WHEN "Up" OR WHEN "NumPad8" THEN RETURN "8".
            WHEN "Down" OR WHEN "NumPad2" THEN RETURN "2".
            WHEN "Home" OR WHEN "NumPad7" THEN RETURN "7".
            WHEN "PageUp" OR WHEN "Prior" OR WHEN "NumPad9" THEN RETURN "9".
            WHEN "End" OR WHEN "NumPad1" THEN RETURN "1".
            WHEN "PageDown" OR WHEN "Next" OR WHEN "NumPad3" THEN RETURN "3".
        END CASE.
        IF plVi AND LENGTH(pcKey) = 1 THEN DO:
            CASE pcKey:
                WHEN "H" THEN RETURN "4".
                WHEN "J" THEN RETURN "2".
                WHEN "K" THEN RETURN "8".
                WHEN "L" THEN RETURN "6".
                WHEN "Y" THEN RETURN "7".
                WHEN "U" THEN RETURN "9".
                WHEN "B" THEN RETURN "1".
                WHEN "N" THEN RETURN "3".
            END CASE.
        END.
        RETURN "".
    END METHOD.

    /* The token for a key, or "" when the game has nothing to do with it. plPicking is true while the game waits for a pack letter. */
    METHOD PUBLIC STATIC CHARACTER Token(INPUT pcKey AS CHARACTER, INPUT plShift AS LOGICAL, INPUT plVi AS LOGICAL, INPUT plPicking AS LOGICAL):
        VAR CHARACTER dir.
        IF pcKey = ? OR pcKey = "" THEN RETURN "".
        /* a letter while picking an item is a pack letter */
        IF plPicking AND LENGTH(pcKey) = 1 AND ASC(pcKey) >= ASC("A") AND ASC(pcKey) <= ASC("Z") THEN RETURN (IF plShift THEN "S-" ELSE "") + LC(pcKey).
        dir = Direction(pcKey, plVi).
        IF dir <> "" THEN RETURN (IF plShift THEN "run" ELSE "") + dir.
        IF LENGTH(pcKey) = 1 AND ASC(pcKey) >= ASC("A") AND ASC(pcKey) <= ASC("Z") THEN RETURN (IF plShift THEN "S-" ELSE "") + LC(pcKey).
        CASE pcKey:
            WHEN "NumPad5" OR WHEN "Clear" THEN RETURN "5".
            WHEN "Decimal" OR WHEN "Delete" THEN RETURN ".".
            WHEN "OemPeriod" THEN RETURN (IF plShift THEN ">" ELSE ".").
            WHEN "Oemcomma" THEN RETURN (IF plShift THEN "<" ELSE ",").
            WHEN "OemQuestion" THEN RETURN (IF plShift THEN "?" ELSE "/").
            WHEN "D6" THEN RETURN (IF plShift THEN "^" ELSE "").
            WHEN "Escape" THEN RETURN "ESC".
            WHEN "Return" OR WHEN "Enter" THEN RETURN "ENTER".
            WHEN "Space" THEN RETURN "SPACE".
            OTHERWISE RETURN "".
        END CASE.
    END METHOD.

END CLASS.
