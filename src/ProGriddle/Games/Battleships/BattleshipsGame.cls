/* Battleships against the computer, as a turn based game.

   The rules:
   - Each side has the same fleet, set by the size of the board (see BattleshipsFleets). Every
     ship is a straight line of at least two cells, horizontal or vertical, never diagonal.
   - Ships may not touch, not even at a corner. Every ship is surrounded by water.
   - You place your fleet by hand (Rotate, then PlaceShip at a cell; RemoveShip takes one back)
     or at random (RandomiseFleet). The computer's fleet is placed at random, out of sight.
   - You fire at a cell of the computer's waters. The computer answers with a shot at yours.
     A turn is one shot each, whether or not it hits. A ship is sunk when every cell of it has
     been hit, and the game says so. The first side to sink the whole fleet of the other wins.
   - You may mark cells of the computer's waters as water (ToggleWater) to keep track of what
     you have worked out. A marked cell cannot be fired at until you clear the mark. Marks are
     notes, so they are not turns. MarkObviousWater does the sure bits for you: the corners of
     every hit (a ship is straight, so they are water) and every cell around a sunk ship.

   The framework keeps one grid per game, so both boards are regions of it: the computer's waters
   on the left (columns 0 to BoardWidth - 1), one divider column, then your fleet on the right.
   Methods take board coordinates, counted from 0 at the top left of the board they are about.
   The grid has four layers:
     ship   0 for water, else the number of the ship (its place in the fleet, longest first)
     shot   0 not fired at, 1 miss, 2 hit
     mark   1 for a cell the player has marked as water (the computer's side only)
     view   what to draw (see ViewCodes.i), kept up to date after every move

   The opponent decides the computer's shots and learns only what each shot did. The game
   owns its grid; Dispose releases it. The opponent belongs to whoever built it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.BattleshipsGame FINAL INHERITS AbstractGame IMPLEMENTS ITurnBasedGame:

    {ProGriddle/Games/Battleships/ViewCodes.i}

    DEFINE PRIVATE VARIABLE mRandom     AS IRandom                NO-UNDO.
    DEFINE PRIVATE VARIABLE mOpponent   AS IBattleshipsOpponent   NO-UNDO.
    DEFINE PRIVATE VARIABLE mBW         AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBH         AS INTEGER NO-UNDO.
    /* the fleet, longest first, with a horizontal and a vertical shape for each ship */
    DEFINE PRIVATE VARIABLE mFleet      AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mShapeH     AS Shape   NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mShapeV     AS Shape   NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mOwnPlaced  AS LOGICAL NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mOwnHits    AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mEnemyHits  AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mOwnSunk    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mEnemySunk  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mHorizontal AS LOGICAL NO-UNDO INITIAL TRUE.
    DEFINE PRIVATE VARIABLE mStarted    AS LOGICAL NO-UNDO.
    DEFINE PRIVATE VARIABLE mLastOwn    AS INTEGER NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mLastSunkLength AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlayerEvent   AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE mComputerEvent AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLShip      AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLShot      AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLMark      AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLView      AS INTEGER NO-UNDO.
    /* ships found in a board text by LoadBoards: where each starts, how long, and which way */
    DEFINE PRIVATE VARIABLE mRunCount   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mRunX       AS INTEGER NO-UNDO EXTENT 100.
    DEFINE PRIVATE VARIABLE mRunY       AS INTEGER NO-UNDO EXTENT 100.
    DEFINE PRIVATE VARIABLE mRunLen     AS INTEGER NO-UNDO EXTENT 100.
    DEFINE PRIVATE VARIABLE mRunHoriz   AS LOGICAL NO-UNDO EXTENT 100.
    DEFINE PRIVATE VARIABLE mRunId      AS INTEGER NO-UNDO EXTENT.

    DEFINE PUBLIC PROPERTY Turn AS INTEGER NO-UNDO
        GET():
            RETURN Generation.
        END GET.

    /* The width and height of each board. The grid is 2 * BoardWidth + 1 columns wide. */
    DEFINE PUBLIC PROPERTY BoardWidth AS INTEGER NO-UNDO
        GET():
            RETURN mBW.
        END GET.

    DEFINE PUBLIC PROPERTY BoardHeight AS INTEGER NO-UNDO
        GET():
            RETURN mBH.
        END GET.

    /* The first grid column of the player's own board. */
    DEFINE PUBLIC PROPERTY OwnLeft AS INTEGER NO-UNDO
        GET():
            RETURN mBW + 1.
        END GET.

    /* How many ships each side has. */
    DEFINE PUBLIC PROPERTY FleetCount AS INTEGER NO-UNDO
        GET():
            RETURN EXTENT(mFleet).
        END GET.

    DEFINE PUBLIC PROPERTY IsWon AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY IsLost AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    /* True from the first shot. Until then the player's fleet can still be rearranged. */
    DEFINE PUBLIC PROPERTY Started AS LOGICAL NO-UNDO
        GET():
            RETURN mStarted.
        END GET.

    /* True while the next ship placed goes down horizontally, false for vertically. */
    DEFINE PUBLIC PROPERTY Horizontal AS LOGICAL NO-UNDO
        GET():
            RETURN mHorizontal.
        END GET.

    /* How many of the player's ships are still to be placed. */
    DEFINE PUBLIC PROPERTY ShipsToPlace AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO EXTENT(mFleet):
                IF NOT mOwnPlaced[i] THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* True when every one of the player's ships is on the board, so shooting may begin. */
    DEFINE PUBLIC PROPERTY FleetReady AS LOGICAL NO-UNDO
        GET():
            RETURN ShipsToPlace = 0.
        END GET.

    /* The length of the next ship to place, or 0 when the fleet is complete. */
    DEFINE PUBLIC PROPERTY CurrentShipLength AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            i = NextUnplaced().
            RETURN (IF i = 0 THEN 0 ELSE mFleet[i]).
        END GET.

    /* Ships of the computer that are not sunk yet, and ships of the player's that are not. */
    DEFINE PUBLIC PROPERTY EnemyShipsLeft AS INTEGER NO-UNDO
        GET():
            RETURN EXTENT(mFleet) - mEnemySunk.
        END GET.

    DEFINE PUBLIC PROPERTY OwnShipsLeft AS INTEGER NO-UNDO
        GET():
            RETURN EXTENT(mFleet) - mOwnSunk.
        END GET.

    /* 0 for a miss, 1 for a hit, 2 for a sunk ship, -1 before a shot. */
    DEFINE PUBLIC PROPERTY LastPlayerOutcome AS INTEGER NO-UNDO INITIAL -1
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastComputerOutcome AS INTEGER NO-UNDO INITIAL -1
        GET.
        PRIVATE SET.

    /* Where the computer's last shot went, on the player's board, or -1 before one. */
    DEFINE PUBLIC PROPERTY LastComputerX AS INTEGER NO-UNDO INITIAL -1
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY LastComputerY AS INTEGER NO-UNDO INITIAL -1
        GET.
        PRIVATE SET.

    /* The last turn in words: "You hit a ship. Computer missed." */
    DEFINE PUBLIC PROPERTY LastEvent AS CHARACTER NO-UNDO
        GET():
            IF mPlayerEvent = "" THEN RETURN "".
            IF mComputerEvent = "" THEN RETURN "You " + mPlayerEvent + ".".
            RETURN "You " + mPlayerEvent + ". Computer " + mComputerEvent + ".".
        END GET.

    /* The grid must have the layers of BattleshipsFactory:Layers(), an odd width of at least 7 and
       a height of at least 3. pcFleet is a comma separated list of ship lengths, each at least 2.
       The player's fleet is unplaced and the computer's is hidden when the constructor returns. */
    CONSTRUCTOR PUBLIC BattleshipsGame(INPUT poGrid AS Grid, INPUT pcFleet AS CHARACTER,
                                       INPUT poRandom AS IRandom, INPUT poOpponent AS IBattleshipsOpponent):
        SUPER("Battleships", poGrid).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Battleships game needs a random source").
        IF NOT VALID-OBJECT(poOpponent) THEN UNDO, THROW NEW GridException("A Battleships game needs an opponent").
        CheckGrid(poGrid).
        mRandom = poRandom.
        mOpponent = poOpponent.
        mBW = INTEGER((poGrid:Width - 1) / 2).
        mBH = poGrid:Height.
        FindLayers().
        ValidateFleet(mBW, mBH, pcFleet).
        SetFleet(pcFleet).
        Initialise().
    END CONSTRUCTOR.

    /* ---- setting up ---- */

    /* Starts a new game on boards of this size with this fleet. A new grid is built only when the
       size differs from the current one. Throws GridException, and changes nothing, for a board
       under 3 x 3 or over 30 x 30, or a fleet that is not a list of lengths from 2 up that
       would fill more than two fifths of the board. */
    METHOD PUBLIC VOID Configure(INPUT piBoardWidth AS INTEGER, INPUT piBoardHeight AS INTEGER, INPUT pcFleet AS CHARACTER):
        DEFINE VARIABLE previous AS Grid NO-UNDO.
        ValidateFleet(piBoardWidth, piBoardHeight, pcFleet).
        IF piBoardWidth <> mBW OR piBoardHeight <> mBH THEN DO:
            previous = Grid.
            Grid = GridFor(piBoardWidth, piBoardHeight).
            previous:Dispose().
            mBW = piBoardWidth.
            mBH = piBoardHeight.
        END.
        SetFleet(pcFleet).
        Initialise().
    END METHOD.

    /* Starts a new game with both fleets exactly as the texts say, ready for the first shot, for
       tests and set puzzles. Each text is one string per row separated by "/", with "X" for a
       ship cell and anything else for water, for example "XX./.../.XX". Both boards must be the
       same size and hold the same ships, each a straight line of at least two cells, none
       touching. The first text is the player's board and the second the computer's. */
    METHOD PUBLIC VOID LoadBoards(INPUT pcOwn AS CHARACTER, INPUT pcEnemy AS CHARACTER):
        DEFINE VARIABLE cols      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE rowCount  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE enemyCols AS INTEGER   NO-UNDO.
        DEFINE VARIABLE enemyRows AS INTEGER   NO-UNDO.
        DEFINE VARIABLE enemyFleet  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i         AS INTEGER   NO-UNDO.
        FindRuns(pcEnemy, OUTPUT enemyCols, OUTPUT enemyRows).
        enemyFleet = FleetOfRuns().
        FindRuns(pcOwn, OUTPUT cols, OUTPUT rowCount).
        IF cols <> enemyCols OR rowCount <> enemyRows THEN UNDO, THROW NEW GridException("Both boards must be the same size").
        IF FleetOfRuns() <> enemyFleet THEN UNDO, THROW NEW GridException("Both boards must hold the same ships").
        Configure(cols, rowCount, enemyFleet).
        StampRuns(OwnLeft, TRUE).
        FindRuns(pcEnemy, OUTPUT enemyCols, OUTPUT enemyRows).
        /* the computer's random fleet from Configure is replaced */
        ClearRegion(0).
        StampRuns(0, FALSE).
        DO i = 1 TO EXTENT(mFleet):
            mOwnPlaced[i] = TRUE.
        END.
    END METHOD.

    /* ---- placing your fleet ---- */

    /* Turns the next ship the other way, horizontal or vertical. */
    METHOD PUBLIC VOID Rotate():
        mHorizontal = NOT mHorizontal.
    END METHOD.

    /* Puts the next ship of the fleet on your board with its first cell at the cell given, in
       the direction set by Rotate. A ship that would hang off the board is moved back so it
       fits. Returns false, and changes nothing, when it would touch another ship, even at a
       corner, when the fleet is already complete, or when shooting has started. Throws
       GridException for a cell off the board. */
    METHOD PUBLIC LOGICAL PlaceShip(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE shape AS Shape   NO-UNDO.
        CheckBoardCell(piX, piY).
        IF IsOver OR mStarted THEN RETURN FALSE.
        i = NextUnplaced().
        IF i = 0 THEN RETURN FALSE.
        shape = (IF mHorizontal THEN mShapeH[i] ELSE mShapeV[i]).
        x = MINIMUM(piX, mBW - shape:Width).
        y = MINIMUM(piY, mBH - shape:Height).
        IF TouchesShip(OwnLeft, x, y, shape:Width, shape:Height) THEN RETURN FALSE.
        PutShip(OwnLeft, i, shape, x, y, TRUE).
        mOwnPlaced[i] = TRUE.
        RETURN TRUE.
    END METHOD.

    /* Takes the ship on that cell of your board back off it, so it is the next to place. Returns
       false when there is no ship there or shooting has started. Throws GridException for a
       cell off the board. */
    METHOD PUBLIC LOGICAL RemoveShip(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE id AS INTEGER NO-UNDO.
        DEFINE VARIABLE x  AS INTEGER NO-UNDO.
        DEFINE VARIABLE y  AS INTEGER NO-UNDO.
        CheckBoardCell(piX, piY).
        IF IsOver OR mStarted THEN RETURN FALSE.
        id = Grid:Store:GetCell(mLShip, OwnLeft + piX, piY).
        IF id = 0 THEN RETURN FALSE.
        DO y = 0 TO mBH - 1:
            DO x = 0 TO mBW - 1:
                IF Grid:Store:GetCell(mLShip, OwnLeft + x, y) = id THEN DO:
                    Grid:Store:SetCell(mLShip, OwnLeft + x, y, 0).
                    Grid:Store:SetCell(mLView, OwnLeft + x, y, {&VIEW-O-WATER}).
                END.
            END.
        END.
        mOwnPlaced[id] = FALSE.
        RETURN TRUE.
    END METHOD.

    /* Takes every ship of yours back off the board. Returns false once shooting has started. */
    METHOD PUBLIC LOGICAL ClearFleet():
        IF IsOver OR mStarted THEN RETURN FALSE.
        ClearRegion(OwnLeft).
        RETURN TRUE.
    END METHOD.

    /* Clears your board and puts the whole fleet on it at random. Returns false once shooting has
       started. */
    METHOD PUBLIC LOGICAL RandomiseFleet():
        IF IsOver OR mStarted THEN RETURN FALSE.
        PlaceFleetAtRandom(OwnLeft, TRUE).
        RETURN TRUE.
    END METHOD.

    /* ---- the battle ---- */

    /* Fires at a cell of the computer's waters, and then the computer fires back at yours.
       Returns false, and nothing happens, when your fleet is not all placed yet, the game is
       over, the cell has been fired at already, or you have marked it as water. Throws
       GridException for a cell off the board. */
    METHOD PUBLIC LOGICAL Fire(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE outcome AS INTEGER NO-UNDO.
        CheckBoardCell(piX, piY).
        IF IsOver OR NOT FleetReady THEN RETURN FALSE.
        IF Grid:Store:GetCell(mLShot, piX, piY) <> 0 OR Grid:Store:GetCell(mLMark, piX, piY) <> 0 THEN RETURN FALSE.
        mStarted = TRUE.
        Generation = Generation + 1.
        outcome = Resolve(TRUE, piX, piY).
        LastPlayerOutcome = outcome.
        mPlayerEvent = (IF outcome = 0 THEN "missed" ELSE IF outcome = 1 THEN "hit a ship" ELSE SUBSTITUTE("sank a &1-cell ship", mLastSunkLength)).
        mComputerEvent = "".
        LastComputerOutcome = -1.
        IF mEnemySunk = EXTENT(mFleet) THEN DO:
            IsWon = TRUE.
            IsOver = TRUE.
            RETURN TRUE.
        END.
        ComputerShot().
        IF mOwnSunk = EXTENT(mFleet) THEN DO:
            IsLost = TRUE.
            IsOver = TRUE.
            RevealEnemyFleet().
        END.
        RETURN TRUE.
    END METHOD.

    /* Marks a cell of the computer's waters as water, or clears the mark. Does nothing for a cell
       that has been fired at, or once the game is over. A marked cell cannot be fired at. Returns
       true when it changed something. Throws GridException for a cell off the board. */
    METHOD PUBLIC LOGICAL ToggleWater(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE marked AS INTEGER NO-UNDO.
        CheckBoardCell(piX, piY).
        IF IsOver OR Grid:Store:GetCell(mLShot, piX, piY) <> 0 THEN RETURN FALSE.
        marked = 1 - Grid:Store:GetCell(mLMark, piX, piY).
        Grid:Store:SetCell(mLMark, piX, piY, marked).
        Grid:Store:SetCell(mLView, piX, piY, (IF marked = 1 THEN {&VIEW-E-MARK} ELSE {&VIEW-E-HIDDEN})).
        RETURN TRUE.
    END METHOD.

    /* Marks as water every cell that must be water: the four corners of every hit (a ship is a
       straight line, so a cell diagonal to a hit is never part of it) and, for a sunk ship, all
       eight cells round every cell of it (ships may not touch). Cells already fired at or marked
       are left alone. Returns how many cells it marked. */
    METHOD PUBLIC INTEGER MarkObviousWater():
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx     AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy     AS INTEGER NO-UNDO.
        DEFINE VARIABLE id     AS INTEGER NO-UNDO.
        DEFINE VARIABLE sunk   AS LOGICAL NO-UNDO.
        DEFINE VARIABLE newMarks  AS INTEGER NO-UNDO.
        IF IsOver THEN RETURN 0.
        DO y = 0 TO mBH - 1:
            DO x = 0 TO mBW - 1:
                IF Grid:Store:GetCell(mLShot, x, y) <> 2 THEN NEXT.
                id = Grid:Store:GetCell(mLShip, x, y).
                sunk = (mEnemyHits[id] = mFleet[id]).
                DO dy = -1 TO 1:
                    DO dx = -1 TO 1:
                        IF dx = 0 AND dy = 0 THEN NEXT.
                        IF NOT sunk AND (dx = 0 OR dy = 0) THEN NEXT.
                        IF x + dx < 0 OR x + dx >= mBW OR y + dy < 0 OR y + dy >= mBH THEN NEXT.
                        IF Grid:Store:GetCell(mLShot, x + dx, y + dy) = 0 AND Grid:Store:GetCell(mLMark, x + dx, y + dy) = 0 THEN DO:
                            Grid:Store:SetCell(mLMark, x + dx, y + dy, 1).
                            Grid:Store:SetCell(mLView, x + dx, y + dy, {&VIEW-E-MARK}).
                            newMarks = newMarks + 1.
                        END.
                    END.
                END.
            END.
        END.
        RETURN newMarks.
    END METHOD.

    /* ---- reading the boards (board coordinates) ---- */

    /* The length of ship i of the fleet, 1 to FleetCount, longest first. */
    METHOD PUBLIC INTEGER FleetLength(INPUT piShip AS INTEGER):
        IF piShip < 1 OR piShip > EXTENT(mFleet) THEN UNDO, THROW NEW GridException("There is no ship " + STRING(piShip)).
        RETURN mFleet[piShip].
    END METHOD.

    /* 0 for water, else the number of the ship on that cell of the computer's board. */
    METHOD PUBLIC INTEGER EnemyShipAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckBoardCell(piX, piY).
        RETURN Grid:Store:GetCell(mLShip, piX, piY).
    END METHOD.

    /* 0 for water, else the number of the ship on that cell of your board. */
    METHOD PUBLIC INTEGER OwnShipAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckBoardCell(piX, piY).
        RETURN Grid:Store:GetCell(mLShip, OwnLeft + piX, piY).
    END METHOD.

    /* 0 not fired at, 1 miss, 2 hit. */
    METHOD PUBLIC INTEGER EnemyShotAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckBoardCell(piX, piY).
        RETURN Grid:Store:GetCell(mLShot, piX, piY).
    END METHOD.

    METHOD PUBLIC INTEGER OwnShotAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckBoardCell(piX, piY).
        RETURN Grid:Store:GetCell(mLShot, OwnLeft + piX, piY).
    END METHOD.

    /* 1 when the cell of the computer's waters is marked as water. */
    METHOD PUBLIC INTEGER EnemyMarkAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        CheckBoardCell(piX, piY).
        RETURN Grid:Store:GetCell(mLMark, piX, piY).
    END METHOD.

    /* What a grid cell shows, as in ViewCodes.i. Grid coordinates, both boards. */
    METHOD PUBLIC INTEGER ViewAt(INPUT piGridX AS INTEGER, INPUT piY AS INTEGER):
        RETURN Grid:Store:GetCell(mLView, piGridX, piY).
    END METHOD.

    /* ---- lifetime ---- */

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mStarted = FALSE.
        mHorizontal = TRUE.
        mOwnSunk = 0.
        mEnemySunk = 0.
        mLastOwn = -1.
        mPlayerEvent = "".
        mComputerEvent = "".
        IsWon = FALSE.
        IsLost = FALSE.
        LastPlayerOutcome = -1.
        LastComputerOutcome = -1.
        LastComputerX = -1.
        LastComputerY = -1.
        mLastSunkLength = 0.
        EXTENT(mOwnPlaced) = EXTENT(mFleet).
        EXTENT(mOwnHits) = EXTENT(mFleet).
        EXTENT(mEnemyHits) = EXTENT(mFleet).
        DO i = 1 TO EXTENT(mFleet):
            mOwnPlaced[i] = FALSE.
            mOwnHits[i] = 0.
            mEnemyHits[i] = 0.
        END.
        Grid:Store:FillLayer(mLShip, 0).
        Grid:Store:FillLayer(mLShot, 0).
        Grid:Store:FillLayer(mLMark, 0).
        Grid:Store:FillLayer(mLView, {&VIEW-E-HIDDEN}).
        DO y = 0 TO mBH - 1:
            DO i = 0 TO mBW - 1:
                Grid:Store:SetCell(mLView, OwnLeft + i, y, {&VIEW-O-WATER}).
            END.
            Grid:Store:SetCell(mLView, mBW, y, {&VIEW-DIVIDER}).
        END.
        mOpponent:Reset(mBW, mBH).
        PlaceFleetAtRandom(0, FALSE).
    END METHOD.

    METHOD PUBLIC OVERRIDE VOID Dispose():
        SUPER:Dispose().
    END METHOD.

    /* ---- private: placing ---- */

    /* Number of the first ship of the fleet that is not on the player's board, 0 when all are. */
    METHOD PRIVATE INTEGER NextUnplaced():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO EXTENT(mFleet):
            IF NOT mOwnPlaced[i] THEN RETURN i.
        END.
        RETURN 0.
    END METHOD.

    /* True when a ship covering the box (piX, piY, piW x piH) would touch a ship already on the
       board at piOffset: any ship cell inside the box or in the ring of cells round it. */
    METHOD PRIVATE LOGICAL TouchesShip(INPUT piOffset AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER,
                                       INPUT piW AS INTEGER, INPUT piH AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = MAXIMUM(0, piY - 1) TO MINIMUM(mBH - 1, piY + piH):
            DO x = MAXIMUM(0, piX - 1) TO MINIMUM(mBW - 1, piX + piW):
                IF Grid:Store:GetCell(mLShip, piOffset + x, y) <> 0 THEN RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    /* Writes ship piShip onto the board at piOffset, with its top left at (piX, piY). The cells of
       the player's own board are drawn as ship when plShow is true. */
    METHOD PRIVATE VOID PutShip(INPUT piOffset AS INTEGER, INPUT piShip AS INTEGER, INPUT poShape AS Shape,
                                INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plShow AS LOGICAL):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Grid:Store:Stamp(mLShip, poShape, piOffset + piX, piY, piShip).
        IF plShow THEN DO i = 1 TO poShape:Size:
            Grid:Store:SetCell(mLView, piOffset + piX + poShape:OffsetX(i), piY + poShape:OffsetY(i), {&VIEW-O-SHIP}).
        END.
    END METHOD.

    /* Takes every ship off the board at piOffset. The player's own board goes back to open water
       and its ships are unplaced. */
    METHOD PRIVATE VOID ClearRegion(INPUT piOffset AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = 0 TO mBH - 1:
            DO x = 0 TO mBW - 1:
                Grid:Store:SetCell(mLShip, piOffset + x, y, 0).
                IF piOffset > 0 THEN Grid:Store:SetCell(mLView, piOffset + x, y, {&VIEW-O-WATER}).
            END.
        END.
        IF piOffset > 0 THEN DO x = 1 TO EXTENT(mFleet):
            mOwnPlaced[x] = FALSE.
        END.
    END METHOD.

    /* Puts the whole fleet on the board at piOffset, each ship at a random place and direction
       with no two touching. Starts again if a ship finds no room, which is rare because every
       fleet takes under two fifths of its board. */
    METHOD PRIVATE VOID PlaceFleetAtRandom(INPUT piOffset AS INTEGER, INPUT plShow AS LOGICAL):
        DEFINE VARIABLE attempt AS INTEGER NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE tries   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER NO-UNDO.
        DEFINE VARIABLE shape   AS Shape   NO-UNDO.
        DEFINE VARIABLE placed  AS LOGICAL NO-UNDO.
        DEFINE VARIABLE allOk   AS LOGICAL NO-UNDO.
        DO attempt = 1 TO 200:
            ClearRegion(piOffset).
            allOk = TRUE.
            DO i = 1 TO EXTENT(mFleet) WHILE allOk:
                placed = FALSE.
                DO tries = 1 TO 500 WHILE NOT placed:
                    shape = (IF mRandom:NextInt(2) = 0 THEN mShapeH[i] ELSE mShapeV[i]).
                    x = mRandom:NextInt(mBW - shape:Width + 1).
                    y = mRandom:NextInt(mBH - shape:Height + 1).
                    IF NOT TouchesShip(piOffset, x, y, shape:Width, shape:Height) THEN DO:
                        PutShip(piOffset, i, shape, x, y, plShow).
                        placed = TRUE.
                    END.
                END.
                IF NOT placed THEN allOk = FALSE.
            END.
            IF allOk THEN DO:
                IF piOffset > 0 THEN DO i = 1 TO EXTENT(mFleet):
                    mOwnPlaced[i] = TRUE.
                END.
                RETURN.
            END.
        END.
        UNDO, THROW NEW GridException("The fleet does not fit on the board").
    END METHOD.

    /* ---- private: shooting ---- */

    /* Fires one shot at the computer's waters (plEnemy) or the player's and returns 0 for a miss,
       1 for a hit and 2 when it sinks a ship, updating the shot layer, the hit counts and the
       view. A sunk ship is drawn as sunk all over, and its length is left in mLastSunkLength. */
    METHOD PRIVATE INTEGER Resolve(INPUT plEnemy AS LOGICAL, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE colBase AS INTEGER NO-UNDO.
        DEFINE VARIABLE id     AS INTEGER NO-UNDO.
        DEFINE VARIABLE hits   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        colBase = (IF plEnemy THEN 0 ELSE OwnLeft).
        id = Grid:Store:GetCell(mLShip, colBase + piX, piY).
        IF id = 0 THEN DO:
            Grid:Store:SetCell(mLShot, colBase + piX, piY, 1).
            Grid:Store:SetCell(mLView, colBase + piX, piY, (IF plEnemy THEN {&VIEW-E-MISS} ELSE {&VIEW-O-LAST-MISS})).
            RETURN 0.
        END.
        Grid:Store:SetCell(mLShot, colBase + piX, piY, 2).
        IF plEnemy THEN DO:
            mEnemyHits[id] = mEnemyHits[id] + 1.
            hits = mEnemyHits[id].
        END.
        ELSE DO:
            mOwnHits[id] = mOwnHits[id] + 1.
            hits = mOwnHits[id].
        END.
        IF hits < mFleet[id] THEN DO:
            Grid:Store:SetCell(mLView, colBase + piX, piY, (IF plEnemy THEN {&VIEW-E-HIT} ELSE {&VIEW-O-LAST-HIT})).
            RETURN 1.
        END.
        DO y = 0 TO mBH - 1:
            DO x = 0 TO mBW - 1:
                IF Grid:Store:GetCell(mLShip, colBase + x, y) = id THEN
                    Grid:Store:SetCell(mLView, colBase + x, y, (IF plEnemy THEN {&VIEW-E-SUNK} ELSE {&VIEW-O-SUNK})).
            END.
        END.
        IF plEnemy THEN mEnemySunk = mEnemySunk + 1.
        ELSE mOwnSunk = mOwnSunk + 1.
        mLastSunkLength = mFleet[id].
        RETURN 2.
    END METHOD.

    /* The computer takes its shot at the player's board. */
    METHOD PRIVATE VOID ComputerShot():
        DEFINE VARIABLE cx      AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy      AS INTEGER NO-UNDO.
        DEFINE VARIABLE outcome AS INTEGER NO-UNDO.
        mOpponent:NextShot(OUTPUT cx, OUTPUT cy).
        IF cx < 0 OR cx >= mBW OR cy < 0 OR cy >= mBH THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("The opponent fired off the board at (&1,&2)", cx, cy)).
        IF Grid:Store:GetCell(mLShot, OwnLeft + cx, cy) <> 0 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("The opponent fired at (&1,&2) twice", cx, cy)).
        FadeLastShot().
        outcome = Resolve(FALSE, cx, cy).
        mOpponent:Observe(cx, cy, outcome > 0, outcome = 2).
        LastComputerOutcome = outcome.
        LastComputerX = cx.
        LastComputerY = cy.
        mLastOwn = cy * Grid:Width + OwnLeft + cx.
        mComputerEvent = (IF outcome = 0 THEN "missed" ELSE IF outcome = 1 THEN "hit one of your ships" ELSE SUBSTITUTE("sank your &1-cell ship", mLastSunkLength)).
    END METHOD.

    /* The cell the computer fired at last turn stops being highlighted. */
    METHOD PRIVATE VOID FadeLastShot():
        DEFINE VARIABLE gx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE gy   AS INTEGER NO-UNDO.
        DEFINE VARIABLE code AS INTEGER NO-UNDO.
        IF mLastOwn < 0 THEN RETURN.
        gx = mLastOwn MODULO Grid:Width.
        gy = INTEGER(TRUNCATE(mLastOwn / Grid:Width, 0)).
        code = Grid:Store:GetCell(mLView, gx, gy).
        IF code = {&VIEW-O-LAST-MISS} THEN Grid:Store:SetCell(mLView, gx, gy, {&VIEW-O-MISS}).
        ELSE IF code = {&VIEW-O-LAST-HIT} THEN Grid:Store:SetCell(mLView, gx, gy, {&VIEW-O-HIT}).
        mLastOwn = -1.
    END METHOD.

    /* After a loss, shows where the computer's ships that were never hit were. */
    METHOD PRIVATE VOID RevealEnemyFleet():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = 0 TO mBH - 1:
            DO x = 0 TO mBW - 1:
                IF Grid:Store:GetCell(mLShip, x, y) <> 0 AND Grid:Store:GetCell(mLShot, x, y) = 0 THEN
                    Grid:Store:SetCell(mLView, x, y, {&VIEW-E-SHIP}).
            END.
        END.
    END METHOD.

    /* ---- private: board texts ---- */

    /* Finds the ships in a board text and leaves them in the mRun arrays, longest first. Throws
       GridException for rows of different length, a ship of one cell, a ship that is not a
       straight line, or two ships that touch. */
    METHOD PRIVATE VOID FindRuns(INPUT pcRows AS CHARACTER, OUTPUT piCols AS INTEGER, OUTPUT piRows AS INTEGER):
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE dx    AS INTEGER NO-UNDO.
        DEFINE VARIABLE dy    AS INTEGER NO-UNDO.
        DEFINE VARIABLE shipLen   AS INTEGER NO-UNDO.
        DEFINE VARIABLE k     AS INTEGER NO-UNDO.
        DEFINE VARIABLE horiz AS LOGICAL NO-UNDO.
        IF pcRows = ? OR pcRows = "" THEN UNDO, THROW NEW GridException("A board needs at least one row").
        piRows = NUM-ENTRIES(pcRows, "/").
        piCols = LENGTH(ENTRY(1, pcRows, "/")).
        DO y = 1 TO piRows:
            IF LENGTH(ENTRY(y, pcRows, "/")) <> piCols THEN UNDO, THROW NEW GridException("Every row of a board must be the same length").
        END.
        EXTENT(mRunId) = piCols * piRows.
        DO k = 1 TO piCols * piRows:
            mRunId[k] = 0.
        END.
        mRunCount = 0.
        DO y = 0 TO piRows - 1:
            DO x = 0 TO piCols - 1:
                IF NOT IsShipCell(pcRows, x, y) OR mRunId[y * piCols + x + 1] <> 0 THEN NEXT.
                IF IsShipCell(pcRows, x + 1, y) THEN horiz = TRUE.
                ELSE IF IsShipCell(pcRows, x, y + 1) THEN horiz = FALSE.
                ELSE UNDO, THROW NEW GridException(SUBSTITUTE("The ship at (&1,&2) is a single cell, and a ship is at least two", x, y)).
                IF mRunCount >= 100 THEN UNDO, THROW NEW GridException("Too many ships on a board").
                shipLen = 0.
                DO WHILE IsShipCell(pcRows, x + (IF horiz THEN shipLen ELSE 0), y + (IF horiz THEN 0 ELSE shipLen)):
                    mRunId[(y + (IF horiz THEN 0 ELSE shipLen)) * piCols + x + (IF horiz THEN shipLen ELSE 0) + 1] = mRunCount + 1.
                    shipLen = shipLen + 1.
                END.
                mRunCount = mRunCount + 1.
                mRunX[mRunCount] = x.
                mRunY[mRunCount] = y.
                mRunLen[mRunCount] = shipLen.
                mRunHoriz[mRunCount] = horiz.
            END.
        END.
        /* no ship cell may have a ship cell of another ship in the eight cells round it */
        DO y = 0 TO piRows - 1:
            DO x = 0 TO piCols - 1:
                IF NOT IsShipCell(pcRows, x, y) THEN NEXT.
                DO dy = -1 TO 1:
                    DO dx = -1 TO 1:
                        IF IsShipCell(pcRows, x + dx, y + dy) AND mRunId[(y + dy) * piCols + x + dx + 1] <> mRunId[y * piCols + x + 1] THEN
                            UNDO, THROW NEW GridException(SUBSTITUTE("Ships may not touch, but the ships at (&1,&2) and (&3,&4) do", x, y, x + dx, y + dy)).
                    END.
                END.
            END.
        END.
        SortRuns().
    END METHOD.

    METHOD PRIVATE LOGICAL IsShipCell(INPUT pcRows AS CHARACTER, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piY < 0 OR piY >= NUM-ENTRIES(pcRows, "/") THEN RETURN FALSE.
        IF piX >= LENGTH(ENTRY(piY + 1, pcRows, "/")) THEN RETURN FALSE.
        RETURN SUBSTRING(ENTRY(piY + 1, pcRows, "/"), piX + 1, 1) = "X".
    END METHOD.

    /* Puts the runs longest first, keeping the order they were found in among equals. */
    METHOD PRIVATE VOID SortRuns():
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE j   AS INTEGER NO-UNDO.
        DEFINE VARIABLE tx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE ty  AS INTEGER NO-UNDO.
        DEFINE VARIABLE tl  AS INTEGER NO-UNDO.
        DEFINE VARIABLE th  AS LOGICAL NO-UNDO.
        DO i = 2 TO mRunCount:
            tx = mRunX[i].
            ty = mRunY[i].
            tl = mRunLen[i].
            th = mRunHoriz[i].
            j = i - 1.
            DO WHILE j >= 1 AND mRunLen[j] < tl:
                mRunX[j + 1] = mRunX[j].
                mRunY[j + 1] = mRunY[j].
                mRunLen[j + 1] = mRunLen[j].
                mRunHoriz[j + 1] = mRunHoriz[j].
                j = j - 1.
            END.
            mRunX[j + 1] = tx.
            mRunY[j + 1] = ty.
            mRunLen[j + 1] = tl.
            mRunHoriz[j + 1] = th.
        END.
    END METHOD.

    /* The fleet the runs make, longest first, as a comma separated list. */
    METHOD PRIVATE CHARACTER FleetOfRuns():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DO i = 1 TO mRunCount:
            result = result + (IF i > 1 THEN "," ELSE "") + STRING(mRunLen[i]).
        END.
        RETURN result.
    END METHOD.

    /* Puts the runs on the board at piOffset as ships 1 to n in order. */
    METHOD PRIVATE VOID StampRuns(INPUT piOffset AS INTEGER, INPUT plShow AS LOGICAL):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mRunCount:
            PutShip(piOffset, i, (IF mRunHoriz[i] THEN mShapeH[i] ELSE mShapeV[i]), mRunX[i], mRunY[i], plShow).
        END.
    END METHOD.

    /* ---- private: the fleet and the grid ---- */

    METHOD PRIVATE VOID ValidateFleet(INPUT piBoardWidth AS INTEGER, INPUT piBoardHeight AS INTEGER, INPUT pcFleet AS CHARACTER):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE shipLen   AS INTEGER NO-UNDO.
        DEFINE VARIABLE total AS INTEGER NO-UNDO.
        IF piBoardWidth = ? OR piBoardHeight = ? OR piBoardWidth < 3 OR piBoardHeight < 3 OR piBoardWidth > 30 OR piBoardHeight > 30 THEN
            UNDO, THROW NEW GridException("A board is from 3 x 3 to 30 x 30 cells").
        IF pcFleet = ? OR pcFleet = "" THEN UNDO, THROW NEW GridException("A fleet needs at least one ship").
        IF NUM-ENTRIES(pcFleet) > 50 THEN UNDO, THROW NEW GridException("A fleet has at most 50 ships").
        DO i = 1 TO NUM-ENTRIES(pcFleet):
            shipLen = INTEGER(TRIM(ENTRY(i, pcFleet))) NO-ERROR.
            IF ERROR-STATUS:ERROR OR shipLen = ? THEN UNDO, THROW NEW GridException("A ship length must be a whole number: " + ENTRY(i, pcFleet)).
            IF shipLen < 2 THEN UNDO, THROW NEW GridException("A ship is at least two cells long, not " + STRING(shipLen)).
            IF shipLen > MAXIMUM(piBoardWidth, piBoardHeight) THEN UNDO, THROW NEW GridException(SUBSTITUTE("A ship of &1 cells does not fit a &2 x &3 board", shipLen, piBoardWidth, piBoardHeight)).
            total = total + shipLen.
        END.
        IF total * 5 > piBoardWidth * piBoardHeight * 2 THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A fleet of &1 cells is too big for a &2 x &3 board", total, piBoardWidth, piBoardHeight)).
    END METHOD.

    /* Stores a validated fleet, longest first, and builds the two shapes of each ship. */
    METHOD PRIVATE VOID SetFleet(INPUT pcFleet AS CHARACTER):
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE j   AS INTEGER NO-UNDO.
        DEFINE VARIABLE shipLen AS INTEGER NO-UNDO.
        n = NUM-ENTRIES(pcFleet).
        EXTENT(mFleet) = n.
        EXTENT(mShapeH) = n.
        EXTENT(mShapeV) = n.
        DO i = 1 TO n:
            shipLen = INTEGER(TRIM(ENTRY(i, pcFleet))).
            j = i - 1.
            DO WHILE j >= 1 AND mFleet[j] < shipLen:
                mFleet[j + 1] = mFleet[j].
                j = j - 1.
            END.
            mFleet[j + 1] = shipLen.
        END.
        DO i = 1 TO n:
            mShapeH[i] = Shape:Parse(FILL("X", mFleet[i])).
            mShapeV[i] = mShapeH[i]:Rotate().
        END.
    END METHOD.

    METHOD PRIVATE Grid GridFor(INPUT piBoardWidth AS INTEGER, INPUT piBoardHeight AS INTEGER):
        RETURN BattleshipsFactory:CreateGrid(piBoardWidth, piBoardHeight).
    END METHOD.

    METHOD PRIVATE VOID CheckBoardCell(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF piX < 0 OR piX >= mBW OR piY < 0 OR piY >= mBH THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Cell (&1,&2) is outside the &3 x &4 board", piX, piY, mBW, mBH)).
    END METHOD.

    METHOD PRIVATE VOID FindLayers():
        mLShip = Grid:Store:LayerIndex("ship").
        mLShot = Grid:Store:LayerIndex("shot").
        mLMark = Grid:Store:LayerIndex("mark").
        mLView = Grid:Store:LayerIndex("view").
    END METHOD.

    METHOD PRIVATE VOID CheckGrid(INPUT poGrid AS Grid):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE layers AS CHARACTER NO-UNDO.
        layers = BattleshipsFactory:Layers().
        IF poGrid:Store:LayerCount <> NUM-ENTRIES(layers) THEN
            UNDO, THROW NEW GridException("A Battleships grid has the layers " + layers).
        DO i = 1 TO NUM-ENTRIES(layers):
            IF poGrid:Store:LayerName(i) <> ENTRY(i, layers) THEN
                UNDO, THROW NEW GridException("A Battleships grid has the layers " + layers).
        END.
        IF poGrid:Width < 7 OR poGrid:Width MODULO 2 = 0 OR poGrid:Height < 3 THEN
            UNDO, THROW NEW GridException("A Battleships grid is two boards and a divider: an odd width of at least 7 and a height of at least 3").
        IF poGrid:Topology:Wraps THEN UNDO, THROW NEW GridException("A Battleships board does not wrap").
    END METHOD.

END CLASS.
