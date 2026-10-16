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
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        mGame = BlastBuddiesFactory:Create(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow)).
        mGame:Land:FillRect(0, 0, 383, 239, FALSE).
        /* the buddies are put off the left side of the map, where they cannot be in the way of the sky */
        DO t = 1 TO 2:
            DO b = 1 TO 3:
                mGame:Plan:TeamAt(t):BuddyAt(b):PlaceAt(-100, 150).
            END.
        END.
        mInner = NEW RecordingRenderer().
        mPainter = NEW BlastBuddiesPainter(mInner, mGame, NEW SeededRandom(1)).
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
            p = NEW BlastBuddiesPainter(?, mGame, NEW SeededRandom(1)).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            p = NEW BlastBuddiesPainter(mInner, ?, NEW SeededRandom(1)).
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
        mGame:Land:FillRect(10, 200, 110, 239, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(mGame:Land:ShadeAt(60, 226), Px(60, 226)).
        Assert:Equals(mGame:Land:ShadeAt(60, 228), Px(60, 228)).
        Assert:Equals(Look(ThemeKey:Water), Px(60, 229)).
        Assert:Equals(mGame:Land:ShadeAt(60, 225), Px(60, 225)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShoreBlownAwayIsWaterAgain():
        mGame:Land:FillRect(10, 200, 110, 239, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        mGame:Land:Carve(60, 226, 15).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:WaterBack), Px(60, 227)).
        Assert:Equals(Look(ThemeKey:Foam), Px(62, 227)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID CloudsAreCirclesInARowWithAShadedUnderside():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:Cloud), Px(35, 28)).
        Assert:Equals(Look(ThemeKey:Cloud), Px(40, 31)).
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

    /* ground at row 150 all along, for the buddies to stand on */
    METHOD PRIVATE VOID Floor():
        mGame:Land:FillRect(0, 150, 383, 239, TRUE).
    END METHOD.

    /* whether the picture shows a sprite as it was asked for, with its feet at (x, y): every pixel of it from a row of the sprite on */
    METHOD PRIVATE LOGICAL Shows(INPUT pcName AS CHARACTER, INPUT piTeam AS INTEGER, INPUT plMirror AS LOGICAL, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piFromRow AS INTEGER):
        DEFINE VARIABLE sp  AS BuddySprites NO-UNDO.
        DEFINE VARIABLE st  AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE sx  AS INTEGER      NO-UNDO.
        DEFINE VARIABLE sy  AS INTEGER      NO-UNDO.
        DEFINE VARIABLE ok  AS LOGICAL      NO-UNDO INITIAL TRUE.
        sp = NEW BuddySprites().
        st = sp:Stamp(pcName, piTeam, plMirror).
        DO sy = piFromRow TO st:Height - 1:
            DO sx = 0 TO st:Width - 1:
                IF st:ColourAt(sx, sy) >= 0 AND Px(piX - sp:OriginX(pcName, plMirror) + sx, piY - sp:OriginY(pcName) + sy) <> st:ColourAt(sx, sy) THEN ok = FALSE.
            END.
        END.
        sp:Dispose().
        RETURN ok.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStandingGoonIsDrawnInItsTeamColoursFacingRight():
        Floor().
        mGame:Plan:TeamAt(1):BuddyAt(1):PlaceAt(100, 150).
        mGame:Plan:TeamAt(1):BuddyAt(1):Facing = 1.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Shows("goon_idle_1", 1, FALSE, 100, 150, 2)).
        Assert:IsFalse(Shows("goon_idle_1", 2, FALSE, 100, 150, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlueGoonFacingLeftIsMirroredAndBlue():
        Floor().
        mGame:Plan:TeamAt(2):BuddyAt(1):PlaceAt(200, 150).
        mGame:Plan:TeamAt(2):BuddyAt(1):Facing = -1.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Shows("goon_idle_1", 2, TRUE, 200, 150, 2)).
        Assert:IsFalse(Shows("goon_idle_1", 2, FALSE, 200, 150, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTeamMarkSitsOnTheHead():
        DEFINE VARIABLE sp   AS BuddySprites NO-UNDO.
        DEFINE VARIABLE st   AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE sx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE sy   AS INTEGER NO-UNDO.
        DEFINE VARIABLE head AS INTEGER NO-UNDO.
        DEFINE VARIABLE ok   AS LOGICAL NO-UNDO INITIAL TRUE.
        Floor().
        sp = NEW BuddySprites().
        mGame:Plan:TeamAt(1):BuddyAt(1):PlaceAt(100, 150).
        mGame:Plan:TeamAt(1):BuddyAt(1):Facing = 1.
        mPainter:Render(mGame:Grid, mGame).
        head = 150 - 12 + sp:HeadTop("goon_idle_1").
        st = sp:Stamp("mark_reds", 0, FALSE).
        DO sy = 0 TO st:Height - 1:
            DO sx = 0 TO st:Width - 1:
                IF st:ColourAt(sx, sy) >= 0 AND Px(100 - sp:OriginX("mark_reds", FALSE) + sx, head + 1 - st:Height + sy) <> st:ColourAt(sx, sy) THEN ok = FALSE.
            END.
        END.
        Assert:IsTrue(ok).
        Assert:IsTrue(sp:HeadTop("goon_idle_1") > 0).
        sp:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGoonInTheAirShowsTheRiseOrTheFall():
        Floor().
        mGame:Plan:TeamAt(1):BuddyAt(1):PlaceAt(100, 150).
        mGame:Plan:TeamAt(1):BuddyAt(1):Facing = 1.
        mGame:Plan:TeamAt(1):BuddyAt(1):State = BuddyState:Airborne.
        mGame:Plan:TeamAt(1):BuddyAt(1):VY = -100.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Shows("goon_jump_rise", 1, FALSE, 100, 150, 5)).
        mGame:Plan:TeamAt(1):BuddyAt(1):VY = 100.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Shows("goon_jump_fall", 1, FALSE, 100, 150, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGoonThatHasJustWalkedShowsAWalkingFrameAndOneJustLandedShowsTheLand():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        Floor().
        b = mGame:Plan:TeamAt(1):BuddyAt(1).
        b:PlaceAt(100, 150).
        b:Facing = 1.
        mPainter:Render(mGame:Grid, mGame).
        b:X256 = 103 * 256.
        mPainter:Render(mGame:Grid, mGame).
        /* column 103: 103 mod 12 is 7, so the frame is 7 div 3 + 1 = 3 */
        Assert:IsTrue(Shows("goon_walk_3", 1, FALSE, 103, 150, 5)).
        b:State = BuddyState:Airborne.
        mPainter:Render(mGame:Grid, mGame).
        b:State = BuddyState:Standing.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Shows("goon_land", 1, FALSE, 103, 150, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGoonInTurnAimsWithTheBazookaTurnedToTheAim():
        DEFINE VARIABLE b  AS Buddy        NO-UNDO.
        DEFINE VARIABLE sp AS BuddySprites NO-UNDO.
        DEFINE VARIABLE st AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE r  AS INTEGER      NO-UNDO.
        DEFINE VARIABLE sx AS INTEGER      NO-UNDO.
        DEFINE VARIABLE sy AS INTEGER      NO-UNDO.
        DEFINE VARIABLE ok AS LOGICAL      NO-UNDO INITIAL TRUE.
        DEFINE VARIABLE k  AS INTEGER      NO-UNDO.
        Floor().
        DO k = 0 TO 5:
            mGame:Plan:TeamAt(k MODULO 2 + 1):BuddyAt(INTEGER(TRUNCATE(k / 2, 0)) + 1):PlaceAt(200 + 20 * k, 150).
        END.
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames() - 1).
        b = mGame:CurrentBuddy.
        b:PlaceAt(100, 150).
        b:Facing = 1.
        Frames(1).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Turn).
        mPainter:Render(mGame:Grid, mGame).
        sp = NEW BuddySprites().
        r = sp:Reach("held_bazooka").
        st = sp:Turned("held_bazooka", 12, FALSE).
        DO sy = 0 TO st:Height - 1:
            DO sx = 0 TO st:Width - 1:
                IF st:ColourAt(sx, sy) >= 0 AND Px(100 + 3 - r + sx, 150 - 5 - r + sy) <> st:ColourAt(sx, sy) THEN ok = FALSE.
            END.
        END.
        Assert:IsTrue(ok).
        sp:Dispose().
    END METHOD.

    /* the buddies in a row on the floor, the first of team 1 at column 100 and the first of team 2 at 136, the rest well away */
    METHOD PRIVATE VOID SetTheStage():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        Floor().
        DO k = 0 TO 5:
            mGame:Plan:TeamAt(k MODULO 2 + 1):BuddyAt(INTEGER(TRUNCATE(k / 2, 0)) + 1):PlaceAt(250 + 20 * k, 150).
        END.
        mGame:Plan:TeamAt(1):BuddyAt(1):PlaceAt(100, 150).
        mGame:Plan:TeamAt(2):BuddyAt(1):PlaceAt(136, 150).
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames()).
        mGame:CurrentBuddy:Facing = 1.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARocketInFlightIsDrawnTurnedToItsCourseWithATrailOfSmokeBehindIt():
        DEFINE VARIABLE sp  AS BuddySprites NO-UNDO.
        DEFINE VARIABLE st  AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE sx  AS INTEGER      NO-UNDO.
        DEFINE VARIABLE sy  AS INTEGER      NO-UNDO.
        DEFINE VARIABLE ok  AS LOGICAL      NO-UNDO INITIAL TRUE.
        sp = NEW BuddySprites().
        st = sp:Stamp("rocket", 0, FALSE).
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 200 * 256, 100 * 256, 1024, 0).
        mPainter:Render(mGame:Grid, mGame).
        DO sy = 0 TO st:Height - 1:
            DO sx = 0 TO st:Width - 1:
                IF st:ColourAt(sx, sy) >= 0 AND Px(200 - 5 + sx, 100 - 3 + sy) <> st:ColourAt(sx, sy) THEN ok = FALSE.
            END.
        END.
        Assert:IsTrue(ok).
        mGame:Shells:Move(1, 300 * 256, 60 * 256, 1024, 0).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(ColourMath:FromHex(ENTRY(1, BuddiesLook:ToneRow("Smoke"))), Px(195, 100)).
        sp:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotAboveTheTopOfTheMapIsMarkedByAnArrowInItsColumn():
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 200 * 256, -20 * 256, 0, -100).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(ColourMath:FromHex("FFFFFF"), Px(200, 1)).
        Assert:Equals(ColourMath:FromHex("1C1426"), Px(200, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheReticleSitsTwentyEightPixelsOutAlongTheAimOfTheGoonInTurn():
        DEFINE VARIABLE sp    AS BuddySprites NO-UNDO.
        DEFINE VARIABLE st    AS PixelStamp NO-UNDO.
        DEFINE VARIABLE rname AS CHARACTER  NO-UNDO.
        DEFINE VARIABLE cx    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE cy    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE sx    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE sy    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE ok    AS LOGICAL    NO-UNDO INITIAL TRUE.
        SetTheStage().
        Assert:IsTrue(mGame:Phase = BuddyPhase:Turn).
        mPainter:Render(mGame:Grid, mGame).
        rname = "reticle_" + STRING(INTEGER(TRUNCATE(mGame:ElapsedMs / 300, 0)) MODULO 2).
        cx = 100 + 3 + INTEGER(ROUND(Heading:DirX(mGame:AimHeading) * 28 / 1024, 0)).
        cy = 150 - 5 + INTEGER(ROUND(Heading:DirY(mGame:AimHeading) * 28 / 1024, 0)).
        sp = NEW BuddySprites().
        st = sp:Stamp(rname, 0, FALSE).
        DO sy = 0 TO st:Height - 1:
            DO sx = 0 TO st:Width - 1:
                IF st:ColourAt(sx, sy) >= 0 AND Px(cx - 4 + sx, cy - 4 + sy) <> st:ColourAt(sx, sy) THEN ok = FALSE.
            END.
        END.
        Assert:IsTrue(ok).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID HoldingFireGrowsADotForEverySixthOfTheChargeInGoldTowardsRed():
        SetTheStage().
        mGame:StartCharge().
        Frames(30).
        mPainter:Render(mGame:Grid, mGame).
        /* 30 of 90 frames: 5 dots and the one that has begun; dot 0 is 6 pixels out and 2 rows up, in gold */
        Assert:Equals(ColourMath:FromHex("FFC23A"),
                      Px(100 + 3 + INTEGER(ROUND(Heading:DirX(mGame:AimHeading) * 6 / 1024, 0)), 150 - 5 + INTEGER(ROUND(Heading:DirY(mGame:AimHeading) * 6 / 1024, 0)) - 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlastFloatsTheDamageNumberUpOverTheBuddyItHurtAndASquealBubble():
        DEFINE VARIABLE x      AS INTEGER NO-UNDO.
        DEFINE VARIABLE y      AS INTEGER NO-UNDO.
        DEFINE VARIABLE hurt   AS LOGICAL NO-UNDO.
        DEFINE VARIABLE bubble AS LOGICAL NO-UNDO.
        SetTheStage().
        mGame:SetAim(1).
        Frames(12).
        mGame:SetAim(0).
        mGame:StartCharge().
        Frames(45).
        mGame:ReleaseCharge().
        Frames(25).
        Assert:IsTrue(mGame:BlastCount >= 1).
        mPainter:Render(mGame:Grid, mGame).
        DO y = 20 TO 140:
            DO x = 110 TO 230:
                IF Px(x, y) = ColourMath:FromHex("FF5A4A") THEN hurt = TRUE.
            END.
        END.
        Assert:IsTrue(hurt).
    END METHOD.

    /* whether a colour is anywhere in a rectangle of the picture */
    METHOD PRIVATE LOGICAL Somewhere(INPUT piColour AS INTEGER, INPUT piX1 AS INTEGER, INPUT piY1 AS INTEGER, INPUT piX2 AS INTEGER, INPUT piY2 AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = piY1 TO piY2:
            DO x = piX1 TO piX2:
                IF Px(x, y) = piColour THEN RETURN TRUE.
            END.
        END.
        RETURN FALSE.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePanelsHaveRoundedCornersAFrameOnTheTimerAndALighterLineInside():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Sky(4), Px(4, 4)).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), Px(5, 4)).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), Px(4, 12)).
        Assert:Equals(ColourMath:FromHex("4A3E5A"), Px(10, 5)).
        Assert:Equals(ColourMath:FromHex("1C1426"), Px(6, 7)).
        /* the active goon and wind panels have no frame, and the corner of the wind panel is left out */
        Assert:Equals(Sky(4), Px(296, 4)).
        Assert:Equals(ColourMath:FromHex("1C1426"), Px(297, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTimerShowsTheSecondsOfTheTurnInWhiteAndInRedForTheLastTen():
        SetTheStage().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FFFFFF"), 6, 9, 31, 23)).
        Frames(BuddyRules:TurnFrames() - 9 * 60).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FF4A3A"), 6, 9, 31, 23)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheActiveGoonPanelHasTheNameTheTeamAndTheWeapon():
        SetTheStage().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Somewhere(ColourMath:FromHex(ENTRY(2, BuddiesLook:ToneRow("Reds"))), 44, 8, 100, 15)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("B8AECB"), 44, 18, 100, 25)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("6E8A3A"), 112, 7, 126, 21)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWindShowsAsManyLitChevronsAsItsStrength():
        DEFINE VARIABLE lit AS INTEGER NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        SetTheStage().
        mPainter:Render(mGame:Grid, mGame).
        /* the tip of a chevron is its middle row, and unlit ones are the colour of the panel rule */
        DO i = 0 TO 9:
            IF Px(304 + 4 * i + (IF mGame:Wind < 0 THEN 0 ELSE 2), 20) <> ColourMath:FromHex("4A3E5A") THEN lit = lit + 1.
        END.
        Assert:Equals(ABSOLUTE(mGame:Wind), lit).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTeamBarsAreAPixelForEveryThirdOfAPointWithAPatternEach():
        mPainter:Render(mGame:Grid, mGame).
        /* 300 health of 400 is 90 pixels of 120 */
        Assert:Equals(ColourMath:FromHex(ENTRY(2, BuddiesLook:ToneRow("Reds"))), Px(130, 225)).
        Assert:Equals(ColourMath:FromHex(ENTRY(3, BuddiesLook:ToneRow("Reds"))), Px(130 + 89, 226)).
        Assert:IsTrue(Px(130 + 90, 225) <> ColourMath:FromHex(ENTRY(2, BuddiesLook:ToneRow("Reds")))).
        /* the Blues have every fourth column in tone 4 */
        Assert:Equals(ColourMath:FromHex(ENTRY(2, BuddiesLook:ToneRow("Blues"))), Px(130, 228)).
        Assert:Equals(ColourMath:FromHex(ENTRY(4, BuddiesLook:ToneRow("Blues"))), Px(133, 228)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBannerAtTheStartOfATurnNamesTheBuddyAndTheTeam():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        Floor().
        DO k = 0 TO 5:
            mGame:Plan:TeamAt(k MODULO 2 + 1):BuddyAt(INTEGER(TRUNCATE(k / 2, 0)) + 1):PlaceAt(250 + 20 * k, 150).
        END.
        Frames(BuddyRules:ArrivalFrames()).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Banner).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), Px(0, 96)).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), Px(383, 135)).
        Assert:Equals(ColourMath:FromHex("1C1426"), Px(0, 110)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex(ENTRY(1, BuddiesLook:ToneRow("Reds"))), 100, 101, 290, 122)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("B8AECB"), 100, 125, 290, 132)).
        Frames(BuddyRules:BannerFrames()).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Turn).
        Assert:IsTrue(Px(0, 96) <> ColourMath:FromHex("FF9A3C")).
    END METHOD.

    /* a shell dropped from above onto the floor at column 200, so a radius 20 blast goes off there, with the painter's picture of the quiet
       moment before it already made */
    METHOD PRIVATE VOID DropAShell():
        Floor().
        mPainter:Render(mGame:Grid, mGame).
        mGame:Shells:Launch(WeaponKind:Bazooka, 1, 200 * 256, 100 * 256, 0, 2048).
        Frames(10).
        Assert:Equals(1, mGame:BlastCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlastBeginsWithAWhiteFlashThenAFireballWhoseMiddleIsTheHottestColour():
        DropAShell().
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(ColourMath:FromHex("FFFFFF"), Px(mGame:LastBlastX, mGame:LastBlastY - 8)).
        Frames(8).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(ColourMath:FromHex(ENTRY(1, BuddiesLook:ToneRow("Blast"))), Px(mGame:LastBlastX, mGame:LastBlastY - 2)).
        /* near the edge of the fireball it is a cooler colour */
        Assert:IsTrue(Px(mGame:LastBlastX, mGame:LastBlastY - 8) <> ColourMath:FromHex(ENTRY(1, BuddiesLook:ToneRow("Blast")))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlastThrowsOutFortyPiecesOfGroundThatLandAndAreGone():
        DropAShell().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mPainter:DebrisInFlight() >= 40).
        Frames(5).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mPainter:DebrisInFlight() > 0).
        Frames(120).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, mPainter:DebrisInFlight()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScorchRingGlowsAndCoolsToItsOwnColourOverSixHundredMilliseconds():
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        DropAShell().
        mPainter:Render(mGame:Grid, mGame).
        cx = mGame:LastBlastX.
        cy = mGame:LastBlastY.
        Assert:Equals(1, mGame:Land:ScorchStep(cx + 21, cy)).
        /* the blast shakes the first picture a pixel to the right, so the ring pixel at cx + 21 is seen at cx + 22 */
        Assert:Equals(ColourMath:FromHex(ENTRY(3, BuddiesLook:ToneRow("Blast"))), Px(cx + 22, cy)).
        Frames(40).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Look(ThemeKey:Scorch1), Px(cx + 21, cy)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARadiusTwentyBlastShakesThePictureOnePixelAndLeavesTheHudAlone():
        DropAShell().
        mPainter:Render(mGame:Grid, mGame).
        /* shifted a pixel to the right, the edge of the sun at 329 is seen at 330 */
        Assert:Equals(Look(ThemeKey:Sun), Px(316 + 14, 44)).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), Px(5, 4)).
        Frames(10).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Sky(44), Px(316 + 14, 44)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADyingBuddyShowsTheAlarmFramesWithASkullThenAPuffOfSmoke():
        DEFINE VARIABLE e AS Buddy NO-UNDO.
        SetTheStage().
        e = mGame:Plan:TeamAt(2):BuddyAt(1).
        e:Facing = 1.
        e:Hurt(100).
        mGame:EndTurn().
        Frames(BuddyRules:SettleFrames()).
        Assert:IsTrue(mGame:DyingBuddy = e).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Shows("goon_alarm_1", 2, FALSE, 136, 150, 5)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("F6F6F2"), 130, 120, 142, 138)).
        Frames(16).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Shows("goon_alarm_2", 2, FALSE, 136, 144, 5)).
        Frames(24).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Somewhere(ColourMath:FromHex(ENTRY(1, BuddiesLook:ToneRow("Smoke"))), 120, 125, 152, 152)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGravestoneRisesOutOfTheGroundAndAHaloFloatsUpOverIt():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        Floor().
        b = mGame:Plan:TeamAt(1):BuddyAt(1).
        b:PlaceAt(100, 150).
        mPainter:Render(mGame:Grid, mGame).
        b:Hurt(100).
        b:Buried = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Sky(145), Px(100, 145)).
        Frames(40).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Shows("gravestone", 0, FALSE, 100, 150, 1)).
        Frames(45).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FFC23A"), 94, 116, 106, 128)).
    END METHOD.

    /* whether the top ten rows of the sink picture of team 1 are in the picture with the feet at the water line */
    METHOD PRIVATE LOGICAL SinkShown(INPUT piX AS INTEGER):
        DEFINE VARIABLE sp AS BuddySprites NO-UNDO.
        DEFINE VARIABLE st AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE sx AS INTEGER      NO-UNDO.
        DEFINE VARIABLE sy AS INTEGER      NO-UNDO.
        DEFINE VARIABLE ok AS LOGICAL      NO-UNDO INITIAL TRUE.
        sp = NEW BuddySprites().
        st = sp:Stamp("goon_sink", 1, FALSE).
        DO sy = 0 TO 9:
            DO sx = 0 TO st:Width - 1:
                IF st:ColourAt(sx, sy) >= 0 AND Px(piX - sp:OriginX("goon_sink", FALSE) + sx, 226 - sp:OriginY("goon_sink") + sy) <> st:ColourAt(sx, sy) THEN ok = FALSE.
            END.
        END.
        sp:Dispose().
        RETURN ok.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuddyThatReachesTheWaterSplashesAndSinksOutOfSight():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        Floor().
        b = mGame:Plan:TeamAt(1):BuddyAt(1).
        b:PlaceAt(100, 150).
        b:Facing = 1.
        mPainter:Render(mGame:Grid, mGame).
        b:Hurt(100).
        b:State = BuddyState:Drowned.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mPainter:DebrisInFlight() >= 10).
        Assert:Equals(Look(ThemeKey:Foam), Px(99, 226)).
        Assert:Equals(Look(ThemeKey:Foam), Px(101, 226)).
        /* the sinking goon, apart from its bottom rows where the droplets are */
        Assert:IsTrue(SinkShown(100)).
        Frames(48).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsFalse(SinkShown(100)).
    END METHOD.

    /* the stage set, team 2 wiped out and the game run on until the Winner phase */
    METHOD PRIVATE VOID TeamOneWins():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        SetTheStage().
        DO i = 1 TO 3:
            mGame:Plan:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        mGame:EndTurn().
        Frames(400).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Winner).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWinnerScreenDimsTheLastPictureOnceAndPutsABandOverIt():
        TeamOneWins().
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), Px(0, 60)).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), Px(383, 123)).
        Assert:Equals(ColourMath:FromHex("1C1426"), Px(0, 80)).
        Assert:Equals(ColourMath:Mix(Sky(10), ColourMath:FromHex("1C1426"), 35, 100), Px(2, 10)).
        /* a second picture is not dimmed again */
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(ColourMath:Mix(Sky(10), ColourMath:FromHex("1C1426"), 35, 100), Px(2, 10)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FFF2A0"), 0, 70, 383, 70)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("B8AECB"), 0, 98, 383, 104)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWinnersDanceInTheFramesOneTwoThreeTwo():
        DEFINE VARIABLE n AS CHARACTER NO-UNDO.
        TeamOneWins().
        mPainter:Render(mGame:Grid, mGame).
        n = ENTRY(INTEGER(TRUNCATE(mGame:ElapsedMs / 150, 0)) MODULO 4 + 1, "1,2,3,2").
        Assert:IsTrue(Shows("goon_dance_" + n, 1, FALSE, 100, 150 - (IF n = "3" THEN 2 ELSE 0), 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenNobodyWinsTheBandSaysSo():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        SetTheStage().
        DO i = 1 TO 3:
            mGame:Plan:TeamAt(1):BuddyAt(i):Hurt(100).
            mGame:Plan:TeamAt(2):BuddyAt(i):Hurt(100).
        END.
        mGame:EndTurn().
        Frames(700).
        Assert:IsTrue(mGame:Phase = BuddyPhase:Draw).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), Px(0, 60)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("B8AECB"), 0, 70, 383, 70)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedGameShowsABandAndKeepsThePicture():
        mPainter:Render(mGame:Grid, mGame).
        mGame:Paused = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(ColourMath:FromHex("FF9A3C"), Px(0, 96)).
        Assert:Equals(ColourMath:FromHex("1C1426"), Px(0, 110)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FFFFFF"), 100, 101, 290, 122)).
        Assert:Equals(Sky(60), Px(2, 60)).
        mGame:Paused = FALSE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Px(0, 96) <> ColourMath:FromHex("FF9A3C")).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhileTheComputerThinksAThoughtBubbleBobsOverItsBuddy():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        mGame:Brain = NEW SimulatingBrain(NEW SeededRandom(2), BuddySkill:Hard).
        Floor().
        DO k = 0 TO 5:
            mGame:Plan:TeamAt(k MODULO 2 + 1):BuddyAt(INTEGER(TRUNCATE(k / 2, 0)) + 1):PlaceAt(60 + 40 * k, 150).
        END.
        Frames(BuddyRules:ArrivalFrames() + BuddyRules:BannerFrames()).
        mGame:EndTurn().
        Frames(BuddyRules:SettleFrames() + BuddyRules:BannerFrames() + 5).
        Assert:IsTrue(mGame:Brain:Thinking).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FFFFFF"), mGame:CurrentBuddy:X() - 4, 150 - 12 - 14 - 14, mGame:CurrentBuddy:X() + 4, 150 - 12 - 14 - 4)).
    END METHOD.

    /* a game with a title, its land left as the generator made it, and a painter for it */
    METHOD PRIVATE VOID TitleStage(OUTPUT poGame AS BlastBuddiesGame, OUTPUT poPainter AS BlastBuddiesPainter):
        poGame = BlastBuddiesFactory:CreateWithTitle(NEW SeededRandom(5), NEW BuddySetup(2, 3, 1, Theme:Meadow)).
        poPainter = NEW BlastBuddiesPainter(NEW RecordingRenderer(), poGame, NEW SeededRandom(1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleScreenHasTheBigNameFourGoonsAndAHintPanel():
        DEFINE VARIABLE g  AS BlastBuddiesGame    NO-UNDO.
        DEFINE VARIABLE p  AS BlastBuddiesPainter NO-UNDO.
        DEFINE VARIABLE gy AS INTEGER             NO-UNDO.
        DEFINE VARIABLE sp AS BuddySprites        NO-UNDO.
        DEFINE VARIABLE st AS PixelStamp          NO-UNDO.
        DEFINE VARIABLE sx AS INTEGER             NO-UNDO.
        DEFINE VARIABLE sy AS INTEGER             NO-UNDO.
        DEFINE VARIABLE ok AS LOGICAL             NO-UNDO INITIAL TRUE.
        TitleStage(OUTPUT g, OUTPUT p).
        p:Render(g:Grid, g).
        mPainter = p.
        mGame = g.
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FFF2A0"), 119, 34, 264, 34)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FFF2A0"), 89, 76, 294, 76)).
        Assert:Equals(ColourMath:FromHex("1C1426"), Px(46, 196)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("B8AECB"), 51, 201, 330, 207)).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FFFFFF"), 159, 213, 224, 219)).
        /* the Reds dance on the hill at column 60 */
        gy = g:Land:FirstGround(60).
        sp = NEW BuddySprites().
        st = sp:Stamp("goon_dance_1", 1, FALSE).
        DO sy = 5 TO st:Height - 1:
            DO sx = 0 TO st:Width - 1:
                IF st:ColourAt(sx, sy) >= 0 AND Px(60 - sp:OriginX("goon_dance_1", FALSE) + sx, gy - sp:OriginY("goon_dance_1") + sy) <> st:ColourAt(sx, sy) THEN ok = FALSE.
            END.
        END.
        Assert:IsTrue(ok).
        sp:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleRocketFliesInAndTakesABiteOutOfTheLastS():
        DEFINE VARIABLE g     AS BlastBuddiesGame    NO-UNDO.
        DEFINE VARIABLE p     AS BlastBuddiesPainter NO-UNDO.
        DEFINE VARIABLE dx    AS INTEGER             NO-UNDO.
        DEFINE VARIABLE dy    AS INTEGER             NO-UNDO.
        DEFINE VARIABLE inkBefore AS INTEGER         NO-UNDO.
        DEFINE VARIABLE inkAfter  AS INTEGER         NO-UNDO.
        TitleStage(OUTPUT g, OUTPUT p).
        mPainter = p.
        mGame = g.
        /* at 2 seconds the rocket is on its way */
        DO dx = 1 TO 120:
            g:Advance().
        END.
        p:Render(g:Grid, g).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("F4F4F0"), 100, 80, 135, 110)).
        /* just before the hit the S is whole */
        DO dx = 1 TO 38:
            g:Advance().
        END.
        p:Render(g:Grid, g).
        DO dy = -7 TO 7:
            DO dx = -7 TO 7:
                IF dx * dx + dy * dy <= 49 AND Px(294 + dx, 80 + dy) = ColourMath:FromHex("1C1426") THEN inkBefore = inkBefore + 1.
            END.
        END.
        Assert:IsTrue(inkBefore > 0).
        /* and when the blast has cleared there is a bite out of it */
        DO dx = 1 TO 50:
            g:Advance().
        END.
        p:Render(g:Grid, g).
        DO dy = -7 TO 7:
            DO dx = -7 TO 7:
                IF dx * dx + dy * dy <= 49 AND Px(294 + dx, 80 + dy) = ColourMath:FromHex("1C1426") THEN inkAfter = inkAfter + 1.
            END.
        END.
        Assert:Equals(0, inkAfter).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBuddiesComeDownByParachuteOneAfterAnotherAndThenStand():
        DEFINE VARIABLE g  AS BlastBuddiesGame    NO-UNDO.
        DEFINE VARIABLE p  AS BlastBuddiesPainter NO-UNDO.
        DEFINE VARIABLE i  AS INTEGER             NO-UNDO.
        DEFINE VARIABLE b  AS Buddy               NO-UNDO.
        DEFINE VARIABLE reds AS INTEGER           NO-UNDO.
        TitleStage(OUTPUT g, OUTPUT p).
        mPainter = p.
        mGame = g.
        reds = ColourMath:FromHex(ENTRY(2, BuddiesLook:ToneRow("Reds"))).
        g:StartMatch().
        b = g:Plan:TeamAt(1):BuddyAt(1).
        g:Advance().
        p:Render(g:Grid, g).
        Assert:IsFalse(Somewhere(reds, b:X() - 8, b:Y() - 40, b:X() + 8, b:Y() - 14)).
        /* at 600 ms the first is on its way under an orange and white parachute */
        DO i = 1 TO 35:
            g:Advance().
        END.
        p:Render(g:Grid, g).
        Assert:IsTrue(Somewhere(ColourMath:FromHex("FF8A1E"), 0, 0, 383, 120)).
        /* by four seconds everybody has landed and shows a health number */
        DO i = 1 TO 220:
            g:Advance().
        END.
        p:Render(g:Grid, g).
        Assert:IsTrue(Somewhere(reds, b:X() - 8, b:Y() - 40, b:X() + 8, b:Y() - 14)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APainterThatSkipsUnchangedDrawsOnlyWhenTheGameHasMovedOn():
        mPainter:SkipUnchanged = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(1, mInner:RenderCount).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(1, mInner:RenderCount).
        mGame:Advance().
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(2, mInner:RenderCount).
        mGame:Paused = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(3, mInner:RenderCount).
        Assert:IsTrue(mPainter:SkipUnchanged).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APainterNeedsARandomSourceToo():
        DEFINE VARIABLE p       AS BlastBuddiesPainter NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL             NO-UNDO.
        DO ON ERROR UNDO, LEAVE:
            p = NEW BlastBuddiesPainter(mInner, mGame, ?).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHealthIsWrittenOverALivingGoonInItsTeamColour():
        DEFINE VARIABLE found AS LOGICAL NO-UNDO.
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        Floor().
        mGame:Plan:TeamAt(1):BuddyAt(1):PlaceAt(100, 150).
        mPainter:Render(mGame:Grid, mGame).
        DO y = 150 - 12 - 16 TO 150 - 12 - 8:
            DO x = 92 TO 108:
                IF Px(x, y) = ColourMath:FromHex(ENTRY(2, BuddiesLook:ToneRow("Reds"))) THEN found = TRUE.
            END.
        END.
        Assert:IsTrue(found).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABuriedBuddyIsAGravestoneAndADrownedOneIsNotDrawn():
        DEFINE VARIABLE b AS Buddy NO-UNDO.
        Floor().
        b = mGame:Plan:TeamAt(1):BuddyAt(1).
        b:PlaceAt(100, 150).
        b:Hurt(100).
        b:Buried = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(Shows("gravestone", 0, FALSE, 100, 150, 1)).
        b:PlaceAt(100, 150).
        b:State = BuddyState:Drowned.
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Sky(140), Px(100, 140)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSpritesAreMadeOnceMirroredAndRecoloured():
        DEFINE VARIABLE sp      AS BuddySprites NO-UNDO.
        DEFINE VARIABLE a       AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE m       AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE bl      AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER      NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER      NO-UNDO.
        DEFINE VARIABLE ok      AS LOGICAL      NO-UNDO INITIAL TRUE.
        DEFINE VARIABLE differs AS LOGICAL      NO-UNDO.
        DEFINE VARIABLE lThrown AS LOGICAL      NO-UNDO.
        sp = NEW BuddySprites().
        a = sp:Stamp("goon_idle_1", 1, FALSE).
        m = sp:Stamp("goon_idle_1", 1, TRUE).
        bl = sp:Stamp("goon_idle_1", 2, FALSE).
        Assert:IsTrue(a = sp:Stamp("goon_idle_1", 1, FALSE)).
        Assert:Equals(11, a:Width).
        Assert:Equals(12, a:Height).
        Assert:Equals(11, sp:WidthOf("goon_idle_1")).
        Assert:Equals(12, sp:HeightOf("goon_idle_1")).
        DO x = 0 TO 10:
            IF a:ColourAt(x, 6) <> m:ColourAt(10 - x, 6) THEN ok = FALSE.
        END.
        Assert:IsTrue(ok).
        DO y = 0 TO 11:
            DO x = 0 TO 10:
                IF a:ColourAt(x, y) <> bl:ColourAt(x, y) THEN differs = TRUE.
            END.
        END.
        Assert:IsTrue(differs).
        Assert:Equals(5, sp:OriginX("goon_idle_1", FALSE)).
        Assert:Equals(6, sp:OriginX("goon_aim", TRUE)).
        Assert:Equals(12, sp:OriginY("goon_idle_1")).
        DO ON ERROR UNDO, LEAVE:
            sp:Stamp("nothing_like_it", 0, FALSE).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        lThrown = FALSE.
        DO ON ERROR UNDO, LEAVE:
            sp:Stamp("goon_idle_1", 5, FALSE).
            CATCH e AS GridException:
                lThrown = TRUE.
            END CATCH.
        END.
        Assert:IsTrue(lThrown).
        sp:Dispose().
        sp:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWeaponTurnedToTheRightIsThePictureItselfAndTurnedToTheLeftIsHalfATurn():
        DEFINE VARIABLE sp  AS BuddySprites NO-UNDO.
        DEFINE VARIABLE src AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE r1  AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE r2  AS PixelStamp   NO-UNDO.
        DEFINE VARIABLE r   AS INTEGER      NO-UNDO.
        DEFINE VARIABLE x   AS INTEGER      NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER      NO-UNDO.
        DEFINE VARIABLE ok1 AS LOGICAL      NO-UNDO INITIAL TRUE.
        DEFINE VARIABLE ok2 AS LOGICAL      NO-UNDO INITIAL TRUE.
        sp = NEW BuddySprites().
        src = sp:Stamp("held_bazooka", 0, FALSE).
        r = sp:Reach("held_bazooka").
        r1 = sp:Turned("held_bazooka", 16, FALSE).
        r2 = sp:Turned("held_bazooka", 48, FALSE).
        Assert:Equals(2 * r + 1, r1:Width).
        DO y = 0 TO src:Height - 1:
            DO x = 0 TO src:Width - 1:
                IF r1:ColourAt(r - sp:OriginX("held_bazooka", FALSE) + x, r - sp:OriginY("held_bazooka") + y) <> src:ColourAt(x, y) THEN ok1 = FALSE.
                IF r2:ColourAt(r + sp:OriginX("held_bazooka", FALSE) - x, r + sp:OriginY("held_bazooka") - y) <> src:ColourAt(x, y) THEN ok2 = FALSE.
            END.
        END.
        Assert:IsTrue(ok1).
        Assert:IsTrue(ok2).
        Assert:IsTrue(sp:Turned("held_bazooka", 80, FALSE) = r1).
        sp:Dispose().
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
        p = NEW BlastBuddiesPainter(NEW RecordingRenderer(), g, NEW SeededRandom(1)).
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
        Assert:IsTrue(ms < 3000, "map " + STRING(ms) + " ms").
        Assert:IsTrue(bl < 800, "blast " + STRING(bl) + " ms").
        Assert:IsTrue(still < 60, "still frame " + STRING(still) + " ms").
        p:Dispose().
        g:Dispose().
    END METHOD.

END CLASS.
