/* Every screen of Football Manager, drawn by the painter from the keys that lead to it: each one draws without trouble, on the board or on the pitch as it should, and the plate comes up at full time. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballScreensTests:

    VAR PRIVATE FootballGame mGame.
    VAR PRIVATE FootballUi mUi.
    VAR PRIVATE FootballInput mInput.
    VAR PRIVATE FootballPainter mPainter.
    VAR PRIVATE RecordingRenderer mInner.

    @Setup.
    METHOD PUBLIC VOID BuildAll():
        mGame = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(5)).
        mUi = NEW FootballUi().
        mInput = NEW FootballInput(mGame, mUi).
        mInner = NEW RecordingRenderer().
        mPainter = NEW FootballPainter(mInner, mGame, mUi).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseAll():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mPainter = ?.
        mGame = ?.
    END METHOD.

    /* Presses a list of keys, such as "A,B,Return". */
    METHOD PRIVATE VOID Press(INPUT pcKeys AS CHARACTER):
        VAR INTEGER i.
        DO i = 1 TO NUM-ENTRIES(pcKeys):
            mInput:HandleKey(ENTRY(i, pcKeys)).
        END.
    END METHOD.

    /* Draws the screen now and says that the picture is on the board (the wooden frame is at the edge, the title band inside it) when it should be. */
    METHOD PRIVATE VOID DrawsOnTheBoard(INPUT pcWhat AS CHARACTER):
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(INTEGER(FootballLook:Tone(FootballRow:Wood, 3)), mPainter:Canvas:ColourAt(1, 100)).
        /* and the title band, clear of its words */
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:BoardHead)), mPainter:Canvas:ColourAt(140, 26)).
    END METHOD.

    /* A game at the menu with plenty of cash, the manager BOB and the first club of the fourth division. */
    METHOD PRIVATE VOID AtTheMenu():
        Press("B,O,B,Return,Return,Return").
        mGame:World:Cash = 1000000.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSetUpScreensDrawOnTheBoard():
        DrawsOnTheBoard("name").
        Press("B,O,B,Return").
        DrawsOnTheBoard("club").
        Press("Return").
        DrawsOnTheBoard("kit").
        Press("Return").
        DrawsOnTheBoard("menu").
        Assert:IsTrue(mInner:RenderCount >= 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMenusScreensDrawOnTheBoard():
        AtTheMenu().
        Press("S").
        DrawsOnTheBoard("status").
        Press("X,A").
        DrawsOnTheBoard("squad").
        Press("Escape,L").
        DrawsOnTheBoard("loan").
        Press("Escape,P").
        DrawsOnTheBoard("repay").
        Press("Escape,V").
        DrawsOnTheBoard("levels").
        Press("Escape").
        DrawsOnTheBoard("main").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSaleAndThePickScreensDrawOnTheBoard():
        AtTheMenu().
        Press("A,Return").
        DrawsOnTheBoard("selling").
        Press("N,Escape,C").
        DrawsOnTheBoard("pick the team").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMatchIsOnThePitchAndTheWeeksScreensAfterItAreOnTheBoard():
        AtTheMenu().
        Press("C,K").
        mPainter:Render(mGame:Grid, mGame).
        /* the pitch has no wooden frame: the stand's roof is at row 18 */
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:Roof)), mPainter:Canvas:ColourAt(100, 18)).
        Press("Space,Space").
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(INTEGER(FootballPhase:FullTime), INTEGER(mGame:Phase)).
        /* the plate over the pitch: its inside is Tunnel */
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:Tunnel)), mPainter:Canvas:ColourAt(66, 60)).
        Press("Return").
        DrawsOnTheBoard("results").
        Press("Return").
        DrawsOnTheBoard("table").
        Press("Return").
        DrawsOnTheBoard("accounts").
        Press("Return").
        DrawsOnTheBoard("transfer").
        Press("P").
        DrawsOnTheBoard("back at the menu").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFullTimePlateIsDrawnOverTheCanvasItIsGiven():
        VAR FootballScreens screens.
        AtTheMenu().
        Press("C,K,Space,Space").
        screens = NEW FootballScreens(mPainter:Canvas, mGame, mUi).
        screens:FullTimePlate().
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:Outline)), mPainter:Canvas:ColourAt(64, 100)).
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:Tunnel)), mPainter:Canvas:ColourAt(66, 60)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScreensRefuseNoCanvasNoGameAndNoScreenState():
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            NEW FootballScreens(?, mGame, mUi).
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(refused).
        refused = FALSE.
        DO ON ERROR UNDO, THROW:
            NEW FootballScreens(mPainter:Canvas, ?, mUi).
            CATCH e2 AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(refused).
        refused = FALSE.
        DO ON ERROR UNDO, THROW:
            NEW FootballScreens(mPainter:Canvas, mGame, ?).
            CATCH e3 AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(refused).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLevelCursorOfTheMenuStartsOnTheLevelInUse():
        AtTheMenu().
        Press("V").
        Assert:Equals(mGame:World:Level, mUi:LevelCursor).
        mUi:LevelCursor = 6.
        Assert:Equals(6, mUi:LevelCursor).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSackedScreenDrawsOnTheBoard():
        AtTheMenu().
        mGame:World:Cash = 0.
        mGame:World:Loan = 1000000.
        Press("C,K,Space,Space,Return,Return,Return,Return").
        DrawsOnTheBoard("sacked").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASeasonEndsOnItsOwnScreenAndNewGameStartsOnTheNameScreenAgain():
        VAR INTEGER guard.
        AtTheMenu().
        DO WHILE mGame:World:Seasons = 0 AND guard < 600:
            guard = guard + 1.
            IF mGame:Phase = FootballPhase:Menu THEN Press("C").
            ELSE IF mGame:Phase = FootballPhase:PickTeam THEN Press("K").
            ELSE IF mGame:Phase = FootballPhase:Transfer THEN Press("P").
            ELSE Press("Space").
            IF mGame:Phase = FootballPhase:SeasonEnd THEN LEAVE.
        END.
        Assert:Equals(INTEGER(FootballPhase:SeasonEnd), INTEGER(mGame:Phase)).
        DrawsOnTheBoard("season end").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingAGameAgainFromTheWindowGoesBackToTheNameScreen():
        AtTheMenu().
        mGame:Initialise().
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(INTEGER(FootballMode:Name), INTEGER(mUi:Mode)).
        DrawsOnTheBoard("name again").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePainterRefusesNoScreenState():
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            NEW FootballPainter(mInner, mGame, ?).
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(refused).
        refused = FALSE.
        DO ON ERROR UNDO, THROW:
            NEW FootballInput(mGame, ?).
            CATCH e2 AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(refused).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScreenStateKeepsAClubSlotAndAnAmount():
        mUi:ClubDivision = 2.
        mUi:ClubCursor = 3.
        Assert:Equals(20, mUi:ClubSlot()).
        mUi:Digits = "".
        Assert:Equals(0, mUi:Amount()).
        mUi:Digits = "123".
        Assert:Equals(123, mUi:Amount()).
        mUi:Settle(FootballPhase:Menu).
        Assert:Equals(INTEGER(FootballMode:Main), INTEGER(mUi:Mode)).
    END METHOD.

END CLASS.
