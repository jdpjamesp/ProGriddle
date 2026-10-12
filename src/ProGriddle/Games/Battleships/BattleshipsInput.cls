/* What a Battleships window can do. The grid has the computer's waters on the left and your fleet
   on the right, and a click means different things on each:

     your board, left click    place the next ship there (until the first shot)
     your board, right click   take that ship back off (until the first shot)
     computer's waters, left   fire there
     computer's waters, right  mark the cell as water, or clear the mark

   The picker chooses the board size, and with it the fleet, and starts a new game. The extra
   commands are Rotate (horizontal or vertical ships), Random (place your fleet at random), Clear
   (take your fleet off the board) and Water (mark the cells that must be water). Rules shows the
   rules. A click or command that cannot be done leaves a notice saying why. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Battleships.BattleshipsInput FINAL IMPLEMENTS IGameInput:

    DEFINE PRIVATE VARIABLE mGame   AS BattleshipsGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mChoice AS CHARACTER       NO-UNDO.
    DEFINE PRIVATE VARIABLE mNotice AS CHARACTER       NO-UNDO.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            DEFINE VARIABLE head AS CHARACTER NO-UNDO.
            head = SUBSTITUTE("&1 &2 x &3", mChoice, mGame:BoardWidth, mGame:BoardHeight).
            IF mGame:IsWon THEN RETURN SUBSTITUTE("&1   You win in &2 shots!", head, mGame:Turn).
            IF mGame:IsLost THEN RETURN SUBSTITUTE("&1   You lose: the computer sank your fleet. Shots &2", head, mGame:Turn).
            IF mGame:Started THEN
                RETURN SUBSTITUTE("&1   Shots &2   Enemy ships left &3 of &4   Yours left &5 of &6   &7",
                    head, mGame:Turn, mGame:EnemyShipsLeft, mGame:FleetCount, mGame:OwnShipsLeft, mGame:FleetCount, mGame:LastEvent).
            IF mGame:FleetReady THEN RETURN head + "   Fleet ready: fire at the left board".
            RETURN SUBSTITUTE("&1   Place your &2-cell ship, &3   Ships to place &4",
                head, mGame:CurrentShipLength, (IF mGame:Horizontal THEN "horizontal" ELSE "vertical"), mGame:ShipsToPlace).
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "Board".
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceNames AS CHARACTER NO-UNDO
        GET():
            RETURN BattleshipsFleets:Names().
        END GET.

    /* The board size. Setting it starts a new game with that size and its fleet, even when it is
       the same one. */
    DEFINE PUBLIC PROPERTY Choice AS CHARACTER NO-UNDO
        GET():
            RETURN mChoice.
        END GET.
        SET(INPUT pcValue AS CHARACTER):
            IF BattleshipsFleets:Canonical(pcValue) = "" THEN
                UNDO, THROW NEW GridException("Unknown Battleships board size: " + STRING(pcValue)).
            mChoice = BattleshipsFleets:Canonical(pcValue).
            mGame:Configure(BattleshipsFleets:SideOf(mChoice), BattleshipsFleets:SideOf(mChoice), BattleshipsFleets:FleetOf(mChoice)).
        END SET.

    DEFINE PUBLIC PROPERTY CommandNames AS CHARACTER NO-UNDO
        GET():
            RETURN "Rotate:O,Random:F,Clear:C,Water:W".
        END GET.

    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "Rules:H".
        END GET.

    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET():
            RETURN "Place your fleet on the right board, then fire at the computer's waters on the left. "
                 + "Take turns: one shot each, hit or miss. The first to sink the other's whole fleet wins."
                 + CHR(10) + CHR(10)
                 + "Ships are straight lines of two or more cells, never diagonal, and may not touch, not even at a corner. "
                 + "The fleet depends on the board size."
                 + CHR(10) + CHR(10)
                 + "Placing (until your first shot)" + CHR(10)
                 + "  Left click on your board: place the next ship" + CHR(10)
                 + "  Right click on your ship: take it back" + CHR(10)
                 + "  Rotate (O): horizontal or vertical" + CHR(10)
                 + "  Random (F): place the whole fleet" + CHR(10)
                 + "  Clear (C): take your fleet off"
                 + CHR(10) + CHR(10)
                 + "Shooting" + CHR(10)
                 + "  Left click on the computer's waters: fire" + CHR(10)
                 + "  Right click: mark a cell as water, or clear the mark" + CHR(10)
                 + "  Water (W): mark the cells that must be water:" + CHR(10)
                 + "    the corners of every hit, and all round a sunk ship".
        END GET.

    /* poGame is the game to drive, in whatever size it starts. The board size shown first is the
       standard one that matches it, or Custom. */
    CONSTRUCTOR PUBLIC BattleshipsInput(INPUT poGame AS BattleshipsGame):
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE fleet AS CHARACTER NO-UNDO.
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Battleships input needs a game").
        mGame = poGame.
        DO i = 1 TO mGame:FleetCount:
            fleet = fleet + (IF i > 1 THEN "," ELSE "") + STRING(mGame:FleetLength(i)).
        END.
        mChoice = BattleshipsFleets:NameFor(mGame:BoardWidth, fleet).
        IF mChoice = "" OR mGame:BoardWidth <> mGame:BoardHeight THEN mChoice = "Custom".
    END CONSTRUCTOR.

    METHOD PUBLIC CHARACTER TakeNotice():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mNotice.
        mNotice = "".
        RETURN notice.
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        DEFINE VARIABLE marked AS INTEGER NO-UNDO.
        CASE pcCommand:
            WHEN "Rotate" THEN DO:
                mGame:Rotate().
                mNotice = "Next ship: " + (IF mGame:Horizontal THEN "horizontal" ELSE "vertical").
            END.
            WHEN "Random" THEN DO:
                IF mGame:RandomiseFleet() THEN mNotice = "Fleet placed at random".
                ELSE mNotice = "The battle has started".
            END.
            WHEN "Clear" THEN DO:
                IF mGame:ClearFleet() THEN mNotice = "Fleet cleared".
                ELSE mNotice = "The battle has started".
            END.
            WHEN "Water" THEN DO:
                marked = mGame:MarkObviousWater().
                IF marked > 0 THEN mNotice = SUBSTITUTE("Marked &1 cells as water", marked).
                ELSE mNotice = "No new water to mark".
            END.
            OTHERWISE UNDO, THROW NEW GridException("Unknown Battleships command: " + STRING(pcCommand)).
        END CASE.
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT mGame:Grid:InBounds(piX, piY) OR piX = mGame:BoardWidth THEN RETURN.
        IF piX < mGame:BoardWidth THEN FireAt(piX, piY).
        ELSE PlaceAt(piX - mGame:OwnLeft, piY).
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF NOT mGame:Grid:InBounds(piX, piY) OR piX = mGame:BoardWidth THEN RETURN.
        IF piX < mGame:BoardWidth THEN mGame:ToggleWater(piX, piY).
        ELSE IF NOT mGame:RemoveShip(piX - mGame:OwnLeft, piY) AND mGame:Started THEN mNotice = "The battle has started".
    END METHOD.

    /* Battleships has no use for both buttons together. */
    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    /* Fires, or says why it cannot. */
    METHOD PRIVATE VOID FireAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF mGame:IsOver THEN mNotice = "The game is over. Press F2 for a new one".
        ELSE IF NOT mGame:FleetReady THEN mNotice = "Place all your ships first".
        ELSE IF mGame:EnemyMarkAt(piX, piY) <> 0 THEN mNotice = "Marked as water. Right click to clear the mark".
        ELSE IF mGame:EnemyShotAt(piX, piY) <> 0 THEN mNotice = "You already fired there".
        ELSE IF mGame:Fire(piX, piY) THEN DO:
            IF mGame:IsWon THEN mNotice = "You win!".
            ELSE IF mGame:IsLost THEN mNotice = "You lose. " + mGame:LastEvent.
            ELSE mNotice = mGame:LastEvent.
        END.
    END METHOD.

    /* Places the next ship, or says why it cannot. */
    METHOD PRIVATE VOID PlaceAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        IF mGame:Started THEN mNotice = "The battle has started".
        ELSE IF mGame:FleetReady THEN mNotice = "Your fleet is complete. Fire at the left board".
        ELSE IF NOT mGame:PlaceShip(piX, piY) THEN mNotice = "Ships may not touch, not even at a corner".
    END METHOD.

END CLASS.
