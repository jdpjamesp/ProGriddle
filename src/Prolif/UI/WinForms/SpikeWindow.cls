/* Phase 0 spike: a form hosting SpikeGridView, a one second timer, a click and a key handler.
   Writes every event to a log file so behaviour can be checked without seeing the screen.
   Replaced by GameWindow in Phase 3. */
USING System.Windows.Forms.* FROM ASSEMBLY.
USING System.Windows.Forms.Timer FROM ASSEMBLY.
USING System.Drawing.* FROM ASSEMBLY.
USING Prolif.UI.WinForms.SpikeGridView.

CLASS Prolif.UI.WinForms.SpikeWindow INHERITS Form:

    DEFINE PRIVATE VARIABLE grid        AS SpikeGridView NO-UNDO.
    DEFINE PRIVATE VARIABLE statusText  AS Label         NO-UNDO.
    DEFINE PRIVATE VARIABLE secondTick  AS Timer         NO-UNDO.
    DEFINE PRIVATE VARIABLE repaintTick AS Timer         NO-UNDO.
    DEFINE PRIVATE VARIABLE ticks       AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE lastEvent   AS CHARACTER     NO-UNDO INITIAL "none".
    DEFINE PRIVATE VARIABLE lastPaints  AS INTEGER       NO-UNDO.
    DEFINE PRIVATE VARIABLE logFile     AS CHARACTER     NO-UNDO.
    DEFINE PRIVATE VARIABLE autoExit    AS INTEGER       NO-UNDO.

    CONSTRUCTOR PUBLIC SpikeWindow(INPUT pcLogFile AS CHARACTER, INPUT piAutoExitSeconds AS INTEGER):
        SUPER().
        logFile = pcLogFile.
        autoExit = piAutoExitSeconds.

        THIS-OBJECT:Text = "ProLific GUI spike".
        THIS-OBJECT:ClientSize = NEW Size(640, 680).
        THIS-OBJECT:KeyPreview = TRUE.

        grid = NEW SpikeGridView().
        grid:Dock = DockStyle:Fill.
        statusText = NEW Label().
        statusText:Dock = DockStyle:Bottom.
        statusText:Height = 40.
        THIS-OBJECT:Controls:Add(grid).
        THIS-OBJECT:Controls:Add(statusText).

        grid:MouseDown:Subscribe(GridMouseDown).
        THIS-OBJECT:KeyDown:Subscribe(FormKeyDown).
        THIS-OBJECT:FormClosed:Subscribe(FormClosedHandler).

        secondTick = NEW Timer().
        secondTick:Interval = 1000.
        secondTick:Tick:Subscribe(SecondTickHandler).

        repaintTick = NEW Timer().
        repaintTick:Interval = 100.
        repaintTick:Tick:Subscribe(RepaintTickHandler).

        WriteLog("created").
        secondTick:Start().
        UpdateStatus().
    END CONSTRUCTOR.

    METHOD PRIVATE VOID WriteLog(INPUT pcText AS CHARACTER):
        IF logFile = "" THEN RETURN.
        OUTPUT TO VALUE(logFile) APPEND.
        PUT UNFORMATTED STRING(NOW) " " pcText SKIP.
        OUTPUT CLOSE.
    END METHOD.

    METHOD PRIVATE VOID UpdateStatus():
        statusText:Text = SUBSTITUTE("ticks &1 | last: &2 | grid &3x&3 | paints &4, last paint &5 ms | keys: 1=20x20 2=100x100 R=10/s repaint",
            ticks, lastEvent, grid:Cells, grid:PaintCount, grid:LastPaintMs).
    END METHOD.

    METHOD PRIVATE VOID SecondTickHandler(INPUT sender AS System.Object, INPUT e AS System.EventArgs):
        ticks = ticks + 1.
        WriteLog(SUBSTITUTE("tick &1 paints/s &2 last paint &3 ms grid &4x&4",
            ticks, grid:PaintCount - lastPaints, grid:LastPaintMs, grid:Cells)).
        lastPaints = grid:PaintCount.
        UpdateStatus().
        IF autoExit > 0 AND ticks >= autoExit THEN THIS-OBJECT:Close().
    END METHOD.

    METHOD PRIVATE VOID RepaintTickHandler(INPUT sender AS System.Object, INPUT e AS System.EventArgs):
        grid:Invalidate().
    END METHOD.

    METHOD PRIVATE VOID GridMouseDown(INPUT sender AS System.Object, INPUT e AS MouseEventArgs):
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        IF grid:HitTest(e:X, e:Y, OUTPUT cx, OUTPUT cy) THEN
            lastEvent = SUBSTITUTE("click cell &1,&2 (&3)", cx, cy, STRING(e:Button)).
        ELSE
            lastEvent = SUBSTITUTE("click outside grid at &1,&2", e:X, e:Y).
        WriteLog(lastEvent).
        UpdateStatus().
    END METHOD.

    METHOD PRIVATE VOID FormKeyDown(INPUT sender AS System.Object, INPUT e AS KeyEventArgs):
        lastEvent = SUBSTITUTE("key &1", STRING(e:KeyCode)).
        WriteLog(lastEvent).
        CASE STRING(e:KeyCode):
            WHEN "D1" THEN DO:
                grid:Cells = 20.
                grid:Invalidate().
            END.
            WHEN "D2" THEN DO:
                grid:Cells = 100.
                grid:Invalidate().
            END.
            WHEN "R" THEN DO:
                IF repaintTick:Enabled THEN repaintTick:Stop(). ELSE repaintTick:Start().
                WriteLog(SUBSTITUTE("repaint timer enabled: &1", repaintTick:Enabled)).
            END.
        END CASE.
        UpdateStatus().
    END METHOD.

    METHOD PRIVATE VOID FormClosedHandler(INPUT sender AS System.Object, INPUT e AS FormClosedEventArgs):
        secondTick:Stop().
        repaintTick:Stop().
        secondTick:Tick:Unsubscribe(SecondTickHandler).
        repaintTick:Tick:Unsubscribe(RepaintTickHandler).
        grid:MouseDown:Unsubscribe(GridMouseDown).
        THIS-OBJECT:KeyDown:Unsubscribe(FormKeyDown).
        THIS-OBJECT:FormClosed:Unsubscribe(FormClosedHandler).
        secondTick:Dispose().
        repaintTick:Dispose().
        grid:ReleaseResources().
        WriteLog("closed cleanly").
    END METHOD.

END CLASS.
