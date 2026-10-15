/* When the sounds of Space Invaders happen: a cue source (ICueSource) and loop source (ILoopSource) that look at the game after
   each change of the picture. They compare the game's own counters with the ones last seen (the shots fired, the invaders alive,
   the passes the rack has made, the cannons left, the score, the phase), so two events in the same millisecond are still two.

   Nothing sounds on the title screen or while a wave is being drawn in: the state is only taken as it is, so a new game, whose
   counters start again, makes no noise. The rack's march is four notes in turn, one for each pass the rack finishes (so it speeds
   up as the invaders die, as the arcade's did), and the saucer hums, a loop, for as long as it is out.

   The cues come most important first: the cannon blowing up, the end of the wave, the saucer hit, an invader hit, an extra cannon,
   the shot, the march note. The shot, the kills, the cannon blowing up, the march and the two fanfares are priority groups of
   their own, so they sound together, and only a saucer hit and an invader hit in the same moment make one sound. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvadersCues FINAL IMPLEMENTS ICueSource, ILoopSource:

    DEFINE PRIVATE VARIABLE mPhase  AS GamePhase NO-UNDO.
    DEFINE PRIVATE VARIABLE mLives  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mAlive  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mShots  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mPasses AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mScore  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSaucer AS LOGICAL   NO-UNDO.
    /* which of the four march notes comes next, 0 to 3 */
    DEFINE PRIVATE VARIABLE mMarch  AS INTEGER   NO-UNDO.

    /* Throws GridException for a game that is not a SpaceInvadersGame. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS SpaceInvadersGame NO-UNDO.
        DEFINE VARIABLE cues  AS CHARACTER         NO-UNDO.
        IF NOT TYPE-OF(poGame, SpaceInvadersGame) THEN UNDO, THROW NEW GridException("The cues of Space Invaders need a Space Invaders game").
        oGame = CAST(poGame, SpaceInvadersGame).
        /* the first look, the title screen and a wave being drawn in: take the state as it is, and say nothing */
        IF NOT VALID-OBJECT(mPhase) OR mPhase = GamePhase:Title OR mPhase = GamePhase:Starting THEN DO:
            Remember(oGame).
            RETURN "".
        END.
        IF oGame:Phase = GamePhase:Dying AND mPhase <> GamePhase:Dying THEN cues = WithCue(cues, INTEGER(InvadersCue:PlayerDies)).
        IF oGame:Phase = GamePhase:Cleared AND mPhase <> GamePhase:Cleared THEN cues = WithCue(cues, INTEGER(InvadersCue:WaveCleared)).
        IF mSaucer AND NOT oGame:SaucerActive AND oGame:Score > mScore THEN cues = WithCue(cues, INTEGER(InvadersCue:SaucerHit)).
        IF oGame:Rack:AliveCount < mAlive THEN cues = WithCue(cues, INTEGER(InvadersCue:InvaderKilled)).
        IF oGame:Lives > mLives THEN cues = WithCue(cues, INTEGER(InvadersCue:ExtraLife)).
        IF oGame:ShotsFired > mShots THEN cues = WithCue(cues, INTEGER(InvadersCue:Shoot)).
        IF oGame:Rack:Passes > mPasses THEN DO:
            cues = WithCue(cues, INTEGER(InvadersCue:March1) + mMarch).
            mMarch = (mMarch + 1) MODULO 4.
        END.
        Remember(oGame).
        RETURN cues.
    END METHOD.

    /* The saucer's hum sounds while the saucer is out, in a game that is being played and is not paused. */
    METHOD PUBLIC CHARACTER Loops(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS SpaceInvadersGame NO-UNDO.
        IF NOT TYPE-OF(poGame, SpaceInvadersGame) THEN UNDO, THROW NEW GridException("The cues of Space Invaders need a Space Invaders game").
        oGame = CAST(poGame, SpaceInvadersGame).
        IF oGame:SaucerActive AND oGame:Phase = GamePhase:Playing AND NOT oGame:Paused THEN RETURN STRING(INTEGER(InvadersCue:SaucerHum)).
        RETURN "".
    END METHOD.

    /* Each of the cannon blowing up, the shot, the kills, the march and the two fanfares is a group; a saucer hit and an invader hit
       share the group of the kills. */
    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        CASE piCue:
            WHEN INTEGER(InvadersCue:Shoot) THEN RETURN 1.
            WHEN INTEGER(InvadersCue:InvaderKilled) OR WHEN INTEGER(InvadersCue:SaucerHit) THEN RETURN 2.
            WHEN INTEGER(InvadersCue:PlayerDies) THEN RETURN 3.
            WHEN INTEGER(InvadersCue:March1) OR WHEN INTEGER(InvadersCue:March2) OR WHEN INTEGER(InvadersCue:March3) OR WHEN INTEGER(InvadersCue:March4) THEN RETURN 4.
            WHEN INTEGER(InvadersCue:ExtraLife) THEN RETURN 5.
            WHEN INTEGER(InvadersCue:WaveCleared) THEN RETURN 6.
            OTHERWISE RETURN 7.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID Remember(INPUT poGame AS SpaceInvadersGame):
        mPhase = poGame:Phase.
        mLives = poGame:Lives.
        mAlive = poGame:Rack:AliveCount.
        mShots = poGame:ShotsFired.
        mPasses = poGame:Rack:Passes.
        mScore = poGame:Score.
        mSaucer = poGame:SaucerActive.
    END METHOD.

    METHOD PRIVATE CHARACTER WithCue(INPUT pcCues AS CHARACTER, INPUT piCue AS INTEGER):
        RETURN pcCues + (IF pcCues = "" THEN "" ELSE ",") + STRING(piCue).
    END METHOD.

END CLASS.
