/* What a Football Manager window can do. All play is on the keyboard, and what the keys mean depends on the screen (FootballUi:Mode):

     Name        type the manager's name (letters, digits and space, Backspace rubs out), Up and Down choose the level, Enter goes on
     Club        arrows move, Page Up and Page Down (or Tab) change the division, Enter picks the club, Esc goes back
     Kit         Left and Right choose white or black, Enter starts the game, Esc goes back
     Main        Up and Down and Enter, or C continue, A squad and sales, L loan, P repay, S status, V level
     Squad       Up and Down choose a player, Enter puts him up for sale, Esc goes back
     Loan, Repay type the amount, Enter asks the bank, Esc goes back
     Levels      Up and Down choose, Enter sets, Esc goes back
     Selling     Y accepts the offer, N or Esc turns it down
     PickTeam    Up and Down choose a player, Space or Enter picks him or takes him out, K kicks off
     Match       Space or Enter skips the highlights, and once they are over goes on
     FullTime, Results, Table, Accounts, SeasonEnd    Space or Enter goes on
     Transfer    type a bid, Enter makes it, P or Esc lets him go
     Sacked      Enter starts again

   P pauses the highlights in the window's own way (the window's keys), and R or F2 starts a new game. The game's own words ("The bank
   refuses") are kept in FootballUi:News and drawn by the painter, so BannerText and TakeNotice stay empty. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballInput FINAL IMPLEMENTS IGameInput:

    VAR PRIVATE FootballGame mGame.
    VAR PRIVATE FootballUi mUi.

    DEFINE PUBLIC PROPERTY Ui AS FootballUi NO-UNDO
        GET():
            RETURN mUi.
        END GET.

    DEFINE PUBLIC PROPERTY StatusText AS CHARACTER NO-UNDO
        GET():
            IF mGame:Phase = FootballPhase:Setup THEN RETURN "Football Manager   Set up".
            RETURN SUBSTITUTE("&1   Division &2   Week &3   Cash &4   Loan &5", mGame:World:ClubName(mGame:World:Slot), mGame:World:Division,
                              mGame:Turn, mGame:World:Cash, mGame:World:Loan).
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY ChoiceNames AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY Choice AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.
        SET(INPUT pcValue AS CHARACTER):
        END SET.

    DEFINE PUBLIC PROPERTY CommandNames AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY BannerText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoLabel AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    DEFINE PUBLIC PROPERTY InfoText AS CHARACTER NO-UNDO
        GET():
            RETURN "".
        END GET.

    /* Throws GridException for no game. */
    CONSTRUCTOR PUBLIC FootballInput(INPUT poGame AS FootballGame):
        THIS-OBJECT(poGame, NEW FootballUi()).
    END CONSTRUCTOR.

    /* An input that keeps its screen state in poUi, which the painter reads. Throws GridException for no game or no screen state. */
    CONSTRUCTOR PUBLIC FootballInput(INPUT poGame AS FootballGame, INPUT poUi AS FootballUi):
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("Football Manager input needs a game").
        IF NOT VALID-OBJECT(poUi) THEN UNDO, THROW NEW GridException("Football Manager input needs the screen state").
        mGame = poGame.
        mUi = poUi.
        Sync().
    END CONSTRUCTOR.

    METHOD PUBLIC CHARACTER TakeNotice():
        RETURN "".
    END METHOD.

    /* The screen follows the game's phase, except at the set up and the menu, where the manager's own choices decide it. */
    METHOD PRIVATE VOID Sync():
        mUi:Settle(mGame:Phase).
    END METHOD.

    /* The character a key types: a letter, a digit or a space, or "" for any other key. */
    METHOD PRIVATE CHARACTER Typed(INPUT pcKey AS CHARACTER):
        IF LENGTH(pcKey) = 1 AND INDEX("ABCDEFGHIJKLMNOPQRSTUVWXYZ", pcKey) > 0 THEN RETURN pcKey.
        IF LENGTH(pcKey) = 2 AND SUBSTRING(pcKey, 1, 1) = "D" AND INDEX("0123456789", SUBSTRING(pcKey, 2, 1)) > 0 THEN RETURN SUBSTRING(pcKey, 2, 1).
        IF LENGTH(pcKey) = 7 AND SUBSTRING(pcKey, 1, 6) = "NumPad" AND INDEX("0123456789", SUBSTRING(pcKey, 7, 1)) > 0 THEN RETURN SUBSTRING(pcKey, 7, 1).
        IF pcKey = "Space" THEN RETURN " ".
        RETURN "".
    END METHOD.

    /* The digit a key types, or "" . */
    METHOD PRIVATE CHARACTER Digit(INPUT pcKey AS CHARACTER):
        VAR CHARACTER c.
        c = Typed(pcKey).
        IF c <> "" AND INDEX("0123456789", c) > 0 THEN RETURN c.
        RETURN "".
    END METHOD.

    /* Moves a player cursor to the next (piStep 1) or previous (-1) player the club owns. */
    METHOD PRIVATE VOID MovePlayer(INPUT piStep AS INTEGER):
        VAR INTEGER p.
        VAR INTEGER n.
        p = mUi:PlayerCursor.
        DO n = 1 TO 24:
            p = p + piStep.
            IF p > 24 THEN p = 1.
            IF p < 1 THEN p = 24.
            IF mGame:World:RoleOf(p) <> SquadRole:NotOwned THEN
            DO:
                mUi:PlayerCursor = p.
                RETURN.
            END.
        END.
    END METHOD.

    /* Puts the cursor on a player the club owns (the first, if it is not on one). */
    METHOD PRIVATE VOID FixPlayer():
        IF mGame:World:RoleOf(mUi:PlayerCursor) = SquadRole:NotOwned THEN
        DO:
            mUi:PlayerCursor = 24.
            MovePlayer(1).
        END.
    END METHOD.

    /* Types a digit into a loan, repayment or bid (up to 7), or rubs one out. */
    METHOD PRIVATE LOGICAL EditDigits(INPUT pcKey AS CHARACTER):
        VAR CHARACTER d = Digit(pcKey).
        IF d <> "" THEN
        DO:
            IF LENGTH(mUi:Digits) < 7 THEN mUi:Digits = mUi:Digits + d.
            RETURN TRUE.
        END.
        IF pcKey = "Back" THEN
        DO:
            IF LENGTH(mUi:Digits) > 0 THEN mUi:Digits = SUBSTRING(mUi:Digits, 1, LENGTH(mUi:Digits) - 1).
            RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* A key went down. Returns true for the keys of the game, which the window then leaves alone. */
    METHOD PUBLIC LOGICAL HandleKey(INPUT pcKey AS CHARACTER):
        VAR LOGICAL used = TRUE.
        IF pcKey = ? THEN RETURN FALSE.
        mUi:News = "".
        Sync().
        CASE mUi:Mode:
            WHEN FootballMode:Name THEN used = KeysName(pcKey).
            WHEN FootballMode:Club THEN used = KeysClub(pcKey).
            WHEN FootballMode:Kit THEN used = KeysKit(pcKey).
            WHEN FootballMode:Main THEN used = KeysMain(pcKey).
            WHEN FootballMode:Squad THEN used = KeysSquad(pcKey).
            WHEN FootballMode:Status THEN mUi:Mode = FootballMode:Main.
            WHEN FootballMode:Loan OR WHEN FootballMode:Repay THEN used = KeysMoney(pcKey).
            WHEN FootballMode:Levels THEN used = KeysLevels(pcKey).
            WHEN FootballMode:Selling THEN used = KeysSelling(pcKey).
            WHEN FootballMode:PickTeam THEN used = KeysPick(pcKey).
            WHEN FootballMode:Transfer THEN used = KeysTransfer(pcKey).
            WHEN FootballMode:Match THEN used = KeysMatch(pcKey).
            WHEN FootballMode:Sacked THEN
            DO:
                used = pcKey = "Return".
                IF used THEN
                DO:
                    mGame:Initialise().
                    mUi:Mode = FootballMode:Name.
                END.
            END.
            OTHERWISE
            DO:
                used = pcKey = "Return" OR pcKey = "Space".
                IF used THEN mGame:Proceed().
            END.
        END CASE.
        /* only the match has anything to pause: on any other screen a P that reached the window would stop the clock, and the next match would start frozen */
        IF pcKey = "P" AND mUi:Mode <> FootballMode:Match THEN used = TRUE.
        Sync().
        RETURN used.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysName(INPUT pcKey AS CHARACTER):
        VAR CHARACTER c = Typed(pcKey).
        /* a space is "" to a comparison, so the length is what says a key typed something */
        IF LENGTH(c) > 0 THEN
        DO:
            IF LENGTH(mUi:ManagerName) < 20 THEN mUi:ManagerName = mUi:ManagerName + c.
            RETURN TRUE.
        END.
        CASE pcKey:
            WHEN "Back" THEN
            DO:
                IF LENGTH(mUi:ManagerName) > 0 THEN mUi:ManagerName = SUBSTRING(mUi:ManagerName, 1, LENGTH(mUi:ManagerName) - 1).
            END.
            WHEN "Up" THEN mUi:Level = MAXIMUM(1, mUi:Level - 1).
            WHEN "Down" THEN mUi:Level = MINIMUM(7, mUi:Level + 1).
            WHEN "Return" THEN
            DO:
                IF LENGTH(TRIM(mUi:ManagerName)) = 0 THEN mUi:News = "TYPE YOUR NAME".
                ELSE mUi:Mode = FootballMode:Club.
            END.
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysClub(INPUT pcKey AS CHARACTER):
        CASE pcKey:
            WHEN "Up" THEN mUi:ClubCursor = (mUi:ClubCursor + 15) MODULO 16.
            WHEN "Down" THEN mUi:ClubCursor = (mUi:ClubCursor + 1) MODULO 16.
            WHEN "Left" OR WHEN "Right" THEN mUi:ClubCursor = (mUi:ClubCursor + 8) MODULO 16.
            WHEN "PageUp" THEN mUi:ClubDivision = (IF mUi:ClubDivision = 1 THEN 4 ELSE mUi:ClubDivision - 1).
            WHEN "PageDown" OR WHEN "Tab" THEN mUi:ClubDivision = (IF mUi:ClubDivision = 4 THEN 1 ELSE mUi:ClubDivision + 1).
            WHEN "Return" THEN mUi:Mode = FootballMode:Kit.
            WHEN "Escape" THEN mUi:Mode = FootballMode:Name.
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysKit(INPUT pcKey AS CHARACTER):
        CASE pcKey:
            WHEN "Left" THEN mUi:Kit = 7.
            WHEN "Right" THEN mUi:Kit = 0.
            WHEN "Return" THEN
            DO:
                mGame:StartNewGame(TRIM(mUi:ManagerName), mUi:ClubSlot(), mUi:Level, mUi:Kit).
                mUi:Mode = FootballMode:Main.
            END.
            WHEN "Escape" THEN mUi:Mode = FootballMode:Club.
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    /* What a choice on the menu does: 0 continue, 1 squad and sales, 2 loan, 3 repay, 4 status, 5 level. */
    METHOD PRIVATE VOID Choose(INPUT piItem AS INTEGER):
        CASE piItem:
            WHEN 0 THEN
            DO:
                mGame:Continue().
                FixPlayer().
            END.
            WHEN 1 THEN
            DO:
                FixPlayer().
                mUi:Mode = FootballMode:Squad.
            END.
            WHEN 2 THEN
            DO:
                mUi:Digits = "".
                mUi:Mode = FootballMode:Loan.
            END.
            WHEN 3 THEN
            DO:
                mUi:Digits = "".
                mUi:Mode = FootballMode:Repay.
            END.
            WHEN 4 THEN mUi:Mode = FootballMode:Status.
            OTHERWISE
            DO:
                mUi:LevelCursor = mGame:World:Level.
                mUi:Mode = FootballMode:Levels.
            END.
        END CASE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysMain(INPUT pcKey AS CHARACTER):
        CASE pcKey:
            WHEN "Up" THEN mUi:MenuCursor = (mUi:MenuCursor + 5) MODULO 6.
            WHEN "Down" THEN mUi:MenuCursor = (mUi:MenuCursor + 1) MODULO 6.
            WHEN "Return" THEN Choose(mUi:MenuCursor).
            WHEN "C" THEN Choose(0).
            WHEN "A" THEN Choose(1).
            WHEN "L" THEN Choose(2).
            WHEN "P" THEN Choose(3).
            WHEN "S" THEN Choose(4).
            WHEN "V" THEN Choose(5).
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysSquad(INPUT pcKey AS CHARACTER):
        CASE pcKey:
            WHEN "Up" THEN MovePlayer(-1).
            WHEN "Down" THEN MovePlayer(1).
            WHEN "Return" THEN
            DO:
                IF Market:CanSell(mGame:World, mUi:PlayerCursor) THEN mGame:OfferSale(mUi:PlayerCursor).
                ELSE mUi:News = "HE IS INJURED - NOBODY WANTS HIM".
            END.
            WHEN "Escape" THEN mUi:Mode = FootballMode:Main.
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysMoney(INPUT pcKey AS CHARACTER):
        VAR LOGICAL ok.
        IF EditDigits(pcKey) THEN RETURN TRUE.
        CASE pcKey:
            WHEN "Return" THEN
            DO:
                IF mUi:Mode = FootballMode:Loan THEN
                DO:
                    ok = mGame:Borrow(mUi:Amount()).
                    mUi:News = (IF ok THEN "THE BANK LENDS YOU THE MONEY" ELSE "THE BANK REFUSES: THAT IS OVER YOUR LIMIT").
                END.
                ELSE
                DO:
                    ok = mGame:Repay(mUi:Amount()).
                    mUi:News = (IF ok THEN "LOAN PAID OFF" ELSE "YOU CANNOT PAY THAT: IT IS MORE THAN THE LOAN OR YOUR CASH").
                END.
                IF ok THEN mUi:Mode = FootballMode:Main.
                mUi:Digits = "".
            END.
            WHEN "Escape" THEN mUi:Mode = FootballMode:Main.
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysLevels(INPUT pcKey AS CHARACTER):
        CASE pcKey:
            WHEN "Up" THEN mUi:LevelCursor = MAXIMUM(1, mUi:LevelCursor - 1).
            WHEN "Down" THEN mUi:LevelCursor = MINIMUM(7, mUi:LevelCursor + 1).
            WHEN "Return" THEN
            DO:
                mGame:SetLevel(mUi:LevelCursor).
                mUi:Mode = FootballMode:Main.
            END.
            WHEN "Escape" THEN mUi:Mode = FootballMode:Main.
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysSelling(INPUT pcKey AS CHARACTER):
        CASE pcKey:
            WHEN "Y" THEN
            DO:
                mGame:AcceptSale().
                mUi:News = "SOLD".
                mUi:Mode = FootballMode:Squad.
                FixPlayer().
            END.
            WHEN "N" OR WHEN "Escape" THEN
            DO:
                IF mGame:TurnDownSale() THEN mUi:News = "HE IS ANGRY AND HAS INJURED HIMSELF".
                mUi:Mode = FootballMode:Squad.
                FixPlayer().
            END.
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysPick(INPUT pcKey AS CHARACTER):
        FixPlayer().
        CASE pcKey:
            WHEN "Up" THEN MovePlayer(-1).
            WHEN "Down" THEN MovePlayer(1).
            WHEN "Space" OR WHEN "Return" THEN
            DO:
                CASE mGame:World:RoleOf(mUi:PlayerCursor):
                    WHEN SquadRole:Starter THEN mGame:DropPlayer(mUi:PlayerCursor).
                    WHEN SquadRole:Reserve THEN
                    DO:
                        IF mGame:World:StarterCount() >= FootballRules:TeamSize() THEN mUi:News = "ELEVEN ARE PICKED ALREADY: TAKE ONE OUT FIRST".
                        ELSE mGame:PickPlayer(mUi:PlayerCursor).
                    END.
                    OTHERWISE mUi:News = "HE IS INJURED".
                END CASE.
            END.
            WHEN "K" THEN mGame:KickOff().
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysTransfer(INPUT pcKey AS CHARACTER):
        VAR BidResult answer.
        IF NOT mGame:TransferBlocked AND EditDigits(pcKey) THEN RETURN TRUE.
        CASE pcKey:
            WHEN "Return" THEN
            DO:
                IF mGame:TransferBlocked THEN mGame:Pass().
                ELSE
                DO:
                    answer = mGame:Bid(mUi:Amount()).
                    CASE answer:
                        WHEN BidResult:Accepted THEN mUi:News = "HE HAS JOINED YOUR TEAM".
                        WHEN BidResult:Refused THEN mUi:News = "REFUSED: THEY WANT MORE NOW".
                        WHEN BidResult:NoMoney THEN mUi:News = "YOU HAVEN'T ENOUGH MONEY".
                        OTHERWISE mUi:News = "YOUR SQUAD IS FULL".
                    END CASE.
                    mUi:Digits = "".
                END.
            END.
            WHEN "Escape" OR WHEN "P" THEN mGame:Pass().
            OTHERWISE RETURN FALSE.
        END CASE.
        RETURN TRUE.
    END METHOD.

    METHOD PRIVATE LOGICAL KeysMatch(INPUT pcKey AS CHARACTER):
        IF pcKey <> "Space" AND pcKey <> "Return" THEN RETURN FALSE.
        IF mGame:HighlightsOver() THEN mGame:Proceed().
        ELSE mGame:SkipHighlights().
        RETURN TRUE.
    END METHOD.

    METHOD PUBLIC VOID ReleaseKey(INPUT pcKey AS CHARACTER):
    END METHOD.

    METHOD PUBLIC VOID Perform(INPUT pcCommand AS CHARACTER):
        UNDO, THROW NEW GridException("Unknown Football Manager command: " + STRING(pcCommand)).
    END METHOD.

    METHOD PUBLIC VOID PrimaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID SecondaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

    METHOD PUBLIC VOID TertiaryAction(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
    END METHOD.

END CLASS.
