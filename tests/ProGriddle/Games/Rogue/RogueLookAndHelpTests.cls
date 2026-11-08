/* The colours, the characters of things, and the words of the help and discovery screens. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueLookAndHelpTests:

    @Test.
    METHOD PUBLIC VOID EveryTintHasAColourAndTheyAreNotAllTheSame():
        VAR INTEGER i.
        VAR INTEGER c.
        VAR INTEGER unlike.
        DO i = 0 TO 31:
            c = RogueLook:Colour(RogueTint:GetEnum(i)).
            Assert:IsTrue(c >= 0 AND c <= 16777215).
            IF i > 0 AND c <> RogueLook:Colour(RogueTint:GetEnum(i - 1)) THEN unlike = unlike + 1.
        END.
        Assert:IsTrue(unlike >= 28).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBackgroundIsDarkAndTheTextIsLight():
        Assert:IsTrue(ColourSum(RogueLook:Colour(RogueTint:Background)) < 100).
        Assert:IsTrue(ColourSum(RogueLook:Colour(RogueTint:Text)) > 600).
    END METHOD.

    METHOD PRIVATE INTEGER ColourSum(INPUT piColour AS INTEGER):
        RETURN INTEGER(TRUNCATE(piColour / 65536, 0)) + INTEGER(TRUNCATE(piColour / 256, 0)) MODULO 256 + piColour MODULO 256.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatIsRememberedIsDrawnAtHalfBrightness():
        Assert:Equals(0x808080, RogueLook:Faded(0xFFFFFF)).
        Assert:Equals(0, RogueLook:Faded(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterIsColouredByHowDangerousItIs():
        Assert:Equals(RogueLook:Colour(RogueTint:MonsterLow), RogueLook:OfMonster(MonsterKind:Bat)).
        Assert:Equals(RogueLook:Colour(RogueTint:MonsterMid), RogueLook:OfMonster(MonsterKind:Centaur)).
        Assert:Equals(RogueLook:Colour(RogueTint:MonsterHigh), RogueLook:OfMonster(MonsterKind:Vampire)).
        Assert:Equals(RogueLook:Colour(RogueTint:MonsterDeadly), RogueLook:OfMonster(MonsterKind:Dragon)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachSortOfThingHasItsCharacterAndColour():
        Assert:Equals("*", RogueLook:GlyphOfItem(ItemType:Gold)).
        Assert:Equals(":", RogueLook:GlyphOfItem(ItemType:Food)).
        Assert:Equals(")", RogueLook:GlyphOfItem(ItemType:Weapon)).
        Assert:Equals("]", RogueLook:GlyphOfItem(ItemType:Armour)).
        Assert:Equals("!", RogueLook:GlyphOfItem(ItemType:Potion)).
        Assert:Equals("?", RogueLook:GlyphOfItem(ItemType:Scroll)).
        Assert:Equals("/", RogueLook:GlyphOfItem(ItemType:Wand)).
        Assert:Equals("=", RogueLook:GlyphOfItem(ItemType:Ring)).
        Assert:Equals(",", RogueLook:GlyphOfItem(ItemType:Amulet)).
        Assert:Equals(RogueLook:Colour(RogueTint:Gold), RogueLook:OfItem(ItemType:Gold)).
        Assert:Equals(RogueLook:Colour(RogueTint:Potion), RogueLook:OfItem(ItemType:Potion)).
        Assert:Equals(RogueLook:Colour(RogueTint:Amulet), RogueLook:OfItem(ItemType:Amulet)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHelpMentionsTheKeysAndFitsTheScreen():
        VAR CHARACTER lines.
        VAR INTEGER i.
        lines = RogueHelp:Text().
        Assert:IsTrue(INDEX(lines, "quaff") > 0).
        Assert:IsTrue(INDEX(lines, "Amulet of Yendor") > 0).
        Assert:IsTrue(NUM-ENTRIES(lines, CHR(10)) <= 20).
        DO i = 1 TO NUM-ENTRIES(lines, CHR(10)):
            Assert:IsTrue(LENGTH(ENTRY(i, lines, CHR(10))) <= 72).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDiscoveriesListWhatTheHeroHasLearnt():
        VAR RogueWorld oWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW SeededRandom(4)).
        Assert:Equals("", RogueHelp:Discoveries(oWorld)).
        oWorld:Names:Learn(ItemType:Potion, INTEGER(PotionKind:Healing)).
        oWorld:Names:Learn(ItemType:Scroll, INTEGER(ScrollKind:Identify)).
        oWorld:Names:Learn(ItemType:Wand, INTEGER(WandKind:Fire)).
        oWorld:Names:Learn(ItemType:Ring, INTEGER(RingKind:Stealth)).
        Assert:Equals("potion of healing" + CHR(10) + "scroll of identify" + CHR(10) + "wand of fire" + CHR(10) + "ring of stealth", RogueHelp:Discoveries(oWorld)).
        oWorld:Dispose().
    END METHOD.

END CLASS.
