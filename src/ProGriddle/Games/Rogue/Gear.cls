/* What the hero wears, wields and puts down or picks up. Each of the actions gives true when it took a turn (a refused one does not, and
   says why). A cursed weapon, suit of armour or ring cannot be taken off once it is on: the hero is told it appears to be cursed. Putting
   on armour or a ring tells the hero its plus and, for the rings that have an obvious effect, which ring it is.

   Dropping puts one of a stack on the floor (the whole thing for anything else) where the hero stands, if there is room: a square can
   hold one thing and stairs and doorways none. Walking onto a thing picks it up (Pickup), gold going into the purse and the rest into the
   pack when it has room. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Gear FINAL:

    /* An item of the pack as one line of the inventory: "b) a +1 ring mail [AC 6] (being worn)". */
    METHOD PUBLIC STATIC CHARACTER Line(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        DEFINE VARIABLE state AS CHARACTER NO-UNDO.
        IF piSlot = poWorld:Pack:WieldedSlot THEN state = " (weapon in hand)".
        ELSE IF piSlot = poWorld:Pack:WornSlot THEN state = " (being worn)".
        ELSE IF piSlot = poWorld:Pack:LeftRingSlot THEN state = " (on left hand)".
        ELSE IF piSlot = poWorld:Pack:RightRingSlot THEN state = " (on right hand)".
        RETURN poWorld:Pack:LetterOf(piSlot) + ") " + ItemText:Describe(poWorld:Pack:At(piSlot), poWorld:Names) + state.
    END METHOD.

    /* Checks that a slot holds something of the sort asked for. Says what is wrong and gives false when not. */
    METHOD PUBLIC STATIC LOGICAL Holds(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER, INPUT poType AS ItemType, INPUT pcRefusal AS CHARACTER):
        IF piSlot < 0 OR piSlot >= RogueRules:PackSize() OR NOT poWorld:Pack:Holds(piSlot) THEN DO:
            poWorld:Say("You have nothing like that.").
            RETURN FALSE.
        END.
        IF poWorld:Pack:At(piSlot):Category <> poType THEN DO:
            poWorld:Say(pcRefusal).
            RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    /* Takes a weapon in hand. */
    METHOD PUBLIC STATIC LOGICAL Wield(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        DEFINE VARIABLE oOld AS Item NO-UNDO.
        IF NOT Holds(poWorld, piSlot, ItemType:Weapon, "You cannot wield that.") THEN RETURN FALSE.
        oOld = poWorld:Pack:Weapon().
        IF poWorld:Pack:WieldedSlot = piSlot THEN DO:
            poWorld:Say("You are already wielding that.").
            RETURN FALSE.
        END.
        IF VALID-OBJECT(oOld) AND oOld:Cursed THEN DO:
            poWorld:Say("You can't. Your " + Weapons:NameOf(WeaponKind:GetEnum(oOld:Kind)) + " appears to be cursed.").
            RETURN FALSE.
        END.
        poWorld:Pack:WieldedSlot = piSlot.
        poWorld:Pack:At(piSlot):Known = TRUE.
        poWorld:Say("You are now wielding " + Line(poWorld, piSlot) + ".").
        RETURN TRUE.
    END METHOD.

    /* Puts on a suit of armour. */
    METHOD PUBLIC STATIC LOGICAL Wear(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        IF NOT Holds(poWorld, piSlot, ItemType:Armour, "You cannot wear that.") THEN RETURN FALSE.
        IF poWorld:Pack:WornSlot >= 0 THEN DO:
            poWorld:Say("You are already wearing some. You'll have to take it off first.").
            RETURN FALSE.
        END.
        poWorld:Pack:WornSlot = piSlot.
        poWorld:Pack:At(piSlot):Known = TRUE.
        poWorld:Say("You are now wearing " + Line(poWorld, piSlot) + ".").
        RETURN TRUE.
    END METHOD.

    /* Takes off the armour that is worn. */
    METHOD PUBLIC STATIC LOGICAL TakeOff(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE oWorn AS Item    NO-UNDO.
        DEFINE VARIABLE slot  AS INTEGER NO-UNDO.
        oWorn = poWorld:Pack:Worn().
        IF NOT VALID-OBJECT(oWorn) THEN DO:
            poWorld:Say("You aren't wearing any armor.").
            RETURN FALSE.
        END.
        IF oWorn:Cursed THEN DO:
            poWorld:Say("You can't. It appears to be cursed.").
            RETURN FALSE.
        END.
        slot = poWorld:Pack:WornSlot.
        poWorld:Pack:WornSlot = -1.
        poWorld:Say("You used to be wearing " + Line(poWorld, slot) + ".").
        RETURN TRUE.
    END METHOD.

    /* Puts a ring on the left hand, or the right when the left is taken. The ring tells the hero its plus when it has an obvious one. */
    METHOD PUBLIC STATIC LOGICAL PutOn(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        DEFINE VARIABLE oRing AS Item NO-UNDO.
        IF NOT Holds(poWorld, piSlot, ItemType:Ring, "You cannot put that on.") THEN RETURN FALSE.
        IF poWorld:Pack:LeftRingSlot >= 0 AND poWorld:Pack:RightRingSlot >= 0 THEN DO:
            poWorld:Say("You already have a ring on each hand.").
            RETURN FALSE.
        END.
        oRing = poWorld:Pack:At(piSlot).
        IF poWorld:Pack:LeftRingSlot < 0 THEN poWorld:Pack:LeftRingSlot = piSlot.
        ELSE poWorld:Pack:RightRingSlot = piSlot.
        CASE RingKind:GetEnum(oRing:Kind):
            WHEN RingKind:Protection OR WHEN RingKind:AddStrength OR WHEN RingKind:Dexterity OR WHEN RingKind:IncreaseDamage THEN DO:
                poWorld:Names:Learn(ItemType:Ring, oRing:Kind).
                oRing:Known = TRUE.
            END.
            WHEN RingKind:SeeInvisible THEN poWorld:Names:Learn(ItemType:Ring, oRing:Kind).
        END CASE.
        poWorld:Say("You are now wearing " + Line(poWorld, piSlot) + ".").
        RETURN TRUE.
    END METHOD.

    /* Takes a ring off a hand. A cursed ring stays. */
    METHOD PUBLIC STATIC LOGICAL RemoveRing(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        DEFINE VARIABLE oRing AS Item NO-UNDO.
        IF NOT Holds(poWorld, piSlot, ItemType:Ring, "That is not a ring.") THEN RETURN FALSE.
        IF piSlot <> poWorld:Pack:LeftRingSlot AND piSlot <> poWorld:Pack:RightRingSlot THEN DO:
            poWorld:Say("You are not wearing that ring.").
            RETURN FALSE.
        END.
        oRing = poWorld:Pack:At(piSlot).
        IF oRing:Cursed THEN DO:
            poWorld:Say("You can't. It appears to be cursed.").
            RETURN FALSE.
        END.
        IF piSlot = poWorld:Pack:LeftRingSlot THEN poWorld:Pack:LeftRingSlot = -1.
        ELSE poWorld:Pack:RightRingSlot = -1.
        poWorld:Say("You removed " + Line(poWorld, piSlot) + ".").
        RETURN TRUE.
    END METHOD.

    /* The number of rings on the hands. */
    METHOD PUBLIC STATIC INTEGER RingsWorn(INPUT poWorld AS RogueWorld):
        RETURN (IF poWorld:Pack:LeftRingSlot >= 0 THEN 1 ELSE 0) + (IF poWorld:Pack:RightRingSlot >= 0 THEN 1 ELSE 0).
    END METHOD.

    /* Puts one of the thing in a slot on the floor where the hero stands. */
    METHOD PUBLIC STATIC LOGICAL DropItem(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        DEFINE VARIABLE oItem  AS Item NO-UNDO.
        DEFINE VARIABLE oLeave AS Item NO-UNDO.
        IF piSlot < 0 OR piSlot >= RogueRules:PackSize() OR NOT poWorld:Pack:Holds(piSlot) THEN DO:
            poWorld:Say("You have nothing like that.").
            RETURN FALSE.
        END.
        oItem = poWorld:Pack:At(piSlot).
        IF poWorld:Pack:InUse(piSlot) AND oItem:Cursed THEN DO:
            poWorld:Say("You can't. It appears to be cursed.").
            RETURN FALSE.
        END.
        IF NOT poWorld:CanLieAt(poWorld:Hero:X, poWorld:Hero:Y) THEN DO:
            poWorld:Say("There is no room to put that here.").
            RETURN FALSE.
        END.
        oLeave = poWorld:Pack:Take(piSlot, 1).
        poWorld:DropOnFloor(oLeave, poWorld:Hero:X, poWorld:Hero:Y).
        poWorld:Say("You dropped " + ItemText:Describe(oLeave, poWorld:Names) + ".").
        RETURN TRUE.
    END METHOD.

    /* Picks up what lies where the hero stands: gold goes in the purse, the rest in the pack if it will go. Gives true when something
       was picked up. A pack that is too full leaves the thing where it is and says so. */
    METHOD PUBLIC STATIC LOGICAL Pickup(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE oItem AS Item    NO-UNDO.
        DEFINE VARIABLE slot  AS INTEGER NO-UNDO.
        oItem = poWorld:FloorItemAt(poWorld:Hero:X, poWorld:Hero:Y).
        IF NOT VALID-OBJECT(oItem) THEN RETURN FALSE.
        IF oItem:Category = ItemType:Gold THEN DO:
            poWorld:TakeFloorItem(poWorld:Hero:X, poWorld:Hero:Y).
            poWorld:Hero:Gold = poWorld:Hero:Gold + oItem:Count.
            poWorld:Say("You found " + STRING(oItem:Count) + " pieces of gold.").
            RETURN TRUE.
        END.
        IF NOT poWorld:Pack:CanTake(oItem) THEN DO:
            poWorld:Say("Your pack is too full to pick up " + ItemText:Describe(oItem, poWorld:Names) + ".").
            RETURN FALSE.
        END.
        poWorld:TakeFloorItem(poWorld:Hero:X, poWorld:Hero:Y).
        slot = poWorld:Pack:Add(oItem).
        poWorld:Say("You now have " + Line(poWorld, slot) + ".").
        RETURN TRUE.
    END METHOD.

END CLASS.
