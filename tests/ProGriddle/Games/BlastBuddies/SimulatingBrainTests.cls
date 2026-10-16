/* The computer player of Blast Buddies and the shot simulator it tries shots with. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.SimulatingBrainTests:

    DEFINE PRIVATE VARIABLE mGame  AS BlastBuddiesGame NO-UNDO.
    DEFINE PRIVATE VARIABLE mBrain AS SimulatingBrain  NO-UNDO.

    @TearDown.
    METHOD PUBLIC VOID TearDown():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* A game of two teams of three, the computer playing team 2 at a skill, on flat ground at row 150 with clear air over it. The buddies of
       team 1 stand at 150 (the one in front), 20 and 35, those of team 2 at 300 (the one that plays), 370 and 355. The first turn of
       team 1 is ended so that it is the computer's turn, and the game is run to the start of it. */
    METHOD PRIVATE VOID Stage(INPUT poSkill AS BuddySkill, INPUT piSeed AS INTEGER):
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow, poSkill)).
        mBrain = NEW SimulatingBrain(NEW SeededRandom(piSeed), poSkill).
        mGame:Brain = mBrain.
        mGame:Land:FillRect(0, 0, 383, 239, FALSE).
        mGame:Land:FillRect(0, 150, 383, 239, TRUE).
        mGame:Plan:TeamAt(1):BuddyAt(1):PlaceAt(150, 150).
        mGame:Plan:TeamAt(1):BuddyAt(2):PlaceAt(20, 150).
        mGame:Plan:TeamAt(1):BuddyAt(3):PlaceAt(35, 150).
        mGame:Plan:TeamAt(2):BuddyAt(1):PlaceAt(300, 150).
        mGame:Plan:TeamAt(2):BuddyAt(2):PlaceAt(370, 150).
        mGame:Plan:TeamAt(2):BuddyAt(3):PlaceAt(355, 150).
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames()).
        mGame:EndTurn().
        Frames(BuddyRules:SettleFrames() + BuddyRules:BannerFrames()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Turn).
        Assert:Equals(2, mGame:CurrentBuddy:Team).
    END METHOD.

    /* runs until the computer has fired, or a number of frames; returns whether it did */
    METHOD PRIVATE LOGICAL RunUntilFired(INPUT piMax AS INTEGER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO WHILE n < piMax AND mGame:ShotsFired = 0:
            mGame:Advance().
            n = n + 1.
        END.
        RETURN mGame:ShotsFired > 0.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSimulatorFliesAShotTheWayTheGameDoes():
        DEFINE VARIABLE sim AS ShotSimulator NO-UNDO.
        DEFINE VARIABLE hx  AS INTEGER       NO-UNDO.
        DEFINE VARIABLE hy  AS INTEGER       NO-UNDO.
        DEFINE VARIABLE hit AS LOGICAL       NO-UNDO.
        DEFINE VARIABLE x0  AS INTEGER       NO-UNDO.
        DEFINE VARIABLE y0  AS INTEGER       NO-UNDO.
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow)).
        mGame:Land:FillRect(0, 0, 383, 239, FALSE).
        mGame:Land:FillRect(0, 150, 383, 239, TRUE).
        mGame:Plan:TeamAt(1):BuddyAt(1):PlaceAt(60, 150).
        mGame:Plan:TeamAt(1):BuddyAt(2):PlaceAt(20, 150).
        mGame:Plan:TeamAt(1):BuddyAt(3):PlaceAt(35, 150).
        mGame:Plan:TeamAt(2):BuddyAt(1):PlaceAt(370, 150).
        mGame:Plan:TeamAt(2):BuddyAt(2):PlaceAt(360, 150).
        mGame:Plan:TeamAt(2):BuddyAt(3):PlaceAt(350, 150).
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames()).
        mGame:CurrentBuddy:Facing = 1.
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 60 * 256 + 1536, 144 * 256 - 400, 600, -500).
        sim = NEW ShotSimulator().
        hit = sim:Fly(mGame:Land, 60 * 256 + 1536, 144 * 256 - 400, 600, -500, mGame:Wind, OUTPUT hx, OUTPUT hy).
        Assert:IsTrue(hit).
        Frames(200).
        Assert:Equals(1, mGame:BlastCount).
        Assert:Equals(hx, mGame:LastBlastX).
        Assert:Equals(hy, mGame:LastBlastY).
        Assert:Equals(1, sim:Flights).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSimulatorLosesAShotInTheWaterOrOffTheSidesAndNeedsATerrain():
        DEFINE VARIABLE sim     AS ShotSimulator NO-UNDO.
        DEFINE VARIABLE t       AS Terrain       NO-UNDO.
        DEFINE VARIABLE hx      AS INTEGER       NO-UNDO.
        DEFINE VARIABLE hy      AS INTEGER       NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL       NO-UNDO.
        sim = NEW ShotSimulator().
        t = NEW Terrain(Theme:Meadow).
        Assert:IsFalse(sim:Fly(t, 100 * 256, 100 * 256, 0, 0, 0, OUTPUT hx, OUTPUT hy)).
        Assert:IsFalse(sim:Fly(t, 100 * 256, 100 * 256, -2000, 0, 0, OUTPUT hx, OUTPUT hy)).
        Assert:IsFalse(sim:Fly(t, 100 * 256, 100 * 256, 2000, 0, 0, OUTPUT hx, OUTPUT hy)).
        t:FillRect(0, 150, 383, 239, TRUE).
        Assert:IsTrue(sim:Fly(t, 100 * 256, 100 * 256, 0, 0, 0, OUTPUT hx, OUTPUT hy)).
        Assert:Equals(100, hx).
        Assert:Equals(150, hy).
        DO ON ERROR UNDO, LEAVE:
            sim:Fly(?, 0, 0, 0, 0, 0, OUTPUT hx, OUTPUT hy).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        t:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABrainOnHardHitsAnEnemyStandingOnFlatGround():
        Stage(BuddySkill:Hard, 7).
        Assert:IsTrue(RunUntilFired(1500)).
        Frames(120).
        Assert:IsTrue(mGame:BlastCount >= 1).
        Assert:IsTrue(mGame:Plan:TeamAt(1):BuddyAt(1):Health < 100, "enemy health " + STRING(mGame:Plan:TeamAt(1):BuddyAt(1):Health)).
        Assert:Equals(100, mGame:Plan:TeamAt(2):BuddyAt(1):Health).
        Assert:IsTrue(mBrain:Stage = BrainStage:Done).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABrainOnEasyAndOnNormalAlsoFireWithinTheirTurn():
        Stage(BuddySkill:Easy, 3).
        Assert:IsTrue(RunUntilFired(2000)).
        mGame:Dispose().
        Stage(BuddySkill:Normal, 4).
        Assert:IsTrue(RunUntilFired(2000)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABrainThatIsBoxedInNeverBlowsItselfUpAtPointBlank():
        Stage(BuddySkill:Hard, 9).
        /* a wall of rock a few pixels in front of the computer, on the side the enemy is */
        mGame:Land:FillRect(290, 60, 296, 149, TRUE).
        Assert:IsTrue(RunUntilFired(2000)).
        Frames(150).
        Assert:Equals(100, mGame:Plan:TeamAt(2):BuddyAt(1):Health).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThinkingBrainShowsItsBubbleForAtLeastASecondAndNeverDoesMoreThanItsSlice():
        DEFINE VARIABLE n      AS INTEGER NO-UNDO.
        DEFINE VARIABLE before AS INTEGER NO-UNDO.
        DEFINE VARIABLE most   AS INTEGER NO-UNDO.
        Stage(BuddySkill:Hard, 5).
        n = 0.
        DO WHILE mBrain:Thinking OR n = 0:
            before = mBrain:Flights.
            mGame:Advance().
            n = n + 1.
            most = MAXIMUM(most, mBrain:Flights - before).
            IF n > 1000 THEN LEAVE.
        END.
        Assert:IsTrue(n >= 60, "thought for " + STRING(n) + " frames").
        Assert:IsTrue(most <= 6, "most flights in a frame " + STRING(most)).
        Assert:IsTrue(mBrain:Flights > 100).
        Assert:IsFalse(mBrain:Thinking).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameSeedMakesTheSameDecision():
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE e AS INTEGER NO-UNDO.
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        Stage(BuddySkill:Easy, 11).
        RunUntilFired(2000).
        x = mBrain:GoalX.
        e = mBrain:GoalAim.
        p = mBrain:GoalPower.
        mGame:Dispose().
        Stage(BuddySkill:Easy, 11).
        RunUntilFired(2000).
        Assert:Equals(x, mBrain:GoalX).
        Assert:Equals(e, mBrain:GoalAim).
        Assert:Equals(p, mBrain:GoalPower).
        Assert:IsTrue(mBrain:GoalFacing = -1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheComputerOnlyPlaysTheTurnsOfItsOwnTeams():
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow, BuddySkill:Hard)).
        mBrain = NEW SimulatingBrain(NEW SeededRandom(1), BuddySkill:Hard).
        mGame:Brain = mBrain.
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames() + 120).
        Assert:Equals(1, mGame:CurrentBuddy:Team).
        Assert:IsTrue(mBrain:Stage = BrainStage:Idle).
        Assert:IsFalse(mBrain:Thinking).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBrainAndTheSetupNeedTheirPartsAndTheFaceCommandChecksItsDirection():
        DEFINE VARIABLE b       AS SimulatingBrain NO-UNDO.
        DEFINE VARIABLE s       AS BuddySetup      NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL         NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            b = NEW SimulatingBrain(?, BuddySkill:Easy).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            b = NEW SimulatingBrain(NEW SeededRandom(1), ?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        b = NEW SimulatingBrain(NEW SeededRandom(1), BuddySkill:Normal).
        DO ON ERROR UNDO, LEAVE:
            b:Drive(?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            s = NEW BuddySetup(2, 3, 1, Theme:Meadow, ?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        Assert:IsTrue(NEW BuddySetup(2, 3, 1, Theme:Meadow, BuddySkill:Hard):Skill = BuddySkill:Hard).
        Assert:IsTrue(BuddySetup:Default():Skill = BuddySkill:Normal).
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), BuddySetup:Default()).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mGame:Face(0).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        Assert:IsTrue(mGame:Brain = ?).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID FaceTurnsTheBuddyInTurnButOnlyWhileItStandsInATurn():
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), BuddySetup:Default()).
        mGame:Face(-1).
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames()).
        mGame:Face(-1).
        Assert:Equals(-1, mGame:CurrentBuddy:Facing).
        mGame:Face(1).
        Assert:Equals(1, mGame:CurrentBuddy:Facing).
        mGame:CurrentBuddy:State = BuddyState:Airborne.
        mGame:Face(-1).
        Assert:Equals(1, mGame:CurrentBuddy:Facing).
    END METHOD.

END CLASS.
