/* The hero: position, strength, hit points, experience, gold, what is in the stomach, and the timers of the things that are wrong with
   or right about the hero (confused, blind, hasted, levitating, asleep, stuck in a bear trap, hallucinating, able to see invisible).
   A timer counts the turns left and is 0 when it is not running. A record with no rules of its own: the game changes it. Rank is the
   experience level, 1 to 21. Nutrition is the stomach: it starts full and each turn costs 1 (see RogueRules:StomachSize). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Hero FINAL:

    DEFINE PUBLIC PROPERTY X AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Y AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Hp AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY MaxHp AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Strength AS INTEGER NO-UNDO
        GET.
        SET.

    /* The strength the hero had before poison and weakness, which a potion of restore strength puts back. */
    DEFINE PUBLIC PROPERTY MaxStrength AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Experience AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Rank AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Gold AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Nutrition AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Confused AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Blind AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Hasted AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Levitating AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Asleep AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Stuck AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Hallucinating AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY SeesInvisible AS INTEGER NO-UNDO
        GET.
        SET.

    /* Turns left in which a potion of monster detection shows every monster on the level, a potion of magic detection every magic thing
       on the floor, and a scroll of food detection every bit of food. */
    DEFINE PUBLIC PROPERTY SensesMonsters AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY SensesMagic AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY SensesFood AS INTEGER NO-UNDO
        GET.
        SET.

    /* How far the hero has got to the next hit point (counted by Upkeep), and the stage of hunger already told about, 0 satisfied to
       4 starved, so each is said only once as the stomach empties. */
    DEFINE PUBLIC PROPERTY HealCounter AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY HungerStage AS INTEGER NO-UNDO
        GET.
        SET.
    /* True while the hero's touch confuses the monster it hits (the scroll of monster confusion). */
    DEFINE PUBLIC PROPERTY ConfusingTouch AS LOGICAL NO-UNDO
        GET.
        SET.

    /* Held by a monster (a venus flytrap): the hero cannot walk away until it is dead. */
    DEFINE PUBLIC PROPERTY HeldBy AS Monster NO-UNDO
        GET.
        SET.

    /* The hero at the start of a game: 12 hit points, a strength of 16, a full stomach, nothing else. */
    CONSTRUCTOR PUBLIC Hero():
        Hp = RogueRules:StartHp().
        MaxHp = RogueRules:StartHp().
        Strength = RogueRules:StartStrength().
        MaxStrength = RogueRules:StartStrength().
        Rank = 1.
        Nutrition = RogueRules:StomachSize().
    END CONSTRUCTOR.

END CLASS.
