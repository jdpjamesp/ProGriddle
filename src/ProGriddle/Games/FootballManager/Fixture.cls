/* A match that is about to be played, or has been: its kind (league or cup), the club the manager meets, which side of the pairing the manager's club is (1 is the home side, 2 the away side), what the gate will bring in, and the opposition's five numbers (energy, morale, defence, midfield, attack). MatchDay makes and plays these. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.Fixture FINAL:

    VAR PRIVATE INTEGER[5] mOpposition.

    DEFINE PUBLIC PROPERTY Kind AS FixtureKind NO-UNDO
        GET.
        SET.

    /* The slot of the club the manager meets. */
    DEFINE PUBLIC PROPERTY OpponentSlot AS INTEGER NO-UNDO
        GET.
        SET.

    /* 1 when the manager's club is the home side, 2 when it is the away side. */
    DEFINE PUBLIC PROPERTY ManagerSide AS INTEGER NO-UNDO
        GET.
        SET.

    /* What the match's gate brings in. */
    DEFINE PUBLIC PROPERTY Gate AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY ManagerIsHome AS LOGICAL NO-UNDO
        GET():
            RETURN ManagerSide = 1.
        END GET.

    METHOD PRIVATE VOID CheckNumber(INPUT piWhich AS INTEGER):
        IF piWhich = ? OR piWhich < 1 OR piWhich > 5 THEN UNDO, THROW NEW GridException("There is no team number " + STRING(piWhich)).
    END METHOD.

    /* One of the opposition's five numbers (1 energy, 2 morale, 3 defence, 4 midfield, 5 attack). */
    METHOD PUBLIC INTEGER OppositionNumber(INPUT piWhich AS INTEGER):
        CheckNumber(piWhich).
        RETURN mOpposition[piWhich].
    END METHOD.

    METHOD PUBLIC VOID SetOppositionNumber(INPUT piWhich AS INTEGER, INPUT piValue AS INTEGER):
        CheckNumber(piWhich).
        mOpposition[piWhich] = piValue.
    END METHOD.

END CLASS.
