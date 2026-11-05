/* When the sounds of Centipede happen: a cue source (ICueSource) and loop source (ILoopSource) that look at the game after each
   change of the picture. They compare the game's own running counts with the ones last seen (shots, segments, mushrooms, the
   creatures hit and killed, lives lost and won, waves cleared, which never go back), so two events in the same millisecond are
   still two. A head shot sounds different from a body segment.

   Nothing sounds on the title screen: the state is only taken as it is. The spider and the scorpion each have a hum that loops for
   as long as they are out. A paused game, a title screen, a dying shooter and a finished game have no loops.

   The cues come most important first. The shooter's death, an extra shooter and a cleared wave are groups of their own, a creature
   hit or killed is one group (only the first is played), a segment or mushroom hit is one group, and the shot is its own, so a shot
   that fires while something is hit sounds as well. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Centipede.CentipedeCues FINAL IMPLEMENTS ICueSource, ILoopSource:

    DEFINE PRIVATE VARIABLE mPhase     AS GamePhase NO-UNDO.
    DEFINE PRIVATE VARIABLE mShots     AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSegments  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeads     AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mMushrooms AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mFleaHits  AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mFleas     AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpiders   AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mScorpions AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mDeaths    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mExtras    AS INTEGER   NO-UNDO.
    DEFINE PRIVATE VARIABLE mWaves     AS INTEGER   NO-UNDO.

    /* Throws GridException for a game that is not a CentipedeGame. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS CentipedeGame NO-UNDO.
        DEFINE VARIABLE cues  AS CHARACTER     NO-UNDO.
        IF NOT TYPE-OF(poGame, CentipedeGame) THEN UNDO, THROW NEW GridException("The cues of Centipede need a Centipede game").
        oGame = CAST(poGame, CentipedeGame).
        /* the first look and the title screen: take the state as it is, and say nothing */
        IF NOT VALID-OBJECT(mPhase) OR mPhase = GamePhase:Title THEN DO:
            Remember(oGame).
            RETURN "".
        END.
        IF oGame:Deaths > mDeaths THEN cues = WithCue(cues, INTEGER(CentipedeCue:PlayerDies)).
        IF oGame:ExtraLives > mExtras THEN cues = WithCue(cues, INTEGER(CentipedeCue:ExtraLife)).
        IF oGame:WavesCleared > mWaves THEN cues = WithCue(cues, INTEGER(CentipedeCue:WaveClear)).
        IF oGame:ScorpionKills > mScorpions THEN cues = WithCue(cues, INTEGER(CentipedeCue:ScorpionKill)).
        IF oGame:SpiderKills > mSpiders THEN cues = WithCue(cues, INTEGER(CentipedeCue:SpiderKill)).
        IF oGame:FleaKills > mFleas THEN cues = WithCue(cues, INTEGER(CentipedeCue:FleaKill)).
        ELSE IF oGame:FleaHits > mFleaHits THEN cues = WithCue(cues, INTEGER(CentipedeCue:FleaHit)).
        IF oGame:HeadsKilled > mHeads THEN cues = WithCue(cues, INTEGER(CentipedeCue:HeadKill)).
        ELSE IF oGame:SegmentsKilled > mSegments THEN cues = WithCue(cues, INTEGER(CentipedeCue:SegmentKill)).
        IF oGame:MushroomsDestroyed > mMushrooms THEN cues = WithCue(cues, INTEGER(CentipedeCue:MushroomBreak)).
        IF oGame:ShotsFired > mShots THEN cues = WithCue(cues, INTEGER(CentipedeCue:Fire)).
        Remember(oGame).
        RETURN cues.
    END METHOD.

    /* The spider and the scorpion hum while they are out, in a game that is being played and is not paused. */
    METHOD PUBLIC CHARACTER Loops(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS CentipedeGame NO-UNDO.
        DEFINE VARIABLE loops AS CHARACTER     NO-UNDO.
        IF NOT TYPE-OF(poGame, CentipedeGame) THEN UNDO, THROW NEW GridException("The cues of Centipede need a Centipede game").
        oGame = CAST(poGame, CentipedeGame).
        IF oGame:Phase <> GamePhase:Playing OR oGame:Paused THEN RETURN "".
        IF oGame:SpiderActive THEN loops = STRING(INTEGER(CentipedeCue:SpiderLoop)).
        IF oGame:ScorpionActive THEN loops = loops + (IF loops = "" THEN "" ELSE ",") + STRING(INTEGER(CentipedeCue:ScorpionLoop)).
        RETURN loops.
    END METHOD.

    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        CASE piCue:
            WHEN INTEGER(CentipedeCue:PlayerDies) THEN RETURN 1.
            WHEN INTEGER(CentipedeCue:ExtraLife) THEN RETURN 2.
            WHEN INTEGER(CentipedeCue:WaveClear) THEN RETURN 3.
            WHEN INTEGER(CentipedeCue:ScorpionKill) OR WHEN INTEGER(CentipedeCue:SpiderKill) OR WHEN INTEGER(CentipedeCue:FleaKill)
                OR WHEN INTEGER(CentipedeCue:FleaHit) THEN RETURN 4.
            WHEN INTEGER(CentipedeCue:HeadKill) OR WHEN INTEGER(CentipedeCue:SegmentKill) OR WHEN INTEGER(CentipedeCue:MushroomBreak) THEN RETURN 5.
            OTHERWISE RETURN 6.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID Remember(INPUT poGame AS CentipedeGame):
        ASSIGN mPhase = poGame:Phase
               mShots = poGame:ShotsFired
               mSegments = poGame:SegmentsKilled
               mHeads = poGame:HeadsKilled
               mMushrooms = poGame:MushroomsDestroyed
               mFleaHits = poGame:FleaHits
               mFleas = poGame:FleaKills
               mSpiders = poGame:SpiderKills
               mScorpions = poGame:ScorpionKills
               mDeaths = poGame:Deaths
               mExtras = poGame:ExtraLives
               mWaves = poGame:WavesCleared.
    END METHOD.

    METHOD PRIVATE CHARACTER WithCue(INPUT pcCues AS CHARACTER, INPUT piCue AS INTEGER):
        RETURN pcCues + (IF pcCues = "" THEN "" ELSE ",") + STRING(piCue).
    END METHOD.

END CLASS.
