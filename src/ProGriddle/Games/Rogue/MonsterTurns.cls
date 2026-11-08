/* What the monsters do once the hero has had a turn. A sleeping monster may wake when the hero is in its room or close by (less often
   when a ring of stealth is worn, and always when a ring of aggravation is). An awake monster that is next to the hero hits, one that is
   not hunts: it steps to the square nearest the hero by the Chase map, or wanders when the hero is far off. Some do other things:

     bats and the like (flag F) flutter about at random half the time      a venus flytrap (S) never moves, it only holds and hits
     confused monsters stumble about at random                              trolls and vampires (R) heal as they go
     a dragon breathes fire down a clear straight line                      a held monster misses its turn, a slowed one every other

   A monster will not step onto a scroll of scare monster, and will not hit a hero standing on one. A monster that has stolen from
   the hero leaves the level. Hasted monsters move twice. Everything chancy goes through the world's random source. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.MonsterTurns FINAL:

    VAR PRIVATE Chase mChase.
    VAR PRIVATE LOGICAL mFresh.

    CONSTRUCTOR PUBLIC MonsterTurns():
        mChase = NEW Chase().
    END CONSTRUCTOR.

    /* The chase map of the last Take, for others that need to know how far something is from the hero. */
    DEFINE PUBLIC PROPERTY Map AS Chase NO-UNDO
        GET():
            RETURN mChase.
        END GET.

    /* Works out the chase map for this turn (it is done at most once, and only when a monster needs it). */
    METHOD PUBLIC VOID Prepare(INPUT poWorld AS RogueWorld):
        mChase:Refresh(poWorld).
        mFresh = TRUE.
    END METHOD.

    /* Every monster on the level takes its turn. */
    METHOD PUBLIC VOID Take(INPUT poWorld AS RogueWorld):
        VAR INTEGER i.
        VAR Monster oMonster.
        mFresh = FALSE.
        DO i = 0 TO RogueRules:MostMonsters() - 1:
            IF poWorld:Dead THEN LEAVE.
            oMonster = poWorld:MonsterInSlot(i).
            IF VALID-OBJECT(oMonster) THEN DO:
                IF oMonster:Awake AND NOT mFresh THEN Prepare(poWorld).
                Act(poWorld, oMonster).
            END.
        END.
    END METHOD.
    /* One monster's turn (or two when hasted, none when held). The chase map must be up to date (Take and Prepare do it). */
    METHOD PUBLIC VOID Act(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        IF poMonster:Held > 0 THEN DO:
            poMonster:Held = poMonster:Held - 1.
            RETURN.
        END.
        IF poMonster:Slowed > 0 THEN DO:
            poMonster:Slowed = poMonster:Slowed - 1.
            IF poWorld:Turns MODULO 2 = 0 THEN RETURN.
        END.
        Move(poWorld, poMonster).
        IF poMonster:Hasted > 0 THEN DO:
            poMonster:Hasted = poMonster:Hasted - 1.
            IF NOT poWorld:Dead AND poWorld:MonsterAtCell(poMonster:X, poMonster:Y) = poMonster THEN Move(poWorld, poMonster).
        END.
    END METHOD.

    /* One go of a monster: heal, wake, fly about, breathe, hit or hunt. */
    METHOD PRIVATE VOID Move(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        VAR INTEGER dx.
        VAR INTEGER dy.
        VAR INTEGER dist.
        IF Bestiary:Has(poMonster:Kind, "R") AND poMonster:Hp < poMonster:MaxHp AND poWorld:Turns MODULO 4 = 0 THEN poMonster:Hp = poMonster:Hp + 1.
        IF NOT poMonster:Awake THEN DO:
            TryToWake(poWorld, poMonster).
            IF NOT poMonster:Awake THEN RETURN.
            IF NOT mFresh THEN Prepare(poWorld).
        END.
        IF poMonster:Confused > 0 THEN DO:
            poMonster:Confused = poMonster:Confused - 1.
            Wander(poWorld, poMonster).
            RETURN.
        END.
        dist = mChase:DistanceAt(poMonster:X, poMonster:Y).
        IF poMonster:Kind = MonsterKind:Dragon AND Breathes(poWorld, poMonster) THEN RETURN.
        IF Bestiary:Has(poMonster:Kind, "F") AND poWorld:Random:NextInt(2) = 0 THEN DO:
            Wander(poWorld, poMonster).
            RETURN.
        END.
        IF dist = 1 THEN DO:
            IF NOT Scared(poWorld, poWorld:Hero:X, poWorld:Hero:Y) THEN Fighting:MonsterAttack(poWorld, poMonster).
            RETURN.
        END.
        IF Bestiary:Has(poMonster:Kind, "S") THEN RETURN.
        IF dist > 1 AND dist <= 25 THEN DO:
            IF mChase:BestStep(poWorld, poMonster, OUTPUT dx, OUTPUT dy) AND NOT Scared(poWorld, poMonster:X + dx, poMonster:Y + dy) THEN
                poWorld:MoveMonster(poMonster, poMonster:X + dx, poMonster:Y + dy).
        END.
        ELSE IF poWorld:Random:NextInt(4) = 0 THEN Wander(poWorld, poMonster).
    END METHOD.

    /* A sleeping monster wakes now and then when the hero is in its room or within three squares. A ring of aggravation wakes them all. */
    METHOD PRIVATE VOID TryToWake(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        VAR INTEGER room.
        IF poWorld:Pack:WearingRing(RingKind:Aggravation) THEN DO:
            poMonster:Awake = TRUE.
            RETURN.
        END.
        room = poWorld:Cave:RoomAt(poMonster:X, poMonster:Y).
        IF (room > 0 AND room = poWorld:Cave:RoomAt(poWorld:Hero:X, poWorld:Hero:Y)) OR RogueWorld:Distance(poMonster:X, poMonster:Y, poWorld:Hero:X, poWorld:Hero:Y) <= 3 THEN DO:
            IF poWorld:Random:NextInt((IF poWorld:Pack:WearingRing(RingKind:Stealth) THEN 12 ELSE 4)) = 0 THEN poMonster:Awake = TRUE.
        END.
    END METHOD.

    /* Steps in a random direction if there is a free square that way (a few tries). */
    METHOD PRIVATE VOID Wander(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        VAR INTEGER tries.
        VAR INTEGER dx.
        VAR INTEGER dy.
        DO tries = 1 TO 6:
            dx = poWorld:Random:NextInt(3) - 1.
            dy = poWorld:Random:NextInt(3) - 1.
            IF (dx <> 0 OR dy <> 0) AND poWorld:CanStep(poMonster:X, poMonster:Y, dx, dy)
               AND poWorld:Cave:MonsterAt(poMonster:X + dx, poMonster:Y + dy) = 0
               AND NOT (poMonster:X + dx = poWorld:Hero:X AND poMonster:Y + dy = poWorld:Hero:Y)
               AND NOT Scared(poWorld, poMonster:X + dx, poMonster:Y + dy) THEN DO:
                poWorld:MoveMonster(poMonster, poMonster:X + dx, poMonster:Y + dy).
                RETURN.
            END.
        END.
    END METHOD.

    /* True when a scroll of scare monster lies on the square. */
    METHOD PUBLIC STATIC LOGICAL Scared(INPUT poWorld AS RogueWorld, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR Item oItem.
        oItem = poWorld:FloorItemAt(piX, piY).
        RETURN VALID-OBJECT(oItem) AND oItem:Category = ItemType:Scroll AND oItem:Kind = INTEGER(ScrollKind:ScareMonster).
    END METHOD.

    /* A dragon in a straight clear line from the hero (along a row, a column or a diagonal) from 2 to 7 squares away breathes fire now and
       then. Gives true when it did. */
    METHOD PRIVATE LOGICAL Breathes(INPUT poWorld AS RogueWorld, INPUT poMonster AS Monster):
        VAR INTEGER dx.
        VAR INTEGER dy.
        VAR INTEGER dist.
        IF poMonster:Cancelled THEN RETURN FALSE.
        dx = poWorld:Hero:X - poMonster:X.
        dy = poWorld:Hero:Y - poMonster:Y.
        dist = RogueWorld:Distance(poMonster:X, poMonster:Y, poWorld:Hero:X, poWorld:Hero:Y).
        IF dist < 2 OR dist > 7 THEN RETURN FALSE.
        IF NOT (dx = 0 OR dy = 0 OR ABSOLUTE(dx) = ABSOLUTE(dy)) THEN RETURN FALSE.
        IF NOT Sight:LineClear(poWorld, poMonster:X, poMonster:Y, poWorld:Hero:X, poWorld:Hero:Y) THEN RETURN FALSE.
        IF poWorld:Random:NextInt(4) <> 0 THEN RETURN FALSE.
        poWorld:Say("The dragon breathes fire!").
        Fighting:Hurt(poWorld, Dice:Roll("6d6", poWorld:Random), "a dragon").
        RETURN TRUE.
    END METHOD.

END CLASS.
