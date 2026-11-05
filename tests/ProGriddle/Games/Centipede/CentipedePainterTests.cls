/* The Centipede painter, by pixel: the picture is drawn on a canvas of its own, so a test reads the colour of any pixel. The picture is
   240 x 256: a strip of 16 pixels above the board, then 30 x 30 tiles of 8 pixels, so tile x, y begins at pixel 8 * x, 16 + 8 * y. The
   random source of the game always says 1. */
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
        DEFINE VARIABLE x AS INTEGER NO-UNDO.
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        DO y = piY TO piY + piH - 1:
            DO x = piX TO piX + piW - 1:
                IF mPainter:Canvas:ColourAt(x, y) = piColour THEN n = n + 1.
            END.
        END.
        RETURN n.
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
    METHOD PUBLIC VOID TheBackgroundIsNightAboveTheZoneAndALighterBlueInIt():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Night), mPainter:Canvas:ColourAt(200, 100)).
        Assert:Equals(Colour(CentipedeTint:Zone), mPainter:Canvas:ColourAt(5, 250)).
        Assert:Equals(Colour(CentipedeTint:Strip), mPainter:Canvas:ColourAt(100, 2)).
        Assert:Equals(Colour(CentipedeTint:StripRule), mPainter:Canvas:ColourAt(100, 15)).
        Assert:Equals(Colour(CentipedeTint:ZoneRule), mPainter:Canvas:ColourAt(5, 208)).
    END METHOD.

    /* ---- the mushrooms ---- */

    @Test.
    METHOD PUBLIC VOID AMushroomHasACapAndAStem():
        mGame:PlaceMushroom(3, 5, 4).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Cap4), Pixel(3, 5, 4, 3)).
        Assert:Equals(Colour(CentipedeTint:Stem), Pixel(3, 5, 3, 6)).
        Assert:Equals(Colour(CentipedeTint:Night), Pixel(3, 5, 0, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCapDarkensAsTheMushroomIsHit():
        mGame:PlaceMushroom(3, 5, 3).
        mGame:PlaceMushroom(4, 5, 2).
        mGame:PlaceMushroom(5, 5, 1).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Cap3), Pixel(3, 5, 4, 3)).
        Assert:Equals(Colour(CentipedeTint:Cap2), Pixel(4, 5, 4, 3)).
        Assert:Equals(Colour(CentipedeTint:Cap1), Pixel(5, 5, 4, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMushroomTakesBitesOutOfItsCapAsItIsHit():
        mGame:PlaceMushroom(3, 5, 4).
        mGame:PlaceMushroom(4, 5, 1).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Cap4), Pixel(3, 5, 6, 1)).
        Assert:Equals(Colour(CentipedeTint:Night), Pixel(4, 5, 6, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APoisonedMushroomIsCyan():
        mGame:PlaceMushroom(3, 5, 4).
        mGame:PoisonMushroom(3, 5).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:PoisonCap), Pixel(3, 5, 4, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMushroomInThePlayerZoneIsDrawnOnTheLighterBand():
        mGame:PlaceMushroom(3, 26, 1).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Zone), Pixel(3, 26, 6, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFieldIsDrawnAgainWhenItChangesAndNotBefore():
        mGame:PlaceMushroom(3, 5, 4).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Cap4), Pixel(3, 5, 4, 3)).
        mGame:PlaceMushroom(3, 5, 2).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Cap2), Pixel(3, 5, 4, 3)).
        mGame:PlaceMushroom(3, 5, 0).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Night), Pixel(3, 5, 4, 3)).
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* ---- what moves ---- */

    @Test.
    METHOD PUBLIC VOID ABodySegmentIsGreenAndAHeadIsLimeWithRedEyes():
        mGame:AddSegment(10, 10, -1, TRUE).
        mGame:AddSegment(12, 10, -1, FALSE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:HeadMain), Pixel(10, 10, 3, 3)).
        Assert:Equals(Colour(CentipedeTint:Eye), Pixel(10, 10, 2, 2)).
        Assert:Equals(Colour(CentipedeTint:BodyMain), Pixel(12, 10, 3, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHeadsEyesAreOnTheSideItIsCrawlingTowards():
        mGame:AddSegment(10, 10, 1, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Eye), Pixel(10, 10, 5, 2)).
        Assert:Equals(Colour(CentipedeTint:HeadMain), Pixel(10, 10, 2, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatMovedIsNotLeftBehindInTheNextPicture():
        mGame:AddSegment(10, 10, -1, TRUE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:HeadMain), Pixel(10, 10, 3, 3)).
        mGame:ClearCentipede().
        mGame:AddSegment(29, 0, -1, FALSE).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Night), Pixel(10, 10, 3, 3)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShooterIsDrawnWhereItIs():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Ship), Pixel(14, 28, 1, 5)).
        Assert:Equals(Colour(CentipedeTint:ShipLight), Pixel(14, 28, 3, 0)).
        mGame:PlacePlayer(40, 200).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Ship), mPainter:Canvas:ColourAt(41, 16 + 200 + 5)).
        Assert:Equals(Colour(CentipedeTint:Zone), Pixel(14, 28, 1, 5)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShotIsAYellowBarWithAnOrangeTail():
        mGame:FireHeld = TRUE.
        mGame:Advance().
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Shot), mPainter:Canvas:ColourAt(mGame:ShotX, 16 + mGame:ShotY)).
        Assert:Equals(Colour(CentipedeTint:ShotTail), mPainter:Canvas:ColourAt(mGame:ShotX, 16 + mGame:ShotY + 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShooterBreaksUpWhenItIsHit():
        mGame:AddSegment(14, 28, -1, TRUE).
        mGame:Advance().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mGame:Phase = GamePhase:Dying).
        Assert:IsTrue(Pixel(14, 28, 1, 5) <> Colour(CentipedeTint:Ship)).
        Assert:IsTrue(CountIn(100, 200, 40, 50, Colour(CentipedeTint:Flash)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFleaTheSpiderAndTheScorpionAreDrawn():
        mGame:SpawnFlea(5).
        mGame:SpawnSpider(TRUE, 25).
        mGame:SpawnScorpion(8, FALSE).
        Frames(10).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 16, 240, 240, Colour(CentipedeTint:FleaMain)) > 0).
        Assert:IsTrue(CountIn(0, 16, 240, 240, Colour(CentipedeTint:SpiderMain)) > 0).
        Assert:IsTrue(CountIn(0, 16, 240, 240, Colour(CentipedeTint:ScorpionMain)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScorpionIsDrawnTheOtherWayRoundWhenItCrawlsLeft():
        DEFINE VARIABLE bodyLeft  AS INTEGER NO-UNDO.
        DEFINE VARIABLE headLeft  AS INTEGER NO-UNDO.
        mGame:SpawnScorpion(8, TRUE).
        Frames(40).
        mPainter:Render(mGame:Grid, mGame).
        /* crawling right, the light head is on the right half */
        headLeft = CountIn(mGame:ScorpionX + 12, 16 + mGame:ScorpionY, 3, 8, Colour(CentipedeTint:ScorpionLight)).
        Assert:IsTrue(headLeft > 0).
        mGame:ClearCreatures().
        mGame:SpawnScorpion(8, FALSE).
        Frames(40).
        mPainter:Render(mGame:Grid, mGame).
        bodyLeft = CountIn(mGame:ScorpionX, 16 + mGame:ScorpionY, 4, 8, Colour(CentipedeTint:ScorpionLight)).
        Assert:IsTrue(bodyLeft > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBonusForACreatureIsShownForAWhile():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mGame:PlacePlayer(120, 224).
        mGame:SpawnScorpion(10, TRUE).
        DO i = 1 TO 112:
            mGame:Advance().
        END.
        mGame:FireHeld = TRUE.
        DO i = 1 TO 30:
            mGame:Advance().
        END.
        Assert:Equals(1000, mGame:LastBonus).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 0, 240, 256, Colour(CentipedeTint:Gold)) > 0).
    END METHOD.

    /* ---- the strip and the screens ---- */

    @Test.
    METHOD PUBLIC VOID TheScoreIsWrittenInTheStripAndASpareShooterIsDrawnForEachLifeInReserve():
        Assert:Equals(3, mGame:Lives).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(4, 4, 40, 10, Colour(CentipedeTint:Text)) > 0).
        /* two spare shooters, the nearest the edge 11 pixels in */
        Assert:IsTrue(CountIn(240 - 11, 4, 9, 8, Colour(CentipedeTint:Ship)) > 0).
        Assert:IsTrue(CountIn(240 - 20, 4, 9, 8, Colour(CentipedeTint:Ship)) > 0).
        Assert:Equals(0, CountIn(240 - 29, 4, 9, 8, Colour(CentipedeTint:Ship))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleShowsTheNameAndACrawlingCentipede():
        DEFINE VARIABLE oGame    AS CentipedeGame NO-UNDO.
        DEFINE VARIABLE oPainter AS CentipedePainter NO-UNDO.
        DEFINE VARIABLE i        AS INTEGER NO-UNDO.
        oGame = CentipedeFactory:Create(NEW ScriptedRandom("1")).
        oPainter = NEW CentipedePainter(NEW CentipedeRecordingRenderer(), oGame).
        DO i = 1 TO 40:
            oGame:Advance().
        END.
        oPainter:Render(oGame:Grid, oGame).
        Assert:IsTrue(oGame:Phase = GamePhase:Title).
        /* the title is shaded from lime at the top to green at the bottom, so its top row is lime */
        Assert:IsTrue(CountIn2(oPainter, 40, 56, 160, 3, Colour(CentipedeTint:TitleTop)) > 0).
        Assert:IsTrue(CountIn2(oPainter, 0, 120, 240, 8, Colour(CentipedeTint:HeadMain)) > 0).
        oPainter:Dispose().
        oGame:Dispose().
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

    @Test.
    METHOD PUBLIC VOID APausedGameIsDimmedAndSaysPaused():
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(CentipedeTint:Night), mPainter:Canvas:ColourAt(230, 60)).
        mGame:Paused = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mPainter:Canvas:ColourAt(230, 60) <> Colour(CentipedeTint:Night)).
        Assert:IsTrue(CountIn(60, 112, 130, 21, Colour(CentipedeTint:Text)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenTheWaveIsClearedTheBoardSaysSo():
        mGame:ClearCentipede().
        mGame:Advance().
        Assert:IsTrue(mGame:Phase = GamePhase:Cleared).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(40, 120, 160, 7, Colour(CentipedeTint:Gold)) > 0).
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
        Assert:IsTrue(CountIn(40, 100, 160, 21, Colour(CentipedeTint:Warn)) > 0).
        Assert:Equals(0, CountIn(40, 170, 160, 7, Colour(CentipedeTint:Text))).
        DO i = 1 TO 91:
            mGame:Advance().
        END.
        /* the words blink, so look at a frame in the lit part of the blink */
        DO WHILE mGame:Frames MODULO 60 >= 40:
            mGame:Advance().
        END.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(40, 170, 160, 7, Colour(CentipedeTint:Text)) > 0).
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
