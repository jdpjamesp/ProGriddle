/* The land of Xevious, as functions of the stage and the row, so the same land comes round every time and nothing has to be kept:
   which ground target stands in a row, and which tile of the design (XeviousTilePicture) lies in each square of the ground. A row is
   counted from the start of a stage (row 0 is the first at the bottom of the screen); a column is 0 to 13. Everything here is made
   from a hash of its numbers.

   The tiles join the way the design says (section 2.1):
   - A river and a road each wind down the land one column at a time: a path is straight for 8 rows, then shifts one column
     sideways in a row made of two bend tiles (the river at rows 7 of 8, the road at rows 3 of 8, so the two never shift in the same
     row). The river keeps to columns 2 to 6 and the road to columns 9 to 11, so they never meet except in a crossing row, where a
     road runs along the row to the left edge over the river (a bridge).
   - Forest is a set of corners: a corner of the map (where four tiles meet) is forest or not, and a tile is chosen by its four
     corners. No corner next to a path, a pad or a land line is forest.
   - A ground target stands on a pad, never on a path. The hidden ones (Spire, Pennant) have no pad and no tell.
   - A land line is a 32 x 32 design of four tiles on open ground. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousMap FINAL:

    /* The targets and land lines of the stage last asked about, worked out once (a stage is the same every time round, so these are
       kept by the stage's place in the 16): the kind (-1 for none) and the column of the target of each row, and the land line
       design (-1 for none) of each band of 12 rows. The map is asked about every tile of every row that scrolls in. */
    VAR PRIVATE STATIC INTEGER sStage = 0.
    VAR PRIVATE STATIC INTEGER[120] sKind.
    VAR PRIVATE STATIC INTEGER[120] sCol.
    VAR PRIVATE STATIC INTEGER[12] sLine.

    /* A number from 0 to 32767 made from three numbers, always the same for the same three. */
    METHOD PUBLIC STATIC INTEGER Hash(INPUT piA AS INTEGER, INPUT piB AS INTEGER, INPUT piC AS INTEGER):
        VAR INT64 h.
        h = piA * 73856093 + piB * 19349663 + piC * 83492791 + 12345.
        h = h MODULO 2147483648.
        h = (h * 1103515245 + 12345) MODULO 2147483648.
        h = (h * 1103515245 + 12345) MODULO 2147483648.
        RETURN INTEGER(TRUNCATE(h / 65536, 0)) MODULO 32768.
    END METHOD.

    /* ---- the targets ---- */

    /* The three hidden towers of a stage (piIndex 0 to 2): the row of each. */
    METHOD PUBLIC STATIC INTEGER SolRow(INPUT piStage AS INTEGER, INPUT piIndex AS INTEGER):
        RETURN 14 + (XeviousRules:StageOf(piStage) * 37 + piIndex * 41) MODULO 84.
    END METHOD.

    /* The hidden flag of the odd numbered stages: whether there is one, and its row. */
    METHOD PUBLIC STATIC LOGICAL HasFlag(INPUT piStage AS INTEGER):
        RETURN XeviousRules:StageOf(piStage) MODULO 2 = 1.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FlagRow(INPUT piStage AS INTEGER):
        RETURN 30 + (XeviousRules:StageOf(piStage) * 29) MODULO 70.
    END METHOD.

    /* The percent of rows that hold a target in a stage, which rises with it. */
    METHOD PUBLIC STATIC INTEGER Density(INPUT piStage AS INTEGER):
        RETURN 12 + 2 * XeviousRules:StageOf(piStage).
    END METHOD.

    /* The kind of ground target that stands in a row of a stage, or unknown for none. The first 4 rows and the last 12 are empty. */
    METHOD PUBLIC STATIC XeviousGround KindAt(INPUT piStage AS INTEGER, INPUT piRow AS INTEGER):
        IF piRow < 0 OR piRow >= XeviousRules:StageRows() THEN RETURN ?.
        Prepare(piStage).
        IF sKind[piRow + 1] < 0 THEN RETURN ?.
        RETURN XeviousGround:GetEnum(sKind[piRow + 1]).
    END METHOD.

    /* Works out the targets and the land lines of a stage, unless they are already known. */
    METHOD PRIVATE STATIC VOID Prepare(INPUT piStage AS INTEGER):
        VAR INTEGER row.
        VAR XeviousGround kind.
        IF XeviousRules:StageOf(piStage) = sStage THEN RETURN.
        DO row = 0 TO XeviousRules:StageRows() - 1:
            kind = ComputeKind(piStage, row).
            sKind[row + 1] = (IF VALID-OBJECT(kind) THEN INTEGER(kind) ELSE -1).
            sCol[row + 1] = ComputeCol(piStage, row).
        END.
        sStage = XeviousRules:StageOf(piStage).
        DO row = 0 TO 11:
            sLine[row + 1] = ComputeLine(piStage, row).
        END.
    END METHOD.

    METHOD PRIVATE STATIC XeviousGround ComputeKind(INPUT piStage AS INTEGER, INPUT piRow AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER total.
        VAR INTEGER pick.
        VAR XeviousGround kind.
        VAR INTEGER stage.
        IF piRow < 4 OR piRow >= XeviousRules:StageRows() - 12 THEN RETURN ?.
        DO i = 0 TO 2:
            IF piRow = SolRow(piStage, i) THEN RETURN XeviousGround:Sol.
        END.
        IF HasFlag(piStage) AND piRow = FlagRow(piStage) THEN RETURN XeviousGround:Flag.
        IF Hash(XeviousRules:StageOf(piStage), piRow, 1) MODULO 100 >= Density(piStage) THEN RETURN ?.
        stage = XeviousRules:StageOf(piStage).
        DO i = 0 TO 6:
            kind = XeviousGround:GetEnum(i).
            IF XeviousRules:GroundFirstStage(kind) <= stage THEN total = total + XeviousRules:GroundWeight(kind).
        END.
        pick = Hash(XeviousRules:StageOf(piStage), piRow, 2) MODULO total.
        DO i = 0 TO 6:
            kind = XeviousGround:GetEnum(i).
            IF XeviousRules:GroundFirstStage(kind) <= stage THEN DO:
                IF pick < XeviousRules:GroundWeight(kind) THEN RETURN kind.
                pick = pick - XeviousRules:GroundWeight(kind).
            END.
        END.
        RETURN XeviousGround:Barra.
    END METHOD.

    /* The column (0 to 13) of the target in a row: the column its hash gives, moved right until it is clear of the river and the
       road (and the columns beside them, so a pad never touches a path). */
    METHOD PUBLIC STATIC INTEGER ColAt(INPUT piStage AS INTEGER, INPUT piRow AS INTEGER):
        IF piRow < 0 OR piRow >= XeviousRules:StageRows() THEN RETURN ComputeCol(piStage, piRow).
        Prepare(piStage).
        RETURN sCol[piRow + 1].
    END METHOD.

    METHOD PRIVATE STATIC INTEGER ComputeCol(INPUT piStage AS INTEGER, INPUT piRow AS INTEGER):
        VAR INTEGER c.
        VAR INTEGER n.
        c = Hash(XeviousRules:StageOf(piStage), piRow, 3) MODULO XeviousRules:Cols().
        DO n = 1 TO XeviousRules:Cols():
            IF NOT IsPath(piStage, c - 1, piRow) AND NOT IsPath(piStage, c, piRow) AND NOT IsPath(piStage, c + 1, piRow) THEN RETURN c.
            c = (c + 1) MODULO XeviousRules:Cols().
        END.
        RETURN c.
    END METHOD.

    /* True when a visible ground target stands on a pad in this tile. */
    METHOD PUBLIC STATIC LOGICAL IsPad(INPUT piStage AS INTEGER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        VAR XeviousGround kind.
        kind = KindAt(piStage, piRow).
        IF NOT VALID-OBJECT(kind) THEN RETURN FALSE.
        IF XeviousRules:IsHidden(kind) THEN RETURN FALSE.
        RETURN ColAt(piStage, piRow) = piCol.
    END METHOD.

    /* ---- the river and the road ---- */

    /* Whether a stage has a river, and whether it has a road. */
    METHOD PUBLIC STATIC LOGICAL RiverOn(INPUT piStage AS INTEGER):
        CASE XeviousRules:StageOf(piStage):
            WHEN 2 OR WHEN 5 OR WHEN 8 OR WHEN 11 OR WHEN 13 OR WHEN 15 THEN RETURN TRUE.
            OTHERWISE RETURN FALSE.
        END CASE.
    END METHOD.

    METHOD PUBLIC STATIC LOGICAL RoadOn(INPUT piStage AS INTEGER):
        CASE XeviousRules:StageOf(piStage):
            WHEN 8 OR WHEN 10 OR WHEN 12 THEN RETURN FALSE.
            OTHERWISE RETURN TRUE.
        END CASE.
    END METHOD.

    /* The column the river is in at a row (2 to 6), and the road (9 to 11). A path moves a column every 8 rows. */
    METHOD PUBLIC STATIC INTEGER RiverCol(INPUT piStage AS INTEGER, INPUT piRow AS INTEGER):
        RETURN 4 + XeviousMotion:Wave(XeviousMotion:Div(MAXIMUM(0, piRow), 8) + XeviousRules:StageOf(piStage) * 3, 8, 2).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER RoadCol(INPUT piStage AS INTEGER, INPUT piRow AS INTEGER):
        RETURN 10 + XeviousMotion:Wave(XeviousMotion:Div(MAXIMUM(0, piRow) + 4, 8) + XeviousRules:StageOf(piStage) * 5, 8, 1).
    END METHOD.

    /* True when a row is one where a road runs along it to the left edge over the river (every 24th row, with both on). */
    METHOD PUBLIC STATIC LOGICAL IsCrossing(INPUT piStage AS INTEGER, INPUT piRow AS INTEGER):
        RETURN RiverOn(piStage) AND RoadOn(piStage) AND piRow >= 8 AND piRow < XeviousRules:StageRows() - 8 AND piRow MODULO 24 = 9.
    END METHOD.

    /* True when a tile is part of the river, the road or a crossing (columns off the field are not). */
    METHOD PUBLIC STATIC LOGICAL IsPath(INPUT piStage AS INTEGER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        IF piCol < 0 OR piCol >= XeviousRules:Cols() OR piRow < 0 THEN RETURN FALSE.
        IF IsCrossing(piStage, piRow) AND piCol <= RoadCol(piStage, piRow) THEN RETURN TRUE.
        IF RiverOn(piStage) AND (piCol = RiverCol(piStage, piRow) OR piCol = RiverCol(piStage, piRow + 1)) THEN RETURN TRUE.
        IF RoadOn(piStage) AND (piCol = RoadCol(piStage, piRow) OR piCol = RoadCol(piStage, piRow + 1)) THEN RETURN TRUE.
        RETURN FALSE.
    END METHOD.

    /* The tile of the river or the road at a place (the picture's name without its kind, built by the caller), or unknown when the
       tile is neither. */
    METHOD PRIVATE STATIC XeviousTilePicture PathPicture(INPUT piStage AS INTEGER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        VAR INTEGER a.
        VAR INTEGER b.
        VAR INTEGER rc.
        IF IsCrossing(piStage, piRow) AND piCol <= RoadCol(piStage, piRow) THEN DO:
            IF piCol = RoadCol(piStage, piRow) THEN RETURN XeviousTilePicture:RoadTW.
            IF RiverOn(piStage) AND piCol = RiverCol(piStage, piRow) THEN RETURN XeviousTilePicture:BridgeEw.
            RETURN XeviousTilePicture:RoadEw.
        END.
        IF RiverOn(piStage) THEN DO:
            a = RiverCol(piStage, piRow).
            b = RiverCol(piStage, piRow + 1).
            IF a = b THEN DO:
                IF piCol = a THEN DO:
                    CASE Hash(XeviousRules:StageOf(piStage), piRow, 7) MODULO 3:
                        WHEN 0 THEN RETURN XeviousTilePicture:RiverNs.
                        WHEN 1 THEN RETURN XeviousTilePicture:RiverNs2.
                        OTHERWISE RETURN XeviousTilePicture:RiverNs3.
                    END CASE.
                END.
            END.
            ELSE DO:
                IF piCol = a THEN RETURN (IF b > a THEN XeviousTilePicture:RiverSe ELSE XeviousTilePicture:RiverSw).
                IF piCol = b THEN RETURN (IF b > a THEN XeviousTilePicture:RiverNw ELSE XeviousTilePicture:RiverNe).
            END.
        END.
        IF RoadOn(piStage) THEN DO:
            rc = RoadCol(piStage, piRow).
            a = rc.
            b = RoadCol(piStage, piRow + 1).
            IF a = b THEN DO:
                IF piCol = a THEN RETURN XeviousTilePicture:RoadNs.
            END.
            ELSE DO:
                IF piCol = a THEN RETURN (IF b > a THEN XeviousTilePicture:RoadSe ELSE XeviousTilePicture:RoadSw).
                IF piCol = b THEN RETURN (IF b > a THEN XeviousTilePicture:RoadNw ELSE XeviousTilePicture:RoadNe).
            END.
        END.
        RETURN ?.
    END METHOD.

    /* ---- the land lines ---- */

    /* The percent of the bands of 12 rows that hold a land line in a stage. */
    METHOD PUBLIC STATIC INTEGER LinesPercent(INPUT piStage AS INTEGER):
        CASE XeviousRules:StageOf(piStage):
            WHEN 1 THEN RETURN 20.
            WHEN 4 THEN RETURN 30.
            WHEN 10 THEN RETURN 60.
            WHEN 16 THEN RETURN 40.
            OTHERWISE RETURN 6.
        END CASE.
    END METHOD.

    /* The design (0 spiral, 1 sunwheel, 2 lark) and the left column and bottom row of the land line in the band of rows that holds
       a row, or -1 for the design when there is none: a band has one when its hash says so and its four tiles are open ground. */
    METHOD PUBLIC STATIC INTEGER LineDesign(INPUT piStage AS INTEGER, INPUT piRow AS INTEGER):
        IF piRow < 8 OR piRow >= XeviousRules:StageRows() - 12 THEN RETURN -1.
        Prepare(piStage).
        RETURN sLine[XeviousMotion:Div(piRow, 12) + 1].
    END METHOD.

    /* The design of the land line of band piBand (0 up), worked out from the map. */
    METHOD PRIVATE STATIC INTEGER ComputeLine(INPUT piStage AS INTEGER, INPUT piBand AS INTEGER):
        VAR INTEGER band.
        VAR INTEGER c0.
        VAR INTEGER r0.
        band = piBand.
        IF band < 1 OR band >= 9 THEN RETURN -1.
        IF Hash(XeviousRules:StageOf(piStage), band, 11) MODULO 100 >= LinesPercent(piStage) THEN RETURN -1.
        c0 = LineCol(piStage, band).
        r0 = LineRow(piStage, band).
        IF IsPath(piStage, c0 - 1, r0) OR IsPath(piStage, c0, r0) OR IsPath(piStage, c0 + 1, r0) OR IsPath(piStage, c0 + 2, r0)
           OR IsPath(piStage, c0 - 1, r0 + 1) OR IsPath(piStage, c0, r0 + 1) OR IsPath(piStage, c0 + 1, r0 + 1) OR IsPath(piStage, c0 + 2, r0 + 1) THEN RETURN -1.
        IF IsPad(piStage, c0, r0) OR IsPad(piStage, c0 + 1, r0) OR IsPad(piStage, c0, r0 + 1) OR IsPad(piStage, c0 + 1, r0 + 1) THEN RETURN -1.
        RETURN Hash(XeviousRules:StageOf(piStage), band, 13) MODULO 3.
    END METHOD.

    /* The left column of the land line of a band (1 to 11) and its bottom row (the lower of its two rows). */
    METHOD PUBLIC STATIC INTEGER LineCol(INPUT piStage AS INTEGER, INPUT piBand AS INTEGER):
        RETURN 1 + Hash(XeviousRules:StageOf(piStage), piBand, 17) MODULO 11.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER LineRow(INPUT piStage AS INTEGER, INPUT piBand AS INTEGER):
        RETURN piBand * 12 + 2 + Hash(XeviousRules:StageOf(piStage), piBand, 19) MODULO 8.
    END METHOD.

    /* The quarter of a land line in this tile, or unknown. Row r0 of the line is its lower half (the south tiles), r0 + 1 its upper. */
    METHOD PRIVATE STATIC XeviousTilePicture LinePicture(INPUT piStage AS INTEGER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        VAR INTEGER design.
        VAR INTEGER c0.
        VAR INTEGER r0.
        VAR INTEGER band.
        VAR CHARACTER name.
        design = LineDesign(piStage, piRow).
        IF design < 0 THEN RETURN ?.
        band = XeviousMotion:Div(piRow, 12).
        c0 = LineCol(piStage, band).
        r0 = LineRow(piStage, band).
        IF piCol < c0 OR piCol > c0 + 1 OR piRow < r0 OR piRow > r0 + 1 THEN RETURN ?.
        name = "Lines" + ENTRY(design + 1, "Spiral,Sunwheel,Lark") + (IF piRow = r0 + 1 THEN "N" ELSE "S") + (IF piCol = c0 THEN "w" ELSE "e").
        RETURN XeviousTilePicture:GetEnum(name).
    END METHOD.

    /* ---- the forest ---- */

    /* True when the corner of the map at column piCx (0 to 14) and row piCy is forest: the corner of the tiles (piCx - 1, piCy - 1),
       (piCx, piCy - 1), (piCx - 1, piCy) and (piCx, piCy). Forest lies in patches, and never touches a path, a pad or a land line. */
    METHOD PUBLIC STATIC LOGICAL IsForestCorner(INPUT piStage AS INTEGER, INPUT piCx AS INTEGER, INPUT piCy AS INTEGER):
        VAR INTEGER dx.
        VAR INTEGER dy.
        IF piCx < 1 OR piCx >= XeviousRules:Cols() OR piCy < 1 OR piCy >= XeviousRules:StageRows() - 8 THEN RETURN FALSE.
        IF Hash(XeviousRules:StageOf(piStage), XeviousMotion:Div(piCy, 3), XeviousMotion:Div(piCx, 3)) MODULO 100 >= ForestPercent(piStage) THEN RETURN FALSE.
        DO dy = -1 TO 0:
            DO dx = -1 TO 0:
                IF IsPath(piStage, piCx + dx, piCy + dy) OR IsPad(piStage, piCx + dx, piCy + dy)
                   OR VALID-OBJECT(LinePicture(piStage, piCx + dx, piCy + dy)) THEN RETURN FALSE.
            END.
        END.
        RETURN TRUE.
    END METHOD.

    /* The percent of the patches of the land that are forest in a stage. */
    METHOD PUBLIC STATIC INTEGER ForestPercent(INPUT piStage AS INTEGER):
        CASE XeviousRules:StageOf(piStage):
            WHEN 1 THEN RETURN 8.
            WHEN 9 OR WHEN 13 THEN RETURN 55.
            WHEN 3 OR WHEN 6 OR WHEN 15 THEN RETURN 45.
            OTHERWISE RETURN 28.
        END CASE.
    END METHOD.

    /* ---- the tile of a place ---- */

    /* The tile of the design that lies in a column of a row of a stage. A path comes first, then a land line, then the pad of a
       ground target, then forest (chosen by its four corners) and last open ground in one of three variants. */
    METHOD PUBLIC STATIC XeviousTilePicture PictureAt(INPUT piStage AS INTEGER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        VAR XeviousTilePicture pic.
        VAR LOGICAL nw.
        VAR LOGICAL ne.
        VAR LOGICAL sw.
        VAR LOGICAL se.
        VAR CHARACTER corners.
        IF piCol < 0 OR piCol >= XeviousRules:Cols() OR piRow < 0 THEN UNDO, THROW NEW GridException(SUBSTITUTE("There is no tile at column &1, row &2", piCol, piRow)).
        pic = PathPicture(piStage, piCol, piRow).
        IF VALID-OBJECT(pic) THEN RETURN pic.
        pic = LinePicture(piStage, piCol, piRow).
        IF VALID-OBJECT(pic) THEN RETURN pic.
        IF IsPad(piStage, piCol, piRow) THEN RETURN XeviousTilePicture:Pad.
        /* the corners: north is up the screen, which is the higher row */
        nw = IsForestCorner(piStage, piCol, piRow + 1).
        ne = IsForestCorner(piStage, piCol + 1, piRow + 1).
        sw = IsForestCorner(piStage, piCol, piRow).
        se = IsForestCorner(piStage, piCol + 1, piRow).
        IF nw OR ne OR sw OR se THEN DO:
            IF nw AND ne AND sw AND se THEN RETURN (IF Hash(XeviousRules:StageOf(piStage), piCol, piRow) MODULO 3 = 0 THEN XeviousTilePicture:ForestFull2 ELSE XeviousTilePicture:ForestFull).
            corners = (IF nw THEN "nw" ELSE "") + (IF ne THEN "ne" ELSE "") + (IF sw THEN "sw" ELSE "") + (IF se THEN "se" ELSE "").
            RETURN XeviousTilePicture:GetEnum("Forest" + CAPS(SUBSTRING(corners, 1, 1)) + SUBSTRING(corners, 2)).
        END.
        CASE Hash(XeviousRules:StageOf(piStage), piCol, piRow) MODULO 3:
            WHEN 0 THEN RETURN XeviousTilePicture:Open1.
            WHEN 1 THEN RETURN XeviousTilePicture:Open2.
            OTHERWISE RETURN XeviousTilePicture:Open3.
        END CASE.
    END METHOD.

END CLASS.
