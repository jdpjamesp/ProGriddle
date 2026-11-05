/* The message log: what is said in a turn becomes one line, and everything said is kept in a history. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.MessageLogTests:

    DEFINE PRIVATE VARIABLE mLog AS MessageLog NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildLog():
        mLog = NEW MessageLog().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewLogIsEmpty():
        Assert:Equals(0, mLog:Count).
        Assert:Equals(0, mLog:TurnCount).
        Assert:Equals("", mLog:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMessageIsOnTheLineAndInTheHistory():
        mLog:Add("You hit the bat.").
        Assert:Equals(1, mLog:Count).
        Assert:Equals(1, mLog:TurnCount).
        Assert:Equals("You hit the bat.", mLog:Line(80)).
        Assert:Equals("You hit the bat.", mLog:At(0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID MessagesOfATurnAreJoinedWithTwoSpaces():
        mLog:Add("You hit the bat.").
        mLog:Add("The bat misses.").
        Assert:Equals("You hit the bat.  The bat misses.", mLog:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheLineIsTooLongTheOldestMessagesAreLeftOff():
        mLog:Add("one one one one").
        mLog:Add("two two two two").
        mLog:Add("three three three").
        Assert:Equals("two two two two  three three three", mLog:Line(40)).
        Assert:Equals("three three three", mLog:Line(25)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALoneMessageThatIsTooLongIsCut():
        mLog:Add("abcdefghijklmnopqrstuvwxyz").
        Assert:Equals("abcdefghij", mLog:Line(10)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewTurnEmptiesTheLineButKeepsTheHistory():
        mLog:Add("First.").
        mLog:BeginTurn().
        Assert:Equals("", mLog:Line(80)).
        Assert:Equals(0, mLog:TurnCount).
        Assert:Equals(1, mLog:Count).
        mLog:Add("Second.").
        Assert:Equals("Second.", mLog:Line(80)).
        Assert:Equals("Second.", mLog:At(0)).
        Assert:Equals("First.", mLog:At(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EmptyMessagesAreIgnored():
        mLog:Add("").
        mLog:Add(?).
        Assert:Equals(0, mLog:Count).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHistoryKeepsTheLastHundredNewestFirst():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 130:
            mLog:BeginTurn().
            mLog:Add("m" + STRING(i)).
        END.
        Assert:Equals(100, mLog:Count).
        Assert:Equals("m130", mLog:At(0)).
        Assert:Equals("m129", mLog:At(1)).
        Assert:Equals("m31", mLog:At(99)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AVeryBusyTurnKeepsTheNewestTwentyMessages():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 25:
            mLog:Add("x" + STRING(i)).
        END.
        Assert:Equals(20, mLog:TurnCount).
        Assert:Equals(25, mLog:Count).
        Assert:IsTrue(INDEX(mLog:Line(500), "x25") > 0).
        Assert:Equals(0, INDEX(mLog:Line(500), "x1 ")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ClearForgetsEverything():
        mLog:Add("Something.").
        mLog:Clear().
        Assert:Equals(0, mLog:Count).
        Assert:Equals("", mLog:Line(80)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlaceBeyondTheHistoryIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        mLog:Add("One.").
        DO ON ERROR UNDO, THROW:
            mLog:At(1).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mLog:At(-1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
