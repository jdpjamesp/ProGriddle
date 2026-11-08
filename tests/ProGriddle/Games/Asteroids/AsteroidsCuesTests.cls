/* The cue source of Asteroids, with real games driven frame by frame: each event is reported once, the title screen is silent, a
   rock's size chooses its sound, and the thrust and the saucers are loops. Cue numbers are INTEGER(AsteroidsCue:...). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsCuesTests:

    VAR PRIVATE AsteroidsGame mGame.
    VAR PRIVATE AsteroidsCues mCues.

    @Setup.
    METHOD PUBLIC VOID BuildCues():
        mGame = AsteroidsFactory:Create(NEW SeededRandom(7)).
        mGame:Drawing = FALSE.
        mCues = NEW AsteroidsCues().
        /* the first look takes the title screen as it is */
        mCues:Poll(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCues():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
        mCues = ?.
    END METHOD.

    METHOD PRIVATE CHARACTER N(INPUT poCue AS AsteroidsCue):
        RETURN STRING(INTEGER(poCue)).
    END METHOD.

    /* True when the list of cues has the cue in it. */
    METHOD PRIVATE LOGICAL Has(INPUT pcCues AS CHARACTER, INPUT poCue AS AsteroidsCue):
        RETURN LOOKUP(N(poCue), pcCues) > 0.
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        VAR INTEGER i.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* A game in play with no rocks and the ship's protection over, and the cues up to date. */
    METHOD PRIVATE VOID EmptySky():
        VAR INTEGER i.
        mGame:StartGame().
        mGame:SkipIntro().
        DO i = 1 TO 60:
            mGame:Rocks:Clear().
            mGame:Rocks:Add(2 * 4096, 2 * 4096, 0, 0, 3, 0, 0, 1000, 1).
            mGame:Advance().
        END.
        mGame:Rocks:Clear().
        mCues:Poll(mGame).
    END METHOD.

    /* Puts a rock of a size straight above the ship, fires and plays until it breaks: returns every cue heard. */
    METHOD PRIVATE CHARACTER BreakARock(INPUT piSize AS INTEGER):
        VAR INTEGER n.
        VAR CHARACTER heardAll.
        EmptySky().
        mGame:Rocks:Add(160 * 4096, 90 * 4096, 0, 0, piSize, 0, 0, 1000, 1).
        mGame:FireHeld = TRUE.
        DO WHILE mGame:RocksBroken = 0 AND n < 20:
            mGame:Advance().
            mGame:FireHeld = FALSE.
            heardAll = heardAll + (IF heardAll = "" THEN "" ELSE ",") + mCues:Poll(mGame).
            n = n + 1.
        END.
        RETURN heardAll.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleScreenAndTheStartOfAGameAreSilent():
        VAR INTEGER i.
        DO i = 1 TO 5:
            mGame:Advance().
            Assert:Equals("", mCues:Poll(mGame)).
        END.
        mGame:StartGame().
        mGame:SkipIntro().
        Assert:Equals("", mCues:Poll(mGame)).
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipsShotIsOneFireCueAndIsReportedOnce():
        EmptySky().
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mGame:FireHeld = FALSE.
        Assert:Equals(N(AsteroidsCue:Fire), mCues:Poll(mGame)).
        mGame:Advance().
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALargeRockBreakingBoomsAndTheShotThatDidItIsHeardToo():
        VAR CHARACTER cues.
        cues = BreakARock(1).
        Assert:IsTrue(Has(cues, AsteroidsCue:Fire)).
        Assert:IsTrue(Has(cues, AsteroidsCue:RockLarge)).
        Assert:IsFalse(Has(cues, AsteroidsCue:RockMedium)).
        Assert:IsFalse(Has(cues, AsteroidsCue:RockSmall)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMediumRockHasItsOwnSound():
        VAR CHARACTER cues.
        cues = BreakARock(2).
        Assert:IsTrue(Has(cues, AsteroidsCue:RockMedium)).
        Assert:IsFalse(Has(cues, AsteroidsCue:RockLarge)).
        Assert:IsFalse(Has(cues, AsteroidsCue:RockSmall)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASmallRockHasItsOwnSound():
        VAR CHARACTER cues.
        cues = BreakARock(3).
        Assert:IsTrue(Has(cues, AsteroidsCue:RockSmall)).
        Assert:IsFalse(Has(cues, AsteroidsCue:RockLarge)).
        Assert:IsFalse(Has(cues, AsteroidsCue:RockMedium)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipBreakingUpIsOneShipDiesCueAndComesFirst():
        VAR CHARACTER cues.
        EmptySky().
        mGame:Rocks:Add(160 * 4096, 120 * 4096, 0, 0, 1, 0, 0, 1000, 1).
        mGame:Advance().
        cues = mCues:Poll(mGame).
        Assert:Equals(2, mGame:Lives).
        Assert:Equals(N(AsteroidsCue:ShipDies), ENTRY(1, cues)).
        mGame:Rocks:Clear().
        mGame:Advance().
        Assert:IsFalse(Has(mCues:Poll(mGame), AsteroidsCue:ShipDies)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnExtraShipAtTenThousandPointsIsAFanfare():
        EmptySky().
        mGame:AddScore(9999).
        Assert:Equals("", mCues:Poll(mGame)).
        mGame:AddScore(1).
        Assert:Equals(N(AsteroidsCue:ExtraShip), mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HyperspaceIsOneCueAtTheStartOfTheJump():
        VAR INTEGER i.
        VAR INTEGER jumps.
        EmptySky().
        mGame:Hyperspace().
        DO i = 1 TO 60:
            mGame:Advance().
            IF Has(mCues:Poll(mGame), AsteroidsCue:Hyperspace) THEN jumps = jumps + 1.
        END.
        Assert:Equals(1, jumps).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucersShotIsOneSaucerFireCueEach():
        VAR INTEGER i.
        VAR INTEGER heard.
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        DO i = 1 TO 600:
            mGame:Rocks:Clear().
            mGame:Advance().
            IF Has(mCues:Poll(mGame), AsteroidsCue:SaucerFire) THEN heard = heard + 1.
            IF mGame:SaucerShotsFired >= 1 THEN LEAVE.
        END.
        Assert:Equals(1, mGame:SaucerShotsFired).
        Assert:Equals(1, heard).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerThatIsShotIsASaucerDiesCue():
        VAR INTEGER n.
        VAR CHARACTER cues.
        VAR CHARACTER heardAll.
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        mGame:PlaceSaucer(160, 90).
        mGame:FireHeld = TRUE.
        DO WHILE mGame:SaucersDestroyed = 0 AND n < 20:
            mGame:Advance().
            mGame:FireHeld = FALSE.
            heardAll = heardAll + (IF heardAll = "" THEN "" ELSE ",") + mCues:Poll(mGame).
            n = n + 1.
        END.
        Assert:IsTrue(Has(heardAll, AsteroidsCue:SaucerDies)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASaucerThatFliesIntoARockIsOneSoundNotTwo():
        VAR RecordingSoundPlayer oPlayer.
        VAR SoundRenderer oRenderer.
        EmptySky().
        oPlayer = NEW RecordingSoundPlayer().
        oRenderer = NEW SoundRenderer(NEW RecordingRenderer(), mCues, oPlayer).
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        mGame:PlaceSaucer(60, 60).
        mGame:Rocks:Add(60 * 4096, 60 * 4096, 0, 0, 1, 0, 0, 1000, 1).
        mGame:Advance().
        oRenderer:Render(mGame:Grid, mGame).
        Assert:Equals(N(AsteroidsCue:SaucerDies), oPlayer:Played).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheThrustRumblesWhileTheShipThrustsAndStopsWhenItDoesNot():
        EmptySky().
        Assert:Equals("", mCues:Loops(mGame)).
        mGame:ThrustHeld = TRUE.
        mGame:Advance().
        Assert:Equals(N(AsteroidsCue:ThrustLoop), mCues:Loops(mGame)).
        mGame:ThrustHeld = FALSE.
        mGame:Advance().
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EachSaucerHumsInItsOwnPitchAndAPausedGameHasNoLoops():
        EmptySky().
        mGame:LaunchSaucerAt(TRUE, 1, 100).
        Assert:Equals(N(AsteroidsCue:SaucerLargeHum), mCues:Loops(mGame)).
        mGame:ThrustHeld = TRUE.
        mGame:Advance().
        Assert:Equals(N(AsteroidsCue:ThrustLoop) + "," + N(AsteroidsCue:SaucerLargeHum), mCues:Loops(mGame)).
        mGame:Paused = TRUE.
        Assert:Equals("", mCues:Loops(mGame)).
        mGame:Paused = FALSE.
        mGame:PlaceSaucer(400, 100).
        Frames(20).
        mGame:ThrustHeld = FALSE.
        Frames(1).
        mGame:LaunchSaucerAt(FALSE, 1, 100).
        Assert:Equals(N(AsteroidsCue:SaucerSmallHum), mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheRocksOfOneGroupAndTheOthersApartAreGroupedAsDescribed():
        Assert:Equals(mCues:GroupOf(INTEGER(AsteroidsCue:RockLarge)), mCues:GroupOf(INTEGER(AsteroidsCue:RockSmall))).
        Assert:Equals(mCues:GroupOf(INTEGER(AsteroidsCue:RockLarge)), mCues:GroupOf(INTEGER(AsteroidsCue:SaucerDies))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(AsteroidsCue:Fire)) <> mCues:GroupOf(INTEGER(AsteroidsCue:RockLarge))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(AsteroidsCue:ShipDies)) <> mCues:GroupOf(INTEGER(AsteroidsCue:RockLarge))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(AsteroidsCue:SaucerFire)) <> mCues:GroupOf(INTEGER(AsteroidsCue:Fire))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(AsteroidsCue:Hyperspace)) <> mCues:GroupOf(INTEGER(AsteroidsCue:ExtraShip))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGameThatIsNotAsteroidsThrowsGridException():
        VAR INTEGER thrown.
        VAR CountingGame oOther = NEW CountingGame(NEW Grid(NEW ArrayStore(2, 2, "state")), 0).
        DO ON ERROR UNDO, THROW:
            mCues:Poll(oOther).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mCues:Loops(oOther).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    /* End to end: the shot and the thrust loop of a real game, through the renderer, reach the player. */
    @Test.
    METHOD PUBLIC VOID TheSoundRendererPlaysTheShotAndLoopsTheThrustOfARealGame():
        VAR RecordingSoundPlayer oPlayer.
        VAR SoundRenderer oRenderer.
        oPlayer = NEW RecordingSoundPlayer().
        oRenderer = NEW SoundRenderer(NEW RecordingRenderer(), mCues, oPlayer).
        EmptySky().
        mGame:FireHeld = TRUE.
        mGame:ThrustHeld = TRUE.
        mGame:Advance().
        oRenderer:Render(mGame:Grid, mGame).
        Assert:Equals(N(AsteroidsCue:Fire), oPlayer:Played).
        Assert:Equals(N(AsteroidsCue:ThrustLoop), oPlayer:Looping).
        mGame:FireHeld = FALSE.
        mGame:ThrustHeld = FALSE.
        mGame:Advance().
        oRenderer:Render(mGame:Grid, mGame).
        Assert:Equals("", oPlayer:Looping).
    END METHOD.

END CLASS.
