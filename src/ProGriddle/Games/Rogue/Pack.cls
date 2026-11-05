/* What the hero carries: 23 slots lettered a to w. An item keeps its letter for as long as it is in the pack, and a new one takes the
   first free letter (stackable things of the same kind join the stack they match). The pack also remembers which slots are in use as
   the wielded weapon, the worn armour and the rings on the left and the right hand (-1 for none). Gold is not carried here: it goes
   straight into the purse. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Pack FINAL:

    DEFINE PRIVATE VARIABLE mSlot AS Item NO-UNDO EXTENT 23.

    /* The slot of the wielded weapon, the worn armour and the two rings, or -1. */
    DEFINE PUBLIC PROPERTY WieldedSlot AS INTEGER NO-UNDO INITIAL -1
        GET.
        SET.

    DEFINE PUBLIC PROPERTY WornSlot AS INTEGER NO-UNDO INITIAL -1
        GET.
        SET.

    DEFINE PUBLIC PROPERTY LeftRingSlot AS INTEGER NO-UNDO INITIAL -1
        GET.
        SET.

    DEFINE PUBLIC PROPERTY RightRingSlot AS INTEGER NO-UNDO INITIAL -1
        GET.
        SET.

    /* How many slots are in use. */
    DEFINE PUBLIC PROPERTY Count AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO RogueRules:PackSize():
                IF VALID-OBJECT(mSlot[i]) THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* The letter of a slot, a to w. Throws GridException for a slot that is not 0 to 22. */
    METHOD PUBLIC CHARACTER LetterOf(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN CHR(ASC("a") + piSlot).
    END METHOD.

    /* The slot of a letter, or -1 for anything that is not a letter a to w. */
    METHOD PUBLIC INTEGER SlotOf(INPUT pcLetter AS CHARACTER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        IF pcLetter = ? OR LENGTH(pcLetter) <> 1 THEN RETURN -1.
        n = ASC(pcLetter) - ASC("a").
        IF n < 0 OR n >= RogueRules:PackSize() THEN RETURN -1.
        RETURN n.
    END METHOD.

    /* True when the slot holds something. */
    METHOD PUBLIC LOGICAL Holds(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN VALID-OBJECT(mSlot[piSlot + 1]).
    END METHOD.

    /* The item in a slot, or unknown for an empty one. */
    METHOD PUBLIC Item At(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN mSlot[piSlot + 1].
    END METHOD.

    /* The first empty slot, or -1 when the pack is full. */
    METHOD PUBLIC INTEGER FreeSlot():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO RogueRules:PackSize():
            IF NOT VALID-OBJECT(mSlot[i]) THEN RETURN i - 1.
        END.
        RETURN -1.
    END METHOD.

    /* True when the item would go in: there is a free slot, or a stack it can join. */
    METHOD PUBLIC LOGICAL CanTake(INPUT poItem AS Item):
        RETURN FreeSlot() >= 0 OR StackFor(poItem) >= 0.
    END METHOD.

    /* Puts an item in the pack and gives the slot it went to, joining a stack it matches (the count is added and poItem is not kept).
       Returns -1 and takes nothing when the pack is full. Gold is refused with a GridException: it belongs in the purse. */
    METHOD PUBLIC INTEGER Add(INPUT poItem AS Item):
        DEFINE VARIABLE slot AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poItem) THEN UNDO, THROW NEW GridException("There is no item to put in the pack").
        IF poItem:Category = ItemType:Gold THEN UNDO, THROW NEW GridException("Gold goes in the purse, not the pack").
        slot = StackFor(poItem).
        IF slot >= 0 THEN DO:
            mSlot[slot + 1]:Count = mSlot[slot + 1]:Count + poItem:Count.
            RETURN slot.
        END.
        slot = FreeSlot().
        IF slot < 0 THEN RETURN -1.
        mSlot[slot + 1] = poItem.
        RETURN slot.
    END METHOD.

    /* Takes piCount of the item in a slot out of the pack and gives them as an item (the item itself when it is all of them). A slot that
       is emptied stops being the wielded weapon, the worn armour or a ring. Throws GridException for an empty slot or a count that is
       not 1 up to what the slot holds. */
    METHOD PUBLIC Item Take(INPUT piSlot AS INTEGER, INPUT piCount AS INTEGER):
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        IF NOT Holds(piSlot) THEN UNDO, THROW NEW GridException("Nothing is in slot " + STRING(piSlot)).
        oItem = mSlot[piSlot + 1].
        IF piCount = ? OR piCount < 1 OR piCount > oItem:Count THEN UNDO, THROW NEW GridException("Cannot take " + STRING(piCount) + " of " + STRING(oItem:Count)).
        IF piCount < oItem:Count THEN DO:
            oItem:Count = oItem:Count - piCount.
            RETURN oItem:Duplicate(piCount).
        END.
        mSlot[piSlot + 1] = ?.
        IF WieldedSlot = piSlot THEN WieldedSlot = -1.
        IF WornSlot = piSlot THEN WornSlot = -1.
        IF LeftRingSlot = piSlot THEN LeftRingSlot = -1.
        IF RightRingSlot = piSlot THEN RightRingSlot = -1.
        RETURN oItem.
    END METHOD.

    /* True when the slot is the wielded weapon, the worn armour or a worn ring. */
    METHOD PUBLIC LOGICAL InUse(INPUT piSlot AS INTEGER):
        CheckSlot(piSlot).
        RETURN piSlot = WieldedSlot OR piSlot = WornSlot OR piSlot = LeftRingSlot OR piSlot = RightRingSlot.
    END METHOD.

    /* The wielded weapon, the worn armour, and the rings on the left and right hands: unknown when there is none. */
    METHOD PUBLIC Item Weapon():
        RETURN (IF WieldedSlot >= 0 THEN mSlot[WieldedSlot + 1] ELSE ?).
    END METHOD.

    METHOD PUBLIC Item Worn():
        RETURN (IF WornSlot >= 0 THEN mSlot[WornSlot + 1] ELSE ?).
    END METHOD.

    METHOD PUBLIC Item LeftRing():
        RETURN (IF LeftRingSlot >= 0 THEN mSlot[LeftRingSlot + 1] ELSE ?).
    END METHOD.

    METHOD PUBLIC Item RightRing():
        RETURN (IF RightRingSlot >= 0 THEN mSlot[RightRingSlot + 1] ELSE ?).
    END METHOD.

    /* True when a worn ring is of the kind. */
    METHOD PUBLIC LOGICAL WearingRing(INPUT poKind AS RingKind):
        DEFINE VARIABLE oLeft  AS Item NO-UNDO.
        DEFINE VARIABLE oRight AS Item NO-UNDO.
        oLeft = LeftRing().
        oRight = RightRing().
        RETURN (VALID-OBJECT(oLeft) AND oLeft:Kind = INTEGER(poKind)) OR (VALID-OBJECT(oRight) AND oRight:Kind = INTEGER(poKind)).
    END METHOD.

    /* The sum of the bonuses of the worn rings of a kind (a ring of protection of +2 and one of +1 give 3). */
    METHOD PUBLIC INTEGER RingBonus(INPUT poKind AS RingKind):
        DEFINE VARIABLE oLeft  AS Item    NO-UNDO.
        DEFINE VARIABLE oRight AS Item    NO-UNDO.
        DEFINE VARIABLE total  AS INTEGER NO-UNDO.
        oLeft = LeftRing().
        oRight = RightRing().
        IF VALID-OBJECT(oLeft) AND oLeft:Kind = INTEGER(poKind) THEN total = total + oLeft:Bonus.
        IF VALID-OBJECT(oRight) AND oRight:Kind = INTEGER(poKind) THEN total = total + oRight:Bonus.
        RETURN total.
    END METHOD.

    /* What everything in the pack adds to the score. */
    METHOD PUBLIC INTEGER Worth():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DO i = 1 TO RogueRules:PackSize():
            IF VALID-OBJECT(mSlot[i]) THEN t = t + mSlot[i]:Worth().
        END.
        RETURN t.
    END METHOD.

    /* True when the pack holds the amulet. */
    METHOD PUBLIC LOGICAL HasAmulet():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO RogueRules:PackSize():
            IF VALID-OBJECT(mSlot[i]) AND mSlot[i]:Category = ItemType:Amulet THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* The slot of a stack the item can join, or -1. */
    METHOD PRIVATE INTEGER StackFor(INPUT poItem AS Item):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poItem) THEN RETURN -1.
        DO i = 1 TO RogueRules:PackSize():
            IF VALID-OBJECT(mSlot[i]) AND mSlot[i]:StacksWith(poItem) THEN RETURN i - 1.
        END.
        RETURN -1.
    END METHOD.

    METHOD PRIVATE VOID CheckSlot(INPUT piSlot AS INTEGER):
        IF piSlot = ? OR piSlot < 0 OR piSlot >= RogueRules:PackSize() THEN UNDO, THROW NEW GridException("There is no pack slot " + STRING(piSlot)).
    END METHOD.

END CLASS.
