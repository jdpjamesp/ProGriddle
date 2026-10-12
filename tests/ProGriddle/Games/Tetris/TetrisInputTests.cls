USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Tetris.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Tetris.TetrisInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS TetrisGame    NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS MemorySettings NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS TetrisInput   NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildInput():
        mSettings = NEW MemorySettings().
        mGame = TetrisFactory:Create(NEW SeededRandom(1)).
        mGame:StartWith("I,O,T,S,Z,J,L").
        mInput = NEW TetrisInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* ---- the keys ---- */

    @Test.
    METHOD PUBLIC VOID TheArrowKeysAndTheirLettersMoveThePiece():
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:Equals(2, mGame:PieceX).
        Assert:IsTrue(mInput:HandleKey("A")).
        Assert:Equals(1, mGame:PieceX).
        Assert:IsTrue(mInput:HandleKey("Right")).
        Assert:IsTrue(mInput:HandleKey("D")).
        Assert:Equals(3, mGame:PieceX).
        Assert:IsTrue(mInput:HandleKey("Down")).
        Assert:Equals(1, mGame:PieceY).
        Assert:IsTrue(mInput:HandleKey("S")).
        Assert:Equals(2, mGame:PieceY).
        Assert:Equals(2, mGame:Score).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID UpWAndXTurnClockwiseAndZTurnsAnticlockwise():
        mInput:HandleKey("Up").
        Assert:Equals(1, mGame:Turns).
        mInput:ReleaseKey("Up").
        mInput:HandleKey("W").
        Assert:Equals(2, mGame:Turns).
        mInput:ReleaseKey("W").
        mInput:HandleKey("X").
        Assert:Equals(3, mGame:Turns).
        mInput:ReleaseKey("X").
        mInput:HandleKey("Z").
        Assert:Equals(2, mGame:Turns).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceIsAHardDrop():
        Assert:IsTrue(mInput:HandleKey("Space")).
        Assert:Equals(1, mGame:PiecesPlaced).
        Assert:Equals(38, mGame:Score).
        Assert:Equals(2, mGame:CurrentPiece).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKeyTheGameDoesNotUseIsNotTaken():
        Assert:IsFalse(mInput:HandleKey("P")).
        Assert:IsFalse(mInput:HandleKey("F2")).
        Assert:IsFalse(mInput:HandleKey("R")).
        Assert:IsFalse(mInput:HandleKey("G")).
        Assert:IsFalse(mInput:HandleKey("Escape")).
        Assert:IsFalse(mInput:HandleKey(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AKeyIsTakenEvenWhenTheMoveIsImpossible():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 5:
            mInput:HandleKey("Left").
        END.
        Assert:Equals(0, mGame:PieceX).
        Assert:IsTrue(mInput:HandleKey("Left")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MovementKeysRepeatWhileHeld():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 3:
            mInput:HandleKey("Left").
        END.
        Assert:Equals(0, mGame:PieceX).
        DO i = 1 TO 5:
            mInput:HandleKey("Down").
        END.
        Assert:Equals(5, mGame:PieceY).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATurnKeyHeldDownTurnsOnceNotOnEveryRepeat():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 6:
            mInput:HandleKey("Up").
        END.
        Assert:Equals(1, mGame:Turns).
        mInput:ReleaseKey("Up").
        mInput:HandleKey("Up").
        Assert:Equals(2, mGame:Turns).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpaceBarHeldDownDropsOnePieceNotAWholeStack():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 6:
            mInput:HandleKey("Space").
        END.
        Assert:Equals(1, mGame:PiecesPlaced).
        mInput:ReleaseKey("Space").
        mInput:HandleKey("Space").
        Assert:Equals(2, mGame:PiecesPlaced).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TwoDifferentTurnKeysHeldTogetherEachWorkOnce():
        mInput:HandleKey("Up").
        mInput:HandleKey("Z").
        mInput:HandleKey("Up").
        mInput:HandleKey("Z").
        Assert:Equals(0, mGame:Turns).
        Assert:IsFalse(mGame:Paused).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ReleasingWithAnEmptyNameFreesEveryKey():
        mInput:HandleKey("Up").
        mInput:HandleKey("Space").
        mInput:ReleaseKey("").
        mInput:HandleKey("Up").
        Assert:Equals(1, mGame:PiecesPlaced).
        Assert:Equals(1, mGame:Turns).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhilePausedTheKeysAreTakenButNothingMoves():
        mGame:Paused = TRUE.
        Assert:IsTrue(mInput:HandleKey("Left")).
        Assert:IsTrue(mInput:HandleKey("Space")).
        Assert:Equals(3, mGame:PieceX).
        Assert:Equals(0, mGame:PiecesPlaced).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMouseDoesNothing():
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(1, 1).
        mInput:TertiaryAction(1, 1).
        Assert:Equals(3, mGame:PieceX).
        Assert:Equals(0, mGame:PieceY).
    END METHOD.

    /* ---- the status line and the banner ---- */

    @Test.
    METHOD PUBLIC VOID TheStatusLineShowsScoreLinesLevelAndTheNextPiece():
        Assert:Equals("Score 0   Lines 0   Level 1   Next O", mInput:StatusText).
        mInput:HandleKey("Space").
        Assert:Equals("Score 38   Lines 0   Level 1   Next T", mInput:StatusText).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysGameOverWithTheFinalScore():
        DEFINE VARIABLE drops AS INTEGER NO-UNDO.
        mGame:StartWith("O,O,O,O,O,O,O,O,O,O,O,O").
        DO WHILE NOT mGame:IsOver AND drops < 15:
            mGame:HardDrop().
            drops = drops + 1.
        END.
        Assert:IsTrue(INDEX(mInput:StatusText, "Game over   Score ") = 1).
        Assert:IsTrue(INDEX(mInput:StatusText, "Lines 0   Level 1") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBannerSaysPausedWhilePausedAndGameOverWhenOver():
        DEFINE VARIABLE drops AS INTEGER NO-UNDO.
        Assert:Equals("", mInput:BannerText).
        mGame:Paused = TRUE.
        Assert:Equals("PAUSED", mInput:BannerText).
        mGame:Paused = FALSE.
        mGame:StartWith("O,O,O,O,O,O,O,O,O,O,O,O").
        DO WHILE NOT mGame:IsOver AND drops < 15:
            mGame:HardDrop().
            drops = drops + 1.
        END.
        Assert:Equals("GAME OVER", mInput:BannerText).
    END METHOD.

    /* ---- the start level picker ---- */

    @Test.
    METHOD PUBLIC VOID ThePickerOffersLevelsOneToTen():
        Assert:Equals("Start level", mInput:ChoiceLabel).
        Assert:Equals("1,2,3,4,5,6,7,8,9,10", mInput:ChoiceNames).
        Assert:Equals("1", mInput:Choice).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingALevelBeforeTheFirstPieceSettlesStartsTheGameThereAtOnce():
        mInput:Choice = "4".
        Assert:Equals("4", mInput:Choice).
        Assert:Equals(4, mGame:Level).
        Assert:Equals(0, mGame:PiecesPlaced).
        Assert:Equals("", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingALevelDuringAGameWaitsForTheNextNewGame():
        mInput:HandleKey("Space").
        mInput:Choice = "6".
        Assert:Equals(1, mGame:Level).
        Assert:Equals("Level 6 from the next new game (F2)", mInput:TakeNotice()).
        mGame:Initialise().
        Assert:Equals(6, mGame:Level).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownStartLevelThrows():
        mInput:Choice = "11".
    END METHOD.

    /* ---- commands ---- */

    @Test.
    METHOD PUBLIC VOID GhostSwitchesTheGhostPieceAndRemembersIt():
        Assert:Equals("Ghost:G", mInput:CommandNames).
        Assert:IsTrue(mGame:ShowGhost).
        mInput:Perform("Ghost").
        Assert:IsFalse(mGame:ShowGhost).
        Assert:IsFalse(mSettings:GetLogical("tetris.ghost", TRUE)).
        Assert:Equals("Ghost piece off", mInput:TakeNotice()).
        mInput:Perform("Ghost").
        Assert:IsTrue(mGame:ShowGhost).
        Assert:Equals("Ghost piece on", mInput:TakeNotice()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSavedGhostSettingIsReadWhenTheInputIsBuilt():
        mSettings:SetLogical("tetris.ghost", FALSE).
        mInput = NEW TetrisInput(mGame, mSettings).
        Assert:IsFalse(mGame:ShowGhost).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HelpExplainsTheKeysAndTheScoring():
        Assert:Equals("Help:H", mInput:InfoLabel).
        Assert:IsTrue(INDEX(mInput:InfoText, "hard drop") > 0).
        Assert:IsTrue(INDEX(mInput:InfoText, "turn anticlockwise") > 0).
        Assert:IsTrue(INDEX(mInput:InfoText, "4 lines 800") > 0).
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID AnUnknownCommandThrows():
        mInput:Perform("Cheat").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInputNeedsAGameAndSettings():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE i      AS TetrisInput NO-UNDO.
        DO ON ERROR UNDO, THROW:
            i = NEW TetrisInput(?, mSettings).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            i = NEW TetrisInput(mGame, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
