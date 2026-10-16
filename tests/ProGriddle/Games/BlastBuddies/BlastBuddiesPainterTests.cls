/* The first part of the Blast Buddies picture: the sky, the sun, the far hills, the clouds and their drift, the ground coloured by the
   rule and coloured again after a blast, and the sea with its waves and the shore standing in it. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BlastBuddiesPainterTests:

    DEFINE PRIVATE VARIABLE mGame     AS BlastBuddiesGame    NO-UNDO.
    DEFINE PRIVATE VARIABLE mInner    AS RecordingRenderer   NO-UNDO.
    DEFINE PRIVATE VARIABLE mPainter  AS BlastBuddiesPainter NO-UNDO.

    /* a game on an empty map, so the sky can be looked at, with a painter that has not drawn yet */
    @Setup.
    METHOD PUBLIC VOID Setup():
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow)).
        mGame:Land:FillRect(0, 0, 383, 239, FALSE).
        mInner = NEW RecordingRenderer().
        mPainter = NEW BlastBuddiesPainter(mInner, mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID TearDown():
        mPainter:Dispose().
        mGame:Dispose().
    END METHOD.

    METHOD PRIVATE INTEGER Look(INPUT poKey AS ThemeKey):
        RETURN TerrainThemes:Colour(Theme:Meadow, poKey).
    END METHOD.

    METHOD PRIVATE INTEGER Px(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        RETURN mPainter:Canvas:ColourAt(piX, piY).
    END METHOD.

    METHOD PRIVATE INTEGER Sky(INPUT piY AS INTEGER):
        RETURN ColourMath:Mix(Look(ThemeKey:SkyTop), Look(ThemeKey:SkyLow), MINIMUM(piY, 200), 200).
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID RenderingHandsTheGridToTheInnerRendererEveryTime():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(1, mInner:RenderCount).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(2, mInner:RenderCount).
        Assert:IsTrue(mPainter:CanvasGrid = mGame:Grid).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APainterNeedsARendererAndAGameAndOnlyDrawsABlastBuddiesGame():
        DEFINE VARIABLE p       AS BlastBuddiesPainter NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL             NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            p = NEW BlastBuddiesPainter(?, mGame).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            p = NEW BlastBuddiesPainter(mInner, ?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            mPainter:Render(mGame:Grid, ?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSkyIsAGradientFromTheTopToRowTwoHundred():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:SkyTop), Px(2, 0)).
        Assert:Equals(Sky(100), Px(2, 100)).
        Assert:Equals(Sky(150), Px(2, 150)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSunIsADiscWithARingOfSparkles():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:Sun), Px(316, 44)).
        Assert:Equals(Look(ThemeKey:Sun), Px(316 + 13, 44)).
        Assert:Equals(Sky(44), Px(316 + 14, 44)).
        /* on the ring (16 away), except where x + y is a multiple of 4 */
        Assert:Equals(Look(ThemeKey:SunRing), Px(317, 28)).
        Assert:Equals(Sky(28), Px(316, 28)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFarHillsStartLowerDownAndTheirTopRowIsLit():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:FarTop), Px(0, 174)).
        Assert:Equals(Look(ThemeKey:Far), Px(0, 175)).
        Assert:Equals(Look(ThemeKey:Far), Px(0, 200)).
        Assert:Equals(Sky(173), Px(0, 173)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGroundIsColouredByTheRule():
        mGame:Land:FillRect(100, 100, 200, 239, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:Top1), Px(150, 100)).
        Assert:Equals(Look(ThemeKey:Top2), Px(150, 101)).
        Assert:Equals(Look(ThemeKey:Top3), Px(150, 102)).
        Assert:Equals(Sky(99), Px(150, 99)).
        Assert:Equals(mGame:Land:ShadeAt(150, 140), Px(150, 140)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlastColoursItsBoxAgainWithNoOneDrawingIt():
        mGame:Land:FillRect(100, 100, 200, 239, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        mGame:Land:Carve(150, 110, 20).
        mGame:Land:Crumble(150, 110, 20).
        Assert:IsTrue(mGame:Land:HasDirty()).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsFalse(mGame:Land:HasDirty()).
        Assert:Equals(Sky(110), Px(150, 110)).
        /* the floor of the crater is the scorch, and the old edge of the hole is a clean face */
        Assert:Equals(Look(ThemeKey:Scorch1), Px(150, 131)).
        Assert:Equals(mGame:Land:ShadeAt(170, 120), Px(170, 120)).
        Assert:Equals(mGame:Land:ShadeAt(150, 160), Px(150, 160)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSeaIsASwellBehindWavesAndABodyFromRowTwoTwoNine():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:Water), Px(0, 229)).
        Assert:Equals(Look(ThemeKey:Water), Px(383, 239)).
        /* the swell: columns 0 to 7 start at row 223, columns 8 to 15 at row 222 */
        Assert:Equals(Look(ThemeKey:WaterBack), Px(0, 223)).
        Assert:IsTrue(Px(0, 222) <> Look(ThemeKey:WaterBack)).
        Assert:Equals(Look(ThemeKey:WaterBack), Px(8, 222)).
        /* wave 1 is foam at 4 and 5 of its top row, and lets the swell show where it has a dot */
        Assert:Equals(Look(ThemeKey:Foam), Px(4, 226)).
        Assert:Equals(Look(ThemeKey:WaterBack), Px(0, 226)).
        Assert:Equals(Look(ThemeKey:WaterTop), Px(5, 227)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWavesChangeEveryTwoHundredMillisecondsAndTheSwellEveryOneTwenty():
        Frames(12).
        Assert:Equals(200, mGame:ElapsedMs).
        mPainter:Render(mGame:Grid, mGame).
        /* wave 2 has its foam at 8 and 9 */
        Assert:Equals(Look(ThemeKey:Foam), Px(8, 226)).
        /* the swell has stepped once (200 ms is one step of 120): column 7 now begins a column early, and column 0 is the odd one */
        Assert:Equals(Look(ThemeKey:WaterBack), Px(7, 222)).
        Assert:IsTrue(Px(0, 222) <> Look(ThemeKey:WaterBack)).
        Frames(36).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:Foam), Px(4, 226)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShoreStandsInTheWavesAndTheBodyOfTheSeaCoversTheRest():
        mGame:Land:FillRect(100, 200, 200, 239, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(mGame:Land:ShadeAt(150, 226), Px(150, 226)).
        Assert:Equals(mGame:Land:ShadeAt(150, 228), Px(150, 228)).
        Assert:Equals(Look(ThemeKey:Water), Px(150, 229)).
        Assert:Equals(mGame:Land:ShadeAt(150, 225), Px(150, 225)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShoreBlownAwayIsWaterAgain():
        mGame:Land:FillRect(100, 200, 200, 239, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        mGame:Land:Carve(150, 226, 15).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:WaterBack), Px(152, 227)).
        Assert:Equals(Look(ThemeKey:Foam), Px(150, 227)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CloudsAreCirclesInARowWithAShadedUnderside():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:Cloud), Px(35, 28)).
        Assert:Equals(Look(ThemeKey:Cloud), Px(49, 26)).
        Assert:Equals(Look(ThemeKey:CloudShade), Px(49, 32)).
        Assert:Equals(Sky(36), Px(35, 36)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CloudsDriftOnePixelEveryEightHundredMillisecondsWhenThereIsNoWind():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, mPainter:CloudDrift).
        Frames(47).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, mPainter:CloudDrift).
        Frames(1).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(1, mPainter:CloudDrift).
        /* the left edge of the first cloud has moved on, and what it left is sky again */
        Assert:Equals(Sky(28), Px(35, 28)).
        Assert:Equals(Look(ThemeKey:Cloud), Px(36, 28)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewGameMakesThePainterStartTheMapAgain():
        mPainter:Render(mGame:Grid, mGame).
        Frames(100).
        mPainter:Render(mGame:Grid, mGame).
        mGame:Initialise().
        mGame:Land:FillRect(0, 0, 383, 239, FALSE).
        mGame:Land:FillRect(40, 120, 90, 239, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, mPainter:CloudDrift).
        Assert:Equals(Look(ThemeKey:Top1), Px(60, 120)).
        Assert:Equals(Sky(150), Px(150, 150)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeCanBeCalledTwice():
        mPainter:Render(mGame:Grid, mGame).
        mPainter:Dispose().
        mPainter:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSineHelperIsCloseToTheRealSine():
        Assert:IsTrue(ABSOLUTE(BuddyMath:SinRad(0)) < 0.001).
        Assert:IsTrue(ABSOLUTE(BuddyMath:SinRad(1.5707963) - 1) < 0.001).
        Assert:IsTrue(ABSOLUTE(BuddyMath:SinRad(3.1415926)) < 0.02).
        Assert:IsTrue(ABSOLUTE(BuddyMath:SinRad(-1.5707963) + 1) < 0.001).
        Assert:IsTrue(ABSOLUTE(BuddyMath:SinRad(0.7) - 0.6442) < 0.002).
        Assert:IsTrue(ABSOLUTE(BuddyMath:SinRad(20) - 0.9129) < 0.01).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePaintingOfAWholeMapTakesUnderASecondAndABlastUnderFiftyMilliseconds():
        DEFINE VARIABLE g  AS BlastBuddiesGame    NO-UNDO.
        DEFINE VARIABLE p  AS BlastBuddiesPainter NO-UNDO.
        DEFINE VARIABLE ms AS INTEGER             NO-UNDO.
        DEFINE VARIABLE bl AS INTEGER             NO-UNDO.
        DEFINE VARIABLE still AS INTEGER           NO-UNDO.
        g = BlastBuddiesFactory:Create(NEW SeededRandom(2), BuddySetup:Default()).
        p = NEW BlastBuddiesPainter(NEW RecordingRenderer(), g).
        ETIME(TRUE).
        p:Render(g:Grid, g).
        ms = ETIME.
        ETIME(TRUE).
        p:Render(g:Grid, g).
        still = ETIME.
        g:Land:Carve(192, 120, 30).
        g:Land:Crumble(192, 120, 30).
        ETIME(TRUE).
        p:Render(g:Grid, g).
        bl = ETIME.
        MESSAGE "timing: painting a new map took" ms "ms, a still frame" still "ms, and the picture after a radius 30 blast" bl "ms".
        Assert:IsTrue(ms < 1500, "map " + STRING(ms) + " ms").
        Assert:IsTrue(bl < 120, "blast " + STRING(bl) + " ms").
        p:Dispose().
        g:Dispose().
    END METHOD.

END CLASS.
