/* When the sounds of Asteroids happen: a cue source (ICueSource) and loop source (ILoopSource) that look at the game after each
   change of the picture. They compare the game's own running counts with the ones last seen (the shots fired, the saucer shots,
   the rocks broken and the saucers destroyed, which never go back, and the ships left), so two events in the same millisecond
   are still two. The size of the rock that broke chooses its sound: a large one booms low, a small one cracks.

   Nothing sounds on the title screen: the state is only taken as it is, so a new game, whose ships start again, makes no noise.
   The thrust is a rumble that loops for as long as the ship thrusts, and each saucer hums, a loop, for as long as it is out (the
   large one low and the small one high). A paused game, a title screen and a finished game have no loops.

   The cues come most important first: the ship breaking up, an extra ship, a saucer destroyed, a rock breaking, a saucer's shot,
   hyperspace, the ship's shot. A saucer destroyed and a rock breaking in the same moment make one sound (a saucer that flies into
   a rock), and the rest are groups of their own, so they sound together. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsCues FINAL IMPLEMENTS ICueSource, ILoopSource:

    DEFINE PRIVATE VARIABLE mPhase   AS GamePhase NO-UNDO.
    DEFINE PRIVATE VARIABLE mLives   AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mShots   AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucShots AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBroken  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucers AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mHyper   AS LOGICAL   NO-UNDO.

    /* Throws GridException for a game that is not an AsteroidsGame. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS AsteroidsGame NO-UNDO.
        DEFINE VARIABLE cues  AS CHARACTER     NO-UNDO.
        IF NOT TYPE-OF(poGame, AsteroidsGame) THEN UNDO, THROW NEW GridException("The cues of Asteroids need an Asteroids game").
        oGame = CAST(poGame, AsteroidsGame).
        /* the first look and the title screen: take the state as it is, and say nothing */
        IF NOT VALID-OBJECT(mPhase) OR mPhase = GamePhase:Title THEN DO:
            Remember(oGame).
            RETURN "".
        END.
        IF oGame:Lives < mLives THEN cues = WithCue(cues, INTEGER(AsteroidsCue:ShipDies)).
        IF oGame:Lives > mLives THEN cues = WithCue(cues, INTEGER(AsteroidsCue:ExtraShip)).
        IF oGame:SaucersDestroyed > mSaucers THEN cues = WithCue(cues, INTEGER(AsteroidsCue:SaucerDies)).
        IF oGame:RocksBroken > mBroken THEN cues = WithCue(cues, INTEGER(AsteroidsCue:RockLarge) + MINIMUM(2, MAXIMUM(0, oGame:LastBrokenSize - 1))).
        IF oGame:SaucerShotsFired > mSaucShots THEN cues = WithCue(cues, INTEGER(AsteroidsCue:SaucerFire)).
        IF oGame:Hyperspacing AND NOT mHyper THEN cues = WithCue(cues, INTEGER(AsteroidsCue:Hyperspace)).
        IF oGame:ShotsFired > mShots THEN cues = WithCue(cues, INTEGER(AsteroidsCue:Fire)).
        Remember(oGame).
        RETURN cues.
    END METHOD.

    /* The thrust rumbles while the ship thrusts, and a saucer hums while it is out, in a game that is being played and is not paused. */
    METHOD PUBLIC CHARACTER Loops(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS AsteroidsGame NO-UNDO.
        DEFINE VARIABLE loops AS CHARACTER     NO-UNDO.
        IF NOT TYPE-OF(poGame, AsteroidsGame) THEN UNDO, THROW NEW GridException("The cues of Asteroids need an Asteroids game").
        oGame = CAST(poGame, AsteroidsGame).
        IF oGame:Phase <> GamePhase:Playing OR oGame:Paused THEN RETURN "".
        IF oGame:ShipAlive AND oGame:Thrusting THEN loops = STRING(INTEGER(AsteroidsCue:ThrustLoop)).
        IF oGame:SaucerActive THEN
            loops = loops + (IF loops = "" THEN "" ELSE ",")
                  + STRING(IF oGame:SaucerLarge THEN INTEGER(AsteroidsCue:SaucerLargeHum) ELSE INTEGER(AsteroidsCue:SaucerSmallHum)).
        RETURN loops.
    END METHOD.

    /* The three rock sounds and a saucer destroyed are one group (the saucer first); every other cue has a group of its own. */
    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        CASE piCue:
            WHEN INTEGER(AsteroidsCue:Fire) THEN RETURN 1.
            WHEN INTEGER(AsteroidsCue:RockLarge) OR WHEN INTEGER(AsteroidsCue:RockMedium) OR WHEN INTEGER(AsteroidsCue:RockSmall)
                OR WHEN INTEGER(AsteroidsCue:SaucerDies) THEN RETURN 2.
            WHEN INTEGER(AsteroidsCue:ShipDies) THEN RETURN 3.
            WHEN INTEGER(AsteroidsCue:SaucerFire) THEN RETURN 4.
            WHEN INTEGER(AsteroidsCue:Hyperspace) THEN RETURN 5.
            WHEN INTEGER(AsteroidsCue:ExtraShip) THEN RETURN 6.
            OTHERWISE RETURN 7.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID Remember(INPUT poGame AS AsteroidsGame):
        mPhase = poGame:Phase.
        mLives = poGame:Lives.
        mShots = poGame:ShotsFired.
        mSaucShots = poGame:SaucerShotsFired.
        mBroken = poGame:RocksBroken.
        mSaucers = poGame:SaucersDestroyed.
        mHyper = poGame:Hyperspacing.
    END METHOD.

    METHOD PRIVATE CHARACTER WithCue(INPUT pcCues AS CHARACTER, INPUT piCue AS INTEGER):
        RETURN pcCues + (IF pcCues = "" THEN "" ELSE ",") + STRING(piCue).
    END METHOD.

END CLASS.
