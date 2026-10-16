/* The keyList of Blast Buddies: held keyList are states, a press is one event, and only a turn played by a person is steered. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BlastBuddiesInputTests:

    DEFINE PRIVATE VARIABLE mGame     AS BlastBuddiesGame  NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings AS ISettings         NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput    AS BlastBuddiesInput NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID Setup():
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow)).
        mSettings = NEW MemorySettings().
        mInput = NEW BlastBuddiesInput(mGame, mSettings).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID TearDown():
        mGame:Dispose().
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    METHOD PRIVATE VOID ToTheFirstTurn():
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameKeysAreTakenAndOtherKeysAreLeftToTheWindow():
        DEFINE VARIABLE keyList AS CHARACTER NO-UNDO INITIAL "Left,Right,Up,Down,Return,Enter,Space,Add,Subtract,Oemplus,OemMinus".
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(keyList):
            Assert:IsTrue(mInput:HandleKey(ENTRY(i, keyList)), ENTRY(i, keyList)).
            mInput:ReleaseKey(ENTRY(i, keyList)).
        END.
        Assert:IsFalse(mInput:HandleKey("P")).
        Assert:IsFalse(mInput:HandleKey("Escape")).
        Assert:IsFalse(mInput:HandleKey("Tab")).
        Assert:IsFalse(mInput:HandleKey(?)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HeldWalkKeysSteerTheBuddyInTurnAndTheLastOneDownWins():
        ToTheFirstTurn().
        mInput:HandleKey("Left").
        Assert:Equals(-1, mGame:WalkDirection).
        mInput:HandleKey("Right").
        Assert:Equals(1, mGame:WalkDirection).
        mInput:ReleaseKey("Right").
        Assert:Equals(-1, mGame:WalkDirection).
        mInput:ReleaseKey("Left").
        Assert:Equals(0, mGame:WalkDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HeldAimKeysSteerTheAim():
        ToTheFirstTurn().
        mInput:HandleKey("Up").
        Assert:Equals(-1, mGame:AimDirection).
        mInput:HandleKey("Down").
        Assert:Equals(1, mGame:AimDirection).
        mInput:ReleaseKey("Down").
        Assert:Equals(-1, mGame:AimDirection).
        mInput:ReleaseKey("Up").
        Assert:Equals(0, mGame:AimDirection).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID KeyRepeatDoesNotRepeatAHopOrAShot():
        ToTheFirstTurn().
        mInput:HandleKey("Return").
        Frames(2).
        mInput:HandleKey("Return").
        mInput:HandleKey("Return").
        /* a second press would have turned the hop into a backflip, going backwards */
        Assert:IsTrue(mGame:CurrentBuddy:VX * mGame:CurrentBuddy:Facing >= 0).
        mInput:HandleKey("Space").
        mInput:HandleKey("Space").
        Frames(10).
        Assert:Equals(10, mGame:Charge).
        mInput:ReleaseKey("Space").
        Assert:Equals(1, mGame:ShotsFired).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APressOfEnterAfterReleaseIsANewPress():
        ToTheFirstTurn().
        mGame:Land:FillRect(0, mGame:CurrentBuddy:Y() - 30, 383, mGame:CurrentBuddy:Y() - 1, FALSE).
        mInput:HandleKey("Return").
        Frames(2).
        mInput:ReleaseKey("Return").
        mInput:HandleKey("Return").
        Assert:IsTrue(mGame:CurrentBuddy:VX <> 0).
        Assert:IsTrue(mGame:CurrentBuddy:VX * mGame:CurrentBuddy:Facing < 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceChargesWhileHeldAndFiresWhenItComesUp():
        ToTheFirstTurn().
        mInput:HandleKey("Space").
        Assert:IsTrue(mGame:Charging).
        Frames(30).
        mInput:ReleaseKey("Space").
        Assert:Equals(1, mGame:ShotsFired).
        Assert:Equals(33, mGame:LastPower).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Retreat).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingSteersTheComputersTurnOrTheBanner():
        mInput:HandleKey("Left").
        mInput:HandleKey("Space").
        Assert:Equals(0, mGame:WalkDirection).
        Assert:IsFalse(mGame:Charging).
        ToTheFirstTurn().
        mGame:EndTurn().
        Frames(BuddyRules:SettleFrames() + BuddyRules:BannerFrames()).
        Assert:IsFalse(mGame:HumanTurn).
        mInput:HandleKey("Right").
        mInput:HandleKey("Up").
        mInput:HandleKey("Space").
        Assert:Equals(0, mGame:WalkDirection).
        Assert:Equals(0, mGame:AimDirection).
        Assert:IsFalse(mGame:Charging).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnEmptyKeyNameReleasesEveryKey():
        ToTheFirstTurn().
        mInput:HandleKey("Left").
        mInput:HandleKey("Up").
        mInput:ReleaseKey("").
        Assert:Equals(0, mGame:WalkDirection).
        Assert:Equals(0, mGame:AimDirection).
        mInput:ReleaseKey(?).
        mInput:ReleaseKey("P").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PlusAndMinusChangeTheSpeedInTensAndItIsKept():
        Assert:Equals(100, mGame:SpeedPercent).
        mInput:HandleKey("Subtract").
        Assert:Equals(90, mGame:SpeedPercent).
        Assert:Equals("Speed 90%", mInput:TakeNotice()).
        Assert:Equals("", mInput:TakeNotice()).
        Assert:Equals(90, mSettings:GetInteger("blastbuddies.speed", 0)).
        mInput:HandleKey("Add").
        mInput:HandleKey("Add").
        Assert:Equals(110, mGame:SpeedPercent).
        Assert:Equals(110, mSettings:GetInteger("blastbuddies.speed", 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpeedStaysBetweenTenAndTwoHundredAndStartsFromTheSetting():
        DEFINE VARIABLE i   AS INTEGER             NO-UNDO.
        DEFINE VARIABLE inp AS BlastBuddiesInput   NO-UNDO.
        DO i = 1 TO 30:
            mInput:HandleKey("Subtract").
        END.
        Assert:Equals(10, mGame:SpeedPercent).
        DO i = 1 TO 30:
            mInput:HandleKey("Add").
        END.
        Assert:Equals(200, mGame:SpeedPercent).
        inp = NEW BlastBuddiesInput(mGame, mSettings).
        Assert:Equals(200, mGame:SpeedPercent).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineTellsTheStateOfTheGame():
        Assert:IsTrue(mInput:StatusText BEGINS "Blast Buddies").
        ToTheFirstTurn().
        Assert:IsTrue(mInput:StatusText MATCHES "*(team 1)*Wind*Time 45*Power 0%*").
        mGame:EndTurn().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineSaysWhoWonAndOfADraw():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ToTheFirstTurn().
        DO i = 1 TO 3:
            mGame:Plan:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        mGame:EndTurn().
        Frames(700).
        Assert:IsTrue(mInput:StatusText BEGINS "Team 1 wins").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStatusLineOfADrawSaysSo():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        ToTheFirstTurn().
        DO i = 1 TO 3:
            mGame:Plan:TeamAt(1):BuddyAt(i):Hurt(100).
            mGame:Plan:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        mGame:EndTurn().
        Frames(700).
        Assert:IsTrue(mInput:StatusText BEGINS "A draw").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThereIsNoPickerNoCommandNoBannerNoInfoAndOtherCommandsAreRefused():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        Assert:Equals("", mInput:ChoiceLabel).
        Assert:Equals("", mInput:ChoiceNames).
        Assert:Equals("", mInput:Choice).
        mInput:Choice = "x".
        Assert:Equals("", mInput:CommandNames).
        Assert:Equals("", mInput:BannerText).
        Assert:Equals("", mInput:InfoLabel).
        Assert:Equals("", mInput:InfoText).
        mInput:PrimaryAction(1, 1).
        mInput:SecondaryAction(1, 1).
        mInput:TertiaryAction(1, 1).
        DO ON ERROR UNDO, LEAVE:
            mInput:Perform("Fly").
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFiveOptionsAreTheirLabelsKeysNamesAndTheCurrentValues():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:Equals(5, mInput:OptionCount).
        Assert:Equals("Teams", mInput:OptionLabel(1)).
        Assert:Equals("Land", mInput:OptionLabel(5)).
        Assert:Equals("teams,buddies,computer,skill,theme", mInput:OptionKey(1) + "," + mInput:OptionKey(2) + "," + mInput:OptionKey(3) + "," + mInput:OptionKey(4) + "," + mInput:OptionKey(5)).
        Assert:Equals("2,3,4", mInput:OptionNames(1)).
        Assert:Equals("3,4", mInput:OptionNames(2)).
        Assert:Equals("None,1,2,3", mInput:OptionNames(3)).
        Assert:Equals("Easy,Normal,Hard", mInput:OptionNames(4)).
        Assert:Equals("Meadow,Canyon,Candy,Random", mInput:OptionNames(5)).
        Assert:Equals("2", mInput:OptionValue(1)).
        Assert:Equals("3", mInput:OptionValue(2)).
        Assert:Equals("1", mInput:OptionValue(3)).
        Assert:Equals("Normal", mInput:OptionValue(4)).
        Assert:Equals("Meadow", mInput:OptionValue(5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ChoosingAnOptionStartsANewGameWithThatSetup():
        mInput:SetOption(1, "3").
        Assert:Equals(3, mGame:Plan:TeamCount()).
        Assert:Equals("3", mInput:OptionValue(1)).
        mInput:SetOption(2, "4").
        Assert:Equals(4, mGame:Plan:TeamAt(1):Count()).
        mInput:SetOption(4, "Hard").
        Assert:IsTrue(mGame:Setup:Skill = BuddySkill:Hard).
        Assert:Equals("Hard", mInput:OptionValue(4)).
        mInput:SetOption(5, "Canyon").
        Assert:IsTrue(mGame:MapTheme = Theme:Canyon).
        Assert:Equals("Canyon", mInput:OptionValue(5)).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Arrival).
        Assert:IsTrue(mInput:TakeNotice() BEGINS "3 teams of 4").
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheComputerIsNeverAllTheTeamsAndRandomPicksAnyLook():
        mInput:SetOption(1, "4").
        mInput:SetOption(3, "3").
        Assert:Equals("3", mInput:OptionValue(3)).
        Assert:IsTrue(mGame:Plan:TeamAt(4):IsComputer).
        Assert:IsFalse(mGame:Plan:TeamAt(1):IsComputer).
        mInput:SetOption(1, "2").
        Assert:Equals("1", mInput:OptionValue(3)).
        mInput:SetOption(3, "None").
        Assert:Equals("None", mInput:OptionValue(3)).
        Assert:IsFalse(mGame:Plan:TeamAt(2):IsComputer).
        mInput:SetOption(5, "Random").
        Assert:Equals("Random", mInput:OptionValue(5)).
        Assert:IsTrue(mGame:Setup:RandomTheme).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadOptionOrValueIsRefused():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mInput:SetOption(6, "x").
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mInput:SetOption(1, "9").
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mInput:OptionLabel(0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mInput:OptionKey(7).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mInput:OptionNames(7).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mInput:OptionValue(7).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameGivesTheComputerPlayerTheSkillOfTheSetup():
        DEFINE VARIABLE brain AS SimulatingBrain NO-UNDO.
        brain = NEW SimulatingBrain(NEW SeededRandom(1), BuddySkill:Easy).
        mGame:Brain = brain.
        mInput:SetOption(4, "Hard").
        Assert:IsTrue(brain:Skill = BuddySkill:Hard).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RestartingNeedsASetupAndTheMapIsInTheThemeOfTheSetup():
        DEFINE VARIABLE lThrown AS LOGICAL NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            mGame:Restart(?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        mGame:Restart(NEW BuddySetup(3, 3, 0, Theme:Candy)).
        Assert:IsTrue(mGame:MapTheme = Theme:Candy).
        Assert:IsTrue(mGame:Land:MapTheme = Theme:Candy).
        Assert:Equals(3, mGame:Plan:TeamCount()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID SpaceStartsTheMatchFromTheTitleAndANewGameFromTheEndScreen():
        DEFINE VARIABLE g   AS BlastBuddiesGame  NO-UNDO.
        DEFINE VARIABLE inp AS BlastBuddiesInput NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER           NO-UNDO.
        g = BlastBuddiesFactory:CreateWithTitle(NEW SeededRandom(5), BuddySetup:Default()).
        inp = NEW BlastBuddiesInput(g, mSettings).
        Assert:IsTrue(inp:StatusText BEGINS "Blast Buddies   Press Space").
        Assert:IsTrue(inp:HandleKey("Space")).
        Assert:IsTrue(g:Phase = BuddyPhase:Arrival).
        inp:ReleaseKey("Space").
        Assert:IsFalse(g:Charging).
        DO i = 1 TO BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames():
            g:Advance().
        END.
        DO i = 1 TO 3:
            g:Plan:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        g:EndTurn().
        DO i = 1 TO 500:
            g:Advance().
        END.
        Assert:IsTrue(g:Phase = BuddyPhase:Winner).
        inp:HandleKey("Space").
        inp:ReleaseKey("Space").
        Assert:IsTrue(g:Phase = BuddyPhase:Title).
        g:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID InputNeedsAGameAndSettings():
        DEFINE VARIABLE inp     AS BlastBuddiesInput NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL           NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            inp = NEW BlastBuddiesInput(?, mSettings).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            inp = NEW BlastBuddiesInput(mGame, ?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

END CLASS.
