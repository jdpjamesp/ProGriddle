/* The rules of Snake, tested without a window. A ScriptedRandom decides where the food goes: each
   piece asks for a number below the count of empty cells and the game takes that empty cell,
   counting along the rows, so "0" always puts it in the first empty cell. The board is 8 x 8, and
   a new game has the snake in row 4, the tail at x 2 and the head at x 4, facing right, with the
   food in the top left corner, which as text is:

     *......./......../......../......../..oo@.../......../......../........
*/
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Snake.*.
USING ProGriddle.UI.Text.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeGameTests:

    DEFINE PRIVATE VARIABLE mGame AS SnakeGame NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = NEW SnakeGame(SnakeFactory:CreateGrid(8, 8), NEW ScriptedRandom("0")).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* The board as text: . empty, o body, @ head, * food, rows separated by a slash. */
    METHOD PRIVATE CHARACTER Board():
        RETURN REPLACE(NEW TextGridRenderer("view", SnakeLook:TextSymbols()):ToText(mGame:Grid), CHR(10), "/").
    END METHOD.

    /* Replaces the game with one that uses the given random numbers. */
    METHOD PRIVATE VOID NewGameWith(INPUT pcRandom AS CHARACTER):
        mGame:Dispose().
        mGame = NEW SnakeGame(SnakeFactory:CreateGrid(8, 8), NEW ScriptedRandom(pcRandom)).
    END METHOD.

    /* Runs n steps, which at the start is 150 ms each. */
    METHOD PRIVATE VOID Steps(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Tick(mGame:StepMs).
        END.
    END METHOD.

    METHOD PRIVATE LOGICAL Throws(INPUT pcBody AS CHARACTER, INPUT pcDirection AS CHARACTER):
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:StartWith(pcBody, pcDirection).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        RETURN thrown.
    END METHOD.

    /* ---- a new game ---- */

    @Test.
    METHOD PUBLIC VOID ANewGameIsNamedSnakeAndStartsAtLevelOneWithNothingScored():
        Assert:Equals("Snake", mGame:Name).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, mGame:FoodEaten).
        Assert:Equals(0, mGame:Generation).
        Assert:Equals(1, mGame:Level).
        Assert:IsFalse(mGame:IsOver).
        Assert:IsFalse(mGame:HasWon).
        Assert:IsFalse(mGame:Paused).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameHasASnakeOfThreeInTheMiddleFacingRight():
        Assert:Equals(3, mGame:Length).
        Assert:Equals(4, mGame:HeadX).
        Assert:Equals(4, mGame:HeadY).
        Assert:Equals(1, mGame:Direction).
        Assert:Equals("Right", mGame:DirectionName).
        Assert:Equals("*......./......../......../......../..oo@.../......../......../........", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFoodGoesInTheEmptyCellTheRandomSourceChooses():
        NewGameWith("37").
        /* the first 32 cells are empty, the snake is on cells 34, 35 and 36, so pick 37 is cell 40 */
        Assert:Equals(0, mGame:FoodX).
        Assert:Equals(5, mGame:FoodY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseStartsAgainWithTheScoreAndSpeedBackToTheStart():
        mGame:SetFood(5, 4).
        Steps(1).
        Assert:Equals(10, mGame:Score).
        mGame:Initialise().
        Assert:Equals(0, mGame:Score).
        Assert:Equals(3, mGame:Length).
        Assert:Equals(150, mGame:StepMs).
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(1, mGame:Direction).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASeededRandomSourceGivesTheSameGameEveryTime():
        DEFINE VARIABLE other AS SnakeGame NO-UNDO.
        mGame:Dispose().
        mGame = SnakeFactory:Create(12, 9, NEW SeededRandom(11)).
        other = SnakeFactory:Create(12, 9, NEW SeededRandom(11)).
        Assert:Equals(other:FoodX, mGame:FoodX).
        Assert:Equals(other:FoodY, mGame:FoodY).
        other:Dispose().
    END METHOD.

    /* ---- time and moving ---- */

    @Test.
    METHOD PUBLIC VOID TheSnakeMovesOneCellOnceAStepHasGoneBy():
        Assert:IsFalse(mGame:Tick(149)).
        Assert:Equals(4, mGame:HeadX).
        Assert:IsTrue(mGame:Tick(1)).
        Assert:Equals(5, mGame:HeadX).
        Assert:Equals(1, mGame:Generation).
        Assert:Equals("*......./......../......../......../...oo@../......../......../........", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TimeLeftOverCountsTowardsTheNextStep():
        mGame:Tick(100).
        mGame:Tick(100).
        Assert:Equals(5, mGame:HeadX).
        mGame:Tick(100).
        Assert:Equals(6, mGame:HeadX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALongTimeMakesSeveralSteps():
        Assert:IsTrue(mGame:Tick(450)).
        Assert:Equals(7, mGame:HeadX).
        Assert:Equals(3, mGame:Generation).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStallIsCutToHalfASecondSoTheSnakeDoesNotLurch():
        mGame:Tick(100000).
        Assert:Equals(7, mGame:HeadX).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ZeroOrNegativeTimeDoesNothing():
        Assert:IsFalse(mGame:Tick(0)).
        Assert:IsFalse(mGame:Tick(-20)).
        Assert:Equals(4, mGame:HeadX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhilePausedNothingMovesAndNoTurnIsTaken():
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:Tick(1000)).
        Assert:IsFalse(mGame:TurnUp()).
        Assert:Equals(4, mGame:HeadX).
        mGame:Paused = FALSE.
        Assert:IsTrue(mGame:Tick(150)).
        Assert:Equals(5, mGame:HeadX).
    END METHOD.

    /* ---- steering ---- */

    @Test.
    METHOD PUBLIC VOID ATurnTakesEffectAtTheNextStep():
        Assert:IsTrue(mGame:TurnUp()).
        Assert:Equals(1, mGame:Direction).
        Steps(1).
        Assert:Equals(0, mGame:Direction).
        Assert:Equals("Up", mGame:DirectionName).
        Assert:Equals(4, mGame:HeadX).
        Assert:Equals(3, mGame:HeadY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachOfTheFourTurnsFacesTheRightWay():
        mGame:TurnDown().
        Steps(1).
        Assert:Equals(2, mGame:Direction).
        mGame:TurnLeft().
        Steps(1).
        Assert:Equals(3, mGame:Direction).
        mGame:TurnUp().
        Steps(1).
        Assert:Equals(0, mGame:Direction).
        mGame:TurnRight().
        Steps(1).
        Assert:Equals(1, mGame:Direction).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSnakeCannotTurnBackOnItself():
        Assert:IsFalse(mGame:TurnLeft()).
        Steps(1).
        Assert:Equals(1, mGame:Direction).
        Assert:Equals(5, mGame:HeadX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnThatRepeatsTheWayItIsGoingIsRefused():
        Assert:IsFalse(mGame:TurnRight()).
        mGame:TurnUp().
        Assert:IsFalse(mGame:TurnUp()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TwoTurnsCanWaitAndAreMadeOnSuccessiveSteps():
        Assert:IsTrue(mGame:TurnUp()).
        Assert:IsTrue(mGame:TurnLeft()).
        Steps(1).
        Assert:Equals(4, mGame:HeadX).
        Assert:Equals(3, mGame:HeadY).
        Steps(1).
        Assert:Equals(3, mGame:HeadX).
        Assert:Equals(3, mGame:HeadY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnIsJudgedAgainstTheTurnBeforeItNotTheWayTheSnakeIsFacing():
        mGame:TurnUp().
        Assert:IsFalse(mGame:TurnDown()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThirdTurnIsRefusedWhileTwoAreWaiting():
        mGame:TurnUp().
        mGame:TurnLeft().
        Assert:IsFalse(mGame:TurnDown()).
        Steps(1).
        Assert:IsTrue(mGame:TurnDown()).
    END METHOD.

    /* ---- eating ---- */

    @Test.
    METHOD PUBLIC VOID EatingGrowsTheSnakeAndScoresTen():
        mGame:SetFood(5, 4).
        Steps(1).
        Assert:Equals(4, mGame:Length).
        Assert:Equals(10, mGame:Score).
        Assert:Equals(1, mGame:FoodEaten).
        Assert:Equals("*......./......../......../......../..ooo@../......../......../........", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewPieceOfFoodAppearsAfterOneIsEaten():
        mGame:SetFood(5, 4).
        Steps(1).
        Assert:Equals(0, mGame:FoodX).
        Assert:Equals(0, mGame:FoodY).
        Assert:Equals("*......./......../......../......../..ooo@../......../......../........", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFoodNeverLandsOnTheSnake():
        NewGameWith("0,34").
        /* the first piece goes in cell 0 and is then moved in front of the head. After it is eaten the
           snake covers the cells 34 to 37 of row 4, so the empty cell numbered 34 (counting from 0) is
           cell 38, not cell 34 */
        mGame:SetFood(5, 4).
        Steps(1).
        Assert:Equals(6, mGame:FoodX).
        Assert:Equals(4, mGame:FoodY).
        Assert:Equals("......../......../......../......../..ooo@*./......../......../........", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPieceOfFoodSpeedsTheSnakeUp():
        Assert:Equals(150, mGame:StepMs).
        mGame:SetFood(5, 4).
        Steps(1).
        Assert:Equals(145, mGame:StepMs).
        Assert:Equals(2, mGame:Level).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStepAndTheLevelFollowTheFoodEatenAndStopRisingAtLevel19():
        Assert:Equals(150, SnakeGame:StepMsFor(0)).
        Assert:Equals(145, SnakeGame:StepMsFor(1)).
        Assert:Equals(60, SnakeGame:StepMsFor(18)).
        Assert:Equals(60, SnakeGame:StepMsFor(19)).
        Assert:Equals(60, SnakeGame:StepMsFor(1000)).
        Assert:Equals(150, SnakeGame:StepMsFor(-3)).
        Assert:Equals(1, SnakeGame:LevelFor(0)).
        Assert:Equals(2, SnakeGame:LevelFor(1)).
        Assert:Equals(19, SnakeGame:LevelFor(18)).
        Assert:Equals(19, SnakeGame:LevelFor(500)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFoodCanBeMovedToAnotherEmptyCell():
        mGame:SetFood(6, 6).
        Assert:Equals(6, mGame:FoodX).
        Assert:Equals(6, mGame:FoodY).
        Assert:Equals("......../......../......../......../..oo@.../......../......*./........", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFoodCannotGoOnTheSnakeOrOffTheBoard():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:SetFood(3, 4).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:SetFood(8, 0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:SetFood(0, -1).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
        Assert:Equals(0, mGame:FoodX).
    END METHOD.

    /* ---- dying ---- */

    @Test.
    METHOD PUBLIC VOID HittingTheRightWallEndsTheGame():
        Steps(3).
        Assert:Equals(7, mGame:HeadX).
        Assert:IsFalse(mGame:IsOver).
        Assert:IsTrue(mGame:Tick(150)).
        Assert:IsTrue(mGame:IsOver).
        Assert:IsFalse(mGame:HasWon).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HittingTheTopWallEndsTheGame():
        mGame:StartWith("3,1;3,0", "Up").
        Steps(1).
        Assert:IsTrue(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HittingTheLeftAndBottomWallsEndsTheGame():
        mGame:StartWith("1,3;0,3", "Left").
        Steps(1).
        Assert:IsTrue(mGame:IsOver).
        mGame:StartWith("3,6;3,7", "Down").
        Steps(1).
        Assert:IsTrue(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RunningIntoItsOwnBodyEndsTheGame():
        /* a hook: the head at 2,2 turns up into the body cell 2,1 */
        mGame:StartWith("1,1;2,1;3,1;3,2;2,2", "Left").
        mGame:TurnUp().
        Steps(1).
        Assert:IsTrue(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeadSnakeStaysWhereItDiedAndTheClockAndTurnsDoNothing():
        Steps(4).
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(7, mGame:HeadX).
        Assert:IsFalse(mGame:Tick(1000)).
        Assert:IsFalse(mGame:TurnUp()).
        Assert:Equals(7, mGame:HeadX).
        Assert:Equals(3, mGame:Length).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeadMayEnterTheCellTheTailIsLeaving():
        /* a ring of four cells chasing its own tail: the head at 1,2 steps up onto 1,1, where the tail is */
        mGame:StartWith("1,1;2,1;2,2;1,2", "Left").
        mGame:TurnUp().
        Steps(1).
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(1, mGame:HeadX).
        Assert:Equals(1, mGame:HeadY).
        Assert:Equals(4, mGame:Length).
        Assert:Equals("*......./.@o...../.oo...../......../......../......../......../........", Board()).
    END METHOD.

    /* ---- winning ---- */

    @Test.
    METHOD PUBLIC VOID EatingTheLastPieceOfFoodFillsTheBoardAndWins():
        DEFINE VARIABLE body AS CHARACTER NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER   NO-UNDO.
        mGame:Dispose().
        mGame = NEW SnakeGame(SnakeFactory:CreateGrid(5, 5), NEW ScriptedRandom("0")).
        /* a snake that winds along every row, left to right on the even rows and back on the odd ones,
           and stops at 3,4 so that only 4,4 is empty. The food goes there, as the only empty cell */
        DO y = 0 TO 4:
            DO x = 0 TO 4:
                IF y = 4 AND x = 4 THEN LEAVE.
                body = body + (IF body = "" THEN "" ELSE ";") + SUBSTITUTE("&1,&2", (IF y MODULO 2 = 0 THEN x ELSE 4 - x), y).
            END.
        END.
        mGame:StartWith(body, "Right").
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(24, mGame:Length).
        Assert:Equals(4, mGame:FoodX).
        Assert:Equals(4, mGame:FoodY).
        Steps(1).
        Assert:Equals(25, mGame:Length).
        Assert:IsTrue(mGame:HasWon).
        Assert:IsTrue(mGame:IsOver).
        Assert:Equals(-1, mGame:FoodX).
    END METHOD.

    /* ---- setting up a game ---- */

    @Test.
    METHOD PUBLIC VOID StartWithPlacesTheSnakeFacesItAndStartsTheScoringAgain():
        mGame:SetFood(5, 4).
        Steps(1).
        mGame:StartWith("1,5;2,5", "Down").
        Assert:Equals(2, mGame:Length).
        Assert:Equals(2, mGame:HeadX).
        Assert:Equals(5, mGame:HeadY).
        Assert:Equals(2, mGame:Direction).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(0, mGame:Generation).
        Assert:Equals("*......./......../......../......../......../.o@...../......../........", Board()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASnakeOfOneCellCanBePlacedAndMoves():
        mGame:StartWith("3,3", "Up").
        Assert:Equals(1, mGame:Length).
        Steps(1).
        Assert:Equals(3, mGame:HeadX).
        Assert:Equals(2, mGame:HeadY).
        Assert:Equals(1, mGame:Length).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadSnakeIsRefusedAndLeavesTheGameAsItWas():
        Assert:IsTrue(Throws("2,2;2,4", "Up")).
        Assert:IsTrue(Throws("2,2;9,2", "Up")).
        Assert:IsTrue(Throws("2,2;3,2;2,2", "Up")).
        Assert:IsTrue(Throws("2,2;3,3", "Up")).
        Assert:IsTrue(Throws("a,2;3,2", "Up")).
        Assert:IsTrue(Throws("2;3", "Up")).
        Assert:IsTrue(Throws("", "Up")).
        Assert:IsTrue(Throws("2,2;3,2", "Sideways")).
        Assert:IsTrue(Throws("2,2;3,2", "Left")).
        Assert:Equals("*......./......../......../......../..oo@.../......../......../........", Board()).
    END METHOD.

    /* ---- waiting for the first key ---- */

    @Test.
    METHOD PUBLIC VOID ByDefaultAGameDoesNotWaitForAKey():
        Assert:IsFalse(mGame:WaitForKey).
        Assert:IsFalse(mGame:Waiting).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatWaitsForAKeyDoesNotMoveUntilTheFirstTurn():
        mGame:WaitForKey = TRUE.
        Assert:IsTrue(mGame:Waiting).
        Assert:IsFalse(mGame:Tick(1000)).
        Assert:Equals(4, mGame:HeadX).
        Assert:IsTrue(mGame:TurnUp()).
        Assert:IsFalse(mGame:Waiting).
        Steps(1).
        Assert:Equals(4, mGame:HeadX).
        Assert:Equals(3, mGame:HeadY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheKeyForTheWayItIsFacingStartsTheSnakeWithoutTurningIt():
        mGame:WaitForKey = TRUE.
        Assert:IsTrue(mGame:TurnRight()).
        Assert:IsFalse(mGame:Waiting).
        Steps(1).
        Assert:Equals(5, mGame:HeadX).
        Assert:Equals(4, mGame:HeadY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKeyThatWouldReverseTheSnakeDoesNotStartIt():
        mGame:WaitForKey = TRUE.
        Assert:IsFalse(mGame:TurnLeft()).
        Assert:IsTrue(mGame:Waiting).
        Assert:IsFalse(mGame:Tick(1000)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryNewGameWaitsAgain():
        mGame:WaitForKey = TRUE.
        mGame:TurnRight().
        Steps(1).
        mGame:Initialise().
        Assert:IsTrue(mGame:Waiting).
        mGame:StartWith("1,1;2,1", "Right").
        Assert:IsTrue(mGame:Waiting).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsAlreadyMovingDoesNotStopToWaitWhenTheFlagIsSet():
        Steps(1).
        mGame:WaitForKey = TRUE.
        Assert:IsFalse(mGame:Waiting).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SwitchingTheFlagOffStopsTheWaiting():
        mGame:WaitForKey = TRUE.
        mGame:WaitForKey = FALSE.
        Assert:IsFalse(mGame:Waiting).
        Assert:IsTrue(mGame:Tick(150)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedWaitingGameTakesNoTurn():
        mGame:WaitForKey = TRUE.
        mGame:Paused = TRUE.
        Assert:IsFalse(mGame:TurnUp()).
        Assert:IsTrue(mGame:Waiting).
    END METHOD.

    /* ---- changing the board ---- */

    @Test.
    METHOD PUBLIC VOID ReplaceStartsANewGameOnTheNewBoard():
        mGame:SetFood(5, 4).
        Steps(1).
        mGame:Replace(SnakeFactory:CreateGrid(12, 10)).
        Assert:Equals(12, mGame:Grid:Width).
        Assert:Equals(10, mGame:Grid:Height).
        Assert:Equals(6, mGame:HeadX).
        Assert:Equals(5, mGame:HeadY).
        Assert:Equals(3, mGame:Length).
        Assert:Equals(0, mGame:Score).
        Assert:Equals(1, mGame:Direction).
        Assert:IsFalse(mGame:IsOver).
        Assert:IsTrue(mGame:Tick(150)).
        Assert:Equals(7, mGame:HeadX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReplaceWorksOnAGameThatIsOverAndOnAMuchSmallerBoard():
        Steps(4).
        Assert:IsTrue(mGame:IsOver).
        mGame:Replace(SnakeFactory:CreateGrid(5, 5)).
        Assert:IsFalse(mGame:IsOver).
        Assert:Equals(2, mGame:HeadX).
        Assert:Equals(2, mGame:HeadY).
        Assert:IsTrue(mGame:Tick(150)).
        Assert:Equals(3, mGame:HeadX).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReplaceKeepsTheWaitForKeyChoice():
        mGame:WaitForKey = TRUE.
        mGame:Replace(SnakeFactory:CreateGrid(9, 9)).
        Assert:IsTrue(mGame:Waiting).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReplaceRefusesAGridThatWillNotDoAndChangesNothing():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:Replace(NEW Grid(NEW ArrayStore(8, 8, "state"))).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:Replace(SnakeFactory:CreateGrid(4, 9)).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:Replace(?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
        Assert:Equals(8, mGame:Grid:Width).
        Assert:Equals("*......./......../......../......../..oo@.../......../......../........", Board()).
    END METHOD.

    /* ---- building the game ---- */

    @Test.
    METHOD PUBLIC VOID TheGameNeedsAGridWithTheOneViewLayerAtLeastFiveByFive():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW SnakeGame(NEW Grid(NEW ArrayStore(8, 8, "state")), NEW ScriptedRandom("0")).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW SnakeGame(SnakeFactory:CreateGrid(4, 8), NEW ScriptedRandom("0")).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW SnakeGame(SnakeFactory:CreateGrid(8, 4), NEW ScriptedRandom("0")).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameNeedsARandomSource():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW SnakeGame(SnakeFactory:CreateGrid(8, 8), ?).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBoardCanBeRectangular():
        mGame:Dispose().
        mGame = SnakeFactory:Create(30, 12, NEW SeededRandom(2)).
        Assert:Equals(30, mGame:Grid:Width).
        Assert:Equals(12, mGame:Grid:Height).
        Assert:Equals(15, mGame:HeadX).
        Assert:Equals(6, mGame:HeadY).
    END METHOD.

    /* ---------------------------------- effects ---------------------------------- */

    @Test.
    METHOD PUBLIC VOID TheSnakeCanBeReadFromTheTailToTheHead():
        Assert:Equals(3, mGame:Length).
        Assert:Equals(2, mGame:BodyX(0)).
        Assert:Equals(4, mGame:BodyY(0)).
        Assert:Equals(3, mGame:BodyX(1)).
        Assert:Equals(4, mGame:BodyX(2)).
        Assert:Equals(mGame:HeadX, mGame:BodyX(2)).
        Steps(1).
        /* it moved: the tail is now where the middle was, the head one further on, and the ring wraps without trouble */
        Assert:Equals(3, mGame:BodyX(0)).
        Assert:Equals(5, mGame:BodyX(2)).
        Assert:Equals(mGame:HeadY, mGame:BodyY(2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBodyReadersRefuseAnIndexOutsideTheSnake():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mGame:BodyX(-1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mGame:BodyY(3).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameKeepsAClockOfItsOwnThatDoesNotCountPausedTime():
        Assert:Equals(0, mGame:ElapsedMs).
        mGame:Tick(100).
        Assert:Equals(100, mGame:ElapsedMs).
        mGame:Paused = TRUE.
        mGame:Tick(100).
        Assert:Equals(100, mGame:ElapsedMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryNewGameHasANewSerialNumber():
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        before = mGame:GameSerial.
        mGame:StartWith("1,1;2,1", "Right").
        Assert:Equals(before + 1, mGame:GameSerial).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameNotesWhenFoodIsPutDownAndWhenItIsEaten():
        Assert:Equals(0, mGame:FoodMs).
        Assert:Equals(-1, mGame:LastEatMs).
        Assert:Equals(-1, mGame:LastEatX).
        mGame:StartWith("1,0;2,0", "Right").
        mGame:SetFood(3, 0).
        mGame:Tick(50).
        mGame:Tick(100).
        Assert:Equals(150, mGame:LastEatMs).
        Assert:Equals(3, mGame:LastEatX).
        Assert:Equals(0, mGame:LastEatY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameNotesWhenItEndsByACrashAndByAWin():
        Assert:Equals(-1, mGame:OverMs).
        mGame:StartWith("1,0;0,0", "Left").
        mGame:Tick(50).
        mGame:Tick(100).
        Assert:Equals(150, mGame:OverMs).
        mGame:StartWith("1,0;0,0", "Left").
        Assert:Equals(-1, mGame:OverMs).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABoardThatIsFilledEndsWithAWinAndTheTime():
        DEFINE VARIABLE g AS SnakeGame NO-UNDO.
        g = NEW SnakeGame(SnakeFactory:CreateGrid(5, 5), NEW ScriptedRandom("0")).
        g:StartWith("0,0;1,0;2,0;3,0;4,0;4,1;3,1;2,1;1,1;0,1;0,2;1,2;2,2;3,2;4,2;4,3;3,3;2,3;1,3;0,3;0,4;1,4;2,4;3,4", "Right").
        g:SetFood(4, 4).
        g:Tick(150).
        Assert:IsTrue(g:HasWon).
        Assert:Equals(150, g:OverMs).
        Assert:Equals(-1, g:FoodMs).
        g:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnimatedMakesTickSayWhenTheSnakeWaitsAndKeepsAnimatingForABitAfterTheEnd():
        mGame:Animated = TRUE.
        mGame:WaitForKey = TRUE.
        Assert:IsTrue(mGame:Tick(20)).
        Assert:IsFalse(mGame:Animating).
        mGame:StartWith("1,0;0,0", "Left").
        mGame:WaitForKey = FALSE.
        mGame:Tick(150).
        Assert:IsTrue(mGame:IsOver).
        Assert:IsTrue(mGame:Animating).
        Assert:IsTrue(mGame:Tick(1000)).
        Assert:IsTrue(mGame:Animating).
        Assert:IsFalse(mGame:Tick(3000)).
        Assert:IsFalse(mGame:Animating).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithoutAnimatedNothingChangesForTick():
        Assert:IsFalse(mGame:Animated).
        mGame:WaitForKey = TRUE.
        Assert:IsFalse(mGame:Tick(20)).
        mGame:WaitForKey = FALSE.
        Assert:IsTrue(mGame:Tick(150)).
        Assert:IsFalse(mGame:Tick(20)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBestScoreIsHeldForThePainterAndRefusesNonsense():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        Assert:Equals(0, mGame:BestScore).
        mGame:BestScore = 120.
        Assert:Equals(120, mGame:BestScore).
        DO ON ERROR UNDO, THROW:
            mGame:BestScore = -1.
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnAnimatedGameSaysSomethingChangedOnlyOncePerSliceOfTheClock():
        mGame:Animated = TRUE.
        mGame:WaitForKey = TRUE.
        /* a new apple is growing for 150 ms, so wait that out: then slices of 100 ms */
        Assert:IsTrue(mGame:Tick(200)).
        Assert:IsFalse(mGame:Tick(20)).
        Assert:IsFalse(mGame:Tick(20)).
        Assert:IsTrue(mGame:Tick(60)).
        Assert:IsFalse(mGame:Tick(20)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhileSomethingIsMovingTheSlicesAreThirtyThreeMilliseconds():
        mGame:Animated = TRUE.
        mGame:StartWith("1,4;2,4", "Right").
        mGame:SetFood(3, 4).
        mGame:Tick(150).
        Assert:IsTrue(mGame:LastEatMs >= 0).
        /* just after the food was eaten: a new slice every 33 ms */
        mGame:Tick(1).
        Assert:IsFalse(mGame:Tick(10)).
        Assert:IsTrue(mGame:Tick(10)).
        Assert:IsFalse(mGame:Tick(10)).
        Assert:IsTrue(mGame:Tick(20)).
    END METHOD.

END CLASS.
