/* The twenty six monsters, one for each letter A to Z, with the numbers the fights are made from: the name, the monster's level (it has
   that many eight sided dice of hit points and hits as well as a hero of that level), the experience it is worth, its armour class
   (lower is harder to hit, and below 0 is possible), the dice of each of its attacks in a turn (a list such as "1d2/1d5/1d5"), the
   chance out of 100 that it carries gold, and some flags:

     M  mean: awake and hunting from the start      F  flits: moves at random half the time    R  regenerates hit points
     I  invisible without a ring or potion          G  greedy: runs for gold in the room        S  never moves (it only fights)

   What the special monsters do (rust, freezing, stealing, draining, breathing fire) is in the game's rules, by kind. Which monsters
   turn up on which depth is the order of the letters in DepthOrder. The kinds are the members of MonsterKind, in the order A to Z. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.Bestiary FINAL:

    METHOD PUBLIC STATIC INTEGER Count():
        RETURN 26.
    END METHOD.

    METHOD PUBLIC STATIC CHARACTER NameOf(INPUT poKind AS MonsterKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "aquator,bat,centaur,dragon,emu,venus flytrap,griffin,hobgoblin,ice monster,jabberwock,kestrel,leprechaun,medusa,nymph,orc,phantom,quagga,rattlesnake,snake,troll,ur-vile,vampire,wraith,xeroc,yeti,zombie").
    END METHOD.

    /* The letter the monster is drawn as, A to Z. */
    METHOD PUBLIC STATIC CHARACTER Letter(INPUT poKind AS MonsterKind):
        RETURN CHR(ASC("A") + INTEGER(poKind)).
    END METHOD.

    /* The kind drawn as a letter A to Z, whatever the case. Throws GridException for anything else. */
    METHOD PUBLIC STATIC MonsterKind OfLetter(INPUT pcLetter AS CHARACTER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        IF pcLetter = ? OR LENGTH(pcLetter) <> 1 THEN UNDO, THROW NEW GridException("A monster is one letter, A to Z").
        n = ASC(CAPS(pcLetter)) - ASC("A").
        IF n < 0 OR n > 25 THEN UNDO, THROW NEW GridException("There is no monster called " + pcLetter).
        RETURN MonsterKind:GetEnum(n).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Level(INPUT poKind AS MonsterKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "5,1,4,10,1,8,13,1,1,15,1,3,8,3,1,8,3,2,1,6,7,8,5,7,4,2")).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Experience(INPUT poKind AS MonsterKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "20,1,17,5000,2,80,2000,3,5,3000,1,10,200,37,5,120,15,9,2,120,190,350,55,100,50,6")).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ArmourClass(INPUT poKind AS MonsterKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "2,3,4,-1,7,3,2,5,9,6,7,8,2,9,6,3,3,3,5,4,-2,1,4,7,6,8")).
    END METHOD.

    /* The dice of each attack in a turn, such as "1d8/1d8/3d10". An attack of 0d0 does no harm of its own (the special does the work). */
    METHOD PUBLIC STATIC CHARACTER Damage(INPUT poKind AS MonsterKind):
        RETURN ENTRY(INTEGER(poKind) + 1, "0d0,1d2,1d2/1d5/1d5,1d8/1d8/3d10,1d2,0d0,4d3/3d5,1d8,0d0,2d12/2d4,1d4,1d1,3d4/3d4/2d5,0d0,1d8,4d4,1d5/1d5,1d6,1d3,1d8/1d8/2d6,1d9/1d9/2d9,1d19,1d6,4d4,1d6/1d6,1d8").
    END METHOD.

    /* The chance out of 100 that the monster is carrying gold. */
    METHOD PUBLIC STATIC INTEGER Carry(INPUT poKind AS MonsterKind):
        RETURN INTEGER(ENTRY(INTEGER(poKind) + 1, "0,0,15,100,0,0,20,0,0,70,0,0,40,100,15,0,0,0,0,50,0,20,0,30,30,0")).
    END METHOD.

    /* The flags of the monster, as letters (see above): "" for none. */
    METHOD PUBLIC STATIC CHARACTER Flags(INPUT poKind AS MonsterKind):
        DEFINE VARIABLE f AS CHARACTER NO-UNDO.
        f = ENTRY(INTEGER(poKind) + 1, "M,F,-,M,M,MS,MR,M,-,-,M,-,M,-,G,I,M,M,M,MR,M,MR,-,-,-,M").
        RETURN (IF f = "-" THEN "" ELSE f).
    END METHOD.

    /* True when the monster has a flag. */
    METHOD PUBLIC STATIC LOGICAL Has(INPUT poKind AS MonsterKind, INPUT pcFlag AS CHARACTER):
        RETURN INDEX(Flags(poKind), pcFlag) > 0.
    END METHOD.

    /* The letters of the monsters in the order they turn up in the dungeon: the first is met on depth 1, the last on depth 26. */
    METHOD PUBLIC STATIC CHARACTER DepthOrder():
        RETURN "KEBSHIROZLCQANYFTWPXUMVGJD".
    END METHOD.

    /* A monster that suits a depth: the one at the position of the depth, moved by a roll of the dice from 6 up to 3 down the list, so
       a deep level can still turn up a weak monster and a shallow one now and then a strong one. */
    METHOD PUBLIC STATIC MonsterKind ForDepth(INPUT piDepth AS INTEGER, INPUT poRandom AS IRandom):
        DEFINE VARIABLE d AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A monster pick needs a random source").
        d = piDepth - 1 + poRandom:NextInt(10) - 6.
        IF d < 0 THEN d = poRandom:NextInt(5).
        IF d > 25 THEN d = 25 - poRandom:NextInt(5).
        RETURN OfLetter(SUBSTRING(DepthOrder(), d + 1, 1)).
    END METHOD.

END CLASS.
