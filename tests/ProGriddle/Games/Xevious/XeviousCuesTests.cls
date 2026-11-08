/* The cue source of Xevious, with real games driven by hand: each event is reported once, the title is silent, the groups say which
   sounds replace which, and the mothership's hum loops while it is out. Cue numbers are INTEGER(XeviousCue:...). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousCuesTests:

    VAR PRIVATE XeviousGame mGame.
    VAR PRIVATE XeviousCues mCues.

    /* A game in play on an empty field, the ship at 104, 208, and the cue source up to date. */
    @Setup.
    METHOD PUBLIC VOID BuildCues():
        mGame = XeviousFactory:Create(NEW ScriptedRandom("1")).
        mCues = NEW XeviousCues().
        /* the first look takes the title as it is, and the next the new game */
        mCues:Poll(mGame).
        mGame:StartGame().
        mGame:StopWaves().
        mGame:ClearGround().
        mGame:ClearAir().
        mGame:PlacePlayer(104, 208).
        mCues:Poll(mGame).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCues():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
        mCues = ?.
    END METHOD.

    METHOD PRIVATE CHARACTER N(INPUT poCue AS XeviousCue):
        RETURN STRING(INTEGER(poCue)).
    END METHOD.

    METHOD PRIVATE VOID Frames(INPUT piCount AS INTEGER):
        VAR INTEGER i.
        DO i = 1 TO piCount:
            mGame:Advance().
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTitleScreenIsSilent():
        VAR XeviousGame oGame.
        VAR XeviousCues oCues.
        oGame = XeviousFactory:Create(NEW ScriptedRandom("1")).
        oCues = NEW XeviousCues().
        Assert:Equals("", oCues:Poll(oGame)).
        oGame:ZapHeld = TRUE.
        oGame:Advance().
        Assert:Equals("", oCues:Poll(oGame)).
        oGame:Dispose().
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AShotIsReportedOnceAndNothingIsReportedWhenNothingHappens():
        Assert:Equals("", mCues:Poll(mGame)).
        mGame:ZapHeld = TRUE.
        mGame:Advance().
        Assert:Equals(N(XeviousCue:Zap), mCues:Poll(mGame)).
        Assert:Equals("", mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombIsReportedWhenItDropsAndWhenItLands():
        mGame:BombHeld = TRUE.
        mGame:Advance().
        mGame:BombHeld = FALSE.
        Assert:Equals(N(XeviousCue:BombDrop), mCues:Poll(mGame)).
        Frames(26).
        Assert:Equals(N(XeviousCue:BombBurst), mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnAirKillAndAGroundKillSoundDifferent():
        mGame:SpawnAir(XeviousAir:Zakato, 104, 120).
        mGame:ZapHeld = TRUE.
        Frames(20).
        mGame:ZapHeld = FALSE.
        Assert:IsTrue(INDEX("," + mCues:Poll(mGame) + ",", "," + N(XeviousCue:AirKill) + ",") > 0).
        mGame:PlaceGround(XeviousGround:Barra, 104, 120).
        mGame:BombHeld = TRUE.
        Frames(27).
        mGame:BombHeld = FALSE.
        Assert:IsTrue(INDEX("," + mCues:Poll(mGame) + ",", "," + N(XeviousCue:GroundKill) + ",") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AHiddenTowerAndAFlagHaveSoundsOfTheirOwn():
        mGame:PlaceGround(XeviousGround:Sol, 104, 120).
        mGame:BombHeld = TRUE.
        Frames(27).
        mGame:BombHeld = FALSE.
        Assert:IsTrue(INDEX("," + mCues:Poll(mGame) + ",", "," + N(XeviousCue:SolFound) + ",") > 0).
        mGame:ClearGround().
        mGame:PlaceGround(XeviousGround:Flag, 104, 120).
        mGame:BombHeld = TRUE.
        Frames(60).
        mGame:BombHeld = FALSE.
        Assert:IsTrue(INDEX("," + mCues:Poll(mGame) + ",", "," + N(XeviousCue:FlagFound) + ",") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ADeathAndAnExtraShipAreReported():
        mGame:AddScore(20000).
        Assert:Equals(N(XeviousCue:ExtraLife), mCues:Poll(mGame)).
        mGame:SpawnAir(XeviousAir:Toroid, mGame:PlayerX, mGame:PlayerY).
        mGame:Advance().
        Assert:Equals(N(XeviousCue:PlayerDies), mCues:Poll(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EnemyFireAndAShotTurnedAwayAreReported():
        mGame:SpawnAir(XeviousAir:Zakato, 20, 100).
        Frames(40).
        Assert:IsTrue(INDEX("," + mCues:Poll(mGame) + ",", "," + N(XeviousCue:EnemyFire) + ",") > 0).
        mGame:ClearAir().
        mGame:SpawnAir(XeviousAir:Bacura, 104, 100).
        mGame:ZapHeld = TRUE.
        Frames(40).
        Assert:IsTrue(INDEX("," + mCues:Poll(mGame) + ",", "," + N(XeviousCue:Clang) + ",") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheMothershipHumsWhileItIsOutAndNotWhenPaused():
        Assert:Equals("", mCues:Loops(mGame)).
        mGame:SpawnBoss().
        Assert:Equals(N(XeviousCue:BossLoop), mCues:Loops(mGame)).
        mGame:Paused = TRUE.
        Assert:Equals("", mCues:Loops(mGame)).
        mGame:Paused = FALSE.
        mGame:ClearBoss().
        Assert:Equals("", mCues:Loops(mGame)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheGroupsSayWhichSoundsReplaceWhich():
        Assert:IsTrue(mCues:GroupOf(INTEGER(XeviousCue:BossHit)) = mCues:GroupOf(INTEGER(XeviousCue:BossKill))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(XeviousCue:AirKill)) = mCues:GroupOf(INTEGER(XeviousCue:Clang))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(XeviousCue:Zap)) <> mCues:GroupOf(INTEGER(XeviousCue:AirKill))).
        Assert:IsTrue(mCues:GroupOf(INTEGER(XeviousCue:PlayerDies)) <> mCues:GroupOf(INTEGER(XeviousCue:ExtraLife))).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ItOnlyTakesAXeviousGame():
        VAR INTEGER thrown.
        VAR CHARACTER c.
        DO ON ERROR UNDO, THROW:
            c = mCues:Poll(?).
            CATCH e1 AS Progress.Lang.Error:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            c = mCues:Loops(?).
            CATCH e2 AS Progress.Lang.Error:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
    END METHOD.

END CLASS.
