/* The keyboard of Football Manager: what each key does on each screen, from the first typed letter of the name to the sack. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballInputTests:

    VAR PRIVATE FootballGame mGame.
    VAR PRIVATE FootballInput mInput.

    @Setup.
    METHOD PUBLIC VOID BuildGame():
        mGame = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(3)).
        mInput = NEW FootballInput(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* Presses a list of keys, such as "A,B,Return". */
    METHOD PRIVATE VOID Press(INPUT pcKeys AS CHARACTER):
        VAR INTEGER i.
        DO i = 1 TO NUM-ENTRIES(pcKeys):
            mInput:HandleKey(ENTRY(i, pcKeys)).
        END.
    END METHOD.

    /* A game at the menu: the manager BOB, the first club of the fourth division, level 3, white, plenty of cash. */
    METHOD PRIVATE VOID AtTheMenu():
        Press("B,O,B,Down,Down,Return,Return,Left,Return").
        mGame:World:Cash = 1000000.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "nogame" THEN NEW FootballInput(?).
                WHEN "perform" THEN mInput:Perform("Anything").
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameStartsOnTheNameScreen():
        Assert:Equals(INTEGER(FootballMode:Name), INTEGER(mInput:Ui:Mode)).
        Assert:IsTrue(mInput:StatusText BEGINS "Football Manager").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TypingBuildsTheNameAndBackspaceRubsItOut():
        Press("B,O,B,D1,Space,Z").
        Assert:Equals("BOB1 Z", mInput:Ui:ManagerName).
        Press("Back,Back").
        Assert:Equals("BOB1", mInput:Ui:ManagerName).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANameIsAtMostTwentyCharactersAndMustNotBeEmpty():
        VAR INTEGER i.
        Press("Return").
        Assert:Equals(INTEGER(FootballMode:Name), INTEGER(mInput:Ui:Mode)).
        Assert:IsTrue(mInput:Ui:News <> "").
        DO i = 1 TO 25:
            Press("X").
        END.
        Assert:Equals(20, LENGTH(mInput:Ui:ManagerName)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID UpAndDownChooseTheLevelOnTheNameScreen():
        Press("Down,Down,Down,Down,Down").
        Assert:Equals(7, mInput:Ui:Level).
        Press("Up").
        Assert:Equals(6, mInput:Ui:Level).
        Press("Up,Up,Up,Up,Up,Up,Up").
        Assert:Equals(1, mInput:Ui:Level).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClubListMovesWithArrowsAndPagesThroughTheDivisions():
        Press("A,Return").
        Assert:Equals(INTEGER(FootballMode:Club), INTEGER(mInput:Ui:Mode)).
        Assert:Equals(4, mInput:Ui:ClubDivision).
        Press("Down,Down").
        Assert:Equals(2, mInput:Ui:ClubCursor).
        Press("Right").
        Assert:Equals(10, mInput:Ui:ClubCursor).
        Press("Up,Up,Up,Up,Up,Up,Up,Up,Up,Up,Up").
        Assert:Equals(15, mInput:Ui:ClubCursor).
        Press("PageDown").
        Assert:Equals(1, mInput:Ui:ClubDivision).
        Press("PageUp,PageUp").
        Assert:Equals(3, mInput:Ui:ClubDivision).
        Press("Tab").
        Assert:Equals(4, mInput:Ui:ClubDivision).
        Assert:Equals(64, mInput:Ui:ClubSlot()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EscapeGoesBackOneStepOfTheSetUp():
        Press("A,Return,Return").
        Assert:Equals(INTEGER(FootballMode:Kit), INTEGER(mInput:Ui:Mode)).
        Press("Escape").
        Assert:Equals(INTEGER(FootballMode:Club), INTEGER(mInput:Ui:Mode)).
        Press("Escape").
        Assert:Equals(INTEGER(FootballMode:Name), INTEGER(mInput:Ui:Mode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheKitScreenChoosesWhiteOrBlackAndEnterStartsTheGame():
        Press("B,O,B,Return,Return").
        Press("Left").
        Assert:Equals(7, mInput:Ui:Kit).
        Press("Right").
        Assert:Equals(0, mInput:Ui:Kit).
        Press("Return").
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(mGame:Phase)).
        Assert:Equals(INTEGER(FootballMode:Main), INTEGER(mInput:Ui:Mode)).
        Assert:Equals("BOB", mGame:World:ManagerName).
        Assert:Equals(0, mGame:World:KitColour).
        Assert:Equals(1, mGame:World:OwnedCount() - 11).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMenuMovesAndTheHotKeysOpenItsScreens():
        AtTheMenu().
        Assert:Equals(7, mGame:World:KitColour).
        Press("Down").
        Assert:Equals(1, mInput:Ui:MenuCursor).
        Press("Up,Up").
        Assert:Equals(5, mInput:Ui:MenuCursor).
        Press("S").
        Assert:Equals(INTEGER(FootballMode:Status), INTEGER(mInput:Ui:Mode)).
        Press("X").
        Assert:Equals(INTEGER(FootballMode:Main), INTEGER(mInput:Ui:Mode)).
        Press("A").
        Assert:Equals(INTEGER(FootballMode:Squad), INTEGER(mInput:Ui:Mode)).
        Press("Escape,L").
        Assert:Equals(INTEGER(FootballMode:Loan), INTEGER(mInput:Ui:Mode)).
        Press("Escape,P").
        Assert:Equals(INTEGER(FootballMode:Repay), INTEGER(mInput:Ui:Mode)).
        Press("Escape,V").
        Assert:Equals(INTEGER(FootballMode:Levels), INTEGER(mInput:Ui:Mode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALoanIsTypedAsDigitsAndAskedOfTheBank():
        AtTheMenu().
        mGame:World:Cash = 0.
        Press("L,D5,D0,NumPad0,NumPad0,NumPad0").
        Assert:Equals("50000", mInput:Ui:Digits).
        Assert:Equals(50000, mInput:Ui:Amount()).
        Press("Return").
        Assert:Equals(50000, mGame:World:Loan).
        Assert:Equals(INTEGER(FootballMode:Main), INTEGER(mInput:Ui:Mode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALoanOverTheLimitIsRefusedWithAWordAndStaysOnTheScreen():
        AtTheMenu().
        Press("L,D9,D0,D0,D0,D0,D0,D0,Return").
        Assert:Equals(0, mGame:World:Loan).
        Assert:Equals(INTEGER(FootballMode:Loan), INTEGER(mInput:Ui:Mode)).
        Assert:IsTrue(mInput:Ui:News <> "").
        Assert:Equals("", mInput:Ui:Digits).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RepayingTakesBackWhatWasBorrowed():
        AtTheMenu().
        Bank:Borrow(mGame:World, 10000).
        Press("P,D4,D0,D0,D0,Return").
        Assert:Equals(6000, mGame:World:Loan).
        Press("P,Back").
        Assert:Equals("", mInput:Ui:Digits).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLevelListSetsTheLevel():
        AtTheMenu().
        /* the set up chose level 5, and Up twice is 3 */
        Press("V,Up,Up,Return").
        Assert:Equals(3, mGame:World:Level).
        Assert:Equals(INTEGER(FootballMode:Main), INTEGER(mInput:Ui:Mode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayerCanBeSoldFromTheSquadScreen():
        AtTheMenu().
        Press("A,Return").
        Assert:Equals(INTEGER(FootballMode:Selling), INTEGER(mInput:Ui:Mode)).
        Press("Y").
        Assert:Equals(INTEGER(FootballMode:Squad), INTEGER(mInput:Ui:Mode)).
        Assert:Equals(11, mGame:World:OwnedCount()).
        Assert:Equals("SOLD", mInput:Ui:News).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnOfferCanBeTurnedDown():
        AtTheMenu().
        Press("A,Return,N").
        Assert:Equals(INTEGER(FootballMode:Squad), INTEGER(mInput:Ui:Mode)).
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSquadCursorSkipsPlayersTheClubDoesNotOwn():
        VAR INTEGER start.
        AtTheMenu().
        Press("A").
        start = mInput:Ui:PlayerCursor.
        Assert:IsTrue(mGame:World:RoleOf(start) <> SquadRole:NotOwned).
        Press("Down").
        Assert:IsTrue(mGame:World:RoleOf(mInput:Ui:PlayerCursor) <> SquadRole:NotOwned).
        Assert:IsTrue(mInput:Ui:PlayerCursor <> start).
        Press("Up").
        Assert:Equals(start, mInput:Ui:PlayerCursor).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ContinuingGoesToPickTheTeamWhereSpacePicksAndDrops():
        VAR INTEGER p.
        AtTheMenu().
        Press("C").
        Assert:Equals(INTEGER(FootballMode:PickTeam), INTEGER(mInput:Ui:Mode)).
        p = mInput:Ui:PlayerCursor.
        IF mGame:World:RoleOf(p) = SquadRole:Starter THEN
        DO:
            Press("Space").
            Assert:Equals(INTEGER(SquadRole:Reserve), INTEGER(mGame:World:RoleOf(p))).
            Press("Return").
            Assert:Equals(INTEGER(SquadRole:Starter), INTEGER(mGame:World:RoleOf(p))).
        END.
        ELSE
        DO:
            Press("Space").
            Assert:IsTrue(mInput:Ui:News <> "" OR mGame:World:RoleOf(p) = SquadRole:Starter).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATwelfthPlayerCannotBePickedUntilOneIsTakenOut():
        VAR INTEGER p.
        AtTheMenu().
        Press("C").
        DO p = 1 TO 24:
            IF mGame:World:RoleOf(p) = SquadRole:Reserve THEN LEAVE.
        END.
        IF p <= 24 THEN
        DO:
            mInput:Ui:PlayerCursor = p.
            Press("Space").
            Assert:Equals(11, mGame:World:StarterCount()).
            Assert:IsTrue(mInput:Ui:News <> "").
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID KickOffPlaysTheMatchAndSpaceSkipsTheHighlightsThenGoesOn():
        AtTheMenu().
        Press("C,K").
        Assert:Equals(INTEGER(FootballMode:Match), INTEGER(mInput:Ui:Mode)).
        Press("Space").
        Assert:IsTrue(mGame:HighlightsOver()).
        Press("Space").
        Assert:Equals(INTEGER(FootballMode:FullTime), INTEGER(mInput:Ui:Mode)).
        Press("Return").
        Assert:Equals(INTEGER(FootballMode:Results), INTEGER(mInput:Ui:Mode)).
        Press("Return").
        Assert:Equals(INTEGER(FootballMode:Table), INTEGER(mInput:Ui:Mode)).
        Press("Return").
        Assert:Equals(INTEGER(FootballMode:Accounts), INTEGER(mInput:Ui:Mode)).
        Press("Return").
        Assert:Equals(INTEGER(FootballMode:Transfer), INTEGER(mInput:Ui:Mode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABidIsTypedAndMadeAndAPassReturnsToTheMenu():
        AtTheMenu().
        Press("C,K,Space,Space,Return,Return,Return,Return").
        Assert:Equals(INTEGER(FootballMode:Transfer), INTEGER(mInput:Ui:Mode)).
        Press("D0,Return").
        Assert:Equals(INTEGER(FootballMode:Transfer), INTEGER(mInput:Ui:Mode)).
        Assert:IsTrue(mInput:Ui:News <> "").
        Press("P").
        Assert:Equals(INTEGER(FootballMode:Main), INTEGER(mInput:Ui:Mode)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSackEndsTheGameAndEnterStartsAgain():
        AtTheMenu().
        mGame:World:Cash = 0.
        mGame:World:Loan = 1000000.
        Press("C,K,Space,Space,Return,Return,Return,Return").
        Assert:Equals(INTEGER(FootballMode:Sacked), INTEGER(mInput:Ui:Mode)).
        Assert:IsTrue(mGame:IsOver).
        Press("Return").
        Assert:Equals(INTEGER(FootballMode:Name), INTEGER(mInput:Ui:Mode)).
        Assert:IsFalse(mGame:IsOver).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID KeysTheGameDoesNotUseAreLeftToTheWindow():
        Assert:IsFalse(mInput:HandleKey("F5")).
        Assert:IsFalse(mInput:HandleKey(?)).
        AtTheMenu().
        Assert:IsFalse(mInput:HandleKey("F5")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWindowsExtrasAreEmpty():
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        Assert:Equals("", mInput:CommandNames).
        Assert:Equals("", mInput:BannerText).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
        Assert:Equals("", mInput:TakeNotice()).
        mInput:ReleaseKey("A").
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(1, 1).
        mInput:TertiaryAction(1, 1).
        mInput:Choice = "x".
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatAreNotAllowedAreRefused():
        Assert:IsTrue(Refused("nogame")).
        Assert:IsTrue(Refused("perform")).
    END METHOD.

END CLASS.
