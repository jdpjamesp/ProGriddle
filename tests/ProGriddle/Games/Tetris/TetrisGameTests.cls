USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* The rules, one at a time. The board is the usual 10 x 20. Pieces are chosen with StartWith so a test
   knows what falls, and the settled blocks are set up with LoadLocked: "." is empty and a piece letter
   (I O T S Z J L) is a block of that piece, rows from the top down, put at the bottom of the board.
   The grid is read back as text with the symbols of TetrisLook:TextSymbols(): . empty, the piece
   letters, : the ghost, | the divider and _ the panel beside the board. */
CLASS ProGriddle.Games.Tetris.TetrisGameTests:

    DEFINE PRIVATE VARIABLE mGame AS TetrisGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mText AS TextGridRenderer NO-UNDO.

    /* A new game whose first pieces are the ones named. */
    METHOD PRIVATE VOID NewGame(INPUT pcPieces AS CHARACTER):
        mGame = TetrisFactory:Create(NEW SeededRandom(1)).
        mGame:StartWith(pcPieces).
        mText = NEW TextGridRenderer("view", TetrisLook:TextSymbols()).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* One row of the grid as text. */
    METHOD PRIVATE CHARACTER Row(INPUT piY AS INTEGER):
        RETURN ENTRY(piY + 1, mText:ToText(mGame:Grid), CHR(10)).
    END METHOD.

    /* n rows, each full but for a gap at column 7, as one string for LoadLocked. */
    METHOD PRIVATE CHARACTER GappedRows(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DO i = 1 TO piCount:
            result = result + (IF i > 1 THEN "/" ELSE "") + "IIIIIII.II".
        END.
        RETURN result.
    END METHOD.

    /* Settled cells on the board. */
    METHOD PRIVATE INTEGER LockedCount():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = 0 TO 19:
            DO x = 0 TO 9:
                IF mGame:LockedAt(x, y) <> 0 THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    /* Cells the falling piece covers. */
    METHOD PRIVATE INTEGER ActiveCount():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = 0 TO 19:
            DO x = 0 TO 9:
                IF mGame:ActiveAt(x, y) THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    /* ---- a new game ---- */

    @Test.
    METHOD PUBLIC VOID ANewGameHasTheBoardADividerAndAPanelInOneGrid():
        NewGame("I,O,T,S,Z,J,L").
        Assert:Equals(17, mGame:Grid:Width).
        Assert:Equals(20, mGame:Grid:Height).
        Assert:Equals(10, mGame:BoardWidth).
        Assert:Equals(20, mGame:BoardHeight).
        Assert:Equals("Tetris", mGame:Name).
        Assert:IsTrue(TYPE-OF(mGame, IRealTimeGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstPieceAppearsAtTheTopInTheMiddleAndTheNextOneIsKnown():
        NewGame("I,O,T,S,Z,J,L").
        Assert:Equals(1, mGame:CurrentPiece).
        Assert:Equals(2, mGame:NextPiece).
        Assert:Equals(3, mGame:PieceX).
        Assert:Equals(0, mGame:PieceY).
        Assert:Equals(0, mGame:Turns).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, mGame:LinesCleared).
        Assert:Equals(1, mGame:Level).
        Assert:Equals(800, mGame:GravityMs).
        Assert:IsFalse(mGame:IsOver).
        Assert:IsFalse(mGame:Paused).
        Assert:Equals(4, ActiveCount()).
        Assert:IsTrue(mGame:ActiveAt(3, 0)).
        Assert:IsTrue(mGame:ActiveAt(6, 0)).
        Assert:IsFalse(mGame:ActiveAt(2, 0)).
        Assert:IsFalse(mGame:ActiveAt(7, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStartingBoardShowsThePieceTheGhostAndTheNextPieceInThePanel():
        NewGame("I,O,T,S,Z,J,L").
        Assert:Equals("...IIII...|______", Row(0)).
        Assert:Equals("..........|______", Row(1)).
        Assert:Equals("..........|__OO__", Row(2)).
        Assert:Equals("..........|__OO__", Row(3)).
        Assert:Equals("..........|______", Row(4)).
        Assert:Equals("...::::...|______", Row(19)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePiecesSettledAreCounted():
        NewGame("O,O,O").
        Assert:Equals(0, mGame:PiecesPlaced).
        mGame:HardDrop().
        mGame:HardDrop().
        Assert:Equals(2, mGame:PiecesPlaced).
        mGame:Initialise().
        Assert:Equals(0, mGame:PiecesPlaced).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePiecesComeInTheOrderGivenAndThenFromTheBag():
        NewGame("Z,S").
        Assert:Equals(5, mGame:CurrentPiece).
        Assert:Equals(4, mGame:NextPiece).
        mGame:HardDrop().
        Assert:Equals(4, mGame:CurrentPiece).
        Assert:IsTrue(mGame:NextPiece >= 1 AND mGame:NextPiece <= 7).
    END METHOD.

    /* ---- moving ---- */

    @Test.
    METHOD PUBLIC VOID APieceMovesLeftAndRightUntilItReachesAWall():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,O,T").
        DO i = 1 TO 3:
            Assert:IsTrue(mGame:MoveLeft()).
        END.
        Assert:Equals(0, mGame:PieceX).
        Assert:IsFalse(mGame:MoveLeft()).
        Assert:Equals(0, mGame:PieceX).
        DO i = 1 TO 6:
            Assert:IsTrue(mGame:MoveRight()).
        END.
        Assert:Equals(6, mGame:PieceX).
        Assert:IsFalse(mGame:MoveRight()).
        Assert:Equals(4, ActiveCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceCannotMoveIntoASettledBlock():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,O,T").
        /* a column of blocks at x = 2 in the bottom ten rows */
        mGame:LoadLocked("..O...../..O...../..O...../..O...../..O...../..O...../..O...../..O...../..O...../..O.....").
        DO i = 1 TO 9:
            mGame:SoftDrop().
        END.
        /* still above the column, so the piece can slide over it */
        Assert:IsTrue(mGame:MoveLeft()).
        Assert:IsTrue(mGame:MoveRight()).
        mGame:SoftDrop().
        Assert:Equals(10, mGame:PieceY).
        /* now beside it, the piece covers x = 3 to 6 and a step left would cover the block at x = 2 */
        Assert:IsFalse(mGame:MoveLeft()).
        Assert:Equals(3, mGame:PieceX).
        Assert:IsTrue(mGame:MoveRight()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASoftDropMovesOneRowForAPointAndStopsOnTheFloor():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,O,T").
        Assert:IsTrue(mGame:SoftDrop()).
        Assert:Equals(1, mGame:PieceY).
        Assert:Equals(1, mGame:Score).
        DO i = 2 TO 19:
            Assert:IsTrue(mGame:SoftDrop()).
        END.
        Assert:Equals(19, mGame:PieceY).
        Assert:Equals(19, mGame:Score).
        Assert:IsFalse(mGame:SoftDrop()).
        Assert:Equals(19, mGame:Score).
        Assert:Equals(1, mGame:CurrentPiece).
    END METHOD.

    /* ---- gravity ---- */

    @Test.
    METHOD PUBLIC VOID GravityMovesThePieceDownOneRowEveryEightHundredMillisecondsAtLevelOne():
        NewGame("I,O,T").
        Assert:IsFalse(mGame:Tick(799)).
        Assert:Equals(0, mGame:PieceY).
        Assert:IsTrue(mGame:Tick(1)).
        Assert:Equals(1, mGame:PieceY).
        Assert:IsTrue(mGame:Tick(1600)).
        Assert:Equals(3, mGame:PieceY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TimeThatIsNotYetAFullStepIsKeptForNextTime():
        NewGame("I,O,T").
        mGame:Tick(500).
        mGame:Tick(500).
        Assert:Equals(1, mGame:PieceY).
        mGame:Tick(600).
        Assert:Equals(2, mGame:PieceY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ZeroOrNegativeTimeDoesNothing():
        NewGame("I,O,T").
        Assert:IsFalse(mGame:Tick(0)).
        Assert:IsFalse(mGame:Tick(-5)).
        Assert:IsFalse(mGame:Tick(?)).
        Assert:Equals(0, mGame:PieceY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceThatCannotFallFurtherSettlesOnTheNextGravityStepAndTheNextPieceAppears():
        NewGame("I,O,T").
        mGame:Tick(19 * 800).
        Assert:Equals(19, mGame:PieceY).
        Assert:Equals(0, mGame:LockedAt(3, 19)).
        mGame:Tick(800).
        Assert:Equals(1, mGame:LockedAt(3, 19)).
        Assert:Equals(1, mGame:LockedAt(6, 19)).
        Assert:Equals(2, mGame:CurrentPiece).
        Assert:Equals(3, mGame:NextPiece).
        Assert:Equals(0, mGame:PieceY).
        Assert:Equals("...IIII...|______", Row(19)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGravityStepGetsShorterAsTheLevelRises():
        NewGame("I,O,T").
        mGame:StartLevel = 2.
        Assert:Equals(800, mGame:GravityMs).
        mGame:Initialise().
        Assert:Equals(725, mGame:GravityMs).
        mGame:StartLevel = 10.
        mGame:Initialise().
        Assert:Equals(125, mGame:GravityMs).
        mGame:StartLevel = 11.
        mGame:Initialise().
        Assert:Equals(50, mGame:GravityMs).
        mGame:StartLevel = 15.
        mGame:Initialise().
        Assert:Equals(50, mGame:GravityMs).
        Assert:Equals(15, mGame:Level).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AStartLevelBelowOneThrows():
        NewGame("I").
        mGame:StartLevel = 0.
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AStartLevelAboveFifteenThrows():
        NewGame("I").
        mGame:StartLevel = 16.
    END METHOD.

    /* ---- dropping ---- */

    @Test.
    METHOD PUBLIC VOID AHardDropGoesToTheBottomSettlesAndScoresTwoPointsARow():
        NewGame("I,O,T").
        Assert:IsTrue(mGame:HardDrop()).
        Assert:Equals(1, mGame:LockedAt(3, 19)).
        Assert:Equals(1, mGame:LockedAt(6, 19)).
        Assert:Equals(38, mGame:Score).
        Assert:Equals(2, mGame:CurrentPiece).
        Assert:Equals(3, mGame:NextPiece).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHardDropStopsOnTopOfSettledBlocks():
        NewGame("I,O,T").
        mGame:LoadLocked("OOOO....../........../..........").
        Assert:IsTrue(mGame:HardDrop()).
        /* the I piece (columns 3 to 6) is caught by the block in column 3 of the row three up from the
           bottom, so it settles one row above that row */
        Assert:Equals(1, mGame:LockedAt(3, 16)).
        Assert:Equals(1, mGame:LockedAt(6, 16)).
        Assert:Equals(2, mGame:LockedAt(3, 17)).
        Assert:Equals(32, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFirstPiecesLandOnTopOfEachOther():
        NewGame("O,O,O").
        mGame:HardDrop().
        mGame:HardDrop().
        Assert:Equals(2, mGame:LockedAt(4, 19)).
        Assert:Equals(2, mGame:LockedAt(5, 18)).
        Assert:Equals(2, mGame:LockedAt(4, 17)).
        Assert:Equals(2, mGame:LockedAt(5, 16)).
        Assert:Equals(0, mGame:LockedAt(4, 15)).
    END METHOD.

    /* ---- turning ---- */

    @Test.
    METHOD PUBLIC VOID TurningATPieceClockwiseGivesTheUprightShapeAndFourTurnsGiveItBack():
        NewGame("T,O,I").
        Assert:IsTrue(mGame:RotateClockwise()).
        Assert:Equals(1, mGame:Turns).
        Assert:Equals(3, mGame:PieceX).
        Assert:Equals(0, mGame:PieceY).
        Assert:IsTrue(mGame:ActiveAt(3, 0)).
        Assert:IsTrue(mGame:ActiveAt(3, 1)).
        Assert:IsTrue(mGame:ActiveAt(3, 2)).
        Assert:IsTrue(mGame:ActiveAt(4, 1)).
        Assert:IsFalse(mGame:ActiveAt(5, 1)).
        Assert:Equals(4, ActiveCount()).
        mGame:RotateClockwise().
        mGame:RotateClockwise().
        mGame:RotateClockwise().
        Assert:Equals(0, mGame:Turns).
        Assert:Equals("....T.....|______", Row(0)).
        Assert:Equals("...TTT....|______", Row(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TurningTheOtherWayGoesBackwardThroughTheTurns():
        NewGame("T,O,I").
        mGame:RotateCounterClockwise().
        Assert:Equals(3, mGame:Turns).
        mGame:RotateClockwise().
        Assert:Equals(0, mGame:Turns).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnIPieceThatIsTurnedUpRightIsKickedDownOffTheTopOfTheBoard():
        NewGame("I,O,T").
        Assert:IsTrue(mGame:RotateClockwise()).
        Assert:Equals(1, mGame:Turns).
        Assert:Equals(4, mGame:PieceX).
        Assert:Equals(0, mGame:PieceY).
        Assert:IsTrue(mGame:ActiveAt(4, 0)).
        Assert:IsTrue(mGame:ActiveAt(4, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APieceTurnedAgainstAWallIsKickedAwayFromIt():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,O,T").
        mGame:RotateClockwise().
        DO i = 1 TO 4:
            mGame:MoveLeft().
        END.
        Assert:Equals(0, mGame:PieceX).
        Assert:IsTrue(mGame:RotateClockwise()).
        Assert:Equals(2, mGame:Turns).
        Assert:Equals(0, mGame:PieceX).
        Assert:Equals(4, ActiveCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnThatHasNoRoomAtAnyKickIsRefused():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,O,T").
        mGame:LoadLocked("IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII/IIII.IIIII").
        Assert:IsTrue(mGame:RotateClockwise()).
        DO i = 1 TO 16:
            Assert:IsTrue(mGame:SoftDrop()).
        END.
        Assert:IsFalse(mGame:SoftDrop()).
        Assert:Equals(16, mGame:PieceY).
        Assert:IsFalse(mGame:RotateClockwise()).
        Assert:IsFalse(mGame:RotateCounterClockwise()).
        Assert:Equals(1, mGame:Turns).
        Assert:Equals(16, mGame:PieceY).
        Assert:Equals(4, ActiveCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOPieceTurnsWithoutChangingAnything():
        NewGame("O,I,T").
        Assert:IsTrue(mGame:RotateClockwise()).
        Assert:Equals(4, mGame:PieceX).
        Assert:Equals(0, mGame:PieceY).
        Assert:Equals(4, ActiveCount()).
    END METHOD.

    /* ---- clearing lines ---- */

    @Test.
    METHOD PUBLIC VOID ClearingOneTwoThreeOrFourLinesScoresOneHundredThreeHundredFiveHundredAndEightHundred():
        DEFINE VARIABLE n        AS INTEGER NO-UNDO.
        DEFINE VARIABLE expected AS INTEGER NO-UNDO EXTENT 4 INITIAL [132, 332, 532, 832].
        DEFINE VARIABLE i        AS INTEGER NO-UNDO.
        DEFINE VARIABLE bad      AS INTEGER NO-UNDO.
        DO n = 1 TO 4:
            NewGame("I,I,I,I,I,I").
            mGame:LoadLocked(GappedRows(n)).
            mGame:RotateClockwise().
            DO i = 1 TO 3:
                mGame:MoveRight().
            END.
            mGame:HardDrop().
            /* the points for the lines, plus 32 for dropping the piece 16 rows */
            IF mGame:Score <> expected[n] OR mGame:LinesCleared <> n THEN bad = bad + 1.
            mGame:Dispose().
        END.
        Assert:Equals(0, bad).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatIsLeftOfThePieceAfterTwoLinesAreClearedDropsToTheFloor():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,I,I,I").
        mGame:LoadLocked(GappedRows(2)).
        mGame:RotateClockwise().
        DO i = 1 TO 3:
            mGame:MoveRight().
        END.
        mGame:HardDrop().
        Assert:Equals(2, mGame:LinesCleared).
        Assert:Equals(1, mGame:LockedAt(7, 19)).
        Assert:Equals(1, mGame:LockedAt(7, 18)).
        Assert:Equals(0, mGame:LockedAt(7, 17)).
        Assert:Equals(2, LockedCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearingAllFourLinesLeavesAnEmptyBoard():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,I,I,I").
        mGame:LoadLocked(GappedRows(4)).
        mGame:RotateClockwise().
        DO i = 1 TO 3:
            mGame:MoveRight().
        END.
        mGame:HardDrop().
        Assert:Equals(0, LockedCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BlocksAboveAClearedLineFallWithTheRowsAndLinesThatAreNotFullStay():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,I,I,I").
        /* a loose block in the top row, then an empty row, a row with a gap at column 7 and a row with a
           gap at column 9. The piece stands in column 7 on the bottom row's block and fills the first gap */
        mGame:LoadLocked("T........./........../IIIIIII.II/IIIIIIIII.").
        mGame:RotateClockwise().
        DO i = 1 TO 3:
            mGame:MoveRight().
        END.
        mGame:HardDrop().
        /* one line goes and everything above it drops one row: the T block from row 16 to row 17, and the
           rest of the piece from rows 15 to 17 to rows 16 to 18. The row with the gap stays where it was */
        Assert:Equals(1, mGame:LinesCleared).
        Assert:Equals(3, mGame:LockedAt(0, 17)).
        Assert:Equals(0, mGame:LockedAt(0, 16)).
        Assert:Equals(1, mGame:LockedAt(7, 16)).
        Assert:Equals(1, mGame:LockedAt(7, 18)).
        Assert:Equals(1, mGame:LockedAt(0, 19)).
        Assert:Equals(0, mGame:LockedAt(9, 19)).
        Assert:Equals(130, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreForLinesIsMultipliedByTheLevel():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        NewGame("I,I,I").
        mGame:StartLevel = 3.
        mGame:StartWith("I,I,I").
        mGame:LoadLocked(GappedRows(1)).
        mGame:RotateClockwise().
        DO i = 1 TO 3:
            mGame:MoveRight().
        END.
        mGame:HardDrop().
        Assert:Equals(300 + 32, mGame:Score).
        Assert:Equals(3, mGame:Level).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryTenLinesRaiseTheLevelAndTheGravityGetsFaster():
        DEFINE VARIABLE round AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        NewGame("I,I,I,I,I,I,I,I,I,I,I,I").
        DO round = 1 TO 3:
            mGame:LoadLocked(GappedRows(4)).
            mGame:RotateClockwise().
            DO i = 1 TO 3:
                mGame:MoveRight().
            END.
            mGame:HardDrop().
            IF round = 2 THEN DO:
                Assert:Equals(8, mGame:LinesCleared).
                Assert:Equals(1, mGame:Level).
            END.
        END.
        Assert:Equals(12, mGame:LinesCleared).
        Assert:Equals(2, mGame:Level).
        Assert:Equals(725, mGame:GravityMs).
        /* the third set was cleared at level one, so all three scored 832 */
        Assert:Equals(3 * 832, mGame:Score).
    END METHOD.

    /* ---- the end ---- */

    @Test.
    METHOD PUBLIC VOID TheGameIsOverWhenANewPieceHasNoRoomToAppear():
        DEFINE VARIABLE drops AS INTEGER NO-UNDO.
        NewGame("O,O,O,O,O,O,O,O,O,O,O,O").
        DO WHILE NOT mGame:IsOver AND drops < 15:
            mGame:HardDrop().
            drops = drops + 1.
        END.
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(10, drops).
        Assert:Equals(0, mGame:CurrentPiece).
        Assert:Equals(0, ActiveCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingWorksOnceTheGameIsOver():
        DEFINE VARIABLE drops AS INTEGER NO-UNDO.
        NewGame("O,O,O,O,O,O,O,O,O,O,O,O").
        DO WHILE NOT mGame:IsOver AND drops < 15:
            mGame:HardDrop().
            drops = drops + 1.
        END.
        Assert:IsFalse(mGame:MoveLeft()).
        Assert:IsFalse(mGame:MoveRight()).
        Assert:IsFalse(mGame:SoftDrop()).
        Assert:IsFalse(mGame:HardDrop()).
        Assert:IsFalse(mGame:RotateClockwise()).
        Assert:IsFalse(mGame:RotateCounterClockwise()).
        Assert:IsFalse(mGame:Tick(5000)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SettledBlocksThatLeaveNoRoomAtTheTopEndTheGameAtOnce():
        NewGame("I,O,T").
        mGame:LoadLocked("........../..........//" + "IIIIIIIIII").
        Assert:IsFalse(mGame:IsOver).
        mGame:Dispose().
        NewGame("I,O,T").
        mGame:LoadLocked("IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII/IIIIIIIIII").
        Assert:IsTrue(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameAfterGameOverStartsClean():
        DEFINE VARIABLE drops AS INTEGER NO-UNDO.
        NewGame("O,O,O,O,O,O,O,O,O,O,O,O").
        DO WHILE NOT mGame:IsOver AND drops < 15:
            mGame:HardDrop().
            drops = drops + 1.
        END.
        mGame:Initialise().
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, LockedCount()).
        Assert:Equals(4, ActiveCount()).
    END METHOD.

    /* ---- pausing ---- */

    @Test.
    METHOD PUBLIC VOID WhilePausedTimeAndMovesDoNothing():
        NewGame("I,O,T").
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:Tick(10000)).
        Assert:IsFalse(mGame:MoveLeft()).
        Assert:IsFalse(mGame:SoftDrop()).
        Assert:IsFalse(mGame:HardDrop()).
        Assert:IsFalse(mGame:RotateClockwise()).
        Assert:Equals(0, mGame:PieceY).
        Assert:Equals(3, mGame:PieceX).
        mGame:Paused = FALSE.
        Assert:IsTrue(mGame:MoveLeft()).
        Assert:IsTrue(mGame:Tick(800)).
    END METHOD.

    /* ---- the ghost ---- */

    @Test.
    METHOD PUBLIC VOID TheGhostIsWhereThePieceWouldLand():
        NewGame("I,O,T").
        Assert:Equals(19, mGame:GhostY()).
        mGame:LoadLocked("OO......../OO......../..........").
        mGame:MoveLeft().
        mGame:MoveLeft().
        mGame:MoveLeft().
        Assert:Equals(16, mGame:GhostY()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TurningTheGhostOffRemovesItFromTheView():
        NewGame("I,O,T").
        mGame:ShowGhost = FALSE.
        Assert:Equals("..........|______", Row(19)).
        mGame:ShowGhost = TRUE.
        Assert:Equals("...::::...|______", Row(19)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePieceIsDrawnOverTheGhostWhenItIsOnTheFloor():
        NewGame("I,O,T").
        mGame:Tick(19 * 800).
        Assert:Equals("...IIII...|______", Row(19)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SettledBlocksAreDrawnInTheirPiecesColours():
        NewGame("I,O,T").
        mGame:LoadLocked("OO......../TTT.......").
        Assert:Equals("OO........|______", Row(18)).
        Assert:Equals("TTT::::...|______", Row(19)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePanelShowsTheNextPieceAndChangesWhenAPieceSettles():
        NewGame("I,O,T").
        mGame:HardDrop().
        Assert:Equals("..........|__T___", Row(2)).
        Assert:Equals("..........|_TTT__", Row(3)).
    END METHOD.

    /* ---- setting up ---- */

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ARowWiderThanTheBoardIsRefused():
        NewGame("I").
        mGame:LoadLocked("IIIIIIIIIII").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID MoreRowsThanTheBoardHasAreRefused():
        NewGame("I").
        mGame:LoadLocked("I/I/I/I/I/I/I/I/I/I/I/I/I/I/I/I/I/I/I/I/I").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID APieceLetterThatDoesNotExistIsRefused():
        NewGame("I").
        mGame:LoadLocked("Q").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID StartWithAnUnknownPieceIsRefused():
        NewGame("I").
        mGame:StartWith("I,W").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LockedAtAndActiveAtRefuseCellsOffTheBoard():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        NewGame("I").
        DO ON ERROR UNDO, THROW:
            mGame:LockedAt(10, 0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:ActiveAt(0, 20).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheConstructorRefusesAnythingThatIsNotATetrisGrid():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE g      AS TetrisGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW TetrisGame(NEW Grid(NEW TableStore(17, 20, "locked,active,view")), NEW SeededRandom(1)).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = NEW TetrisGame(NEW Grid(NEW TableStore(12, 20, TetrisFactory:Layers())), NEW SeededRandom(1)).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = NEW TetrisGame(NEW Grid(NEW TableStore(17, 5, TetrisFactory:Layers())), NEW SeededRandom(1)).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = NEW TetrisGame(NEW Grid(NEW TableStore(17, 20, TetrisFactory:Layers()), NEW ToroidalTopology(), NEW MooreNeighbourhood()), NEW SeededRandom(1)).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = TetrisFactory:Create(?).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(5, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABoardOfAnotherSizeWorks():
        DEFINE VARIABLE g AS TetrisGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = TetrisFactory:CreateSized(8, 12, NEW SeededRandom(2)).
            Assert:Equals(8, g:BoardWidth).
            Assert:Equals(12, g:BoardHeight).
            Assert:Equals(15, g:Grid:Width).
            Assert:IsTrue(g:HardDrop()).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- whole games ---- */

    @Test.
    METHOD PUBLIC VOID APlayerWhoDoesNothingLosesWhenThePiecesPileUpAndTheClockStops():
        DEFINE VARIABLE clock      AS FakeClock          NO-UNDO.
        DEFINE VARIABLE controller AS RealTimeController NO-UNDO.
        DEFINE VARIABLE renderer   AS TextGridRenderer   NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NewGame("O,O,O,O,O,O,O,O,O,O,O,O").
            clock = NEW FakeClock().
            clock:Interval = 50.
            renderer = NEW TextGridRenderer("view", TetrisLook:TextSymbols()).
            controller = NEW RealTimeController(mGame, renderer, clock).
            controller:Start().
            clock:Advance(300000).
            Assert:IsTrue(mGame:IsOver).
            Assert:IsFalse(controller:IsRunning).
            Assert:Equals(0, mGame:Score).
            Assert:IsTrue(renderer:RenderCount > 10).
            FINALLY:
                IF VALID-OBJECT(controller) THEN controller:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARandomPlayerNeverBreaksTheBoardAndTheGameAlwaysEnds():
        DEFINE VARIABLE rnd   AS SeededRandom NO-UNDO.
        DEFINE VARIABLE step  AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE bad   AS INTEGER NO-UNDO.
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        DEFINE VARIABLE overlap AS INTEGER NO-UNDO.
        mGame = TetrisFactory:Create(NEW SeededRandom(9)).
        rnd = NEW SeededRandom(77).
        DO step = 1 TO 400 WHILE NOT mGame:IsOver:
            before = mGame:Score.
            CASE rnd:NextInt(7):
                WHEN 0 THEN mGame:MoveLeft().
                WHEN 1 THEN mGame:MoveRight().
                WHEN 2 THEN mGame:RotateClockwise().
                WHEN 3 THEN mGame:RotateCounterClockwise().
                WHEN 4 THEN mGame:SoftDrop().
                WHEN 5 THEN mGame:Tick(800).
                OTHERWISE mGame:HardDrop().
            END CASE.
            IF mGame:Score < before THEN bad = bad + 1.
            IF NOT mGame:IsOver AND ActiveCount() <> 4 THEN bad = bad + 1.
            IF step MODULO 10 = 0 THEN DO y = 0 TO 19:
                DO x = 0 TO 9:
                    IF mGame:ActiveAt(x, y) AND mGame:LockedAt(x, y) <> 0 THEN overlap = overlap + 1.
                END.
            END.
        END.
        Assert:Equals(0, bad).
        Assert:Equals(0, overlap).
        Assert:IsTrue(mGame:Score > 0).
    END METHOD.

END CLASS.
