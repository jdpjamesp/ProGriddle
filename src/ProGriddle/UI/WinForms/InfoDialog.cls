/* A small modal window that shows a block of text, such as a game's high scores. The text is
   shown in a fixed width font, read only, with an OK button. Enter, Escape and the OK button
   all close it. The caller shows it with ShowDialog and then disposes it.

   Line feeds in the text are turned into the line breaks a text box needs, so a game can
   build its text with plain CHR(10) separators. */
USING Progress.Lang.*.
USING System.Drawing.* FROM ASSEMBLY.
USING System.Windows.Forms.* FROM ASSEMBLY.
USING ProGriddle.Core.*.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.InfoDialog INHERITS Form:

    DEFINE PRIVATE VARIABLE mBox AS TextBox NO-UNDO.
    DEFINE PRIVATE VARIABLE mOk  AS Button  NO-UNDO.

    /* The text on show, with the line breaks the text box uses. */
    DEFINE PUBLIC PROPERTY Body AS CHARACTER NO-UNDO
        GET():
            RETURN mBox:Text.
        END GET.

    CONSTRUCTOR PUBLIC InfoDialog(INPUT pcTitle AS CHARACTER, INPUT pcText AS CHARACTER):
        SUPER().
        IF pcTitle = ? OR pcTitle = "" THEN UNDO, THROW NEW GridException("A dialog needs a title").
        IF pcText = ? THEN UNDO, THROW NEW GridException("A dialog needs some text").

        THIS-OBJECT:Text = pcTitle.
        THIS-OBJECT:FormBorderStyle = FormBorderStyle:FixedDialog.
        THIS-OBJECT:StartPosition = FormStartPosition:CenterParent.
        THIS-OBJECT:MaximizeBox = FALSE.
        THIS-OBJECT:MinimizeBox = FALSE.
        THIS-OBJECT:ShowInTaskbar = FALSE.
        THIS-OBJECT:ClientSize = NEW Size(360, 400).

        mOk = NEW Button().
        mOk:Text = "OK".
        mOk:Dock = DockStyle:Bottom.
        mOk:Height = 34.
        mOk:DialogResult = DialogResult:OK.

        mBox = NEW TextBox().
        mBox:Multiline = TRUE.
        mBox:ReadOnly = TRUE.
        mBox:ScrollBars = ScrollBars:Vertical.
        mBox:BorderStyle = BorderStyle:None.
        mBox:Font = NEW Font("Consolas", System.Convert:ToSingle(11), FontStyle:Regular, GraphicsUnit:Point).
        mBox:Dock = DockStyle:Fill.
        mBox:Text = REPLACE(pcText, CHR(10), CHR(13) + CHR(10)).
        mBox:TabStop = FALSE.

        /* Fill first, then the edge, so the text gets what is left over */
        THIS-OBJECT:Controls:Add(mBox).
        THIS-OBJECT:Controls:Add(mOk).
        THIS-OBJECT:AcceptButton = mOk.
        THIS-OBJECT:CancelButton = mOk.
    END CONSTRUCTOR.

END CLASS.
