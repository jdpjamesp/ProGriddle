/* The numbers of Xevious: the field and the ground, the stages and the laps, the ship's weapons, and the points, first stages and hit
   points of every enemy. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousRulesTests:

    @Test.
    METHOD PUBLIC VOID TheFieldIs224By256MadeOfTilesOf16():
        Assert:Equals(224, XeviousRules:FieldWidth()).
        Assert:Equals(256, XeviousRules:FieldHeight()).
        Assert:Equals(16, XeviousRules:Tile()).
        Assert:Equals(14, XeviousRules:Cols()).
        Assert:Equals(XeviousRules:FieldWidth(), XeviousRules:Cols() * XeviousRules:Tile()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AStageIs120RowsAndTheGameHas16Stages():
        Assert:Equals(16, XeviousRules:Stages()).
        Assert:Equals(120, XeviousRules:StageRows()).
        Assert:Equals(2, XeviousRules:ScrollNum()).
        Assert:Equals(3, XeviousRules:ScrollDen()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID StagesGoRoundAfter16AndCountTheLaps():
        Assert:Equals(1, XeviousRules:StageOf(1)).
        Assert:Equals(16, XeviousRules:StageOf(16)).
        Assert:Equals(1, XeviousRules:StageOf(17)).
        Assert:Equals(5, XeviousRules:StageOf(37)).
        Assert:Equals(0, XeviousRules:LapOf(16)).
        Assert:Equals(1, XeviousRules:LapOf(17)).
        Assert:Equals(2, XeviousRules:LapOf(33)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryFourthStageEndsWithTheMothership():
        Assert:IsFalse(XeviousRules:HasBoss(1)).
        Assert:IsFalse(XeviousRules:HasBoss(3)).
        Assert:IsTrue(XeviousRules:HasBoss(4)).
        Assert:IsTrue(XeviousRules:HasBoss(16)).
        Assert:IsTrue(XeviousRules:HasBoss(20)).
        Assert:Equals(3, XeviousRules:BossHp()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShipAndItsWeaponsHaveTheirNumbers():
        Assert:Equals(2, XeviousRules:PlayerSpeed()).
        Assert:Equals(16, XeviousRules:PlayerSize()).
        Assert:Equals(8, XeviousRules:PlayerBox()).
        Assert:Equals(2, XeviousRules:ZapMax()).
        Assert:Equals(6, XeviousRules:ZapSpeed()).
        Assert:Equals(7, XeviousRules:ZapCooldown()).
        Assert:Equals(88, XeviousRules:SightDistance()).
        Assert:Equals(26, XeviousRules:BombFlight()).
        Assert:Equals(8, XeviousRules:BlastRadius()).
        Assert:Equals(14, XeviousRules:BlastFrames()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheLivesTheTimingsAndTheBonusesHaveTheirNumbers():
        Assert:Equals(3, XeviousRules:StartLives()).
        Assert:Equals(90, XeviousRules:DyingFrames()).
        Assert:Equals(150, XeviousRules:ProtectFrames()).
        Assert:Equals(300, XeviousRules:ClearFrames()).
        Assert:Equals(480, XeviousRules:CheckpointEvery()).
        Assert:Equals(20000, XeviousRules:ExtraLifeFirst()).
        Assert:Equals(60000, XeviousRules:ExtraLifeEvery()).
        Assert:Equals(30, XeviousRules:BonusPerPercent()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryAirEnemyHasPointsAndAFirstStage():
        VAR INTEGER i.
        DO i = INTEGER(XeviousAir:Toroid) TO INTEGER(XeviousAir:Bacura):
            Assert:IsTrue(XeviousRules:AirPoints(XeviousAir:GetEnum(i)) > 0).
            Assert:IsTrue(XeviousRules:AirFirstStage(XeviousAir:GetEnum(i)) >= 1).
        END.
        Assert:Equals(30, XeviousRules:AirPoints(XeviousAir:Toroid)).
        Assert:Equals(1000, XeviousRules:AirPoints(XeviousAir:Kapi)).
        Assert:Equals(1, XeviousRules:AirFirstStage(XeviousAir:Toroid)).
        Assert:Equals(5, XeviousRules:AirFirstStage(XeviousAir:Terrazi)).
        Assert:Equals(40, XeviousRules:BacuraHits()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryGroundTargetHasPointsHitPointsAndAFirstStage():
        VAR INTEGER i.
        DO i = INTEGER(XeviousGround:Barra) TO INTEGER(XeviousGround:Flag):
            Assert:IsTrue(XeviousRules:GroundHp(XeviousGround:GetEnum(i)) >= 1).
            Assert:IsTrue(XeviousRules:GroundFirstStage(XeviousGround:GetEnum(i)) >= 1).
            Assert:IsTrue(XeviousRules:GroundPoints(XeviousGround:GetEnum(i)) >= 0).
        END.
        Assert:Equals(10, XeviousRules:GroundPoints(XeviousGround:Barra)).
        Assert:Equals(2000, XeviousRules:GroundPoints(XeviousGround:Sol)).
        Assert:Equals(0, XeviousRules:GroundPoints(XeviousGround:Flag)).
        Assert:Equals(2, XeviousRules:GroundHp(XeviousGround:GaruBarra)).
        Assert:Equals(1, XeviousRules:GroundHp(XeviousGround:Barra)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyTheSolAndTheFlagAreHiddenAndTheyAreNeverChosenByWeight():
        Assert:IsTrue(XeviousRules:IsHidden(XeviousGround:Sol)).
        Assert:IsTrue(XeviousRules:IsHidden(XeviousGround:Flag)).
        Assert:IsFalse(XeviousRules:IsHidden(XeviousGround:Barra)).
        Assert:Equals(0, XeviousRules:GroundWeight(XeviousGround:Sol)).
        Assert:Equals(40, XeviousRules:GroundWeight(XeviousGround:Barra)).
        Assert:Equals(4, XeviousRules:GroundWeight(XeviousGround:GaruZakato)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID BulletsGetFasterAndWavesComeSoonerAsTheGameGoesOn():
        Assert:Equals(24, XeviousRules:MostBullets()).
        Assert:IsTrue(XeviousRules:BulletSpeed(16) > XeviousRules:BulletSpeed(1)).
        Assert:IsTrue(XeviousRules:BulletSpeed(17) > XeviousRules:BulletSpeed(1)).
        Assert:IsTrue(XeviousRules:WaveDelay(16) < XeviousRules:WaveDelay(1)).
        Assert:IsTrue(XeviousRules:WaveDelay(1000) >= 50).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnknownEnemyHasNoPoints():
        VAR XeviousAir oKind.
        VAR INTEGER thrown.
        oKind = ?.
        DO ON ERROR UNDO, THROW:
            XeviousRules:AirPoints(oKind).
            CATCH e1 AS Progress.Lang.Error:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
    END METHOD.

END CLASS.
