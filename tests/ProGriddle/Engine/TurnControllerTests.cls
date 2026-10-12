USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.TurnControllerTests:

    DEFINE PRIVATE VARIABLE mGame       AS CountingTurnGame  NO-UNDO.
    DEFINE PRIVATE VARIABLE mRenderer   AS RecordingRenderer NO-UNDO.
    DEFINE PRIVATE VARIABLE mController AS TurnController    NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildController():
        mGame = NEW CountingTurnGame(NEW Grid(NEW ArrayStore(3, 3, "s"))).
        mRenderer = NEW RecordingRenderer().
        mController = NEW TurnController(mGame, mRenderer).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseController():
        IF VALID-OBJECT(mController) THEN mController:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mController = ?.
        mGame = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DrawsTheGameOnceWhenBuilt():
        Assert:Equals(1, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID IsNotSteppableAndNeverRuns():
        Assert:IsFalse(mController:Steppable).
        Assert:IsFalse(mController:IsRunning).
        Assert:Equals(0, mController:SpeedLevel).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RefreshDrawsAgainWithoutChangingTheGame():
        mGame:MakeMove().
        mController:Refresh().
        Assert:Equals(2, mRenderer:RenderCount).
        Assert:Equals(1, mGame:Turn).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ResetStartsANewGameAndRedraws():
        mGame:MakeMove().
        mController:Reset().
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(1, mGame:InitialiseCount).
        Assert:Equals(2, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExecuteResetStartsANewGame():
        mGame:MakeMove().
        mController:Execute(GameCommand:Reset).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals(2, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExecuteOfASteppingCommandThrows():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mController:Execute(GameCommand:Start).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PauseGameDoesNothing():
        mController:PauseGame().
        Assert:Equals(1, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SetSpeedLevelThrows():
        DEFINE VARIABLE thrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mController:SetSpeedLevel(3).
            CATCH e AS GridException:
                thrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ConstructorRejectsMissingParts():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE tc     AS TurnController NO-UNDO.
        DO ON ERROR UNDO, THROW:
            tc = NEW TurnController(?, mRenderer).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            tc = NEW TurnController(mGame, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
