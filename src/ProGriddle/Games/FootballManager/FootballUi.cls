/* What the manager is doing with the screens, apart from the game itself: the choices of the set up (name, club, level, kit), where the
   cursor is on each list, the digits typed for a loan, a repayment or a bid, and a word of news. FootballInput changes it and the painter
   reads it. Mode is the screen being shown. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballUi FINAL:

    DEFINE PUBLIC PROPERTY Mode AS FootballMode NO-UNDO
        GET.
        SET.

    /* The manager's name as typed, up to 20 characters. */
    DEFINE PUBLIC PROPERTY ManagerName AS CHARACTER NO-UNDO
        GET.
        SET.

    /* The level 1 to 7 at the set up (where the cursor is). */
    DEFINE PUBLIC PROPERTY Level AS INTEGER NO-UNDO
        GET.
        SET.

    /* The club list: the division on show (1 to 4) and the cursor on its 16 clubs (0 to 15). */
    DEFINE PUBLIC PROPERTY ClubDivision AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY ClubCursor AS INTEGER NO-UNDO
        GET.
        SET.

    /* The kit chosen: 0 black or 7 white. */
    DEFINE PUBLIC PROPERTY Kit AS INTEGER NO-UNDO
        GET.
        SET.

    /* The cursor on the menu (0 to 5) and on a list of players (a player of the pool, 1 to 24). */
    DEFINE PUBLIC PROPERTY MenuCursor AS INTEGER NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY PlayerCursor AS INTEGER NO-UNDO
        GET.
        SET.

    /* The cursor on the level list of the menu (1 to 7). */
    DEFINE PUBLIC PROPERTY LevelCursor AS INTEGER NO-UNDO
        GET.
        SET.

    /* The digits typed for a loan, a repayment or a bid. */
    DEFINE PUBLIC PROPERTY Digits AS CHARACTER NO-UNDO
        GET.
        SET.

    /* A word of news about the last thing done ("The bank refuses"), shown until the next key. */
    DEFINE PUBLIC PROPERTY News AS CHARACTER NO-UNDO
        GET.
        SET.

    CONSTRUCTOR PUBLIC FootballUi():
        Mode = FootballMode:Name.
        ManagerName = "".
        Level = 3.
        ClubDivision = 4.
        Kit = 0.
        Digits = "".
        News = "".
        PlayerCursor = 1.
        LevelCursor = 3.
    END CONSTRUCTOR.

    /* Makes the screen follow the game's phase, except at the set up and the menu, where the manager's own choices decide it (a game that was started
       again from the window goes back to the name screen). */
    METHOD PUBLIC VOID Settle(INPUT poPhase AS FootballPhase):
        CASE poPhase:
            WHEN FootballPhase:Setup THEN
                IF Mode <> FootballMode:Name AND Mode <> FootballMode:Club AND Mode <> FootballMode:Kit THEN Mode = FootballMode:Name.
            WHEN FootballPhase:Menu THEN
                IF Mode <> FootballMode:Main AND Mode <> FootballMode:Squad AND Mode <> FootballMode:Status
                   AND Mode <> FootballMode:Loan AND Mode <> FootballMode:Repay AND Mode <> FootballMode:Levels THEN Mode = FootballMode:Main.
            WHEN FootballPhase:Selling THEN Mode = FootballMode:Selling.
            WHEN FootballPhase:PickTeam THEN Mode = FootballMode:PickTeam.
            WHEN FootballPhase:Match THEN Mode = FootballMode:Match.
            WHEN FootballPhase:FullTime THEN Mode = FootballMode:FullTime.
            WHEN FootballPhase:Results THEN Mode = FootballMode:Results.
            WHEN FootballPhase:Table THEN Mode = FootballMode:Table.
            WHEN FootballPhase:Accounts THEN Mode = FootballMode:Accounts.
            WHEN FootballPhase:SeasonEnd THEN Mode = FootballMode:SeasonEnd.
            WHEN FootballPhase:Transfer THEN Mode = FootballMode:Transfer.
            OTHERWISE Mode = FootballMode:Sacked.
        END CASE.
    END METHOD.

    /* The amount typed so far as a number (0 when nothing is). */
    METHOD PUBLIC INTEGER Amount():
        IF Digits = "" THEN RETURN 0.
        RETURN INTEGER(Digits).
    END METHOD.

    /* The slot of the club under the cursor on the club list. */
    METHOD PUBLIC INTEGER ClubSlot():
        RETURN (ClubDivision - 1) * 16 + ClubCursor + 1.
    END METHOD.

END CLASS.
