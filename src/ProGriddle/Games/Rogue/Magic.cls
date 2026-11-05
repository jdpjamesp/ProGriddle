/* Potions, scrolls, wands, food and traps: everything that is used up, aimed or sprung. Each of Quaff, ReadScroll, Eat and Zap gives true
   when it took a turn (a refused one does not, and says why), uses up one of the thing it is done with, and, when the hero has seen
   what it does, learns the kind (from then on it is called by its real name). A thing whose effect cannot be seen (a wand zapped at
   nothing, a scroll of hold monster with nobody near) is not learnt. What a kind does is as in the original game, in numbers a little
   softened:

     potions   confusion, hallucination, poison (strength), strength, see invisible, healing, monster and magic detection, a level,
               extra healing, haste, restored strength, blindness, levitation
     scrolls   identify, enchant armour or weapon, remove curse, monster confusion, teleport, magic mapping, sleep, hold monster,
               create monster, scare monster, food detection, aggravate monsters, protect armour
     wands     light, invisibility, lightning, fire, cold, polymorph, magic missile, haste or slow monster, drain life, nothing,
               teleport away or to, cancellation (each aimed in a direction at the first monster in the way)
     traps     a trap door, an arrow, sleeping gas, a bear trap, teleporting, a poison dart, rust, and a mystic one that just confuses

   Everything chancy goes through the world's random source. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Magic FINAL:

    /* ================================== helpers ================================== */

    /* Heals the hero by an amount; going past the most hit points raises the most by one (two for the best potion). */
    METHOD PUBLIC STATIC VOID Heal(INPUT poWorld AS RogueWorld, INPUT piPoints AS INTEGER, INPUT piRaise AS INTEGER):
        poWorld:Hero:Hp = poWorld:Hero:Hp + piPoints.
        IF poWorld:Hero:Hp > poWorld:Hero:MaxHp THEN DO:
            poWorld:Hero:MaxHp = poWorld:Hero:MaxHp + piRaise.
            poWorld:Hero:Hp = poWorld:Hero:MaxHp.
        END.
    END METHOD.

    /* A floor square picked at random that has no monster on it and is not where the hero stands. Gives false when there is none. */
    METHOD PUBLIC STATIC LOGICAL RandomFreeFloor(INPUT poWorld AS RogueWorld, OUTPUT piX AS INTEGER, OUTPUT piY AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DO y = 0 TO RogueRules:MapHeight() - 1:
            DO x = 0 TO RogueRules:MapWidth() - 1:
                IF IsFreeFloor(poWorld, x, y) THEN n = n + 1.
            END.
        END.
        IF n = 0 THEN RETURN FALSE.
        k = poWorld:Random:NextInt(n).
        n = 0.
        DO y = 0 TO RogueRules:MapHeight() - 1:
            DO x = 0 TO RogueRules:MapWidth() - 1:
                IF IsFreeFloor(poWorld, x, y) THEN DO:
                    IF n = k THEN DO:
                        piX = x.
                        piY = y.
                        RETURN TRUE.
                    END.
                    n = n + 1.
                END.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE STATIC LOGICAL IsFreeFloor(INPUT poWorld AS RogueWorld, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN poWorld:Cave:TerrainAt(piX, piY) = INTEGER(Terrain:Floor) AND poWorld:Cave:MonsterAt(piX, piY) = 0 AND NOT (piX = poWorld:Hero:X AND piY = poWorld:Hero:Y).
    END METHOD.

    /* Moves the hero to a free floor square picked at random, and out of any hold. */
    METHOD PUBLIC STATIC VOID Teleport(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        IF RandomFreeFloor(poWorld, OUTPUT x, OUTPUT y) THEN DO:
            poWorld:PlaceHero(x, y).
            poWorld:Hero:HeldBy = ?.
        END.
    END METHOD.
    /* Takes one of the thing in a slot out of the pack and gives it. */
    METHOD PRIVATE STATIC Item UseOne(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        RETURN poWorld:Pack:Take(piSlot, 1).
    END METHOD.

    /* The first monster in a direction from the hero (up to 12 squares, stopping at a wall), or unknown. */
    METHOD PUBLIC STATIC Monster FirstInLine(INPUT poWorld AS RogueWorld, INPUT piDX AS INTEGER, INPUT piDY AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        x = poWorld:Hero:X.
        y = poWorld:Hero:Y.
        DO i = 1 TO 12:
            x = x + piDX.
            y = y + piDY.
            IF poWorld:Cave:Opaque(x, y) THEN RETURN ?.
            IF VALID-OBJECT(poWorld:MonsterAtCell(x, y)) THEN RETURN poWorld:MonsterAtCell(x, y).
        END.
        RETURN ?.
    END METHOD.

    /* ================================== food ================================== */

    /* Eats one of the food in a slot: the stomach is filled by what the food gives, up to a full stomach. */
    METHOD PUBLIC STATIC LOGICAL Eat(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        DEFINE VARIABLE oFood AS Item NO-UNDO.
        IF NOT Gear:Holds(poWorld, piSlot, ItemType:Food, "That's disgusting!") THEN RETURN FALSE.
        oFood = UseOne(poWorld, piSlot).
        poWorld:Hero:Nutrition = MINIMUM(RogueRules:StomachSize(), poWorld:Hero:Nutrition + Foods:Nutrition(FoodKind:GetEnum(oFood:Kind))).
        poWorld:Say(IF oFood:Kind = INTEGER(FoodKind:Mango) THEN "My, that was a yummy mango." ELSE "Yum, that tasted good.").
        RETURN TRUE.
    END METHOD.

    /* ================================== potions ================================== */

    /* Drinks one of the potions in a slot. */
    METHOD PUBLIC STATIC LOGICAL Quaff(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        DEFINE VARIABLE oPotion AS Item    NO-UNDO.
        DEFINE VARIABLE learnt  AS LOGICAL NO-UNDO INITIAL TRUE.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE oMon    AS Monster NO-UNDO.
        DEFINE VARIABLE n       AS INTEGER NO-UNDO.
        DEFINE VARIABLE more    AS INTEGER NO-UNDO.
        IF NOT Gear:Holds(poWorld, piSlot, ItemType:Potion, "Yuk! Why would you want to drink that?") THEN RETURN FALSE.
        oPotion = UseOne(poWorld, piSlot).
        CASE PotionKind:GetEnum(oPotion:Kind):
            WHEN PotionKind:Confusion THEN DO:
                poWorld:Hero:Confused = poWorld:Hero:Confused + 8 + poWorld:Random:NextInt(8).
                poWorld:Say("Wait, what's going on here. Huh? What? Who?").
            END.
            WHEN PotionKind:Hallucination THEN DO:
                poWorld:Hero:Hallucinating = poWorld:Hero:Hallucinating + 150 + poWorld:Random:NextInt(100).
                poWorld:Say("Oh, wow! Everything seems so cosmic!").
            END.
            WHEN PotionKind:Poison THEN DO:
                IF poWorld:Pack:WearingRing(RingKind:SustainStrength) THEN poWorld:Say("You feel momentarily sick.").
                ELSE DO:
                    poWorld:Hero:Strength = MAXIMUM(3, poWorld:Hero:Strength - 1 - poWorld:Random:NextInt(3)).
                    poWorld:Say("You feel very sick now.").
                END.
            END.
            WHEN PotionKind:GainStrength THEN DO:
                poWorld:Hero:Strength = poWorld:Hero:Strength + 1.
                poWorld:Hero:MaxStrength = MAXIMUM(poWorld:Hero:MaxStrength, poWorld:Hero:Strength).
                poWorld:Say("You feel stronger. What bulging muscles!").
            END.
            WHEN PotionKind:SeeInvisible THEN DO:
                poWorld:Hero:SeesInvisible = poWorld:Hero:SeesInvisible + 150 + poWorld:Random:NextInt(100).
                poWorld:Hero:Blind = 0.
                poWorld:Say("This potion tastes like slime-mold juice.").
            END.
            WHEN PotionKind:Healing THEN DO:
                Heal(poWorld, Dice:Roll(STRING(poWorld:Hero:Rank) + "d4", poWorld:Random), 1).
                poWorld:Hero:Blind = 0.
                poWorld:Say("You begin to feel better.").
            END.
            WHEN PotionKind:MonsterDetection THEN DO:
                IF poWorld:MonsterCount > 0 THEN DO:
                    poWorld:Hero:SensesMonsters = 20.
                    poWorld:Say("You sense the presence of monsters.").
                END.
                ELSE DO:
                    poWorld:Say("You have a strange feeling for a moment, then it passes.").
                    learnt = FALSE.
                END.
            END.
            WHEN PotionKind:MagicDetection THEN DO:
                IF AnyMagicOnTheFloor(poWorld) THEN DO:
                    poWorld:Hero:SensesMagic = 20.
                    poWorld:Say("You sense the presence of magic.").
                END.
                ELSE DO:
                    poWorld:Say("You have a strange feeling for a moment, then it passes.").
                    learnt = FALSE.
                END.
            END.
            WHEN PotionKind:RaiseLevel THEN DO:
                poWorld:Say("You suddenly feel much more skillful.").
                Fighting:GainExperience(poWorld, MAXIMUM(1, RogueRules:ExperienceToPass(poWorld:Hero:Rank) - poWorld:Hero:Experience)).
            END.
            WHEN PotionKind:ExtraHealing THEN DO:
                Heal(poWorld, Dice:Roll(STRING(poWorld:Hero:Rank) + "d8", poWorld:Random), 2).
                poWorld:Hero:Blind = 0.
                poWorld:Hero:Confused = 0.
                poWorld:Hero:Hallucinating = 0.
                poWorld:Say("You begin to feel much better.").
            END.
            WHEN PotionKind:HasteSelf THEN DO:
                poWorld:Hero:Hasted = poWorld:Hero:Hasted + 12 + poWorld:Random:NextInt(10).
                poWorld:Say("You feel yourself moving much faster.").
            END.
            WHEN PotionKind:RestoreStrength THEN DO:
                poWorld:Hero:Strength = poWorld:Hero:MaxStrength.
                poWorld:Say("Hey, this tastes great. It makes you feel warm all over.").
            END.
            WHEN PotionKind:Blindness THEN DO:
                poWorld:Hero:Blind = poWorld:Hero:Blind + 100 + poWorld:Random:NextInt(50).
                poWorld:Say("A cloak of darkness falls around you.").
            END.
            WHEN PotionKind:Levitation THEN DO:
                poWorld:Hero:Levitating = poWorld:Hero:Levitating + 30 + poWorld:Random:NextInt(20).
                poWorld:Say("You float into the air!").
            END.
        END CASE.
        IF learnt THEN poWorld:Names:Learn(ItemType:Potion, oPotion:Kind).
        RETURN TRUE.
    END METHOD.

    /* True when some magic thing (a potion, scroll, wand, ring or enchanted weapon or armour) lies on the floor. */
    METHOD PUBLIC STATIC LOGICAL AnyMagicOnTheFloor(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = 0 TO RogueRules:MapHeight() - 1:
            DO x = 0 TO RogueRules:MapWidth() - 1:
                IF IsMagic(poWorld:FloorItemAt(x, y)) THEN RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* True for a potion, scroll, wand or ring, and for a weapon or armour with a plus or a minus. */
    METHOD PUBLIC STATIC LOGICAL IsMagic(INPUT poItem AS Item):
        IF NOT VALID-OBJECT(poItem) THEN RETURN FALSE.
        CASE poItem:Category:
            WHEN ItemType:Potion OR WHEN ItemType:Scroll OR WHEN ItemType:Wand OR WHEN ItemType:Ring THEN RETURN TRUE.
            WHEN ItemType:Weapon OR WHEN ItemType:Armour THEN RETURN poItem:Bonus <> 0 OR poItem:DamageBonus <> 0.
            OTHERWISE RETURN FALSE.
        END CASE.
    END METHOD.

    /* ================================== scrolls ================================== */

    /* Reads one of the scrolls in a slot. plPick is true when it was a scroll of identify and the game should now ask which thing to
       identify (IdentifyItem does it). */
    METHOD PUBLIC STATIC LOGICAL ReadScroll(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER, OUTPUT plPick AS LOGICAL):
        DEFINE VARIABLE oScroll AS Item    NO-UNDO.
        DEFINE VARIABLE oArmour AS Item    NO-UNDO.
        DEFINE VARIABLE oWeapon AS Item    NO-UNDO.
        DEFINE VARIABLE learnt  AS LOGICAL NO-UNDO INITIAL TRUE.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE n       AS INTEGER NO-UNDO.
        DEFINE VARIABLE oMon    AS Monster NO-UNDO.
        plPick = FALSE.
        IF NOT Gear:Holds(poWorld, piSlot, ItemType:Scroll, "There is nothing on it to read.") THEN RETURN FALSE.
        oScroll = UseOne(poWorld, piSlot).
        CASE ScrollKind:GetEnum(oScroll:Kind):
            WHEN ScrollKind:Identify THEN DO:
                poWorld:Say("This scroll is an identify scroll.").
                plPick = poWorld:Pack:Count > 0.
            END.
            WHEN ScrollKind:EnchantArmour THEN DO:
                oArmour = poWorld:Pack:Worn().
                IF VALID-OBJECT(oArmour) THEN DO:
                    oArmour:Bonus = oArmour:Bonus + 1.
                    oArmour:Cursed = FALSE.
                    oArmour:Known = TRUE.
                    poWorld:Say("Your armor glows silver for a moment.").
                END.
                ELSE DO:
                    poWorld:Say("You feel a strange sense of loss.").
                    learnt = FALSE.
                END.
            END.
            WHEN ScrollKind:EnchantWeapon THEN DO:
                oWeapon = poWorld:Pack:Weapon().
                IF VALID-OBJECT(oWeapon) THEN DO:
                    IF poWorld:Random:NextInt(2) = 0 THEN oWeapon:Bonus = oWeapon:Bonus + 1.
                    ELSE oWeapon:DamageBonus = oWeapon:DamageBonus + 1.
                    oWeapon:Cursed = FALSE.
                    oWeapon:Known = TRUE.
                    poWorld:Say("Your " + Weapons:NameOf(WeaponKind:GetEnum(oWeapon:Kind)) + " glows blue for a moment.").
                END.
                ELSE DO:
                    poWorld:Say("You feel a strange sense of loss.").
                    learnt = FALSE.
                END.
            END.
            WHEN ScrollKind:RemoveCurse THEN DO:
                DO i = 0 TO RogueRules:PackSize() - 1:
                    IF poWorld:Pack:Holds(i) THEN poWorld:Pack:At(i):Cursed = FALSE.
                END.
                poWorld:Say("You feel as if somebody is watching over you.").
            END.
            WHEN ScrollKind:MonsterConfusion THEN DO:
                poWorld:Hero:ConfusingTouch = TRUE.
                poWorld:Say("Your hands begin to glow red.").
            END.
            WHEN ScrollKind:Teleportation THEN Teleport(poWorld).
            WHEN ScrollKind:MagicMapping THEN DO:
                MapTheLevel(poWorld).
                poWorld:Say("Oh, now this scroll has a map on it.").
            END.
            WHEN ScrollKind:SleepSpell THEN DO:
                poWorld:Hero:Asleep = poWorld:Hero:Asleep + 4 + poWorld:Random:NextInt(4).
                poWorld:Say("You fall asleep.").
            END.
            WHEN ScrollKind:HoldMonster THEN DO:
                n = 0.
                DO i = 0 TO RogueRules:MostMonsters() - 1:
                    oMon = poWorld:MonsterInSlot(i).
                    IF VALID-OBJECT(oMon) AND RogueWorld:Distance(oMon:X, oMon:Y, poWorld:Hero:X, poWorld:Hero:Y) <= 2 THEN DO:
                        oMon:Held = 12 + poWorld:Random:NextInt(8).
                        n = n + 1.
                    END.
                END.
                IF n > 0 THEN poWorld:Say("The monsters around you freeze.").
                ELSE DO:
                    poWorld:Say("You feel a strange sense of loss.").
                    learnt = FALSE.
                END.
            END.
            WHEN ScrollKind:CreateMonster THEN DO:
                IF MakeMonsterNear(poWorld) THEN poWorld:Say("You hear a noise.").
                ELSE DO:
                    poWorld:Say("You hear a faint cry of anguish in the distance.").
                    learnt = FALSE.
                END.
            END.
            WHEN ScrollKind:ScareMonster THEN DO:
                DO i = 0 TO RogueRules:MostMonsters() - 1:
                    oMon = poWorld:MonsterInSlot(i).
                    IF VALID-OBJECT(oMon) AND poWorld:Cave:InView(oMon:X, oMon:Y) THEN oMon:Held = 12 + poWorld:Random:NextInt(8).
                END.
                poWorld:Say("You hear maniacal laughter in the distance.").
            END.
            WHEN ScrollKind:FoodDetection THEN DO:
                IF AnyFoodOnTheFloor(poWorld) THEN DO:
                    poWorld:Hero:SensesFood = 20.
                    poWorld:Say("Your nose tingles and you smell food.").
                END.
                ELSE DO:
                    poWorld:Say("Your nose tingles.").
                    learnt = FALSE.
                END.
            END.
            WHEN ScrollKind:Aggravate THEN DO:
                DO i = 0 TO RogueRules:MostMonsters() - 1:
                    oMon = poWorld:MonsterInSlot(i).
                    IF VALID-OBJECT(oMon) THEN oMon:Awake = TRUE.
                END.
                poWorld:Say("You hear a high pitched humming noise.").
            END.
            WHEN ScrollKind:ProtectArmour THEN DO:
                oArmour = poWorld:Pack:Worn().
                IF VALID-OBJECT(oArmour) THEN DO:
                    oArmour:Warded = TRUE.
                    poWorld:Say("A protective golden glow surrounds your armor.").
                END.
                ELSE DO:
                    poWorld:Say("You feel a strange sense of loss.").
                    learnt = FALSE.
                END.
            END.
        END CASE.
        IF learnt THEN poWorld:Names:Learn(ItemType:Scroll, oScroll:Kind).
        RETURN TRUE.
    END METHOD.

    /* The scroll of identify at work: the thing in a slot is known for what it is, and so is its kind. */
    METHOD PUBLIC STATIC VOID IdentifyItem(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER):
        DEFINE VARIABLE oItem AS Item NO-UNDO.
        IF piSlot < 0 OR piSlot >= RogueRules:PackSize() OR NOT poWorld:Pack:Holds(piSlot) THEN DO:
            poWorld:Say("You have nothing like that.").
            RETURN.
        END.
        oItem = poWorld:Pack:At(piSlot).
        oItem:Known = TRUE.
        IF Disguises:Kinds(oItem:Category) > 0 THEN poWorld:Names:Learn(oItem:Category, oItem:Kind).
        poWorld:Say(Gear:Line(poWorld, piSlot) + ".").
    END METHOD.

    /* Shows the shape of the whole level, secret doors as doors. */
    METHOD PUBLIC STATIC VOID MapTheLevel(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = 0 TO RogueRules:MapHeight() - 1:
            DO x = 0 TO RogueRules:MapWidth() - 1:
                IF poWorld:Cave:IsSecret(x, y) THEN poWorld:Cave:SetTerrain(x, y, Terrain:Door).
                IF poWorld:Cave:TerrainAt(x, y) <> INTEGER(Terrain:Rock) THEN poWorld:Cave:SetSeen(x, y, TRUE).
            END.
        END.
    END METHOD.

    /* True when some food lies on the floor. */
    METHOD PUBLIC STATIC LOGICAL AnyFoodOnTheFloor(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE oItem AS Item    NO-UNDO.
        DO y = 0 TO RogueRules:MapHeight() - 1:
            DO x = 0 TO RogueRules:MapWidth() - 1:
                oItem = poWorld:FloorItemAt(x, y).
                IF VALID-OBJECT(oItem) AND oItem:Category = ItemType:Food THEN RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* Puts a new monster of the level's kind on a free square next to the hero. Gives false when there is no square. */
    METHOD PUBLIC STATIC LOGICAL MakeMonsterNear(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE dx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE start AS INTEGER NO-UNDO.
        DEFINE VARIABLE k     AS INTEGER NO-UNDO.
        DEFINE VARIABLE d     AS INTEGER NO-UNDO.
        DEFINE VARIABLE oMon  AS Monster NO-UNDO.
        start = poWorld:Random:NextInt(8).
        DO k = 0 TO 7:
            d = (start + k) MODULO 8.
            dx = INTEGER(ENTRY(d + 1, "-1,0,1,-1,1,-1,0,1")).
            dy = INTEGER(ENTRY(d + 1, "-1,-1,-1,0,0,1,1,1")).
            IF poWorld:Cave:Walkable(poWorld:Hero:X + dx, poWorld:Hero:Y + dy) AND poWorld:Cave:MonsterAt(poWorld:Hero:X + dx, poWorld:Hero:Y + dy) = 0 THEN DO:
                oMon = poWorld:AddMonster(Bestiary:ForDepth(poWorld:Depth, poWorld:Random), poWorld:Hero:X + dx, poWorld:Hero:Y + dy).
                oMon:Awake = TRUE.
                RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* ================================== wands ================================== */

    /* Zaps a wand in a direction. A wand with no charges left does nothing. */
    METHOD PUBLIC STATIC LOGICAL Zap(INPUT poWorld AS RogueWorld, INPUT piSlot AS INTEGER, INPUT piDX AS INTEGER, INPUT piDY AS INTEGER):
        DEFINE VARIABLE oWand   AS Item    NO-UNDO.
        DEFINE VARIABLE oTarget AS Monster NO-UNDO.
        DEFINE VARIABLE learnt  AS LOGICAL NO-UNDO.
        IF NOT Gear:Holds(poWorld, piSlot, ItemType:Wand, "You can't zap with that.") THEN RETURN FALSE.
        oWand = poWorld:Pack:At(piSlot).
        IF oWand:Charges <= 0 THEN DO:
            poWorld:Say("Nothing happens.").
            RETURN TRUE.
        END.
        oWand:Charges = oWand:Charges - 1.
        oTarget = FirstInLine(poWorld, piDX, piDY).
        CASE WandKind:GetEnum(oWand:Kind):
            WHEN WandKind:Light THEN DO:
                IF poWorld:Cave:RoomAt(poWorld:Hero:X, poWorld:Hero:Y) > 0 THEN DO:
                    poWorld:SetRoomLit(poWorld:Cave:RoomAt(poWorld:Hero:X, poWorld:Hero:Y), TRUE).
                    poWorld:Say("The room is lit by a shimmering blue light.").
                    learnt = TRUE.
                END.
                ELSE poWorld:Say("The corridor glows and then fades.").
            END.
            WHEN WandKind:Nothing THEN poWorld:Say("Nothing happens.").
            WHEN WandKind:DrainLife THEN learnt = DrainLife(poWorld).
            OTHERWISE DO:
                IF VALID-OBJECT(oTarget) THEN learnt = ZapMonster(poWorld, WandKind:GetEnum(oWand:Kind), oTarget).
                ELSE poWorld:Say("The bolt hits nothing.").
            END.
        END CASE.
        IF learnt THEN poWorld:Names:Learn(ItemType:Wand, oWand:Kind).
        RETURN TRUE.
    END METHOD.

    /* What a wand does to the monster it hits. Gives true when the hero has seen what it was. */
    METHOD PRIVATE STATIC LOGICAL ZapMonster(INPUT poWorld AS RogueWorld, INPUT poKind AS WandKind, INPUT poMonster AS Monster):
        DEFINE VARIABLE name AS CHARACTER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE kind AS INTEGER   NO-UNDO.
        DEFINE VARIABLE oNew AS Monster   NO-UNDO.
        name = Fighting:Name(poWorld, poMonster, FALSE).
        poMonster:Awake = TRUE.
        CASE poKind:
            WHEN WandKind:Invisibility THEN DO:
                poMonster:Invisible = TRUE.
                poWorld:Say("The " + Bestiary:NameOf(poMonster:Kind) + " vanishes!").
                RETURN TRUE.
            END.
            WHEN WandKind:Lightning OR WHEN WandKind:Fire OR WHEN WandKind:Cold THEN DO:
                poWorld:Say("The " + (IF poKind = WandKind:Lightning THEN "bolt of lightning" ELSE IF poKind = WandKind:Fire THEN "flame" ELSE "frost") + " hits " + name + ".").
                Fighting:DamageMonster(poWorld, poMonster, Dice:Roll("6d6", poWorld:Random)).
                RETURN TRUE.
            END.
            WHEN WandKind:MagicMissile THEN DO:
                poWorld:Say("The missile hits " + name + ".").
                Fighting:DamageMonster(poWorld, poMonster, Dice:Roll("3d4", poWorld:Random)).
                RETURN TRUE.
            END.
            WHEN WandKind:Polymorph THEN DO:
                x = poMonster:X.
                y = poMonster:Y.
                kind = poWorld:Random:NextInt(25).
                IF kind >= INTEGER(poMonster:Kind) THEN kind = kind + 1.
                poWorld:RemoveMonster(poMonster).
                oNew = poWorld:AddMonster(MonsterKind:GetEnum(kind), x, y).
                oNew:Awake = TRUE.
                poWorld:Say(name + " turns into " + Fighting:Name(poWorld, oNew, FALSE) + "!").
                RETURN TRUE.
            END.
            WHEN WandKind:HasteMonster THEN DO:
                poMonster:Hasted = poMonster:Hasted + 20.
                poWorld:Say(name + " speeds up.").
                RETURN TRUE.
            END.
            WHEN WandKind:SlowMonster THEN DO:
                poMonster:Slowed = poMonster:Slowed + 20.
                poWorld:Say(name + " slows down.").
                RETURN TRUE.
            END.
            WHEN WandKind:TeleportAway THEN DO:
                IF RandomFreeFloor(poWorld, OUTPUT x, OUTPUT y) THEN poWorld:MoveMonster(poMonster, x, y).
                poWorld:Say(name + " disappears.").
                RETURN TRUE.
            END.
            WHEN WandKind:TeleportTo THEN DO:
                poWorld:Say(name + " is pulled to you.").
                PullNextToHero(poWorld, poMonster).
                RETURN TRUE.
            END.
            WHEN WandKind:Cancellation THEN DO:
                poMonster:Cancelled = TRUE.
                poMonster:Invisible = FALSE.
                poWorld:Say(name + " is cancelled.").
                RETURN TRUE.
            END.
        END CASE.
        RETURN FALSE.
    END METHOD.

    /* Moves a monster to a free square next to the hero if there is one. */
    METHOD PRIVATE STATIC VOID PullNextToHero(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        DEFINE VARIABLE dx AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy AS INTEGER NO-UNDO.
        DO dy = -1 TO 1:
            DO dx = -1 TO 1:
                IF (dx <> 0 OR dy <> 0) AND poWorld:Cave:Walkable(poWorld:Hero:X + dx, poWorld:Hero:Y + dy) AND poWorld:Cave:MonsterAt(poWorld:Hero:X + dx, poWorld:Hero:Y + dy) = 0 THEN DO:
                    poWorld:MoveMonster(poMonster, poWorld:Hero:X + dx, poWorld:Hero:Y + dy).
                    RETURN.
                END.
            END.
        END.
    END METHOD.

    /* The wand of drain life: the hero loses half the hit points they have, and every monster in sight loses as many. */
    METHOD PRIVATE STATIC LOGICAL DrainLife(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE cost AS INTEGER NO-UNDO.
        DEFINE VARIABLE i    AS INTEGER NO-UNDO.
        DEFINE VARIABLE oMon AS Monster NO-UNDO.
        IF poWorld:Hero:Hp < 2 THEN DO:
            poWorld:Say("You are too weak to use it.").
            RETURN FALSE.
        END.
        cost = INTEGER(TRUNCATE(poWorld:Hero:Hp / 2, 0)).
        poWorld:Hero:Hp = poWorld:Hero:Hp - cost.
        poWorld:Say("You feel an intense pain.").
        DO i = 0 TO RogueRules:MostMonsters() - 1:
            oMon = poWorld:MonsterInSlot(i).
            IF VALID-OBJECT(oMon) AND poWorld:Cave:InView(oMon:X, oMon:Y) THEN Fighting:DamageMonster(poWorld, oMon, cost).
        END.
        RETURN TRUE.
    END METHOD.

    /* ================================== traps ================================== */

    /* The hero steps on a trap: it is found, and does what it does. Gives true when the hero has fallen through a trap door (the game
       then takes the hero down a level). */
    METHOD PUBLIC STATIC LOGICAL SpringTrap(INPUT poWorld AS RogueWorld, INPUT poKind AS TrapKind):
        DEFINE VARIABLE oWorn AS Item NO-UNDO.
        poWorld:Cave:SetTrapFound(poWorld:Hero:X, poWorld:Hero:Y, TRUE).
        CASE poKind:
            WHEN TrapKind:TrapDoor THEN DO:
                poWorld:Say("You fall through a trap door!").
                RETURN TRUE.
            END.
            WHEN TrapKind:Arrow THEN DO:
                IF Fighting:Swing(poWorld, poWorld:Depth, Fighting:ArmourClass(poWorld), 0) THEN DO:
                    poWorld:Say("An arrow shoots out and hits you.").
                    Fighting:Hurt(poWorld, Dice:Roll("1d6", poWorld:Random), "an arrow").
                END.
                ELSE poWorld:Say("An arrow shoots past you.").
            END.
            WHEN TrapKind:SleepingGas THEN DO:
                poWorld:Say("A sleeping gas fills the air. You fall asleep.").
                poWorld:Hero:Asleep = poWorld:Hero:Asleep + 4 + poWorld:Random:NextInt(3).
            END.
            WHEN TrapKind:BearTrap THEN DO:
                poWorld:Say("You are caught in a bear trap.").
                poWorld:Hero:Stuck = 3 + poWorld:Random:NextInt(3).
            END.
            WHEN TrapKind:Teleport THEN DO:
                poWorld:Say("You feel yourself being drawn away.").
                Teleport(poWorld).
            END.
            WHEN TrapKind:PoisonDart THEN DO:
                IF Fighting:Swing(poWorld, poWorld:Depth, Fighting:ArmourClass(poWorld), 0) THEN DO:
                    poWorld:Say("A small dart just hit you in the shoulder.").
                    Fighting:Hurt(poWorld, Dice:Roll("1d4", poWorld:Random), "a poison dart").
                    IF NOT poWorld:Dead AND NOT poWorld:Pack:WearingRing(RingKind:SustainStrength) AND poWorld:Hero:Strength > 3 THEN DO:
                        poWorld:Hero:Strength = poWorld:Hero:Strength - 1.
                        poWorld:Say("You feel weaker.").
                    END.
                END.
                ELSE poWorld:Say("A small dart whizzes by your ear and vanishes.").
            END.
            WHEN TrapKind:Rust THEN DO:
                poWorld:Say("A gush of water hits you on the head.").
                oWorn = poWorld:Pack:Worn().
                IF VALID-OBJECT(oWorn) AND NOT oWorn:Warded AND NOT poWorld:Pack:WearingRing(RingKind:MaintainArmour) THEN DO:
                    oWorn:Bonus = oWorn:Bonus - 1.
                    poWorld:Say("Your armor weakens.").
                END.
            END.
            WHEN TrapKind:Mystic THEN DO:
                poWorld:Say("You are suddenly in a parallel dimension.").
                poWorld:Hero:Confused = poWorld:Hero:Confused + 3.
            END.
        END CASE.
        RETURN FALSE.
    END METHOD.

END CLASS.
