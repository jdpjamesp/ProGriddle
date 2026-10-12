/* The arcade: a window with one button for each game in an IGameCatalog. A button starts the game
   through an IGameLauncher and, while that game is running, shows it as playing in green. A click on
   a game that is already running only says so. The games come from the catalog, so adding a game adds a button without changing this class.

   It knows nothing about any game. Call ReleaseResources (the window does when it closes) to stop the
   timers that watch for games that have finished and that close the window for scripted runs. */
USING Progress.Lang.*.
USING System.Drawing.* FROM ASSEMBLY.
USING System.Windows.Forms.* FROM ASSEMBLY.
USING System.Windows.Forms.Timer FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.ArcadeWindow INHERITS Form:

    DEFINE PRIVATE VARIABLE mCatalog   AS IGameCatalog  NO-UNDO.
    DEFINE PRIVATE VARIABLE mLauncher  AS IGameLauncher NO-UNDO.
    DEFINE PRIVATE VARIABLE mButtons   AS Button        NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mTitles    AS CHARACTER     NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mStatus    AS Label         NO-UNDO.
    DEFINE PRIVATE VARIABLE mTagline   AS Label         NO-UNDO.
    DEFINE PRIVATE VARIABLE mWatcher   AS Timer         NO-UNDO.
    DEFINE PRIVATE VARIABLE mCloser    AS Timer         NO-UNDO.
    DEFINE PRIVATE VARIABLE mReleased  AS LOGICAL       NO-UNDO.

    /* How many game buttons the window has. */
    DEFINE PUBLIC PROPERTY GameCount AS INTEGER NO-UNDO
        GET():
            RETURN mCatalog:Count.
        END GET.

    /* The text of the line at the bottom: what was last started, or why it could not be. */
    DEFINE PUBLIC PROPERTY StatusLine AS CHARACTER NO-UNDO
        GET():
            RETURN mStatus:Text.
        END GET.

    CONSTRUCTOR PUBLIC ArcadeWindow(INPUT pcTitle AS CHARACTER, INPUT poCatalog AS IGameCatalog, INPUT poLauncher AS IGameLauncher):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE heading AS Label   NO-UNDO.
        DEFINE VARIABLE area   AS Panel   NO-UNDO.
        SUPER().
        IF pcTitle = ? OR pcTitle = "" THEN UNDO, THROW NEW GridException("An arcade needs a title").
        IF NOT VALID-OBJECT(poCatalog) THEN UNDO, THROW NEW GridException("An arcade needs a game catalog").
        IF NOT VALID-OBJECT(poLauncher) THEN UNDO, THROW NEW GridException("An arcade needs a launcher").
        mCatalog = poCatalog.
        mLauncher = poLauncher.

        THIS-OBJECT:Text = pcTitle.
        THIS-OBJECT:StartPosition = FormStartPosition:CenterScreen.
        THIS-OBJECT:ClientSize = NEW Size(620, 130 + MINIMUM(MAXIMUM(mCatalog:Count, 1), 8) * 64).
        THIS-OBJECT:MinimumSize = NEW Size(460, 260).
        THIS-OBJECT:BackColor = Color:FromArgb(18, 22, 27).
        THIS-OBJECT:ForeColor = Color:FromArgb(230, 233, 237).
        THIS-OBJECT:Font = NEW Font("Segoe UI", System.Convert:ToSingle(10), FontStyle:Regular, GraphicsUnit:Point).

        mStatus = NEW Label().
        mStatus:Dock = DockStyle:Bottom.
        mStatus:Height = 28.
        mStatus:TextAlign = ContentAlignment:MiddleLeft.
        mStatus:Padding = NEW Padding(14, 0, 0, 0).
        mStatus:ForeColor = Color:FromArgb(150, 160, 172).
        mStatus:Text = (IF mCatalog:Count = 0 THEN "No games found" ELSE SUBSTITUTE("&1 games. Pick one to play", mCatalog:Count)).

        heading = NEW Label().
        heading:Dock = DockStyle:Top.
        heading:Height = 40.
        heading:Padding = NEW Padding(14, 8, 0, 0).
        heading:Text = pcTitle.
        heading:Font = NEW Font("Segoe UI", System.Convert:ToSingle(16), FontStyle:Bold, GraphicsUnit:Point).

        mTagline = NEW Label().
        mTagline:Dock = DockStyle:Top.
        mTagline:Height = 30.
        mTagline:Padding = NEW Padding(16, 0, 0, 0).
        mTagline:ForeColor = Color:FromArgb(150, 160, 172).
        mTagline:Text = "Pick a game and get cooking".

        area = NEW Panel().
        area:Dock = DockStyle:Fill.
        area:AutoScroll = TRUE.

        IF mCatalog:Count > 0 THEN DO:
            EXTENT(mButtons) = mCatalog:Count.
            EXTENT(mTitles) = mCatalog:Count.
            /* a row docked to the top stacks above the ones added before it, so add them backwards */
            DO i = mCatalog:Count TO 1 BY -1:
                mTitles[i] = mCatalog:TitleAt(i).
                area:Controls:Add(NewRow(i)).
            END.
        END.

        /* fill first, then the edges, so the games get what is left over */
        THIS-OBJECT:Controls:Add(area).
        THIS-OBJECT:Controls:Add(mTagline).
        THIS-OBJECT:Controls:Add(heading).
        THIS-OBJECT:Controls:Add(mStatus).

        mWatcher = NEW Timer().
        mWatcher:Interval = 1000.
        mWatcher:Tick:Subscribe(OnWatch).
        mWatcher:Start().
        THIS-OBJECT:FormClosed:Subscribe(OnFormClosed).
        UpdateButtons().
    END CONSTRUCTOR.

    /* The button of the game that is started by this program, for tests and scripts. */
    METHOD PUBLIC Button ButtonFor(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mCatalog:Count:
            IF mCatalog:ProgramAt(i) = pcProgram THEN RETURN mButtons[i].
        END.
        UNDO, THROW NEW GridException("The arcade has no game " + STRING(pcProgram)).
    END METHOD.

    /* Closes the window by itself after this many seconds. For scripted runs. */
    METHOD PUBLIC VOID AutoClose(INPUT piSeconds AS INTEGER):
        IF piSeconds = ? OR piSeconds < 1 THEN UNDO, THROW NEW GridException("Auto close needs a number of seconds").
        IF NOT VALID-OBJECT(mCloser) THEN DO:
            mCloser = NEW Timer().
            mCloser:Tick:Subscribe(OnCloseTimer).
        END.
        mCloser:Interval = piSeconds * 1000.
        mCloser:Start().
    END METHOD.

    /* Stops the timers and lets go of the buttons' events. Safe to call more than once. */
    METHOD PUBLIC VOID ReleaseResources():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF mReleased THEN RETURN.
        mReleased = TRUE.
        mWatcher:Stop().
        mWatcher:Tick:Unsubscribe(OnWatch).
        mWatcher:Dispose().
        IF VALID-OBJECT(mCloser) THEN DO:
            mCloser:Stop().
            mCloser:Tick:Unsubscribe(OnCloseTimer).
            mCloser:Dispose().
        END.
        DO i = 1 TO mCatalog:Count:
            mButtons[i]:Click:Unsubscribe(OnPlay).
        END.
    END METHOD.

    /* One row: the game's button on the left and its blurb filling the rest. */
    METHOD PRIVATE Panel NewRow(INPUT piPlace AS INTEGER):
        DEFINE VARIABLE rowPanel   AS Panel  NO-UNDO.
        DEFINE VARIABLE blurb AS Label  NO-UNDO.
        DEFINE VARIABLE btn   AS Button NO-UNDO.
        rowPanel = NEW Panel().
        rowPanel:Dock = DockStyle:Top.
        rowPanel:Height = 64.
        rowPanel:Padding = NEW Padding(14, 6, 14, 6).

        blurb = NEW Label().
        blurb:Dock = DockStyle:Fill.
        blurb:TextAlign = ContentAlignment:MiddleLeft.
        blurb:Padding = NEW Padding(12, 0, 0, 0).
        blurb:ForeColor = Color:FromArgb(150, 160, 172).
        blurb:Text = mCatalog:BlurbAt(piPlace).

        btn = NEW Button().
        btn:Dock = DockStyle:Left.
        btn:Width = 190.
        btn:Name = mCatalog:ProgramAt(piPlace).
        btn:FlatStyle = FlatStyle:Flat.
        btn:BackColor = Color:FromArgb(42, 52, 65).
        btn:Font = NEW Font("Segoe UI", System.Convert:ToSingle(12), FontStyle:Bold, GraphicsUnit:Point).
        btn:Click:Subscribe(OnPlay).
        mButtons[piPlace] = btn.

        rowPanel:Controls:Add(blurb).
        rowPanel:Controls:Add(btn).
        RETURN rowPanel.
    END METHOD.

    /* A game that is running shows as playing, in green. */
    METHOD PRIVATE VOID UpdateButtons():
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE playing AS LOGICAL NO-UNDO.
        DO i = 1 TO mCatalog:Count:
            playing = mLauncher:IsRunning(mCatalog:ProgramAt(i)).
            mButtons[i]:Text = (IF playing THEN mTitles[i] + " (playing)" ELSE mTitles[i]).
            mButtons[i]:ForeColor = (IF playing THEN Color:FromArgb(76, 195, 138) ELSE Color:FromArgb(230, 233, 237)).
            mButtons[i]:BackColor = (IF playing THEN Color:FromArgb(30, 38, 48) ELSE Color:FromArgb(42, 52, 65)).
        END.
    END METHOD.

    /* Starts the game whose program is given, as a click on its button does. A game that is already
       running is not started again, and one that cannot be started is reported on the status line,
       not thrown. */
    METHOD PUBLIC VOID Play(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE wasOn  AS LOGICAL   NO-UNDO.
        DO ON ERROR UNDO, THROW:
            wasOn = mLauncher:IsRunning(pcProgram).
            mLauncher:Launch(pcProgram).
            DO i = 1 TO mCatalog:Count:
                IF mCatalog:ProgramAt(i) = pcProgram THEN
                    mStatus:Text = (IF wasOn THEN mTitles[i] + " is already running" ELSE "Started " + mTitles[i]).
            END.
            CATCH err AS Progress.Lang.Error:
                mStatus:Text = err:GetMessage(1).
            END CATCH.
        END.
        UpdateButtons().
    END METHOD.

    METHOD PRIVATE VOID OnPlay(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        Play(CAST(poSender, Button):Name).
    END METHOD.

    METHOD PRIVATE VOID OnWatch(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        UpdateButtons().
    END METHOD.

    METHOD PRIVATE VOID OnCloseTimer(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        mCloser:Stop().
        THIS-OBJECT:Close().
    END METHOD.

    METHOD PRIVATE VOID OnFormClosed(INPUT poSender AS System.Object, INPUT e AS FormClosedEventArgs):
        THIS-OBJECT:FormClosed:Unsubscribe(OnFormClosed).
        ReleaseResources().
    END METHOD.

END CLASS.
