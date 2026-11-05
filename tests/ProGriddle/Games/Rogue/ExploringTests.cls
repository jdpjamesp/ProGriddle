/* Searching for secret doors and hidden traps. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.ExploringTests:

    DEFINE PRIVATE VARIABLE mWorld AS RogueWorld NO-UNDO.

    METHOD PRIVATE VOID Build(INPUT pcScript AS CHARACTER):
        mWorld = NEW RogueWorld(LevelMap:CreateGrid(), NEW ScriptedRandom(pcScript)).
        mWorld:NewHero().
        mWorld:ClearLevel().
        mWorld:CarveRoom(5, 5, 10, 4).
        mWorld:PlaceHero(14, 6).
        mWorld:Cave:SetTerrain(15, 6, Terrain:SecretDown).
        mWorld:Cave:SetTrap(13, 7, INTEGER(TrapKind:BearTrap) + 1).
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseScene():
        IF VALID-OBJECT(mWorld) THEN mWorld:Dispose().
        mWorld = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ALuckySearchFindsASecretDoorAndAHiddenTrapNextToTheHero():
        Build("0").
        Assert:Equals(2, Exploring:Search(mWorld)).
        Assert:Equals(INTEGER(Terrain:Door), mWorld:Cave:TerrainAt(15, 6)).
        Assert:IsTrue(mWorld:Cave:TrapFound(13, 7)).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "You find a secret door.") > 0).
        Assert:IsTrue(INDEX(mWorld:Messages:Line(200), "You find a bear trap.") > 0).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AnUnluckySearchFindsNothing():
        Build("1").
        Assert:Equals(0, Exploring:Search(mWorld)).
        Assert:Equals(INTEGER(Terrain:SecretDown), mWorld:Cave:TerrainAt(15, 6)).
        Assert:IsFalse(mWorld:Cave:TrapFound(13, 7)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhatIsFurtherThanOneSquareIsNotFound():
        Build("0").
        mWorld:PlaceHero(10, 6).
        Assert:Equals(0, Exploring:Search(mWorld)).
        Assert:Equals(INTEGER(Terrain:SecretDown), mWorld:Cave:TerrainAt(15, 6)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ATrapAlreadyFoundIsNotFoundAgain():
        Build("0").
        mWorld:Cave:SetTrapFound(13, 7, TRUE).
        Assert:Equals(1, Exploring:Search(mWorld)).
    END METHOD.

END CLASS.
