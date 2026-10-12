USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Battleships.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

/* Clicks are in grid columns: the computer's waters are columns 0 to 5, the divider is column 6
   and the player's own board is columns 7 to 12 on these 6 x 6 boards. */
CLASS ProGriddle.Games.Battleships.BattleshipsInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS BattleshipsGame  NO-UNDO.
    DEFINE PRIVATE VARIABLE mOpponent AS ScriptedOpponent NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS BattleshipsInput NO-UNDO.

    METHOD PRIVATE CHARACTER Own():
        RETURN "XX..../....../..XXX./....../X...../X.....".
    END METHOD.

    METHOD PRIVATE CHARACTER Enemy():
        RETURN "X..XX./X...../....../.XXX../....../......".
    END METHOD.

    /* Every water cell of the player's board in reading order, for a computer that never hits. */
    METHOD PRIVATE CHARACTER WaterShots():
        DEFINE VARIABLE x      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE result AS CHARACTER NO-UNDO.
        DO y = 0 TO 5:
            DO x = 0 TO 5:
                IF SUBSTRING(ENTRY(y + 1, Own(), "/"), x + 1, 1) <> "X" THEN result = result + (IF result = "" THEN "" ELSE ";") + SUBSTITUTE("&1,&2", x, y).
            END.
        END.
        RETURN result.
    END METHOD.

    /* A Tiny game (6 x 6, ships of 3, 2 and 2) with the fleets not placed yet. */
    METHOD PRIVATE VOID Build(INPUT pcShots AS CHARACTER):
        mOpponent = NEW ScriptedOpponent(pcShots).
        mGame = BattleshipsFactory:Create(6, 6, "3,2,2", NEW SeededRandom(1), mOpponent).
        mInput = NEW BattleshipsInput(mGame).
    END METHOD.

    /* The same, with both fleets loaded and ready to fire. */
    METHOD PRIVATE VOID BuildReady():
        Build(WaterShots()).
        mGame:LoadBoards(Own(), Enemy()).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* ---- the picker ---- */

    @Test.
    METHOD PUBLIC VOID ThePickerOffersTheStandardSizes():
        Build("").
        Assert:Equals("Board", mInput:ChoiceLabel).
        Assert:Equals("Tiny,Small,Classic,Large,Huge", mInput:ChoiceNames).
        Assert:Equals("Tiny", mInput:Choice).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABoardThatIsNotAStandardSizeIsCalledCustom():
        mOpponent = NEW ScriptedOpponent("").
        mGame = BattleshipsFactory:Create(5, 5, "3,2,2", NEW SeededRandom(1), mOpponent).
        Assert:Equals("Custom", NEW BattleshipsInput(mGame):Choice).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingASizeStartsANewGameWithThatBoardAndItsFleet():
        Build("").
        mInput:Choice = "classic".
        Assert:Equals("Classic", mInput:Choice).
        Assert:Equals(10, mGame:BoardWidth).
        Assert:Equals(10, mGame:BoardHeight).
        Assert:Equals(5, mGame:FleetCount).
        Assert:Equals(5, mGame:FleetLength(1)).
        Assert:Equals(2, mGame:FleetLength(5)).
        mInput:Choice = "Huge".
        Assert:Equals(15, mGame:BoardWidth).
        Assert:Equals(9, mGame:FleetCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingTheSameSizeAgainStillStartsANewGame():
        BuildReady().
        mInput:PrimaryAction(4, 4).
        Assert:Equals(1, mGame:Turn).
        mInput:Choice = "Tiny".
        Assert:Equals(0, mGame:Turn).
        Assert:IsFalse(mGame:Started).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownSizeThrows():
        Build("").
        mInput:Choice = "Gigantic".
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID CustomCannotBeChosenFromThePicker():
        Build("").
        mInput:Choice = "Custom".
    END METHOD.

    /* ---- the status line ---- */

    @Test.
    METHOD PUBLIC VOID TheStatusLineTellsYouWhichShipToPlaceAndHow():
        Build("").
        Assert:Equals("Tiny 6 x 6   Place your 3-cell ship, horizontal   Ships to place 3", mInput:StatusText).
        mInput:Perform("Rotate").
        Assert:Equals("Tiny 6 x 6   Place your 3-cell ship, vertical   Ships to place 3", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysWhenTheFleetIsReady():
        BuildReady().
        Assert:Equals("Tiny 6 x 6   Fleet ready: fire at the left board", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineShowsTheShotsShipsLeftAndWhatJustHappened():
        BuildReady().
        mInput:PrimaryAction(4, 4).
        Assert:Equals("Tiny 6 x 6   Shots 1   Enemy ships left 3 of 3   Yours left 3 of 3   You missed. Computer missed.", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysYouWinWithTheNumberOfShots():
        BuildReady().
        mInput:PrimaryAction(0, 0).
        mInput:PrimaryAction(0, 1).
        mInput:PrimaryAction(3, 0).
        mInput:PrimaryAction(4, 0).
        mInput:PrimaryAction(1, 3).
        mInput:PrimaryAction(2, 3).
        mInput:PrimaryAction(3, 3).
        Assert:Equals("Tiny 6 x 6   You win in 7 shots!", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysYouLoseWhenTheComputerSinksYourFleet():
        Build("0,0;1,0;2,2;3,2;4,2;0,4;0,5").
        mGame:LoadBoards(Own(), Enemy()).
        mInput:PrimaryAction(5, 5).
        mInput:PrimaryAction(4, 5).
        mInput:PrimaryAction(3, 5).
        mInput:PrimaryAction(2, 5).
        mInput:PrimaryAction(1, 5).
        mInput:PrimaryAction(0, 5).
        mInput:PrimaryAction(5, 4).
        Assert:Equals("Tiny 6 x 6   You lose: the computer sank your fleet. Shots 7", mInput:StatusText).
        Assert:Equals("You lose. You missed. Computer sank your 2-cell ship.", mInput:TakeNotice()).
    END METHOD.

    /* ---- placing with the mouse ---- */

    @Test.
    METHOD PUBLIC VOID ALeftClickOnYourBoardPlacesTheNextShip():
        Build("").
        mInput:PrimaryAction(7, 0).
        Assert:Equals(1, mGame:OwnShipAt(0, 0)).
        Assert:Equals(1, mGame:OwnShipAt(2, 0)).
        Assert:Equals(2, mGame:ShipsToPlace).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlacementThatTouchesIsRefusedWithAReason():
        Build("").
        mInput:PrimaryAction(7, 0).
        mInput:PrimaryAction(7, 1).
        Assert:Equals(2, mGame:ShipsToPlace).
        Assert:Equals("Ships may not touch, not even at a corner", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARightClickOnYourShipTakesItBack():
        Build("").
        mInput:PrimaryAction(7, 0).
        mInput:SecondaryAction(8, 0).
        Assert:Equals(0, mGame:OwnShipAt(0, 0)).
        Assert:Equals(3, mGame:ShipsToPlace).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClickingOnYourBoardWhenTheFleetIsCompleteExplainsWhy():
        BuildReady().
        mInput:PrimaryAction(12, 5).
        Assert:Equals("Your fleet is complete. Fire at the left board", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClickingOnYourBoardAfterTheFirstShotExplainsWhy():
        BuildReady().
        mInput:PrimaryAction(4, 4).
        mInput:TakeNotice().
        mInput:PrimaryAction(12, 5).
        Assert:Equals("The battle has started", mInput:TakeNotice()).
        mInput:SecondaryAction(7, 0).
        Assert:Equals("The battle has started", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheDividerAndClicksOffTheGridAreIgnored():
        BuildReady().
        mInput:PrimaryAction(6, 2).
        mInput:SecondaryAction(6, 2).
        mInput:PrimaryAction(-1, 0).
        mInput:PrimaryAction(13, 0).
        mInput:SecondaryAction(0, 6).
        mInput:TertiaryAction(2, 2).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    /* ---- shooting with the mouse ---- */

    @Test.
    METHOD PUBLIC VOID ALeftClickOnTheComputersWatersFiresAndTheNoticeSaysWhatHappened():
        BuildReady().
        mInput:PrimaryAction(0, 0).
        Assert:Equals(2, mGame:EnemyShotAt(0, 0)).
        Assert:Equals("You hit a ship. Computer missed.", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FiringBeforeTheFleetIsPlacedExplainsWhy():
        Build("").
        mInput:PrimaryAction(0, 0).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals("Place all your ships first", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FiringAtTheSameCellAgainExplainsWhy():
        BuildReady().
        mInput:PrimaryAction(4, 4).
        mInput:TakeNotice().
        mInput:PrimaryAction(4, 4).
        Assert:Equals(1, mGame:Turn).
        Assert:Equals("You already fired there", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FiringAtAMarkedCellExplainsWhyAndAMarkIsMadeWithARightClick():
        BuildReady().
        mInput:SecondaryAction(4, 4).
        Assert:Equals(1, mGame:EnemyMarkAt(4, 4)).
        mInput:PrimaryAction(4, 4).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals("Marked as water. Right click to clear the mark", mInput:TakeNotice()).
        mInput:SecondaryAction(4, 4).
        Assert:Equals(0, mGame:EnemyMarkAt(4, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FiringAfterTheGameIsOverExplainsHowToStartAgain():
        BuildReady().
        mInput:PrimaryAction(0, 0).
        mInput:PrimaryAction(0, 1).
        mInput:PrimaryAction(3, 0).
        mInput:PrimaryAction(4, 0).
        mInput:PrimaryAction(1, 3).
        mInput:PrimaryAction(2, 3).
        mInput:PrimaryAction(3, 3).
        Assert:Equals("You win!", mInput:TakeNotice()).
        mInput:PrimaryAction(5, 5).
        Assert:Equals("The game is over. Press F2 for a new one", mInput:TakeNotice()).
    END METHOD.

    /* ---- commands ---- */

    @Test.
    METHOD PUBLIC VOID BattleshipsUsesNoKeysAndShowsNoBanner():
        Build("").
        Assert:IsFalse(mInput:HandleKey("Left")).
        mInput:ReleaseKey("").
        Assert:Equals("", mInput:BannerText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCommandsHaveKeys():
        Build("").
        Assert:Equals("Rotate:O,Random:F,Clear:C,Water:W", mInput:CommandNames).
        Assert:Equals("Rules:H", mInput:InfoLabel).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RotateTurnsTheNextShipAndSaysSo():
        Build("").
        mInput:Perform("Rotate").
        Assert:IsFalse(mGame:Horizontal).
        Assert:Equals("Next ship: vertical", mInput:TakeNotice()).
        mInput:Perform("Rotate").
        Assert:Equals("Next ship: horizontal", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RandomPlacesTheWholeFleetUntilShootingStarts():
        Build(WaterShots()).
        mInput:Perform("Random").
        Assert:IsTrue(mGame:FleetReady).
        Assert:Equals("Fleet placed at random", mInput:TakeNotice()).
        mInput:PrimaryAction(0, 0).
        mInput:TakeNotice().
        mInput:Perform("Random").
        Assert:Equals("The battle has started", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearTakesTheFleetOffUntilShootingStarts():
        Build(WaterShots()).
        mInput:Perform("Random").
        mInput:TakeNotice().
        mInput:Perform("Clear").
        Assert:Equals(3, mGame:ShipsToPlace).
        Assert:Equals("Fleet cleared", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WaterMarksTheCellsThatMustBeWaterAndSaysHowMany():
        BuildReady().
        mInput:Perform("Water").
        Assert:Equals("No new water to mark", mInput:TakeNotice()).
        mInput:PrimaryAction(2, 3).
        mInput:TakeNotice().
        mInput:Perform("Water").
        Assert:Equals("Marked 4 cells as water", mInput:TakeNotice()).
        Assert:Equals(1, mGame:EnemyMarkAt(1, 2)).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownCommandThrows():
        Build("").
        mInput:Perform("Cheat").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRulesScreenExplainsTheRulesAndTheControls():
        Build("").
        Assert:IsTrue(INDEX(mInput:InfoText, "may not touch") > 0).
        Assert:IsTrue(INDEX(mInput:InfoText, "never diagonal") > 0).
        Assert:IsTrue(INDEX(mInput:InfoText, "Rotate (O)") > 0).
        Assert:IsTrue(INDEX(mInput:InfoText, "Water (W)") > 0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID TheInputNeedsAGame():
        DEFINE VARIABLE i AS BattleshipsInput NO-UNDO.
        i = NEW BattleshipsInput(?).
    END METHOD.

END CLASS.
