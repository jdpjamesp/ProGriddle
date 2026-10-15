/* The painter of Tetris: it reads the game and draws the picture in the "Lantern Glass" look on a canvas of its own, then hands
   that canvas to the window's renderer. The canvas is 17 x 20 cells of 16 pixels: the well, a divider and the panel. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisPainterTests:

    DEFINE PRIVATE VARIABLE mGame    AS TetrisGame             NO-UNDO.
    DEFINE PRIVATE VARIABLE mInner   AS GridRecordingRenderer  NO-UNDO.
    DEFINE PRIVATE VARIABLE mPainter AS TetrisPainter          NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildPainter():
        mGame = TetrisFactory:Create(NEW SeededRandom(1)).
        mGame:StartWith("I,O,T,S,Z,J,L").
        mInner = NEW GridRecordingRenderer().
        mPainter = NEW TetrisPainter(mInner, mGame, NEW SeededRandom(3)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleasePainter():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mPainter = ?.
        mGame = ?.
    END METHOD.

    METHOD PRIVATE INTEGER Colour(INPUT poTint AS Tint):
        RETURN TetrisLook:Colour(poTint).
    END METHOD.

    /* The colour of tone piTone (1 to 5) of a colour row. */
    METHOD PRIVATE INTEGER Tone(INPUT piRow AS INTEGER, INPUT piTone AS INTEGER):
        RETURN ColourMath:FromHex(ENTRY(piTone, TetrisLook:Tones(piRow))).
    END METHOD.

    METHOD PRIVATE INTEGER Px(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN mPainter:Canvas:ColourAt(piX, piY).
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

    /* The floor colour of row r. */
    METHOD PRIVATE INTEGER Floor(INPUT piRow AS INTEGER):
        RETURN ColourMath:Mix(Colour(Tint:FloorTop), Colour(Tint:FloorBottom), piRow, 19).
    END METHOD.

    METHOD PRIVATE VOID Draw():
        mPainter:Render(mGame:Grid, mGame).
    END METHOD.

    /* ---------------------------------- the canvas ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheCanvasIsSeventeenByTwentyCellsOfSixteenPixelsAndIsHandedToTheWindowsRenderer():
        Assert:Equals(272, mPainter:Canvas:Width).
        Assert:Equals(320, mPainter:Canvas:Height).
        Draw().
        Assert:Equals(1, mInner:RenderCount).
        Assert:IsTrue(mInner:LastGrid = mPainter:CanvasGrid).
        Assert:Equals(272, mInner:LastGrid:Width).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePainterNeedsAnInnerRendererAGameAndARandomSource():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW TetrisPainter(?, mGame, NEW SeededRandom(3)).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW TetrisPainter(mInner, ?, NEW SeededRandom(3)).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW TetrisPainter(mInner, mGame, ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePainterOnlyDrawsATetrisGame():
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

    /* ---------------------------------- the picture that stays ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheBackgroundIsAGradientFromNightTopToNightBottomWithDotsInThePanel():
        Draw().
        Assert:Equals(ColourMath:Mix(Colour(Tint:NightTop), Colour(Tint:NightBottom), 100, 319), Px(270, 100)).
        Assert:Equals(Colour(Tint:NightBottom), Px(270, 319)).
        Assert:Equals(ColourMath:Mix(Colour(Tint:NightTop), Colour(Tint:NightBottom), 98, 319), Px(270, 98)).
        /* a faint dot every 16 pixels in the panel: x = 184 + 16k, y = 8 + 16m, where no card covers it */
        Assert:Equals(Colour(Tint:Dot), Px(264, 296)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyCellOfTheWellIsTheFloorOfItsRowWithAFaintGridLineOnItsRightAndBottom():
        Draw().
        Assert:Equals(Floor(10), Px(16 * 3 + 5, 16 * 10 + 5)).
        Assert:Equals(Floor(0), Px(16 * 8 + 5, 5)).
        Assert:Equals(ColourMath:Mix(Floor(10), 16777215, 35, 1000), Px(16 * 3 + 15, 16 * 10 + 5)).
        Assert:Equals(ColourMath:Mix(Floor(10), 16777215, 35, 1000), Px(16 * 3 + 5, 16 * 10 + 15)).
        /* deeper rows are lighter than the top ones */
        Assert:IsTrue(Px(16 * 3 + 5, 16 * 17 + 5) <> Px(16 * 3 + 5, 16 * 2 + 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWellHasTwoLitPixelsOfWallOnItsLeftAndBottomAndTheDividerOnItsRight():
        Draw().
        Assert:Equals(Colour(Tint:WallHigh), Px(0, 100)).
        Assert:Equals(Colour(Tint:WallLow), Px(1, 100)).
        Assert:Equals(Colour(Tint:WallLow), Px(20, 318)).
        Assert:Equals(Colour(Tint:WallHigh), Px(20, 319)).
        /* the divider: two lit pixels, twelve of dark gap, and the edge of the panel */
        Assert:Equals(Colour(Tint:WallLow), Px(160, 50)).
        Assert:Equals(Colour(Tint:WallHigh), Px(161, 50)).
        Assert:Equals(Colour(Tint:Gap), Px(162, 50)).
        Assert:Equals(Colour(Tint:Gap), Px(173, 50)).
        Assert:Equals(Colour(Tint:FrameInner), Px(174, 50)).
        Assert:Equals(Colour(Tint:FrameOuter), Px(175, 50)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCardsAreFramesWithCutCornersAndAPanelFillInside():
        Draw().
        /* the SCORE card is 88 x 40 at (180, 104) */
        Assert:Equals(Colour(Tint:NightTop), Px(180, 104)).
        Assert:Equals(Colour(Tint:FrameOuter), Px(181, 104)).
        Assert:Equals(Colour(Tint:FrameOuter), Px(180, 105)).
        Assert:Equals(Colour(Tint:FrameInner), Px(181, 105)).
        Assert:Equals(Colour(Tint:PanelFill), Px(182, 106)).
        Assert:Equals(Colour(Tint:PanelFill), Px(264, 140)).
        Assert:Equals(Colour(Tint:FrameOuter), Px(267, 140)).
        /* the NEXT box is 96 x 96 at (176, 0) */
        Assert:Equals(Colour(Tint:FrameOuter), Px(177, 0)).
        Assert:Equals(Colour(Tint:PanelFill), Px(180, 90)).
    END METHOD.

    /* ---------------------------------- the pieces ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheNextPieceIsDrawnInTheMiddleOfTheBoxInItsOwnBlocks():
        /* the pieces are I then O: the next piece is the O, 2 x 2 cells, at x = 192 + 16, y = 24 + 16 */
        Draw().
        Assert:Equals(Tone(2, 1), Px(208 + 1, 40 + 1)).
        Assert:Equals(Tone(2, 1), Px(208 + 16 + 1, 40 + 16 + 1)).
        Assert:Equals(Tone(2, 5), Px(208, 40)).
        /* nothing outside the two by two */
        Assert:IsFalse(Px(208 - 5, 40 + 5) = Tone(2, 3)).
        Assert:Equals(Colour(Tint:PanelFill), Px(208 + 40, 40 + 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFallingPieceIsDrawnWithTheBlocksOfItsPiece():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        Draw().
        shape = Tetrominoes:ShapeOf(mGame:CurrentPiece, mGame:Turns).
        DO i = 1 TO shape:Size:
            Assert:Equals(Tone(1, 1), Px(16 * (mGame:PieceX + shape:OffsetX(i)) + 1, 16 * (mGame:PieceY + shape:OffsetY(i)) + 1)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGhostShowsWhereThePieceWouldLandInASofterOutlineAndGoesWhenSwitchedOff():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE gx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE gy    AS INTEGER NO-UNDO.
        shape = Tetrominoes:ShapeOf(mGame:CurrentPiece, mGame:Turns).
        gx = mGame:PieceX + shape:OffsetX(1).
        gy = mGame:GhostY() + shape:OffsetY(1).
        Draw().
        Assert:Equals(Colour(Tint:GhostLine), Px(16 * gx + 1, 16 * gy)).
        /* the middle of the ghost is open: the floor shows through */
        Assert:Equals(Floor(gy), Px(16 * gx + 7, 16 * gy + 2)).
        mGame:ShowGhost = FALSE.
        Draw().
        Assert:Equals(Floor(gy), Px(16 * gx + 1, 16 * gy + 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SettledBlocksAreDrawnAndTheyCoverTheWallAtTheEdge():
        mGame:LoadLocked("T........./.........S").
        Draw().
        /* the T at column 0 of row 18: its tone 2 at (3, 3), over the wall */
        Assert:Equals(Tone(3, 2), Px(3, 16 * 18 + 3)).
        Assert:Equals(Tone(3, 5), Px(0, 16 * 18)).
        /* the S at column 9 of row 19, over the bottom wall */
        Assert:Equals(Tone(4, 2), Px(16 * 9 + 3, 16 * 19 + 3)).
        Assert:Equals(Tone(4, 5), Px(16 * 9 + 5, 16 * 19 + 15)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceThatSettlesStaysAndThePiecesBeforeItStayToo():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x1    AS INTEGER NO-UNDO.
        DEFINE VARIABLE y1    AS INTEGER NO-UNDO.
        Draw().
        shape = Tetrominoes:ShapeOf(1, 0).
        x1 = mGame:PieceX + shape:OffsetX(1).
        mGame:HardDrop().
        mGame:Tick(150).
        Draw().
        /* the I sits on the floor: where it landed is its tone 1 at the top left of the tile */
        Assert:Equals(Tone(1, 1), Px(16 * x1 + 1, 16 * 19 + 1)).
        /* the next piece (the O) comes down on top of it */
        mGame:HardDrop().
        mGame:Tick(150).
        Draw().
        Assert:Equals(Tone(1, 1), Px(16 * x1 + 1, 16 * 19 + 1)).
        Assert:IsTrue(CountOf(Tone(2, 1), 0, 16 * 17, 160, 32) >= 2).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenRowsAreClearedTheBlocksAboveDropAndTheRowsAreFloorAgain():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mGame:StartWith("I,I,I").
        mGame:LoadLocked("T........./IIIIIII.II").
        Draw().
        Assert:Equals(Tone(3, 2), Px(3, 16 * 18 + 3)).
        mGame:RotateClockwise().
        DO i = 1 TO 3:
            mGame:MoveRight().
        END.
        mGame:HardDrop().
        mGame:Tick(150).
        Draw().
        /* the full row is gone: the T came down a row, onto the floor, and what was the fourth row of the I's column is now the last */
        Assert:Equals(Tone(3, 2), Px(3, 16 * 19 + 3)).
        Assert:Equals(Floor(18), Px(16 * 5 + 5, 16 * 18 + 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameStartsFromAnEmptyWell():
        mGame:LoadLocked("T........./IIIIIII.II").
        Draw().
        Assert:Equals(Tone(3, 2), Px(3, 16 * 18 + 3)).
        mGame:Initialise().
        Draw().
        Assert:Equals(Floor(18), Px(16 * 0 + 5, 16 * 18 + 5)).
    END METHOD.

    /* ---------------------------------- the numbers ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheLabelsAndTheNumbersAreWrittenInTheCards():
        mGame:BestScore = 38250.
        Draw().
        /* NEXT in amber at (212, 8), the four labels in the label colour, the level in amber, the best in dim, the numbers in text */
        Assert:IsTrue(CountOf(Colour(Tint:Accent), 212, 8, 30, 7) > 10).
        Assert:IsTrue(CountOf(Colour(Tint:Label), 188, 110, 36, 7) > 10).
        Assert:IsTrue(CountOf(Colour(Tint:Label), 188, 156, 36, 7) > 10).
        Assert:IsTrue(CountOf(Colour(Tint:Label), 188, 202, 36, 7) > 10).
        Assert:IsTrue(CountOf(Colour(Tint:Label), 188, 248, 48, 7) > 10).
        Assert:IsTrue(CountOf(Colour(Tint:Text), 188, 122, 70, 14) > 40).
        Assert:IsTrue(CountOf(Colour(Tint:Text), 188, 168, 70, 14) > 40).
        Assert:IsTrue(CountOf(Colour(Tint:Accent), 188, 214, 24, 14) > 10).
        Assert:IsTrue(CountOf(Colour(Tint:Dim), 188, 260, 70, 14) > 40).
        Assert:IsTrue(CountOf(Colour(Tint:Label), 188, 294, 50, 7) > 10).
        Assert:IsTrue(CountOf(Colour(Tint:Label), 188, 304, 50, 7) > 10).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreIsSixDigitsPaddedWithZerosAndChangesWhenTheGameScores():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        Draw().
        before = CountOf(Colour(Tint:Text), 188, 122, 70, 14).
        mGame:HardDrop().
        Draw().
        /* the digits changed: 000000 became 000038 or so, so the lit pixels are not the same */
        Assert:IsTrue(mGame:Score > 0).
        Assert:IsFalse(CountOf(Colour(Tint:Text), 188, 122, 70, 14) = before).
    END METHOD.

    /* The first cell of the piece that has just been hard dropped, as a pixel x, and the row it sits on (the floor). */
    METHOD PRIVATE INTEGER DropAnI():
        DEFINE VARIABLE shape AS Shape NO-UNDO.
        shape = Tetrominoes:ShapeOf(1, 0).
        mGame:HardDrop().
        RETURN 16 * (mGame:LastLockX + shape:OffsetX(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASettlingPieceIsLitForFiftyMillisecondsThenOnlyItsHighlightIsWhiteThenNormal():
        DEFINE VARIABLE x0 AS INTEGER NO-UNDO.
        Draw().
        x0 = DropAnI().
        Draw().
        /* lit: the highlight is white and tone 2 is the old tone 1 */
        Assert:Equals(16777215, Px(x0 + 1, 16 * 19 + 1)).
        Assert:Equals(Tone(1, 1), Px(x0 + 3, 16 * 19 + 3)).
        mGame:Tick(60).
        Draw().
        /* the highlight is still white but the rest is the normal tile */
        Assert:Equals(16777215, Px(x0 + 1, 16 * 19 + 1)).
        Assert:Equals(Tone(1, 2), Px(x0 + 3, 16 * 19 + 3)).
        mGame:Tick(60).
        Draw().
        Assert:Equals(Tone(1, 1), Px(x0 + 1, 16 * 19 + 1)).
        Assert:Equals(Tone(1, 2), Px(x0 + 3, 16 * 19 + 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASettlingPieceThrowsSparksThatAreGoneAfterTenFrames():
        DEFINE VARIABLE x0     AS INTEGER NO-UNDO.
        DEFINE VARIABLE during AS INTEGER NO-UNDO.
        DEFINE VARIABLE after  AS INTEGER NO-UNDO.
        Draw().
        x0 = DropAnI().
        mGame:Tick(100).
        Draw().
        /* six frames old, the sparks wear tone 2 of the piece, near the bottom of the blocks */
        during = CountOf(Tone(1, 2), x0, 16 * 19 + 13, 16, 2).
        mGame:Tick(100).
        Draw().
        after = CountOf(Tone(1, 2), x0, 16 * 19 + 13, 16, 2).
        Assert:IsTrue(during > after).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHardDropLeavesATwoPixelTrailInTheColumnsThatFadesThroughTonesTwoThreeAndFour():
        DEFINE VARIABLE x0 AS INTEGER NO-UNDO.
        Draw().
        x0 = DropAnI().
        Draw().
        Assert:Equals(Tone(1, 2), Px(x0 + 7, 16 * 8 + 5)).
        Assert:Equals(Tone(1, 2), Px(x0 + 8, 16 * 8 + 5)).
        Assert:IsFalse(Px(x0 + 6, 16 * 8 + 5) = Tone(1, 2)).
        Assert:IsFalse(Px(x0 + 9, 16 * 8 + 5) = Tone(1, 2)).
        mGame:Tick(60).
        Draw().
        Assert:Equals(Tone(1, 3), Px(x0 + 7, 16 * 8 + 5)).
        mGame:Tick(50).
        Draw().
        Assert:Equals(Tone(1, 4), Px(x0 + 7, 16 * 8 + 5)).
        mGame:Tick(50).
        Draw().
        Assert:Equals(Floor(8), Px(x0 + 7, 16 * 8 + 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASoftLandingLeavesNoTrail():
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        DEFINE VARIABLE x0    AS INTEGER NO-UNDO.
        shape = Tetrominoes:ShapeOf(1, 0).
        x0 = 16 * (mGame:PieceX + shape:OffsetX(1)).
        Draw().
        Assert:Equals(Floor(8), Px(x0 + 7, 16 * 8 + 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHardDropImpactIsALineAlongTheBottomEdgeThatGrowsFourPixelsEachSideAStep():
        DEFINE VARIABLE x0 AS INTEGER NO-UNDO.
        Draw().
        x0 = DropAnI().
        Draw().
        Assert:Equals(Colour(Tint:Flash), Px(x0 + 4, 16 * 19 + 15)).
        mGame:Tick(60).
        Draw().
        Assert:Equals(Tone(1, 1), Px(x0 - 3, 16 * 19 + 15)).
        Assert:Equals(Tone(1, 1), Px(x0 + 64 + 3, 16 * 19 + 15)).
        mGame:Tick(50).
        Draw().
        Assert:Equals(Tone(1, 3), Px(x0 - 8, 16 * 19 + 15)).
        mGame:Tick(50).
        Draw().
        Assert:IsFalse(Px(x0 - 8, 16 * 19 + 15) = Tone(1, 3)).
    END METHOD.

    /* A game that holds a clear for 300 ms, with one full row about to go (row 19, ten blocks once the I is dropped in). */
    METHOD PRIVATE VOID SetUpOneRow():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mGame:ClearDelayMs = 300.
        mGame:StartWith("I,I,I").
        mGame:LoadLocked("T........./IIIIIII.II").
        Draw().
        mGame:RotateClockwise().
        DO i = 1 TO 3:
            mGame:MoveRight().
        END.
        mGame:HardDrop().
    END METHOD.

    /* A game that holds a clear for 300 ms, with four full rows about to go. */
    METHOD PRIVATE VOID SetUpFourRows():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mGame:ClearDelayMs = 300.
        mGame:StartWith("I,I,I").
        mGame:LoadLocked("IIIIIIIII./IIIIIIIII./IIIIIIIII./IIIIIIIII.").
        Draw().
        mGame:RotateClockwise().
        DO i = 1 TO 6:
            mGame:MoveRight().
        END.
        mGame:HardDrop().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AClearedRowIsLitThenWhiteThenTurnsToFloorFromTheMiddleOut():
        SetUpOneRow().
        Assert:IsTrue(mGame:Clearing).
        Draw().
        /* frame 0: lit, the highlight is white and tone 2 is the old tone 1 */
        Assert:Equals(16777215, Px(16 * 2 + 1, 16 * 19 + 1)).
        Assert:Equals(Tone(1, 1), Px(16 * 2 + 3, 16 * 19 + 3)).
        mGame:Tick(50).
        Draw().
        /* frame 1: the whole row is white */
        Assert:Equals(16777215, Px(5, 16 * 19 + 5)).
        Assert:Equals(16777215, Px(159, 16 * 19 + 15)).
        Assert:IsFalse(Px(5, 16 * 18 + 5) = 16777215).
        mGame:Tick(50).
        Draw().
        /* frame 2: columns 4 and 5 are floor, the rest lit */
        Assert:Equals(Floor(19), Px(16 * 4 + 5, 16 * 19 + 5)).
        Assert:Equals(Floor(19), Px(16 * 5 + 5, 16 * 19 + 5)).
        Assert:Equals(Tone(1, 1), Px(16 * 3 + 3, 16 * 19 + 3)).
        mGame:Tick(50).
        Draw().
        Assert:Equals(Floor(19), Px(16 * 3 + 5, 16 * 19 + 5)).
        Assert:Equals(Tone(1, 1), Px(16 * 2 + 3, 16 * 19 + 3)).
        mGame:Tick(50).
        Draw().
        Assert:Equals(Floor(19), Px(16 * 2 + 5, 16 * 19 + 5)).
        Assert:Equals(Tone(1, 1), Px(16 * 1 + 3, 16 * 19 + 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWipeThrowsGoldSparksAndTheScoreGlowsGoldForFourHundredMilliseconds():
        DEFINE VARIABLE gold1 AS INTEGER NO-UNDO.
        SetUpOneRow().
        gold1 = ColourMath:FromHex(ENTRY(1, TetrisLook:Tones(9))).
        mGame:Tick(90).
        Draw().
        Assert:Equals(0, CountOf(gold1, 0, 16 * 15, 160, 80)).
        Assert:IsTrue(CountOf(Colour(Tint:Gold), 188, 122, 70, 14) > 0).
        mGame:Tick(60).
        Draw().
        /* three frames after the first wipe frame the sparks wear the first gold */
        Assert:IsTrue(CountOf(gold1, 0, 16 * 15, 160, 80) > 0).
        mGame:Tick(300).
        Draw().
        Assert:Equals(0, CountOf(Colour(Tint:Gold), 188, 122, 70, 14)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFourRowClearBeginsInGoldGoesWhiteAndShowsTheWordTetrisForHalfASecond():
        DEFINE VARIABLE gold AS INTEGER NO-UNDO.
        SetUpFourRows().
        Assert:IsTrue(mGame:Clearing).
        Assert:Equals(4, mGame:LastClearCount).
        gold = ColourMath:FromHex(ENTRY(1, TetrisLook:Tones(9))).
        Draw().
        Assert:Equals(gold, Px(16 * 2 + 1, 16 * 17 + 1)).
        mGame:Tick(60).
        Draw().
        Assert:Equals(16777215, Px(5, 16 * 17 + 5)).
        Assert:Equals(16777215, Px(150, 16 * 19 + 5)).
        Assert:Equals(0, CountOf(Colour(Tint:Gold), 45, 281, 70, 14)).
        mGame:Tick(70).
        Draw().
        /* the word, in gold at the top of its letters, over the well */
        Assert:IsTrue(CountOf(Colour(Tint:Gold), 45, 281, 70, 14) > 0).
        Assert:IsTrue(CountOf(Colour(Tint:Gold), 188, 122, 70, 14) > 0).
        mGame:Tick(600).
        Draw().
        Assert:Equals(0, CountOf(Colour(Tint:Gold), 45, 281, 70, 14)).
        /* the score is gold for 800 ms after a Tetris */
        Assert:IsTrue(CountOf(Colour(Tint:Gold), 188, 122, 70, 14) > 0).
        mGame:Tick(100).
        Draw().
        Assert:Equals(0, CountOf(Colour(Tint:Gold), 188, 122, 70, 14)).
    END METHOD.

    /* Ten single row clears, the last of which raises the level: the level up is 5 ms before the end of the clock. */
    METHOD PRIVATE VOID RaiseTheLevel():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.
        mGame:StartWith("I,I,I,I,I,I,I,I,I,I,I,I").
        DO i = 1 TO 10:
            mGame:Tick(5).
            mGame:LoadLocked("IIIIIII.II").
            mGame:RotateClockwise().
            DO j = 1 TO 3:
                mGame:MoveRight().
            END.
            mGame:HardDrop().
        END.
        Draw().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALevelUpSendsAGoldLineUpTheEmptyCellsOfTheWellThatDarkensHalfWay():
        RaiseTheLevel().
        Assert:Equals(2, mGame:Level).
        mGame:Tick(20).
        Draw().
        /* the second frame: two pixels at 300, over the empty floor, but not over the wall */
        Assert:Equals(Colour(Tint:Gold), Px(150, 300)).
        Assert:Equals(Colour(Tint:Gold), Px(150, 301)).
        Assert:IsFalse(Px(150, 302) = Colour(Tint:Gold)).
        Assert:IsFalse(Px(1, 300) = Colour(Tint:Gold)).
        mGame:Tick(130).
        Draw().
        /* the tenth frame, in gold tone 4 */
        Assert:Equals(ColourMath:FromHex(ENTRY(4, TetrisLook:Tones(9))), Px(150, 318 - 18 * 9)).
        mGame:Tick(200).
        Draw().
        Assert:IsFalse(Px(150, 318 - 18 * 9) = ColourMath:FromHex(ENTRY(4, TetrisLook:Tones(9)))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALevelUpMakesTheLevelCardAmberAndBlinksTheNumberForHalfASecond():
        RaiseTheLevel().
        mGame:Tick(20).
        Draw().
        Assert:Equals(Colour(Tint:Accent), Px(mPainter:Canvas:Width - 96 + 4 + 10, 196)).
        Assert:IsTrue(CountOf(Colour(Tint:Gold), 188, 214, 22, 14) > 0).
        Assert:Equals(0, CountOf(Colour(Tint:Accent), 188, 214, 22, 14)).
        mGame:Tick(80).
        Draw().
        Assert:Equals(0, CountOf(Colour(Tint:Gold), 188, 214, 22, 14)).
        Assert:IsTrue(CountOf(Colour(Tint:Accent), 188, 214, 22, 14) > 0).
        mGame:Tick(400).
        Draw().
        Assert:Equals(Colour(Tint:FrameOuter), Px(mPainter:Canvas:Width - 96 + 4 + 10, 196)).
        Assert:Equals(0, CountOf(Colour(Tint:Gold), 188, 214, 22, 14)).
    END METHOD.

END CLASS.
