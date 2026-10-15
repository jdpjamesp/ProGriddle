/* The sound renderer: it asks a cue source what is new on every Render, plays it once per priority group, and always draws. */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SoundRendererTests:

    DEFINE PRIVATE VARIABLE mInner    AS RecordingRenderer    NO-UNDO.
    DEFINE PRIVATE VARIABLE mSource   AS ScriptedCueSource    NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlayer   AS RecordingSoundPlayer NO-UNDO.
    DEFINE PRIVATE VARIABLE mRenderer AS SoundRenderer        NO-UNDO.
    DEFINE PRIVATE VARIABLE mGrid     AS Grid                 NO-UNDO.
    DEFINE PRIVATE VARIABLE mGame     AS CountingGame         NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildRenderer():
        mInner = NEW RecordingRenderer().
        mSource = NEW ScriptedCueSource().
        mPlayer = NEW RecordingSoundPlayer().
        mRenderer = NEW SoundRenderer(mInner, mSource, mPlayer).
        mGrid = NEW Grid(NEW ArrayStore(4, 4, "state")).
        mGame = NEW CountingGame(mGrid, 0).
        mGame:Initialise().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseRenderer():
        IF VALID-OBJECT(mGame) THEN mGame:Dispose().
        mGame = ?.
        mGrid = ?.
        mRenderer = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID EveryRenderIsPassedOnAndTheCueSourceIsGivenTheGame():
        mRenderer:Render(mGrid, mGame).
        mRenderer:Render(mGrid, mGame).
        Assert:Equals(2, mInner:RenderCount).
        Assert:Equals(2, mSource:PollCount).
        Assert:IsTrue(mSource:LastGame = mGame).
        Assert:Equals("", mPlayer:Played).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheCuesOfAPollArePlayedInTheOrderTheSourceGaveThem():
        mSource:NextCues = "21,11,31".
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("21,11,31", mPlayer:Played).
        /* and only once: the next poll finds nothing new */
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("21,11,31", mPlayer:Played).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID OnlyTheFirstCueOfEachPriorityGroupIsPlayed():
        /* 11 and 12 share a group, 21 and 22 another, 31 is alone */
        mSource:NextCues = "12,11,21,22,31".
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("12,21,31", mPlayer:Played).
        /* the groups start afresh on the next poll */
        mSource:NextCues = "11,12".
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("12,21,31,11", mPlayer:Played).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMutedPlayerStillPollsSoNothingOldSoundsOnUnmuting():
        mPlayer:Muted = TRUE.
        mSource:NextCues = "11".
        mRenderer:Render(mGrid, mGame).
        Assert:Equals(1, mSource:PollCount).
        Assert:Equals("", mPlayer:Played).
        mPlayer:Muted = FALSE.
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("", mPlayer:Played).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID LoopsAreStartedWhenWantedAndStoppedWhenTheyAreNot():
        mSource:WantedLoops = "7".
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("7", mPlayer:Looping).
        mSource:WantedLoops = "7,8".
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("7,8", mPlayer:Looping).
        Assert:Equals(2, mPlayer:LoopStarts).
        mSource:WantedLoops = "8".
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("8", mPlayer:Looping).
        mSource:WantedLoops = "".
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("", mPlayer:Looping).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID AMutedLoopComesBackAfterUnmutingOnTheNextRender():
        mSource:WantedLoops = "7".
        mPlayer:Muted = TRUE.
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("", mPlayer:Looping).
        mPlayer:Muted = FALSE.
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("7", mPlayer:Looping).
        /* muting stops it at once */
        mPlayer:Muted = TRUE.
        Assert:Equals("", mPlayer:Looping).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ASourceThatIsNotALoopSourceStartsNoLoops():
        DEFINE VARIABLE oPlain AS ICueSource NO-UNDO.
        oPlain = NEW PlainCueSource().
        mRenderer = NEW SoundRenderer(mInner, oPlain, mPlayer).
        mRenderer:Render(mGrid, mGame).
        Assert:Equals("", mPlayer:Looping).
        Assert:Equals(0, mPlayer:LoopStarts).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ARendererNeedsAnInnerRendererASourceAndAPlayer():
        DEFINE VARIABLE thrown AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW SoundRenderer(?, mSource, mPlayer).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW SoundRenderer(mInner, ?, mPlayer).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        DO ON ERROR UNDO, THROW:
            NEW SoundRenderer(mInner, mSource, ?).
            CATCH e3 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(3, thrown).
    END METHOD.

END CLASS.
