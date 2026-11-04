/* The picture of FOR EACH, looked at pixel by pixel: the strips, the baked maze and its bits (and a bit taken off when it is eaten), the
   characters, the words of each phase, the flash after a level, the title, the crash and the cartoons. A game and a painter are built on the real maze or on
   a small one, the game is driven to the moment under test, and the canvas the painter draws is read back. Positions are canvas pixels, the
   maze starting 24 pixels down. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachPainterTests:

    DEFINE PRIVATE VARIABLE mGame    AS ForEachGame              NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpy     AS ForEachRecordingRenderer NO-UNDO.
    DEFINE PRIVATE VARIABLE mPainter AS ForEachPainter           NO-UNDO.

    @TearDown.
    METHOD PUBLIC VOID ReleaseAll():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mPainter = ?.
        mGame = ?.
    END METHOD.

    /* A painter on a game on the real maze, or on a maze given as text. */
    METHOD PRIVATE VOID Build(INPUT pcMaze AS CHARACTER):
        mGame = (IF pcMaze = "" THEN ForEachFactory:Create(NEW SeededRandom(7)) ELSE ForEachKit:GameOn(pcMaze)).
        mSpy = NEW ForEachRecordingRenderer().
        mPainter = NEW ForEachPainter(mSpy, mGame).
    END METHOD.

    METHOD PRIVATE INTEGER Look(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN mPainter:Canvas:ColourAt(piX, piY).
    END METHOD.

    /* How many pixels of a rectangle of the canvas are this colour. */
    METHOD PRIVATE INTEGER Count(INPUT piColour AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = piY TO piY + piH - 1:
            DO x = piX TO piX + piW - 1:
                IF Look(x, y) = piColour THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    /* How many pixels of a rectangle are not the floor colour. */
    METHOD PRIVATE INTEGER Busy(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        RETURN piW * piH - Count(ForEachLook:Colour(ForEachTint:Floor), piX, piY, piW, piH).
    END METHOD.

    /* How many pixels of a rectangle are in any of the five tones of a colour row: how much of a character in that row is there. */
    METHOD PRIVATE INTEGER Tones(INPUT poRow AS ForEachRow, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO k = 1 TO 5:
            n = n + Count(ForEachLook:Tone(poRow, k), piX, piY, piW, piH).
        END.
        RETURN n.
    END METHOD.

    METHOD PRIVATE INTEGER Tint(INPUT poTint AS ForEachTint):
        RETURN ForEachLook:Colour(poTint).
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        DEFINE VARIABLE other AS ForEachPainter NO-UNDO.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN other = NEW ForEachPainter(?, mGame).
                WHEN 2 THEN other = NEW ForEachPainter(mSpy, ?).
                WHEN 3 THEN mPainter:Render(mGame:Grid, ?).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    /* ---------------------------------- building ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ThePictureIs224By288ForTheRealMaze():
        Build("").
        Assert:Equals(224, mPainter:Canvas:Width).
        Assert:Equals(288, mPainter:Canvas:Height).
        Assert:Equals(224, mPainter:CanvasGrid:Width).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APainterNeedsARendererAndAGameAndOnlyDrawsAForEachGame():
        Build("").
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RenderHandsThePictureOnceToTheWindowsRenderer():
        Build("").
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(1, mSpy:RenderCount).
        Assert:IsTrue(mSpy:LastGrid = mPainter:CanvasGrid).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeCanBeCalledTwice():
        Build("").
        mPainter:Render(mGame:Grid, mGame).
        mPainter:Dispose().
        mPainter:Dispose().
        Assert:IsTrue(TRUE).
    END METHOD.

    /* ---------------------------------- the maze ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheMazeHasItsFloorStudsItsWallLinesAndItsBits():
        Build("").
        ForEachKit:Play(mGame).
        mPainter:Render(mGame:Grid, mGame).
        /* the stud at the corner of a lane tile, a bit in the first lane (tile 1, 1), a line in the border wall */
        Assert:Equals(Tint(ForEachTint:FloorStud), Look(8, 24 + 8)).
        Assert:Equals(Tint(ForEachTint:Bit), Look(8 + 3, 24 + 8 + 3)).
        Assert:Equals(Tint(ForEachTint:Bit), Look(8 + 4, 24 + 8 + 4)).
        Assert:IsTrue(Count(Tint(ForEachTint:Line), 0, 24, 224, 248) > 500).
        Assert:IsTrue(Count(Tint(ForEachTint:Bit), 0, 24, 224, 248) >= 240 * 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTunnelFloorIsAShadeLighterAndTheDoorIsGoldAndBlack():
        Build("").
        ForEachKit:Play(mGame).
        mPainter:Render(mGame:Grid, mGame).
        /* row 14 starts as tunnel lane, and the door is in tiles 13 and 14 of row 12, in its rows 3 and 4 */
        Assert:IsTrue(Count(Tint(ForEachTint:Tunnel), 0, 24 + 14 * 8, 40, 8) > 40).
        Assert:IsTrue(Count(Tint(ForEachTint:Door), 13 * 8, 24 + 12 * 8, 16, 8) > 8).
        Assert:IsTrue(Count(Tint(ForEachTint:DoorShade), 13 * 8, 24 + 12 * 8, 16, 8) > 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABitThatIsEatenIsPaintedBackToTheFloor():
        Build("").
        ForEachKit:Play(mGame).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Tint(ForEachTint:Bit), Look(8 + 3, 24 + 8 + 3)).
        mGame:EatBits(1).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Tint(ForEachTint:Floor), Look(8 + 3, 24 + 8 + 3)).
        Assert:Equals(Tint(ForEachTint:Floor), Look(8 + 4, 24 + 8 + 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewLevelPutsEveryBitBack():
        Build("").
        ForEachKit:Play(mGame).
        mGame:EatBits(30).
        mPainter:Render(mGame:Grid, mGame).
        mGame:StartLevel(2).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:Bit), 0, 24, 224, 248) >= 240 * 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCommitTokensBlink():
        DEFINE VARIABLE lit AS INTEGER NO-UNDO.
        DEFINE VARIABLE dim AS INTEGER NO-UNDO.
        Build("").
        ForEachKit:Play(mGame).
        mPainter:Render(mGame:Grid, mGame).
        lit = Count(Tint(ForEachTint:Token), 8, 24 + 3 * 8, 8, 8).
        ForEachKit:Frames(mGame, 10).
        mPainter:Render(mGame:Grid, mGame).
        dim = Count(Tint(ForEachTint:Token), 8, 24 + 3 * 8, 8, 8).
        Assert:IsTrue(lit > 0).
        Assert:IsTrue(lit <> dim).
    END METHOD.

    /* ---------------------------------- the characters ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID DibbyAndTheFirstPhantomAreDrawnWhereTheyStand():
        Build("").
        ForEachKit:Play(mGame).
        mPainter:Render(mGame:Grid, mGame).
        /* Dibby at (112, 188) and Mary at (112, 92) in the maze: a drum and a wisp, in their colours */
        Assert:IsTrue(Tones(ForEachRow:Dibby, 104, 24 + 180, 16, 16) > 40).
        Assert:IsTrue(Tones(ForEachRow:Mary, 104, 24 + 84, 16, 16) > 40).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoCharactersAreDrawnWhileTheMazeIsBuildingAtTheStartOfAGame():
        Build("").
        mGame:StartGame().
        ForEachKit:Frames(mGame, 10).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, Tones(ForEachRow:Dibby, 104, 24 + 180, 16, 16)).
        ForEachKit:Frames(mGame, 120).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Tones(ForEachRow:Dibby, 104, 24 + 180, 16, 16) > 40).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomRolledBackIsBlueAndOneRunningHomeIsOnlyEyes():
        Build("").
        ForEachKit:Play(mGame).
        mGame:Rollback().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Tones(ForEachRow:Rollback, 96, 24 + 76, 32, 32) > 40).
        mGame:PlacePhantom(PhantomKind:Mary, 112, 92, MazeDir:Left, PhantomMode:Returning).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, Tones(ForEachRow:Rollback, 104, 24 + 84, 16, 16)).
        Assert:IsTrue(Count(Tint(ForEachTint:Eye), 104, 24 + 84, 16, 16) > 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomsEyesLookTheWayItGoesAndItsMarkIsDrawnOverThem():
        DEFINE VARIABLE left  AS INTEGER NO-UNDO.
        DEFINE VARIABLE right AS INTEGER NO-UNDO.
        Build("").
        ForEachKit:Play(mGame).
        mGame:PlacePhantom(PhantomKind:Brian, 80, 92, MazeDir:Left, PhantomMode:Scatter).
        mPainter:Render(mGame:Grid, mGame).
        left = Count(Tint(ForEachTint:Pupil), 72, 24 + 84, 4, 16).
        mGame:PlacePhantom(PhantomKind:Brian, 80, 92, MazeDir:Right, PhantomMode:Scatter).
        mPainter:Render(mGame:Grid, mGame).
        right = Count(Tint(ForEachTint:Pupil), 72, 24 + 84, 4, 16).
        Assert:IsTrue(left > right).
        /* Brian's glasses are in Ink */
        Assert:IsTrue(Count(Tint(ForEachTint:Ink), 72, 24 + 84, 16, 16) > 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MaryGetsAngryEyesInHerSecondStage():
        Build("").
        ForEachKit:Play(mGame).
        mGame:SetRage(1).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, Count(Tint(ForEachTint:Angry), 104, 24 + 84, 16, 16)).
        mGame:SetRage(2).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:Angry), 104, 24 + 84, 16, 16) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACharacterInTheTunnelIsDrawnAtBothEdgesAsItLeaves():
        Build(ForEachKit:TunnelCorridor()).
        ForEachKit:Play(mGame).
        mGame:PlaceDibby(2, 12, MazeDir:Left).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Tones(ForEachRow:Dibby, 0, 24, 12, 16) > 8).
        Assert:IsTrue(Tones(ForEachRow:Dibby, 148, 24, 12, 16) > 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBonusItemAndItsPopUpAreDrawn():
        Build(ForEachKit:ItemCorridor()).
        ForEachKit:Play(mGame).
        mGame:ShowItem().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Busy(16, 24 + 4, 16, 16) > 40).
        mGame:PlaceDibby(34, 12, MazeDir:Left).
        ForEachKit:Frames(mGame, 6).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:PopItem), 0, 24, 40, 20) > 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomEatenShowsItsPoints():
        Build(ForEachKit:ClosedCorridor()).
        ForEachKit:Play(mGame).
        mGame:PlacePhantom(PhantomKind:Mary, 80, 12, MazeDir:Right, PhantomMode:Chase).
        mGame:Rollback().
        mGame:PlaceDibby(80, 12, MazeDir:Left).
        mGame:Advance().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:PopPhantom), 60, 24, 40, 20) > 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDebugOverlayMarksTheTargetOfEachPhantomInItsColourWhenSwitchedOn():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        Build("").
        ForEachKit:Play(mGame).
        mGame:SwitchWave().
        mPainter:Render(mGame:Grid, mGame).
        before = Count(Tint(ForEachTint:Target), 0, 0, 224, 288).
        mGame:ShowTargets = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:Target), 0, 0, 224, 288) > before).
    END METHOD.

    /* ---------------------------------- words and strips ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheStripsShowTheScoreTheBestScoreAndTheLives():
        Build("").
        ForEachKit:Play(mGame).
        mGame:AddScore(1230).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:Text), 20, 9, 44, 7) > 10).
        Assert:IsTrue(Count(Tint(ForEachTint:LabelText), 82, 1, 60, 7) > 0 OR Count(Tint(ForEachTint:Player), 82, 1, 60, 7) > 0).
        /* two spare lives show as two small drums in the strip below */
        Assert:IsTrue(Busy(14, 273, 40, 14) > 40).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OneUPBlinksWhileAGameIsOn():
        DEFINE VARIABLE lit AS LOGICAL NO-UNDO.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        Build("").
        ForEachKit:Play(mGame).
        mPainter:Render(mGame:Grid, mGame).
        lit = Count(Tint(ForEachTint:Player), 24, 1, 20, 7) > 0.
        ForEachKit:Frames(mGame, 16).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(lit <> (Count(Tint(ForEachTint:Player), 24, 1, 20, 7) > 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReadyAndPlayerOneShowAfterTheMazeHasBuilt():
        Build("").
        mGame:StartGame().
        ForEachKit:Frames(mGame, 60).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, Count(Tint(ForEachTint:Player), 80, 24 + 136, 60, 8)).
        ForEachKit:Frames(mGame, 20).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:Player), 80, 24 + 136, 60, 8) > 10).
        Assert:IsTrue(Count(Tint(ForEachTint:PopPhantom), 60, 24 + 88, 100, 8) > 10).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID GameOverShowsInRedAndANewBestScoreSaysSo():
        Build("").
        ForEachKit:Play(mGame).
        mGame:Lives = 1.
        mGame:PlacePhantom(PhantomKind:Mary, mGame:DibbyX, mGame:DibbyY, MazeDir:Left, PhantomMode:Chase).
        ForEachKit:RunUntil(mGame, ForEachPhase:GameOver, 900).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:Over), 70, 24 + 136, 90, 8) > 10).
        mGame:AddScore(500).
        ForEachKit:Frames(mGame, 100).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:Player), 60, 24 + 136, 110, 8) > 10).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PausedShowsItsWordOverTheMazeAndNothingElseChanges():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Build("").
        ForEachKit:Play(mGame).
        mGame:Paused = TRUE.
        DO n = 1 TO 2:
            mPainter:Render(mGame:Grid, mGame).
            IF Count(Tint(ForEachTint:Player), 90, 24 + 136, 50, 8) > 10 THEN LEAVE.
            ForEachKit:Frames(mGame, 32).
        END.
        Assert:IsTrue(Count(Tint(ForEachTint:Player), 90, 24 + 136, 50, 8) > 10).
    END METHOD.

    /* ---------------------------------- the other pictures ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheTitleShowsTheNameTheGiantDibbyAndThePlainFloor():
        Build("").
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Busy(60, 30, 100, 40) > 200).
        Assert:IsTrue(Tones(ForEachRow:Dibby, 170, 38, 32, 32) > 100).
        /* the maze is not there: no wall line in the middle of the picture */
        Assert:Equals(0, Count(Tint(ForEachTint:Line), 0, 100, 224, 100)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRollCallBringsInTheFourPhantomsOneByOne():
        Build("").
        ForEachKit:Frames(mGame, 100).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Tones(ForEachRow:Mary, 18, 103, 16, 16) > 40).
        Assert:Equals(0, Tones(ForEachRow:Chip, 18, 169, 16, 16)).
        ForEachKit:Frames(mGame, 240).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Tones(ForEachRow:Chip, 18, 169, 16, 16) > 40).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleGoesOnToThePointsAndTheChase():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Build("").
        ForEachKit:Frames(mGame, 400).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:Bit), 77, 202, 2, 2) = 4).
        ForEachKit:Frames(mGame, 100).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Busy(0, 240, 224, 20) > 40).
        ForEachKit:Frames(mGame, 1200).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(TRUE).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCrashPlaysThroughItsFramesAndEndsWithThePop():
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        Build("").
        ForEachKit:Play(mGame).
        mGame:PlacePhantom(PhantomKind:Mary, mGame:DibbyX, mGame:DibbyY, MazeDir:Left, PhantomMode:Chase).
        mGame:Advance().
        mPainter:Render(mGame:Grid, mGame).
        /* caught: Dibby stands in the maze and the phantoms are gone */
        Assert:IsTrue(Tones(ForEachRow:Dibby, 104, 24 + 180, 16, 16) > 40).
        Assert:Equals(0, Tones(ForEachRow:Mary, 96, 24 + 84, 32, 16)).
        ForEachKit:RunUntil(mGame, ForEachPhase:Dying, 100).
        DO n = 1 TO 100:
            mGame:Advance().
            mPainter:Render(mGame:Grid, mGame).
        END.
        Assert:IsTrue(TRUE).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMazeFlashesWhiteAfterTheLastBitAndComesBack():
        Build(ForEachKit:FewBits()).
        ForEachKit:Play(mGame).
        ForEachKit:RunUntil(mGame, ForEachPhase:Cleared, 200).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, Count(Tint(ForEachTint:FlashGlow), 0, 24, 160, 24)).
        ForEachKit:Frames(mGame, 62).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Count(Tint(ForEachTint:FlashGlow), 0, 24, 160, 24) > 100).
        ForEachKit:Frames(mGame, 12).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, Count(Tint(ForEachTint:FlashGlow), 0, 24, 160, 24)).
        Assert:IsTrue(Count(Tint(ForEachTint:Line), 0, 24, 160, 24) > 100).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachOfTheThreeCartoonsDrawsWithoutHarmFromStartToEnd():
        DEFINE VARIABLE act AS INTEGER NO-UNDO.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DO act = 1 TO 3:
            Build(ForEachKit:FewBits()).
            ForEachKit:Play(mGame).
            mGame:StartLevel(IF act = 1 THEN 2 ELSE IF act = 2 THEN 5 ELSE 9).
            ForEachKit:RunUntil(mGame, ForEachPhase:Playing, 900).
            ForEachKit:RunUntil(mGame, ForEachPhase:Cleared, 200).
            ForEachKit:RunUntil(mGame, ForEachPhase:Intermission, 900).
            Assert:Equals(act, mGame:IntermissionAct).
            DO n = 1 TO 300 BY 10:
                ForEachKit:Frames(mGame, 10).
                mPainter:Render(mGame:Grid, mGame).
            END.
            Assert:IsTrue(Busy(0, 24, 160, 40) >= 0).
            mPainter:Dispose().
            mGame:Dispose().
            mPainter = ?.
            mGame = ?.
        END.
    END METHOD.

END CLASS.
