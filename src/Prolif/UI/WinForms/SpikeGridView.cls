/* Phase 0 spike: a double buffered checkerboard control. Replaced by GridView in Phase 3. */
USING System.Windows.Forms.* FROM ASSEMBLY.
USING System.Drawing.* FROM ASSEMBLY.

CLASS Prolif.UI.WinForms.SpikeGridView INHERITS Panel:

    DEFINE PUBLIC PROPERTY Cells AS INTEGER NO-UNDO INITIAL 20
        GET.
        SET.
    DEFINE PUBLIC PROPERTY LastPaintMs AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.
    DEFINE PUBLIC PROPERTY PaintCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PRIVATE VARIABLE brushLight AS SolidBrush NO-UNDO.
    DEFINE PRIVATE VARIABLE brushDark  AS SolidBrush NO-UNDO.

    CONSTRUCTOR PUBLIC SpikeGridView():
        SUPER().
        THIS-OBJECT:DoubleBuffered = TRUE.
        brushLight = NEW SolidBrush(Color:Gainsboro).
        brushDark  = NEW SolidBrush(Color:DimGray).
    END CONSTRUCTOR.

    METHOD PUBLIC INTEGER CellSize():
        RETURN INTEGER(MAXIMUM(1, TRUNCATE(MINIMUM(THIS-OBJECT:ClientSize:Width, THIS-OBJECT:ClientSize:Height) / Cells, 0))).
    END METHOD.

    /* Converts pixels to a cell. Returns false when the point is outside the grid. */
    METHOD PUBLIC LOGICAL HitTest(INPUT px AS INTEGER, INPUT py AS INTEGER,
                                  OUTPUT cx AS INTEGER, OUTPUT cy AS INTEGER):
        DEFINE VARIABLE cs AS INTEGER NO-UNDO.
        cs = CellSize().
        cx = TRUNCATE(px / cs, 0).
        cy = TRUNCATE(py / cs, 0).
        RETURN cx >= 0 AND cx < Cells AND cy >= 0 AND cy < Cells.
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnPaint(INPUT e AS PaintEventArgs):
        DEFINE VARIABLE cs AS INTEGER NO-UNDO.
        DEFINE VARIABLE x  AS INTEGER NO-UNDO.
        DEFINE VARIABLE y  AS INTEGER NO-UNDO.
        ETIME(TRUE).
        cs = CellSize().
        DO y = 0 TO Cells - 1:
            DO x = 0 TO Cells - 1:
                IF (x + y) MODULO 2 = 0 THEN
                    e:Graphics:FillRectangle(brushLight, x * cs, y * cs, cs, cs).
                ELSE
                    e:Graphics:FillRectangle(brushDark, x * cs, y * cs, cs, cs).
            END.
        END.
        LastPaintMs = ETIME.
        PaintCount = PaintCount + 1.
        SUPER:OnPaint(e).
    END METHOD.

    METHOD PUBLIC VOID ReleaseResources():
        IF VALID-OBJECT(brushLight) THEN brushLight:Dispose().
        IF VALID-OBJECT(brushDark) THEN brushDark:Dispose().
        brushLight = ?.
        brushDark = ?.
    END METHOD.

END CLASS.
