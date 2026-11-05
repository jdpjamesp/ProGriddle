/* The picture of Rogue, by pixel: the map with what is seen and what is remembered, things and monsters, the lines of text and the screens. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RoguePainterTests:

    DEFINE PRIVATE VARIABLE mGame     AS RogueGame              NO-UNDO.
    DEFINE PRIVATE VARIABLE mScores   AS RogueScores            NO-UNDO.
    DEFINE PRIVATE VARIABLE mRenderer AS RogueRecordingRenderer NO-UNDO.
    DEFINE PRIVATE VARIABLE mPainter  AS RoguePainter           NO-UNDO.

    /* A started game swept for a lit room with floor (5, 5) to (14, 8), a door at (15, 6) and a passage beyond it, the hero at (6, 6) */
    @Setup.
    METHOD PUBLIC VOID BuildPainter():
        mGame = NEW RogueGame(LevelMap:CreateGrid(), NEW SeededRandom(21)).
        mGame:Initialise().
        mGame:World:ClearLevel().
        mGame:World:CarveRoom(5, 5, 10, 4).
        mGame:World:Cave:SetTerrain(15, 6, Terrain:Door).
        mGame:World:Cave:SetTerrain(16, 6, Terrain:Passage).
        mGame:World:Cave:SetTerrain(17, 6, Terrain:Passage).
        mGame:World:PlaceHero(6, 6).
        mGame:World:Messages:Clear().
        Sight:Look(mGame:World).
        mScores = NEW RogueScores(NEW MemorySettings()).
        mRenderer = NEW RogueRecordingRenderer().
        mPainter = NEW RoguePainter(mRenderer, mGame, mScores).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleasePainter():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        mPainter = ?.
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    METHOD PRIVATE VOID Draw():
        mPainter:Render(mGame:Grid, mGame).
    END METHOD.

    /* How many pixels of a character cell (column, row of the 80 x 24 screen) have a colour. */
    METHOD PRIVATE INTEGER Lit(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = 0 TO 13:
            DO x = 0 TO 7:
                IF mPainter:Canvas:ColourAt(piCol * 8 + x, piRow * 14 + y) = piColour THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    /* How many pixels of a cell are not the background. */
    METHOD PRIVATE INTEGER Painted(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        RETURN 112 - Lit(piCol, piRow, RogueLook:Colour(RogueTint:Background)).
    END METHOD.

    METHOD PRIVATE INTEGER Tint(INPUT poTint AS RogueTint):
        RETURN RogueLook:Colour(poTint).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScreenIsEightyByTwentyFourCharactersOfEightByFourteen():
        Assert:Equals(640, mPainter:Canvas:Width).
        Assert:Equals(336, mPainter:Canvas:Height).
        Assert:IsTrue(mPainter:CanvasGrid:Width = 640).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RenderingHandsTheCanvasToTheWindowsRenderer():
        Draw().
        Assert:Equals(1, mRenderer:RenderCount).
        Assert:IsTrue(mRenderer:LastGrid = mPainter:CanvasGrid).
        Draw().
        Assert:Equals(2, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeroIsAnAtSignOnTheMapRowBelowTheMessageLine():
        Draw().
        Assert:IsTrue(Lit(6, 7, Tint(RogueTint:Hero)) > 8).
        Assert:Equals(0, Lit(7, 7, Tint(RogueTint:Hero))).
        Assert:Equals(0, Lit(6, 6, Tint(RogueTint:Hero))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WallsAreDrawnAsJoinedLinesAndTheFloorAsADot():
        Draw().
        Assert:Equals(28, Lit(4, 7, Tint(RogueTint:Wall))).
        Assert:Equals(16, Lit(8, 5, Tint(RogueTint:Wall))).
        Assert:Equals(4, Lit(8, 7, Tint(RogueTint:Floor))).
        Assert:IsTrue(Lit(4, 5, Tint(RogueTint:Wall)) > 10).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DoorsPassagesAndStairsHaveTheirOwnSigns():
        mGame:World:Cave:SetTerrain(9, 7, Terrain:Stairs).
        Draw().
        Assert:IsTrue(Lit(15, 7, Tint(RogueTint:Door)) > 4).
        Assert:IsTrue(Lit(9, 8, Tint(RogueTint:Stairs)) > 4).
        mGame:World:PlaceHero(17, 6).
        Sight:Look(mGame:World).
        Draw().
        Assert:IsTrue(Lit(16, 7, Tint(RogueTint:Passage)) > 4).
        Assert:IsTrue(Lit(15, 7, RogueLook:Faded(Tint(RogueTint:Door))) > 4).
    END METHOD.
    @Test.
    METHOD PUBLIC VOID WhatIsOutOfSightButRememberedIsDrawnDimAndWhatWasNeverSeenIsNot():
        mGame:World:PlaceHero(17, 6).
        Sight:Look(mGame:World).
        Draw().
        Assert:Equals(4, Lit(8, 7, Tint(RogueTint:FloorSeen))).
        Assert:Equals(0, Lit(8, 7, Tint(RogueTint:Floor))).
        Assert:Equals(0, Painted(30, 11)).
        Assert:Equals(0, Painted(50, 15)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASecretDoorLooksLikeWall():
        mGame:World:Cave:SetTerrain(15, 7, Terrain:SecretDown).
        Sight:Look(mGame:World).
        Draw().
        Assert:Equals(28, Lit(15, 8, Tint(RogueTint:Wall))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFoundTrapIsShownAndAHiddenOneIsNot():
        mGame:World:Cave:SetTrap(9, 6, INTEGER(TrapKind:Arrow) + 1).
        mGame:World:Cave:SetTrap(10, 6, INTEGER(TrapKind:Arrow) + 1).
        mGame:World:Cave:SetTrapFound(10, 6, TRUE).
        Draw().
        Assert:Equals(0, Lit(9, 7, Tint(RogueTint:Trap))).
        Assert:IsTrue(Lit(10, 7, Tint(RogueTint:Trap)) > 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterInSightIsALetterColouredByItsDanger():
        mGame:World:AddMonster(MonsterKind:Orc, 10, 6).
        mGame:World:AddMonster(MonsterKind:Dragon, 12, 7).
        Sight:Look(mGame:World).
        Draw().
        Assert:IsTrue(Lit(10, 7, Tint(RogueTint:MonsterLow)) > 8).
        Assert:IsTrue(Lit(12, 8, Tint(RogueTint:MonsterDeadly)) > 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnInvisibleMonsterIsNotDrawnUntilTheHeroCanSeeIt():
        mGame:World:AddMonster(MonsterKind:Phantom, 10, 6).
        Sight:Look(mGame:World).
        Draw().
        Assert:Equals(4, Painted(10, 7)).
        mGame:World:Hero:SeesInvisible = 10.
        Draw().
        Assert:IsTrue(Painted(10, 7) > 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMonsterOutOfSightIsNotDrawnUnlessSensed():
        mGame:World:Cave:SetTerrain(30, 15, Terrain:Floor).
        mGame:World:AddMonster(MonsterKind:Orc, 30, 15).
        Draw().
        Assert:Equals(0, Painted(30, 16)).
        mGame:World:Hero:SensesMonsters = 5.
        Draw().
        Assert:IsTrue(Painted(30, 16) > 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsAreDrawnWithTheSignOfTheirSortWhereTheHeroCanSee():
        mGame:World:DropOnFloor(Items:Make(ItemType:Potion, 0), 9, 6).
        mGame:World:DropOnFloor(Items:Make(ItemType:Gold, 0), 10, 6).
        Draw().
        Assert:IsTrue(Lit(9, 7, Tint(RogueTint:Potion)) > 4).
        Assert:IsTrue(Lit(10, 7, Tint(RogueTint:Gold)) > 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThingOutOfSightIsNotDrawnUnlessASensingShowsIt():
        mGame:World:Cave:SetTerrain(30, 15, Terrain:Floor).
        mGame:World:Cave:SetSeen(30, 15, TRUE).
        mGame:World:DropOnFloor(Items:Make(ItemType:Scroll, 0), 30, 15).
        Draw().
        Assert:Equals(0, Lit(30, 16, Tint(RogueTint:Scroll))).
        mGame:World:Hero:SensesMagic = 5.
        Draw().
        Assert:IsTrue(Lit(30, 16, Tint(RogueTint:Scroll)) > 4).
        mGame:World:Hero:SensesMagic = 0.
        mGame:World:DropOnFloor(Items:Make(ItemType:Food, 0), 31, 15).
        mGame:World:Cave:SetTerrain(31, 15, Terrain:Floor).
        mGame:World:Hero:SensesFood = 5.
        mGame:World:DropOnFloor(Items:Make(ItemType:Food, 0), 31, 15).
        Draw().
        Assert:IsTrue(Lit(31, 16, Tint(RogueTint:Food)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMessagesOfTheTurnAreOnTheTopRow():
        mGame:Command(".").
        mGame:World:Say("You hit the bat.").
        Draw().
        Assert:IsTrue(Lit(0, 0, Tint(RogueTint:Text)) > 4).
        Assert:IsTrue(Lit(1, 0, Tint(RogueTint:Text)) > 4).
        Assert:Equals(0, Painted(40, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AQuestionReplacesTheMessagesOnTheTopRow():
        mGame:World:Say("You hit the bat.").
        mGame:Command("q").
        Draw().
        Assert:Equals(0, Lit(0, 0, Tint(RogueTint:Text))).
        Assert:IsTrue(Lit(0, 0, Tint(RogueTint:Title)) > 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLinesShowTheNumbersAndHowTheHeroIs():
        Draw().
        Assert:IsTrue(Lit(0, 22, Tint(RogueTint:Label)) > 4).
        Assert:Equals(0, Painted(0, 23)).
        mGame:World:Hero:Nutrition = 200.
        mGame:World:Hero:Confused = 3.
        Draw().
        Assert:IsTrue(Lit(0, 23, Tint(RogueTint:Warn)) > 4).
        mGame:World:Hero:Hp = 2.
        Draw().
        Assert:IsTrue(Painted(20, 22) >= 0).
        mGame:World:Hero:Nutrition = 100.
        Draw().
        Assert:IsTrue(Lit(0, 23, Tint(RogueTint:Danger)) > 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWeakHeroSeesTheirHitPointsInRed():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mGame:World:Hero:Hp = 2.
        Draw().
        DO i = 0 TO 79:
            n = n + Lit(i, 22, Tint(RogueTint:Danger)).
        END.
        Assert:IsTrue(n > 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AskingForAnItemShowsThePackOnItsOwn():
        mGame:Command("q").
        Draw().
        Assert:IsTrue(Lit(11, 1, Tint(RogueTint:Label)) > 4).
        Assert:IsTrue(Painted(14, 1) > 4).
        Assert:IsTrue(Painted(14, 5) > 4).
        Assert:Equals(0, Lit(2, 1, Tint(RogueTint:PanelEdge))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePackScreenListsTheThingsInTheirColoursAndAnyKeyClosesIt():
        mGame:Command("i").
        Draw().
        Assert:IsTrue(Lit(14, 1, Tint(RogueTint:Food)) > 4).
        Assert:IsTrue(Lit(14, 2, Tint(RogueTint:Armour)) > 4).
        Assert:IsTrue(Lit(14, 3, Tint(RogueTint:Weapon)) > 4).
        mGame:Command("x").
        Draw().
        Assert:Equals(0, Lit(14, 1, Tint(RogueTint:Food))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyPackSaysSo():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO 4:
            mGame:World:Pack:Take(i, mGame:World:Pack:At(i):Count).
        END.
        mGame:Command("i").
        Draw().
        Assert:IsTrue(Painted(22, 2) > 0).
        Assert:IsTrue(Lit(20, 1, Tint(RogueTint:PanelEdge)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHelpScreenIsAPanelWithATitle():
        mGame:Command("?").
        Draw().
        Assert:IsTrue(Lit(2, 1, Tint(RogueTint:PanelEdge)) > 0).
        Assert:IsTrue(Lit(5, 1, Tint(RogueTint:Title)) > 0).
        Assert:IsTrue(Lit(5, 4, Tint(RogueTint:Text)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMessagesScreenShowsThePastMessagesOldestFirst():
        mGame:World:Say("First thing.").
        mGame:World:Messages:BeginTurn().
        mGame:World:Say("Second thing.").
        mGame:Command("S-m").
        Draw().
        Assert:IsTrue(Lit(3, 2, Tint(RogueTint:Text)) > 0).
        Assert:IsTrue(Lit(3, 3, Tint(RogueTint:Text)) > 0).
        Assert:Equals(0, Lit(3, 4, Tint(RogueTint:Text))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDiscoveriesScreenSaysWhenThereAreNone():
        mGame:Command("S-d").
        Draw().
        Assert:IsTrue(Lit(22, 2, Tint(RogueTint:Text)) > 0).
        mGame:Command("ESC").
        mGame:World:Names:Learn(ItemType:Potion, 3).
        mGame:Command("S-d").
        Draw().
        Assert:IsTrue(Lit(22, 2, Tint(RogueTint:Text)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeadHeroGetsATombstoneAndTheListOfScores():
        mScores:Add(500, 4, "a bat", FALSE).
        mGame:Command("S-q").
        mGame:Command("y").
        Draw().
        Assert:IsTrue(Lit(17, 1, Tint(RogueTint:Title)) > 0).
        Assert:IsTrue(Lit(27, 4, Tint(RogueTint:Wall)) > 0).
        Assert:IsTrue(Lit(17, 14, Tint(RogueTint:Label)) > 0).
        Assert:IsTrue(Lit(16, 20, Tint(RogueTint:Dim)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHeroWhoGotOutIsAWinner():
        mGame:World:Pack:Add(Items:Amulet()).
        mGame:World:Cave:SetTerrain(6, 6, Terrain:Stairs).
        mGame:Command("<").
        Draw().
        Assert:IsTrue(Lit(22, 3, Tint(RogueTint:Good)) > 0).
        Assert:IsTrue(Lit(17, 1, Tint(RogueTint:Title)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHallucinatingHeroSeesSomeLetterInPlaceOfAMonster():
        mGame:World:AddMonster(MonsterKind:Orc, 10, 6).
        mGame:World:Hero:Hallucinating = 20.
        Sight:Look(mGame:World).
        Draw().
        Assert:IsTrue(Painted(10, 7) > 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APaintedGameThatIsNotRogueIsRefusedAndNothingIsNeededForEither():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mPainter:Render(mGame:Grid, ?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW RoguePainter(?, mGame, mScores).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW RoguePainter(mRenderer, ?, mScores).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW RoguePainter(mRenderer, mGame, ?).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(4, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposingTwiceIsHarmless():
        Draw().
        mPainter:Dispose().
        mPainter:Dispose().
        Assert:IsTrue(TRUE).
    END METHOD.

END CLASS.
