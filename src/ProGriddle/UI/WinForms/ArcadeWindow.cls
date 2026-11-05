/* The Cookoff: a window with one chip for each game in an IGameCatalog, over a backdrop drawn from the
   Cookoff artwork (CookoffBackdrop). A chip starts the game through an IGameLauncher and, while that
   game is running, shows PLAYING in green. A click on a game that is already running only says so.
   Pointing at a chip shows that game's blurb under the badge, and leaving it brings back the line that
   names all the games. The games come from the catalog, so adding a game adds a chip without changing
   this class. A chip's colour is the one its run file asks for, or one worked out from its title.

   When any game names a category (a Category line in its run file) a row of tabs sits above the chips:
   one tab for each category in order, then Other for games with none, and All at the end, so a list
   that scrolls starts with groups, not with the catch-all. A tab hides the
   chips of the other categories, so the window stays the same size however many games there are. With
   no categories there are no tabs.

   It knows nothing about any game. Call ReleaseResources (the window does when it closes) to stop the
   timers that watch for games that have finished and that close the window for scripted runs. */
USING Progress.Lang.*.
USING System.Drawing.Drawing2D.* FROM ASSEMBLY.
USING System.Drawing.Text.* FROM ASSEMBLY.
USING System.Drawing.* FROM ASSEMBLY.
USING System.Windows.Forms.* FROM ASSEMBLY.
USING System.Windows.Forms.Timer FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.ArcadeWindow INHERITS Form:

    DEFINE PRIVATE VARIABLE mCatalog   AS IGameCatalog   NO-UNDO.
    DEFINE PRIVATE VARIABLE mLauncher  AS IGameLauncher  NO-UNDO.
    DEFINE PRIVATE VARIABLE mButtons   AS Button         NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mTitles    AS CHARACTER      NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mBlurbs    AS CHARACTER      NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mCategoryOf AS CHARACTER     NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mTabs      AS Button         NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mTabList   AS CHARACTER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mShown     AS CHARACTER      NO-UNDO INITIAL "All".
    DEFINE PRIVATE VARIABLE mFlow      AS FlowLayoutPanel NO-UNDO.
    DEFINE PRIVATE VARIABLE mTabFlow   AS FlowLayoutPanel NO-UNDO.
    DEFINE PRIVATE VARIABLE mTabFont   AS Font           NO-UNDO.
    DEFINE PRIVATE VARIABLE mBackdrop  AS CookoffBackdrop NO-UNDO.
    DEFINE PRIVATE VARIABLE mStatus    AS Label          NO-UNDO.
    DEFINE PRIVATE VARIABLE mWatcher   AS Timer          NO-UNDO.
    DEFINE PRIVATE VARIABLE mCloser    AS Timer          NO-UNDO.
    DEFINE PRIVATE VARIABLE mChipFont  AS Font           NO-UNDO.
    DEFINE PRIVATE VARIABLE mTagFont   AS Font           NO-UNDO.
    DEFINE PRIVATE VARIABLE mDefaultCaption AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE mReleased  AS LOGICAL        NO-UNDO.

    /* How many game chips the window has. */
    DEFINE PUBLIC PROPERTY GameCount AS INTEGER NO-UNDO
        GET():
            RETURN mCatalog:Count.
        END GET.

    /* The names of the tabs, comma separated, All last, or an empty string when the window has no tabs. */
    DEFINE PUBLIC PROPERTY TabNames AS CHARACTER NO-UNDO
        GET():
            RETURN mTabList.
        END GET.

    /* The tab that is showing: the first one when the window opens, All when there are no tabs. */
    DEFINE PUBLIC PROPERTY ShownTab AS CHARACTER NO-UNDO
        GET():
            RETURN mShown.
        END GET.

    /* How many game chips are showing under the tab that is selected. */
    DEFINE PUBLIC PROPERTY ShownCount AS INTEGER NO-UNDO
        GET():
            DEFINE VARIABLE i AS INTEGER NO-UNDO.
            DEFINE VARIABLE n AS INTEGER NO-UNDO.
            DO i = 1 TO mCatalog:Count:
                IF InShownTab(i) THEN n = n + 1.
            END.
            RETURN n.
        END GET.

    /* The text of the line at the bottom: what was last started, or why it could not be. */
    DEFINE PUBLIC PROPERTY StatusLine AS CHARACTER NO-UNDO
        GET():
            RETURN mStatus:Text.
        END GET.

    /* The line under the badge: the blurb of the game under the pointer, or the line naming every game. */
    DEFINE PUBLIC PROPERTY Caption AS CHARACTER NO-UNDO
        GET():
            RETURN mBackdrop:Caption.
        END GET.

    /* An .ico file to use as the window's icon. A file that does not exist is ignored, so the window
       never fails over its looks. */
    DEFINE PUBLIC PROPERTY IconFile AS CHARACTER NO-UNDO
        GET.
        SET(INPUT pcValue AS CHARACTER):
            IconFile = pcValue.
            IF pcValue = ? OR pcValue = "" THEN RETURN.
            FILE-INFORMATION:FILE-NAME = pcValue.
            IF FILE-INFORMATION:FULL-PATHNAME = ? THEN RETURN.
            DO ON ERROR UNDO, THROW:
                THIS-OBJECT:Icon = NEW Icon(FILE-INFORMATION:FULL-PATHNAME).
                CATCH e AS Progress.Lang.Error:
                    /* a bad icon is not worth stopping for */
                END CATCH.
            END.
        END SET.

    CONSTRUCTOR PUBLIC ArcadeWindow(INPUT pcTitle AS CHARACTER, INPUT poCatalog AS IGameCatalog, INPUT poLauncher AS IGameLauncher):
        DEFINE VARIABLE i    AS INTEGER   NO-UNDO.
        DEFINE VARIABLE rowsShown AS INTEGER NO-UNDO.
        SUPER().
        IF pcTitle = ? OR pcTitle = "" THEN UNDO, THROW NEW GridException("An arcade needs a title").
        IF NOT VALID-OBJECT(poCatalog) THEN UNDO, THROW NEW GridException("An arcade needs a game catalog").
        IF NOT VALID-OBJECT(poLauncher) THEN UNDO, THROW NEW GridException("An arcade needs a launcher").
        mCatalog = poCatalog.
        mLauncher = poLauncher.

        THIS-OBJECT:Text = pcTitle.
        THIS-OBJECT:StartPosition = FormStartPosition:CenterScreen.
        THIS-OBJECT:FormBorderStyle = FormBorderStyle:FixedSingle.
        THIS-OBJECT:MaximizeBox = FALSE.
        /* two small chips to a row, 46 pixels a row, so the usual window holds five rows (ten games) without growing;
           a catalog with more than ten scrolls inside the list */
        rowsShown = MINIMUM(5, MAXIMUM(2, INTEGER(TRUNCATE((mCatalog:Count + 1) / 2, 0)))).
        THIS-OBJECT:ClientSize = NEW Size(1120, 650).
        THIS-OBJECT:BackColor = Color:FromArgb(10, 14, 22).
        THIS-OBJECT:ForeColor = Color:FromArgb(245, 239, 230).

        mChipFont = NEW Font("Consolas", System.Convert:ToSingle(15), FontStyle:Bold, GraphicsUnit:Pixel).
        mTagFont = NEW Font("Consolas", System.Convert:ToSingle(11), FontStyle:Bold, GraphicsUnit:Pixel).

        mStatus = NEW Label().
        mStatus:Dock = DockStyle:Bottom.
        mStatus:Height = 28.
        mStatus:TextAlign = ContentAlignment:MiddleLeft.
        mStatus:Padding = NEW Padding(46, 0, 0, 0).
        mStatus:BackColor = Color:FromArgb(10, 14, 22).
        mStatus:ForeColor = Color:FromArgb(110, 120, 138).
        mStatus:Font = NEW Font("Consolas", System.Convert:ToSingle(12), FontStyle:Regular, GraphicsUnit:Pixel).
        mStatus:Text = (IF mCatalog:Count = 0 THEN "No games found" ELSE SUBSTITUTE("&1 games. Pick one to play", mCatalog:Count)).

        mBackdrop = NEW CookoffBackdrop().
        mBackdrop:Dock = DockStyle:Fill.

        /* the chips sit in a panel that wraps them two to a row and scrolls when there are more */
        mFlow = NEW FlowLayoutPanel().
        mFlow:Location = NEW Point(46, 372).
        mFlow:Size = NEW Size(510, rowsShown * 46 + 6).
        mFlow:FlowDirection = FlowDirection:LeftToRight.
        mFlow:WrapContents = TRUE.
        mFlow:AutoScroll = TRUE.
        mFlow:BackColor = Color:Transparent.

        IF mCatalog:Count > 0 THEN DO:
            EXTENT(mButtons) = mCatalog:Count.
            EXTENT(mTitles) = mCatalog:Count.
            EXTENT(mBlurbs) = mCatalog:Count.
            EXTENT(mCategoryOf) = mCatalog:Count.
            DO i = 1 TO mCatalog:Count:
                mTitles[i] = mCatalog:TitleAt(i).
                mBlurbs[i] = mCatalog:BlurbAt(i).
                mCategoryOf[i] = CategoryLabel(mCatalog:CategoryAt(i)).
                mButtons[i] = NewChip(i).
                mFlow:Controls:Add(mButtons[i]).
            END.
        END.
        mBackdrop:Controls:Add(mFlow).

        mTabList = TabsFor().
        IF mTabList <> "" THEN DO:
            BuildTabs().
            ShowTab(ENTRY(1, mTabList)).
        END.

        mDefaultCaption = (IF mTabList <> "" THEN GroupsLine() ELSE NamesLine()).
        mBackdrop:Caption = mDefaultCaption.

        THIS-OBJECT:Controls:Add(mBackdrop).
        THIS-OBJECT:Controls:Add(mStatus).

        mWatcher = NEW Timer().
        mWatcher:Interval = 1000.
        mWatcher:Tick:Subscribe(OnWatch).
        mWatcher:Start().
        THIS-OBJECT:FormClosed:Subscribe(OnFormClosed).
        UpdateButtons().
    END CONSTRUCTOR.

    /* The chip of the game that is started by this program, for tests and scripts. */
    METHOD PUBLIC Button ButtonFor(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mCatalog:Count:
            IF mCatalog:ProgramAt(i) = pcProgram THEN RETURN mButtons[i].
        END.
        UNDO, THROW NEW GridException("The arcade has no game " + STRING(pcProgram)).
    END METHOD.

    /* The colour name (red, orange, blue, purple, green, yellow or teal) of the chip of the game started
       by this program, for tests and scripts. */
    METHOD PUBLIC CHARACTER AccentNameFor(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE place AS INTEGER NO-UNDO.
        place = PlaceOf(pcProgram).
        IF place = 0 THEN UNDO, THROW NEW GridException("The arcade has no game " + STRING(pcProgram)).
        RETURN ENTRY(AccentNumber(place) + 1, "red,orange,blue,purple,green,yellow,teal").
    END METHOD.

    /* The tab button with this name (All, a category, or Other), for tests and scripts. */
    METHOD PUBLIC Button TabFor(INPUT pcName AS CHARACTER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        n = LOOKUP(pcName, mTabList).
        IF n = 0 THEN UNDO, THROW NEW GridException("The arcade has no tab " + STRING(pcName)).
        RETURN mTabs[n].
    END METHOD.

    /* True when the chip of the game started by this program is showing under the tab that is selected.
       (A control reports itself hidden until its window is shown, so this answers from the tab.) */
    METHOD PUBLIC LOGICAL IsShown(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE place AS INTEGER NO-UNDO.
        place = PlaceOf(pcProgram).
        IF place = 0 THEN UNDO, THROW NEW GridException("The arcade has no game " + STRING(pcProgram)).
        RETURN InShownTab(place).
    END METHOD.

    /* Shows only the games of one category, as a click on its tab does: All, or a name in TabNames. The
       list goes back to the top. */
    METHOD PUBLIC VOID ShowTab(INPUT pcName AS CHARACTER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        n = LOOKUP(pcName, mTabList).
        IF n = 0 THEN UNDO, THROW NEW GridException("The arcade has no tab " + STRING(pcName)).
        mShown = ENTRY(n, mTabList).
        mFlow:SuspendLayout().
        DO n = 1 TO mCatalog:Count:
            mButtons[n]:Visible = InShownTab(n).
        END.
        mFlow:ResumeLayout().
        mFlow:AutoScrollPosition = NEW Point(0, 0).
        StyleTabs().
    END METHOD.

    /* True while the launcher says this game is running, which is when its chip shows PLAYING. */
    METHOD PUBLIC LOGICAL IsPlaying(INPUT pcProgram AS CHARACTER):
        RETURN mLauncher:IsRunning(pcProgram).
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

    /* Stops the timers, lets go of the chips' events and frees the drawing. Safe to call more than once. */
    METHOD PUBLIC VOID ReleaseResources():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF mReleased THEN RETURN.
        mReleased = TRUE.
        IF EXTENT(mTabs) <> ? THEN
            DO i = 1 TO EXTENT(mTabs):
                mTabs[i]:Click:Unsubscribe(OnTab).
            END.
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
            mButtons[i]:MouseEnter:Unsubscribe(OnPoint).
            mButtons[i]:MouseLeave:Unsubscribe(OnLeave).
            mButtons[i]:Paint:Unsubscribe(OnPaintChip).
        END.
        mBackdrop:ReleaseResources().
        mChipFont:Dispose().
        mTagFont:Dispose().
        IF VALID-OBJECT(mTabFont) THEN mTabFont:Dispose().
    END METHOD.

    /* Starts the game whose program is given, as a click on its chip does. A game that is already
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

    /* "Life, Minesweeper and Tetris, all cooking on the same grid." made from the games it has. */
    METHOD PRIVATE CHARACTER NamesLine():
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE names AS CHARACTER NO-UNDO.
        IF mCatalog:Count = 0 THEN RETURN "No games found in the run folder yet. Add a run-<game>.p and it will show up here.".
        DO i = 1 TO mCatalog:Count:
            names = names + (IF i = 1 THEN "" ELSE IF i = mCatalog:Count THEN " and " ELSE ", ") + mTitles[i].
        END.
        RETURN names + ", all cooking on the same grid.".
    END METHOD.

    /* The tab a game goes under: its category, or Other when it has none. */
    METHOD PRIVATE CHARACTER CategoryLabel(INPUT pcCategory AS CHARACTER):
        IF pcCategory = ? OR TRIM(pcCategory) = "" THEN RETURN "Other".
        RETURN REPLACE(TRIM(pcCategory), ",", " ").
    END METHOD.

    /* Whether the chip at a place belongs under the tab that is showing. */
    METHOD PRIVATE LOGICAL InShownTab(INPUT piPlace AS INTEGER):
        RETURN mShown = "All" OR mCategoryOf[piPlace] = mShown.
    END METHOD.

    /* The tab names: the categories in alphabetical order, then Other, then All last. Empty when no game named a
       category, because then there is nothing to choose between. */
    METHOD PRIVATE CHARACTER TabsFor():
        DEFINE VARIABLE i      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE j      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE n      AS INTEGER   NO-UNDO.
        DEFINE VARIABLE named  AS LOGICAL   NO-UNDO.
        DEFINE VARIABLE other  AS LOGICAL   NO-UNDO.
        DEFINE VARIABLE cats   AS CHARACTER NO-UNDO.
        DEFINE VARIABLE swap   AS CHARACTER NO-UNDO.
        DO i = 1 TO mCatalog:Count:
            IF TRIM(mCatalog:CategoryAt(i)) <> "" THEN named = TRUE.
            IF mCategoryOf[i] = "Other" THEN other = TRUE.
            ELSE IF LOOKUP(mCategoryOf[i], cats) = 0 THEN cats = cats + (IF cats = "" THEN "" ELSE ",") + mCategoryOf[i].
        END.
        IF NOT named THEN RETURN "".
        n = NUM-ENTRIES(cats).
        DO i = 1 TO n - 1:
            DO j = i + 1 TO n:
                IF ENTRY(j, cats) < ENTRY(i, cats) THEN DO:
                    swap = ENTRY(i, cats).
                    ENTRY(i, cats) = ENTRY(j, cats).
                    ENTRY(j, cats) = swap.
                END.
            END.
        END.
        RETURN cats + (IF other THEN (IF cats = "" THEN "" ELSE ",") + "Other" ELSE "") + (IF cats = "" AND NOT other THEN "" ELSE ",") + "All".
    END METHOD.

    /* The row of tab buttons in the gap between the caption and the chips. */
    METHOD PRIVATE VOID BuildTabs():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mTabFont = NEW Font("Consolas", System.Convert:ToSingle(13), FontStyle:Bold, GraphicsUnit:Pixel).
        mTabFlow = NEW FlowLayoutPanel().
        mTabFlow:Location = NEW Point(46, 338).
        mTabFlow:Size = NEW Size(590, 30).
        mTabFlow:FlowDirection = FlowDirection:LeftToRight.
        mTabFlow:WrapContents = FALSE.
        mTabFlow:BackColor = Color:Transparent.
        EXTENT(mTabs) = NUM-ENTRIES(mTabList).
        DO i = 1 TO NUM-ENTRIES(mTabList):
            mTabs[i] = NEW Button().
            mTabs[i]:Name = ENTRY(i, mTabList).
            mTabs[i]:Text = ENTRY(i, mTabList).
            mTabs[i]:AccessibleName = ENTRY(i, mTabList) + " games".
            mTabs[i]:Size = NEW Size(24 + 9 * LENGTH(ENTRY(i, mTabList)), 28).
            mTabs[i]:Margin = NEW Padding(0, 0, 6, 0).
            mTabs[i]:Font = mTabFont.
            mTabs[i]:BackColor = Color:FromArgb(15, 20, 29).
            mTabs[i]:FlatStyle = FlatStyle:Flat.
            mTabs[i]:FlatAppearance:BorderSize = 1.
            mTabs[i]:Cursor = Cursors:Hand.
            mTabs[i]:Click:Subscribe(OnTab).
            mTabFlow:Controls:Add(mTabs[i]).
        END.
        mBackdrop:Controls:Add(mTabFlow).
        StyleTabs().
    END METHOD.

    /* The tab that is showing is outlined and lettered in the Cookoff orange, the others are quiet. */
    METHOD PRIVATE VOID StyleTabs():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF EXTENT(mTabs) = ? THEN RETURN.
        DO i = 1 TO EXTENT(mTabs):
            IF mTabs[i]:Name = mShown THEN DO:
                mTabs[i]:ForeColor = Color:FromArgb(255, 255, 138, 61).
                mTabs[i]:FlatAppearance:BorderColor = Color:FromArgb(255, 255, 138, 61).
            END.
            ELSE DO:
                mTabs[i]:ForeColor = Color:FromArgb(255, 160, 168, 182).
                mTabs[i]:FlatAppearance:BorderColor = Color:FromArgb(38, 46, 60).
            END.
        END.
    END METHOD.

    /* The caption when there are tabs: a short line, because the names of many games would run into them. */
    METHOD PRIVATE CHARACTER GroupsLine():
        RETURN SUBSTITUTE("&1 games in &2 groups, all cooking on the same grid.", mCatalog:Count, NUM-ENTRIES(mTabList) - 1).
    END METHOD.

    /* The number of the accent colour of the chip at a place, 0 to 6 for red, orange, blue, purple, green,
       yellow and teal. It is the colour the game asked for in its run file, and when it asked for none,
       one worked out from its title, so a game keeps its colour whatever else is added to the list. */
    METHOD PRIVATE INTEGER AccentNumber(INPUT piPlace AS INTEGER):
        DEFINE VARIABLE named AS INTEGER   NO-UNDO.
        DEFINE VARIABLE gameName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE sum   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        named = LOOKUP(mCatalog:AccentAt(piPlace), "red,orange,blue,purple,green,yellow,teal").
        IF named > 0 THEN RETURN named - 1.
        gameName = LC(mTitles[piPlace]).
        DO i = 1 TO LENGTH(gameName):
            sum = sum + ASC(SUBSTRING(gameName, i, 1)) * i.
        END.
        RETURN sum MODULO 7.
    END METHOD.

    /* The accent colour of the chip at a place (see AccentNumber). Red, orange, blue and purple are the
       colours of the artwork's chips. */
    METHOD PRIVATE Color Accent(INPUT piPlace AS INTEGER):
        CASE AccentNumber(piPlace):
            WHEN 0 THEN RETURN Color:FromArgb(255, 242, 84, 90).
            WHEN 1 THEN RETURN Color:FromArgb(255, 255, 138, 61).
            WHEN 2 THEN RETURN Color:FromArgb(255, 74, 144, 240).
            WHEN 3 THEN RETURN Color:FromArgb(255, 165, 107, 240).
            WHEN 4 THEN RETURN Color:FromArgb(255, 61, 214, 140).
            WHEN 5 THEN RETURN Color:FromArgb(255, 242, 193, 78).
            OTHERWISE RETURN Color:FromArgb(255, 56, 200, 220).
        END CASE.
    END METHOD.

    /* The place of the game that is started by this program, or 0. */
    METHOD PRIVATE INTEGER PlaceOf(INPUT pcProgram AS CHARACTER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO mCatalog:Count:
            IF mCatalog:ProgramAt(i) = pcProgram THEN RETURN i.
        END.
        RETURN 0.
    END METHOD.

    /* One chip: a dark flat button with the game's title, and a coloured mark and the PLAYING tag
       painted over it (OnPaintChip). */
    METHOD PRIVATE Button NewChip(INPUT piPlace AS INTEGER):
        DEFINE VARIABLE btn AS Button NO-UNDO.
        btn = NEW Button().
        btn:Size = NEW Size(232, 40).
        btn:Margin = NEW Padding(0, 0, 10, 6).
        btn:Name = mCatalog:ProgramAt(piPlace).
        btn:Text = mTitles[piPlace].
        btn:AccessibleName = mTitles[piPlace].
        btn:TextAlign = ContentAlignment:MiddleLeft.
        btn:Padding = NEW Padding(40, 0, 0, 0).
        btn:Font = mChipFont.
        btn:ForeColor = Color:FromArgb(245, 239, 230).
        btn:BackColor = Color:FromArgb(15, 20, 29).
        btn:FlatStyle = FlatStyle:Flat.
        btn:FlatAppearance:BorderSize = 1.
        btn:FlatAppearance:BorderColor = Color:FromArgb(38, 46, 60).
        btn:FlatAppearance:MouseOverBackColor = Color:FromArgb(22, 29, 41).
        btn:FlatAppearance:MouseDownBackColor = Color:FromArgb(28, 36, 50).
        btn:Cursor = Cursors:Hand.
        btn:Click:Subscribe(OnPlay).
        btn:MouseEnter:Subscribe(OnPoint).
        btn:MouseLeave:Subscribe(OnLeave).
        btn:Paint:Subscribe(OnPaintChip).
        RETURN btn.
    END METHOD.

    /* A game that is running shows PLAYING, with its chip outlined in its colour. */
    METHOD PRIVATE VOID UpdateButtons():
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE playing AS LOGICAL NO-UNDO.
        DO i = 1 TO mCatalog:Count:
            playing = mLauncher:IsRunning(mCatalog:ProgramAt(i)).
            mButtons[i]:AccessibleName = (IF playing THEN mTitles[i] + " (playing)" ELSE mTitles[i]).
            mButtons[i]:FlatAppearance:BorderColor = (IF playing THEN Accent(i) ELSE Color:FromArgb(38, 46, 60)).
            mButtons[i]:Invalidate().
        END.
    END METHOD.

    METHOD PRIVATE VOID OnPlay(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        Play(CAST(poSender, Button):Name).
    END METHOD.

    METHOD PRIVATE VOID OnTab(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        ShowTab(CAST(poSender, Button):Name).
    END METHOD.

    METHOD PRIVATE VOID OnPoint(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        DEFINE VARIABLE place AS INTEGER NO-UNDO.
        place = PlaceOf(CAST(poSender, Button):Name).
        IF place > 0 AND mBlurbs[place] <> "" THEN mBackdrop:Caption = mBlurbs[place].
    END METHOD.

    METHOD PRIVATE VOID OnLeave(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        mBackdrop:Caption = mDefaultCaption.
    END METHOD.

    /* Draws the game's coloured mark at the left of its chip, and PLAYING at the right while it runs. */
    METHOD PRIVATE VOID OnPaintChip(INPUT poSender AS System.Object, INPUT e AS PaintEventArgs):
        DEFINE VARIABLE btn     AS Button     NO-UNDO.
        DEFINE VARIABLE place   AS INTEGER    NO-UNDO.
        DEFINE VARIABLE cy      AS INTEGER    NO-UNDO.
        DEFINE VARIABLE mark    AS SolidBrush NO-UNDO.
        DEFINE VARIABLE glow    AS SolidBrush NO-UNDO.
        DEFINE VARIABLE live    AS SolidBrush NO-UNDO.
        DO ON ERROR UNDO, THROW:
            btn = CAST(poSender, Button).
            place = PlaceOf(btn:Name).
            IF place = 0 THEN RETURN.
            cy = INTEGER(TRUNCATE(btn:Height / 2, 0)).
            e:Graphics:SmoothingMode = SmoothingMode:AntiAlias.
            e:Graphics:TextRenderingHint = TextRenderingHint:AntiAliasGridFit.
            mark = NEW SolidBrush(Accent(place)).
            glow = NEW SolidBrush(Color:FromArgb(45, Accent(place))).
            /* red is round, as the ships are in the artwork, the rest are squares */
            IF AccentNumber(place) = 0 THEN DO:
                e:Graphics:FillEllipse(glow, 11, cy - 12, 24, 24).
                e:Graphics:FillEllipse(mark, 16, cy - 7, 14, 14).
            END.
            ELSE DO:
                e:Graphics:FillRectangle(glow, 11, cy - 12, 24, 24).
                e:Graphics:FillRectangle(mark, 16, cy - 7, 14, 14).
            END.
            IF mLauncher:IsRunning(btn:Name) THEN DO:
                live = NEW SolidBrush(Color:FromArgb(255, 61, 214, 140)).
                e:Graphics:DrawString("PLAYING", mTagFont, live, System.Convert:ToSingle(btn:Width - 64), System.Convert:ToSingle(cy - 7)).
            END.
            FINALLY:
                IF VALID-OBJECT(live) THEN live:Dispose().
                IF VALID-OBJECT(glow) THEN glow:Dispose().
                IF VALID-OBJECT(mark) THEN mark:Dispose().
            END FINALLY.
        END.
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
