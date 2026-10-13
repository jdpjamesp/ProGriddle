/* The window that hosts any game. It shows the board (GridView), a toolbar with the game's
   own commands and a picker when the game has one, and a status bar. For a steppable game the
   toolbar also has Start or Pause, Step, Reset and a speed slider. A real time game has Start
   or Pause and New game. A turn based game has just a New game button. It knows nothing about any particular game: the status text,
   picker, extra commands and clicks all come through IGameInput, and whether the game steps
   comes from IGameController.

   After every click, key and command the game's TakeNotice, such as "Question marks on", is
   shown over the middle of the board and fades away.

   A game can offer an extra text screen (IGameInput:InfoLabel and InfoText, the high scores for
   Minesweeper): the window adds a button and a key for it and shows the text in an InfoDialog.

   A game can offer extra drop down lists by also implementing IGameOptions (Life: the rules and the
   board size). The window adds a captioned list for each after the picker, applies a choice with
   SetOption, then redraws, since a choice may replace the game's grid, and shows the game's notice.

   The game's own keys (IGameInput:HandleKey) are offered every key press first, and told when keys
   come up, so a real time game can use the arrow keys. The game's BannerText, such as PAUSED, is
   kept over the board while it is not empty.

   Keys: see KeyMap. A turn based game only answers to the new game keys (R and F2). The mouse
   is read as a gesture and acted on when the last button is released, on the cell under the
   pointer: left alone is PrimaryAction, right alone is SecondaryAction, and a middle click or
   left and right together is TertiaryAction. A double click is a PrimaryAction followed by a
   TertiaryAction, so a game that treats a double click on a number as a chord gets it while a
   game that toggles on every click (Life) still sees both clicks. The window title also carries the status text
   (and the speed when stepping), so a script can read them from outside.

   Settings: the window size, position and maximised state, the speed and the picker choice
   are restored when the window is built and saved when it closes, under the keys
   "window.width", "window.height", "window.x", "window.y", "window.maximised",
   "<prefix>.speed" and "<prefix>.choice", and one "<prefix>.<OptionKey>" for each option.

   The window owns the GridView it is given and releases it on close. It does not own or
   dispose the controller, clock or settings: whoever built them does, after Application:Run
   returns. All .NET event handlers are removed when the window closes. */
USING Progress.Lang.*.
USING System.Drawing.* FROM ASSEMBLY.
USING System.Windows.Forms.Timer FROM ASSEMBLY.
USING System.Windows.Forms.* FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.GameWindow INHERITS Form:

    DEFINE PRIVATE VARIABLE mController AS IGameController NO-UNDO.
    DEFINE PRIVATE VARIABLE mView       AS GridView       NO-UNDO.
    DEFINE PRIVATE VARIABLE mInput      AS IGameInput     NO-UNDO.
    DEFINE PRIVATE VARIABLE mClock      AS IClock         NO-UNDO.
    DEFINE PRIVATE VARIABLE mSettings   AS ISettings      NO-UNDO.
    DEFINE PRIVATE VARIABLE mPrefix     AS CHARACTER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mTitle      AS CHARACTER      NO-UNDO.
    DEFINE PRIVATE VARIABLE mKeys       AS KeyMap         NO-UNDO.
    DEFINE PRIVATE VARIABLE mSyncing    AS LOGICAL        NO-UNDO.
    /* the game's extra drop down lists, when it implements IGameOptions, one box for each option */
    DEFINE PRIVATE VARIABLE mOptions    AS IGameOptions   NO-UNDO.
    DEFINE PRIVATE VARIABLE mOptionBoxes AS ComboBox      NO-UNDO EXTENT.
    /* mouse buttons held now, and every button used since the first went down */
    DEFINE PRIVATE VARIABLE mHeld       AS LOGICAL        NO-UNDO EXTENT 3.
    DEFINE PRIVATE VARIABLE mGesture    AS LOGICAL        NO-UNDO EXTENT 3.
    DEFINE PRIVATE VARIABLE mDouble     AS LOGICAL        NO-UNDO.
    DEFINE PRIVATE VARIABLE mInfoButton AS Button         NO-UNDO.

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

    CONSTRUCTOR PUBLIC GameWindow(INPUT pcTitle AS CHARACTER, INPUT poController AS IGameController,
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
        IF TYPE-OF(poInput, IGameOptions) THEN mOptions = CAST(poInput, IGameOptions).
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
        mView:MouseUp:Subscribe(OnViewMouseUp).
        THIS-OBJECT:Deactivate:Subscribe(OnDeactivate).
        THIS-OBJECT:KeyDown:Subscribe(OnKeyDown).
        THIS-OBJECT:KeyUp:Subscribe(OnKeyUp).
        THIS-OBJECT:FormClosed:Subscribe(OnFormClosed).
        mClock:Tick:Subscribe(OnClockTick).

        SyncSpeed().
        mController:Refresh().
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
        DEFINE VARIABLE j        AS INTEGER   NO-UNDO.
        DEFINE VARIABLE names    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE captioned    AS FlowLayoutPanel NO-UNDO.

        mToolbar = NEW FlowLayoutPanel().
        mToolbar:Dock = DockStyle:Top.
        mToolbar:AutoSize = TRUE.
        mToolbar:WrapContents = TRUE.
        mToolbar:Padding = NEW Padding(4, 4, 4, 2).

        IF mController:Pausable THEN DO:
            mRunButton = NewButton("Start", "Start or pause (P" + (IF mController:Steppable THEN " or Space" ELSE "") + ")").
            mRunButton:Click:Subscribe(OnRunClick).
        END.
        IF mController:Steppable THEN DO:
            mStepButton = NewButton("Step", "One generation (S or Right arrow)").
            mStepButton:Click:Subscribe(OnStepClick).
            mResetButton = NewButton("Reset", "Back to the start (R)").
        END.
        ELSE mResetButton = NewButton("New game", "Start a new game (R or F2)").
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

        IF mInput:InfoLabel <> "" THEN DO:
            mInfoButton = NewButton(mKeys:NameOf(mInput:InfoLabel),
                SUBSTITUTE("&1 (&2)", mKeys:NameOf(mInput:InfoLabel), mKeys:KeyOf(mInput:InfoLabel))).
            mInfoButton:Click:Subscribe(OnInfoClick).
        END.

        names = mInput:ChoiceNames.
        IF names <> "" THEN DO:
            captioned = NewCaptioned(mInput:ChoiceLabel).
            mPicker = NEW ComboBox().
            mPicker:DropDownStyle = ComboBoxStyle:DropDownList.
            mPicker:Width = 150.
            mPicker:Margin = NEW Padding(2, 5, 2, 0).
            DO i = 1 TO NUM-ENTRIES(names):
                mPicker:Items:Add(ENTRY(i, names)).
            END.
            mPicker:SelectedIndex = MAXIMUM(0, LOOKUP(mInput:Choice, names) - 1).
            mPicker:SelectedIndexChanged:Subscribe(OnPickerChanged).
            mPicker:DropDownClosed:Subscribe(OnPickerClosed).
            captioned:Controls:Add(mPicker).
        END.

        IF VALID-OBJECT(mOptions) AND mOptions:OptionCount > 0 THEN DO:
            EXTENT(mOptionBoxes) = mOptions:OptionCount.
            DO i = 1 TO mOptions:OptionCount:
                names = mOptions:OptionNames(i).
                captioned = NewCaptioned(mOptions:OptionLabel(i)).
                mOptionBoxes[i] = NEW ComboBox().
                mOptionBoxes[i]:Name = STRING(i).
                mOptionBoxes[i]:DropDownStyle = ComboBoxStyle:DropDownList.
                mOptionBoxes[i]:Width = 120.
                mOptionBoxes[i]:Margin = NEW Padding(2, 5, 2, 0).
                DO j = 1 TO NUM-ENTRIES(names):
                    mOptionBoxes[i]:Items:Add(ENTRY(j, names)).
                END.
                mOptionBoxes[i]:SelectedIndex = MAXIMUM(0, LOOKUP(mOptions:OptionValue(i), names) - 1).
                mOptionBoxes[i]:SelectedIndexChanged:Subscribe(OnOptionChanged).
                mOptionBoxes[i]:DropDownClosed:Subscribe(OnPickerClosed).
                captioned:Controls:Add(mOptionBoxes[i]).
            END.
        END.

        IF mController:Steppable THEN DO:
            captioned = NewCaptioned("Speed").
            mSpeed = NEW TrackBar().
            mSpeed:Minimum = 1.
            mSpeed:Maximum = 6.
            mSpeed:Value = 3.
            mSpeed:TickStyle = TickStyle:BottomRight.
            mSpeed:AutoSize = FALSE.
            mSpeed:Width = 130.
            mSpeed:Height = 30.
            mSpeed:ValueChanged:Subscribe(OnSpeedChanged).
            captioned:Controls:Add(mSpeed).
        END.

        THIS-OBJECT:Controls:Add(mToolbar).
    END METHOD.

    /* A captioned part of the toolbar: the caption and the control that follows it are added to the
       panel, which is added to the toolbar, so when the toolbar wraps they move to the next row
       together and a caption is never left behind. */
    METHOD PRIVATE FlowLayoutPanel NewCaptioned(INPUT pcCaption AS CHARACTER):
        DEFINE VARIABLE captioned   AS FlowLayoutPanel NO-UNDO.
        DEFINE VARIABLE caption AS Label           NO-UNDO.
        captioned = NEW FlowLayoutPanel().
        captioned:AutoSize = TRUE.
        captioned:WrapContents = FALSE.
        captioned:FlowDirection = FlowDirection:LeftToRight.
        captioned:Margin = NEW Padding(8, 0, 0, 0).
        captioned:Padding = NEW Padding(0).
        caption = NEW Label().
        caption:Text = pcCaption.
        caption:AutoSize = TRUE.
        caption:Margin = NEW Padding(4, 8, 2, 0).
        captioned:Controls:Add(caption).
        mToolbar:Controls:Add(captioned).
        RETURN captioned.
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

        IF mController:Steppable THEN
            mController:SetSpeedLevel(mSettings:GetInteger(mPrefix + ".speed", mController:SpeedLevel)).
        sel = mSettings:GetString(mPrefix + ".choice", mInput:Choice).
        IF mInput:ChoiceNames <> "" AND LOOKUP(sel, mInput:ChoiceNames) > 0 THEN DO:
            mInput:Choice = sel.
            mPicker:SelectedIndex = LOOKUP(mInput:Choice, mInput:ChoiceNames) - 1.
        END.
        RestoreOptions().
    END METHOD.

    /* Puts back each saved option that is still one of the names on offer. A value the game now
       refuses is ignored: a stale settings file must not stop the window from opening. */
    METHOD PRIVATE VOID RestoreOptions():
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE saved AS CHARACTER NO-UNDO.
        IF NOT VALID-OBJECT(mOptions) THEN RETURN.
        DO i = 1 TO mOptions:OptionCount:
            saved = mSettings:GetString(mPrefix + "." + mOptions:OptionKey(i), "").
            IF saved = "" OR saved = mOptions:OptionValue(i) THEN NEXT.
            IF LOOKUP(saved, mOptions:OptionNames(i)) = 0 THEN NEXT.
            DO ON ERROR UNDO, THROW:
                mOptions:SetOption(i, saved).
                CATCH e AS Progress.Lang.Error:
                    /* keep what the game started with */
                END CATCH.
            END.
            ShowOption(i).
        END.
    END METHOD.

    /* True while one of the game's option lists is dropped down, when it needs the arrow keys and
       the letters for itself. */
    METHOD PRIVATE LOGICAL OptionListOpen():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF EXTENT(mOptionBoxes) = ? THEN RETURN FALSE.
        DO i = 1 TO EXTENT(mOptionBoxes):
            IF mOptionBoxes[i]:DroppedDown THEN RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* Makes box i show the option's value now, without that being taken as a choice. */
    METHOD PRIVATE VOID ShowOption(INPUT piOption AS INTEGER):
        mSyncing = TRUE.
        mOptionBoxes[piOption]:SelectedIndex = MAXIMUM(0, LOOKUP(mOptions:OptionValue(piOption), mOptions:OptionNames(piOption)) - 1).
        mSyncing = FALSE.
    END METHOD.

    METHOD PRIVATE VOID SaveSettings():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO ON ERROR UNDO, THROW:
            IF THIS-OBJECT:WindowState = FormWindowState:Normal THEN DO:
                mSettings:SetInteger("window.width", THIS-OBJECT:ClientSize:Width).
                mSettings:SetInteger("window.height", THIS-OBJECT:ClientSize:Height).
                mSettings:SetInteger("window.x", THIS-OBJECT:Location:X).
                mSettings:SetInteger("window.y", THIS-OBJECT:Location:Y).
            END.
            mSettings:SetLogical("window.maximised", THIS-OBJECT:WindowState = FormWindowState:Maximized).
            IF mController:Steppable THEN mSettings:SetInteger(mPrefix + ".speed", mController:SpeedLevel).
            IF mInput:ChoiceNames <> "" THEN mSettings:SetString(mPrefix + ".choice", mInput:Choice).
            IF VALID-OBJECT(mOptions) THEN DO i = 1 TO mOptions:OptionCount:
                mSettings:SetString(mPrefix + "." + mOptions:OptionKey(i), mOptions:OptionValue(i)).
            END.
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
        IF mController:Steppable THEN DO:
            state = (IF mController:IsRunning THEN "Running" ELSE "Paused").
            mStatus:Text = SUBSTITUTE("&1   Speed &2   &3", mInput:StatusText, mController:SpeedLevel, state).
            THIS-OBJECT:Text = SUBSTITUTE("&1 - &2   Speed &3", mTitle, mInput:StatusText, mController:SpeedLevel).
            mRunButton:Text = (IF mController:IsRunning THEN "Pause" ELSE "Start").
        END.
        ELSE DO:
            mStatus:Text = mInput:StatusText.
            THIS-OBJECT:Text = SUBSTITUTE("&1 - &2", mTitle, mInput:StatusText).
            IF mController:Pausable THEN mRunButton:Text = (IF mController:IsRunning THEN "Pause" ELSE "Start").
        END.
        mView:SetBanner(mInput:BannerText).
    END METHOD.

    /* Moves the slider to the controller's speed without that move being taken as a request. */
    METHOD PRIVATE VOID SyncSpeed():
        IF NOT mController:Steppable THEN RETURN.
        mSyncing = TRUE.
        mSpeed:Value = mController:SpeedLevel.
        mSyncing = FALSE.
    END METHOD.

    METHOD PRIVATE VOID RunCommand(INPUT poCommand AS GameCommand):
        mController:Execute(poCommand).
        SyncSpeed().
        UpdateStatus().
    END METHOD.

    /* Shows what the game has to say about the last action, if anything. */
    METHOD PRIVATE VOID ShowNoticeIfAny():
        DEFINE VARIABLE notice AS CHARACTER NO-UNDO.
        notice = mInput:TakeNotice().
        IF notice <> "" THEN mView:ShowNotice(notice).
    END METHOD.

    METHOD PRIVATE VOID RunExtra(INPUT pcName AS CHARACTER):
        mInput:Perform(pcName).
        mController:Refresh().
        UpdateStatus().
        ShowNoticeIfAny().
    END METHOD.

    /* ---- events ---- */

    METHOD PRIVATE VOID OnKeyDown(INPUT poSender AS System.Object, INPUT e AS KeyEventArgs):
        DEFINE VARIABLE keyName AS CHARACTER NO-UNDO.
        DEFINE VARIABLE cmd     AS GameCommand NO-UNDO.
        DEFINE VARIABLE extra   AS CHARACTER NO-UNDO.
        IF e:Control OR e:Alt THEN RETURN.
        /* an open pattern list needs its arrow keys and letters for itself */
        IF (VALID-OBJECT(mPicker) AND mPicker:DroppedDown) OR OptionListOpen() THEN RETURN.
        keyName = STRING(e:KeyCode).
        /* the game's own keys come first, so a real time game can use the arrows and the space bar */
        IF mInput:HandleKey(keyName) THEN DO:
            mController:Refresh().
            UpdateStatus().
            ShowNoticeIfAny().
            e:Handled = TRUE.
            e:SuppressKeyPress = TRUE.
            RETURN.
        END.
        cmd = mKeys:CommandFor(keyName, mController:IsRunning).
        /* a game that does not step has a new game command, and start and pause when it has a clock */
        IF VALID-OBJECT(cmd) AND NOT mController:Steppable AND cmd <> GameCommand:Reset
           AND NOT (mController:Pausable AND (cmd = GameCommand:Start OR cmd = GameCommand:PauseGame)) THEN cmd = ?.
        IF VALID-OBJECT(cmd) THEN DO:
            RunCommand(cmd).
            e:Handled = TRUE.
            e:SuppressKeyPress = TRUE.
            RETURN.
        END.
        IF mInput:InfoLabel <> "" AND mKeys:ExtraFor(keyName, mInput:InfoLabel) <> "" THEN DO:
            ShowInfo().
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

    METHOD PRIVATE VOID OnKeyUp(INPUT poSender AS System.Object, INPUT e AS KeyEventArgs):
        mInput:ReleaseKey(STRING(e:KeyCode)).
    END METHOD.

    /* 1 for the left button, 2 for the right, 3 for the middle, 0 for any other. */
    METHOD PRIVATE INTEGER ButtonNumber(INPUT poArgs AS MouseEventArgs):
        DEFINE VARIABLE b AS CHARACTER NO-UNDO.
        b = STRING(poArgs:Button).
        IF b = "Left" THEN RETURN 1.
        IF b = "Right" THEN RETURN 2.
        IF b = "Middle" THEN RETURN 3.
        RETURN 0.
    END METHOD.

    METHOD PRIVATE VOID OnViewMouseDown(INPUT poSender AS System.Object, INPUT e AS MouseEventArgs):
        DEFINE VARIABLE b AS INTEGER NO-UNDO.
        mView:Focus().
        b = ButtonNumber(e).
        IF b = 0 THEN RETURN.
        mHeld[b] = TRUE.
        mGesture[b] = TRUE.
        IF b = 1 AND e:Clicks >= 2 THEN mDouble = TRUE.
    END METHOD.

    /* Acts once the last button of the gesture is up, on the cell under the pointer. */
    METHOD PRIVATE VOID OnViewMouseUp(INPUT poSender AS System.Object, INPUT e AS MouseEventArgs):
        DEFINE VARIABLE b    AS INTEGER NO-UNDO.
        DEFINE VARIABLE cx   AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy   AS INTEGER NO-UNDO.
        DEFINE VARIABLE acted AS LOGICAL NO-UNDO.
        b = ButtonNumber(e).
        IF b = 0 THEN RETURN.
        mHeld[b] = FALSE.
        IF mHeld[1] OR mHeld[2] OR mHeld[3] THEN RETURN.
        IF mView:HitTest(e:X, e:Y, OUTPUT cx, OUTPUT cy) THEN DO:
            acted = TRUE.
            IF mGesture[3] OR (mGesture[1] AND mGesture[2]) THEN mInput:TertiaryAction(cx, cy).
            ELSE IF mGesture[1] THEN DO:
                mInput:PrimaryAction(cx, cy).
                IF mDouble THEN mInput:TertiaryAction(cx, cy).
            END.
            ELSE IF mGesture[2] THEN mInput:SecondaryAction(cx, cy).
            ELSE acted = FALSE.
            IF acted THEN DO:
                mController:Refresh().
                UpdateStatus().
                ShowNoticeIfAny().
            END.
        END.
        ResetGesture().
    END METHOD.

    METHOD PRIVATE VOID ResetGesture():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO 3:
            mHeld[i] = FALSE.
            mGesture[i] = FALSE.
        END.
        mDouble = FALSE.
    END METHOD.

    /* A button released while another window had the mouse would leave the gesture stuck. */
    METHOD PRIVATE VOID OnDeactivate(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        ResetGesture().
        mInput:ReleaseKey("").
    END METHOD.

    METHOD PRIVATE VOID OnRunClick(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        RunCommand(IF mController:IsRunning THEN GameCommand:PauseGame ELSE GameCommand:Start).
    END METHOD.

    /* Shows the game's extra text screen and gives the keyboard back to the board. */
    METHOD PRIVATE VOID ShowInfo():
        DEFINE VARIABLE dialog AS InfoDialog NO-UNDO.
        DO ON ERROR UNDO, THROW:
            dialog = NEW InfoDialog(SUBSTITUTE("&1 - &2", mTitle, mKeys:NameOf(mInput:InfoLabel)), mInput:InfoText).
            /* ABL only allows a dialog as the target of a WAIT-FOR */
            WAIT-FOR dialog:ShowDialog(THIS-OBJECT).

            FINALLY:
                IF VALID-OBJECT(dialog) THEN dialog:Dispose().
                mView:Focus().
            END FINALLY.
        END.
    END METHOD.

    METHOD PRIVATE VOID OnInfoClick(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        ShowInfo().
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
        /* a choice can change the game, for example a new board size */
        mController:Refresh().
        UpdateStatus().
    END METHOD.

    /* A choice in one of the game's option lists. The game may refuse it, in which case the notice says
       so and the list goes back to what the game has. */
    METHOD PRIVATE VOID OnOptionChanged(INPUT poSender AS System.Object, INPUT e AS System.EventArgs):
        DEFINE VARIABLE box AS ComboBox NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER  NO-UNDO.
        IF mSyncing THEN RETURN.
        box = CAST(poSender, ComboBox).
        IF box:SelectedIndex < 0 THEN RETURN.
        i = INTEGER(box:Name).
        DO ON ERROR UNDO, THROW:
            mOptions:SetOption(i, STRING(box:SelectedItem)).
            CATCH err AS Progress.Lang.Error:
                mView:ShowNotice(err:GetMessage(1)).
                ShowOption(i).
            END CATCH.
        END.
        /* an option can change the game, for example a new board size */
        mController:Refresh().
        UpdateStatus().
        ShowNoticeIfAny().
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
        mView:MouseUp:Unsubscribe(OnViewMouseUp).
        THIS-OBJECT:Deactivate:Unsubscribe(OnDeactivate).
        THIS-OBJECT:KeyDown:Unsubscribe(OnKeyDown).
        THIS-OBJECT:KeyUp:Unsubscribe(OnKeyUp).
        THIS-OBJECT:FormClosed:Unsubscribe(OnFormClosed).
        IF VALID-OBJECT(mRunButton) THEN mRunButton:Click:Unsubscribe(OnRunClick).
        IF VALID-OBJECT(mStepButton) THEN mStepButton:Click:Unsubscribe(OnStepClick).
        mResetButton:Click:Unsubscribe(OnResetClick).
        IF VALID-OBJECT(mInfoButton) THEN mInfoButton:Click:Unsubscribe(OnInfoClick).
        IF EXTENT(mExtraButtons) <> ? THEN DO i = 1 TO EXTENT(mExtraButtons):
            mExtraButtons[i]:Click:Unsubscribe(OnExtraClick).
        END.
        IF VALID-OBJECT(mPicker) THEN DO:
            mPicker:SelectedIndexChanged:Unsubscribe(OnPickerChanged).
            mPicker:DropDownClosed:Unsubscribe(OnPickerClosed).
        END.
        IF VALID-OBJECT(mSpeed) THEN mSpeed:ValueChanged:Unsubscribe(OnSpeedChanged).
        IF EXTENT(mOptionBoxes) <> ? THEN DO i = 1 TO EXTENT(mOptionBoxes):
            mOptionBoxes[i]:SelectedIndexChanged:Unsubscribe(OnOptionChanged).
            mOptionBoxes[i]:DropDownClosed:Unsubscribe(OnPickerClosed).
        END.
        mView:ReleaseResources().
    END METHOD.

END CLASS.
