/* The picture of the match: the canvas is handed to the window's renderer, the pitch is drawn for the goal being attacked, the score
   bar and the ticker show what the highlights have reached, and the close up opens for a shot. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballPainterTests:

    VAR PRIVATE FootballGame mGame.
    VAR PRIVATE FootballPainter mPainter.
    VAR PRIVATE RecordingRenderer mInner.

    @TearDown.
    METHOD PUBLIC VOID ReleaseAll():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mPainter = ?.
        mGame = ?.
    END METHOD.

    /* A game in the Match phase, the highlights at the start, for the seed given; the first attack is the home side's if piTeam is 1 and the away side's if 2: the seeds are tried until one is. Returns false if none of the first 200 seeds fits. */
    METHOD PRIVATE LOGICAL MatchWithFirstAttackBy(INPUT piTeam AS INTEGER):
        VAR INTEGER seed.
        DO seed = 1 TO 200:
            mGame = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(seed)).
            mGame:StartNewGame("Bob", 1, 3, 7).
            mGame:World:Cash = 1000000.
            mGame:Continue().
            mGame:KickOff().
            IF mGame:Played:AttackAt(1):Team = piTeam THEN
            DO:
                mInner = NEW RecordingRenderer().
                mPainter = NEW FootballPainter(mInner, mGame).
                RETURN TRUE.
            END.
            mGame:Dispose().
        END.
        RETURN FALSE.
    END METHOD.

    METHOD PRIVATE LOGICAL Refused(INPUT pcWhat AS CHARACTER):
        VAR LOGICAL refused.
        DO ON ERROR UNDO, THROW:
            CASE pcWhat:
                WHEN "norenderer" THEN NEW FootballPainter(?, mGame).
                WHEN "nogame" THEN NEW FootballPainter(NEW RecordingRenderer(), ?).
                WHEN "wronggame" THEN mPainter:Render(mGame:Grid, ?).
            END CASE.
            CATCH e AS GridException:
                refused = TRUE.
            END CATCH.
        END.
        RETURN refused.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RenderingHandsTheCanvasToTheWindowsRenderer():
        Assert:IsTrue(MatchWithFirstAttackBy(1)).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(1, mInner:RenderCount).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(2, mInner:RenderCount).
        Assert:Equals(320, mPainter:Canvas:Width).
        Assert:Equals(240, mPainter:Canvas:Height).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreBarAndTheTickerAreTheTunnelColour():
        Assert:IsTrue(MatchWithFirstAttackBy(1)).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:Tunnel)), mPainter:Canvas:ColourAt(2, 2)).
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:Tunnel)), mPainter:Canvas:ColourAt(100, 220)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APitchForTheRightGoalHasMownGrassAtTheLeftAndRunOffBeyondTheGoalLine():
        VAR INTEGER atLeft.
        VAR INTEGER atRight.
        Assert:IsTrue(MatchWithFirstAttackBy(1)).
        mPainter:Render(mGame:Grid, mGame).
        atLeft = mPainter:Canvas:ColourAt(5, 150).
        atRight = mPainter:Canvas:ColourAt(315, 100).
        Assert:IsTrue(atLeft = FootballLook:Colour(FootballTint:GrassA) OR atLeft = FootballLook:Colour(FootballTint:GrassB)).
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:RunOff)), atRight).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APitchForTheLeftGoalIsTheRightGoalsTurnedRound():
        VAR INTEGER atLeft.
        VAR INTEGER atRight.
        Assert:IsTrue(MatchWithFirstAttackBy(2)).
        mPainter:Render(mGame:Grid, mGame).
        atLeft = mPainter:Canvas:ColourAt(5, 100).
        atRight = mPainter:Canvas:ColourAt(315, 150).
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:RunOff)), atLeft).
        Assert:IsTrue(atRight = FootballLook:Colour(FootballTint:GrassA) OR atRight = FootballLook:Colour(FootballTint:GrassB)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStandsAndTheHoardingsAreTheSameForBothGoals():
        VAR INTEGER top.
        Assert:IsTrue(MatchWithFirstAttackBy(2)).
        mPainter:Render(mGame:Grid, mGame).
        top = mPainter:Canvas:ColourAt(100, 18).
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:Roof)), top).
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:Hoarding)), mPainter:Canvas:ColourAt(0, 30)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCloseUpOpensForAShotAndHasTheYellowRing():
        VAR PitchAttack attack.
        VAR INTEGER shotAt.
        Assert:IsTrue(MatchWithFirstAttackBy(1)).
        attack = mGame:Played:AttackAt(1).
        IF attack:Outcome = AttackOutcome:Blocked THEN RETURN.
        /* the ring of a close up over the far corner: yellow at (7, 85) for the right goal, only once the shot has been taken */
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsFalse(mPainter:Canvas:ColourAt(7, 85) = FootballLook:Colour(FootballTint:ChalkYellow)).
        /* the close up opens once the ball has crossed the pitch */
        shotAt = attack:DribbleSteps * Highlights:DribbleMs() + Highlights:ShotMs() + Highlights:RunMs(attack).
        mGame:Tick(shotAt + 100).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(INTEGER(FootballLook:Colour(FootballTint:ChalkYellow)), mPainter:Canvas:ColourAt(7, 85)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryTimeOfAMatchCanBeDrawnToTheEnd():
        VAR INTEGER total.
        VAR INTEGER ms.
        Assert:IsTrue(MatchWithFirstAttackBy(2)).
        total = Highlights:TotalMs(mGame:Played).
        DO ms = 0 TO total BY 250:
            mGame:SkipHighlights().
            mGame:Initialise().
            mGame:StartNewGame("Bob", 1, 3, 7).
            mGame:Continue().
            mGame:KickOff().
            mGame:Tick(ms).
            mPainter:Render(mGame:Grid, mGame).
        END.
        Assert:IsTrue(mInner:RenderCount > 5).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADisposedPainterCanBeDisposedAgain():
        Assert:IsTrue(MatchWithFirstAttackBy(1)).
        mPainter:Dispose().
        mPainter:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThingsThatAreNotAllowedAreRefused():
        Assert:IsTrue(MatchWithFirstAttackBy(1)).
        Assert:IsTrue(Refused("norenderer")).
        Assert:IsTrue(Refused("nogame")).
        Assert:IsTrue(Refused("wronggame")).
    END METHOD.

    /* How many pixels of the prompt's yellow are in the strip under the ticker. */
    METHOD PRIVATE INTEGER PromptPixels():
        VAR INTEGER px.
        VAR INTEGER py.
        VAR INTEGER found.
        DO py = 226 TO 238:
            DO px = 40 TO 280:
                IF mPainter:Canvas:ColourAt(px, py) = INTEGER(FootballLook:Colour(FootballTint:ChalkYellow)) THEN found = found + 1.
            END.
        END.
        RETURN found.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheHighlightsAreOverThePictureSaysHowToGoOn():
        Assert:IsTrue(MatchWithFirstAttackBy(1)).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, PromptPixels()).
        mGame:SkipHighlights().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(PromptPixels() > 40).
    END METHOD.

end CLASS.
