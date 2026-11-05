/* The numbers of Rogue that more than one class needs: the size of the map and the screen, how deep the dungeon goes, the pack, the
   stomach, the experience table and the starting hero. Everything here is a plain quantity. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueRules FINAL:

    /* The map is 80 across and 21 down, as on the original's 80 x 24 screen: a message line above it and two status lines below. */
    METHOD PUBLIC STATIC INTEGER MapWidth():
        RETURN 80.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER MapHeight():
        RETURN 21.
    END METHOD.

    /* The depth of the level with the amulet, and so how many levels there are. */
    METHOD PUBLIC STATIC INTEGER AmuletDepth():
        RETURN 26.
    END METHOD.

    /* The most things the pack holds, a to w. */
    METHOD PUBLIC STATIC INTEGER PackSize():
        RETURN 23.
    END METHOD.

    /* The most monsters on a level, and the most things lying on the floor of one. */
    METHOD PUBLIC STATIC INTEGER MostMonsters():
        RETURN 64.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER MostFloorItems():
        RETURN 120.
    END METHOD.

    /* The hero starts with 12 hit points and a strength of 16, and with nothing in the stomach to spare. */
    METHOD PUBLIC STATIC INTEGER StartHp():
        RETURN 12.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER StartStrength():
        RETURN 16.
    END METHOD.

    /* A full stomach, and the points of it under which the hero is Hungry, Weak and Faint. A turn costs one point. */
    METHOD PUBLIC STATIC INTEGER StomachSize():
        RETURN 2000.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER HungryBelow():
        RETURN 300.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER WeakBelow():
        RETURN 150.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FaintBelow():
        RETURN 50.
    END METHOD.

    /* The experience points a hero needs to reach experience level piRank + 1 (level 1 needs 10 to become level 2). The last level
       never needs more: 0 is returned past it. */
    METHOD PUBLIC STATIC INTEGER ExperienceToPass(INPUT piRank AS INTEGER):
        IF piRank = ? OR piRank < 1 OR piRank > 20 THEN RETURN 0.
        RETURN INTEGER(ENTRY(piRank, "10,20,40,80,160,320,640,1300,2600,5200,13000,26000,50000,100000,200000,400000,800000,2000000,4000000,8000000")).
    END METHOD.

    /* The highest experience level. */
    METHOD PUBLIC STATIC INTEGER HighestRank():
        RETURN 21.
    END METHOD.

    /* What a strength adds to the chance to hit and to the damage of a blow: nothing at 16, a point more for each two above it up to the
       top, and a point less for each two below it. */
    METHOD PUBLIC STATIC INTEGER StrengthHit(INPUT piStrength AS INTEGER):
        RETURN (IF piStrength >= 16 THEN INTEGER(TRUNCATE((piStrength - 16) / 2, 0)) ELSE - INTEGER(TRUNCATE((16 - piStrength) / 2, 0))).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER StrengthDamage(INPUT piStrength AS INTEGER):
        RETURN StrengthHit(piStrength).
    END METHOD.

    /* The width and height of the whole screen in characters, and the rows of it: the message line is row 0, the map starts at row 1 and
       the two status lines are the last two. */
    METHOD PUBLIC STATIC INTEGER ScreenColumns():
        RETURN 80.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ScreenRows():
        RETURN 24.
    END METHOD.

END CLASS.
