/* Scripted sessions: a real LifeGame driven by GameController, a FakeClock and a
   TextGridRenderer, the way a person would drive it from the keyboard. This is the
   no-GUI proof that the whole stack works together. */
USING OpenEdge.Core.Assert.
USING Progress.Lang.*.
USING Prolif.Engine.GameCommand.
USING Prolif.Engine.GameController.
USING Prolif.Games.Life.LifeFactory.
USING Prolif.Games.Life.LifeGame.
USING Prolif.Games.Life.LifePatterns.
USING Prolif.Games.Life.LifeRules.
USING Prolif.UI.Text.FakeClock.
USING Prolif.UI.Text.TextGridRenderer.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Games.Life.LifeSessionTests:

    DEFINE PRIVATE VARIABLE LF AS CHARACTER NO-UNDO.

    CONSTRUCTOR PUBLIC LifeSessionTests():
        LF = CHR(10).
    END CONSTRUCTOR.

    METHOD PRIVATE CHARACTER Horizontal():
        RETURN "....." + LF + "....." + LF + ".###." + LF + "....." + LF + ".....".
    END METHOD.

    METHOD PRIVATE CHARACTER Vertical():
        RETURN "....." + LF + "..#.." + LF + "..#.." + LF + "..#.." + LF + ".....".
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AScriptedSessionWithABlinker():
        DEFINE VARIABLE game     AS LifeGame NO-UNDO.
        DEFINE VARIABLE renderer AS TextGridRenderer NO-UNDO.
        DEFINE VARIABLE clock    AS FakeClock NO-UNDO.
        DEFINE VARIABLE ctrl     AS GameController NO-UNDO.
        DO ON ERROR UNDO, THROW:
            game = LifeFactory:Create(5, 5, FALSE, LifeRules:Conway(), 0.01).
            game:Place(LifePatterns:Blinker(), 1, 2).
            renderer = NEW TextGridRenderer("state", ".#").
            clock = NEW FakeClock().
            ctrl = NEW GameController(game, renderer, clock).

            /* the starting board is drawn as soon as the controller is built */
            Assert:Equals(1, renderer:RenderCount).
            Assert:Equals(Horizontal(), renderer:LastOutput).

            /* Space: start. A quarter of a second per step at the default speed. */
            ctrl:Execute(GameCommand:Start).
            clock:Advance(250).
            Assert:Equals(Vertical(), renderer:LastOutput).
            clock:Advance(250).
            Assert:Equals(Horizontal(), renderer:LastOutput).
            Assert:Equals(2, game:Generation).

            /* Space again: pause. Time passing changes nothing. */
            ctrl:Execute(GameCommand:PauseGame).
            clock:Advance(5000).
            Assert:Equals(2, game:Generation).
            Assert:Equals(3, renderer:RenderCount).

            /* S: single step while paused */
            ctrl:Execute(GameCommand:StepOnce).
            Assert:Equals(Vertical(), renderer:LastOutput).
            Assert:Equals(3, game:Generation).

            /* R: reset to the board as it was at the first step */
            ctrl:Execute(GameCommand:Reset).
            Assert:Equals(Horizontal(), renderer:LastOutput).
            Assert:Equals(0, game:Generation).
            Assert:IsFalse(ctrl:IsRunning).
            FINALLY:
                IF VALID-OBJECT(ctrl) THEN ctrl:Dispose().
                IF VALID-OBJECT(game) THEN game:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedKeysChangeHowManyGenerationsPassInASecond():
        DEFINE VARIABLE game     AS LifeGame NO-UNDO.
        DEFINE VARIABLE clock    AS FakeClock NO-UNDO.
        DEFINE VARIABLE ctrl     AS GameController NO-UNDO.
        DO ON ERROR UNDO, THROW:
            game = LifeFactory:Create(5, 5, FALSE, LifeRules:Conway(), 0.01).
            game:Place(LifePatterns:Blinker(), 1, 2).
            clock = NEW FakeClock().
            ctrl = NEW GameController(game, NEW TextGridRenderer("state", ".#"), clock).
            ctrl:Start().
            clock:Advance(1000).
            Assert:Equals(4, game:Generation).
            ctrl:Execute(GameCommand:SpeedUp).
            ctrl:Execute(GameCommand:SpeedUp).
            clock:Advance(1000).
            /* level 5 is one step every 60 ms: 16 more in a second, 16 * 60 = 960 */
            Assert:Equals(20, game:Generation).
            ctrl:Execute(GameCommand:SlowDown).
            ctrl:Execute(GameCommand:SlowDown).
            ctrl:Execute(GameCommand:SlowDown).
            ctrl:Execute(GameCommand:SlowDown).
            clock:Advance(2000).
            /* level 1 is one step a second */
            Assert:Equals(22, game:Generation).
            FINALLY:
                IF VALID-OBJECT(ctrl) THEN ctrl:Dispose().
                IF VALID-OBJECT(game) THEN game:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EditingTheBoardWhilePausedShowsOnTheNextDraw():
        DEFINE VARIABLE game     AS LifeGame NO-UNDO.
        DEFINE VARIABLE renderer AS TextGridRenderer NO-UNDO.
        DEFINE VARIABLE ctrl     AS GameController NO-UNDO.
        DO ON ERROR UNDO, THROW:
            game = LifeFactory:Create(5, 5, FALSE, LifeRules:Conway(), 0.5).
            renderer = NEW TextGridRenderer("state", ".#").
            ctrl = NEW GameController(game, renderer, NEW FakeClock()).
            /* the user clicks three cells in a row, then steps */
            game:ToggleCell(1, 2).
            game:ToggleCell(2, 2).
            game:ToggleCell(3, 2).
            ctrl:StepOnce().
            Assert:Equals(Vertical(), renderer:LastOutput).
            FINALLY:
                IF VALID-OBJECT(ctrl) THEN ctrl:Dispose().
                IF VALID-OBJECT(game) THEN game:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADenseAndASparseSessionDrawTheSameThing():
        DEFINE VARIABLE dense   AS LifeGame NO-UNDO.
        DEFINE VARIABLE sparse  AS LifeGame NO-UNDO.
        DEFINE VARIABLE rd      AS TextGridRenderer NO-UNDO.
        DEFINE VARIABLE rs      AS TextGridRenderer NO-UNDO.
        DEFINE VARIABLE cd      AS FakeClock NO-UNDO.
        DEFINE VARIABLE cs      AS FakeClock NO-UNDO.
        DEFINE VARIABLE ctrlD   AS GameController NO-UNDO.
        DEFINE VARIABLE ctrlS   AS GameController NO-UNDO.
        DO ON ERROR UNDO, THROW:
            dense = LifeFactory:Create(30, 20, TRUE, LifeRules:Conway(), 0.5).
            sparse = LifeFactory:Create(30, 20, TRUE, LifeRules:Conway(), 0.01).
            dense:Place(LifePatterns:Glider(), 2, 2).
            sparse:Place(LifePatterns:Glider(), 2, 2).
            dense:Place(LifePatterns:Blinker(), 15, 10).
            sparse:Place(LifePatterns:Blinker(), 15, 10).
            rd = NEW TextGridRenderer("state", ".#").
            rs = NEW TextGridRenderer("state", ".#").
            cd = NEW FakeClock().
            cs = NEW FakeClock().
            ctrlD = NEW GameController(dense, rd, cd).
            ctrlS = NEW GameController(sparse, rs, cs).
            ctrlD:Start().
            ctrlS:Start().
            cd:Advance(5000).
            cs:Advance(5000).
            Assert:Equals(20, dense:Generation).
            Assert:Equals(dense:Generation, sparse:Generation).
            Assert:Equals(rd:LastOutput, rs:LastOutput).
            Assert:Equals(rd:RenderCount, rs:RenderCount).
            FINALLY:
                IF VALID-OBJECT(ctrlS) THEN ctrlS:Dispose().
                IF VALID-OBJECT(ctrlD) THEN ctrlD:Dispose().
                IF VALID-OBJECT(sparse) THEN sparse:Dispose().
                IF VALID-OBJECT(dense) THEN dense:Dispose().
            END FINALLY.
        END.
    END METHOD.

END CLASS.
