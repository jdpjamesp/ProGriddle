/* The words of the help screen, one line for each CHR(10), and the list of what has been discovered. The help says what every key does,
   in the keys of the original game. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueHelp FINAL:

    /* The lines of the help screen, none longer than 72 characters. */
    METHOD PUBLIC STATIC CHARACTER Text():
        RETURN "ROGUE" + CHR(10) +
            "" + CHR(10) +
            "Move    h j k l y u b n, or the number pad and arrows. Shift runs." + CHR(10) +
            "Fight   walk into a monster." + CHR(10) +
            "Rest    . or 5      Search  s      Pick up  ," + CHR(10) +
            "Stairs  > goes down, < goes up (only with the amulet)" + CHR(10) +
            "Pack    i show the pack    q quaff    r read    e eat" + CHR(10) +
            "        w wield    W wear    T take off    P put on    R remove ring" + CHR(10) +
            "        d drop    t throw    z zap    M messages    D discoveries" + CHR(10) +
            "Q       give up.  F2 starts a new game.  Keys button: vi or number pad." + CHR(10) +
            "" + CHR(10) +
            "Things  * gold  : food  ) weapon  ] armour  ! potion  ? scroll" + CHR(10) +
            "        = ring  / wand  , the amulet" + CHR(10) +
            "Dungeon + door  # passage  % stairs  ^ trap  @ you  A to Z monsters" + CHR(10) +
            "" + CHR(10) +
            "Find the Amulet of Yendor on the 26th level and climb out with it." + CHR(10) +
            "" + CHR(10) +
            "Press any key to go back to the game.".
    END METHOD.
    /* What the hero knows: the potions, scrolls, wands and rings that have been learnt, by real name, one line each. */
    METHOD PUBLIC STATIC CHARACTER Discoveries(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DO i = 0 TO 13:
            IF poWorld:Names:IsKnown(ItemType:Potion, i) THEN result = result + "potion of " + Potions:NameOf(PotionKind:GetEnum(i)) + CHR(10).
        END.
        DO i = 0 TO 13:
            IF poWorld:Names:IsKnown(ItemType:Scroll, i) THEN result = result + "scroll of " + Scrolls:NameOf(ScrollKind:GetEnum(i)) + CHR(10).
        END.
        DO i = 0 TO 13:
            IF poWorld:Names:IsKnown(ItemType:Wand, i) THEN result = result + "wand of " + Wands:NameOf(WandKind:GetEnum(i)) + CHR(10).
        END.
        DO i = 0 TO 13:
            IF poWorld:Names:IsKnown(ItemType:Ring, i) THEN result = result + "ring of " + Rings:NameOf(RingKind:GetEnum(i)) + CHR(10).
        END.
        RETURN RIGHT-TRIM(result, CHR(10)).
    END METHOD.

END CLASS.
