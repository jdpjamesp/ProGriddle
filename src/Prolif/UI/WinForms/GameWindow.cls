/* The window that hosts any steppable game. It shows the board (GridView), a toolbar with
   Start or Pause, Step, Reset, the game's own commands, a picker when the game has one and a
   speed slider, and a status bar. It knows nothing about any particular game: the status
   text, picker, extra commands and clicks all come through IGameInput.

   Keys: see KeyMap. Left click and right click on the board go to the game's PrimaryAction and
   SecondaryAction. The window title also carries the status text and the speed, so a script
   can read them from outside.

   Settings: the window size, position and maximised state, the speed and the picker choice
   are restored when the window is built and saved when it closes, under the keys
   "window.width", "window.height", "window.x", "window.y", "window.maximised",
   "<prefix>.speed" and "<prefix>.choice".

   The window owns the GridView it is given and releases it on close. It does not own or
   dispose the controller, clock or settings: whoever built them does, after Application:Run
   returns. All .NET event handlers are removed when the window closes. */
USING Progress.Lang.*.
USING System.Drawing.* FROM ASSEMBLY.
USING System.Windows.Forms.Timer FROM ASSEMBLY.
USING System.Windows.Forms.* FROM ASSEMBLY.
USING Prolif.Core.*.
USING Prolif.Engine.*.
USING Prolif.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.UI.WinForms.GameWindow INHERITS Form:

    DEFINE PRIVATE VARIABLE mController AS GameController NO-UNDO.
    DEFINE PRIVATE VARIABLE mView       AS GridView       NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput      AS IGameInput     NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock      AS IClock         NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings   AS ISettings      NO-UNDO.
    DEFINE PRIVATE VARIABLE mPrefix     AS CHARACTER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mTitle      AS CHARACTER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mKeys       AS KeyMap         NO-UNDO.
    DEFINE PRIVATE VARIABLE mSyncing    AS LOGICAL        NO-UNDO.

    DEFINE PRIVATE VARIABLE mToolbar    AS FlowLayoutPanel NO-UNDO.
    DEFINE PRIVATE VARIABLE mRunButton  AS Button         NO-UNDO.
    DEFINE PRIVATE VARIABLE mStepButton AS Button         NO-UNDO.
    DEFINE PRIVATE VARIABLE mResetButton AS Button        NO-UNDO.
    DEFINE PRIVATE VARIABLE mPicker     AS ComboBox       NO-UNDO.
    DEFINE PRIVATE VARIABLE mSpeed      AS TrackBar       NO-UNDO.
    DEFINE PRIVATE VARIABLE mStatus     AS Label          NO-UNDO.
    DEFINE PRIVATE VARIABLE mCloseTimer AS Timer          NO-UNDO.
    DEFINE PRIVATE VARIABLE mExtraButtons AS Button       NO-UNDO EXTENT.

    /* Closes the window by itself after this many seconds, 0 for never. For scripted runs. */
    DEFINE PUBLIC PROPERTY AutoCloseSeconds AS INTEGER NO-UNDO
        GET.
        SET(INPUT piValue AS INTEGER):
            AutoCloseSeconds = piValue.
            IF piValue > 0 THEN DO:
                mCloseTimer:Interval = piValue * 1000.
                mCloseTimer:Start().
            END.
            ELSE mCloseTimer:Stop().
        END SET.

    CONSTRUCTOR PUBLIC GameWindow(INPUT pcTitle AS CHARACTER, INPUT poController AS GameController,
                                  INPUT poView AS GridView, INPUT poInput AS IGameInput,
                                  INPUT poClock AS IClock, INPUT poSettings AS ISettings,
                                  INPUT pcPrefix AS CHARACTER):
        SUPER().
        IF pcTitle = ? OR pcTitle = "" THEN UNDO, THROW NEW GridException("A window needs a title").
        IF NOT VALID-OBJECT(poController) THEN UNDO, THROW NEW GridException("A window needs a controller").
        IF NOT VALID-OBJECT(poView) THEN UNDO, THROW NEW GridException("A window needs a view").
        IF NOT VALID-OBJECT(poInput) THEN UNDO, THROW NEW GridException("A window needs a game input").
        IF NOT VALID-OBJECT(poClock) THEN UNDO, THROW NEW GridException("A window needs a clock").
        IF NOT VALID-OBJECT(poSettings) THEN UNDO, THROW NEW GridException("A window needs settings").
        IF pcPrefix = ? OR pcPrefix = "" THEN UNDO, THROW NEW GridException("A window needs a settings prefix").

        mTitle = pcTitle.
        mController = poController.
        mView = poView.
        mInput = poInput.
        mClock = poClock.
        mSettings = poSettings.
        mPrefix = pcPrefix.
        mKeys = NEW KeyMap().

        THIS-OBJECT:Text = mTitle.
        THIS-OBJECT:KeyPreview = TRUE.
        mCloseTimer = NEW Timer().
        mCloseTimer:Tick:Subscribe(OnCloseTimer).

        /* Fill first, then the edges, so the board gets what is left over */
        mView:Dock = DockStyle:Fill.
        THIS-OBJECT:Controls:Add(mView).
        BuildStatusBar().
        BuildToolbar().

        RestoreSettings().

        mView:MouseDown:Subscribe(OnViewMouseDown).
        THIS-OBJECT:KeyDown:Subscribe(OnKeyDown).
        THIS-OBJECT:FormClosed:Subscribe(OnFormClosed).
        mClock:Tick:Subscribe(OnClockTick).

        SyncSpeed().
        UpdateStatus().
    END CONSTRUCTOR.

    /* ---- building the window ---- */

    METHOD PRIVATE VOID BuildStatusBar():
        mStatus = NEW Label().
        mStatus:Dock = DockStyle:Bottom.
        mStatus:AutoSize = FALSE.
        mStatus:Height = 26.
        mStatus:TextAlign = ContentAlignment:MiddleLeft.
        mStatus:Padding = NEW Padding(8, 0, 8, 0).
        THIS-OBJECT:Controls:Add(mStatus).
    END METHOD.

    METHOD PRIVATE VOID BuildToolbar():
        DEFINE VARIABLE commands AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i        AS INTEGER   NO-UNDO.
        DEFINE VARIABLE names    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE caption  AS Label     NO-UNDO.

        mToolbar = NEW FlowLayoutPanel().
        mToolbar:Dock = DockStyle:Top.
        mToolbar:AutoSize = TRUE.
        mToolbar:WrapContents = TRUE.
        mToolbar:Padding = NEW Padding(4, 4, 4, 2).

        mRunButton = NewButton("Start", "Start or pause (Space)").
        mRunButton:Click:Subscribe(OnRunClick).
        mStepButton = NewButton("Step", "One generation (S or Right arrow)").
        mStepButton:Click:Subscribe(OnStepClick).
        mResetButton = NewButton("Reset", "Back to the start (R)").
        mResetButton:Click:Subscribe(OnResetClick).

        commands = mInput:CommandNames.
        IF commands <> "" THEN DO:
            EXTENT(mExtraButtons) = NUM-ENTRIES(commands).
            DO i = 1 TO NUM-ENTRIES(commands):
                mExtraButtons[i] = NewButton(mKeys:NameOf(ENTRY(i, commands)),
                    SUBSTITUTE("&1 (&2)", mKeys:NameOf(ENTRY(i, commands)), mKeys:KeyOf(ENTRY(i, commands)))).
                mExtraButtons[i]:Name = mKeys:NameOf(ENTRY(i, commands)).
                mExtraButtons[i]:Click:Subscribe(OnExtraClick).
            END.
        END.

        names = mInput:ChoiceNames.
        IF names <> "" THEN DO:
            caption = NEW Label().
            caption:Text = mInput:ChoiceLabel.
            caption:AutoSize = TRUE.
            caption:Margin = NEW Padding(12, 8, 2, 0).
            mToolbar:Controls:Add(caption).
            mPicker = NEW ComboBox().
            mPicker:DropDownStyle = ComboBoxStyle:DropDownList.
            mPicker:Width = 170.
            mPicker:Margin = NEW Padding(2, 5, 2, 0).
            DO i = 1 TO NUM-ENTRIES(names):
                mPicker:Items:Add(ENTRY(i, names)).
            END.
            mPicker:SelectedIndex = MAXIMUM(0, LOOKUP(mInput:Choice, names) - 1).
            mPicker:SelectedIndexChanged:Subscribe(OnPickerChanged).
            mPicker:DropDownClosed:Subscribe(OnPickerClosed).
            mToolbar:Controls:Add(mPicker).
        END.

        caption = NEW Label().
        caption:Text = "Speed".
        caption:AutoSize = TRUE.
        caption:Margin = NEW Padding(12, 8, 2, 0).
        mToolbar:Controls:Add(caption).
        mSpeed = NEW TrackBar().
        mSpeed:Minimum = 1.
        mSpeed:Maximum = 6.
        mSpeed:Value = 3.
        mSpeed:TickStyle = TickStyle:BottomRight.
        mSpeed:AutoSize = FALSE.
        mSpeed:Width = 130.
        mSpeed:Height = 30.
        mSpeed:ValueChanged:Subscribe(OnSpeedChanged).
        mToolbar:Controls:Add(mSpeed).

        THIS-OBJECT:Controls:Add(mToolbar).
    END METHOD.

    METHOD PRIVATE Button NewButton(INPUT pcText AS CHARACTER, INPUT pcTip AS CHARACTER):
        DEFINE VARIABLE b AS Button NO-UNDO.
        b = NEW Button().
        b:Text = pcText.
        b:AutoSize = TRUE.
        b:Height = 28.
        b:TabStop = FALSE.
        mToolbar:Controls:Add(b).
        RETURN b.
    END METHOD.

    /* ---- settings ---- */

    METHOD PRIVATE VOID RestoreSettings():
        DEFINE VARIABLE w   AS INTEGER NO-UNDO.
        DEFINE VARIABLE h   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE pt  AS Point   NO-UNDO.
        DEFINE VARIABLE wa  AS Rectangle NO-UNDO.
        DEFINE VARIABLE sel AS CHARACTER NO-UNDO.

        w = MAXIMUM(400, MINIMUM(4000, mSettings:GetInteger("window.width", 1000))).
        h = MAXIMUM(300, MINIMUM(3000, mSettings:GetInteger("window.height", 760))).
        THIS-OBJECT:ClientSize = NEW Size(w, h).

        THIS-OBJECT:StartPosition = FormStartPosition:CenterScreen.
        IF mSettings:Has("window.x") AND mSettings:Has("window.y") THEN DO:
            x = mSettings:GetInteger("window.x", 0).
            y = mSettings:GetInteger("window.y", 0).
            /* only use the saved position when the title bar would still be on a screen */
            pt = NEW Point(x + 60, y + 12).
            wa = Screen:GetWorkingArea(pt).
            IF wa:Contains(pt) THEN DO:
                THIS-OBJECT:StartPosition = FormStartPosition:Manual.
                THIS-OBJECT:Location = NEW Point(x, y).
            END.
        END.
        IF mSettings:GetLogical("window.maximised", FALSE) THEN THIS-OBJECT:WindowState = FormWindowState:Maximized.

        mController:SetSpeedLevel(mSettings:GetInteger(mPrefix + ".speed", mController:SpeedLevel)).
        sel = mSettings:GetString(mPrefix + ".choice", mInput:Choice).
        IF mInput:ChoiceNames <> "" AND LOOKUP(sel, mInput:ChoiceNames) > 0 THEN DO:
            mInput:Choice = sel.
            mPicker:SelectedIndex = LOOKUP(mInput:Choice, mInput:ChoiceNames) - 1.
        END.
    END METHOD.

    METHOD PRIVATE VOID SaveSettings():
        DO ON ERROR UNDO, THROW:
            IF THIS-OBJECT:WindowState = FormWindowState:Normal THEN DO:
                mSettings:SetInteger("window.width", THIS-OBJECT:ClientSize:Width).
                mSettings:SetInteger("window.height", THIS-OBJECT:ClientSize:Height).
                mSettings:SetInteger("window.x", THIS-OBJECT:Location:X).
                mSettings:SetInteger("window.y", THIS-OBJECT:Location:Y).
            END.
            mSettings:SetLogical("window.maximised", THIS-OBJECT:WindowState = FormWindowState:Maximized).
            mSettings:SetInteger(mPrefix + ".speed", mController:SpeedLevel).
            IF mInput:ChoiceNames <> "" THEN mSettings:SetString(mPrefix + ".choice", mInput:Choice).
            mSettings:Save().
            /* failing to save settings must never stop a window from closing */
            CATCH e AS Progress.Lang.Error:
                MESSAGE "Could not save settings: " e:GetMessage(1).
            END CATCH.
        END.
    END METHOD.

    /* ---- showing the state ---- */

    METHOD PRIVATE VOID UpdateStatus():
        DEFINE VARIABLE state AS CHARACTER NO-UNDO.
        state = (IF mController:IsRunning THEN "Running" ELSE "Paused").
        mStatus:Text = SUBSTITUTE("&1   Speed &2   &3", mInput:StatusText, mController:SpeedLevel, state).
        THIS-OBJECT:Text = SUBSTITUTE("&1 - &2   Speed &3", mTitle, mInput:StatusText, mController:SpeedLevel).
        mRunButton:Text = (IF mController:IsRunning THEN "Pause" ELSE "Start").
    END METHOD.

    /* Moves the slider to the controller's speed without that move being taken as a request. */
    METHOD PRIVATE VOID SyncSpeed():
        mSyncing = TRUE.
        mSpeed:Value = mController:SpeedLevel.
        mSyncing = FALSE.
    END METHOD.

    METHOD PRIVATE VOID RunCommand(INPUT poCommand AS GameCommand):
        mController:Execute(poCommand).
        SyncSpeed().
        UpdateStatus().
    END METHOD.

    METHOD PRIVATE VOID RunExtra(INPUT pcName AS CHARACTER):
        mInput:Perform(pcName).
        mController:Refresh().
        UpdateStatus().
    END METHOD.

    /* ---- events ---- */

    METHOD PRIVATE VOID OnKeyDown(INPUT poSender AS System.Object, INPUT e AS KeyEventArgs):
        DEFINE VARIABLE keyName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cmd     AS GameCommand NO-UNDO.
        DEFINE VARIABLE extra   AS CHARACTER NO-UNDO.
        IF e:Control OR e:Alt THEN RETURN.
        /* an open pattern list needs its arrow keys and letters for itself */
        IF VALID-OBJECT(mPicker) AND mPicker:DroppedDown THEN RETURN.
        keyName = STRING(e:KeyCode).
        cmd = mKeys:CommandFor(keyName, mController:IsRunning).
        IF VALID-OBJECT(cmd) THEN DO:
            RunCommand(cmd).
            e:Handled = TRUE.
            e:SuppressKeyPress = TRUE.
            RETURN.
        END.
        extra = mKeys:ExtraFor(keyName, mInput:CommandNames).
        IF extra <> "" THEN DO:
            RunExtra(extra).
            e:Handled = TRUE.
            e:SuppressKeyPress = TRUE.
        END.
    END METHOD.

    METHOD PRIVATE VOID OnViewMouseDown(INPUT poSender AS System.Object, INPUT e AS MouseEventArgs):
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        mView:Focus().
        IF NOT mView:HitTest(e:X, e:Y, OUTPUT cx, OUTPUT cy) THEN RETURN.
        IF STRING(e:Button) = "Left" THEN mInput:PrimaryAction(cx, cy).
        ELSE IF STRING(e:Button) = "Right" THEN mInput:SecondaryAction(cx, cy).
        ELSE RETURN.
        mController:Refresh().
        UpdateStatus().
    END METHOD.

    METHOD PRIVATE VOID OnRunClick(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        RunCommand(IF mController:IsRunning THEN GameCommand:PauseGame ELSE GameCommand:Start).
    END METHOD.

    METHOD PRIVATE VOID OnStepClick(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        RunCommand(GameCommand:StepOnce).
    END METHOD.

    METHOD PRIVATE VOID OnResetClick(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        RunCommand(GameCommand:Reset).
    END METHOD.

    METHOD PRIVATE VOID OnExtraClick(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        RunExtra(CAST(poSender, Button):Name).
    END METHOD.

    METHOD PRIVATE VOID OnPickerChanged(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        IF mPicker:SelectedIndex >= 0 THEN mInput:Choice = STRING(mPicker:SelectedItem).
    END METHOD.

    /* After choosing a pattern, give the keyboard back to the board so Space, S, R and the
       other keys act on the game and not on the list. */
    METHOD PRIVATE VOID OnPickerClosed(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        mView:Focus().
    END METHOD.

    METHOD PRIVATE VOID OnSpeedChanged(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        IF mSyncing THEN RETURN.
        mController:SetSpeedLevel(mSpeed:Value).
        UpdateStatus().
    END METHOD.

    METHOD PRIVATE VOID OnClockTick(INPUT piElapsedMs AS INTEGER):
        UpdateStatus().
    END METHOD.

    METHOD PRIVATE VOID OnCloseTimer(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        mCloseTimer:Stop().
        THIS-OBJECT:Close().
    END METHOD.

    /* Stops the game, saves the settings, removes every handler and frees the board. */
    METHOD PRIVATE VOID OnFormClosed(INPUT poSender AS System.Object, INPUT e AS FormClosedEventArgs):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        mController:PauseGame().
        SaveSettings().

        mCloseTimer:Stop().
        mCloseTimer:Tick:Unsubscribe(OnCloseTimer).
        mCloseTimer:Dispose().
        mClock:Tick:Unsubscribe(OnClockTick).
        mView:MouseDown:Unsubscribe(OnViewMouseDown).
        THIS-OBJECT:KeyDown:Unsubscribe(OnKeyDown).
        THIS-OBJECT:FormClosed:Unsubscribe(OnFormClosed).
        mRunButton:Click:Unsubscribe(OnRunClick).
        mStepButton:Click:Unsubscribe(OnStepClick).
        mResetButton:Click:Unsubscribe(OnResetClick).
        IF EXTENT(mExtraButtons) <> ? THEN DO i = 1 TO EXTENT(mExtraButtons):
            mExtraButtons[i]:Click:Unsubscribe(OnExtraClick).
        END.
        IF VALID-OBJECT(mPicker) THEN DO:
            mPicker:SelectedIndexChanged:Unsubscribe(OnPickerChanged).
            mPicker:DropDownClosed:Unsubscribe(OnPickerClosed).
        END.
        mSpeed:ValueChanged:Unsubscribe(OnSpeedChanged).
        mView:ReleaseResources().
    END METHOD.

END CLASS.
