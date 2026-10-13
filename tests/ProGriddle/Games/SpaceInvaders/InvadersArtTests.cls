/* The pictures are the place to change the art, so these tests hold on to what the rules rely on: the sizes. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersArtTests:

    {ProGriddle/Games/SpaceInvaders/Art.i}

    METHOD PRIVATE LOGICAL Size(INPUT poSprite AS Sprite, INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER):
        RETURN poSprite:Width = piWidth AND poSprite:Height = piHeight.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryPictureIsThereAndIsNotEmpty():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        Assert:IsTrue(InvadersArt:Count() > 30).
        DO i = 1 TO InvadersArt:Count():
            Assert:IsTrue(InvadersArt:Picture(i):Count > 0, "picture " + STRING(i)).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ThePicturesAreMadeOnceAndHandedOutAgain():
        Assert:IsTrue(InvadersArt:Picture({&ART-CANNON}) = InvadersArt:Picture({&ART-CANNON})).
        Assert:IsTrue(InvadersArt:Invader(1, 0) = InvadersArt:Invader(1, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInvadersAreEightElevenAndTwelveWideAndEightHighInBothPoses():
        Assert:IsTrue(Size(InvadersArt:Invader(0, 0), 8, 8)).
        Assert:IsTrue(Size(InvadersArt:Invader(0, 1), 8, 8)).
        Assert:IsTrue(Size(InvadersArt:Invader(1, 0), 11, 8)).
        Assert:IsTrue(Size(InvadersArt:Invader(1, 1), 11, 8)).
        Assert:IsTrue(Size(InvadersArt:Invader(2, 0), 12, 8)).
        Assert:IsTrue(Size(InvadersArt:Invader(2, 1), 12, 8)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheTwoPosesOfAnInvaderAreDifferentPictures():
        Assert:IsTrue(InvadersArt:Invader(0, 0):ToString() <> InvadersArt:Invader(0, 1):ToString()).
        Assert:IsTrue(InvadersArt:Invader(1, 0):ToString() <> InvadersArt:Invader(1, 1):ToString()).
        Assert:IsTrue(InvadersArt:Invader(2, 0):ToString() <> InvadersArt:Invader(2, 1):ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheInvaderPicturesMatchTheWidthsThatTheRackUses():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DO k = 0 TO 2:
            Assert:Equals(InvaderRack:WidthOfKind(k), InvadersArt:Invader(k, 0):Width).
            Assert:Equals(InvaderRack:SpriteHeight(), InvadersArt:Invader(k, 1):Height).
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCannonTheSaucerTheShieldAndTheShotHaveTheArcadeSizes():
        Assert:IsTrue(Size(InvadersArt:Picture({&ART-CANNON}), 13, 8)).
        Assert:IsTrue(Size(InvadersArt:Picture({&ART-SAUCER}), 16, 7)).
        Assert:IsTrue(Size(InvadersArt:Picture({&ART-SHIELD}), 22, 16)).
        Assert:IsTrue(Size(InvadersArt:Picture({&ART-SHOT}), 1, 4)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryBombIsThreeWideAndSevenHighInAllFourFramesOfAllThreeTypes():
        DEFINE VARIABLE t AS INTEGER NO-UNDO.
        DEFINE VARIABLE f AS INTEGER NO-UNDO.
        DO t = 0 TO 2:
            DO f = 0 TO 3:
                Assert:IsTrue(Size(InvadersArt:Bomb(t, f), 3, 7), SUBSTITUTE("bomb &1 frame &2", t, f)).
            END.
        END.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABombFrameWrapsAroundSoAnyFrameCountWorks():
        Assert:IsTrue(InvadersArt:Bomb(1, 4) = InvadersArt:Bomb(1, 0)).
        Assert:IsTrue(InvadersArt:Bomb(2, 7) = InvadersArt:Bomb(2, 3)).
        Assert:IsTrue(InvadersArt:Bomb(0, ?) = InvadersArt:Bomb(0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheBombTypesLookDifferent():
        Assert:IsTrue(InvadersArt:Bomb(0, 0):ToString() <> InvadersArt:Bomb(1, 0):ToString()).
        Assert:IsTrue(InvadersArt:Bomb(1, 0):ToString() <> InvadersArt:Bomb(2, 0):ToString()).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheShieldHasAnArchCutOutOfItsBottom():
        DEFINE VARIABLE s AS Sprite NO-UNDO.
        s = InvadersArt:Picture({&ART-SHIELD}).
        Assert:Equals(0, s:ToneAt(11, 15)).
        Assert:Equals(0, s:ToneAt(7, 12)).
        Assert:Equals(1, s:ToneAt(11, 11)).
        Assert:Equals(1, s:ToneAt(0, 15)).
        Assert:Equals(0, s:ToneAt(0, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheChipsThatEatAShieldComeInThreeVariantsForEachKind():
        DEFINE VARIABLE k AS INTEGER NO-UNDO.
        DEFINE VARIABLE v AS INTEGER NO-UNDO.
        DO k = 0 TO 1:
            DO v = 0 TO 2:
                Assert:IsTrue(InvadersArt:Chip(k, v):Count > 8).
            END.
        END.
        Assert:IsTrue(InvadersArt:Chip(0, 3) = InvadersArt:Chip(0, 0)).
        Assert:IsTrue(InvadersArt:Chip(1, ?) = InvadersArt:Chip(1, 0)).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ABadPictureKindOrPoseIsRefused():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            InvadersArt:Picture(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvadersArt:Picture(InvadersArt:Count() + 1).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvadersArt:Invader(3, 0).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvadersArt:Invader(0, 2).
            CATCH e4 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvadersArt:Bomb(3, 0).
            CATCH e5 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            InvadersArt:Chip(2, 0).
            CATCH e6 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(6, thrown).
    END METHOD.

END CLASS.
