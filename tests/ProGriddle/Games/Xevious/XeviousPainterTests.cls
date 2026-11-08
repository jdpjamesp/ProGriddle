/* The Xevious painter, by pixel: the picture is drawn on a canvas of its own, so a test reads the colour of any pixel. The picture is
   224 x 288: a strip of 16 rows, the field of 224 x 256 (field row y is picture row 16 + y) and a strip of 16 rows. The random source of
   the game always says 1. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousPainterTests:

    VAR PRIVATE XeviousGame mGame.
    VAR PRIVATE XeviousRecordingRenderer mInner.
    VAR PRIVATE XeviousPainter mPainter.

    /* A game in play on an empty field, the ship at 104, 208. The area start band lasts the first 120 frames of a stage. */
    @Setup.
    METHOD PUBLIC VOID BuildPainter():
        mGame = XeviousFactory:Create(NEW ScriptedRandom("1")).
        mInner = NEW XeviousRecordingRenderer().
        mPainter = NEW XeviousPainter(mInner, mGame).
        mPainter:Haze = FALSE.
        mGame:StartGame().
        mGame:StopWaves().
        mGame:ClearGround().
        mGame:StopLand().
        mGame:ClearAir().
        mGame:PlacePlayer(104, 208).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleasePainter():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mPainter = ?.
        mGame = ?.
    END METHOD.

    METHOD PRIVATE INTEGER Colour(INPUT poTint AS XeviousTint):
        RETURN XeviousLook:Colour(poTint).
    END METHOD.

    /* How many pixels of a colour there are in a rectangle of the picture. */
    METHOD PRIVATE INTEGER CountIn(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT piColour AS INTEGER):
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER n.
        DO y = piY TO piY + piH - 1:
            DO x = piX TO piX + piW - 1:
                IF mPainter:Canvas:ColourAt(x, y) = piColour THEN n = n + 1.
            END.
        END.
        RETURN n.
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        VAR INTEGER i.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* Skips the area start band: the first 120 frames of a stage. */
    METHOD PRIVATE VOID PastTheBand():
        Frames(125).
        mGame:ClearBullets().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePictureIs224By288AndIsHandedToTheInnerRenderer():
        Assert:Equals(224, mPainter:Canvas:Width).
        Assert:Equals(288, mPainter:Canvas:Height).
        Assert:Equals(16, mPainter:StripHeight).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(1, mInner:RenderCount).
        Assert:IsTrue(mInner:LastGrid = mPainter:CanvasGrid).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStripsAreDarkWithAnInkLineAndTheScoreIsInSignal():
        mGame:AddScore(150).
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(Colour(XeviousTint:Strip), mPainter:Canvas:ColourAt(110, 3)).
        Assert:Equals(Colour(XeviousTint:Ink), mPainter:Canvas:ColourAt(110, 15)).
        Assert:Equals(Colour(XeviousTint:Strip), mPainter:Canvas:ColourAt(110, 280)).
        Assert:IsTrue(CountIn(40, 1, 40, 8, Colour(XeviousTint:Signal)) > 0).
        Assert:IsTrue(CountIn(6, 1, 36, 8, Colour(XeviousTint:TextDim)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBottomStripShowsASpareShipForEachLifeButOneAndTheArea():
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 272, 40, 16, Colour(XeviousTint:WingMark)) > 0).
        Assert:IsTrue(CountIn(150, 272, 74, 16, Colour(XeviousTint:Text)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBottomRowOfTheGroundIsTheFirstRowOfTilesAtTheStartOfAStage():
        VAR XeviousSprites oSprites.
        VAR INTEGER x.
        mPainter:Render(mGame:Grid, mGame).
        oSprites = NEW XeviousSprites().
        oSprites:ForArea(1).
        DO x = 0 TO 223 BY 7:
            Assert:Equals(oSprites:TilePixel(XeviousMap:PictureAt(1, XeviousMotion:Div(x, 16), 0), x MODULO 16, 15), mPainter:Canvas:ColourAt(x, 16 + 255)).
            Assert:Equals(oSprites:TilePixel(XeviousMap:PictureAt(1, XeviousMotion:Div(x, 16), 15), x MODULO 16, 0), mPainter:Canvas:ColourAt(x, 16)).
        END.
        oSprites:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGroundScrollsDownAsTheDistanceGrows():
        VAR XeviousSprites oSprites.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER u.
        VAR INTEGER r.
        mPainter:Render(mGame:Grid, mGame).
        Frames(100).
        mGame:ClearBullets().
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(66, mGame:Distance).
        oSprites = NEW XeviousSprites().
        oSprites:ForArea(1).
        /* the picture is only compared where nothing else is drawn on the land: the band is up and so are the ship and the sight, so the
           corners of the field are used */
        DO y = 0 TO 100 BY 37:
            DO x = 3 TO 60 BY 41:
                u = 240 + mGame:Distance - y.
                r = (IF u <= 0 THEN 0 ELSE XeviousMotion:Div(u + 15, 16)).
                Assert:Equals(oSprites:TilePixel(XeviousMap:PictureAt(1, XeviousMotion:Div(x, 16), r), x MODULO 16, 16 * r - u), mPainter:Canvas:ColourAt(x, 16 + y)).
            END.
        END.
        oSprites:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipHasItsWingMarksAndItsCanopy():
        PastTheBand().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(104, 16 + 208, 16, 16, Colour(XeviousTint:WingMark)) > 0).
        Assert:IsTrue(CountIn(104, 16 + 208, 16, 16, Colour(XeviousTint:Glass)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipBanksTowardsTheSideItMovesTo():
        VAR INTEGER level.
        PastTheBand().
        mPainter:Render(mGame:Grid, mGame).
        level = CountIn(100, 16 + 208, 24, 16, Colour(XeviousTint:Hull)).
        mGame:MoveX = -1.
        mGame:Advance().
        mGame:ClearBullets().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(100, 16 + 208, 24, 16, Colour(XeviousTint:Hull)) <> level).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSightIsPaleGreenWithAnInkKeylineAndTurnsRedOverATarget():
        PastTheBand().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(104, 16 + 120, 16, 16, Colour(XeviousTint:Sight)) > 0).
        Assert:IsTrue(CountIn(104, 16 + 120, 16, 16, Colour(XeviousTint:Ink)) > 0).
        Assert:Equals(0, CountIn(104, 16 + 120, 16, 16, Colour(XeviousTint:SightLock))).
        mGame:PlaceGround(XeviousGround:Barra, 104, 120).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(104, 16 + 120, 16, 16, Colour(XeviousTint:SightLock)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AGroundTargetIsDrawnButAHiddenOneIsNot():
        PastTheBand().
        mGame:PlaceGround(XeviousGround:Barra, 20, 60).
        mGame:PlaceGround(XeviousGround:Sol, 160, 60).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(20, 16 + 60, 16, 16, Colour(XeviousTint:Stone)) + CountIn(20, 16 + 60, 16, 16, Colour(XeviousTint:Rust)) > 0).
        Assert:Equals(0, CountIn(160, 16 + 60, 16, 16, Colour(XeviousTint:Stone))).
        Assert:Equals(0, CountIn(160, 16 + 60, 16, 16, Colour(XeviousTint:Rust))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryKindOfGroundTargetAndAirEnemyCanBeDrawn():
        VAR INTEGER i.
        PastTheBand().
        DO i = 0 TO 6:
            mGame:PlaceGround(XeviousGround:GetEnum(i), 10 + i * 16, 100).
        END.
        DO i = 0 TO 7:
            mGame:SpawnAir(XeviousAir:GetEnum(i), 10 + i * 24, 30).
        END.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 16 + 100, 130, 16, Colour(XeviousTint:StoneMid)) > 0).
        Assert:IsTrue(CountIn(0, 16 + 30, 210, 16, Colour(XeviousTint:Plum)) > 0).
        Assert:IsTrue(CountIn(0, 16 + 30, 210, 16, Colour(XeviousTint:Eye)) > 0).
        Assert:IsTrue(CountIn(0, 16 + 30, 210, 16, Colour(XeviousTint:Iron)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADestroyedTargetLeavesAScorchInTheGroundThatScrollsWithIt():
        PastTheBand().
        mGame:PlaceGround(XeviousGround:Barra, 104, 120).
        mGame:BombHeld = TRUE.
        Frames(27).
        mGame:BombHeld = FALSE.
        mGame:ClearBullets().
        mPainter:Render(mGame:Grid, mGame).
        Frames(30).
        mGame:ClearBullets().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(104, 16 + 120, 16, 60, Colour(XeviousTint:Scorch)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ShotsAndBulletsAreDrawnWithTheirHalo():
        PastTheBand().
        mGame:ZapHeld = TRUE.
        Frames(4).
        mGame:ZapHeld = FALSE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(100, 16, 30, 230, Colour(XeviousTint:Zap)) > 0).
        mGame:ClearAir().
        mGame:SpawnAir(XeviousAir:Zakato, 20, 100).
        Frames(46).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 16, 224, 256, Colour(XeviousTint:HotCore)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBombIsDrawnInFlight():
        PastTheBand().
        mGame:BombHeld = TRUE.
        Frames(10).
        mGame:BombHeld = FALSE.
        mGame:ClearBullets().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mGame:BombActive).
        Assert:IsTrue(CountIn(0, 16, 224, 256, Colour(XeviousTint:FlameHot)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCitadelIsDrawnWithItsCoreAndShields():
        PastTheBand().
        mGame:SpawnBoss().
        Frames(60).
        mGame:ClearBullets().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 16, 224, 140, Colour(XeviousTint:Shell)) > 0).
        Assert:IsTrue(CountIn(0, 16, 224, 140, Colour(XeviousTint:Core)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleDrawsTheNameTheRollCallAndAVeiledLand():
        VAR XeviousGame oGame.
        VAR XeviousPainter oPainter.
        oGame = XeviousFactory:Create(NEW ScriptedRandom("1")).
        oPainter = NEW XeviousPainter(NEW XeviousRecordingRenderer(), oGame).
        oPainter:Render(oGame:Grid, oGame).
        Assert:IsTrue(oPainter:Canvas:ColourAt(112, 60) <> 0).
        oPainter:Dispose().
        oGame:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheAreaStartBandOpensOverTheLandAndGoesAfterTwoSeconds():
        mPainter:Render(mGame:Grid, mGame).
        Frames(30).
        mGame:ClearBullets().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 120, 224, 1, Colour(XeviousTint:WingMark)) > 0).
        Assert:IsTrue(CountIn(0, 127, 224, 20, Colour(XeviousTint:DawnTop)) > 0).
        PastTheBand().
        mPainter:Render(mGame:Grid, mGame).
        Assert:Equals(0, CountIn(0, 120, 224, 1, Colour(XeviousTint:WingMark))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedGameIsVeiledWithItsWordsOnIt():
        PastTheBand().
        mGame:Paused = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(0, 100, 224, 70, Colour(XeviousTint:Text)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStageClearScreenCountsTheSquaresAndTheBonusUp():
        mGame:StartGame().
        mGame:StopWaves().
        Frames(2880).
        Assert:Equals(STRING(XeviousPhase:StageClear), STRING(mGame:Phase)).
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(CountIn(16, 56, 192, 1, Colour(XeviousTint:WingMark)) > 0).
        Assert:IsTrue(CountIn(16, 56, 192, 160, Colour(XeviousTint:DawnTop)) > 0).
        Assert:IsTrue(CountIn(16, 130, 192, 20, Colour(XeviousTint:StoneDark)) > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipBreaksUpIntoPiecesThatCrumbleAway():
        VAR INTEGER early.
        VAR INTEGER late.
        PastTheBand().
        mGame:SpawnAir(XeviousAir:Zakato, mGame:PlayerX, mGame:PlayerY).
        Frames(2).
        mPainter:Render(mGame:Grid, mGame).
        early = CountIn(80, 16 + 190, 70, 50, Colour(XeviousTint:HullInk)) + CountIn(80, 16 + 190, 70, 50, Colour(XeviousTint:Hull)).
        Frames(60).
        mPainter:Render(mGame:Grid, mGame).
        late = CountIn(80, 16 + 190, 70, 50, Colour(XeviousTint:HullInk)) + CountIn(80, 16 + 190, 70, 50, Colour(XeviousTint:Hull)).
        Assert:IsTrue(early > late).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHazeTintsTheLandAndCanBeSwitchedOff():
        VAR INT64 plain.
        VAR INT64 hazy.
        VAR INTEGER x.
        VAR INTEGER y.
        PastTheBand().
        mPainter:Render(mGame:Grid, mGame).
        DO y = 16 TO 270 BY 3:
            DO x = 0 TO 223 BY 3:
                plain = plain + mPainter:Canvas:ColourAt(x, y).
            END.
        END.
        mPainter:Haze = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        DO y = 16 TO 270 BY 3:
            DO x = 0 TO 223 BY 3:
                hazy = hazy + mPainter:Canvas:ColourAt(x, y).
            END.
        END.
        Assert:IsTrue(mPainter:Haze).
        Assert:IsTrue(hazy <> plain).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScanlinesAreOffUntilSwitchedOn():
        PastTheBand().
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsFalse(mPainter:Scanlines).
        mPainter:Scanlines = TRUE.
        mPainter:Render(mGame:Grid, mGame).
        Assert:IsTrue(mPainter:Scanlines).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItNeedsARendererAndAGameAndOnlyDrawsAXeviousGame():
        VAR INTEGER thrown.
        VAR XeviousPainter oOther.
        DO ON ERROR UNDO, THROW:
            oOther = NEW XeviousPainter(?, mGame).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            oOther = NEW XeviousPainter(mInner, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            mPainter:Render(mGame:Grid, ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
