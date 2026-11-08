/* When the sounds of Cuber happen: a cue source (ICueSource) that looks at the game after each change of the picture. It compares
   the game's own running counts (hops, lamps lit, lamps rung, lamps put out, falls, hits, rides, the Coil's falls, Frosts, moths,
   hatchings, rounds and levels cleared, extra Pips, games started), which never go back, with the ones last seen, so two events
   in the same millisecond are still two.

   Nothing sounds on the title screen: the state is only taken as it is. Starting a game plays its own little fanfare. The cues come
   most important first. A hit or a fall is a group of its own, an extra Pip and a cleared round or level are groups, what Pip
   catches or rides is one group (only the first is played), a lamp changing is one group, and the hop is its own, so a hop that
   lights a lamp sounds as well. Nothing in Cuber loops, so there is no loop source. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Cuber.CuberCues FINAL IMPLEMENTS ICueSource:

    VAR PRIVATE CuberPhase mPhase.
    VAR PRIVATE INTEGER mHops.
    VAR PRIVATE INTEGER mLit.
    VAR PRIVATE INTEGER mRinged.
    VAR PRIVATE INTEGER mPutOut.
    VAR PRIVATE INTEGER mFalls.
    VAR PRIVATE INTEGER mHits.
    VAR PRIVATE INTEGER mRides.
    VAR PRIVATE INTEGER mCoilFalls.
    VAR PRIVATE INTEGER mFrosts.
    VAR PRIVATE INTEGER mMoths.
    VAR PRIVATE INTEGER mHatchings.
    VAR PRIVATE INTEGER mRounds.
    VAR PRIVATE INTEGER mLevels.
    VAR PRIVATE INTEGER mExtras.
    VAR PRIVATE INTEGER mGames.

    /* Throws GridException for a game that is not a CuberGame. */
    METHOD PUBLIC CHARACTER Poll(INPUT poGame AS IGame):
        VAR CuberGame oGame.
        VAR CHARACTER cues.
        IF NOT TYPE-OF(poGame, CuberGame) THEN UNDO, THROW NEW GridException("The cues of Cuber need a Cuber game").
        oGame = CAST(poGame, CuberGame).
        /* the first look and the title screen: take the state as it is, and say nothing. A game that has just been started is
           the one thing worth a sound. */
        IF NOT VALID-OBJECT(mPhase) THEN DO:
            Remember(oGame).
            RETURN "".
        END.
        IF mPhase = CuberPhase:Title AND oGame:GamesStarted = mGames THEN DO:
            Remember(oGame).
            RETURN "".
        END.
        IF oGame:GamesStarted > mGames THEN cues = WithCue(cues, INTEGER(CuberCue:GameStart)).
        ELSE DO:
            IF oGame:Hits > mHits THEN cues = WithCue(cues, INTEGER(CuberCue:Hit)).
            IF oGame:Falls > mFalls THEN cues = WithCue(cues, INTEGER(CuberCue:Fall)).
            IF oGame:ExtraLives > mExtras THEN cues = WithCue(cues, INTEGER(CuberCue:ExtraLife)).
            IF oGame:LevelsCleared > mLevels THEN cues = WithCue(cues, INTEGER(CuberCue:LevelClear)).
            ELSE IF oGame:RoundsCleared > mRounds THEN cues = WithCue(cues, INTEGER(CuberCue:RoundClear)).
            IF oGame:Rides > mRides THEN cues = WithCue(cues, INTEGER(CuberCue:HaloRide)).
            IF oGame:CoilFalls > mCoilFalls THEN cues = WithCue(cues, INTEGER(CuberCue:CoilFalls)).
            IF oGame:FrostsTouched > mFrosts THEN cues = WithCue(cues, INTEGER(CuberCue:FrostPop)).
            IF oGame:MothsCaught > mMoths THEN cues = WithCue(cues, INTEGER(CuberCue:MothCaught)).
            IF oGame:Hatchings > mHatchings THEN cues = WithCue(cues, INTEGER(CuberCue:Hatch)).
            IF oGame:LampsLit > mLit THEN cues = WithCue(cues, INTEGER(CuberCue:LampDone)).
            ELSE IF oGame:LampsRinged > mRinged THEN cues = WithCue(cues, INTEGER(CuberCue:LampHalf)).
            ELSE IF oGame:LampsPutOut > mPutOut THEN cues = WithCue(cues, INTEGER(CuberCue:LampOut)).
            IF oGame:Hops > mHops THEN cues = WithCue(cues, INTEGER(CuberCue:Hop)).
        END.
        Remember(oGame).
        RETURN cues.
    END METHOD.

    METHOD PUBLIC INTEGER GroupOf(INPUT piCue AS INTEGER):
        CASE piCue:
            WHEN INTEGER(CuberCue:GameStart) THEN RETURN 1.
            WHEN INTEGER(CuberCue:Hit) OR WHEN INTEGER(CuberCue:Fall) THEN RETURN 2.
            WHEN INTEGER(CuberCue:ExtraLife) THEN RETURN 3.
            WHEN INTEGER(CuberCue:LevelClear) OR WHEN INTEGER(CuberCue:RoundClear) THEN RETURN 4.
            WHEN INTEGER(CuberCue:HaloRide) OR WHEN INTEGER(CuberCue:CoilFalls) OR WHEN INTEGER(CuberCue:FrostPop)
                OR WHEN INTEGER(CuberCue:MothCaught) OR WHEN INTEGER(CuberCue:Hatch) THEN RETURN 5.
            WHEN INTEGER(CuberCue:LampDone) OR WHEN INTEGER(CuberCue:LampHalf) OR WHEN INTEGER(CuberCue:LampOut) THEN RETURN 6.
            OTHERWISE RETURN 7.
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID Remember(INPUT poGame AS CuberGame):
        ASSIGN mPhase = poGame:Phase
               mHops = poGame:Hops
               mLit = poGame:LampsLit
               mRinged = poGame:LampsRinged
               mPutOut = poGame:LampsPutOut
               mFalls = poGame:Falls
               mHits = poGame:Hits
               mRides = poGame:Rides
               mCoilFalls = poGame:CoilFalls
               mFrosts = poGame:FrostsTouched
               mMoths = poGame:MothsCaught
               mHatchings = poGame:Hatchings
               mRounds = poGame:RoundsCleared
               mLevels = poGame:LevelsCleared
               mExtras = poGame:ExtraLives
               mGames = poGame:GamesStarted.
    END METHOD.

    METHOD PRIVATE CHARACTER WithCue(INPUT pcCues AS CHARACTER, INPUT piCue AS INTEGER):
        RETURN pcCues + (IF pcCues = "" THEN "" ELSE ",") + STRING(piCue).
    END METHOD.

END CLASS.
