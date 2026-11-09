/* The club's money: the wage bill, interest, a week's bills turning cash into loan, borrowing and repaying within the bank's limit, and what each kind of match brings in. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.BankTests:

    VAR PRIVATE FootballWorld mWorld.

    /* A fourth division club with twelve players of skill 1, rent 500, a home gate of 5000 and no money. */
    @Setup.
    METHOD PUBLIC VOID BuildWorld():
        mWorld = NEW FootballWorld().
        mWorld:NewGame("Bob", 1, 1, 0, NEW ScriptedRandom("0")).
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "borrow" THEN Bank:Borrow(mWorld, -1).
                WHEN "repay" THEN Bank:Repay(mWorld, -1).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWageBillIsOneHundredAPointOfSkillForEveryPlayerOwnedTimesTheDivision():
        Assert:Equals(1200, Bank:Wages(mWorld)).
        mWorld:SetSkill(1, 5).
        Assert:Equals(1600, Bank:Wages(mWorld)).
        mWorld:SetRole(12, SquadRole:Injured).
        Assert:Equals(1600, Bank:Wages(mWorld)).
        mWorld:SetRole(12, SquadRole:NotOwned).
        Assert:Equals(1500, Bank:Wages(mWorld)).
        mWorld:Slot = 40.
        Assert:Equals(3000, Bank:Wages(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InterestIsAHundredthOfTheLoanInWholePounds():
        mWorld:Loan = 12345.
        Assert:Equals(123, Bank:Interest(mWorld)).
        mWorld:Loan = 99.
        Assert:Equals(0, Bank:Interest(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBankLendsTwoHundredAndFiftyThousandTimesTheDivision():
        Assert:Equals(250000, Bank:LoanLimit(mWorld)).
        mWorld:Slot = 3.
        Assert:Equals(1000000, Bank:LoanLimit(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALoanOverTheLimitIsOverTheLimitAndOneAtItIsNot():
        mWorld:Loan = 250000.
        Assert:IsFalse(Bank:OverLimit(mWorld)).
        mWorld:Loan = 250001.
        Assert:IsTrue(Bank:OverLimit(mWorld)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWeeksBillsComeOutOfTheCashAndTheBalanceIsTheChangeSinceTheLastReport():
        VAR INTEGER balance.
        mWorld:Cash = 5000.
        balance = Bank:PayWeek(mWorld).
        /* wages 1200 and rent 500 */
        Assert:Equals(3300, mWorld:Cash).
        Assert:Equals(3300, balance).
        Assert:Equals(3300, mWorld:LastBalance).
        balance = Bank:PayWeek(mWorld).
        Assert:Equals(1600, mWorld:Cash).
        Assert:Equals(-1700, balance).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InterestIsPaidWithTheBills():
        mWorld:Cash = 5000.
        mWorld:Loan = 10000.
        Bank:PayWeek(mWorld).
        /* wages 1200, rent 500, interest 100 */
        Assert:Equals(3200, mWorld:Cash).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CashThatGoesBelowNothingBecomesLoan():
        VAR INTEGER balance.
        mWorld:Cash = 1000.
        balance = Bank:PayWeek(mWorld).
        Assert:Equals(-700, balance).
        Assert:Equals(0, mWorld:Cash).
        Assert:Equals(700, mWorld:Loan).
        Assert:Equals(-700, mWorld:LastBalance).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BorrowingAddsToTheCashAndTheLoanUpToTheLimit():
        Assert:IsTrue(Bank:Borrow(mWorld, 200000)).
        Assert:Equals(200000, mWorld:Cash).
        Assert:Equals(200000, mWorld:Loan).
        Assert:IsFalse(Bank:Borrow(mWorld, 50001)).
        Assert:Equals(200000, mWorld:Loan).
        Assert:IsTrue(Bank:Borrow(mWorld, 50000)).
        Assert:Equals(250000, mWorld:Loan).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RepayingTakesFromTheCashAndTheLoanButNotMoreThanEither():
        mWorld:Cash = 500.
        mWorld:Loan = 1000.
        Assert:IsFalse(Bank:Repay(mWorld, 600)).
        Assert:Equals(500, mWorld:Cash).
        Assert:IsTrue(Bank:Repay(mWorld, 500)).
        Assert:Equals(0, mWorld:Cash).
        Assert:Equals(500, mWorld:Loan).
        mWorld:Cash = 5000.
        Assert:IsFalse(Bank:Repay(mWorld, 501)).
        Assert:Equals(5000, mWorld:Cash).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANegativeLoanOrRepaymentIsRefused():
        Assert:IsTrue(Refused("borrow")).
        Assert:IsTrue(Refused("repay")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALeagueMatchAtHomeBringsInTheHomeGate():
        mWorld:Gate = 6500.
        Assert:Equals(6500, Bank:GateFor(mWorld, FixtureKind:League, TRUE, 49)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALeagueMatchAwayPaysFiveHundredAPlaceBelowSeventeenTimesTheDivision():
        /* before the first table every club is in place 0: 17 * 500 */
        Assert:Equals(8500, Bank:GateFor(mWorld, FixtureKind:League, FALSE, 49)).
        mWorld:SetPlace(1, 3).
        Assert:Equals(7000, Bank:GateFor(mWorld, FixtureKind:League, FALSE, 49)).
        mWorld:Slot = 40.
        mWorld:SetPlace(2, 1).
        Assert:Equals(16000, Bank:GateFor(mWorld, FixtureKind:League, FALSE, 34)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACupTieAtHomeBringsInTheHomeGateAndAwayTenThousandADivisionBelowTheFifth():
        mWorld:CupRound = 2.
        mWorld:Gate = 6500.
        Assert:Equals(6500, Bank:GateFor(mWorld, FixtureKind:Cup, TRUE, 20)).
        Assert:Equals(40000, Bank:GateFor(mWorld, FixtureKind:Cup, FALSE, 5)).
        Assert:Equals(30000, Bank:GateFor(mWorld, FixtureKind:Cup, FALSE, 20)).
        Assert:Equals(20000, Bank:GateFor(mWorld, FixtureKind:Cup, FALSE, 40)).
        Assert:Equals(10000, Bank:GateFor(mWorld, FixtureKind:Cup, FALSE, 60)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSemiFinalAndTheFinalPayTheSameAtHomeAndAway():
        mWorld:CupRound = 7.
        Assert:Equals(50000, Bank:GateFor(mWorld, FixtureKind:Cup, TRUE, 5)).
        Assert:Equals(50000, Bank:GateFor(mWorld, FixtureKind:Cup, FALSE, 5)).
        mWorld:CupRound = 8.
        Assert:Equals(100000, Bank:GateFor(mWorld, FixtureKind:Cup, TRUE, 5)).
        Assert:Equals(100000, Bank:GateFor(mWorld, FixtureKind:Cup, FALSE, 5)).
    END METHOD.

END CLASS.
