/* The rules of a fight. A blow lands when a twenty sided die, plus the attacker's bonus, reaches (20 minus the attacker's level minus the
   armour class of the one hit): the lower the armour class, the harder to hit. The hero's level is the experience level, a monster's its
   level in the Bestiary; the hero's bonus is the weapon's plus, strength and a ring of dexterity, and a sleeping or held monster is
   easier to hit. A monster has one blow for each set of dice in its damage list, and the specials of the odd ones (rust, freezing,
   stealing, draining, holding, confusing) happen when a blow hits and the monster has not been cancelled.

   Killing a monster gives the hero its experience (and the next level when there is enough), and drops what it carried and the gold it
   stole. When the hero's hit points run out the world is marked Dead and the cause is kept (for example "a bat"). Everything is said
   to the hero through the world's messages. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Fighting FINAL:

    /* The hero's strength with the rings of strength worn. */
    METHOD PUBLIC STATIC INTEGER EffectiveStrength(INPUT poWorld AS RogueWorld):
        RETURN poWorld:Hero:Strength + poWorld:Pack:RingBonus(RingKind:AddStrength).
    END METHOD.

    /* The hero's armour class: 10 for a hero in nothing, less the class of the armour worn (less its enchantment) and less a ring of
       protection. Lower is better, and it can go below 0. */
    METHOD PUBLIC STATIC INTEGER ArmourClass(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE oWorn AS Item    NO-UNDO.
        DEFINE VARIABLE ac    AS INTEGER NO-UNDO.
        ac = 10.
        oWorn = poWorld:Pack:Worn().
        IF VALID-OBJECT(oWorn) THEN ac = Armours:ArmourClass(ArmourKind:GetEnum(oWorn:Kind)) - oWorn:Bonus.
        RETURN ac - poWorld:Pack:RingBonus(RingKind:Protection).
    END METHOD.

    /* True when a blow lands: a roll of 1 to 20 plus the bonus reaches 20 minus the attacker's level minus the armour class of the target. */
    METHOD PUBLIC STATIC LOGICAL Swing(INPUT poWorld AS RogueWorld, INPUT piLevel AS INTEGER, INPUT piArmour AS INTEGER, INPUT piBonus AS INTEGER):
        RETURN poWorld:Random:NextInt(20) + 1 + piBonus >= (20 - piLevel) - piArmour.
    END METHOD.

    /* A monster as a phrase for a message: "the bat", "The bat", or "something" when the hero cannot see it (blind, or it is invisible). */
    METHOD PUBLIC STATIC CHARACTER Name(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster, INPUT plCapital AS LOGICAL):
        IF poWorld:Hero:Blind > 0 OR (poMonster:Invisible AND NOT Sight:SeesInvisible(poWorld)) THEN RETURN (IF plCapital THEN "Something" ELSE "something").
        RETURN Bestiary:Phrase(poMonster:Kind, plCapital).
    END METHOD.

    /* The damage the hero's hand does: the dice of the wielded weapon, or 1d4 with bare hands. */
    METHOD PUBLIC STATIC CHARACTER HandDice(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE oWeapon AS Item NO-UNDO.
        oWeapon = poWorld:Pack:Weapon().
        RETURN (IF VALID-OBJECT(oWeapon) THEN Weapons:Swing(WeaponKind:GetEnum(oWeapon:Kind)) ELSE "1d4").
    END METHOD.

    /* The bonus to hit of the hero's hand: the weapon's plus, strength and a ring of dexterity. */
    METHOD PUBLIC STATIC INTEGER HitBonus(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE oWeapon AS Item NO-UNDO.
        oWeapon = poWorld:Pack:Weapon().
        RETURN (IF VALID-OBJECT(oWeapon) THEN oWeapon:Bonus ELSE 0) + RogueRules:StrengthHit(EffectiveStrength(poWorld)) + poWorld:Pack:RingBonus(RingKind:Dexterity).
    END METHOD.

    /* The bonus to damage of the hero's hand: the weapon's plus, strength and a ring of increase damage. */
    METHOD PUBLIC STATIC INTEGER DamageBonus(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE oWeapon AS Item NO-UNDO.
        oWeapon = poWorld:Pack:Weapon().
        RETURN (IF VALID-OBJECT(oWeapon) THEN oWeapon:DamageBonus ELSE 0) + RogueRules:StrengthDamage(EffectiveStrength(poWorld)) + poWorld:Pack:RingBonus(RingKind:IncreaseDamage).
    END METHOD.

    /* ================================ the hero strikes ================================ */

    /* The hero swings at a monster. It wakes, whether it was hit or not. */
    METHOD PUBLIC STATIC VOID HeroAttack(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        DEFINE VARIABLE bonus  AS INTEGER NO-UNDO.
        DEFINE VARIABLE damage AS INTEGER NO-UNDO.
        bonus = HitBonus(poWorld) + (IF NOT poMonster:Awake OR poMonster:Held > 0 THEN 4 ELSE 0).
        poMonster:Awake = TRUE.
        IF Swing(poWorld, poWorld:Hero:Rank, Bestiary:ArmourClass(poMonster:Kind), bonus) THEN DO:
            damage = MAXIMUM(1, Dice:Roll(HandDice(poWorld), poWorld:Random) + DamageBonus(poWorld)).
            poWorld:Say("You hit " + Name(poWorld, poMonster, FALSE) + ".").
            IF poWorld:Hero:ConfusingTouch THEN DO:
                poMonster:Confused = 10 + poWorld:Random:NextInt(10).
                poWorld:Hero:ConfusingTouch = FALSE.
                poWorld:Say("Your hands stop glowing red.").
            END.
            DamageMonster(poWorld, poMonster, damage).
        END.
        ELSE poWorld:Say("You miss " + Name(poWorld, poMonster, FALSE) + ".").
    END METHOD.

    /* Hurts a monster by an amount that has been rolled. A monster that is hurt wakes and a monster at 0 hit points dies. Gives true when
       it died. */
    METHOD PUBLIC STATIC LOGICAL DamageMonster(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster, INPUT piDamage AS INTEGER):
        poMonster:Hp = poMonster:Hp - piDamage.
        poMonster:Awake = TRUE.
        IF poMonster:Hp <= 0 THEN DO:
            Kill(poWorld, poMonster).
            RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* A monster dies: the hero is told, gets the experience and the monster drops what it carried and the gold it took. */
    METHOD PUBLIC STATIC VOID Kill(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        DEFINE VARIABLE oGold AS Item NO-UNDO.
        poWorld:Say("You killed " + Name(poWorld, poMonster, FALSE) + ".").
        IF VALID-OBJECT(poMonster:Carried) THEN poWorld:DropOnFloor(poMonster:Carried, poMonster:X, poMonster:Y).
        IF poMonster:Gold > 0 THEN DO:
            oGold = NEW Item(ItemType:Gold, 0).
            oGold:Count = poMonster:Gold.
            poWorld:DropOnFloor(oGold, poMonster:X, poMonster:Y).
        END.
        poWorld:RemoveMonster(poMonster).
        GainExperience(poWorld, Bestiary:Experience(poMonster:Kind)).
    END METHOD.

    /* Adds experience points, and moves the hero up a level (more hit points, a welcome) for each level they now reach. */
    METHOD PUBLIC STATIC VOID GainExperience(INPUT poWorld AS RogueWorld, INPUT piPoints AS INTEGER):
        DEFINE VARIABLE more AS INTEGER NO-UNDO.
        poWorld:Hero:Experience = poWorld:Hero:Experience + piPoints.
        DO WHILE poWorld:Hero:Rank < RogueRules:HighestRank() AND poWorld:Hero:Experience >= RogueRules:ExperienceToPass(poWorld:Hero:Rank):
            poWorld:Hero:Rank = poWorld:Hero:Rank + 1.
            more = poWorld:Random:NextInt(10) + 1.
            poWorld:Hero:MaxHp = poWorld:Hero:MaxHp + more.
            poWorld:Hero:Hp = poWorld:Hero:Hp + more.
            poWorld:Say("Welcome to level " + STRING(poWorld:Hero:Rank) + "!").
        END.
    END METHOD.

    /* The hero loses a level (a wraith's touch): fewer hit points and the experience of the level below. A hero of the first level dies. */
    METHOD PUBLIC STATIC VOID LoseLevel(INPUT poWorld AS RogueWorld, INPUT pcCause AS CHARACTER):
        DEFINE VARIABLE less AS INTEGER NO-UNDO.
        IF poWorld:Hero:Rank <= 1 THEN DO:
            Die(poWorld, pcCause).
            RETURN.
        END.
        poWorld:Hero:Rank = poWorld:Hero:Rank - 1.
        poWorld:Hero:Experience = (IF poWorld:Hero:Rank > 1 THEN RogueRules:ExperienceToPass(poWorld:Hero:Rank - 1) ELSE 0).
        less = poWorld:Random:NextInt(10) + 1.
        poWorld:Hero:MaxHp = MAXIMUM(1, poWorld:Hero:MaxHp - less).
        poWorld:Hero:Hp = MINIMUM(poWorld:Hero:Hp, poWorld:Hero:MaxHp).
        poWorld:Say("You feel your life force draining away.").
    END METHOD.

    /* ============================== the monster strikes ============================== */

    /* A monster attacks the hero: one blow for each set of dice in its damage list, stopping when the hero is dead. */
    METHOD PUBLIC STATIC VOID MonsterAttack(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        DEFINE VARIABLE list   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE damage AS INTEGER   NO-UNDO.
        DEFINE VARIABLE bonus  AS INTEGER   NO-UNDO.
        list = Bestiary:Damage(poMonster:Kind).
        bonus = (IF poWorld:Hero:Asleep > 0 OR poWorld:Hero:Stuck > 0 THEN 4 ELSE 0).
        DO i = 1 TO Dice:Attacks(list):
            IF poWorld:Dead THEN LEAVE.
            IF Swing(poWorld, Bestiary:Level(poMonster:Kind), ArmourClass(poWorld), bonus) THEN DO:
                damage = Dice:Roll(Dice:Attack(list, i), poWorld:Random).
                poWorld:Say(Name(poWorld, poMonster, TRUE) + " " + Bestiary:Verb(poMonster:Kind) + " you.").
                IF damage > 0 THEN Hurt(poWorld, damage, Bestiary:WithArticle(poMonster:Kind)).
                IF NOT poWorld:Dead AND NOT poMonster:Cancelled THEN Special(poWorld, poMonster).
                /* a monster that has stolen from the hero has gone */
                IF NOT VALID-OBJECT(poWorld:MonsterAtCell(poMonster:X, poMonster:Y)) OR poWorld:MonsterAtCell(poMonster:X, poMonster:Y) <> poMonster THEN LEAVE.
            END.
            ELSE poWorld:Say(Name(poWorld, poMonster, TRUE) + " misses you.").
        END.
    END METHOD.

    /* The hero takes damage; at 0 hit points or fewer the hero dies of pcCause ("a bat"). */
    METHOD PUBLIC STATIC VOID Hurt(INPUT poWorld AS RogueWorld, INPUT piDamage AS INTEGER, INPUT pcCause AS CHARACTER):
        poWorld:Hero:Hp = poWorld:Hero:Hp - piDamage.
        IF poWorld:Hero:Hp <= 0 THEN Die(poWorld, pcCause).
    END METHOD.

    /* The hero dies. */
    METHOD PUBLIC STATIC VOID Die(INPUT poWorld AS RogueWorld, INPUT pcCause AS CHARACTER):
        IF poWorld:Dead THEN RETURN.
        poWorld:Hero:Hp = MINIMUM(poWorld:Hero:Hp, 0).
        poWorld:Dead = TRUE.
        poWorld:Cause = pcCause.
        poWorld:Say("You die...").
    END METHOD.

    /* What a hit of a special monster does besides its damage. */
    METHOD PRIVATE STATIC VOID Special(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        DEFINE VARIABLE oWorn  AS Item    NO-UNDO.
        DEFINE VARIABLE oStolen AS Item   NO-UNDO.
        DEFINE VARIABLE slot   AS INTEGER NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE pick   AS INTEGER NO-UNDO.
        DEFINE VARIABLE took   AS INTEGER NO-UNDO.
        CASE poMonster:Kind:
            WHEN MonsterKind:Aquator THEN DO:
                oWorn = poWorld:Pack:Worn().
                IF VALID-OBJECT(oWorn) AND NOT oWorn:Warded AND NOT poWorld:Pack:WearingRing(RingKind:MaintainArmour) THEN DO:
                    oWorn:Bonus = oWorn:Bonus - 1.
                    poWorld:Say("Your armor weakens.").
                END.
            END.
            WHEN MonsterKind:IceMonster THEN DO:
                IF poWorld:Hero:Asleep = 0 THEN DO:
                    poWorld:Hero:Asleep = 2 + poWorld:Random:NextInt(3).
                    poWorld:Say("You are frozen by the ice monster!").
                END.
            END.
            WHEN MonsterKind:VenusFlytrap THEN DO:
                IF NOT VALID-OBJECT(poWorld:Hero:HeldBy) OR poWorld:Hero:HeldBy <> poMonster THEN DO:
                    poWorld:Say("You are being held.").
                    poWorld:Hero:HeldBy = poMonster.
                    poMonster:Grip = 0.
                END.
                poMonster:Grip = poMonster:Grip + 1.
                Hurt(poWorld, poMonster:Grip, "a venus flytrap").
            END.
            WHEN MonsterKind:Rattlesnake THEN DO:
                IF NOT poWorld:Pack:WearingRing(RingKind:SustainStrength) AND poWorld:Hero:Strength > 3 THEN DO:
                    poWorld:Hero:Strength = poWorld:Hero:Strength - 1.
                    poWorld:Say("You feel weaker.").
                END.
            END.
            WHEN MonsterKind:Vampire THEN DO:
                IF poWorld:Hero:MaxHp > 1 THEN DO:
                    poWorld:Hero:MaxHp = poWorld:Hero:MaxHp - 1 - poWorld:Random:NextInt(2).
                    IF poWorld:Hero:MaxHp < 1 THEN poWorld:Hero:MaxHp = 1.
                    poWorld:Hero:Hp = MINIMUM(poWorld:Hero:Hp, poWorld:Hero:MaxHp).
                    poWorld:Say("You feel your life draining away.").
                END.
            END.
            WHEN MonsterKind:Wraith THEN LoseLevel(poWorld, "a wraith").
            WHEN MonsterKind:Medusa THEN DO:
                poWorld:Hero:Confused = poWorld:Hero:Confused + 6 + poWorld:Random:NextInt(4).
                poWorld:Say("The medusa's gaze confuses you.").
            END.
            WHEN MonsterKind:Leprechaun THEN DO:
                IF poWorld:Hero:Gold > 0 THEN DO:
                    took = MINIMUM(poWorld:Hero:Gold, poWorld:Random:NextInt(50 + 10 * poWorld:Depth) + 1).
                    poWorld:Hero:Gold = poWorld:Hero:Gold - took.
                    poWorld:Say("Your purse feels lighter.").
                    poWorld:RemoveMonster(poMonster).
                END.
            END.
            WHEN MonsterKind:Nymph THEN DO:
                /* anything in the pack that is not being worn or wielded */
                DO i = 0 TO RogueRules:PackSize() - 1:
                    IF poWorld:Pack:Holds(i) AND NOT poWorld:Pack:InUse(i) THEN n = n + 1.
                END.
                IF n > 0 THEN DO:
                    pick = poWorld:Random:NextInt(n).
                    n = 0.
                    DO i = 0 TO RogueRules:PackSize() - 1:
                        IF poWorld:Pack:Holds(i) AND NOT poWorld:Pack:InUse(i) THEN DO:
                            IF n = pick THEN slot = i.
                            n = n + 1.
                        END.
                    END.
                    oStolen = poWorld:Pack:Take(slot, poWorld:Pack:At(slot):Count).
                    poWorld:Say("She stole " + ItemText:Describe(oStolen, poWorld:Names) + "!").
                    poWorld:RemoveMonster(poMonster).
                END.
            END.
        END CASE.
    END METHOD.

END CLASS.
