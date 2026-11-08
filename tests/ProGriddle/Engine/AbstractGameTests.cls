USING OpenEdge.Core.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.AbstractGameTests:

    METHOD PRIVATE Grid NewGrid():
        RETURN NEW Grid(NEW ArrayStore(3, 3, "s")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ExposesItsNameGridAndStartingState():
        VAR CountingGame game.
        VAR Grid g.
        DO ON ERROR UNDO, THROW:
            g = NewGrid().
            game = NEW CountingGame(g, 0).
            Assert:Equals("counting", game:Name).
            Assert:IsTrue(game:Grid = g).
            Assert:IsFalse(game:IsOver).
            Assert:Equals(0, game:Generation).
            FINALLY:
                IF VALID-OBJECT(game) THEN game:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InitialiseResetsTheCounterAndTheOverFlagAndCallsTheHook():
        VAR CountingGame game.
        DO ON ERROR UNDO, THROW:
            game = NEW CountingGame(NewGrid(), 2).
            game:Step().
            game:Step().
            Assert:IsTrue(game:IsOver).
            Assert:Equals(2, game:Generation).
            game:Initialise().
            Assert:IsFalse(game:IsOver).
            Assert:Equals(0, game:Generation).
            Assert:Equals(1, game:InitialiseCount).
            game:Initialise().
            Assert:Equals(2, game:InitialiseCount).
            FINALLY:
                IF VALID-OBJECT(game) THEN game:Dispose().
            END FINALLY.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeDisposesTheGrid():
        VAR CountingGame game.
        VAR ArrayStore s = NEW ArrayStore(2, 2, "s").
        game = NEW CountingGame(NEW Grid(s), 0).
        game:Dispose().
        /* a second call must be harmless */
        game:Dispose().
    END METHOD.

    @Test (expected="ProGriddle.Core.GridException").
    METHOD PUBLIC VOID ConstructorThrowsWithoutAGrid():
        VAR Grid g.
        NEW CountingGame(g, 0).
    END METHOD.

END CLASS.
