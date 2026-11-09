/* A game of FootballManager kept in the settings: the round trip of every piece of the world, the refusal of a save that is missing, damaged or of another shape (the world is left as it was), and the game's own saving at the office and loading at the set up. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballSaveTests:

    VAR PRIVATE MemorySettings mSettings.
    VAR PRIVATE FootballSave mSave.
    VAR PRIVATE FootballWorld mWorld.
    VAR PRIVATE FootballGame mGame.

    @Setup.
    METHOD PUBLIC VOID BuildSave():
        mSettings = NEW MemorySettings().
        mSave = NEW FootballSave(mSettings).
        mWorld = NEW FootballWorld().
        mWorld:NewGame("Bob Paisley", 5, 4, 7, NEW SeededRandom(7)).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseGame():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
    END METHOD.

    /* Changes everything a played game changes: a promoted club (swapped slots, a new slot), injuries, a loan, a cup run, a sorted table. */
    METHOD PRIVATE VOID PlayedWorld():
        mWorld:SwapClubs(3, 40).
        mWorld:Slot = 41.
        mWorld:Cash = -1234.
        mWorld:Loan = 56000.
        mWorld:LastBalance = 777.
        mWorld:Gate = 31000.
        mWorld:Rent = 5000.
        mWorld:Morale = 14.
        mWorld:LeagueMatch = 9.
        mWorld:CupRound = 3.
        mWorld:CupOver = TRUE.
        mWorld:Cycle = 2.
        mWorld:NextHome = 1.
        mWorld:Seasons = 2.
        mWorld:SeasonScore = 70.
        mWorld:SetRole(1, SquadRole:Injured).
        mWorld:SetRole(2, SquadRole:Starter).
        mWorld:SetEnergy(2, 3).
        mWorld:AddResult(4, 3, 2, 1).
        mWorld:AddResult(9, 1, 0, 0).
        mWorld:SetPlace(4, 2).
        mWorld:SetTeamAt(1, 4).
        mWorld:SetTeamAt(4, 1).
    END METHOD.

    /* A short word for what differs between two worlds, or "" when they are the same. */
    METHOD PRIVATE CHARACTER Difference(INPUT poA AS FootballWorld, INPUT poB AS FootballWorld):
        VAR INTEGER i.
        IF poA:ManagerName <> poB:ManagerName THEN RETURN "manager".
        IF poA:Slot <> poB:Slot OR poA:Level <> poB:Level OR poA:KitColour <> poB:KitColour THEN RETURN "slot level kit".
        IF poA:Cash <> poB:Cash OR poA:Loan <> poB:Loan OR poA:LastBalance <> poB:LastBalance THEN RETURN "money".
        IF poA:Gate <> poB:Gate OR poA:Rent <> poB:Rent OR poA:Morale <> poB:Morale THEN RETURN "gate rent morale".
        IF poA:LeagueMatch <> poB:LeagueMatch OR poA:CupRound <> poB:CupRound OR poA:CupOver <> poB:CupOver THEN RETURN "season progress".
        IF poA:Cycle <> poB:Cycle OR poA:NextHome <> poB:NextHome THEN RETURN "cycle".
        IF poA:Seasons <> poB:Seasons OR poA:SeasonScore <> poB:SeasonScore THEN RETURN "seasons".
        DO i = 1 TO 64:
            IF poA:ClubName(i) <> poB:ClubName(i) THEN RETURN "club " + STRING(i).
        END.
        DO i = 1 TO 24:
            IF poA:RoleOf(i) <> poB:RoleOf(i) THEN RETURN "role " + STRING(i).
            IF poA:SkillOf(i) <> poB:SkillOf(i) THEN RETURN "skill " + STRING(i).
            IF poA:EnergyOf(i) <> poB:EnergyOf(i) THEN RETURN "energy " + STRING(i).
            IF poA:WorthOf(i) <> poB:WorthOf(i) THEN RETURN "worth " + STRING(i).
        END.
        DO i = 1 TO 16:
            IF poA:PointsOf(i) <> poB:PointsOf(i) OR poA:GoalsForOf(i) <> poB:GoalsForOf(i) OR poA:GoalsAgainstOf(i) <> poB:GoalsAgainstOf(i) THEN
                RETURN "table " + STRING(i).
            IF poA:PlaceOf(i) <> poB:PlaceOf(i) OR poA:TeamAt(i) <> poB:TeamAt(i) THEN RETURN "order " + STRING(i).
        END.
        RETURN "".
    END METHOD.

    /* Loads the save into a fresh world and says whether it worked. */
    METHOD PRIVATE LOGICAL Loads():
        VAR FootballWorld other = NEW FootballWorld().
        VAR INTEGER turnLoaded.
        RETURN mSave:Restore(other, OUTPUT turnLoaded).
    END METHOD.

    /* A save of the world after PlayedWorld, with one key changed. */
    METHOD PRIVATE VOID KeepWith(INPUT pcKey AS CHARACTER, INPUT pcValue AS CHARACTER):
        PlayedWorld().
        mSave:Keep(mWorld, 5).
        mSettings:SetString("footballmanager.save." + pcKey, pcValue).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaveNeedsSettings():
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            mSave = NEW FootballSave(?).
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(refused).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheVersionIsOne():
        Assert:Equals(1, FootballSave:Version()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID NothingIsSavedUntilAGameIsKept():
        Assert:IsFalse(mSave:HasSave()).
        mSave:Keep(mWorld, 0).
        Assert:IsTrue(mSave:HasSave()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameRoundTrips():
        VAR FootballWorld other = NEW FootballWorld().
        VAR INTEGER turnLoaded.
        mSave:Keep(mWorld, 0).
        Assert:IsTrue(mSave:Restore(other, OUTPUT turnLoaded)).
        Assert:Equals("", Difference(mWorld, other)).
        Assert:Equals(0, turnLoaded).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APlayedGameRoundTripsEveryPieceAndTheTurn():
        VAR FootballWorld other = NEW FootballWorld().
        VAR INTEGER turnLoaded.
        PlayedWorld().
        mSave:Keep(mWorld, 23).
        Assert:IsTrue(mSave:Restore(other, OUTPUT turnLoaded)).
        Assert:Equals("", Difference(mWorld, other)).
        Assert:Equals(23, turnLoaded).
        Assert:Equals(41, other:Slot).
        Assert:IsTrue(other:CupOver).
        Assert:Equals(INTEGER(SquadRole:Injured), INTEGER(other:RoleOf(1))).
        Assert:Equals(4, other:TeamAt(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaveSurvivesBeingWrittenToAFileAndReadBack():
        VAR CHARACTER path = SESSION:TEMP-DIRECTORY + "football-save-test.json".
        VAR FootballWorld other = NEW FootballWorld().
        VAR INTEGER turnLoaded.
        VAR FootballSave writer = NEW FootballSave(NEW JsonFileSettings(path)).
        PlayedWorld().
        writer:Keep(mWorld, 8).
        Assert:IsTrue(NEW FootballSave(NEW JsonFileSettings(path)):Restore(other, OUTPUT turnLoaded)).
        Assert:Equals("", Difference(mWorld, other)).
        Assert:Equals(8, turnLoaded).
        OS-DELETE VALUE(path).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALoadedWorldKeepsItsInvariants():
        VAR FootballWorld other = NEW FootballWorld().
        VAR INTEGER turnLoaded.
        VAR INTEGER i.
        VAR INTEGER n.
        VAR LOGICAL[64] seen.
        PlayedWorld().
        mSave:Keep(mWorld, 1).
        mSave:Restore(other, OUTPUT turnLoaded).
        DO i = 1 TO 24:
            Assert:IsTrue(other:SkillOf(i) >= 1 AND other:SkillOf(i) <= 5).
            Assert:IsTrue(other:EnergyOf(i) >= 1 AND other:EnergyOf(i) <= 20).
        END.
        Assert:IsTrue(other:Slot >= 1 AND other:Slot <= 64).
        DO i = 1 TO 64:
            DO n = 1 TO 64:
                IF other:ClubName(i) = FootballNames:Club(n) THEN seen[n] = TRUE.
            END.
        END.
        DO n = 1 TO 64:
            Assert:IsTrue(seen[n]).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WithNoSaveNothingLoadsAndTheWorldIsUntouched():
        VAR FootballWorld other = NEW FootballWorld().
        VAR INTEGER turnLoaded = 99.
        Assert:IsFalse(mSave:Restore(other, OUTPUT turnLoaded)).
        Assert:Equals("", Difference(other, NEW FootballWorld())).
        Assert:Equals(0, turnLoaded).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaveOfAnotherShapeIsIgnored():
        mSave:Keep(mWorld, 0).
        mSettings:SetInteger("footballmanager.save.version", 2).
        Assert:IsTrue(mSave:HasSave()).
        Assert:IsFalse(Loads()).
        mSettings:SetInteger("footballmanager.save.version", 0).
        Assert:IsFalse(Loads()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADamagedSaveIsIgnoredAndLeavesTheWorldAsItWas():
        VAR FootballWorld other = NEW FootballWorld().
        VAR INTEGER turnLoaded.
        KeepWith("order", "1,1,3,4,5,6,7,8,9,10,11,12,13,14,15,16").
        Assert:IsFalse(mSave:Restore(other, OUTPUT turnLoaded)).
        Assert:Equals("", Difference(other, NEW FootballWorld())).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryKindOfDamageIsRefused():
        KeepWith("role", "1,1,1").
        Assert:IsFalse(Loads()).
        KeepWith("role", "9,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1").
        Assert:IsFalse(Loads()).
        KeepWith("skill", "6,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1").
        Assert:IsFalse(Loads()).
        KeepWith("energy", "0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1").
        Assert:IsFalse(Loads()).
        KeepWith("energy", "21,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1").
        Assert:IsFalse(Loads()).
        KeepWith("worth", "x,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1").
        Assert:IsFalse(Loads()).
        KeepWith("clubs", "Arsenal|Arsenal").
        Assert:IsFalse(Loads()).
        KeepWith("manager", "Bob").
        mSettings:SetString("footballmanager.save.clubs", REPLACE(mSettings:GetString("footballmanager.save.clubs", ""), "Arsenal", "Nowhere FC")).
        Assert:IsFalse(Loads()).
        KeepWith("points", "").
        Assert:IsFalse(Loads()).
        KeepWith("place", "0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,17").
        Assert:IsFalse(Loads()).
        KeepWith("manager", "").
        Assert:IsFalse(Loads()).
        KeepWith("slot", "65").
        Assert:IsFalse(Loads()).
        KeepWith("slot", "0").
        Assert:IsFalse(Loads()).
        KeepWith("slot", "abc").
        Assert:IsFalse(Loads()).
        KeepWith("kit", "3").
        Assert:IsFalse(Loads()).
        KeepWith("level", "8").
        Assert:IsFalse(Loads()).
        KeepWith("morale", "0").
        Assert:IsFalse(Loads()).
        KeepWith("cupround", "9").
        Assert:IsFalse(Loads()).
        KeepWith("leaguematch", "-1").
        Assert:IsFalse(Loads()).
        KeepWith("nexthome", "3").
        Assert:IsFalse(Loads()).
        KeepWith("loan", "-5").
        Assert:IsFalse(Loads()).
        KeepWith("turn", "").
        Assert:IsFalse(Loads()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TooManyPlayersInTheSquadIsDamage():
        KeepWith("role", "1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1").
        Assert:IsFalse(Loads()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeletedPartIsDamage():
        PlayedWorld().
        mSave:Keep(mWorld, 5).
        mSettings:SetString("footballmanager.save.cash", "").
        Assert:IsFalse(Loads()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EraseForgetsTheSave():
        mSave:Keep(mWorld, 3).
        mSave:Erase().
        Assert:IsFalse(mSave:HasSave()).
        Assert:IsFalse(Loads()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID KeepAndRestoreNeedAWorld():
        VAR LOGICAL keepRefused.
        VAR LOGICAL restoreRefused.
        VAR INTEGER turnLoaded.
        DO ON ERROR UNDO, THROW:
            mSave:Keep(?, 0).
            CATCH e AS GridException:
                keepRefused = TRUE.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mSave:Restore(?, OUTPUT turnLoaded).
            CATCH e2 AS GridException:
                restoreRefused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(keepRefused).
        Assert:IsTrue(restoreRefused).
    END METHOD.

    /* A game at the Menu that keeps itself in mSettings. */
    METHOD PRIVATE VOID KeptGame():
        mGame = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(3)).
        mGame:Autosave = mSave.
        mGame:StartNewGame("Ann", 2, 3, 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameWithNoSaveStartsAtTheSetup():
        mGame = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(3)).
        Assert:IsFalse(mGame:LoadSaved()).
        mGame:Autosave = mSave.
        Assert:IsFalse(mGame:LoadSaved()).
        Assert:Equals(INTEGER(FootballPhase:Setup), INTEGER(mGame:Phase)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StartingAGameKeepsItAndAnotherRunLoadsItIntoTheOffice():
        VAR FootballGame second.
        KeptGame().
        Assert:IsTrue(mSave:HasSave()).
        second = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(99)).
        second:Autosave = NEW FootballSave(mSettings).
        Assert:IsTrue(second:LoadSaved()).
        Assert:Equals(INTEGER(FootballPhase:Menu), INTEGER(second:Phase)).
        Assert:Equals("Ann", second:World:ManagerName).
        Assert:Equals("", Difference(mGame:World, second:World)).
        second:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMenuActionsAreKept():
        VAR FootballGame second.
        KeptGame().
        mGame:Borrow(5000).
        mGame:SetLevel(6).
        second = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(1)).
        second:Autosave = mSave.
        second:LoadSaved().
        Assert:Equals(5000, second:World:Loan).
        Assert:Equals(6, second:World:Level).
        mGame:Repay(1000).
        second:Dispose().
        second = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(1)).
        second:Autosave = mSave.
        second:LoadSaved().
        Assert:Equals(4000, second:World:Loan).
        second:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaleIsKeptWhetherAcceptedOrTurnedDown():
        VAR FootballGame second.
        VAR INTEGER player.
        VAR INTEGER i.
        KeptGame().
        DO i = 1 TO 24:
            IF mGame:World:RoleOf(i) = SquadRole:Reserve THEN player = i.
        END.
        mGame:OfferSale(player).
        mGame:AcceptSale().
        second = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(1)).
        second:Autosave = mSave.
        second:LoadSaved().
        Assert:Equals(INTEGER(SquadRole:NotOwned), INTEGER(second:World:RoleOf(player))).
        Assert:Equals("", Difference(mGame:World, second:World)).
        second:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWeekIsKeptOnlyWhenItIsOverAndTheTurnComesBack():
        VAR FootballGame second.
        VAR INTEGER guard.
        KeptGame().
        mGame:World:Cash = 10000000.
        mGame:Borrow(1).
        mGame:Continue().
        mGame:KickOff().
        /* in the middle of the week the save is still the last time in the office */
        second = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(1)).
        second:Autosave = mSave.
        second:LoadSaved().
        Assert:Equals(0, second:Turn).
        second:Dispose().
        DO WHILE mGame:Phase <> FootballPhase:Menu AND guard < 60:
            guard = guard + 1.
            IF mGame:Phase = FootballPhase:Transfer THEN mGame:Pass().
            ELSE mGame:Proceed().
        END.
        second = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(1)).
        second:Autosave = mSave.
        second:LoadSaved().
        Assert:Equals(1, mGame:Turn).
        Assert:Equals(1, second:Turn).
        Assert:Equals("", Difference(mGame:World, second:World)).
        second:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BeingSackedForgetsTheSave():
        KeptGame().
        mGame:World:Cash = 0.
        mGame:World:Loan = 1000000.
        mGame:Continue().
        mGame:KickOff().
        mGame:Proceed().
        mGame:Proceed().
        mGame:Proceed().
        mGame:Proceed().
        mGame:Proceed().
        Assert:Equals(INTEGER(FootballPhase:Sacked), INTEGER(mGame:Phase)).
        Assert:IsFalse(mSave:HasSave()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALoadedGameCanBeLoadedOnlyAtTheSetup():
        VAR LOGICAL refused.
        KeptGame().
        DO ON ERROR UNDO, THROW:
            mGame:LoadSaved().
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(refused).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsNotKeptStillPlays():
        mGame = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(3)).
        mGame:StartNewGame("Ann", 2, 3, 0).
        mGame:Borrow(10).
        Assert:Equals(10, mGame:World:Loan).
        Assert:IsFalse(mSave:HasSave()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADamagedSaveLeavesTheGameAtTheSetup():
        mSave:Keep(mWorld, 4).
        mSettings:SetString("footballmanager.save.skill", "oops").
        mGame = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(3)).
        mGame:Autosave = mSave.
        Assert:IsFalse(mGame:LoadSaved()).
        Assert:Equals(INTEGER(FootballPhase:Setup), INTEGER(mGame:Phase)).
        Assert:Equals(0, mGame:Turn).
        Assert:Equals("", mGame:World:ManagerName).
    END METHOD.

END CLASS.
