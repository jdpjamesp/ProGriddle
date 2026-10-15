/* The Snake painter, by pixel: the picture is drawn on a canvas of its own, so a test reads the colour of any pixel. The board is
   8 x 8 cells, so the tile is 16 pixels, the strip above the board is 24 high (a narrow board) and the picture is 128 x 152.
   A new game has the snake in row 4, the tail at x 2 and the head at x 4, facing right, with the food at 0, 0, which a test
   usually moves to 5, 1. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakePainterTests:

    DEFINE PRIVATE VARIABLE mGame    AS SnakeGame               NO-UNDO.
    DEFINE PRIVATE VARIABLE mInner   AS SnakeRecordingRenderer  NO-UNDO.
    DEFINE PRIVATE VARIABLE mPainter AS SnakePainter            NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildPainter():
        mGame = NEW SnakeGame(SnakeFactory:CreateGrid(8, 8), NEW ScriptedRandom("0")).
        mGame:Animated = TRUE.
        mInner = NEW SnakeRecordingRenderer().
        mPainter = NEW SnakePainter(mInner, mGame, NEW SeededRandom(3)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleasePainter():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mPainter = ?.
        mGame = ?.
    END METHOD.

    METHOD PRIVATE INTEGER Colour(INPUT poTint AS SnakeTint):
        RETURN SnakeLook:Colour(poTint).
    END METHOD.

    /* Tone piTone (1 to 5) of the colour row of a base colour. */
    METHOD PRIVATE INTEGER Tone(INPUT poBase AS SnakeTint, INPUT piTone AS INTEGER):
        RETURN ColourMath:FromHex(ENTRY(piTone, SnakeLook:ToneRow(Colour(poBase)))).
    END METHOD.

    METHOD PRIVATE INTEGER Px(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN mPainter:Canvas:ColourAt(piX, piY).
    END METHOD.

    /* The picture's x and y of the top left pixel of a cell. */
    METHOD PRIVATE INTEGER CellX(INPUT piCell AS INTEGER):
        RETURN piCell * mPainter:TileSize.
    END METHOD.

    METHOD PRIVATE INTEGER CellY(INPUT piCell AS INTEGER):
        RETURN mPainter:StripHeight + piCell * mPainter:TileSize.
    END METHOD.

    /* How many pixels of a colour there are in a rectangle of the picture. */
    METHOD PRIVATE INTEGER CountOf(INPUT piColour AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = piY TO piY + piH - 1:
            DO x = piX TO piX + piW - 1:
                IF mPainter:Canvas:ColourAt(x, y) = piColour THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    /* How many pixels of a cell do not have the colour a tile gives them (only the pixels that are a tone, 1 to 5). */
    METHOD PRIVATE INTEGER Mismatches(INPUT piCellX AS INTEGER, INPUT piCellY AS INTEGER, INPUT poTile AS Tile, INPUT pcTones AS CHARACTER):
        DEFINE VARIABLE x  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE n  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE ch AS CHARACTER NO-UNDO.
        DO y = 0 TO poTile:Height - 1:
            DO x = 0 TO poTile:Width - 1:
                ch = poTile:PixelAt(x, y).
                IF INDEX("12345", ch) = 0 THEN NEXT.
                IF Px(CellX(piCellX) + x, CellY(piCellY) + y) <> ColourMath:FromHex(ENTRY(INTEGER(ch), pcTones)) THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    METHOD PRIVATE VOID Draw():
        mPainter:Render(mGame:Grid, mGame).
    END METHOD.

    /* Runs n steps, which at the start is 150 ms each. */
    METHOD PRIVATE VOID Steps(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Tick(mGame:StepMs).
        END.
    END METHOD.

    /* ---------------------------------- the picture that stays ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ThePictureIsTheBoardInTilesWithAStripAboveItAndIsHandedToTheWindowsRenderer():
        Assert:Equals(128, mPainter:Canvas:Width).
        Assert:Equals(152, mPainter:Canvas:Height).
        Assert:Equals(16, mPainter:TileSize).
        Assert:Equals(24, mPainter:StripHeight).
        Draw().
        Assert:Equals(1, mInner:RenderCount).
        Assert:IsTrue(mInner:LastGrid = mPainter:CanvasGrid).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePainterNeedsAnInnerRendererAGameAndARandomSource():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW SnakePainter(?, mGame, NEW SeededRandom(3)).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW SnakePainter(mInner, ?, NEW SeededRandom(3)).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW SnakePainter(mInner, mGame, ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePainterOnlyDrawsASnakeGame():
        DEFINE VARIABLE other  AS AnimatedRealTimeGame NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER              NO-UNDO.
        other = NEW AnimatedRealTimeGame(NEW Grid(NEW ArrayStore(3, 3, "s")), 10, 10).
        DO ON ERROR UNDO, THROW:
            mPainter:Render(other:Grid, other).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        other:Dispose().
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFloorIsACheckerboardOfTwoCloseColoursPerCell():
        Draw().
        /* cell 2, 2 is even and cell 3, 2 is odd */
        Assert:Equals(Colour(SnakeTint:FloorA), Px(CellX(2) + 8, CellY(2) + 8)).
        Assert:Equals(Colour(SnakeTint:FloorB), Px(CellX(3) + 8, CellY(2) + 8)).
        Assert:Equals(Colour(SnakeTint:FloorB), Px(CellX(2) + 8, CellY(3) + 8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWallRingIsTwoPixelsOverTheEdgeWithALampInEachCorner():
        Draw().
        Assert:Equals(Colour(SnakeTint:RingHigh), Px(64, 24)).
        Assert:Equals(Colour(SnakeTint:RingLow), Px(64, 25)).
        Assert:Equals(Colour(SnakeTint:RingHigh), Px(64, 151)).
        Assert:Equals(Colour(SnakeTint:RingLow), Px(64, 150)).
        Assert:Equals(Colour(SnakeTint:RingHigh), Px(0, 80)).
        Assert:Equals(Colour(SnakeTint:RingHigh), Px(127, 80)).
        Assert:Equals(Colour(SnakeTint:Lamp), Px(0, 24)).
        Assert:Equals(Colour(SnakeTint:Lamp), Px(1, 25)).
        Assert:Equals(Colour(SnakeTint:Lamp), Px(127, 24)).
        Assert:Equals(Colour(SnakeTint:Lamp), Px(0, 151)).
        Assert:Equals(Colour(SnakeTint:Lamp), Px(126, 150)).
        /* and inside the ring it is the floor */
        Assert:Equals(Colour(SnakeTint:FloorA), Px(2, 26)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStripIsNightWithARuleUnderItAndTheFourLabelsInFourColumns():
        Draw().
        Assert:Equals(Colour(SnakeTint:NightTop), Px(127, 2)).
        Assert:Equals(Colour(SnakeTint:FrameInner), Px(60, 23)).
        Assert:Equals(Colour(SnakeTint:NightTop), Px(60, 22)).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Label), 4, 4, 30, 7) > 0).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Label), 36, 4, 35, 7) > 0).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Label), 68, 4, 30, 7) > 0).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Label), 100, 4, 28, 7) > 0).
        /* the values: the score and the length are text, the level is the accent colour, the best is dim */
        Assert:IsTrue(CountOf(Colour(SnakeTint:Text), 4, 13, 20, 7) > 0).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Text), 36, 13, 20, 7) > 0).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Accent), 68, 13, 20, 7) > 0).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Dim), 100, 13, 20, 7) > 0).
    END METHOD.

    /* ---------------------------------- the snake ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheSnakeIsDrawnAsTailBodyAndHeadFacingEast():
        Draw().
        /* the tail with its body on the east: turned twice; the body between them straight; the head with its eye white and pupil */
        Assert:Equals(0, Mismatches(2, 4, SnakeArt:Tail(16):Turned(2), SnakeLook:ToneRow(Colour(SnakeTint:TailBase)))).
        Assert:Equals(0, Mismatches(3, 4, SnakeArt:BodyStraight(16), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        Assert:Equals(Colour(SnakeTint:Eye), Px(CellX(4) + 8, CellY(4) + 3)).
        Assert:Equals(Colour(SnakeTint:Pupil), Px(CellX(4) + 9, CellY(4) + 4)).
        Assert:Equals(0, Mismatches(4, 4, SnakeArt:Head(16), SnakeLook:ToneRow(Colour(SnakeTint:HeadBase)))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPieceOfALongSnakeIsTurnedToJoinItsNeighbours():
        mGame:StartWith("1,1;2,1;3,1;3,2;3,3;4,3;5,3", "Right").
        Draw().
        /* the tail, body on its east */
        Assert:Equals(0, Mismatches(1, 1, SnakeArt:Tail(16):Turned(2), SnakeLook:ToneRow(Colour(SnakeTint:TailBase)))).
        Assert:Equals(0, Mismatches(2, 1, SnakeArt:BodyStraight(16), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        /* the corner joining west and south */
        Assert:Equals(0, Mismatches(3, 1, SnakeArt:BodyCorner(16):Turned(1), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        /* the vertical straight piece */
        Assert:Equals(0, Mismatches(3, 2, SnakeArt:BodyStraight(16):Turned(1), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        /* the corner joining north and east */
        Assert:Equals(0, Mismatches(3, 3, SnakeArt:BodyCorner(16):Turned(3), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        Assert:Equals(0, Mismatches(4, 3, SnakeArt:BodyStraight(16), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        Assert:Equals(0, Mismatches(5, 3, SnakeArt:Head(16), SnakeLook:ToneRow(Colour(SnakeTint:HeadBase)))).
        /* the other two corners, and a tail with its body to the south */
        mGame:StartWith("3,3;3,4;2,4;2,3", "Up").
        Draw().
        Assert:Equals(0, Mismatches(3, 3, SnakeArt:Tail(16):Turned(3), SnakeLook:ToneRow(Colour(SnakeTint:TailBase)))).
        Assert:Equals(0, Mismatches(3, 4, SnakeArt:BodyCorner(16):Turned(2), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        Assert:Equals(0, Mismatches(2, 4, SnakeArt:BodyCorner(16):Turned(3), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeadFacesTheWayItGoesAndAOneCellSnakeFacesEast():
        mGame:StartWith("2,2;2,3", "Down").
        Draw().
        /* the pupil, at 9, 4 when facing east, is at 11, 9 turned once (facing south) */
        Assert:Equals(Colour(SnakeTint:Pupil), Px(CellX(2) + 11, CellY(3) + 9)).
        mGame:StartWith("2,3;2,2", "Up").
        Draw().
        Assert:Equals(0, Mismatches(2, 2, SnakeArt:Head(16):Turned(3), SnakeLook:ToneRow(Colour(SnakeTint:HeadBase)))).
        mGame:StartWith("4,4", "Right").
        Draw().
        Assert:Equals(0, Mismatches(4, 4, SnakeArt:Head(16), SnakeLook:ToneRow(Colour(SnakeTint:HeadBase)))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStepMovesTheHeadLeavesFloorWhereTheTailWasAndTurnsTheOldHeadIntoBody():
        Draw().
        Steps(1).
        Draw().
        /* the tail was at 2, 4, now floor (even); the tail is now at 3, 4, the old head is body */
        Assert:Equals(Colour(SnakeTint:FloorA), Px(CellX(2) + 8, CellY(4) + 8)).
        Assert:Equals(0, Mismatches(3, 4, SnakeArt:Tail(16):Turned(2), SnakeLook:ToneRow(Colour(SnakeTint:TailBase)))).
        Assert:Equals(0, Mismatches(4, 4, SnakeArt:BodyStraight(16), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        Assert:Equals(0, Mismatches(5, 4, SnakeArt:Head(16), SnakeLook:ToneRow(Colour(SnakeTint:HeadBase)))).
        /* a turn: the old head is now a corner */
        mGame:TurnDown().
        Steps(1).
        Draw().
        Assert:Equals(0, Mismatches(5, 4, SnakeArt:BodyCorner(16):Turned(1), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        Assert:Equals(0, Mismatches(5, 5, SnakeArt:Head(16):Turned(1), SnakeLook:ToneRow(Colour(SnakeTint:HeadBase)))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheSnakeEatsItGrowsAndTheTailStaysWhereItWas():
        mGame:SetFood(5, 4).
        Draw().
        Steps(1).
        Draw().
        Assert:Equals(4, mGame:Length).
        Assert:Equals(0, Mismatches(2, 4, SnakeArt:Tail(16):Turned(2), SnakeLook:ToneRow(Colour(SnakeTint:TailBase)))).
        Assert:Equals(0, Mismatches(4, 4, SnakeArt:BodyStraight(16), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
        Assert:Equals(0, Mismatches(5, 4, SnakeArt:Head(16), SnakeLook:ToneRow(Colour(SnakeTint:HeadBase)))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASnakeAtTheWallLosesASliverOfItsTileToTheRing():
        mGame:StartWith("1,2;0,2", "Left").
        Draw().
        /* the head at 0, 2 on the left edge: the outermost pixel column is the ring, over the head */
        Assert:Equals(Colour(SnakeTint:RingHigh), Px(0, CellY(2) + 8)).
        Assert:Equals(Colour(SnakeTint:RingLow), Px(1, CellY(2) + 8)).
        Assert:IsFalse(Px(2, CellY(2) + 8) = Colour(SnakeTint:RingLow)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTongueIsOutForAHundredMillisecondsInSixHundredWhileItMoves():
        mGame:StartWith("1,4;2,4", "Right").
        mGame:SetFood(5, 1).
        Draw().
        /* at the start the clock is 0, which is in the first 100 ms: the tongue */
        Assert:Equals(Colour(SnakeTint:Tongue), Px(CellX(2) + 15, CellY(4) + 6)).
        mGame:Tick(120).
        Draw().
        Assert:IsFalse(Px(CellX(2) + 15, CellY(4) + 6) = Colour(SnakeTint:Tongue)).
        mGame:Tick(300).
        mGame:Tick(180).
        Draw().
        /* 600 ms: four steps on, the head at 6, 4, and the tongue is out again */
        Assert:Equals(600, mGame:ElapsedMs).
        Assert:Equals(6, mGame:HeadX).
        Assert:Equals(Colour(SnakeTint:Tongue), Px(CellX(6) + 15, CellY(4) + 6)).
    END METHOD.

    /* ---------------------------------- the food ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheFoodGrowsInForAShortTimeThenBeatsThroughFourFrames():
        mGame:SetFood(5, 1).
        Draw().
        /* the first step of its growth: a small disc in the middle of the cell */
        Assert:Equals(Tone(SnakeTint:Apple, 3), Px(CellX(5) + 8, CellY(1) + 8)).
        Assert:Equals(Colour(SnakeTint:FloorA), Px(CellX(5) + 2, CellY(1) + 2)).
        mGame:Tick(160).
        Draw().
        /* a whole apple: its stem at 8, 0 is the stem colour */
        Assert:Equals(Colour(SnakeTint:Stem), Px(CellX(5) + 8, CellY(1) + 3)).
        /* a heartbeat: frame 1 at 120 to 240 ms, frame 2 would be at 240; the apple's outline changes between frames */
        Assert:Equals(0, Mismatches(5, 1, SnakeArt:Food(16, 1), SnakeLook:ToneRow(Colour(SnakeTint:Apple)))).
        mGame:Tick(100).
        Draw().
        Assert:Equals(0, Mismatches(5, 1, SnakeArt:Food(16, 2), SnakeLook:ToneRow(Colour(SnakeTint:Apple)))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryFourthRoundOfTheHeartbeatShowsTheGlint():
        mGame:SetFood(5, 1).
        mGame:Tick(3 * 480).
        Draw().
        /* the clock is 1440 ms: round 3, first frame, so the glint frame replaces frame 0 */
        Assert:Equals(0, Mismatches(5, 1, SnakeArt:Food(16, 3), SnakeLook:ToneRow(Colour(SnakeTint:Apple)))).
    END METHOD.

    /* ---------------------------------- the strip ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID EatingMakesTheScoreGoldForThreeHundredMillisecondsAndTheLengthGrow():
        mGame:SetFood(5, 4).
        Steps(1).
        Draw().
        Assert:IsTrue(CountOf(Colour(SnakeTint:Gold), 4, 13, 20, 7) > 0).
        mGame:Tick(300).
        Draw().
        Assert:Equals(0, CountOf(Colour(SnakeTint:Gold), 4, 13, 20, 7)).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Text), 4, 13, 20, 7) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABestScoreFromBeforeIsShownAndAScoreOverItBlinksNewInGold():
        mGame:BestScore = 200.
        mGame:SetFood(5, 4).
        Steps(1).
        Draw().
        Assert:Equals(0, CountOf(Colour(SnakeTint:Gold), 100, 4, 28, 7)).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Dim), 100, 13, 24, 7) > 0).
        mGame:BestScore = 0.
        Draw().
        /* 150 ms is in the first 300: shown. 300 ms later it is in the second and the plain label is back */
        Assert:IsTrue(CountOf(Colour(SnakeTint:Gold), 100, 4, 28, 7) > 0).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Gold), 100, 13, 24, 7) > 0).
        mGame:Tick(300).
        Draw().
        Assert:Equals(0, CountOf(Colour(SnakeTint:Gold), 100, 4, 28, 7)).
        Assert:IsTrue(CountOf(Colour(SnakeTint:Label), 100, 4, 28, 7) > 0).
    END METHOD.

    /* ---------------------------------- the size of the board ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID ABiggerBoardMakesASmallerTileAndAWiderStripWhenTheBoardIsTwentyAcross():
        SnakeFactory:Rebuild(mGame, 20, 20).
        Draw().
        Assert:Equals(16, mPainter:TileSize).
        Assert:Equals(32, mPainter:StripHeight).
        Assert:Equals(320, mPainter:Canvas:Width).
        Assert:Equals(352, mPainter:Canvas:Height).
        Assert:IsTrue(mInner:LastGrid = mPainter:CanvasGrid).
        /* the rule is two pixels on a wide strip */
        Assert:Equals(Colour(SnakeTint:FrameInner), Px(100, 30)).
        Assert:Equals(Colour(SnakeTint:FrameInner), Px(100, 31)).
        Assert:Equals(Colour(SnakeTint:RingHigh), Px(100, 32)).
        SnakeFactory:Rebuild(mGame, 30, 20).
        Draw().
        Assert:Equals(8, mPainter:TileSize).
        Assert:Equals(24, mPainter:StripHeight).
        Assert:Equals(240, mPainter:Canvas:Width).
        Assert:Equals(24 + 160, mPainter:Canvas:Height).
        /* one pixel of ring on a small tile, then the floor of the odd cell (12, 0) */
        Assert:Equals(Colour(SnakeTint:RingHigh), Px(100, 24)).
        Assert:Equals(Colour(SnakeTint:FloorA), Px(100, 25)).
        Assert:Equals(Colour(SnakeTint:Lamp), Px(0, 24)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSmallTilesAreDrawnWithTheSmallArt():
        SnakeFactory:Rebuild(mGame, 30, 20).
        Draw().
        /* the head in the middle of a 30 x 20 board is at 15, 10 facing east */
        Assert:Equals(0, Mismatches(15, 10, SnakeArt:Head(8), SnakeLook:ToneRow(Colour(SnakeTint:HeadBase)))).
        Assert:Equals(0, Mismatches(14, 10, SnakeArt:BodyStraight(8), SnakeLook:ToneRow(Colour(SnakeTint:BodyBase)))).
    END METHOD.

END CLASS.
