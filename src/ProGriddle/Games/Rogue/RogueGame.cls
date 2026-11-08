/* Rogue, as a game the window can play: a turn based game whose every move is a command token given to Command. It owns the world (see
   RogueWorld) and the monsters' turns, and knows what the game is waiting for (Mode):

     Play           a command. Tokens are one character ("q" quaff, "r" read, "e" eat, "w" wield, "t" throw, "z" zap, "d" drop, "i", ",", ".",
                    "s", ">", "<", "?", "D", "M" ...), "S-" and a letter for a shifted letter ("S-w" wear, "S-t" take off, "S-p" put on, "S-r"
                    remove a ring, "S-q" quit), "1" to "9" (not 5) to step in the directions of a number pad ("4" west, "9" north east), "run1"
                    to "run9" to run, and "ESC", "ENTER", "SPACE"
     PickItem       a pack letter "a" to "w" for the command that asked (quaff what?), or "ESC" to give up
     PickDirection  a direction "1" to "9" for the throw or the zap, or "ESC"
     Overlay        (Showing says which) any token closes the screen on show (the pack, the help, the messages, what has been discovered)
     Confirm        "y" to give up (after "S-q"), anything else to carry on
     Over           the hero is dead or has left with the amulet: "ENTER" starts a new game

   A command that takes time lets the monsters take theirs, the hero's hunger, healing and timers go on, and what the hero can see is
   worked out again. A hasted hero has two commands to each turn of the monsters, a hero who is asleep (frozen, or fainted) loses turns
   until awake again. The dungeon has 26 levels: down the stairs with ">", and, once the amulet is in the pack, up with "<" to the surface
   from the first level to win.

   The game knows nothing of keys or pictures: RogueInput turns keys into tokens and RogueScreen draws what is here. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueGame FINAL INHERITS AbstractGame IMPLEMENTS ITurnBasedGame:

    VAR PRIVATE RogueWorld mWorld.
    VAR PRIVATE MonsterTurns mTurns.
    /* a hasted hero's actions come in pairs, and the monsters move on the second of each pair */
    VAR PRIVATE LOGICAL mBeat.
    /* what a command that needs an item or a direction is waiting to do, and the item chosen for it */
    VAR PRIVATE INTEGER mItemSlot.

    DEFINE PUBLIC PROPERTY World AS RogueWorld NO-UNDO
        GET():
            RETURN mWorld.
        END GET.

    DEFINE PUBLIC PROPERTY Mode AS RogueMode NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Action AS RogueAction NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Showing AS RogueOverlay NO-UNDO
        GET.
        PRIVATE SET.

    /* The turns the monsters have had (each is a turn of the game, however many commands a hasted hero gets in it). */
    DEFINE PUBLIC PROPERTY Turn AS INTEGER NO-UNDO
        GET():
            RETURN mWorld:Turns.
        END GET.

    /* The words that ask for what the game is waiting for ("Quaff what?"), empty when it is waiting for a command. */
    DEFINE PUBLIC PROPERTY Asking AS CHARACTER NO-UNDO
        GET.
        PRIVATE SET.

    /* How hungry the hero is. */
    DEFINE PUBLIC PROPERTY HungerState AS Hunger NO-UNDO
        GET():
            RETURN Hunger:GetEnum(Upkeep:StageOf(mWorld:Hero:Nutrition)).
        END GET.

    /* Throws GridException for a grid that is not a Rogue level, or no random source. The game starts when it is Initialised. */
    CONSTRUCTOR PUBLIC RogueGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        SUPER("Rogue", poGrid).
        mWorld = NEW RogueWorld(poGrid, poRandom).
        mTurns = NEW MonsterTurns().
    END CONSTRUCTOR.

    /* A new game: a new hero and the first level. */
    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        mWorld:Reset().
        mBeat = FALSE.
        mItemSlot = -1.
        Mode = RogueMode:Play.
        Action = RogueAction:None.
        Showing = RogueOverlay:None.
        Asking = "".
        mWorld:Say("Hello Rogue. Welcome to the Dungeons of Doom.").
        Sight:Look(mWorld).
    END METHOD.

    /* ================================== the commands ================================== */

    /* Gives the game a command token (see above). */
    METHOD PUBLIC VOID Command(INPUT pcToken AS CHARACTER):
        IF pcToken = ? OR pcToken = "" THEN RETURN.
        CASE Mode:
            WHEN RogueMode:Play THEN PlayCommand(pcToken).
            WHEN RogueMode:PickItem THEN PickedItem(pcToken).
            WHEN RogueMode:PickDirection THEN PickedDirection(pcToken).
            WHEN RogueMode:Overlay THEN CloseOverlay().
            WHEN RogueMode:Confirm THEN Confirmed(pcToken).
            OTHERWISE DO:
                IF pcToken = "ENTER" THEN Initialise().
            END.
        END CASE.
    END METHOD.

    /* The step of a number pad direction token ("1" to "9"): the change across and down, or 0 for a token that is not one. */
    METHOD PUBLIC STATIC INTEGER StepX(INPUT pcToken AS CHARACTER):
        CASE pcToken:
            WHEN "1" OR WHEN "4" OR WHEN "7" THEN RETURN -1.
            WHEN "3" OR WHEN "6" OR WHEN "9" THEN RETURN 1.
            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER StepY(INPUT pcToken AS CHARACTER):
        CASE pcToken:
            WHEN "7" OR WHEN "8" OR WHEN "9" THEN RETURN -1.
            WHEN "1" OR WHEN "2" OR WHEN "3" THEN RETURN 1.
            OTHERWISE RETURN 0.
        END CASE.
    END METHOD.

    /* True for a token that is a direction: "1" to "4" and "6" to "9". */
    METHOD PUBLIC STATIC LOGICAL IsDirection(INPUT pcToken AS CHARACTER):
        RETURN pcToken <> ? AND LENGTH(pcToken) = 1 AND INDEX("12346789", pcToken) > 0.
    END METHOD.

    METHOD PRIVATE VOID PlayCommand(INPUT pcToken AS CHARACTER):
        VAR INTEGER dx.
        VAR INTEGER dy.
        mWorld:Messages:BeginTurn().
        IF IsDirection(pcToken) THEN DO:
            IF StepHero(StepX(pcToken), StepY(pcToken)) > 0 THEN EndAction().
            RETURN.
        END.
        IF LENGTH(pcToken) = 4 AND SUBSTRING(pcToken, 1, 3) = "run" AND IsDirection(SUBSTRING(pcToken, 4, 1)) THEN DO:
            RunHero(StepX(SUBSTRING(pcToken, 4, 1)), StepY(SUBSTRING(pcToken, 4, 1))).
            RETURN.
        END.
        CASE pcToken:
            WHEN "5" OR WHEN "." THEN EndAction().
            WHEN "s" THEN DO:
                IF Exploring:Search(mWorld) = 0 THEN mWorld:Say("You find nothing.").
                EndAction().
            END.
            WHEN "i" THEN Show(RogueOverlay:Inventory).
            WHEN "?" THEN Show(RogueOverlay:Help).
            WHEN "S-d" THEN Show(RogueOverlay:Discoveries).
            WHEN "S-m" THEN Show(RogueOverlay:Messages).
            WHEN "q" THEN Ask(RogueAction:Quaff, "Quaff what?").
            WHEN "r" THEN Ask(RogueAction:ReadScroll, "Read what?").
            WHEN "e" THEN Ask(RogueAction:Eat, "Eat what?").
            WHEN "w" THEN Ask(RogueAction:Wield, "Wield what?").
            WHEN "S-w" THEN Ask(RogueAction:Wear, "Wear what?").
            WHEN "S-t" THEN DO:
                IF Gear:TakeOff(mWorld) THEN EndAction().
            END.
            WHEN "S-p" THEN Ask(RogueAction:PutOn, "Put on what?").
            WHEN "S-r" THEN RemoveARing().
            WHEN "d" THEN Ask(RogueAction:DropItem, "Drop what?").
            WHEN "t" THEN Ask(RogueAction:ThrowItem, "Throw what?").
            WHEN "z" THEN Ask(RogueAction:Zap, "Zap with what?").
            WHEN "," THEN DO:
                IF Gear:Pickup(mWorld) THEN EndAction().
                ELSE IF NOT VALID-OBJECT(mWorld:FloorItemAt(mWorld:Hero:X, mWorld:Hero:Y)) THEN mWorld:Say("There is nothing here to pick up.").
            END.
            WHEN ">" THEN GoDown().
            WHEN "<" THEN GoUp().
            WHEN "S-q" THEN DO:
                Asking = "Really quit? (y or n)".
                Mode = RogueMode:Confirm.
            END.
            WHEN "v" THEN mWorld:Say("Rogue, in ProGriddle. The Amulet of Yendor lies on the 26th level.").
        END CASE.
    END METHOD.

    /* ================================== prompts and screens ================================== */

    METHOD PRIVATE VOID Ask(INPUT poAction AS RogueAction, INPUT pcPrompt AS CHARACTER):
        IF mWorld:Pack:Count = 0 THEN DO:
            mWorld:Say("You have nothing in your pack.").
            RETURN.
        END.
        Action = poAction.
        Asking = pcPrompt + " (a letter, or ESC)".
        Mode = RogueMode:PickItem.
    END METHOD.

    METHOD PRIVATE VOID Show(INPUT poOverlay AS RogueOverlay):
        Showing = poOverlay.
        Mode = RogueMode:Overlay.
    END METHOD.

    METHOD PRIVATE VOID CloseOverlay():
        Showing = RogueOverlay:None.
        Mode = RogueMode:Play.
    END METHOD.

    METHOD PRIVATE VOID GiveUpAsking():
        Action = RogueAction:None.
        Asking = "".
        mItemSlot = -1.
        Mode = RogueMode:Play.
    END METHOD.

    /* A token while the game waits for a yes or no to giving up: "y" gives up, anything else carries on. */
    METHOD PRIVATE VOID Confirmed(INPUT pcToken AS CHARACTER):
        Asking = "".
        Mode = RogueMode:Play.
        IF pcToken <> "y" THEN RETURN.
        mWorld:Messages:BeginTurn().
        mWorld:Say("You quit.").
        Fighting:Die(mWorld, "quit").
        EndAction().
    END METHOD.
    /* A token while the game waits for an item. */
    METHOD PRIVATE VOID PickedItem(INPUT pcToken AS CHARACTER):
        VAR INTEGER slot.
        VAR LOGICAL spent.
        VAR LOGICAL pick.
        IF pcToken = "ESC" THEN DO:
            GiveUpAsking().
            RETURN.
        END.
        slot = mWorld:Pack:SlotOf(pcToken).
        IF slot < 0 OR LENGTH(pcToken) <> 1 THEN RETURN.
        mWorld:Messages:BeginTurn().
        IF NOT mWorld:Pack:Holds(slot) THEN DO:
            mWorld:Say("You have nothing like that.").
            RETURN.
        END.
        CASE Action:
            WHEN RogueAction:ThrowItem OR WHEN RogueAction:Zap THEN DO:
                mItemSlot = slot.
                Asking = "In what direction? (a number pad direction, or ESC)".
                Mode = RogueMode:PickDirection.
                RETURN.
            END.
            WHEN RogueAction:Identify THEN DO:
                Magic:IdentifyItem(mWorld, slot).
                GiveUpAsking().
                RETURN.
            END.
        END CASE.
        CASE Action:
            WHEN RogueAction:Quaff THEN spent = Magic:Quaff(mWorld, slot).
            WHEN RogueAction:Eat THEN spent = Magic:Eat(mWorld, slot).
            WHEN RogueAction:Wield THEN spent = Gear:Wield(mWorld, slot).
            WHEN RogueAction:Wear THEN spent = Gear:Wear(mWorld, slot).
            WHEN RogueAction:PutOn THEN spent = Gear:PutOn(mWorld, slot).
            WHEN RogueAction:RemoveRing THEN spent = Gear:RemoveRing(mWorld, slot).
            WHEN RogueAction:DropItem THEN spent = Gear:DropItem(mWorld, slot).
            WHEN RogueAction:ReadScroll THEN DO:
                spent = Magic:ReadScroll(mWorld, slot, OUTPUT pick).
                IF pick THEN DO:
                    Action = RogueAction:Identify.
                    Asking = "Identify what? (a letter, or ESC)".
                    IF spent THEN EndAction().
                    RETURN.
                END.
            END.
        END CASE.
        GiveUpAsking().
        IF spent THEN EndAction().
    END METHOD.

    /* A token while the game waits for a direction (for a throw or a zap). */
    METHOD PRIVATE VOID PickedDirection(INPUT pcToken AS CHARACTER):
        VAR INTEGER slot.
        VAR LOGICAL spent.
        VAR RogueAction what.
        IF pcToken = "ESC" THEN DO:
            GiveUpAsking().
            RETURN.
        END.
        IF NOT IsDirection(pcToken) THEN RETURN.
        slot = mItemSlot.
        what = Action.
        GiveUpAsking().
        mWorld:Messages:BeginTurn().
        IF what = RogueAction:ThrowItem THEN spent = Throwing:Throw(mWorld, slot, StepX(pcToken), StepY(pcToken)).
        ELSE spent = Magic:Zap(mWorld, slot, StepX(pcToken), StepY(pcToken)).
        IF spent THEN EndAction().
    END METHOD.

    /* The "remove ring" command: the ring that is worn when there is one, else ask which. */
    METHOD PRIVATE VOID RemoveARing():
        VAR INTEGER n.
        n = Gear:RingsWorn(mWorld).
        IF n = 0 THEN DO:
            mWorld:Say("You have no rings on.").
            RETURN.
        END.
        IF n = 1 THEN DO:
            IF Gear:RemoveRing(mWorld, (IF mWorld:Pack:LeftRingSlot >= 0 THEN mWorld:Pack:LeftRingSlot ELSE mWorld:Pack:RightRingSlot)) THEN EndAction().
            RETURN.
        END.
        Ask(RogueAction:RemoveRing, "Remove which ring?").
    END METHOD.

    /* ================================== moving ================================== */

    /* One step of the hero in a direction. Gives 0 when no time passed (a wall in the way), 1 for a step taken and 2 for a fight, being
       held or stuck, or anything else that took the turn. */
    METHOD PRIVATE INTEGER StepHero(INPUT piDX AS INTEGER, INPUT piDY AS INTEGER):
        VAR INTEGER dx.
        VAR INTEGER dy.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER trap.
        VAR Monster oMonster.
        dx = piDX.
        dy = piDY.
        IF mWorld:Hero:Confused > 0 AND mWorld:Random:NextInt(2) = 0 THEN DO:
            dx = mWorld:Random:NextInt(3) - 1.
            dy = mWorld:Random:NextInt(3) - 1.
            IF dx = 0 AND dy = 0 THEN dx = 1.
        END.
        x = mWorld:Hero:X + dx.
        y = mWorld:Hero:Y + dy.
        oMonster = mWorld:MonsterAtCell(x, y).
        IF VALID-OBJECT(oMonster) AND mWorld:CanStep(mWorld:Hero:X, mWorld:Hero:Y, dx, dy) THEN DO:
            Fighting:HeroAttack(mWorld, oMonster).
            RETURN 2.
        END.
        IF mWorld:Hero:Stuck > 0 THEN DO:
            mWorld:Hero:Stuck = mWorld:Hero:Stuck - 1.
            mWorld:Say("You are stuck in the bear trap.").
            RETURN 2.
        END.
        IF VALID-OBJECT(mWorld:Hero:HeldBy) THEN DO:
            mWorld:Say("You are being held.").
            RETURN 2.
        END.
        IF NOT mWorld:CanStep(mWorld:Hero:X, mWorld:Hero:Y, dx, dy) THEN RETURN 0.
        mWorld:PlaceHero(x, y).
        Sight:Look(mWorld).
        Gear:Pickup(mWorld).
        trap = mWorld:Cave:TrapAt(x, y).
        IF trap > 0 AND mWorld:Hero:Levitating = 0 THEN DO:
            IF Magic:SpringTrap(mWorld, TrapKind:GetEnum(trap - 1)) THEN FallDown().
        END.
        RETURN 1.
    END METHOD.

    /* Runs: steps again and again until something interesting turns up, as much as 60 steps. */
    METHOD PRIVATE VOID RunHero(INPUT piDX AS INTEGER, INPUT piDY AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER before.
        VAR INTEGER hp.
        VAR INTEGER depth.
        VAR INTEGER result.
        depth = mWorld:Depth.
        DO i = 1 TO 60:
            before = mWorld:Messages:TurnCount.
            hp = mWorld:Hero:Hp.
            result = StepHero(piDX, piDY).
            IF result = 0 THEN LEAVE.
            EndAction().
            IF mWorld:Dead OR mWorld:Won OR mWorld:Depth <> depth OR result <> 1 THEN LEAVE.
            IF mWorld:Messages:TurnCount > before OR mWorld:Hero:Hp < hp THEN LEAVE.
            IF Interesting(piDX, piDY) THEN LEAVE.
        END.
    END METHOD.

    /* True when a runner should stop where they are: a monster in sight, a door, the stairs, or a fork in a corridor. */
    METHOD PRIVATE LOGICAL Interesting(INPUT piDX AS INTEGER, INPUT piDY AS INTEGER):
        VAR INTEGER i.
        VAR Monster oMonster.
        VAR INTEGER ways.
        DO i = 0 TO RogueRules:MostMonsters() - 1:
            oMonster = mWorld:MonsterInSlot(i).
            IF VALID-OBJECT(oMonster) AND Sight:CanSee(mWorld, oMonster) THEN RETURN TRUE.
        END.
        IF mWorld:Cave:IsDoorway(mWorld:Hero:X, mWorld:Hero:Y) OR mWorld:Cave:TerrainAt(mWorld:Hero:X, mWorld:Hero:Y) = INTEGER(Terrain:Stairs) THEN RETURN TRUE.
        IF mWorld:Cave:TerrainAt(mWorld:Hero:X, mWorld:Hero:Y) = INTEGER(Terrain:Passage) THEN DO:
            IF mWorld:Cave:Walkable(mWorld:Hero:X - 1, mWorld:Hero:Y) THEN ways = ways + 1.
            IF mWorld:Cave:Walkable(mWorld:Hero:X + 1, mWorld:Hero:Y) THEN ways = ways + 1.
            IF mWorld:Cave:Walkable(mWorld:Hero:X, mWorld:Hero:Y - 1) THEN ways = ways + 1.
            IF mWorld:Cave:Walkable(mWorld:Hero:X, mWorld:Hero:Y + 1) THEN ways = ways + 1.
            IF ways > 2 THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* ================================== the stairs ================================== */

    METHOD PRIVATE VOID GoDown():
        IF mWorld:Cave:TerrainAt(mWorld:Hero:X, mWorld:Hero:Y) <> INTEGER(Terrain:Stairs) THEN DO:
            mWorld:Say("I see no way down.").
            RETURN.
        END.
        IF mWorld:Depth >= RogueRules:AmuletDepth() THEN DO:
            mWorld:Say("You cannot go any deeper.").
            RETURN.
        END.
        mWorld:NewLevel(mWorld:Depth + 1).
        mWorld:Say("You descend to level " + STRING(mWorld:Depth) + ".").
        EndAction().
    END METHOD.

    METHOD PRIVATE VOID GoUp():
        IF mWorld:Cave:TerrainAt(mWorld:Hero:X, mWorld:Hero:Y) <> INTEGER(Terrain:Stairs) THEN DO:
            mWorld:Say("I see no way up.").
            RETURN.
        END.
        IF NOT mWorld:Pack:HasAmulet() THEN DO:
            mWorld:Say("Your way is magically blocked.").
            RETURN.
        END.
        IF mWorld:Depth = 1 THEN DO:
            mWorld:Won = TRUE.
            mWorld:Say("You emerge into the sunlight with the Amulet of Yendor. You have won!").
            EndAction().
            RETURN.
        END.
        mWorld:NewLevel(mWorld:Depth - 1).
        mWorld:Say("You climb to level " + STRING(mWorld:Depth) + ".").
        EndAction().
    END METHOD.

    /* The hero falls through a trap door to the level below (or the trap does nothing on the last level). */
    METHOD PRIVATE VOID FallDown():
        IF mWorld:Depth >= RogueRules:AmuletDepth() THEN RETURN.
        mWorld:NewLevel(mWorld:Depth + 1).
        mWorld:Say("You are now on level " + STRING(mWorld:Depth) + ".").
    END METHOD.

    /* ================================== time ================================== */

    /* A command has taken time: the hero's hunger and healing go on, the monsters move (every second command when hasted), and a hero who
       is asleep loses turns until awake. The game is over when the hero has died or won. */
    METHOD PRIVATE VOID EndAction():
        EndOneAction().
        DO WHILE mWorld:Hero:Asleep > 0 AND NOT mWorld:Dead AND NOT mWorld:Won:
            mWorld:Hero:Asleep = mWorld:Hero:Asleep - 1.
            IF mWorld:Hero:Asleep = 0 THEN mWorld:Say("You can move again.").
            EndOneAction().
        END.
        IF mWorld:Dead OR mWorld:Won THEN DO:
            IsOver = TRUE.
            Mode = RogueMode:Over.
            Showing = RogueOverlay:Tombstone.
            Asking = "".
        END.
    END METHOD.

    METHOD PRIVATE VOID EndOneAction():
        IF mWorld:Won THEN RETURN.
        IF mWorld:Hero:Hasted > 0 THEN DO:
            mWorld:Hero:Hasted = mWorld:Hero:Hasted - 1.
            mBeat = NOT mBeat.
            IF mBeat THEN DO:
                Sight:Look(mWorld).
                RETURN.
            END.
        END.
        mWorld:Turns = mWorld:Turns + 1.
        Upkeep:Tick(mWorld).
        IF NOT mWorld:Dead THEN mTurns:Take(mWorld).
        Sight:Look(mWorld).
        mWorld:Hero:HeldBy = (IF VALID-OBJECT(mWorld:Hero:HeldBy) AND RogueWorld:Distance(mWorld:Hero:X, mWorld:Hero:Y, mWorld:Hero:HeldBy:X, mWorld:Hero:HeldBy:Y) <= 1 THEN mWorld:Hero:HeldBy ELSE ?).
    END METHOD.

END CLASS.
