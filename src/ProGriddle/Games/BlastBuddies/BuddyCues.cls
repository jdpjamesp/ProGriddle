/* When the sounds of Blast Buddies happen: a cue source (ICueSource) and loop source (ILoopSource) that look at the game after each change
   of the picture. They compare the game's own running counts with the ones last seen (hops, flips, pixels walked, steps of aim, landings,
   shots, blasts, buddies hurt, deaths, drownings and splashes, which never go back), so two events in the same moment are still two.

   A walk ticks every third pixel and the aim every fourth step; while the fire key is held a tick sounds each time the power passes a
   multiple of 8 percent, rising in four pitches. A blast sounds in one of three sizes by its radius. A new turn has its two note call,
   and the last ten seconds of a turn tick off. The winner and a draw have their own endings. A new game (its frame count goes back) is
   noticed and its old events are forgotten, so nothing sounds for them. The rocket's whoosh is a loop that lasts as long as a rocket is
   in the air; a paused game and a finished game have none.

   The cues come most important first: the ending, a death, a blast, a squeal, the water, a shot, a new turn, a landing, a hop or a flip,
   the clock, the power building, the aim, the walk. The sizes of blast are one group, and the others are groups of their own, so they
   sound together. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddyCues FINAL IMPLEMENTS ICueSource, ILoopSource:

    DEFINE PRIVATE VARIABLE mSeen     AS LOGICAL    NO-UNDO.
    DEFINE PRIVATE VARIABLE mFrames   AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mSerial   AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mPhase    AS BuddyPhase NO-UNDO.
    DEFINE PRIVATE VARIABLE mTurns    AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mHops     AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mFlips    AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mSteps    AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mAims     AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mLands    AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mShots    AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mBlasts   AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mHurt     AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mDeaths   AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mSplashes AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mBucket   AS INTEGER    NO-UNDO.
    DEFINE PRIVATE VARIABLE mSeconds  AS INTEGER    NO-UNDO.

    /* Throws GridException for a game that is not a Blast Buddies game. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame  AS BlastBuddiesGame NO-UNDO.
        DEFINE VARIABLE cues   AS CHARACTER        NO-UNDO.
        DEFINE VARIABLE bucket AS INTEGER          NO-UNDO.
        DEFINE VARIABLE secs   AS INTEGER          NO-UNDO.
        DEFINE VARIABLE splash AS INTEGER          NO-UNDO.
        IF NOT TYPE-OF(poGame, BlastBuddiesGame) THEN UNDO, THROW NEW GridException("The cues of Blast Buddies need a Blast Buddies game").
        oGame = CAST(poGame, BlastBuddiesGame).
        /* the first look, and a game that has started again: take the state as it is, and say nothing */
        IF NOT mSeen OR oGame:MapSerial <> mSerial OR oGame:FrameCount < mFrames THEN DO:
            Remember(oGame).
            RETURN "".
        END.
        bucket = (IF oGame:Charging THEN INTEGER(TRUNCATE(oGame:PowerPercent / 8, 0)) ELSE 0).
        secs = INTEGER(TRUNCATE((oGame:TimeLeftMs + 999) / 1000, 0)).
        splash = oGame:DrownCount + oGame:WaterHits.
        IF oGame:Phase = BuddyPhase:Winner AND mPhase <> BuddyPhase:Winner THEN cues = WithCue(cues, INTEGER(BuddyCue:Winner)).
        IF oGame:Phase = BuddyPhase:Draw AND mPhase <> BuddyPhase:Draw THEN cues = WithCue(cues, INTEGER(BuddyCue:Draw)).
        IF oGame:DeathCount > mDeaths THEN cues = WithCue(cues, INTEGER(BuddyCue:Death)).
        IF oGame:BlastCount > mBlasts THEN
            cues = WithCue(cues, (IF oGame:LastBlastRadius >= 30 THEN INTEGER(BuddyCue:BlastLarge) ELSE IF oGame:LastBlastRadius >= 20 THEN INTEGER(BuddyCue:BlastMedium)
                                  ELSE INTEGER(BuddyCue:BlastSmall))).
        IF oGame:HurtCount > mHurt THEN cues = WithCue(cues, INTEGER(BuddyCue:Squeal)).
        IF splash > mSplashes THEN cues = WithCue(cues, INTEGER(BuddyCue:Splash)).
        IF oGame:ShotsFired > mShots THEN cues = WithCue(cues, INTEGER(BuddyCue:Fire)).
        IF oGame:Generation > mTurns THEN cues = WithCue(cues, INTEGER(BuddyCue:TurnStart)).
        IF oGame:LandCount > mLands THEN cues = WithCue(cues, INTEGER(BuddyCue:Land)).
        IF oGame:FlipCount > mFlips THEN cues = WithCue(cues, INTEGER(BuddyCue:Flip)).
        ELSE IF oGame:HopCount > mHops THEN cues = WithCue(cues, INTEGER(BuddyCue:Hop)).
        IF oGame:Phase = BuddyPhase:Turn AND secs <= 10 AND secs < mSeconds AND secs > 0 THEN cues = WithCue(cues, INTEGER(BuddyCue:Countdown)).
        IF bucket > mBucket THEN cues = WithCue(cues, INTEGER(BuddyCue:ChargeA) + MINIMUM(3, INTEGER(TRUNCATE((bucket - 1) / 3, 0)))).
        IF INTEGER(TRUNCATE(oGame:AimTicks / 4, 0)) > INTEGER(TRUNCATE(mAims / 4, 0)) THEN cues = WithCue(cues, INTEGER(BuddyCue:AimTick)).
        IF INTEGER(TRUNCATE(oGame:StepCount / 3, 0)) > INTEGER(TRUNCATE(mSteps / 3, 0)) THEN cues = WithCue(cues, INTEGER(BuddyCue:WalkTick)).
        Remember(oGame).
        RETURN cues.
    END METHOD.

    /* The rocket's hiss sounds while a rocket is in the air, in a game that is being played and is not paused. */
    METHOD PUBLIC CHARACTER Loops(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS BlastBuddiesGame NO-UNDO.
        IF NOT TYPE-OF(poGame, BlastBuddiesGame) THEN UNDO, THROW NEW GridException("The cues of Blast Buddies need a Blast Buddies game").
        oGame = CAST(poGame, BlastBuddiesGame).
        IF oGame:Paused OR oGame:IsOver THEN RETURN "".
        IF oGame:Shells:Count() > 0 THEN RETURN STRING(INTEGER(BuddyCue:FlightLoop)).
        RETURN "".
    END METHOD.

    /* The three sizes of blast are one group (so the biggest comes first and the others are left out); every other cue has a group of its own. */
    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        CASE piCue:
            WHEN INTEGER(BuddyCue:BlastSmall) OR WHEN INTEGER(BuddyCue:BlastMedium) OR WHEN INTEGER(BuddyCue:BlastLarge) THEN RETURN 1.
            WHEN INTEGER(BuddyCue:Fire) THEN RETURN 2.
            WHEN INTEGER(BuddyCue:Squeal) THEN RETURN 3.
            WHEN INTEGER(BuddyCue:Death) THEN RETURN 4.
            WHEN INTEGER(BuddyCue:Splash) THEN RETURN 5.
            WHEN INTEGER(BuddyCue:Hop) OR WHEN INTEGER(BuddyCue:Flip) THEN RETURN 6.
            WHEN INTEGER(BuddyCue:Land) THEN RETURN 7.
            WHEN INTEGER(BuddyCue:WalkTick) THEN RETURN 8.
            WHEN INTEGER(BuddyCue:AimTick) THEN RETURN 9.
            WHEN INTEGER(BuddyCue:ChargeA) OR WHEN INTEGER(BuddyCue:ChargeB) OR WHEN INTEGER(BuddyCue:ChargeC) OR WHEN INTEGER(BuddyCue:ChargeD) THEN RETURN 10.
            WHEN INTEGER(BuddyCue:TurnStart) THEN RETURN 11.
            WHEN INTEGER(BuddyCue:Countdown) THEN RETURN 12.
            WHEN INTEGER(BuddyCue:Winner) OR WHEN INTEGER(BuddyCue:Draw) THEN RETURN 13.
            OTHERWISE RETURN 14.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID Remember(INPUT poGame AS BlastBuddiesGame):
        mSeen = TRUE.
        mSerial = poGame:MapSerial.
        mFrames = poGame:FrameCount.
        mPhase = poGame:Phase.
        mTurns = poGame:Generation.
        mHops = poGame:HopCount.
        mFlips = poGame:FlipCount.
        mSteps = poGame:StepCount.
        mAims = poGame:AimTicks.
        mLands = poGame:LandCount.
        mShots = poGame:ShotsFired.
        mBlasts = poGame:BlastCount.
        mHurt = poGame:HurtCount.
        mDeaths = poGame:DeathCount.
        mSplashes = poGame:DrownCount + poGame:WaterHits.
        mBucket = (IF poGame:Charging THEN INTEGER(TRUNCATE(poGame:PowerPercent / 8, 0)) ELSE 0).
        mSeconds = INTEGER(TRUNCATE((poGame:TimeLeftMs + 999) / 1000, 0)).
    END METHOD.

    METHOD PRIVATE CHARACTER WithCue(INPUT pcCues AS CHARACTER, INPUT piCue AS INTEGER):
        RETURN pcCues + (IF pcCues = "" THEN "" ELSE ",") + STRING(piCue).
    END METHOD.

END CLASS.
