/* The maze of FOR EACH (section 2.1 of docs/design/foreach-art.md), as the game plays it: 28 tiles across and 31 down, 240 bits
   and 4 commit tokens, the two halves mirror images, the phantom lobby in the middle (8 x 3 inside, with its door on top), the two
   tunnels on row 14, the 12 tiles where phantoms may not turn up (columns 11 to 16 of rows 11 and 23), and every start where the
   design has it. Rows are counted from the top of the maze (the 24 pixel score strip above it is not counted). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachMazeTests:

    VAR PRIVATE MazeMap mMaze.

    @Setup.
    METHOD PUBLIC VOID BuildMaze():
        mMaze = NEW MazeMap(ForEachMaze:Layout()).
    END METHOD.

    /* How many tiles of the maze are of this kind. */
    METHOD PRIVATE INTEGER CountOf(INPUT poKind AS TileKind):
        VAR INTEGER cc.
        VAR INTEGER rr.
        VAR INTEGER n.
        DO rr = 0 TO mMaze:Rows - 1:
            DO cc = 0 TO mMaze:Cols - 1:
                IF mMaze:KindAt(cc, rr) = poKind THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMazeIs28TilesAcrossAnd31Down():
        Assert:Equals(28, mMaze:Cols).
        Assert:Equals(31, mMaze:Rows).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereAre240BitsAnd4CommitsSo244ThingsToEat():
        Assert:Equals(240, CountOf(TileKind:Bit)).
        Assert:Equals(4, CountOf(TileKind:Commit)).
        Assert:Equals(244, mMaze:BitsTotal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCommitsAreInTheFourCornersAreas():
        Assert:Equals(TileKind:Commit, mMaze:KindAt(1, 3)).
        Assert:Equals(TileKind:Commit, mMaze:KindAt(26, 3)).
        Assert:Equals(TileKind:Commit, mMaze:KindAt(1, 23)).
        Assert:Equals(TileKind:Commit, mMaze:KindAt(26, 23)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLeftHalfIsTheMirrorImageOfTheRightHalf():
        VAR INTEGER cc.
        VAR INTEGER rr.
        DO rr = 0 TO 30:
            DO cc = 0 TO 13:
                Assert:Equals(mMaze:KindAt(cc, rr), mMaze:KindAt(27 - cc, rr)).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTopAndBottomRowsAreWall():
        VAR INTEGER cc.
        DO cc = 0 TO 27:
            Assert:Equals(TileKind:Wall, mMaze:KindAt(cc, 0)).
            Assert:Equals(TileKind:Wall, mMaze:KindAt(cc, 30)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSidesAreWallExceptWhereTheTunnelLeavesOnRow14():
        VAR INTEGER rr.
        DO rr = 0 TO 30:
            IF rr = 14 THEN DO:
                Assert:IsTrue(mMaze:KindAt(0, rr) <> TileKind:Wall).
                Assert:IsTrue(mMaze:KindAt(27, rr) <> TileKind:Wall).
            END.
            ELSE DO:
                Assert:Equals(TileKind:Wall, mMaze:KindAt(0, rr)).
                Assert:Equals(TileKind:Wall, mMaze:KindAt(27, rr)).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTunnelIsSlowForFiveTilesAtEachEndOfRow14AndNowhereElse():
        VAR INTEGER cc.
        VAR INTEGER rr.
        DO rr = 0 TO 30:
            DO cc = 0 TO 27:
                IF rr = 14 AND (cc <= 4 OR cc >= 23) THEN
                    Assert:IsTrue(mMaze:IsTunnel(cc, rr)).
                ELSE
                    Assert:IsFalse(mMaze:IsTunnel(cc, rr)).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePhantomLobbyHasADoorOnTopAndRoomForThreePhantomsInside():
        Assert:Equals(TileKind:Door, mMaze:KindAt(13, 12)).
        Assert:Equals(TileKind:Door, mMaze:KindAt(14, 12)).
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(11, 14)).
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(13, 14)).
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(14, 14)).
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(16, 14)).
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(13, 13)).
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(13, 15)).
        Assert:Equals(TileKind:Wall, mMaze:KindAt(12, 12)).
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(10, 14)).
        Assert:Equals(TileKind:Lobby, mMaze:KindAt(17, 14)).
        Assert:Equals(TileKind:Wall, mMaze:KindAt(9, 14)).
        Assert:Equals(TileKind:Wall, mMaze:KindAt(18, 14)).
        Assert:Equals(TileKind:Wall, mMaze:KindAt(13, 16)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TwelveTilesStopAPhantomTurningUpSixAboveTheLobbyAndSixAboveDibbysStart():
        VAR INTEGER cc.
        VAR INTEGER rr.
        VAR INTEGER n.
        DO rr = 0 TO 30:
            DO cc = 0 TO 27:
                IF mMaze:NoUpAt(cc, rr) THEN n = n + 1.
            END.
        END.
        Assert:Equals(12, n).
        DO cc = 11 TO 16:
            Assert:IsTrue(mMaze:NoUpAt(cc, 11)).
            Assert:IsTrue(mMaze:NoUpAt(cc, 23)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryoneStartsWhereTheyBelong():
        Assert:Equals(112, mMaze:DibbyStartX).
        Assert:Equals(188, mMaze:DibbyStartY).
        Assert:Equals(112, mMaze:PhantomStartX(PhantomKind:Mary)).
        Assert:Equals(92, mMaze:PhantomStartY(PhantomKind:Mary)).
        Assert:Equals(112, mMaze:PhantomStartX(PhantomKind:Rich)).
        Assert:Equals(116, mMaze:PhantomStartY(PhantomKind:Rich)).
        Assert:Equals(96, mMaze:PhantomStartX(PhantomKind:Brian)).
        Assert:Equals(116, mMaze:PhantomStartY(PhantomKind:Brian)).
        Assert:Equals(128, mMaze:PhantomStartX(PhantomKind:Chip)).
        Assert:Equals(116, mMaze:PhantomStartY(PhantomKind:Chip)).
        Assert:IsTrue(mMaze:HasItemSpot).
        Assert:Equals(112, mMaze:ItemX).
        Assert:Equals(140, mMaze:ItemY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryBitAndCommitCanBeReachedFromWhereDibbyStarts():
        VAR LOGICAL[868] seen.
        VAR INTEGER[868] queue.
        VAR INTEGER qIn.
        VAR INTEGER qOut.
        VAR INTEGER cc.
        VAR INTEGER rr.
        VAR INTEGER nc.
        VAR INTEGER nr.
        VAR INTEGER d.
        VAR MazeDir dir.
        VAR INTEGER missed.
        qIn = 1.
        qOut = 1.
        cc = INTEGER(TRUNCATE(mMaze:DibbyStartX / 8, 0)).
        rr = INTEGER(TRUNCATE(mMaze:DibbyStartY / 8, 0)).
        queue[1] = rr * 28 + cc.
        seen[rr * 28 + cc + 1] = TRUE.
        qIn = 2.
        DO WHILE qOut < qIn:
            rr = INTEGER(TRUNCATE(queue[qOut] / 28, 0)).
            cc = queue[qOut] MODULO 28.
            qOut = qOut + 1.
            DO d = 1 TO 4:
                dir = MazeDir:GetEnum(d).
                nc = (cc + MazeDirs:Dx(dir) + 28) MODULO 28.
                nr = rr + MazeDirs:Dy(dir).
                IF nr >= 0 AND nr <= 30 AND mMaze:CanEnter(nc, nr, FALSE) AND NOT seen[nr * 28 + nc + 1] THEN DO:
                    seen[nr * 28 + nc + 1] = TRUE.
                    queue[qIn] = nr * 28 + nc.
                    qIn = qIn + 1.
                END.
            END.
        END.
        DO rr = 0 TO 30:
            DO cc = 0 TO 27:
                IF (mMaze:KindAt(cc, rr) = TileKind:Bit OR mMaze:KindAt(cc, rr) = TileKind:Commit) AND NOT seen[rr * 28 + cc + 1] THEN missed = missed + 1.
            END.
        END.
        Assert:Equals(0, missed).
    END METHOD.

END CLASS.
