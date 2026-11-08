/* The maze map: a maze read from text, tile by tile. The symbols are # wall, _ path, . bit, o commit, - door, = phantom lobby floor,
   T tunnel path (where phantoms are slow), N a bit and U an empty path where phantoms may not turn up (there are twelve such
   tiles), and the starts P (Dibby, there must be exactly one), M R B C (Mary, Rich, Brian, Chip, each at most one) and F
   (the item, at most one). A start sits on a tile: across it means the left edge of the tile, down it means the middle (so a
   start at column 5 row 3 is x 40, y 28). Under M, P and F the tile is path and under R, B and C it is phantom lobby floor. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.MazeMapTests:

    VAR PRIVATE MazeMap mMaze.

    @Setup.
    METHOD PUBLIC VOID BuildMaze():
        /* seven across, five down: a bit, a commit and a door along the top, the lobby and two starts in the middle, a tunnel
           tile, two no up tiles and Dibby along the bottom */
        mMaze = NEW MazeMap(ForEachKit:Pipes("#######|#.o_.-#|#=R=M.#|#TNU.P#|#######")).
    END METHOD.

    METHOD PRIVATE LOGICAL ThrowsGridException(INPUT piWhich AS INTEGER):
        VAR MazeMap other.
        VAR INTEGER n.
        DO ON ERROR UNDO, THROW:
            CASE piWhich:
                WHEN 1 THEN other = NEW MazeMap("").
                WHEN 2 THEN other = NEW MazeMap(?).
                WHEN 3 THEN other = NEW MazeMap(ForEachKit:Pipes("####|#P#|####")).
                WHEN 4 THEN other = NEW MazeMap(ForEachKit:Pipes("####|#Z_#|####")).
                WHEN 5 THEN other = NEW MazeMap(ForEachKit:Pipes("####|#__#|####")).
                WHEN 6 THEN other = NEW MazeMap(ForEachKit:Pipes("####|#PP#|####")).
                WHEN 7 THEN other = NEW MazeMap(ForEachKit:Pipes("#####|#PBB#|#####")).
                WHEN 8 THEN mMaze:KindAt(1, 5).
                WHEN 9 THEN mMaze:KindAt(1, -1).
                WHEN 10 THEN mMaze:Take(1, 9).
                WHEN 11 THEN mMaze:PhantomStartX(PhantomKind:Brian).
                WHEN 12 THEN n = mMaze:ItemX.
                WHEN 13 THEN mMaze:CanEnter(1, 7, FALSE).
                WHEN 14 THEN mMaze:IsTunnel(1, 7).
                WHEN 15 THEN mMaze:NoUpAt(1, 7).
            END CASE.
            RETURN FALSE.
            CATCH e AS GridException:
                RETURN TRUE.
            END CATCH.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMazeIsTheSizeOfTheText():
        Assert:Equals(7, mMaze:Cols).
        Assert:Equals(5, mMaze:Rows).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMazeMustBeTextWithOneBlockOfEqualRowsAndOneDibbyStart():
        Assert:IsTrue(ThrowsGridException(1)).
        Assert:IsTrue(ThrowsGridException(2)).
        Assert:IsTrue(ThrowsGridException(3)).
        Assert:IsTrue(ThrowsGridException(4)).
        Assert:IsTrue(ThrowsGridException(5)).
        Assert:IsTrue(ThrowsGridException(6)).
        Assert:IsTrue(ThrowsGridException(7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID KindAtGivesWhatEachSymbolStandsFor():
        Assert:Equals(TileKind:Wall, mMaze:KindAt(0, 0)).
        Assert:Equals(TileKind:Bit, mMaze:KindAt(1, 1)).
        Assert:Equals(TileKind:Commit, mMaze:KindAt(2, 1)).
        Assert:Equals(TileKind:Path, mMaze:KindAt(3, 1)).
        Assert:Equals(TileKind:Door, mMaze:KindAt(5, 1)).
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(1, 2)).
        Assert:Equals(TileKind:Path, mMaze:KindAt(1, 3)).
        Assert:Equals(TileKind:Bit, mMaze:KindAt(2, 3)).
        Assert:Equals(TileKind:Path, mMaze:KindAt(3, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTileUnderAStartIsPathExceptInThePhantomLobby():
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(2, 2)).
        Assert:Equals(TileKind:Path, mMaze:KindAt(4, 2)).
        Assert:Equals(TileKind:Path, mMaze:KindAt(5, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AColumnOffTheEdgeComesRoundToTheOtherSideAndARowOffTheMazeIsRefused():
        Assert:Equals(mMaze:KindAt(6, 3), mMaze:KindAt(-1, 3)).
        Assert:Equals(mMaze:KindAt(0, 3), mMaze:KindAt(7, 3)).
        Assert:IsTrue(ThrowsGridException(8)).
        Assert:IsTrue(ThrowsGridException(9)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BitsTotalCountsEveryBitAndCommitAndBitsLeftStartsEqual():
        Assert:Equals(6, mMaze:BitsTotal).
        Assert:Equals(6, mMaze:BitsLeft).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TakeEatsABitOrACommitAndSaysWhichItWas():
        Assert:Equals(TileKind:Commit, mMaze:Take(2, 1)).
        Assert:Equals(TileKind:Path, mMaze:KindAt(2, 1)).
        Assert:Equals(5, mMaze:BitsLeft).
        Assert:Equals(TileKind:Bit, mMaze:Take(1, 1)).
        Assert:Equals(4, mMaze:BitsLeft).
        Assert:Equals(6, mMaze:BitsTotal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TakeOnAnythingElseEatsNothing():
        Assert:Equals(TileKind:Path, mMaze:Take(3, 1)).
        Assert:Equals(TileKind:Wall, mMaze:Take(0, 0)).
        Assert:Equals(6, mMaze:BitsLeft).
        Assert:IsTrue(ThrowsGridException(10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RefillPutsEveryBitAndCommitBack():
        mMaze:Take(1, 1).
        mMaze:Take(2, 1).
        mMaze:Take(5, 2).
        mMaze:Refill().
        Assert:Equals(6, mMaze:BitsLeft).
        Assert:Equals(TileKind:Bit, mMaze:KindAt(1, 1)).
        Assert:Equals(TileKind:Commit, mMaze:KindAt(2, 1)).
        Assert:Equals(TileKind:Bit, mMaze:KindAt(5, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DibbyWalksOnPathAndBitsButNotThroughWallsTheDoorOrTheLobby():
        Assert:IsTrue(mMaze:CanEnter(3, 1, FALSE)).
        Assert:IsTrue(mMaze:CanEnter(1, 1, FALSE)).
        Assert:IsTrue(mMaze:CanEnter(2, 1, FALSE)).
        Assert:IsFalse(mMaze:CanEnter(0, 0, FALSE)).
        Assert:IsFalse(mMaze:CanEnter(5, 1, FALSE)).
        Assert:IsFalse(mMaze:CanEnter(1, 2, FALSE)).
        Assert:IsFalse(mMaze:CanEnter(2, 2, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomCanAlsoUseTheDoorAndTheLobbyButNeverAWall():
        Assert:IsTrue(mMaze:CanEnter(3, 1, TRUE)).
        Assert:IsTrue(mMaze:CanEnter(5, 1, TRUE)).
        Assert:IsTrue(mMaze:CanEnter(1, 2, TRUE)).
        Assert:IsTrue(mMaze:CanEnter(2, 2, TRUE)).
        Assert:IsFalse(mMaze:CanEnter(0, 0, TRUE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CanEnterAlsoWrapsAColumnOffTheEdge():
        VAR MazeMap tunnel = NEW MazeMap(ForEachKit:TunnelCorridor()).
        Assert:IsTrue(tunnel:CanEnter(-1, 1, FALSE)).
        Assert:IsTrue(tunnel:CanEnter(20, 1, FALSE)).
        Assert:IsFalse(mMaze:CanEnter(-1, 3, FALSE)).
        Assert:IsTrue(ThrowsGridException(13)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TunnelTilesAreMarkedAndPlainPathIsNot():
        Assert:IsTrue(mMaze:IsTunnel(1, 3)).
        Assert:IsFalse(mMaze:IsTunnel(2, 3)).
        Assert:IsFalse(mMaze:IsTunnel(3, 1)).
        Assert:IsTrue(ThrowsGridException(14)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NoUpTilesAreMarkedWhetherOrNotTheyHoldABit():
        Assert:IsTrue(mMaze:NoUpAt(2, 3)).
        Assert:IsTrue(mMaze:NoUpAt(3, 3)).
        Assert:IsFalse(mMaze:NoUpAt(4, 3)).
        Assert:IsFalse(mMaze:NoUpAt(1, 1)).
        Assert:IsTrue(ThrowsGridException(15)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DibbyStartsAtTheLeftEdgeOfItsTileAndInTheMiddleOfItsRow():
        Assert:Equals(40, mMaze:DibbyStartX).
        Assert:Equals(28, mMaze:DibbyStartY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APhantomStartIsFoundTheSameWay():
        Assert:IsTrue(mMaze:HasPhantomStart(PhantomKind:Mary)).
        Assert:IsTrue(mMaze:HasPhantomStart(PhantomKind:Rich)).
        Assert:IsFalse(mMaze:HasPhantomStart(PhantomKind:Brian)).
        Assert:IsFalse(mMaze:HasPhantomStart(PhantomKind:Chip)).
        Assert:Equals(32, mMaze:PhantomStartX(PhantomKind:Mary)).
        Assert:Equals(20, mMaze:PhantomStartY(PhantomKind:Mary)).
        Assert:Equals(16, mMaze:PhantomStartX(PhantomKind:Rich)).
        Assert:Equals(20, mMaze:PhantomStartY(PhantomKind:Rich)).
        Assert:IsTrue(ThrowsGridException(11)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheItemSpotIsOptionalAndFoundTheSameWay():
        VAR MazeMap item.
        Assert:IsFalse(mMaze:HasItemSpot).
        Assert:IsTrue(ThrowsGridException(12)).
        item = NEW MazeMap(ForEachKit:ItemCorridor()).
        Assert:IsTrue(item:HasItemSpot).
        Assert:Equals(24, item:ItemX).
        Assert:Equals(12, item:ItemY).
    END METHOD.

END CLASS.
