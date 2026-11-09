/* The club's money: the gate a match brings in, the weekly bills, and the bank. The bank lends up to 250000 times the division's number; going over that after a week's bills ends the game. Cash that goes below nothing in a week's bills turns into loan. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.Bank FINAL:

    /* The most the bank will let the loan be. */
    METHOD PUBLIC STATIC INTEGER LoanLimit(INPUT poWorld AS FootballWorld):
        RETURN FootballRules:LoanUnit() * poWorld:Multiplier.
    END METHOD.

    /* True when the loan is over the limit (the manager is sacked). */
    METHOD PUBLIC STATIC LOGICAL OverLimit(INPUT poWorld AS FootballWorld):
        RETURN poWorld:Loan > LoanLimit(poWorld).
    END METHOD.

    /* The wage bill for a week: 100 for each point of skill of every player the club owns (reserves and injured too), times the division's number. */
    METHOD PUBLIC STATIC INTEGER Wages(INPUT poWorld AS FootballWorld):
        VAR INTEGER i.
        VAR INTEGER total.
        DO i = 1 TO FootballRules:PoolSize():
            IF poWorld:RoleOf(i) <> SquadRole:NotOwned THEN total = total + poWorld:SkillOf(i) * FootballRules:WageUnit() * poWorld:Multiplier.
        END.
        RETURN total.
    END METHOD.

    /* A week's interest: a hundredth of the loan, whole pounds. */
    METHOD PUBLIC STATIC INTEGER Interest(INPUT poWorld AS FootballWorld):
        RETURN INTEGER(TRUNCATE(poWorld:Loan / FootballRules:InterestDivisor(), 0)).
    END METHOD.

    /* Pays a week's bills: wages, ground rent and interest come out of the cash, and what that leaves below nothing becomes loan. Returns the week's balance, the change in cash minus loan since the last report (usually negative). */
    METHOD PUBLIC STATIC INTEGER PayWeek(INPUT poWorld AS FootballWorld):
        VAR INTEGER balance.
        poWorld:Cash = poWorld:Cash - Wages(poWorld) - poWorld:Rent - Interest(poWorld).
        balance = poWorld:Cash - poWorld:Loan - poWorld:LastBalance.
        poWorld:LastBalance = poWorld:Cash - poWorld:Loan.
        IF poWorld:Cash < 0 THEN
        DO:
            poWorld:Loan = poWorld:Loan - poWorld:Cash.
            poWorld:Cash = 0.
        END.
        RETURN balance.
    END METHOD.

    /* Takes a loan of piAmount, which both adds to the cash and the loan. Returns false (and changes nothing) if that would put the loan over the limit. Throws GridException for an amount under 0. */
    METHOD PUBLIC STATIC LOGICAL Borrow(INPUT poWorld AS FootballWorld, INPUT piAmount AS INTEGER):
        IF piAmount = ? OR piAmount < 0 THEN UNDO, THROW NEW GridException("A loan cannot be " + STRING(piAmount)).
        IF poWorld:Loan + piAmount > LoanLimit(poWorld) THEN RETURN FALSE.
        poWorld:Cash = poWorld:Cash + piAmount.
        poWorld:Loan = poWorld:Loan + piAmount.
        RETURN TRUE.
    END METHOD.

    /* Pays off piAmount of the loan from the cash. Returns false (and changes nothing) if it is more than the loan or more than the cash. Throws GridException for an amount under 0. */
    METHOD PUBLIC STATIC LOGICAL Repay(INPUT poWorld AS FootballWorld, INPUT piAmount AS INTEGER):
        IF piAmount = ? OR piAmount < 0 THEN UNDO, THROW NEW GridException("A repayment cannot be " + STRING(piAmount)).
        IF piAmount > poWorld:Loan OR piAmount > poWorld:Cash THEN RETURN FALSE.
        poWorld:Cash = poWorld:Cash - piAmount.
        poWorld:Loan = poWorld:Loan - piAmount.
        RETURN TRUE.
    END METHOD.

    /* What a match brings in, for a match of poKind that the manager plays at home or away against the club in slot piOpponent.
       League: at home the home gate; away 500 for each place the other club is from the bottom of the table plus one (17 less its place), times the division's number (a club with no place yet counts as place 0).
       Cup: at home the home gate, away 10000 for each division the other club is below the fifth (a first division club pays 40000), but the semi-final (round 7) pays 50000 and the final (round 8) 100000 whichever side. */
    METHOD PUBLIC STATIC INTEGER GateFor(INPUT poWorld AS FootballWorld, INPUT poKind AS FixtureKind, INPUT plHome AS LOGICAL, INPUT piOpponent AS INTEGER):
        VAR INTEGER division.
        division = INTEGER(TRUNCATE((piOpponent - 1) / 16, 0)) + 1.
        CASE poKind:
            WHEN FixtureKind:League THEN
            DO:
                IF plHome THEN RETURN poWorld:Gate.
                RETURN (17 - poWorld:PlaceOf(piOpponent - poWorld:DivisionBase)) * poWorld:Multiplier * FootballRules:AwayGateUnit().
            END.
            OTHERWISE
            DO:
                IF poWorld:CupRound = FootballRules:CupRounds() THEN RETURN FootballRules:FinalGate().
                IF poWorld:CupRound = FootballRules:CupRounds() - 1 THEN RETURN FootballRules:SemiFinalGate().
                IF plHome THEN RETURN poWorld:Gate.
                RETURN (5 - division) * FootballRules:CupAwayUnit().
            END.
        END CASE.
    END METHOD.

END CLASS.
