USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Battleships.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* The rules, one at a time. Fleets are set up with LoadBoards so every test knows where the ships
   are: "X" is a ship cell, "." is water, "/" ends a row. The grid is read back as text with the
   symbols of BattleshipsLook:TextSymbols(), the computer's waters on the left of the "|" and the
   player's fleet on the right. */
CLASS ProGriddle.Games.Battleships.BattleshipsGameTests:

    DEFINE PRIVATE VARIABLE mGame     AS BattleshipsGame  NO-UNDO.
    DEFINE PRIVATE VARIABLE mOpponent AS ScriptedOpponent NO-UNDO.
    DEFINE PRIVATE VARIABLE mText     AS TextGridRenderer NO-UNDO.

    @Test.
    METHOD PUBLIC VOID TheFixturesAreValid():
        DEFINE VARIABLE g AS BattleshipsGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), NEW ScriptedOpponent("")).
            g:LoadBoards(Own(), Enemy()).
            Assert:Equals(7, CountShips(g, TRUE)).
            Assert:Equals(7, CountShips(g, FALSE)).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* Rows of the player's board: A (2 across the top), B (3 across the middle), C (2 down the left). */
    METHOD PRIVATE CHARACTER Own():
        RETURN "XX.../...../..XXX/X..../X....".
    END METHOD.

    /* The computer's board: a 2 down the left, a 2 across the top right, a 3 near the bottom. */
    METHOD PRIVATE CHARACTER Enemy():
        RETURN "X..XX/X..../...../.XXX./.....".
    END METHOD.

    /* Every water cell of the player's board in reading order as "x,y;x,y;...", so a computer that
       fires them in order never hits anything. */
    METHOD PRIVATE CHARACTER WaterShots():
        DEFINE VARIABLE x      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DO y = 0 TO 4:
            DO x = 0 TO 4:
                IF SUBSTRING(ENTRY(y + 1, Own(), "/"), x + 1, 1) <> "X" THEN result = result + (IF result = "" THEN "" ELSE ";") + SUBSTITUTE("&1,&2", x, y).
            END.
        END.
        RETURN result.
    END METHOD.

    /* A game on 5 x 5 boards with both fleets loaded and the computer firing the given shots. */
    METHOD PRIVATE VOID StartGame(INPUT pcComputerShots AS CHARACTER):
        mOpponent = NEW ScriptedOpponent(pcComputerShots).
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        mGame:LoadBoards(Own(), Enemy()).
        mText = NEW TextGridRenderer("view", BattleshipsLook:TextSymbols()).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* The grid as text, rows joined by "/". */
    METHOD PRIVATE CHARACTER Board():
        RETURN REPLACE(mText:ToText(mGame:Grid), CHR(10), "/").
    END METHOD.

    /* Number of ship cells on one board. */
    METHOD PRIVATE INTEGER CountShips(INPUT poGame AS BattleshipsGame, INPUT plOwn AS LOGICAL):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = 0 TO poGame:BoardHeight - 1:
            DO x = 0 TO poGame:BoardWidth - 1:
                IF (IF plOwn THEN poGame:OwnShipAt(x, y) ELSE poGame:EnemyShipAt(x, y)) <> 0 THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    /* How many rules a board breaks: a ship that is not a straight line of the right length, a
       cell next to a different ship, a ship of one cell. Zero means it is a legal fleet. */
    METHOD PRIVATE INTEGER Violations(INPUT poGame AS BattleshipsGame, INPUT plOwn AS LOGICAL):
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE id     AS INTEGER NO-UNDO.
        DEFINE VARIABLE other  AS INTEGER NO-UNDO.
        DEFINE VARIABLE bad    AS INTEGER NO-UNDO.
        DEFINE VARIABLE cells  AS INTEGER NO-UNDO EXTENT 100.
        DEFINE VARIABLE minX   AS INTEGER NO-UNDO EXTENT 100.
        DEFINE VARIABLE maxX   AS INTEGER NO-UNDO EXTENT 100.
        DEFINE VARIABLE minY   AS INTEGER NO-UNDO EXTENT 100.
        DEFINE VARIABLE maxY   AS INTEGER NO-UNDO EXTENT 100.
        DO id = 1 TO poGame:FleetCount:
            minX[id] = 999.
            minY[id] = 999.
            maxX[id] = -1.
            maxY[id] = -1.
        END.
        DO y = 0 TO poGame:BoardHeight - 1:
            DO x = 0 TO poGame:BoardWidth - 1:
                id = (IF plOwn THEN poGame:OwnShipAt(x, y) ELSE poGame:EnemyShipAt(x, y)).
                IF id = 0 THEN NEXT.
                cells[id] = cells[id] + 1.
                minX[id] = MINIMUM(minX[id], x).
                maxX[id] = MAXIMUM(maxX[id], x).
                minY[id] = MINIMUM(minY[id], y).
                maxY[id] = MAXIMUM(maxY[id], y).
                DO dy = -1 TO 1:
                    DO dx = -1 TO 1:
                        IF x + dx < 0 OR x + dx >= poGame:BoardWidth OR y + dy < 0 OR y + dy >= poGame:BoardHeight THEN NEXT.
                        other = (IF plOwn THEN poGame:OwnShipAt(x + dx, y + dy) ELSE poGame:EnemyShipAt(x + dx, y + dy)).
                        IF other <> 0 AND other <> id THEN bad = bad + 1.
                    END.
                END.
            END.
        END.
        DO id = 1 TO poGame:FleetCount:
            IF cells[id] <> poGame:FleetLength(id) OR poGame:FleetLength(id) < 2 THEN bad = bad + 1.
            IF NOT (minX[id] = maxX[id] OR minY[id] = maxY[id]) THEN bad = bad + 1.
            IF (maxX[id] - minX[id] + 1) * (maxY[id] - minY[id] + 1) <> cells[id] THEN bad = bad + 1.
        END.
        RETURN bad.
    END METHOD.

    /* ---- a new game ---- */

    @Test.
    METHOD PUBLIC VOID ANewGameHasBothBoardsSideBySideInOneGrid():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        mText = NEW TextGridRenderer("view", BattleshipsLook:TextSymbols()).
        Assert:Equals(11, mGame:Grid:Width).
        Assert:Equals(5, mGame:Grid:Height).
        Assert:Equals(5, mGame:BoardWidth).
        Assert:Equals(6, mGame:OwnLeft).
        Assert:Equals(3, mGame:FleetCount).
        Assert:Equals("#####|...../#####|...../#####|...../#####|...../#####|.....", Board()).
        Assert:Equals(0, mGame:Turn).
        Assert:IsFalse(mGame:IsOver).
        Assert:IsFalse(mGame:Started).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheComputersFleetIsAlreadyHiddenOnItsBoard():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        Assert:Equals(7, CountShips(mGame, FALSE)).
        Assert:Equals(0, CountShips(mGame, TRUE)).
        Assert:Equals(0, Violations(mGame, FALSE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFleetIsKeptLongestFirstWhateverOrderItIsGivenIn():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(8, 8, "2,4,3,2", NEW SeededRandom(1), mOpponent).
        Assert:Equals(4, mGame:FleetLength(1)).
        Assert:Equals(3, mGame:FleetLength(2)).
        Assert:Equals(2, mGame:FleetLength(3)).
        Assert:Equals(2, mGame:FleetLength(4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryStandardSizeGetsLegalFleetsOnBothSides():
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE seed  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE sizeName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE g     AS BattleshipsGame NO-UNDO.
        DEFINE VARIABLE bad   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE wrong AS INTEGER   NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(BattleshipsFleets:Names()):
            sizeName = ENTRY(i, BattleshipsFleets:Names()).
            DO seed = 1 TO 12 ON ERROR UNDO, THROW:
                g = BattleshipsFactory:Create(BattleshipsFleets:SideOf(sizeName), BattleshipsFleets:SideOf(sizeName),
                                              BattleshipsFleets:FleetOf(sizeName), NEW SeededRandom(seed), NEW ScriptedOpponent("")).
                g:RandomiseFleet().
                bad = bad + Violations(g, TRUE) + Violations(g, FALSE).
                IF CountShips(g, TRUE) <> BattleshipsFleets:CellsOf(sizeName) OR CountShips(g, FALSE) <> BattleshipsFleets:CellsOf(sizeName) THEN wrong = wrong + 1.
                FINALLY:
                    IF VALID-OBJECT(g) THEN g:Dispose().
                END FINALLY.
            END.
        END.
        Assert:Equals(0, bad).
        Assert:Equals(0, wrong).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameSeedPlacesTheSameFleet():
        DEFINE VARIABLE a AS BattleshipsGame NO-UNDO.
        DEFINE VARIABLE b AS BattleshipsGame NO-UNDO.
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE differ AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            a = BattleshipsFactory:Create(10, 10, "5,4,3,3,2", NEW SeededRandom(5), NEW ScriptedOpponent("")).
            b = BattleshipsFactory:Create(10, 10, "5,4,3,3,2", NEW SeededRandom(5), NEW ScriptedOpponent("")).
            DO y = 0 TO 9:
                DO x = 0 TO 9:
                    IF a:EnemyShipAt(x, y) <> b:EnemyShipAt(x, y) THEN differ = differ + 1.
                END.
            END.
            Assert:Equals(0, differ).
            FINALLY:
                IF VALID-OBJECT(a) THEN a:Dispose().
                IF VALID-OBJECT(b) THEN b:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheOpponentIsToldTheBoardSizeAtTheStart():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        Assert:Equals(1, mOpponent:ResetCount).
        Assert:Equals(5, mOpponent:Width).
        Assert:Equals(5, mOpponent:Height).
        mGame:Initialise().
        Assert:Equals(2, mOpponent:ResetCount).
    END METHOD.

    /* ---- placing your fleet ---- */

    @Test.
    METHOD PUBLIC VOID TheFirstShipPlacedIsTheLongestAndGoesAcrossFromTheCellClicked():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        mText = NEW TextGridRenderer("view", BattleshipsLook:TextSymbols()).
        Assert:Equals(3, mGame:CurrentShipLength).
        Assert:IsTrue(mGame:Horizontal).
        Assert:IsTrue(mGame:PlaceShip(1, 0)).
        Assert:Equals(1, mGame:OwnShipAt(1, 0)).
        Assert:Equals(1, mGame:OwnShipAt(3, 0)).
        Assert:Equals(0, mGame:OwnShipAt(0, 0)).
        Assert:Equals(0, mGame:OwnShipAt(4, 0)).
        Assert:Equals("#####|.SSS./#####|...../#####|...../#####|...../#####|.....", Board()).
        Assert:Equals(2, mGame:ShipsToPlace).
        Assert:Equals(2, mGame:CurrentShipLength).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RotateTurnsTheNextShipTheOtherWay():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        mGame:Rotate().
        Assert:IsFalse(mGame:Horizontal).
        Assert:IsTrue(mGame:PlaceShip(2, 1)).
        Assert:Equals(1, mGame:OwnShipAt(2, 1)).
        Assert:Equals(1, mGame:OwnShipAt(2, 2)).
        Assert:Equals(1, mGame:OwnShipAt(2, 3)).
        Assert:Equals(0, mGame:OwnShipAt(3, 1)).
        mGame:Rotate().
        Assert:IsTrue(mGame:Horizontal).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShipThatWouldHangOffTheBoardIsMovedBackToFit():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        Assert:IsTrue(mGame:PlaceShip(4, 4)).
        Assert:Equals(1, mGame:OwnShipAt(2, 4)).
        Assert:Equals(1, mGame:OwnShipAt(3, 4)).
        Assert:Equals(1, mGame:OwnShipAt(4, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShipsMayNotTouchSideOnEndOnOrAtACorner():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(7, 7, "3,2,2", NEW SeededRandom(1), mOpponent).
        mGame:PlaceShip(1, 1).
        /* the 3 ship covers (1,1) to (3,1). A 2 ship placed so that it ... */
        Assert:IsFalse(mGame:PlaceShip(1, 2)).
        Assert:IsFalse(mGame:PlaceShip(4, 1)).
        Assert:IsFalse(mGame:PlaceShip(4, 2)).
        Assert:IsFalse(mGame:PlaceShip(0, 0)).
        Assert:IsFalse(mGame:PlaceShip(3, 0)).
        Assert:Equals(2, mGame:ShipsToPlace).
        Assert:Equals(0, mGame:OwnShipAt(4, 1)).
        Assert:IsTrue(mGame:PlaceShip(5, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShipsOneCellApartAreAllowed():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(7, 7, "3,2,2", NEW SeededRandom(1), mOpponent).
        Assert:IsTrue(mGame:PlaceShip(0, 0)).
        Assert:IsTrue(mGame:PlaceShip(0, 2)).
        Assert:IsTrue(mGame:PlaceShip(0, 4)).
        Assert:IsTrue(mGame:FleetReady).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AVerticalShipCannotTouchEitherEnd():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(7, 7, "3,2,2", NEW SeededRandom(1), mOpponent).
        mGame:Rotate().
        mGame:PlaceShip(3, 2).
        /* the ship is (3,2) to (3,4): above it, below it and the corners are all out */
        Assert:IsFalse(mGame:PlaceShip(3, 0)).
        Assert:IsFalse(mGame:PlaceShip(3, 5)).
        Assert:IsFalse(mGame:PlaceShip(4, 5)).
        Assert:IsFalse(mGame:PlaceShip(2, 0)).
        Assert:IsTrue(mGame:PlaceShip(5, 5)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID PlacingOffTheBoardThrows():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        mGame:PlaceShip(5, 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RemoveShipTakesItBackAndItBecomesTheNextToPlace():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(7, 7, "3,2,2", NEW SeededRandom(1), mOpponent).
        mGame:PlaceShip(0, 0).
        mGame:PlaceShip(0, 2).
        Assert:Equals(2, mGame:CurrentShipLength).
        Assert:IsTrue(mGame:RemoveShip(1, 0)).
        Assert:Equals(0, mGame:OwnShipAt(0, 0)).
        Assert:Equals(0, mGame:OwnShipAt(2, 0)).
        Assert:Equals(2, mGame:ShipsToPlace).
        Assert:Equals(3, mGame:CurrentShipLength).
        Assert:Equals(2, mGame:OwnShipAt(0, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RemoveShipOnWaterDoesNothing():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(7, 7, "3,2,2", NEW SeededRandom(1), mOpponent).
        mGame:PlaceShip(0, 0).
        Assert:IsFalse(mGame:RemoveShip(5, 5)).
        Assert:Equals(2, mGame:ShipsToPlace).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnceTheFleetIsCompleteNoMoreShipsGoDown():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(7, 7, "3,2,2", NEW SeededRandom(1), mOpponent).
        mGame:PlaceShip(0, 0).
        mGame:PlaceShip(0, 2).
        mGame:PlaceShip(0, 4).
        Assert:IsTrue(mGame:FleetReady).
        Assert:Equals(0, mGame:CurrentShipLength).
        Assert:IsFalse(mGame:PlaceShip(4, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearFleetTakesEveryShipOff():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(7, 7, "3,2,2", NEW SeededRandom(1), mOpponent).
        mGame:PlaceShip(0, 0).
        mGame:PlaceShip(0, 2).
        Assert:IsTrue(mGame:ClearFleet()).
        Assert:Equals(0, CountShips(mGame, TRUE)).
        Assert:Equals(3, mGame:ShipsToPlace).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RandomiseFleetPlacesAWholeLegalFleetAndReplacesAnEarlierOne():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(8, 8, "4,3,3,2", NEW SeededRandom(7), mOpponent).
        mGame:PlaceShip(0, 0).
        Assert:IsTrue(mGame:RandomiseFleet()).
        Assert:IsTrue(mGame:FleetReady).
        Assert:Equals(12, CountShips(mGame, TRUE)).
        Assert:Equals(0, Violations(mGame, TRUE)).
        Assert:IsTrue(mGame:RandomiseFleet()).
        Assert:Equals(12, CountShips(mGame, TRUE)).
        Assert:Equals(0, Violations(mGame, TRUE)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFleetCannotBeChangedOnceShootingHasStarted():
        StartGame(WaterShots()).
        mGame:Fire(4, 4).
        Assert:IsTrue(mGame:Started).
        Assert:IsFalse(mGame:ClearFleet()).
        Assert:IsFalse(mGame:RandomiseFleet()).
        Assert:IsFalse(mGame:RemoveShip(0, 0)).
        Assert:IsFalse(mGame:PlaceShip(0, 1)).
        Assert:Equals(7, CountShips(mGame, TRUE)).
    END METHOD.

    /* ---- loading boards ---- */

    @Test.
    METHOD PUBLIC VOID LoadBoardsShowsBothFleetsAsReadyToStartAndHidesTheComputersOne():
        StartGame("").
        Assert:Equals("#####|SS.../#####|...../#####|..SSS/#####|S..../#####|S....", Board()).
        Assert:IsTrue(mGame:FleetReady).
        Assert:IsFalse(mGame:Started).
        Assert:Equals(1, mGame:OwnShipAt(2, 2)).
        Assert:Equals(0, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LoadBoardsGivesTheLongestShipNumberOne():
        StartGame("").
        Assert:Equals(1, mGame:OwnShipAt(2, 2)).
        Assert:Equals(1, mGame:EnemyShipAt(1, 3)).
        Assert:Equals(3, mGame:FleetLength(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LoadBoardsResizesTheGame():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(8, 8, "4,3,3,2", NEW SeededRandom(1), mOpponent).
        mGame:LoadBoards("XXX./..../XX../....", "XXX./..../..XX/....").
        Assert:Equals(4, mGame:BoardWidth).
        Assert:Equals(4, mGame:BoardHeight).
        Assert:Equals(2, mGame:FleetCount).
        Assert:Equals(9, mGame:Grid:Width).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABoardWithASingleCellShipIsRefused():
        StartGame("").
        mGame:LoadBoards("XX./.../..X", "XX./.../.XX").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABoardWhereShipsTouchAtACornerIsRefused():
        StartGame("").
        mGame:LoadBoards("XX../..XX/....", "XX../..../XX..").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABoardWhereShipsTouchSideToSideIsRefused():
        StartGame("").
        mGame:LoadBoards("XX./XX./...", "XX./.../XX.").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ABentShipIsRefused():
        StartGame("").
        mGame:LoadBoards("XX./X../...", "XX./.../XX.").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TwoBoardsOfDifferentFleetsAreRefused():
        StartGame("").
        mGame:LoadBoards("XX./.../XXX", "XX./.../XX.").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TwoBoardsOfDifferentSizesAreRefused():
        StartGame("").
        mGame:LoadBoards("XX./.../XXX", "XXX./..../XX..").
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID RowsOfDifferentLengthAreRefused():
        StartGame("").
        mGame:LoadBoards("XX./..", "XX./.../XX.").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARefusedLoadChangesNothing():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        StartGame("").
        DO ON ERROR UNDO, THROW:
            mGame:LoadBoards("XX./.../..X", "XX./.../.XX").
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
        Assert:Equals("#####|SS.../#####|...../#####|..SSS/#####|S..../#####|S....", Board()).
    END METHOD.

    /* ---- shooting ---- */

    @Test.
    METHOD PUBLIC VOID ShootingBeforeTheFleetIsPlacedDoesNothing():
        mOpponent = NEW ScriptedOpponent("0,0").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        Assert:IsFalse(mGame:Fire(2, 2)).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(0, mOpponent:ShotCount).
        Assert:Equals(0, mGame:EnemyShotAt(2, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMissIsShownAndTheComputerFiresBack():
        StartGame(WaterShots()).
        Assert:IsTrue(mGame:Fire(4, 4)).
        Assert:Equals(1, mGame:EnemyShotAt(4, 4)).
        Assert:Equals(0, mGame:LastPlayerOutcome).
        Assert:Equals(0, mGame:LastComputerOutcome).
        Assert:Equals(1, mGame:Turn).
        Assert:Equals(1, mOpponent:ShotCount).
        Assert:Equals(1, mOpponent:ObserveCount).
        Assert:IsFalse(mOpponent:LastHit).
        Assert:Equals("#####|SS;../#####|...../#####|..SSS/#####|S..../####o|S....", Board()).
        Assert:Equals("You missed. Computer missed.", mGame:LastEvent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHitIsShownAsAHitAndTheShipIsNotSunkYet():
        StartGame(WaterShots()).
        mGame:Fire(0, 0).
        Assert:Equals(2, mGame:EnemyShotAt(0, 0)).
        Assert:Equals(1, mGame:LastPlayerOutcome).
        Assert:Equals(3, mGame:ViewAt(0, 0)).
        Assert:Equals(3, mGame:EnemyShipsLeft).
        Assert:Equals("You hit a ship. Computer missed.", mGame:LastEvent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HittingEveryCellOfAShipSinksItAndTheWholeShipShowsAsSunk():
        StartGame(WaterShots()).
        mGame:Fire(0, 0).
        mGame:Fire(0, 1).
        Assert:Equals(2, mGame:LastPlayerOutcome).
        Assert:Equals(4, mGame:ViewAt(0, 0)).
        Assert:Equals(4, mGame:ViewAt(0, 1)).
        Assert:Equals(2, mGame:EnemyShipsLeft).
        Assert:Equals("You sank a 2-cell ship. Computer missed.", mGame:LastEvent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FiringAtTheSameCellTwiceDoesNothingAndIsNotATurn():
        StartGame(WaterShots()).
        mGame:Fire(4, 4).
        Assert:IsFalse(mGame:Fire(4, 4)).
        Assert:Equals(1, mGame:Turn).
        Assert:Equals(1, mOpponent:ShotCount).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID FiringOffTheBoardThrows():
        StartGame(WaterShots()).
        mGame:Fire(5, 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheComputersHitsAreShownOnYourBoardAndTheLatestShotIsLit():
        StartGame("0,0;2,0;1,0").
        mGame:Fire(4, 4).
        Assert:Equals(1, mGame:LastComputerOutcome).
        Assert:Equals(0, mGame:LastComputerX).
        Assert:Equals(0, mGame:LastComputerY).
        Assert:IsTrue(mOpponent:LastHit).
        Assert:IsFalse(mOpponent:LastSunk).
        Assert:Equals(12, mGame:ViewAt(6, 0)).
        Assert:Equals("You missed. Computer hit one of your ships.", mGame:LastEvent).
        mGame:Fire(3, 4).
        /* the old shot is no longer lit and the new miss is */
        Assert:Equals(8, mGame:ViewAt(6, 0)).
        Assert:Equals(11, mGame:ViewAt(8, 0)).
        mGame:Fire(2, 4).
        Assert:Equals(10, mGame:ViewAt(8, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheComputerSinkingYourShipIsReported():
        StartGame("0,0;1,0").
        mGame:Fire(4, 4).
        mGame:Fire(3, 4).
        Assert:Equals(2, mGame:LastComputerOutcome).
        Assert:IsTrue(mOpponent:LastSunk).
        Assert:Equals(9, mGame:ViewAt(6, 0)).
        Assert:Equals(9, mGame:ViewAt(7, 0)).
        Assert:Equals(2, mGame:OwnShipsLeft).
        Assert:Equals("You missed. Computer sank your 2-cell ship.", mGame:LastEvent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnIsOneShotEachWhetherOrNotItHits():
        StartGame("0,0;1,0;2,0").
        mGame:Fire(0, 0).
        mGame:Fire(0, 1).
        Assert:Equals(2, mGame:Turn).
        Assert:Equals(2, mOpponent:ShotCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SinkingTheWholeFleetWinsAndTheComputerDoesNotReply():
        StartGame(WaterShots()).
        mGame:Fire(0, 0).
        mGame:Fire(0, 1).
        mGame:Fire(3, 0).
        mGame:Fire(4, 0).
        mGame:Fire(1, 3).
        mGame:Fire(2, 3).
        Assert:IsFalse(mGame:IsOver).
        mGame:Fire(3, 3).
        Assert:IsTrue(mGame:IsWon).
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mGame:IsLost).
        Assert:Equals(7, mGame:Turn).
        Assert:Equals(6, mOpponent:ShotCount).
        Assert:Equals(0, mGame:EnemyShipsLeft).
        Assert:IsFalse(mGame:Fire(4, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheComputerSinkingYourWholeFleetLosesAndShowsTheShipsYouNeverFound():
        StartGame("0,0;1,0;2,2;3,2;4,2;0,3;0,4").
        mGame:Fire(0, 0).
        mGame:Fire(0, 4).
        mGame:Fire(1, 4).
        mGame:Fire(2, 4).
        mGame:Fire(3, 4).
        mGame:Fire(4, 4).
        Assert:IsFalse(mGame:IsOver).
        mGame:Fire(4, 3).
        Assert:IsTrue(mGame:IsLost).
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mGame:IsWon).
        Assert:Equals(0, mGame:OwnShipsLeft).
        /* the one hit is still a hit, the ships never hit are shown, the water is not */
        Assert:Equals(3, mGame:ViewAt(0, 0)).
        Assert:Equals(5, mGame:ViewAt(0, 1)).
        Assert:Equals(5, mGame:ViewAt(3, 0)).
        Assert:Equals(5, mGame:ViewAt(2, 3)).
        Assert:Equals(0, mGame:ViewAt(2, 2)).
        Assert:IsFalse(mGame:Fire(4, 2)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnOpponentThatFiresAtTheSameCellTwiceIsCaught():
        StartGame("2,0;2,0").
        mGame:Fire(4, 4).
        mGame:Fire(3, 4).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnOpponentThatFiresOffTheBoardIsCaught():
        StartGame("7,0").
        mGame:Fire(4, 4).
    END METHOD.

    /* ---- marking water ---- */

    @Test.
    METHOD PUBLIC VOID MarkingACellAsWaterShowsItAndMarkingAgainClearsIt():
        StartGame(WaterShots()).
        Assert:IsTrue(mGame:ToggleWater(2, 2)).
        Assert:Equals(1, mGame:EnemyMarkAt(2, 2)).
        Assert:Equals(1, mGame:ViewAt(2, 2)).
        Assert:IsTrue(mGame:ToggleWater(2, 2)).
        Assert:Equals(0, mGame:EnemyMarkAt(2, 2)).
        Assert:Equals(0, mGame:ViewAt(2, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MarksAreNotesSoTheyAreNotTurnsAndTheComputerDoesNotReply():
        StartGame(WaterShots()).
        mGame:ToggleWater(2, 2).
        mGame:ToggleWater(3, 2).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(0, mOpponent:ShotCount).
        Assert:IsFalse(mGame:Started).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMarkedCellCannotBeFiredAtUntilTheMarkIsCleared():
        StartGame(WaterShots()).
        mGame:ToggleWater(4, 4).
        Assert:IsFalse(mGame:Fire(4, 4)).
        Assert:Equals(0, mGame:Turn).
        mGame:ToggleWater(4, 4).
        Assert:IsTrue(mGame:Fire(4, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACellThatHasBeenFiredAtCannotBeMarked():
        StartGame(WaterShots()).
        mGame:Fire(4, 4).
        Assert:IsFalse(mGame:ToggleWater(4, 4)).
        Assert:Equals(2, mGame:ViewAt(4, 4)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID MarkingOffTheBoardThrows():
        StartGame(WaterShots()).
        mGame:ToggleWater(-1, 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ObviousWaterWithNoHitsMarksNothing():
        StartGame(WaterShots()).
        Assert:Equals(0, mGame:MarkObviousWater()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCornersOfAHitAreWaterBecauseShipsAreStraight():
        StartGame(WaterShots()).
        mGame:Fire(2, 3).
        Assert:Equals(4, mGame:MarkObviousWater()).
        Assert:Equals(1, mGame:EnemyMarkAt(1, 2)).
        Assert:Equals(1, mGame:EnemyMarkAt(3, 2)).
        Assert:Equals(1, mGame:EnemyMarkAt(1, 4)).
        Assert:Equals(1, mGame:EnemyMarkAt(3, 4)).
        Assert:Equals(0, mGame:EnemyMarkAt(2, 2)).
        Assert:Equals(0, mGame:EnemyMarkAt(1, 3)).
        Assert:Equals(0, mGame:MarkObviousWater()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryCellAroundASunkShipIsWater():
        StartGame(WaterShots()).
        mGame:Fire(1, 3).
        mGame:Fire(2, 3).
        mGame:Fire(3, 3).
        Assert:IsTrue(mGame:MarkObviousWater() > 0).
        /* the ring of 12 cells round a ship of three on a 5 x 5 board */
        Assert:Equals(12, mGame:Grid:Store:CountOf(mGame:Grid:Store:LayerIndex("mark"), 1)).
        Assert:Equals(1, mGame:EnemyMarkAt(0, 3)).
        Assert:Equals(1, mGame:EnemyMarkAt(4, 3)).
        Assert:Equals(1, mGame:EnemyMarkAt(2, 2)).
        Assert:Equals(1, mGame:EnemyMarkAt(2, 4)).
        Assert:Equals(1, mGame:EnemyMarkAt(0, 2)).
        Assert:Equals(1, mGame:EnemyMarkAt(4, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShipOnTheEdgeHasWaterOnlyOnTheBoard():
        StartGame(WaterShots()).
        mGame:Fire(0, 0).
        mGame:Fire(0, 1).
        Assert:Equals(4, mGame:MarkObviousWater()).
        Assert:Equals(1, mGame:EnemyMarkAt(1, 0)).
        Assert:Equals(1, mGame:EnemyMarkAt(1, 1)).
        Assert:Equals(1, mGame:EnemyMarkAt(1, 2)).
        Assert:Equals(1, mGame:EnemyMarkAt(0, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ObviousWaterLeavesCellsAlreadyFiredAtOrMarkedAlone():
        StartGame(WaterShots()).
        mGame:Fire(1, 2).
        mGame:ToggleWater(3, 2).
        mGame:Fire(2, 3).
        /* two of the four corners were taken already, one by a shot and one by a mark */
        Assert:Equals(2, mGame:MarkObviousWater()).
        Assert:Equals(1, mGame:ViewAt(3, 2)).
        Assert:Equals(2, mGame:ViewAt(1, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ObviousWaterDoesNothingOnceTheGameIsOver():
        StartGame(WaterShots()).
        mGame:Fire(0, 0).
        mGame:Fire(0, 1).
        mGame:Fire(3, 0).
        mGame:Fire(4, 0).
        mGame:Fire(1, 3).
        mGame:Fire(2, 3).
        mGame:Fire(3, 3).
        Assert:IsTrue(mGame:IsWon).
        Assert:Equals(0, mGame:MarkObviousWater()).
        Assert:IsFalse(mGame:ToggleWater(4, 4)).
    END METHOD.

    /* ---- configuring ---- */

    @Test.
    METHOD PUBLIC VOID ConfigureChangesTheBoardsAndTheFleetAndStartsAgain():
        StartGame(WaterShots()).
        mGame:Fire(4, 4).
        mGame:Configure(8, 8, "4,3,3,2").
        Assert:Equals(8, mGame:BoardWidth).
        Assert:Equals(17, mGame:Grid:Width).
        Assert:Equals(8, mGame:Grid:Height).
        Assert:Equals(4, mGame:FleetCount).
        Assert:Equals(4, mGame:ShipsToPlace).
        Assert:Equals(0, mGame:Turn).
        Assert:IsFalse(mGame:Started).
        Assert:Equals(12, CountShips(mGame, FALSE)).
        Assert:Equals(8, mOpponent:Width).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ConfigureWithTheSameSizeKeepsTheGrid():
        DEFINE VARIABLE before AS Grid NO-UNDO.
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        before = mGame:Grid.
        mGame:Configure(5, 5, "2,2").
        Assert:IsTrue(before = mGame:Grid).
        Assert:Equals(2, mGame:FleetCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadConfigureThrowsAndLeavesTheGameAsItWas():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        DO ON ERROR UNDO, THROW:
            mGame:Configure(2, 5, "2,2").
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:Configure(5, 5, "1,2").
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:Configure(5, 5, "two,3").
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:Configure(5, 5, "6,2").
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:Configure(5, 5, "5,5,5,5").
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:Configure(5, 5, "").
            CATCH e6 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:Configure(31, 5, "2,2").
            CATCH e7 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(7, thrown).
        Assert:Equals(5, mGame:BoardWidth).
        Assert:Equals(3, mGame:FleetCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheConstructorRefusesAnythingThatIsNotABattleshipsGrid():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE g      AS BattleshipsGame NO-UNDO.
        DO ON ERROR UNDO, THROW:
            g = NEW BattleshipsGame(NEW Grid(NEW TableStore(11, 5, "ship,shot,mark")), "3,2", NEW SeededRandom(1), NEW ScriptedOpponent("")).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = NEW BattleshipsGame(NEW Grid(NEW TableStore(10, 5, BattleshipsFactory:Layers())), "3,2", NEW SeededRandom(1), NEW ScriptedOpponent("")).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = NEW BattleshipsGame(NEW Grid(NEW TableStore(11, 5, BattleshipsFactory:Layers()), NEW ToroidalTopology(), NEW MooreNeighbourhood()), "3,2", NEW SeededRandom(1), NEW ScriptedOpponent("")).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = BattleshipsFactory:Create(5, 5, "3,2", ?, NEW ScriptedOpponent("")).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            g = BattleshipsFactory:Create(5, 5, "3,2", NEW SeededRandom(1), ?).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(5, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameIsTurnBasedAndNamed():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        Assert:Equals("Battleships", mGame:Name).
        Assert:IsTrue(TYPE-OF(mGame, ITurnBasedGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseStartsAFreshGame():
        StartGame(WaterShots()).
        mGame:Fire(4, 4).
        mGame:Initialise().
        Assert:Equals(0, mGame:Turn).
        Assert:IsFalse(mGame:Started).
        Assert:Equals(3, mGame:ShipsToPlace).
        Assert:Equals(7, CountShips(mGame, FALSE)).
        Assert:Equals(0, CountShips(mGame, TRUE)).
    END METHOD.

    /* ---- whole games ---- */

    @Test.
    METHOD PUBLIC VOID WholeGamesAgainstTheRealOpponentAlwaysEndWithOneWinner():
        DEFINE VARIABLE seed   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE g      AS BattleshipsGame NO-UNDO.
        DEFINE VARIABLE o      AS HuntTargetOpponent NO-UNDO.
        DEFINE VARIABLE bad    AS INTEGER NO-UNDO.
        DEFINE VARIABLE stuck  AS INTEGER NO-UNDO.
        DO seed = 1 TO 8 ON ERROR UNDO, THROW:
            o = NEW HuntTargetOpponent(NEW SeededRandom(seed + 100)).
            g = BattleshipsFactory:Create(10, 10, "5,4,3,3,2", NEW SeededRandom(seed), o).
            g:RandomiseFleet().
            /* the player fires at every cell in reading order until the game ends */
            DO y = 0 TO 9 WHILE NOT g:IsOver:
                DO x = 0 TO 9 WHILE NOT g:IsOver:
                    g:Fire(x, y).
                END.
            END.
            IF NOT g:IsOver THEN stuck = stuck + 1.
            IF g:IsWon = g:IsLost THEN bad = bad + 1.
            IF g:IsWon AND g:EnemyShipsLeft <> 0 THEN bad = bad + 1.
            IF g:IsLost AND g:OwnShipsLeft <> 0 THEN bad = bad + 1.
            IF g:Turn > 100 THEN bad = bad + 1.
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
                IF VALID-OBJECT(o) THEN o:Dispose().
            END FINALLY.
        END.
        Assert:Equals(0, stuck).
        Assert:Equals(0, bad).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRealOpponentFindsAWholeFleetInAboutFortyFiveShots():
        /* the player only ever fires at water, so only the computer can end the game: it must sink
           every ship, with no shot repeated, and do it in a sensible number of shots */
        DEFINE VARIABLE seed   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE g      AS BattleshipsGame NO-UNDO.
        DEFINE VARIABLE o      AS HuntTargetOpponent NO-UNDO.
        DEFINE VARIABLE total  AS INTEGER NO-UNDO.
        DEFINE VARIABLE worst  AS INTEGER NO-UNDO.
        DEFINE VARIABLE notLost AS INTEGER NO-UNDO.
        DO seed = 1 TO 20 ON ERROR UNDO, THROW:
            o = NEW HuntTargetOpponent(NEW SeededRandom(seed + 500)).
            g = BattleshipsFactory:Create(10, 10, "5,4,3,3,2", NEW SeededRandom(seed), o).
            g:RandomiseFleet().
            DO y = 0 TO 9 WHILE NOT g:IsOver:
                DO x = 0 TO 9 WHILE NOT g:IsOver:
                    IF g:EnemyShipAt(x, y) = 0 THEN g:Fire(x, y).
                END.
            END.
            IF NOT g:IsLost THEN notLost = notLost + 1.
            total = total + g:Turn.
            worst = MAXIMUM(worst, g:Turn).
            FINALLY:
                IF VALID-OBJECT(g) THEN g:Dispose().
                IF VALID-OBJECT(o) THEN o:Dispose().
            END FINALLY.
        END.
        Assert:Equals(0, notLost).
        Assert:IsTrue(total / 20 < 52).
        Assert:IsTrue(worst < 75).
    END METHOD.

END CLASS.
