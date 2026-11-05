/* The Centipede painter, by pixel: the picture is drawn on a canvas of its own, so a test reads the colour of any pixel. The picture is
   240 x 256: a strip of 16 pixels above the board, then 30 x 30 tiles of 8 pixels, so tile x, y begins at pixel 8 * x, 16 + 8 * y. The
   random source of the game always says 1. The first night has an orchid crawler on jade bulbs. A game in play shows a banner over
   rows 90 to 139 for its first 90 frames, so a test that reads colours there looks away from that band. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedePainterTests:

    DEFINE PRIVATE VARIABLE mGame    AS CentipedeGame              NO-UNDO.
    DEFINE PRIVATE VARIABLE mInner   AS CentipedeRecordingRenderer NO-UNDO.
    DEFINE PRIVATE VARIABLE mPainter AS CentipedePainter           NO-UNDO.

    /* A game in play on an empty field, with a segment kept out of the way so the wave is not over, and the shooter at 112, 224. */
    @Setup.
    METHOD PUBLIC VOID BuildPainter():
        mGame = CentipedeFactory:Create(NEW ScriptedRandom("1")).
        mInner = NEW CentipedeRecordingRenderer().
        mPainter = NEW CentipedePainter(mInner, mGame).
        mGame:StartGame().
        mGame:ClearField().
        mGame:ClearCentipede().
        mGame:ClearCreatures().
        mGame:PlacePlayer(112, 224).
        mGame:AddSegment(29, 0, -1, FALSE).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleasePainter():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mPainter = ?.
        mGame = ?.
    END METHOD.

    METHOD PRIVATE INTEGER Colour(INPUT poTint AS CentipedeTint):
        RETURN CentipedeLook:Colour(poTint).
    END METHOD.

    /* The colour of the pixel at tile piTx, piTy, piDx and piDy pixels in. */
    METHOD PRIVATE INTEGER Pixel(INPUT piTx AS INTEGER, INPUT piTy AS INTEGER, INPUT piDx AS INTEGER, INPUT piDy AS INTEGER):
        RETURN mPainter:Canvas:ColourAt(piTx * 8 + piDx, 16 + piTy * 8 + piDy).
    END METHOD.

    /* How many pixels of a colour there are in a rectangle of the picture. */
    METHOD PRIVATE INTEGER CountIn(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT piColour AS INTEGER):
        RETURN CountIn2(mPainter, piX, piY, piW, piH, piColour).
    END METHOD.

    METHOD PRIVATE INTEGER CountIn2(INPUT poPainter AS CentipedePainter, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER,
                                    INPUT piColour AS INTEGER):
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = piY TO piY + piH - 1:
            DO x = piX TO piX + piW - 1:
                IF poPainter:Canvas:ColourAt(x, y) = piColour THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* Plays on to wave piWave by clearing the wave each time, then leaves the field as the setup did. */
    METHOD PRIVATE VOID ToWave(INPUT piWave AS INTEGER):
        DEFINE VARIABLE guard AS INTEGER NO-UNDO.
        DO WHILE mGame:Wave < piWave AND guard < 2000:
            mGame:ClearCentipede().
            mGame:Advance().
            DO WHILE mGame:Phase = GamePhase:Cleared AND guard < 2000:
                mGame:Advance().
                guard = guard + 1.
            END.
        END.
        Assert:Equals(piWave, mGame:Wave).
        mGame:ClearField().
        mGame:ClearCentipede().
        mGame:ClearCreatures().
        mGame:AddSegment(29, 0, -1, FALSE).
    END METHOD.

    /* ---- the picture ---- */

    @Test.
    METHOD PUBLIC VOID ThePictureIs240By256AndIsHandedToTheInnerRenderer():
        Assert:Equals(240, mPainter:Canvas:Width).
        Assert:Equals(256, mPainter:Canvas:Height).
        Assert:Equals(16, mPainter:StripHeight).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(1, mInner:RenderCount).
        Assert:IsTrue(mInner:LastGrid = mPainter:CanvasGrid).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBackgroundIsNightAboveTheBandAndAQuieterBlueInIt():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Night), mPainter:Canvas:ColourAt(200, 60)).
        Assert:Equals(Colour(CentipedeTint:Band), mPainter:Canvas:ColourAt(5, 250)).
        Assert:Equals(Colour(CentipedeTint:Strip), mPainter:Canvas:ColourAt(100, 2)).
        Assert:Equals(Colour(CentipedeTint:StripRule), mPainter:Canvas:ColourAt(100, 15)).
        Assert:Equals(Colour(CentipedeTint:BandRule), mPainter:Canvas:ColourAt(5, 208)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADottedRuleRunsUnderEveryRowOfTheNight():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Rule), mPainter:Canvas:ColourAt(2, 23)).
        Assert:Equals(Colour(CentipedeTint:Rule), mPainter:Canvas:ColourAt(6, 23)).
        Assert:Equals(Colour(CentipedeTint:Night), mPainter:Canvas:ColourAt(3, 23)).
        /* a sparser one in the band, and none under the last row of the night */
        Assert:Equals(Colour(CentipedeTint:BandRule), mPainter:Canvas:ColourAt(2, 247)).
        Assert:Equals(Colour(CentipedeTint:Band), mPainter:Canvas:ColourAt(6, 247)).
        Assert:Equals(Colour(CentipedeTint:Night), mPainter:Canvas:ColourAt(2, 207)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StarsDriftAboveTheBedAndGrassGrowsAtTheFootOfTheBand():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Mote), mPainter:Canvas:ColourAt(13, 22)).
        Assert:Equals(Colour(CentipedeTint:BandRule), mPainter:Canvas:ColourAt(3, 255)).
        Assert:Equals(Colour(CentipedeTint:BandRule), mPainter:Canvas:ColourAt(3, 254)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStarsMoveAsTheGameGoesOn():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Mote), mPainter:Canvas:ColourAt(13, 22)).
        Frames(64).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Mote), mPainter:Canvas:ColourAt(13, 23)).
    END METHOD.

    /* ---- the bulbs ---- */

    @Test.
    METHOD PUBLIC VOID AWholeBulbHasATipABellyAndRoots():
        mGame:PlaceMushroom(3, 5, 4).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(CentipedeLook:FamilyColour(CentipedeLook:BulbFamily(1), 1), Pixel(3, 5, 4, 0)).
        Assert:Equals(CentipedeLook:FamilyColour(CentipedeLook:BulbFamily(1), 2), Pixel(3, 5, 2, 4)).
        Assert:Equals(Colour(CentipedeTint:Stalk), Pixel(3, 5, 2, 7)).
        Assert:Equals(Colour(CentipedeTint:Night), Pixel(3, 5, 0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABulbIsEatenFromBelowAsItIsHit():
        mGame:PlaceMushroom(3, 5, 3).
        mGame:PlaceMushroom(5, 5, 1).
        mPainter:Render(mGame:Grid, mGame).
        /* the roots go first, then the belly, and the tip is always left */
        Assert:Equals(0, CountIn(24, 56, 8, 8, Colour(CentipedeTint:Stalk))).
        Assert:Equals(Colour(CentipedeTint:Night), Pixel(3, 5, 3, 7)).
        Assert:Equals(Colour(CentipedeTint:Night), Pixel(5, 5, 2, 4)).
        Assert:Equals(CentipedeLook:FamilyColour(CentipedeLook:BulbFamily(1), 1), Pixel(5, 5, 4, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABlightedBulbIsPaleLilacWhateverTheNight():
        mGame:PlaceMushroom(3, 5, 4).
        mGame:PoisonMushroom(3, 5).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:BlightLight), Pixel(3, 5, 4, 0)).
        Assert:Equals(Colour(CentipedeTint:Blight), Pixel(3, 5, 3, 4)).
        Assert:Equals(Colour(CentipedeTint:BlightDeep), Pixel(3, 5, 4, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABulbInTheBandIsDrawnOnTheQuieterGround():
        mGame:PlaceMushroom(3, 26, 1).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Band), Pixel(3, 26, 0, 0)).
        Assert:Equals(CentipedeLook:FamilyColour(CentipedeLook:BulbFamily(1), 1), Pixel(3, 26, 4, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFieldIsDrawnAgainWhenItChangesAndNotBefore():
        mGame:PlaceMushroom(3, 5, 4).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Stalk), Pixel(3, 5, 2, 7)).
        mGame:PlaceMushroom(3, 5, 2).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Night), Pixel(3, 5, 3, 7)).
        mGame:PlaceMushroom(3, 5, 0).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Night), Pixel(3, 5, 4, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBulbsTakeTheColoursOfTheNightOfTheWave():
        mGame:PlaceMushroom(3, 5, 4).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:JadeLight), Pixel(3, 5, 4, 0)).
        ToWave(2).
        mGame:PlaceMushroom(3, 5, 4).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:TideLight), Pixel(3, 5, 4, 0)).
    END METHOD.

    /* ---- what moves ---- */

    @Test.
    METHOD PUBLIC VOID ABeadIsTheColourOfTheNightAndAHeadHasEmberEyes():
        mGame:AddSegment(10, 4, -1, TRUE).
        mGame:AddSegment(12, 4, -1, FALSE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(80, 48, 8, 8, Colour(CentipedeTint:Ember)) > 0).
        Assert:IsTrue(CountIn(80, 48, 8, 8, Colour(CentipedeTint:Orchid)) > 0).
        Assert:Equals(0, CountIn(96, 48, 8, 8, Colour(CentipedeTint:Ember))).
        Assert:IsTrue(CountIn(96, 48, 8, 8, Colour(CentipedeTint:Orchid)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeadsEyesAreOnTheSideItIsCrawlingTowards():
        mGame:AddSegment(10, 4, 1, TRUE).
        mGame:AddSegment(14, 4, -1, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Ember), Pixel(10, 4, 6, 2)).
        Assert:Equals(Colour(CentipedeTint:Ember), Pixel(14, 4, 1, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatMovedIsNotLeftBehindInTheNextPicture():
        mGame:AddSegment(10, 4, -1, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(80, 48, 8, 8, Colour(CentipedeTint:Ember)) > 0).
        mGame:ClearCentipede().
        mGame:AddSegment(29, 0, -1, FALSE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, CountIn(80, 48, 8, 8, Colour(CentipedeTint:Ember))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADivingSegmentFlickersInTheColoursOfBlight():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mGame:PlaceMushroom(3, 3, 4).
        mGame:PoisonMushroom(3, 3).
        mGame:AddSegment(5, 3, -1, TRUE).
        DO WHILE NOT mGame:SegmentDiving(1) AND i < 200:
            mGame:Advance().
            i = i + 1.
        END.
        Assert:IsTrue(mGame:SegmentDiving(1)).
        DO WHILE INTEGER(TRUNCATE(mGame:Frames / 4, 0)) MODULO 2 <> 0:
            mGame:Advance().
        END.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(mGame:SegmentX(1), 16 + mGame:SegmentY(1), 8, 8, Colour(CentipedeTint:BlightLight)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWickIsDrawnWhereItIsWithAGlowRoundIt():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:WickDeep), mPainter:Canvas:ColourAt(112, 16 + 224 + 6)).
        Assert:Equals(Colour(CentipedeTint:Wick), mPainter:Canvas:ColourAt(115, 16 + 224 + 1)).
        /* the cell above the flame is not plain band: it has taken a little of the glow */
        Assert:IsTrue(mPainter:Canvas:ColourAt(115, 16 + 224 - 1) <> Colour(CentipedeTint:Band)).
        mGame:PlacePlayer(40, 200).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:WickDeep), mPainter:Canvas:ColourAt(40, 16 + 200 + 6)).
        Assert:Equals(Colour(CentipedeTint:Band), mPainter:Canvas:ColourAt(112, 16 + 224 + 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSparkIsAWhiteHeadWithAGoldTail():
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Spark), mPainter:Canvas:ColourAt(mGame:ShotX, 16 + mGame:ShotY)).
        Assert:Equals(Colour(CentipedeTint:SparkTail), mPainter:Canvas:ColourAt(mGame:ShotX, 16 + mGame:ShotY + 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMuzzleFlashShowsWhileTheSparkIsStillNearTheWick():
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mGame:PlayerY - mGame:ShotY < 16).
        Assert:Equals(Colour(CentipedeTint:Spark), mPainter:Canvas:ColourAt(112 + 1 + 1, 16 + 224 - 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheWickBreaksUpWhenItIsHit():
        mGame:AddSegment(14, 28, -1, TRUE).
        mGame:Advance().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mGame:Phase = GamePhase:Dying).
        Assert:IsTrue(Pixel(14, 28, 0, 6) <> Colour(CentipedeTint:WickDeep)).
        Assert:IsTrue(CountIn(104, 232, 24, 24, Colour(CentipedeTint:Flash)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePestsAreDrawnInTheirOwnColours():
        mGame:SpawnFlea(5).
        mGame:SpawnSpider(TRUE, 25).
        mGame:SpawnScorpion(8, FALSE).
        Frames(10).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 16, 240, 240, Colour(CentipedeTint:Husk)) > 0).
        Assert:IsTrue(CountIn(0, 16, 240, 240, Colour(CentipedeTint:Jack)) > 0).
        Assert:IsTrue(CountIn(0, 16, 240, 240, Colour(CentipedeTint:Blight)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSowerHasLightWingsAndAnEmberEye():
        mGame:SpawnFlea(5).
        Frames(2).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 16, 240, 240, Colour(CentipedeTint:HuskLight)) > 0).
        Assert:IsTrue(CountIn(0, 16, 240, 240, Colour(CentipedeTint:Ember)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMoonsnailIsDrawnTheOtherWayRoundWhenItCrawlsLeft():
        mGame:SpawnScorpion(8, TRUE).
        Frames(40).
        mPainter:Render(mGame:Grid, mGame).
        /* crawling right, the pale eyes are in the right of the sprite and none in the first three cells */
        Assert:IsTrue(CountIn(mGame:ScorpionX + 12, 16 + mGame:ScorpionY, 4, 8, Colour(CentipedeTint:BlightLight)) > 0).
        Assert:Equals(0, CountIn(mGame:ScorpionX, 16 + mGame:ScorpionY, 3, 8, Colour(CentipedeTint:BlightLight))).
        mGame:ClearCreatures().
        mGame:SpawnScorpion(8, FALSE).
        Frames(40).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(mGame:ScorpionX, 16 + mGame:ScorpionY, 3, 8, Colour(CentipedeTint:BlightLight)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSkitterjackIsDrawnAtTheEndsOfItsPathToo():
        /* row 20 is the top of its path, where it crouches */
        mGame:SpawnSpider(TRUE, 20).
        Frames(30).
        Assert:IsTrue(mGame:SpiderActive).
        Assert:IsTrue(mGame:SpiderY <= 162).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(mGame:SpiderX, 16 + mGame:SpiderY, 16, 8, Colour(CentipedeTint:Jack)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePointsOfACreatureAreShownForAWhile():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mGame:PlacePlayer(120, 224).
        mGame:SpawnScorpion(10, TRUE).
        DO i = 1 TO 112:
            mGame:Advance().
        END.
        mGame:FireHeld = TRUE.
        DO WHILE mGame:LastBonus = 0 AND i < 400:
            mGame:Advance().
            i = i + 1.
        END.
        Assert:Equals(1000, mGame:LastBonus).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 16, 240, 200, Colour(CentipedeTint:Points)) > 0).
    END METHOD.

    /* ---- the strip and the screens ---- */

    @Test.
    METHOD PUBLIC VOID TheScoreTheMoonTheWaveAndASpareWickForEachLifeInReserveAreInTheStrip():
        Assert:Equals(3, mGame:Lives).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(4, 4, 40, 10, Colour(CentipedeTint:Points)) > 0).
        Assert:IsTrue(CountIn(96, 4, 40, 10, Colour(CentipedeTint:Text)) > 0).
        Assert:Equals(Colour(CentipedeTint:TextDim), mPainter:Canvas:ColourAt(162, 4)).
        Assert:IsTrue(CountIn(170, 4, 8, 10, Colour(CentipedeTint:Text)) > 0).
        /* two spare Wicks, the nearest the edge, and no third */
        Assert:IsTrue(CountIn(231, 5, 5, 6, Colour(CentipedeTint:WickDeep)) > 0).
        Assert:IsTrue(CountIn(223, 5, 5, 6, Colour(CentipedeTint:WickDeep)) > 0).
        Assert:Equals(0, CountIn(215, 5, 5, 6, Colour(CentipedeTint:WickDeep))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMoonOfTheStripFollowsTheNight():
        ToWave(5).
        mPainter:Render(mGame:Grid, mGame).
        /* the full moon is all one colour */
        Assert:Equals(Colour(CentipedeTint:Text), mPainter:Canvas:ColourAt(163, 7)).
        Assert:Equals(Colour(CentipedeTint:Text), mPainter:Canvas:ColourAt(162, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ANewNightStartsWithABannerNamingTheWaveAndTheMoon():
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(90, 98, 60, 14, Colour(CentipedeTint:Text)) > 0).
        Assert:IsTrue(CountIn(100, 128, 40, 8, Colour(CentipedeTint:TextDim)) > 0).
        /* the banner darkens the field behind it */
        Assert:IsTrue(mPainter:Canvas:ColourAt(230, 110) <> Colour(CentipedeTint:Night)).
        Frames(90).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, CountIn(90, 98, 60, 14, Colour(CentipedeTint:Text))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleShowsTheNameTheCrawlingGloamAndTheRollCall():
        DEFINE VARIABLE oGame    AS CentipedeGame    NO-UNDO.
        DEFINE VARIABLE oPainter AS CentipedePainter NO-UNDO.
        DEFINE VARIABLE i        AS INTEGER          NO-UNDO.
        oGame = CentipedeFactory:Create(NEW ScriptedRandom("1")).
        oPainter = NEW CentipedePainter(NEW CentipedeRecordingRenderer(), oGame).
        DO i = 1 TO 40:
            oGame:Advance().
        END.
        oPainter:Render(oGame:Grid, oGame).
        Assert:IsTrue(oGame:Phase = GamePhase:Title).
        /* the name is shaded from pale moon at the top to blue at the bottom */
        Assert:IsTrue(CountIn2(oPainter, 30, 30, 180, 8, Colour(CentipedeTint:MoonTop)) > 0).
        Assert:IsTrue(CountIn2(oPainter, 0, 90, 240, 8, Colour(CentipedeTint:Orchid)) > 0).
        Assert:IsTrue(CountIn2(oPainter, 0, 90, 240, 8, Colour(CentipedeTint:Ember)) > 0).
        Assert:IsTrue(CountIn2(oPainter, 150, 120, 80, 90, Colour(CentipedeTint:Points)) > 0).
        Assert:IsTrue(CountIn2(oPainter, 80, 120, 70, 90, Colour(CentipedeTint:Text)) > 0).
        oPainter:Dispose().
        oGame:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedGameIsDimmedAndSaysPaused():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Night), mPainter:Canvas:ColourAt(200, 60)).
        mGame:Paused = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mPainter:Canvas:ColourAt(200, 60) <> Colour(CentipedeTint:Night)).
        Assert:IsTrue(CountIn(60, 112, 120, 32, Colour(CentipedeTint:Text)) > 0).
        Assert:Equals(Colour(CentipedeTint:Plate), mPainter:Canvas:ColourAt(62, 114)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheWaveIsClearedTheBoardSaysSo():
        mGame:ClearCentipede().
        mGame:Advance().
        Assert:IsTrue(mGame:Phase = GamePhase:Cleared).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(30, 98, 180, 14, Colour(CentipedeTint:Text)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameOverScreenIsDimmedAndSaysGameOverAndPressSpaceAfterAMoment():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 3:
            mGame:ClearCentipede().
            mGame:PlacePlayer(112, 224).
            mGame:AddSegment(14, 28, -1, TRUE).
            mGame:Advance().
            DO WHILE mGame:Phase = GamePhase:Dying:
                mGame:Advance().
            END.
        END.
        Assert:IsTrue(mGame:Phase = GamePhase:GameOver).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Plate), mPainter:Canvas:ColourAt(40, 100)).
        Assert:IsTrue(CountIn(36, 105, 168, 16, Colour(CentipedeTint:MoonTop)) > 0).
        Assert:Equals(0, CountIn(40, 176, 160, 7, Colour(CentipedeTint:Text))).
        DO i = 1 TO 91:
            mGame:Advance().
        END.
        /* the words blink, so look at a frame in the lit part of the blink */
        DO WHILE mGame:Frames MODULO 60 >= 40:
            mGame:Advance().
        END.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(40, 176, 160, 7, Colour(CentipedeTint:Text)) > 0).
    END METHOD.

    /* ---- the contract ---- */

    @Test.
    METHOD PUBLIC VOID RenderRefusesAGameThatIsNotCentipede():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mPainter:Render(mGame:Grid, ?).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePainterNeedsARendererAndAGame():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DEFINE VARIABLE oOther AS CentipedePainter NO-UNDO.
        DO ON ERROR UNDO, THROW:
            oOther = NEW CentipedePainter(?, mGame).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW CentipedePainter(mInner, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeCanBeCalledMoreThanOnce():
        mPainter:Dispose().
        mPainter:Dispose().
        Assert:IsTrue(TRUE).
    END METHOD.

END CLASS.
