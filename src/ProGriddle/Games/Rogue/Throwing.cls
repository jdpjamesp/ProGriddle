/* Throwing one thing from the pack in a direction. It flies up to ten squares and stops at a wall or the first monster in its way. At a
   monster it has a chance to hit (the same roll as a blow, with the thing's own plus), and a hit does the thing's thrown damage: an
   arrow does its full damage only when a bow is wielded (and the bow's plus counts), thrown by hand it does almost nothing; darts,
   shuriken, daggers and spears do their thrown damage; anything else does 1d2. A flask thrown breaks. An arrow that hits breaks one time
   in three, everything else lands on the floor where it stopped (or near it when something is already there). Throwing always takes a
   turn. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Throwing FINAL:

    /* Throws one of the thing in a slot. Gives false (and says why) when the thing cannot be thrown: a cursed thing in use. */
    METHOD PUBLIC STATIC LOGICAL Throw(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER, INPUT piDX AS INTEGER, INPUT piDY AS INTEGER):
        VAR Item oOne.
        VAR Monster oMonster.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER i.
        VAR LOGICAL broke.
        IF piSlot < 0 OR piSlot >= RogueRules:PackSize() OR NOT poWorld:Pack:Holds(piSlot) THEN DO:
            poWorld:Say("You have nothing like that.").
            RETURN FALSE.
        END.
        IF poWorld:Pack:InUse(piSlot) AND poWorld:Pack:At(piSlot):Cursed THEN DO:
            poWorld:Say("You can't. It appears to be cursed.").
            RETURN FALSE.
        END.
        oOne = poWorld:Pack:Take(piSlot, 1).
        x = poWorld:Hero:X.
        y = poWorld:Hero:Y.
        DO i = 1 TO 10:
            IF poWorld:Cave:Opaque(x + piDX, y + piDY) THEN LEAVE.
            x = x + piDX.
            y = y + piDY.
            oMonster = poWorld:MonsterAtCell(x, y).
            IF VALID-OBJECT(oMonster) THEN DO:
                broke = Strike(poWorld, oOne, oMonster).
                LEAVE.
            END.
        END.
        IF oOne:Category = ItemType:Potion THEN DO:
            poWorld:Say("The flask shatters and its liquid splashes harmlessly.").
            RETURN TRUE.
        END.
        IF NOT broke THEN poWorld:DropOnFloor(oOne, x, y).
        RETURN TRUE.
    END METHOD.

    /* The dice of a thrown thing's hit. */
    METHOD PUBLIC STATIC CHARACTER DiceOf(INPUT poWorld AS RogueWorld, INPUT poItem AS Item):
        VAR Item oBow.
        IF poItem:Category <> ItemType:Weapon THEN RETURN "1d2".
        IF poItem:Kind = INTEGER(WeaponKind:Arrow) THEN DO:
            oBow = poWorld:Pack:Weapon().
            IF VALID-OBJECT(oBow) AND oBow:Kind = INTEGER(WeaponKind:Bow) THEN RETURN Weapons:Hurled(WeaponKind:Arrow).
            RETURN Weapons:Swing(WeaponKind:Arrow).
        END.
        RETURN Weapons:Hurled(WeaponKind:GetEnum(poItem:Kind)).
    END METHOD.

    /* A thrown thing meets a monster: a hit or a miss. Gives true when the thing was an arrow that broke. */
    METHOD PRIVATE STATIC LOGICAL Strike(INPUT poWorld AS RogueWorld, INPUT poItem AS Item, INPUT poMonster AS Monster):
        VAR INTEGER bonus.
        VAR INTEGER damage.
        VAR Item oBow.
        VAR CHARACTER noun.
        VAR LOGICAL asleep.
        noun = "The " + ItemText:Noun(poItem, poWorld:Names).
        asleep = NOT poMonster:Awake.
        poMonster:Awake = TRUE.
        bonus = RogueRules:StrengthHit(Fighting:EffectiveStrength(poWorld)) + poWorld:Pack:RingBonus(RingKind:Dexterity).
        IF poItem:Category = ItemType:Weapon THEN DO:
            bonus = bonus + poItem:Bonus.
            oBow = poWorld:Pack:Weapon().
            IF poItem:Kind = INTEGER(WeaponKind:Arrow) AND VALID-OBJECT(oBow) AND oBow:Kind = INTEGER(WeaponKind:Bow) THEN bonus = bonus + oBow:Bonus.
        END.
        IF NOT Fighting:Swing(poWorld, poWorld:Hero:Rank, Bestiary:ArmourClass(poMonster:Kind), bonus + (IF asleep THEN 4 ELSE 0)) THEN DO:
            poWorld:Say(noun + " misses " + Fighting:Name(poWorld, poMonster, FALSE) + ".").
            RETURN FALSE.
        END.
        damage = MAXIMUM(1, Dice:Roll(DiceOf(poWorld, poItem), poWorld:Random) + (IF poItem:Category = ItemType:Weapon THEN poItem:DamageBonus ELSE 0) + RogueRules:StrengthDamage(Fighting:EffectiveStrength(poWorld))).
        poWorld:Say(noun + " hits " + Fighting:Name(poWorld, poMonster, FALSE) + ".").
        Fighting:DamageMonster(poWorld, poMonster, damage).
        RETURN poItem:Category = ItemType:Weapon AND poItem:Kind = INTEGER(WeaponKind:Arrow) AND poWorld:Random:NextInt(3) = 0.
    END METHOD.

END CLASS.
