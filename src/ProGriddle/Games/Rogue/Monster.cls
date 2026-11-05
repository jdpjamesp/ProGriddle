/* One monster on the level: what it is, where it is and its state. A record with no rules of its own (what it does on its turn is in
   MonsterTurns). Awake is false while it sleeps: a sleeping monster stays put until the hero comes near and it wakes. Held, Confused,
   Slowed and Hasted count turns left, and Stunned the turns it cannot act. Cancelled monsters have lost their special power. Gold is
   what it drops when it dies. Seen is true once the hero has laid eyes on it, so a monster found by a potion is still named properly. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Monster FINAL:

    DEFINE PUBLIC PROPERTY Kind AS MonsterKind NO-UNDO
        GET.
        SET.

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

    DEFINE PUBLIC PROPERTY Awake AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Invisible AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Cancelled AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Seen AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Held AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Confused AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Slowed AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Hasted AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY Gold AS INTEGER NO-UNDO
        GET.
        SET.

    /* A monster starts awake only if it is a mean one, and invisible only if it is of an invisible kind. Throws GridException for no kind
       or fewer than 1 hit point. */
    CONSTRUCTOR PUBLIC Monster(INPUT poKind AS MonsterKind, INPUT piHp AS INTEGER):
        IF NOT VALID-OBJECT(poKind) THEN UNDO, THROW NEW GridException("A monster needs a kind").
        IF piHp = ? OR piHp < 1 THEN UNDO, THROW NEW GridException("A monster needs at least 1 hit point").
        Kind = poKind.
        Hp = piHp.
        MaxHp = piHp.
        Awake = Bestiary:Has(poKind, "M").
        Invisible = Bestiary:Has(poKind, "I").
    END CONSTRUCTOR.

    /* The letter the monster is drawn as. */
    METHOD PUBLIC CHARACTER Letter():
        RETURN Bestiary:Letter(Kind).
    END METHOD.

    /* The name of the kind, such as "bat". */
    METHOD PUBLIC CHARACTER Called():
        RETURN Bestiary:NameOf(Kind).
    END METHOD.

END CLASS.
