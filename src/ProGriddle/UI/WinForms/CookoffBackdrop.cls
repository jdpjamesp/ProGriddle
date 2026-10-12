/* The picture behind the Cookoff window, drawn in code from the Cookoff artwork: a dark navy
   backdrop with a faint grid and a warm glow, the eyebrow line, the Pro Griddle wordmark, the tilted
   COOKOFF badge, the board of mixed grid games on the right, and a caption line that the window
   changes (the tagline, or the blurb of the game under the pointer).

   Everything except the caption is drawn once into a bitmap and then copied, so a repaint costs one
   copy and one line of text. The window places its game buttons on top of this control, at the
   places the layout below leaves free: the buttons go at 48, 372 and the board is at 590, 50.
   Call ReleaseResources when the window closes. */
USING Progress.Lang.*.
USING System.Drawing.Drawing2D.* FROM ASSEMBLY.
USING System.Drawing.Text.* FROM ASSEMBLY.
USING System.Drawing.* FROM ASSEMBLY.
USING System.Windows.Forms.* FROM ASSEMBLY.
USING ProGriddle.UI.WinForms.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.UI.WinForms.CookoffBackdrop INHERITS Panel:

    /* The board of the artwork, 14 by 14, one character a cell. Each symbol is different even when
       case is ignored: . empty, a Life cell, b Life cell fading, p purple, y yellow, g green, u blue,
       k pink (Tetris blocks), # a closed Minesweeper tile, 1 and 2 its numbers, f a flag, d a shot
       that missed, s a ship, x a ship that was hit, z the Tetris ghost. */
    DEFINE PRIVATE VARIABLE mBoard      AS CHARACTER NO-UNDO EXTENT 14.
    DEFINE PRIVATE VARIABLE mArt        AS Bitmap    NO-UNDO.
    DEFINE PRIVATE VARIABLE mCaption    AS CHARACTER NO-UNDO.
    DEFINE PRIVATE VARIABLE mCaptionFont  AS Font      NO-UNDO.
    DEFINE PRIVATE VARIABLE mCaptionBrush AS SolidBrush NO-UNDO.
    DEFINE PRIVATE VARIABLE mFormat     AS StringFormat NO-UNDO.
    DEFINE PRIVATE VARIABLE mReleased   AS LOGICAL   NO-UNDO.

    /* The line under the badge. Setting it repaints. */
    DEFINE PUBLIC PROPERTY Caption AS CHARACTER NO-UNDO
        GET():
            RETURN mCaption.
        END GET.
        SET(INPUT pcValue AS CHARACTER):
            IF pcValue = ? THEN pcValue = "".
            IF pcValue = mCaption THEN RETURN.
            mCaption = pcValue.
            THIS-OBJECT:Invalidate().
        END SET.

    CONSTRUCTOR PUBLIC CookoffBackdrop():
        SUPER().
        THIS-OBJECT:DoubleBuffered = TRUE.
        THIS-OBJECT:BackColor = Color:FromArgb(10, 14, 22).
        mBoard[1]  = "......p..#####".
        mBoard[2]  = ".a...ppp.111##".
        mBoard[3]  = "..a........1#f".
        mBoard[4]  = "aaa........12#".
        mBoard[5]  = "..b.........1#".
        mBoard[6]  = ".aaa.......d..".
        mBoard[7]  = "..b......d..s.".
        mBoard[8]  = ".......sxxs.x.".
        mBoard[9]  = ".....d....d.s.".
        mBoard[10] = "..............".
        mBoard[11] = "..............".
        mBoard[12] = "g.......y.p...".
        mBoard[13] = "g.uu..z.y.ppk.".
        mBoard[14] = "gguu.zzzyyppkk".
        mCaptionFont = NEW Font("Consolas", System.Convert:ToSingle(15), FontStyle:Regular, GraphicsUnit:Pixel).
        mCaptionBrush = NEW SolidBrush(Color:FromArgb(255, 160, 168, 182)).
        mFormat = NEW StringFormat().
        mFormat:Alignment = StringAlignment:Center.
        mFormat:LineAlignment = StringAlignment:Center.
    END CONSTRUCTOR.

    /* Frees the picture, the faceFont and the brush. Safe to call more than once. */
    METHOD PUBLIC VOID ReleaseResources():
        IF mReleased THEN RETURN.
        mReleased = TRUE.
        IF VALID-OBJECT(mArt) THEN mArt:Dispose().
        mArt = ?.
        mCaptionFont:Dispose().
        mCaptionBrush:Dispose().
        mFormat:Dispose().
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnPaint(INPUT e AS PaintEventArgs):
        IF mReleased THEN RETURN.
        IF NOT VALID-OBJECT(mArt) OR mArt:Width <> THIS-OBJECT:ClientSize:Width OR mArt:Height <> THIS-OBJECT:ClientSize:Height THEN BuildArt().
        IF NOT VALID-OBJECT(mArt) THEN RETURN.
        e:Graphics:DrawImageUnscaled(mArt, 0, 0).
        e:Graphics:TextRenderingHint = TextRenderingHint:AntiAliasGridFit.
        e:Graphics:DrawString(mCaption, mCaptionFont, mCaptionBrush,
                              NEW RectangleF(System.Convert:ToSingle(48), System.Convert:ToSingle(296),
                                             System.Convert:ToSingle(510), System.Convert:ToSingle(66))).
        SUPER:OnPaint(e).
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnResize(INPUT e AS System.EventArgs):
        SUPER:OnResize(e).
        THIS-OBJECT:Invalidate().
    END METHOD.

    /* ---- the picture ---- */

    METHOD PRIVATE VOID BuildArt():
        DEFINE VARIABLE w       AS INTEGER NO-UNDO.
        DEFINE VARIABLE h       AS INTEGER NO-UNDO.
        DEFINE VARIABLE g       AS Graphics NO-UNDO.
        DEFINE VARIABLE bg      AS LinearGradientBrush NO-UNDO.
        DEFINE VARIABLE gridPen AS Pen NO-UNDO.
        DEFINE VARIABLE x       AS INTEGER NO-UNDO.
        DEFINE VARIABLE y       AS INTEGER NO-UNDO.
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        w = THIS-OBJECT:ClientSize:Width.
        h = THIS-OBJECT:ClientSize:Height.
        IF w < 1 OR h < 1 THEN RETURN.
        IF VALID-OBJECT(mArt) THEN mArt:Dispose().
        mArt = NEW Bitmap(w, h).
        DO ON ERROR UNDO, THROW:
            g = Graphics:FromImage(mArt).
            g:SmoothingMode = SmoothingMode:AntiAlias.
            g:TextRenderingHint = TextRenderingHint:AntiAliasGridFit.

            bg = NEW LinearGradientBrush(NEW System.Drawing.Rectangle(0, 0, w, h), Color:FromArgb(255, 8, 11, 18),
                                         Color:FromArgb(255, 14, 19, 30), LinearGradientMode:ForwardDiagonal).
            g:FillRectangle(bg, 0, 0, w, h).

            /* a faint grid over everything */
            gridPen = NEW Pen(Color:FromArgb(9, 255, 255, 255), System.Convert:ToSingle(1)).
            DO x = 0 TO w BY 40:
                g:DrawLine(gridPen, x, 0, x, h).
            END.
            DO y = 0 TO h BY 40:
                g:DrawLine(gridPen, 0, y, w, y).
            END.

            /* the warm glow behind the board: rings that get fainter outwards */
            DO i = 1 TO 9:
                Disc(g, 255, 122, 46, 5, w - 200, h - 120, 460 - i * 40).
            END.

            DrawSparkles(g).
            DrawBoard(g).
            DrawWords(g).

            FINALLY:
                IF VALID-OBJECT(gridPen) THEN gridPen:Dispose().
                IF VALID-OBJECT(bg) THEN bg:Dispose().
                IF VALID-OBJECT(g) THEN g:Dispose().
            END FINALLY.
        END.
    END METHOD.

    METHOD PRIVATE VOID DrawSparkles(INPUT g AS Graphics):
        Disc(g, 255, 176, 60, 210, 505, 22, 4).
        Disc(g, 255, 176, 60, 160, 28, 600, 4).
        Disc(g, 255, 150, 50, 190, 545, 598, 5).
        Disc(g, 255, 176, 60, 150, 1100, 330, 3).
        Disc(g, 255, 176, 60, 120, 330, 604, 3).
        Disc(g, 255, 176, 60, 120, 575, 40, 3).
    END METHOD.

    /* A filled circle of the given radius at a centre, in a colour with an opacity. */
    METHOD PRIVATE VOID Disc(INPUT g AS Graphics, INPUT pr AS INTEGER, INPUT pg AS INTEGER, INPUT pb AS INTEGER,
                             INPUT pa AS INTEGER, INPUT cx AS INTEGER, INPUT cy AS INTEGER, INPUT rad AS INTEGER):
        DEFINE VARIABLE brush AS SolidBrush NO-UNDO.
        DO ON ERROR UNDO, THROW:
            brush = NEW SolidBrush(Color:FromArgb(pa, pr, pg, pb)).
            g:FillEllipse(brush, cx - rad, cy - rad, rad * 2, rad * 2).
            FINALLY:
                IF VALID-OBJECT(brush) THEN brush:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* A rounded rectangle path. The caller disposes it. */
    METHOD PRIVATE GraphicsPath RoundPath(INPUT px AS INTEGER, INPUT py AS INTEGER, INPUT pw AS INTEGER, INPUT ph AS INTEGER, INPUT pr AS INTEGER):
        DEFINE VARIABLE path AS GraphicsPath NO-UNDO.
        DEFINE VARIABLE d    AS INTEGER      NO-UNDO.
        d = pr * 2.
        path = NEW GraphicsPath().
        path:AddArc(px, py, d, d, System.Convert:ToSingle(180), System.Convert:ToSingle(90)).
        path:AddArc(px + pw - d, py, d, d, System.Convert:ToSingle(270), System.Convert:ToSingle(90)).
        path:AddArc(px + pw - d, py + ph - d, d, d, System.Convert:ToSingle(0), System.Convert:ToSingle(90)).
        path:AddArc(px, py + ph - d, d, d, System.Convert:ToSingle(90), System.Convert:ToSingle(90)).
        path:CloseFigure().
        RETURN path.
    END METHOD.

    /* Fills a rounded rectangle with a colour at an opacity. */
    METHOD PRIVATE VOID Fill(INPUT g AS Graphics, INPUT pa AS INTEGER, INPUT pr AS INTEGER, INPUT pg AS INTEGER, INPUT pb AS INTEGER,
                             INPUT px AS INTEGER, INPUT py AS INTEGER, INPUT pw AS INTEGER, INPUT ph AS INTEGER, INPUT prad AS INTEGER):
        DEFINE VARIABLE path  AS GraphicsPath NO-UNDO.
        DEFINE VARIABLE brush AS SolidBrush   NO-UNDO.
        DO ON ERROR UNDO, THROW:
            path = RoundPath(px, py, pw, ph, prad).
            brush = NEW SolidBrush(Color:FromArgb(pa, pr, pg, pb)).
            g:FillPath(brush, path).
            FINALLY:
                IF VALID-OBJECT(brush) THEN brush:Dispose().
                IF VALID-OBJECT(path) THEN path:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* Outlines a rounded rectangle, solid or dashed. */
    METHOD PRIVATE VOID Outline(INPUT g AS Graphics, INPUT pr AS INTEGER, INPUT pg AS INTEGER, INPUT pb AS INTEGER, INPUT pa AS INTEGER,
                                INPUT pwidth AS INTEGER, INPUT pdashed AS LOGICAL,
                                INPUT px AS INTEGER, INPUT py AS INTEGER, INPUT pw AS INTEGER, INPUT ph AS INTEGER, INPUT prad AS INTEGER):
        DEFINE VARIABLE path AS GraphicsPath NO-UNDO.
        DEFINE VARIABLE pen  AS Pen          NO-UNDO.
        DO ON ERROR UNDO, THROW:
            path = RoundPath(px, py, pw, ph, prad).
            pen = NEW Pen(Color:FromArgb(pa, pr, pg, pb), System.Convert:ToSingle(pwidth)).
            IF pdashed THEN pen:DashStyle = DashStyle:Dash.
            g:DrawPath(pen, path).
            FINALLY:
                IF VALID-OBJECT(pen) THEN pen:Dispose().
                IF VALID-OBJECT(path) THEN path:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- the board ---- */

    METHOD PRIVATE VOID DrawBoard(INPUT g AS Graphics):
        DEFINE VARIABLE rowNo   AS INTEGER NO-UNDO.
        DEFINE VARIABLE colNo   AS INTEGER NO-UNDO.
        DEFINE VARIABLE fx    AS INTEGER NO-UNDO INITIAL 590.
        DEFINE VARIABLE fy    AS INTEGER NO-UNDO INITIAL 50.
        DEFINE VARIABLE pitch AS INTEGER NO-UNDO INITIAL 33.
        DEFINE VARIABLE padPx   AS INTEGER NO-UNDO INITIAL 22.
        DEFINE VARIABLE kind  AS CHARACTER NO-UNDO.
        /* the frame, with a soft glow round it */
        Fill(g, 14, 255, 122, 46, fx - 8, fy - 8, pitch * 14 + padPx * 2 + 16, pitch * 14 + padPx * 2 + 16, 38).
        Fill(g, 255, 11, 15, 23, fx, fy, pitch * 14 + padPx * 2, pitch * 14 + padPx * 2, 30).
        Outline(g, 38, 46, 60, 255, 2, FALSE, fx, fy, pitch * 14 + padPx * 2, pitch * 14 + padPx * 2, 30).
        DO rowNo = 1 TO 14:
            DO colNo = 1 TO 14:
                kind = SUBSTRING(mBoard[rowNo], colNo, 1).
                DrawCell(g, kind, fx + padPx + (colNo - 1) * pitch, fy + padPx + (rowNo - 1) * pitch, pitch - 5).
            END.
        END.
    END METHOD.

    /* One cell of the board, s pixels square, with its top left corner at x, y. */
    METHOD PRIVATE VOID DrawCell(INPUT g AS Graphics, INPUT pcKind AS CHARACTER, INPUT x AS INTEGER, INPUT y AS INTEGER, INPUT s AS INTEGER):
        DEFINE VARIABLE half AS INTEGER NO-UNDO.
        half = INTEGER(TRUNCATE(s / 2, 0)).
        CASE pcKind:
            WHEN "." THEN DO:
                Fill(g, 255, 17, 22, 32, x, y, s, s, 7).
                Outline(g, 25, 31, 43, 255, 1, FALSE, x, y, s, s, 7).
            END.
            WHEN "a" THEN DO:
                /* a living Life cell glows */
                Fill(g, 40, 255, 138, 61, x - 4, y - 4, s + 8, s + 8, 11).
                Fill(g, 255, 255, 122, 46, x, y, s, s, 8).
                Fill(g, 120, 255, 190, 100, x + 4, y + 3, s - 8, s - 9, 6).
            END.
            WHEN "b" THEN DO:
                Fill(g, 255, 20, 22, 28, x, y, s, s, 7).
                Outline(g, 96, 58, 32, 255, 1, FALSE, x, y, s, s, 7).
            END.
            WHEN "#" THEN Tile(g, 62, 70, 88, x, y, s).
            WHEN "p" THEN Block(g, 165, 107, 240, x, y, s).
            WHEN "y" THEN Block(g, 242, 193, 78, x, y, s).
            WHEN "g" THEN Block(g, 61, 214, 140, x, y, s).
            WHEN "u" THEN Block(g, 74, 144, 240, x, y, s).
            WHEN "k" THEN Block(g, 242, 92, 122, x, y, s).
            WHEN "s" THEN Tile(g, 141, 151, 168, x, y, s).
            WHEN "x" THEN DO:
                Tile(g, 141, 151, 168, x, y, s).
                Disc(g, 242, 84, 84, 255, x + half, y + half, 7).
                Disc(g, 255, 170, 170, 150, x + half - 2, y + half - 2, 3).
            END.
            WHEN "d" THEN DO:
                Fill(g, 255, 14, 24, 42, x, y, s, s, 7).
                Outline(g, 30, 58, 95, 255, 1, FALSE, x, y, s, s, 7).
                Disc(g, 232, 238, 250, 255, x + half, y + half, 5).
            END.
            WHEN "z" THEN DO:
                Fill(g, 255, 20, 16, 32, x, y, s, s, 7).
                Outline(g, 96, 66, 150, 255, 1, TRUE, x, y, s, s, 7).
            END.
            WHEN "1" OR WHEN "2" THEN DO:
                Fill(g, 255, 17, 22, 32, x, y, s, s, 7).
                Outline(g, 25, 31, 43, 255, 1, FALSE, x, y, s, s, 7).
                Digit(g, pcKind, x, y, s).
            END.
            WHEN "f" THEN DO:
                Tile(g, 62, 70, 88, x, y, s).
                Flag(g, x, y).
            END.
        END CASE.
    END METHOD.

    /* A lit block: the colour, a lighter band across the top and a darker lip below. */
    METHOD PRIVATE VOID Block(INPUT g AS Graphics, INPUT pr AS INTEGER, INPUT pg AS INTEGER, INPUT pb AS INTEGER,
                              INPUT x AS INTEGER, INPUT y AS INTEGER, INPUT s AS INTEGER):
        Fill(g, 255, MAXIMUM(0, pr - 60), MAXIMUM(0, pg - 60), MAXIMUM(0, pb - 60), x, y + 2, s, s - 1, 8).
        Fill(g, 255, pr, pg, pb, x, y, s, s - 3, 8).
        Fill(g, 85, 255, 255, 255, x + 3, y + 3, s - 6, 6, 4).
    END METHOD.

    /* A raised tile: a closed Minesweeper square or a ship. */
    METHOD PRIVATE VOID Tile(INPUT g AS Graphics, INPUT pr AS INTEGER, INPUT pg AS INTEGER, INPUT pb AS INTEGER,
                             INPUT x AS INTEGER, INPUT y AS INTEGER, INPUT s AS INTEGER):
        Fill(g, 255, MAXIMUM(0, pr - 30), MAXIMUM(0, pg - 30), MAXIMUM(0, pb - 30), x, y + 1, s, s, 7).
        Fill(g, 255, pr, pg, pb, x, y, s, s - 2, 7).
        Fill(g, 55, 255, 255, 255, x + 2, y + 2, s - 4, 5, 3).
    END METHOD.

    METHOD PRIVATE VOID Digit(INPUT g AS Graphics, INPUT pcDigit AS CHARACTER, INPUT x AS INTEGER, INPUT y AS INTEGER, INPUT s AS INTEGER):
        DEFINE VARIABLE faceFont  AS Font       NO-UNDO.
        DEFINE VARIABLE brush AS SolidBrush NO-UNDO.
        DO ON ERROR UNDO, THROW:
            faceFont = NEW Font("Consolas", System.Convert:ToSingle(17), FontStyle:Bold, GraphicsUnit:Pixel).
            IF pcDigit = "1" THEN brush = NEW SolidBrush(Color:FromArgb(255, 74, 157, 255)).
            ELSE brush = NEW SolidBrush(Color:FromArgb(255, 61, 214, 140)).
            g:DrawString(pcDigit, faceFont, brush, System.Convert:ToSingle(x + s / 2), System.Convert:ToSingle(y + s / 2), mFormat).
            FINALLY:
                IF VALID-OBJECT(brush) THEN brush:Dispose().
                IF VALID-OBJECT(faceFont) THEN faceFont:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* A red flag on a pole, drawn from rectangles. */
    METHOD PRIVATE VOID Flag(INPUT g AS Graphics, INPUT x AS INTEGER, INPUT y AS INTEGER):
        DEFINE VARIABLE pole  AS SolidBrush NO-UNDO.
        DEFINE VARIABLE cloth AS SolidBrush NO-UNDO.
        DO ON ERROR UNDO, THROW:
            pole = NEW SolidBrush(Color:FromArgb(255, 226, 232, 242)).
            cloth = NEW SolidBrush(Color:FromArgb(255, 240, 69, 58)).
            g:FillRectangle(pole, x + 10, y + 6, 2, 17).
            g:FillRectangle(cloth, x + 12, y + 6, 11, 3).
            g:FillRectangle(cloth, x + 12, y + 9, 8, 3).
            g:FillRectangle(cloth, x + 12, y + 12, 5, 3).
            FINALLY:
                IF VALID-OBJECT(cloth) THEN cloth:Dispose().
                IF VALID-OBJECT(pole) THEN pole:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* ---- the words ---- */

    METHOD PRIVATE VOID DrawWords(INPUT g AS Graphics):
        DEFINE VARIABLE mono    AS Font       NO-UNDO.
        DEFINE VARIABLE monoSm  AS Font       NO-UNDO.
        DEFINE VARIABLE word    AS Font       NO-UNDO.
        DEFINE VARIABLE orange  AS SolidBrush NO-UNDO.
        DEFINE VARIABLE cream   AS SolidBrush NO-UNDO.
        DEFINE VARIABLE muted   AS SolidBrush NO-UNDO.
        DEFINE VARIABLE plain   AS StringFormat NO-UNDO.
        DO ON ERROR UNDO, THROW:
            mono = NEW Font("Consolas", System.Convert:ToSingle(14), FontStyle:Bold, GraphicsUnit:Pixel).
            monoSm = NEW Font("Consolas", System.Convert:ToSingle(12), FontStyle:Regular, GraphicsUnit:Pixel).
            word = NEW Font("Segoe UI Black", System.Convert:ToSingle(66), FontStyle:Regular, GraphicsUnit:Pixel).
            orange = NEW SolidBrush(Color:FromArgb(255, 255, 122, 46)).
            cream = NEW SolidBrush(Color:FromArgb(255, 245, 239, 230)).
            muted = NEW SolidBrush(Color:FromArgb(255, 86, 96, 114)).
            plain = StringFormat:GenericTypographic.

            Spaced(g, "A COOKOFF OF GRID GAMES", mono, orange, 48, 50, 4).
            g:DrawString("Pro", word, cream, System.Convert:ToSingle(38), System.Convert:ToSingle(66), plain).
            g:DrawString("Griddle", word, orange, System.Convert:ToSingle(38), System.Convert:ToSingle(132), plain).
            DrawBadge(g, mono, orange).
            Spaced(g, "WRITTEN IN OPENEDGE ABL", monoSm, muted, 48, 596, 3).

            FINALLY:
                IF VALID-OBJECT(muted) THEN muted:Dispose().
                IF VALID-OBJECT(cream) THEN cream:Dispose().
                IF VALID-OBJECT(orange) THEN orange:Dispose().
                IF VALID-OBJECT(word) THEN word:Dispose().
                IF VALID-OBJECT(monoSm) THEN monoSm:Dispose().
                IF VALID-OBJECT(mono) THEN mono:Dispose().
            END FINALLY.
        END.
    END METHOD.

    /* The outlined COOKOFF badge, tilted a little, with a glow. */
    METHOD PRIVATE VOID DrawBadge(INPUT g AS Graphics, INPUT pFont AS Font, INPUT pBrush AS SolidBrush):
        g:TranslateTransform(System.Convert:ToSingle(52), System.Convert:ToSingle(246)).
        g:RotateTransform(System.Convert:ToSingle(-3)).
        Outline(g, 255, 122, 46, 40, 7, FALSE, -2, -2, 154, 44, 22).
        Outline(g, 255, 122, 46, 255, 2, FALSE, 0, 0, 150, 40, 20).
        Spaced(g, "COOKOFF", pFont, pBrush, 24, 12, 5).
        g:ResetTransform().
    END METHOD.

    /* Draws text one character at a time with extra space between, as the artwork's small caps do. */
    METHOD PRIVATE VOID Spaced(INPUT g AS Graphics, INPUT pcText AS CHARACTER, INPUT pFont AS Font, INPUT pBrush AS SolidBrush,
                               INPUT px AS INTEGER, INPUT py AS INTEGER, INPUT pSpacing AS INTEGER):
        DEFINE VARIABLE i       AS INTEGER NO-UNDO.
        DEFINE VARIABLE advance AS DECIMAL NO-UNDO.
        DEFINE VARIABLE plain   AS StringFormat NO-UNDO.
        plain = StringFormat:GenericTypographic.
        /* the faceFont is monospaced, so every character is as wide as the letter M */
        advance = g:MeasureString("MMMMMMMMMM", pFont, 1000, plain):Width / 10.
        DO i = 1 TO LENGTH(pcText):
            g:DrawString(SUBSTRING(pcText, i, 1), pFont, pBrush, System.Convert:ToSingle(px + (i - 1) * (advance + pSpacing)),
                         System.Convert:ToSingle(py), plain).
        END.
    END METHOD.

END CLASS.
