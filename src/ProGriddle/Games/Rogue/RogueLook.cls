/* The colours of Rogue, in one place. The look is a dark terminal with a little colour: grey walls, dim dots for the floor, warm doors,
   a bright staircase, and every sort of thing in a colour of its own, so a room can be read at a glance. A monster's colour tells how
   dangerous it is (green for the weak, then yellow, orange and red). What is remembered but out of sight is drawn at about half the
   brightness. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueLook FINAL:

    /* The 0xRRGGBB number of a colour. */
    METHOD PUBLIC STATIC INTEGER Colour(INPUT poTint AS RogueTint):
        CASE poTint:
            WHEN RogueTint:Background THEN RETURN 0x0B0F14.
            WHEN RogueTint:PanelBack THEN RETURN 0x121923.
            WHEN RogueTint:PanelEdge THEN RETURN 0x5B6578.
            WHEN RogueTint:Text THEN RETURN 0xE8ECF2.
            WHEN RogueTint:Label THEN RETURN 0x8F9BB0.
            WHEN RogueTint:Value THEN RETURN 0xFFFFFF.
            WHEN RogueTint:Dim THEN RETURN 0x56627A.
            WHEN RogueTint:Warn THEN RETURN 0xFFB347.
            WHEN RogueTint:Danger THEN RETURN 0xFF5C5C.
            WHEN RogueTint:Good THEN RETURN 0x7CE3A1.
            WHEN RogueTint:Title THEN RETURN 0xFFD54A.
            WHEN RogueTint:Wall THEN RETURN 0x8E96A6.
            WHEN RogueTint:Floor THEN RETURN 0x6A7690.
            WHEN RogueTint:FloorSeen THEN RETURN 0x3A4358.
            WHEN RogueTint:Door THEN RETURN 0xD9923F.
            WHEN RogueTint:Passage THEN RETURN 0x8C7A5E.
            WHEN RogueTint:Stairs THEN RETURN 0x7CE3A1.
            WHEN RogueTint:Trap THEN RETURN 0xE5484D.
            WHEN RogueTint:Hero THEN RETURN 0xFFFFFF.
            WHEN RogueTint:Gold THEN RETURN 0xFFD54A.
            WHEN RogueTint:Food THEN RETURN 0xB8E07A.
            WHEN RogueTint:Weapon THEN RETURN 0x6FD3F2.
            WHEN RogueTint:Armour THEN RETURN 0x6FA8F2.
            WHEN RogueTint:Potion THEN RETURN 0xE57BE5.
            WHEN RogueTint:Scroll THEN RETURN 0xF4F4F4.
            WHEN RogueTint:Wand THEN RETURN 0x8AF0DC.
            WHEN RogueTint:Ring THEN RETURN 0xFFA040.
            WHEN RogueTint:Amulet THEN RETURN 0xFF4DA6.
            WHEN RogueTint:MonsterLow THEN RETURN 0x9BE29B.
            WHEN RogueTint:MonsterMid THEN RETURN 0xF2D24A.
            WHEN RogueTint:MonsterHigh THEN RETURN 0xF28A3A.
            WHEN RogueTint:MonsterDeadly THEN RETURN 0xF25555.
            OTHERWISE UNDO, THROW NEW GridException("There is no colour called " + STRING(poTint)).
        END CASE.
    END METHOD.

    /* The same colour at about half the brightness, for what is remembered but not in sight. */
    METHOD PUBLIC STATIC INTEGER Faded(INPUT piColour AS INTEGER):
        RETURN ColourMath:Scale(piColour, 50).
    END METHOD.

    /* The colour of a monster of a level: green up to 2, yellow to 5, orange to 9, and red above. */
    METHOD PUBLIC STATIC INTEGER OfMonster(INPUT poKind AS MonsterKind):
        VAR INTEGER level.
        level = Bestiary:Level(poKind).
        IF level <= 2 THEN RETURN Colour(RogueTint:MonsterLow).
        IF level <= 5 THEN RETURN Colour(RogueTint:MonsterMid).
        IF level <= 9 THEN RETURN Colour(RogueTint:MonsterHigh).
        RETURN Colour(RogueTint:MonsterDeadly).
    END METHOD.

    /* The colour of a sort of thing lying about. */
    METHOD PUBLIC STATIC INTEGER OfItem(INPUT poType AS ItemType):
        CASE poType:
            WHEN ItemType:Gold THEN RETURN Colour(RogueTint:Gold).
            WHEN ItemType:Food THEN RETURN Colour(RogueTint:Food).
            WHEN ItemType:Weapon THEN RETURN Colour(RogueTint:Weapon).
            WHEN ItemType:Armour THEN RETURN Colour(RogueTint:Armour).
            WHEN ItemType:Potion THEN RETURN Colour(RogueTint:Potion).
            WHEN ItemType:Scroll THEN RETURN Colour(RogueTint:Scroll).
            WHEN ItemType:Wand THEN RETURN Colour(RogueTint:Wand).
            WHEN ItemType:Ring THEN RETURN Colour(RogueTint:Ring).
            OTHERWISE RETURN Colour(RogueTint:Amulet).
        END CASE.
    END METHOD.

    /* The character of a sort of thing: gold *, food :, weapons ), armour ], potions !, scrolls ?, wands /, rings =, the amulet comma. */
    METHOD PUBLIC STATIC CHARACTER GlyphOfItem(INPUT poType AS ItemType):
        CASE poType:
            WHEN ItemType:Gold THEN RETURN "*".
            WHEN ItemType:Food THEN RETURN ":".
            WHEN ItemType:Weapon THEN RETURN ")".
            WHEN ItemType:Armour THEN RETURN "]".
            WHEN ItemType:Potion THEN RETURN "!".
            WHEN ItemType:Scroll THEN RETURN "?".
            WHEN ItemType:Wand THEN RETURN "/".
            WHEN ItemType:Ring THEN RETURN "=".
            OTHERWISE RETURN ",".
        END CASE.
    END METHOD.

END CLASS.
