/* The game as a window drives it: tokens in, a world changed. Scenes are made by hand on a game that has been started (a seeded one). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RogueGameTests:

    VAR PRIVATE RogueGame mGame.

    /* A started game whose level is swept away for a lit room: floor (5, 5) to (14, 8), the hero in it at (6, 6), the starting kit */
    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = NEW RogueGame(LevelMap:CreateGrid(), NEW SeededRandom(17)).
        mGame:Initialise().
        mGame:World:ClearLevel().
        mGame:World:CarveRoom(5, 5, 10, 4).
        mGame:World:PlaceHero(6, 6).
        mGame:World:Messages:Clear().
        Sight:Look(mGame:World).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    METHOD PRIVATE Monster Beside(INPUT poKind AS MonsterKind, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR Monster oMonster.
        oMonster = mGame:World:AddMonster(poKind, piX, piY).
        oMonster:Awake = TRUE.
        RETURN oMonster.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameStartsInPlayOnTheFirstLevelWithAWelcome():
        VAR RogueGame oGame = NEW RogueGame(LevelMap:CreateGrid(), NEW SeededRandom(3)).
        oGame:Initialise().
        Assert:Equals("Rogue", oGame:Name).
        Assert:Equals(RogueMode:Play, oGame:Mode).
        Assert:Equals(RogueAction:None, oGame:Action).
        Assert:Equals(RogueOverlay:None, oGame:Showing).
        Assert:Equals("", oGame:Asking).
        Assert:Equals(0, oGame:Turn).
        Assert:Equals(1, oGame:World:Depth).
        Assert:IsFalse(oGame:IsOver).
        Assert:IsTrue(oGame:World:Cave:InView(oGame:World:Hero:X, oGame:World:Hero:Y)).
        Assert:Equals("Hello Rogue. Welcome to the Dungeons of Doom.", oGame:World:Messages:At(0)).
        oGame:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDirectionTokensAreTheNumberPad():
        Assert:Equals(-1, RogueGame:StepX("4")).
        Assert:Equals(1, RogueGame:StepX("6")).
        Assert:Equals(0, RogueGame:StepX("8")).
        Assert:Equals(-1, RogueGame:StepY("7")).
        Assert:Equals(1, RogueGame:StepY("2")).
        Assert:Equals(0, RogueGame:StepY("6")).
        Assert:Equals(1, RogueGame:StepX("3")).
        Assert:Equals(1, RogueGame:StepY("3")).
        Assert:IsTrue(RogueGame:IsDirection("9")).
        Assert:IsFalse(RogueGame:IsDirection("5")).
        Assert:IsFalse(RogueGame:IsDirection("0")).
        Assert:IsFalse(RogueGame:IsDirection("a")).
        Assert:IsFalse(RogueGame:IsDirection("12")).
        Assert:IsFalse(RogueGame:IsDirection(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStepMovesTheHeroAndTakesATurn():
        mGame:Command("6").
        Assert:Equals(7, mGame:World:Hero:X).
        Assert:Equals(6, mGame:World:Hero:Y).
        Assert:Equals(1, mGame:Turn).
        mGame:Command("9").
        Assert:Equals(8, mGame:World:Hero:X).
        Assert:Equals(5, mGame:World:Hero:Y).
        mGame:Command("1").
        Assert:Equals(7, mGame:World:Hero:X).
        Assert:Equals(6, mGame:World:Hero:Y).
        Assert:Equals(3, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStepIntoAWallTakesNoTime():
        mGame:Command("4").
        mGame:Command("4").
        Assert:Equals(5, mGame:World:Hero:X).
        Assert:Equals(1, mGame:Turn).
        mGame:Command("4").
        Assert:Equals(5, mGame:World:Hero:X).
        Assert:Equals(1, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RestingAndSearchingTakeATurnEach():
        mGame:Command(".").
        mGame:Command("5").
        mGame:Command("s").
        Assert:Equals(3, mGame:Turn).
        Assert:Equals(6, mGame:World:Hero:X).
        Assert:IsTrue(INDEX(mGame:World:Messages:Line(200), "You find nothing.") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingIntoAMonsterIsAnAttack():
        VAR Monster oOrc.
        oOrc = Beside(MonsterKind:Orc, 7, 6).
        oOrc:Hp = 500.
        oOrc:MaxHp = 500.
        mGame:Command("6").
        Assert:Equals(6, mGame:World:Hero:X).
        Assert:Equals(1, mGame:Turn).
        Assert:IsTrue(INDEX(mGame:World:Messages:Line(200), "the orc") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMonstersMoveAfterTheHero():
        VAR Monster oOrc.
        oOrc = Beside(MonsterKind:Orc, 14, 6).
        mGame:Command(".").
        Assert:Equals(13, oOrc:X).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WalkingOntoGoldOrAThingPicksItUp():
        VAR Item oGold.
        oGold = Items:Make(ItemType:Gold, 0).
        oGold:Count = 33.
        mGame:World:DropOnFloor(oGold, 7, 6).
        mGame:World:DropOnFloor(Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Spear)), 8, 6).
        mGame:Command("6").
        Assert:Equals(33, mGame:World:Hero:Gold).
        mGame:Command("6").
        Assert:Equals(6, mGame:World:Pack:Count).
        Assert:Equals(0, mGame:World:FloorItemCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APickUpCommandWithNothingThereSaysSo():
        mGame:Command(",").
        Assert:Equals("There is nothing here to pick up.", mGame:World:Messages:At(0)).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADroppedThingCanBePickedUpAgainWithTheCommaKey():
        mGame:Command("d").
        mGame:Command("a").
        Assert:Equals(1, mGame:World:FloorItemCount).
        Assert:Equals(1, mGame:Turn).
        mGame:Command(",").
        Assert:Equals(0, mGame:World:FloorItemCount).
        Assert:Equals(2, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInventoryIsAScreenAnyKeyCloses():
        mGame:Command("i").
        Assert:Equals(RogueMode:Overlay, mGame:Mode).
        Assert:Equals(RogueOverlay:Inventory, mGame:Showing).
        mGame:Command("x").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:Equals(RogueOverlay:None, mGame:Showing).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHelpTheDiscoveriesAndTheMessagesAreScreensToo():
        mGame:Command("?").
        Assert:Equals(RogueOverlay:Help, mGame:Showing).
        mGame:Command("ESC").
        mGame:Command("S-d").
        Assert:Equals(RogueOverlay:Discoveries, mGame:Showing).
        mGame:Command("ESC").
        mGame:Command("S-m").
        Assert:Equals(RogueOverlay:Messages, mGame:Showing).
        mGame:Command("ESC").
        Assert:Equals(RogueMode:Play, mGame:Mode).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID QuaffingAsksWhichPotionAndDrinksIt():
        mGame:World:Pack:Add(Items:Make(ItemType:Potion, INTEGER(PotionKind:GainStrength))).
        mGame:Command("q").
        Assert:Equals(RogueMode:PickItem, mGame:Mode).
        Assert:Equals(RogueAction:Quaff, mGame:Action).
        Assert:IsTrue(INDEX(mGame:Asking, "Quaff what?") > 0).
        mGame:Command("f").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:Equals(17, mGame:World:Hero:Strength).
        Assert:Equals(1, mGame:Turn).
        Assert:Equals("", mGame:Asking).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EscapeGivesUpTheQuestionWithoutATurn():
        mGame:Command("q").
        mGame:Command("ESC").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:Equals(RogueAction:None, mGame:Action).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALetterWithNothingBehindItKeepsAskingAndAnythingElseIsIgnored():
        mGame:Command("q").
        mGame:Command("m").
        Assert:Equals(RogueMode:PickItem, mGame:Mode).
        Assert:Equals("You have nothing like that.", mGame:World:Messages:At(0)).
        mGame:Command("7").
        mGame:Command("?").
        Assert:Equals(RogueMode:PickItem, mGame:Mode).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWrongSortOfThingIsRefusedAndTakesNoTime():
        mGame:Command("q").
        mGame:Command("a").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:Equals(0, mGame:Turn).
        Assert:IsTrue(INDEX(mGame:World:Messages:Line(200), "Yuk!") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EatingTakesATurnAndFillsTheStomach():
        mGame:World:Hero:Nutrition = 400.
        mGame:Command("e").
        mGame:Command("a").
        Assert:Equals(1, mGame:Turn).
        Assert:IsTrue(mGame:World:Hero:Nutrition > 1900).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AskingWithAnEmptyPackSaysSo():
        VAR INTEGER i.
        DO i = 0 TO 4:
            mGame:World:Pack:Take(i, mGame:World:Pack:At(i):Count).
        END.
        mGame:Command("q").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:Equals("You have nothing in your pack.", mGame:World:Messages:At(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WieldingWearingAndRingsGoThroughTheQuestions():
        VAR INTEGER slot.
        slot = mGame:World:Pack:Add(Items:Make(ItemType:Weapon, INTEGER(WeaponKind:Spear))).
        mGame:Command("w").
        mGame:Command("f").
        Assert:Equals(slot, mGame:World:Pack:WieldedSlot).
        mGame:Command("S-t").
        Assert:Equals(-1, mGame:World:Pack:WornSlot).
        mGame:Command("S-w").
        mGame:Command("b").
        Assert:Equals(1, mGame:World:Pack:WornSlot).
        slot = mGame:World:Pack:Add(Items:Make(ItemType:Ring, INTEGER(RingKind:Stealth))).
        mGame:Command("S-p").
        mGame:Command("g").
        Assert:Equals(slot, mGame:World:Pack:LeftRingSlot).
        mGame:Command("S-r").
        Assert:Equals(-1, mGame:World:Pack:LeftRingSlot).
        Assert:Equals(5, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithTwoRingsOnTheGameAsksWhichToTakeOff():
        VAR INTEGER a.
        VAR INTEGER b.
        a = mGame:World:Pack:Add(Items:Make(ItemType:Ring, INTEGER(RingKind:Stealth))).
        b = mGame:World:Pack:Add(Items:Make(ItemType:Ring, INTEGER(RingKind:Searching))).
        Gear:PutOn(mGame:World, a).
        Gear:PutOn(mGame:World, b).
        mGame:Command("S-r").
        Assert:Equals(RogueMode:PickItem, mGame:Mode).
        Assert:Equals(RogueAction:RemoveRing, mGame:Action).
        mGame:Command("g").
        Assert:Equals(-1, mGame:World:Pack:RightRingSlot).
        Assert:Equals(a, mGame:World:Pack:LeftRingSlot).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RemovingARingWithNoneOnSaysSo():
        mGame:Command("S-r").
        Assert:Equals("You have no rings on.", mGame:World:Messages:At(0)).
        Assert:Equals(RogueMode:Play, mGame:Mode).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThrowingAsksForAThingAndThenADirection():
        VAR INTEGER before.
        before = mGame:World:Pack:At(4):Count.
        mGame:Command("t").
        mGame:Command("e").
        Assert:Equals(RogueMode:PickDirection, mGame:Mode).
        Assert:IsTrue(INDEX(mGame:Asking, "direction") > 0).
        mGame:Command("6").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:Equals(before - 1, mGame:World:Pack:At(4):Count).
        Assert:Equals(1, mGame:Turn).
        Assert:IsTrue(VALID-OBJECT(mGame:World:FloorItemAt(14, 6))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnythingButADirectionIsIgnoredWhileAskingForOne():
        mGame:Command("t").
        mGame:Command("e").
        mGame:Command("x").
        mGame:Command("5").
        Assert:Equals(RogueMode:PickDirection, mGame:Mode).
        mGame:Command("ESC").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ZappingAWandAsksForADirectionToo():
        VAR INTEGER slot.
        VAR Monster oOrc.
        slot = mGame:World:Pack:Add(Items:Make(ItemType:Wand, INTEGER(WandKind:SlowMonster))).
        mGame:World:Pack:At(slot):Charges = 3.
        oOrc = Beside(MonsterKind:Orc, 11, 6).
        mGame:Command("z").
        mGame:Command("f").
        mGame:Command("6").
        Assert:IsTrue(oOrc:Slowed > 0).
        Assert:Equals(2, mGame:World:Pack:At(slot):Charges).
        Assert:Equals(1, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScrollOfIdentifyAsksWhatToIdentify():
        VAR INTEGER potion.
        potion = mGame:World:Pack:Add(Items:Make(ItemType:Potion, INTEGER(PotionKind:Healing))).
        mGame:World:Pack:Add(Items:Make(ItemType:Scroll, INTEGER(ScrollKind:Identify))).
        mGame:Command("r").
        mGame:Command("g").
        Assert:Equals(RogueMode:PickItem, mGame:Mode).
        Assert:Equals(RogueAction:Identify, mGame:Action).
        Assert:Equals(1, mGame:Turn).
        mGame:Command("f").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:IsTrue(mGame:World:Names:IsKnown(ItemType:Potion, INTEGER(PotionKind:Healing))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStairsDownTakeTheHeroToTheNextLevel():
        mGame:World:Cave:SetTerrain(6, 6, Terrain:Stairs).
        mGame:Command(">").
        Assert:Equals(2, mGame:World:Depth).
        Assert:Equals(1, mGame:Turn).
        Assert:IsTrue(INDEX(mGame:World:Messages:Line(300), "You descend to level 2.") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoWayDownWhereThereAreNoStairsOrOnTheLastLevel():
        mGame:Command(">").
        Assert:Equals("I see no way down.", mGame:World:Messages:At(0)).
        Assert:Equals(0, mGame:Turn).
        mGame:World:NewLevel(26).
        mGame:World:Cave:SetTerrain(mGame:World:Hero:X, mGame:World:Hero:Y, Terrain:Stairs).
        mGame:Command(">").
        Assert:Equals("You cannot go any deeper.", mGame:World:Messages:At(0)).
        Assert:Equals(26, mGame:World:Depth).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWayUpIsBlockedWithoutTheAmulet():
        mGame:Command("<").
        Assert:Equals("I see no way up.", mGame:World:Messages:At(0)).
        mGame:World:Cave:SetTerrain(6, 6, Terrain:Stairs).
        mGame:Command("<").
        Assert:Equals("Your way is magically blocked.", mGame:World:Messages:At(0)).
        Assert:Equals(1, mGame:World:Depth).
        Assert:IsFalse(mGame:World:Won).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithTheAmuletTheWayUpGoesAUpLevelAtATime():
        mGame:World:NewLevel(5).
        mGame:World:Pack:Add(Items:Amulet()).
        mGame:World:Cave:SetTerrain(mGame:World:Hero:X, mGame:World:Hero:Y, Terrain:Stairs).
        mGame:Command("<").
        Assert:Equals(4, mGame:World:Depth).
        Assert:IsFalse(mGame:World:Won).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LeavingTheDungeonWithTheAmuletWinsTheGame():
        mGame:World:Pack:Add(Items:Amulet()).
        mGame:World:Hero:Gold = 100.
        mGame:World:Cave:SetTerrain(6, 6, Terrain:Stairs).
        mGame:Command("<").
        Assert:IsTrue(mGame:World:Won).
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(RogueMode:Over, mGame:Mode).
        Assert:Equals(RogueOverlay:Tombstone, mGame:Showing).
        Assert:IsTrue(mGame:World:Score > 1100).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeroWhoDiesEndsTheGameAndEnterStartsAnother():
        mGame:World:Hero:Hp = 1.
        Beside(MonsterKind:Dragon, 7, 6).
        mGame:Command(".").
        Assert:IsTrue(mGame:World:Dead).
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(RogueMode:Over, mGame:Mode).
        Assert:Equals(RogueOverlay:Tombstone, mGame:Showing).
        mGame:Command("6").
        Assert:Equals(RogueMode:Over, mGame:Mode).
        mGame:Command("ENTER").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:IsFalse(mGame:World:Dead).
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(1, mGame:World:Depth).
        Assert:Equals(12, mGame:World:Hero:Hp).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID QuittingAsksFirstAndThenEndsTheGameWithTheCauseQuit():
        mGame:Command("S-q").
        Assert:Equals(RogueMode:Confirm, mGame:Mode).
        Assert:IsTrue(INDEX(mGame:Asking, "Really quit?") > 0).
        Assert:IsFalse(mGame:World:Dead).
        mGame:Command("y").
        Assert:IsTrue(mGame:World:Dead).
        Assert:Equals("quit", mGame:World:Cause).
        Assert:IsTrue(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnythingButYesCarriesOnPlaying():
        mGame:Command("S-q").
        mGame:Command("n").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        Assert:Equals("", mGame:Asking).
        Assert:IsFalse(mGame:World:Dead).
        mGame:Command("S-q").
        mGame:Command("ESC").
        Assert:Equals(RogueMode:Play, mGame:Mode).
        mGame:Command("S-q").
        mGame:Command("6").
        Assert:IsFalse(mGame:World:Dead).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeroWhoIsAsleepLosesTurnsUntilAwake():
        mGame:World:Hero:Asleep = 3.
        mGame:Command(".").
        Assert:Equals(4, mGame:Turn).
        Assert:Equals(0, mGame:World:Hero:Asleep).
        Assert:IsTrue(INDEX(mGame:World:Messages:Line(300), "You can move again.") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHastedHeroHasTwoCommandsToEachTurnOfTheMonsters():
        VAR Monster oOrc.
        oOrc = Beside(MonsterKind:Orc, 14, 8).
        mGame:World:Hero:Hasted = 10.
        mGame:Command(".").
        Assert:Equals(14, oOrc:X).
        Assert:Equals(0, mGame:Turn).
        mGame:Command(".").
        Assert:Equals(13, oOrc:X).
        Assert:Equals(1, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABearTrapHoldsTheHeroForSomeSteps():
        mGame:World:Hero:Stuck = 2.
        mGame:Command("6").
        Assert:Equals(6, mGame:World:Hero:X).
        Assert:Equals(1, mGame:World:Hero:Stuck).
        mGame:Command("6").
        mGame:Command("6").
        Assert:Equals(7, mGame:World:Hero:X).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeroHeldByAMonsterCannotWalkAway():
        VAR Monster oPlant.
        oPlant = Beside(MonsterKind:VenusFlytrap, 7, 6).
        mGame:World:Hero:HeldBy = oPlant.
        mGame:Command("4").
        Assert:Equals(6, mGame:World:Hero:X).
        Assert:IsTrue(INDEX(mGame:World:Messages:Line(300), "You are being held.") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SteppingOnAHiddenTrapSpringsIt():
        mGame:World:Cave:SetTrap(7, 6, INTEGER(TrapKind:SleepingGas) + 1).
        mGame:Command("6").
        Assert:IsTrue(mGame:World:Cave:TrapFound(7, 6)).
        Assert:IsTrue(INDEX(mGame:World:Messages:Line(300), "sleeping gas") > 0).
        Assert:IsTrue(mGame:Turn > 1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALevitatingHeroFloatsOverATrap():
        mGame:World:Cave:SetTrap(7, 6, INTEGER(TrapKind:BearTrap) + 1).
        mGame:World:Hero:Levitating = 10.
        mGame:Command("6").
        Assert:IsFalse(mGame:World:Cave:TrapFound(7, 6)).
        Assert:Equals(0, mGame:World:Hero:Stuck).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATrapDoorDropsTheHeroToTheNextLevel():
        mGame:World:Cave:SetTrap(7, 6, INTEGER(TrapKind:TrapDoor) + 1).
        mGame:Command("6").
        Assert:Equals(2, mGame:World:Depth).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RunningGoesAcrossTheRoomAndStopsAtTheWall():
        mGame:Command("run6").
        Assert:Equals(14, mGame:World:Hero:X).
        Assert:Equals(8, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RunningStopsWhenAMonsterComesIntoView():
        VAR Monster oOrc.
        mGame:World:Cave:SetTerrain(15, 6, Terrain:Door).
        mGame:World:Cave:SetTerrain(16, 6, Terrain:Passage).
        oOrc = Beside(MonsterKind:Orc, 12, 8).
        mGame:Command("run6").
        Assert:IsTrue(mGame:World:Hero:X < 14).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RunningStopsInADoorway():
        mGame:World:Cave:SetTerrain(15, 6, Terrain:Door).
        mGame:World:Cave:SetTerrain(16, 6, Terrain:Passage).
        mGame:Command("run6").
        Assert:Equals(15, mGame:World:Hero:X).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RunningStopsToPickUpAThing():
        mGame:World:DropOnFloor(Items:Make(ItemType:Potion, 1), 9, 6).
        mGame:Command("run6").
        Assert:Equals(9, mGame:World:Hero:X).
        Assert:Equals(6, mGame:World:Pack:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RunningAgainstAWallIsNoTime():
        mGame:Command("run4").
        Assert:Equals(5, mGame:World:Hero:X).
        mGame:Command("run4").
        Assert:Equals(1, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHungerStateFollowsTheStomach():
        Assert:Equals(Hunger:Satisfied, mGame:HungerState).
        mGame:World:Hero:Nutrition = 200.
        Assert:Equals(Hunger:Hungry, mGame:HungerState).
        mGame:World:Hero:Nutrition = 100.
        Assert:Equals(Hunger:Weak, mGame:HungerState).
        mGame:World:Hero:Nutrition = 20.
        Assert:Equals(Hunger:Faint, mGame:HungerState).
        mGame:World:Hero:Nutrition = 0.
        Assert:Equals(Hunger:Starved, mGame:HungerState).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATokenThatMeansNothingChangesNothing():
        mGame:Command("").
        mGame:Command(?).
        mGame:Command("x").
        mGame:Command("ESC").
        mGame:Command("S-z").
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(RogueMode:Play, mGame:Mode).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AConfusedHeroSometimesStaggersTheWrongWay():
        VAR INTEGER i.
        VAR INTEGER moved.
        mGame:World:Hero:Confused = 500.
        DO i = 1 TO 12:
            mGame:Command(".").
        END.
        mGame:World:PlaceHero(10, 7).
        DO i = 1 TO 20:
            mGame:World:PlaceHero(10, 7).
            mGame:Command("6").
            IF mGame:World:Hero:Y <> 7 OR mGame:World:Hero:X <> 11 THEN moved = moved + 1.
        END.
        Assert:IsTrue(moved > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameCanBeDisposedAndTheGridGoesWithIt():
        VAR RogueGame oGame = NEW RogueGame(LevelMap:CreateGrid(), NEW SeededRandom(2)).
        oGame:Initialise().
        oGame:Dispose().
        Assert:IsTrue(TRUE).
    END METHOD.

END CLASS.
