/* When the sounds of Xevious happen: a cue source (ICueSource) and loop source (ILoopSource) that look at the game after each
   change of the picture. They compare the game's own running counts with the ones last seen (shots, bombs, kills, hits, lives lost
   and won, stages cleared, which never go back), so two events in the same millisecond are still two.

   Nothing sounds on the title screen: the state is only taken as it is. The mothership has a hum that loops for as long as it is
   out. A paused game, a title screen, a dying ship and a finished game have no loops.

   The cues come most important first. The ship's death, an extra ship and a cleared stage are groups of their own, the finding of a
   hidden tower or flag is one group, a kill or a hit on the mothership is one group, a bomb landing is one group, and the two
   guns and the enemy fire are each their own, so a shot that fires while something is hit sounds as well. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousCues FINAL IMPLEMENTS ICueSource, ILoopSource:

    DEFINE PRIVATE VARIABLE mPhase   AS XeviousPhase NO-UNDO.
    DEFINE PRIVATE VARIABLE mZaps    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mDrops   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBursts  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mAir     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mGround  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mSols    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mFlags   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mEnemy   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mClangs  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBossHit AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mBossKil AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mDeaths  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mExtras  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mStages  AS INTEGER NO-UNDO.

    /* Throws GridException for a game that is not a XeviousGame. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS XeviousGame NO-UNDO.
        DEFINE VARIABLE cues  AS CHARACTER   NO-UNDO.
        IF NOT TYPE-OF(poGame, XeviousGame) THEN UNDO, THROW NEW GridException("The cues of Xevious need a Xevious game").
        oGame = CAST(poGame, XeviousGame).
        /* the first look and the title screen: take the state as it is, and say nothing */
        IF NOT VALID-OBJECT(mPhase) OR mPhase = XeviousPhase:Title THEN DO:
            Remember(oGame).
            RETURN "".
        END.
        IF oGame:Deaths > mDeaths THEN cues = WithCue(cues, INTEGER(XeviousCue:PlayerDies)).
        IF oGame:ExtraLives > mExtras THEN cues = WithCue(cues, INTEGER(XeviousCue:ExtraLife)).
        IF oGame:StagesCleared > mStages THEN cues = WithCue(cues, INTEGER(XeviousCue:StageClear)).
        IF oGame:BossKills > mBossKil THEN cues = WithCue(cues, INTEGER(XeviousCue:BossKill)).
        ELSE IF oGame:BossHits > mBossHit THEN cues = WithCue(cues, INTEGER(XeviousCue:BossHit)).
        IF oGame:SolsFound > mSols THEN cues = WithCue(cues, INTEGER(XeviousCue:SolFound)).
        ELSE IF oGame:FlagsFound > mFlags THEN cues = WithCue(cues, INTEGER(XeviousCue:FlagFound)).
        IF oGame:GroundKills > mGround THEN cues = WithCue(cues, INTEGER(XeviousCue:GroundKill)).
        ELSE IF oGame:BombBursts > mBursts THEN cues = WithCue(cues, INTEGER(XeviousCue:BombBurst)).
        IF oGame:AirKills > mAir THEN cues = WithCue(cues, INTEGER(XeviousCue:AirKill)).
        ELSE IF oGame:Clangs > mClangs THEN cues = WithCue(cues, INTEGER(XeviousCue:Clang)).
        IF oGame:BombsDropped > mDrops THEN cues = WithCue(cues, INTEGER(XeviousCue:BombDrop)).
        IF oGame:EnemyShots > mEnemy THEN cues = WithCue(cues, INTEGER(XeviousCue:EnemyFire)).
        IF oGame:ZapsFired > mZaps THEN cues = WithCue(cues, INTEGER(XeviousCue:Zap)).
        Remember(oGame).
        RETURN cues.
    END METHOD.

    /* The mothership hums while it is out, in a game that is being played and is not paused. */
    METHOD PUBLIC CHARACTER Loops(INPUT poGame AS IGame):
        DEFINE VARIABLE oGame AS XeviousGame NO-UNDO.
        IF NOT TYPE-OF(poGame, XeviousGame) THEN UNDO, THROW NEW GridException("The cues of Xevious need a Xevious game").
        oGame = CAST(poGame, XeviousGame).
        IF oGame:Phase <> XeviousPhase:Playing OR oGame:Paused THEN RETURN "".
        IF oGame:BossActive THEN RETURN STRING(INTEGER(XeviousCue:BossLoop)).
        RETURN "".
    END METHOD.

    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        CASE piCue:
            WHEN INTEGER(XeviousCue:PlayerDies) THEN RETURN 1.
            WHEN INTEGER(XeviousCue:ExtraLife) THEN RETURN 2.
            WHEN INTEGER(XeviousCue:StageClear) THEN RETURN 3.
            WHEN INTEGER(XeviousCue:BossKill) OR WHEN INTEGER(XeviousCue:BossHit) THEN RETURN 4.
            WHEN INTEGER(XeviousCue:SolFound) OR WHEN INTEGER(XeviousCue:FlagFound) THEN RETURN 5.
            WHEN INTEGER(XeviousCue:GroundKill) OR WHEN INTEGER(XeviousCue:BombBurst) THEN RETURN 6.
            WHEN INTEGER(XeviousCue:AirKill) OR WHEN INTEGER(XeviousCue:Clang) THEN RETURN 7.
            WHEN INTEGER(XeviousCue:BombDrop) THEN RETURN 8.
            WHEN INTEGER(XeviousCue:EnemyFire) THEN RETURN 9.
            OTHERWISE RETURN 10.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID Remember(INPUT poGame AS XeviousGame):
        ASSIGN mPhase = poGame:Phase
               mZaps = poGame:ZapsFired
               mDrops = poGame:BombsDropped
               mBursts = poGame:BombBursts
               mAir = poGame:AirKills
               mGround = poGame:GroundKills
               mSols = poGame:SolsFound
               mFlags = poGame:FlagsFound
               mEnemy = poGame:EnemyShots
               mClangs = poGame:Clangs
               mBossHit = poGame:BossHits
               mBossKil = poGame:BossKills
               mDeaths = poGame:Deaths
               mExtras = poGame:ExtraLives
               mStages = poGame:StagesCleared.
    END METHOD.

    METHOD PRIVATE CHARACTER WithCue(INPUT pcCues AS CHARACTER, INPUT piCue AS INTEGER):
        RETURN pcCues + (IF pcCues = "" THEN "" ELSE ",") + STRING(piCue).
    END METHOD.

END CLASS.
