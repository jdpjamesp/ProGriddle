/* Gives a game sound without the game, the painter or the controller knowing: a renderer that wraps the real one. The controller
   already redraws whenever a game says something changed, so on each Render this one asks the game's cue source what is new,
   plays it (at most one cue of each priority group, the first the source names), and passes the drawing on. It owns neither the
   player nor the source nor the inner renderer. It polls even while the player is muted, so unmuting does not replay old events.

   A cue source that is also an ILoopSource has loops as well: on each Render the renderer asks which should be sounding, starts
   them (the player ignores a start for a loop it already has, and while muted, so a loop comes back after unmuting) and stops the
   ones that were wanted before and are not now. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.SoundRenderer FINAL IMPLEMENTS IGridRenderer:

    DEFINE PRIVATE VARIABLE mInner  AS IGridRenderer NO-UNDO.
    DEFINE PRIVATE VARIABLE mSource AS ICueSource    NO-UNDO.
    DEFINE PRIVATE VARIABLE mPlayer AS ISoundPlayer  NO-UNDO.
    /* the loops that were wanted at the last Render, as a comma list */
    DEFINE PRIVATE VARIABLE mLoops  AS CHARACTER     NO-UNDO.

    CONSTRUCTOR PUBLIC SoundRenderer(INPUT poInner AS IGridRenderer, INPUT poSource AS ICueSource, INPUT poPlayer AS ISoundPlayer):
        IF NOT VALID-OBJECT(poInner) OR NOT VALID-OBJECT(poSource) OR NOT VALID-OBJECT(poPlayer) THEN
            UNDO, THROW NEW GridException("A sound renderer needs a renderer, a cue source and a player").
        mInner = poInner.
        mSource = poSource.
        mPlayer = poPlayer.
    END CONSTRUCTOR.

    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        DEFINE VARIABLE cues   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE usedBy AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE cue    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE grp    AS CHARACTER NO-UNDO.
        cues = mSource:Poll(poGame).
        IF cues <> ? AND cues <> "" THEN
            DO i = 1 TO NUM-ENTRIES(cues):
                cue = INTEGER(ENTRY(i, cues)).
                grp = STRING(mSource:GroupOf(cue)).
                IF LOOKUP(grp, usedBy) > 0 THEN NEXT.
                usedBy = usedBy + (IF usedBy = "" THEN "" ELSE ",") + grp.
                mPlayer:Play(cue).
            END.
        IF TYPE-OF(mSource, ILoopSource) THEN KeepLoops(CAST(mSource, ILoopSource):Loops(poGame)).
        mInner:Render(poGrid, poGame).
    END METHOD.

    /* Starts the loops that are wanted and stops the ones that were wanted at the last Render and no longer are. */
    METHOD PRIVATE VOID KeepLoops(INPUT pcWanted AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF pcWanted = ? THEN pcWanted = "".
        DO i = 1 TO NUM-ENTRIES(mLoops):
            IF ENTRY(i, mLoops) <> "" AND LOOKUP(ENTRY(i, mLoops), pcWanted) = 0 THEN mPlayer:StopLoop(INTEGER(ENTRY(i, mLoops))).
        END.
        DO i = 1 TO NUM-ENTRIES(pcWanted):
            IF ENTRY(i, pcWanted) <> "" THEN mPlayer:StartLoop(INTEGER(ENTRY(i, pcWanted))).
        END.
        mLoops = pcWanted.
    END METHOD.

END CLASS.
