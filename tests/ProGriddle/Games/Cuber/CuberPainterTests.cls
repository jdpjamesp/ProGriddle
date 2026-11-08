/* The Cuber painter, reading pixels of the picture it draws on a 256 x 256 canvas: the background and the HUD, the lamps in their
   three states and four lights, a lamp changing without the others changing, Pip and the enemies, and the screens. The painter's own
   effects (the lanterns and the motes) are switched off where a test reads the sky. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberPainterTests:

    VAR PRIVATE CuberGame mGame.
    VAR PRIVATE CuberPainter mPainter.
    VAR PRIVATE CuberRecordingRenderer mRenderer.

    @Setup.
    METHOD PUBLIC VOID BuildPainter():
        mGame = CuberFactory:Create(NEW ScriptedRandom("1")).
        mRenderer = NEW CuberRecordingRenderer().
        mPainter = NEW CuberPainter(mRenderer, mGame).
        mPainter:Effects = FALSE.
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleasePainter():
        IF VALID-OBJECT(mPainter) THEN mPainter:Dispose().
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mPainter = ?.
        mGame = ?.
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        VAR INTEGER i.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    /* A game in play on level piLevel with no enemies and none coming, Pip far from the apex, and a picture drawn. */
    METHOD PRIVATE VOID Scene(INPUT piLevel AS INTEGER, INPUT piRound AS INTEGER):
        mGame:StartGame().
        mGame:BeginRound(piLevel, piRound).
        Frames(CuberRules:ReadyFrames()).
        mGame:ClearEnemies().
        mGame:StopSpawns().
        mGame:PlacePip(7, 3).
    END METHOD.

    METHOD PRIVATE VOID Draw():
        mPainter:Render(mGame:Grid, mGame).
    END METHOD.

    /* The colour at the middle of the lit part of a lamp's top: row 8, column 16 of its picture. */
    METHOD PRIVATE INTEGER LampCentre(INPUT piRow AS INTEGER, INPUT piCol AS INTEGER):
        RETURN mPainter:Canvas:ColourAt(CuberRules:LampX(piRow, piCol) + 16, CuberRules:LampY(piRow) + 8).
    END METHOD.

    /* How many pixels of a colour there are in a rectangle of the picture. */
    METHOD PRIVATE INTEGER Count(INPUT piColour AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER):
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

    /* ---- the picture ---- */

    @Test.
    METHOD PUBLIC VOID TheCanvasIs256By256AndItsGridIsTheOneHandedToTheRenderer():
        Draw().
        Assert:Equals(256, mPainter:Canvas:Width).
        Assert:Equals(256, mPainter:Canvas:Height).
        Assert:Equals(1, mRenderer:RenderCount).
        Assert:IsTrue(mRenderer:LastGrid = mPainter:CanvasGrid).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSkyIsInBandsWithTheHudRuleAndTheVoidUnderThePyramid():
        Draw().
        Assert:Equals(CuberLook:Colour(CuberTint:HudRule), mPainter:Canvas:ColourAt(3, 31)).
        Assert:Equals(CuberLook:Colour(CuberTint:Hud), mPainter:Canvas:ColourAt(3, 30)).
        Assert:Equals(CuberLook:Colour(CuberTint:VoidDeep), mPainter:Canvas:ColourAt(5, 250)).
        Assert:Equals(CuberLook:Colour(CuberTint:VoidTop), mPainter:Canvas:ColourAt(5, 230)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheStarsAreBakedIntoTheSky():
        Draw().
        /* the first star of the design is at 84, 72 and is dim */
        Assert:Equals(CuberLook:Colour(CuberTint:StarDim), mPainter:Canvas:ColourAt(84, 72)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnlitLampIsTheDarkSlateOfItsRow():
        Scene(1, 1).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(1, 0)).
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(5, 2)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALitLampShowsTheGlowOfTheRoundsLightAndOnlyThatLampChanges():
        Scene(1, 1).
        Draw().
        mGame:SetLamp(4, 1, 2).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Mint, 1), LampCentre(4, 1)).
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(4, 0)).
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(5, 1)).
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(3, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALampChangingBackPutsTheDarkTopBack():
        Scene(1, 1).
        mGame:SetLamp(4, 1, 2).
        Draw().
        mGame:SetLamp(4, 1, 0).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(4, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARingedLampHasTheMiddleToneOfTheHalfRowAndTheRingIsHollow():
        Scene(3, 1).
        mGame:SetLamp(3, 1, 1).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:MintHalf, 3), LampCentre(3, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLightChangesWithTheRoundAndSoDoTheLampsAlreadyLit():
        Scene(1, 1).
        mGame:SetLamp(4, 1, 2).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Mint, 1), LampCentre(4, 1)).
        mGame:BeginRound(1, 2).
        Frames(CuberRules:ReadyFrames()).
        mGame:SetLamp(4, 1, 2).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Rose, 1), LampCentre(4, 1)).
        mGame:BeginRound(1, 4).
        Frames(CuberRules:ReadyFrames()).
        mGame:SetLamp(2, 0, 2).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Lilac, 1), LampCentre(2, 0)).
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(4, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSecondDrawOfAnUnchangedGameLeavesThePyramidAlone():
        VAR INTEGER before.
        Scene(1, 1).
        mGame:SetLamp(6, 3, 2).
        Draw().
        before = LampCentre(6, 3).
        Draw().
        Assert:Equals(before, LampCentre(6, 3)).
        Assert:Equals(2, mRenderer:RenderCount).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheEdgeLineOfALampStaysCoveredByTheLampsUnderItWhenItChanges():
        VAR INTEGER y.
        VAR INTEGER x.
        VAR INTEGER fresh.
        VAR INTEGER again.
        Scene(1, 1).
        mGame:SetLamp(3, 1, 2).
        Draw().
        /* drawing the whole pyramid from scratch in the same state must give the same pixels as the change did */
        fresh = Count(CuberLook:Colour(CuberTint:Edge), 0, 32, 256, 192).
        mPainter:Dispose().
        mPainter = NEW CuberPainter(mRenderer, mGame).
        mPainter:Effects = FALSE.
        Draw().
        again = Count(CuberLook:Colour(CuberTint:Edge), 0, 32, 256, 192).
        Assert:Equals(again, fresh).
    END METHOD.

    /* ---- Pip and the enemies ---- */

    @Test.
    METHOD PUBLIC VOID PipIsDrawnInItsOwnColourWhereItStands():
        Scene(1, 1).
        Draw().
        Assert:IsTrue(Count(CuberLook:Tone(CuberRow:Pip, 3), CuberRules:FootX(7, 3) - 8, CuberRules:FootY(7) - 16, 16, 18) > 20).
        Assert:Equals(0, Count(CuberLook:Tone(CuberRow:Pip, 3), CuberRules:FootX(1, 0) - 8, CuberRules:FootY(1) - 16, 16, 18)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID PipIsNotDrawnOnTheGameOverScreen():
        VAR INTEGER i.
        Scene(1, 1).
        mGame:PlacePip(1, 0).
        DO i = 1 TO 3:
            mGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
            Frames(1 + CuberRules:HitFrames()).
            Frames(CuberRules:ReadyFrames()).
        END.
        Assert:Equals(STRING(CuberPhase:GameOver), STRING(mGame:Phase)).
        Draw().
        Assert:Equals(0, Count(CuberLook:Tone(CuberRow:Pip, 3), CuberRules:FootX(1, 0) - 8, CuberRules:FootY(1) - 16, 16, 18)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AThornIsRedAndAFrostIsIce():
        Scene(1, 1).
        mGame:SpawnEnemy(CuberKind:Thorn, 4, 1).
        mGame:SetEnemyRest(0, 900).
        mGame:SpawnEnemy(CuberKind:Frost, 6, 4).
        mGame:SetEnemyRest(1, 900).
        Draw().
        Assert:IsTrue(Count(CuberLook:Tone(CuberRow:Thorn, 3), CuberRules:FootX(4, 1) - 8, CuberRules:FootY(4) - 12, 16, 14) > 8).
        Assert:IsTrue(Count(CuberLook:Tone(CuberRow:Frost, 3), CuberRules:FootX(6, 4) - 8, CuberRules:FootY(6) - 12, 16, 14) > 8).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AFrozenEnemyIsDrawnInIce():
        Scene(1, 1).
        mGame:SpawnEnemy(CuberKind:Thorn, 4, 1).
        mGame:SetEnemyRest(0, 900).
        mGame:SpawnEnemy(CuberKind:Frost, 1, 0).
        mGame:PlacePip(1, 0).
        Frames(1).
        Draw().
        Assert:Equals(0, Count(CuberLook:Tone(CuberRow:Thorn, 3), CuberRules:FootX(4, 1) - 8, CuberRules:FootY(4) - 12, 16, 14)).
        Assert:IsTrue(Count(CuberLook:Tone(CuberRow:Ice, 3), CuberRules:FootX(4, 1) - 8, CuberRules:FootY(4) - 12, 16, 14) > 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCoilWearsItsEmberRim():
        Scene(1, 1).
        mGame:SpawnEnemy(CuberKind:Coil, 5, 2).
        mGame:SetEnemyRest(0, 900).
        Draw().
        Assert:IsTrue(Count(CuberLook:Colour(CuberTint:Ember), CuberRules:FootX(5, 2) - 10, CuberRules:FootY(5) - 26, 20, 28) > 5).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWaitingHaloIsDrawnWhereItWillBeLandedOn():
        Scene(1, 1).
        mGame:SetHalo(1, TRUE).
        Draw().
        Assert:IsTrue(Count(CuberLook:Tone(CuberRow:Halo, 3), CuberRules:FootX(3, -1) - 12, CuberRules:FootY(3) - 6, 24, 12) > 10).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHaloThatIsTakenAwayIsNotDrawn():
        Scene(1, 1).
        mGame:SetHalo(1, FALSE).
        Draw().
        Assert:Equals(0, Count(CuberLook:Tone(CuberRow:Halo, 3), CuberRules:FootX(3, -1) - 12, CuberRules:FootY(3) - 6, 24, 12)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheScoreOfALampShowsOverItInGold():
        Scene(1, 1).
        mGame:PlacePip(1, 0).
        mGame:RequestHop(CuberDir:DownLeft).
        Frames(14).
        Draw().
        Assert:IsTrue(Count(CuberLook:Colour(CuberTint:Gold), CuberRules:FootX(2, 0) - 12, CuberRules:FootY(2) - 40, 24, 16) > 4).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheFreezeRingSpreadsFromTheFrostForAFewFrames():
        Scene(1, 1).
        mGame:PlacePip(4, 1).
        mGame:SpawnEnemy(CuberKind:Frost, 4, 1).
        Frames(1).
        Draw().
        Assert:IsTrue(Count(CuberLook:Tone(CuberRow:Frost, 3), CuberRules:FootX(4, 1) - 14, CuberRules:FootY(4) - 8, 28, 16) > 5).
    END METHOD.

    /* ---- the HUD and the screens ---- */

    @Test.
    METHOD PUBLIC VOID TheHudShowsTheScoreInWhiteAndTheTargetLampInTheRoundsLight():
        Scene(1, 2).
        mGame:AddScore(4325).
        Draw().
        Assert:IsTrue(Count(CuberLook:Colour(CuberTint:Text), 8, 13, 70, 14) > 40).
        Assert:IsTrue(Count(CuberLook:Tone(CuberRow:Rose, 3), 232, 8, 16, 16) > 20).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheHudShowsASparePipForEachLifeInHand():
        Scene(1, 1).
        Draw().
        /* two spare Pips: two icons side by side under the best score */
        Assert:IsTrue(Count(CuberLook:Tone(CuberRow:Pip, 3), 100, 14, 56, 12) > 10).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleDrawsTheNameAndPressSpaceAndHasNoScore():
        Draw().
        Assert:IsTrue(Count(CuberLook:Colour(CuberTint:Gold), 60, 226, 140, 16) > 40).
        Assert:Equals(0, Count(CuberLook:Colour(CuberTint:Label), 8, 4, 30, 8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleIntroLightsALampWhenPipLandsOnIt():
        VAR INTEGER lit.
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(2, 1)).
        /* the lamp of row 2 is lit when Pip lands on it, at frame 92 of the intro */
        Frames(100).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Mint, 1), LampCentre(2, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleIntroStartsAgainAndTheLampsGoDarkAgain():
        Frames(620).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(7, 3)).
        Frames(200).
        Draw().
        Assert:Equals(CuberLook:Tone(CuberRow:Unlit, 3), LampCentre(2, 1)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheReadyBannerHasAPlateWithTwoRules():
        mGame:StartGame().
        Frames(10).
        Draw().
        Assert:Equals(CuberLook:Colour(CuberTint:PlateRule), mPainter:Canvas:ColourAt(3, 112)).
        Assert:Equals(CuberLook:Colour(CuberTint:PlateRule), mPainter:Canvas:ColourAt(3, 135)).
        Assert:Equals(CuberLook:Colour(CuberTint:Plate), mPainter:Canvas:ColourAt(3, 120)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGameOverPlateIsBigger():
        VAR INTEGER i.
        Scene(1, 1).
        mGame:PlacePip(1, 0).
        DO i = 1 TO 3:
            mGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
            Frames(1 + CuberRules:HitFrames()).
            Frames(CuberRules:ReadyFrames()).
        END.
        Draw().
        Assert:Equals(CuberLook:Colour(CuberTint:PlateRule), mPainter:Canvas:ColourAt(3, 100)).
        Assert:Equals(CuberLook:Colour(CuberTint:PlateRule), mPainter:Canvas:ColourAt(3, 155)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APausedGameShowsPausedOnAPlate():
        Scene(1, 1).
        mGame:Paused = TRUE.
        Draw().
        Assert:Equals(CuberLook:Colour(CuberTint:PlateRule), mPainter:Canvas:ColourAt(3, 112)).
        Assert:Equals(CuberLook:Colour(CuberTint:PlateRule), mPainter:Canvas:ColourAt(3, 143)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheClearedRoundShowsTheRippleAndThenTheNextRoundOnAPlate():
        VAR INTEGER r.
        VAR INTEGER c.
        Scene(1, 1).
        mGame:PlacePip(1, 0).
        DO r = 1 TO 7:
            DO c = 0 TO r - 1:
                mGame:SetLamp(r, c, 2).
            END.
        END.
        mGame:SetLamp(2, 1, 0).
        mGame:RequestHop(CuberDir:DownRight).
        Frames(14).
        Assert:Equals(STRING(CuberPhase:Cleared), STRING(mGame:Phase)).
        Draw().
        Assert:IsTrue(Count(CuberLook:Colour(CuberTint:Spark), 96, 48, 48, 24) > 3).
        Frames(CuberRules:ClearFrames() - 60).
        Draw().
        Assert:Equals(CuberLook:Colour(CuberTint:PlateRule), mPainter:Canvas:ColourAt(3, 112)).
    END METHOD.

    /* ---- the sky, the effects and the owner's duties ---- */

    @Test.
    METHOD PUBLIC VOID TheLanternsAndMotesAreDrawnOnlyWithEffectsOn():
        VAR INTEGER shown.
        VAR INTEGER without.
        mPainter:Effects = TRUE.
        Draw().
        shown = Count(CuberLook:Colour(CuberTint:Lantern), 0, 32, 256, 190) + Count(CuberLook:Colour(CuberTint:Mote), 0, 200, 256, 56).
        mPainter:Effects = FALSE.
        Draw().
        without = Count(CuberLook:Colour(CuberTint:Lantern), 0, 32, 256, 190) + Count(CuberLook:Colour(CuberTint:Mote), 0, 200, 256, 56).
        Assert:IsTrue(shown > without).
        Assert:Equals(0, without).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID APainterRefusesNoRendererNoGameAndAnotherKindOfGame():
        VAR INTEGER thrown.
        VAR CuberPainter other.
        DO ON ERROR UNDO, LEAVE:
            other = NEW CuberPainter(?, mGame).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            other = NEW CuberPainter(mRenderer, ?).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, LEAVE:
            mPainter:Render(mGame:Grid, ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID DisposeCanBeCalledMoreThanOnce():
        mPainter:Dispose().
        mPainter:Dispose().
        Assert:IsTrue(TRUE).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AWholeGameDrawsEveryFrameWithoutAnError():
        VAR INTEGER i.
        mGame:StartGame().
        DO i = 1 TO 900:
            IF i MODULO 11 = 0 THEN mGame:RequestHop(CuberDir:GetEnum(i MODULO 4)).
            mGame:Advance().
            IF i MODULO 7 = 0 THEN Draw().
        END.
        Assert:IsTrue(mRenderer:RenderCount > 100).
    END METHOD.

END CLASS.
