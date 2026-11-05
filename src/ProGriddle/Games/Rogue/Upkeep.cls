/* What happens to the hero as turns go by, whatever the hero does: the stomach empties (a ring of slow digestion halves it), hunger is
   told at each stage (hungry under 300, weak under 150, faint under 50, and starving to death at 0, with a chance to faint when faint),
   hit points come back (one every 22 minus twice the experience level turns, to a minimum of 8 at the seventh level and one every 3 turns
   after, twice as fast with a ring of regeneration), the timers of confusion, blindness, levitation, seeing invisible, the detections
   and hallucination run down (with a word when one ends), a ring of searching searches, and a ring of teleportation now and then moves
   the hero. One call is one turn. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Upkeep FINAL:

    /* The stage of hunger of a stomach: 0 for satisfied, 1 hungry, 2 weak, 3 faint and 4 starved. */
    METHOD PUBLIC STATIC INTEGER StageOf(INPUT piNutrition AS INTEGER):
        IF piNutrition <= 0 THEN RETURN 4.
        IF piNutrition < RogueRules:FaintBelow() THEN RETURN 3.
        IF piNutrition < RogueRules:WeakBelow() THEN RETURN 2.
        IF piNutrition < RogueRules:HungryBelow() THEN RETURN 1.
        RETURN 0.
    END METHOD.

    /* The number of turns between one hit point coming back and the next, for an experience level. */
    METHOD PUBLIC STATIC INTEGER HealEvery(INPUT piRank AS INTEGER, INPUT plRegeneration AS LOGICAL):
        DEFINE VARIABLE period AS INTEGER NO-UNDO.
        period = (IF piRank < 8 THEN 22 - 2 * piRank ELSE 3).
        RETURN (IF plRegeneration THEN MAXIMUM(1, INTEGER(TRUNCATE(period / 2, 0))) ELSE period).
    END METHOD.

    /* One turn goes by. */
    METHOD PUBLIC STATIC VOID Tick(INPUT poWorld AS RogueWorld):
        DEFINE VARIABLE stage AS INTEGER NO-UNDO.
        /* the stomach */
        IF NOT (poWorld:Pack:WearingRing(RingKind:SlowDigestion) AND poWorld:Turns MODULO 2 = 0) THEN poWorld:Hero:Nutrition = poWorld:Hero:Nutrition - 1.
        IF poWorld:Pack:WearingRing(RingKind:Regeneration) AND poWorld:Turns MODULO 3 = 0 THEN poWorld:Hero:Nutrition = poWorld:Hero:Nutrition - 1.
        stage = StageOf(poWorld:Hero:Nutrition).
        IF stage > poWorld:Hero:HungerStage THEN DO:
            CASE stage:
                WHEN 1 THEN poWorld:Say("You are starting to feel hungry.").
                WHEN 2 THEN poWorld:Say("You are getting weak from hunger.").
                WHEN 3 THEN poWorld:Say("You feel faint from lack of food.").
                OTHERWISE Fighting:Die(poWorld, "starvation").
            END CASE.
        END.
        poWorld:Hero:HungerStage = stage.
        IF stage = 3 AND poWorld:Hero:Asleep = 0 AND poWorld:Random:NextInt(5) = 0 THEN DO:
            poWorld:Hero:Asleep = 3.
            poWorld:Say("You faint from lack of food.").
        END.
        IF poWorld:Dead THEN RETURN.
        /* hit points */
        IF poWorld:Hero:Hp < poWorld:Hero:MaxHp THEN DO:
            poWorld:Hero:HealCounter = poWorld:Hero:HealCounter + 1.
            IF poWorld:Hero:HealCounter >= HealEvery(poWorld:Hero:Rank, poWorld:Pack:WearingRing(RingKind:Regeneration)) THEN DO:
                poWorld:Hero:HealCounter = 0.
                poWorld:Hero:Hp = poWorld:Hero:Hp + 1.
            END.
        END.
        ELSE poWorld:Hero:HealCounter = 0.
        /* the timers */
        IF poWorld:Hero:Confused > 0 THEN DO:
            poWorld:Hero:Confused = poWorld:Hero:Confused - 1.
            IF poWorld:Hero:Confused = 0 THEN poWorld:Say("You feel less confused now.").
        END.
        IF poWorld:Hero:Blind > 0 THEN DO:
            poWorld:Hero:Blind = poWorld:Hero:Blind - 1.
            IF poWorld:Hero:Blind = 0 THEN poWorld:Say("The veil of darkness lifts.").
        END.
        IF poWorld:Hero:Levitating > 0 THEN DO:
            poWorld:Hero:Levitating = poWorld:Hero:Levitating - 1.
            IF poWorld:Hero:Levitating = 0 THEN poWorld:Say("You float gently to the ground.").
        END.
        IF poWorld:Hero:Hallucinating > 0 THEN DO:
            poWorld:Hero:Hallucinating = poWorld:Hero:Hallucinating - 1.
            IF poWorld:Hero:Hallucinating = 0 THEN poWorld:Say("You feel less trippy now.").
        END.
        IF poWorld:Hero:SeesInvisible > 0 THEN DO:
            poWorld:Hero:SeesInvisible = poWorld:Hero:SeesInvisible - 1.
            IF poWorld:Hero:SeesInvisible = 0 THEN poWorld:Say("The tingling in your eyes fades.").
        END.
        IF poWorld:Hero:SensesMonsters > 0 THEN poWorld:Hero:SensesMonsters = poWorld:Hero:SensesMonsters - 1.
        IF poWorld:Hero:SensesMagic > 0 THEN poWorld:Hero:SensesMagic = poWorld:Hero:SensesMagic - 1.
        IF poWorld:Hero:SensesFood > 0 THEN poWorld:Hero:SensesFood = poWorld:Hero:SensesFood - 1.
        /* the rings */
        IF poWorld:Pack:WearingRing(RingKind:Searching) THEN Exploring:Search(poWorld).
        IF poWorld:Pack:WearingRing(RingKind:Teleportation) AND poWorld:Random:NextInt(50) = 0 THEN DO:
            Magic:Teleport(poWorld).
            poWorld:Say("You feel yourself being drawn away.").
        END.
    END METHOD.

END CLASS.
