/* Phase 0 storage benchmark. Modes extf and memf add an interior fast path (no bounds checks, unrolled neighbours).
    Throwaway code, not framework code.
   Run through bench/run-bench.ps1, or directly:
     _progres -b -p bench/phase0-storage.p -param "mode,width,height,density,gens"
   Modes: ext (dynamic extent, max 28000 cells), mem (MEMPTR), tt (temp table
   with one record per cell), sparse (temp table of live cells only),
   rowclear (Tetris row clear and shift on a 10 x 20 temp table).
   Rules: bounded edges, B3/S23, the same seeded start for every mode, so the
   live count after N generations must match across modes. */

DEFINE VARIABLE cMode   AS CHARACTER NO-UNDO.
DEFINE VARIABLE iW      AS INTEGER   NO-UNDO.
DEFINE VARIABLE iH      AS INTEGER   NO-UNDO.
DEFINE VARIABLE dDens   AS DECIMAL   NO-UNDO.
DEFINE VARIABLE iGens   AS INTEGER   NO-UNDO.
DEFINE VARIABLE lFast   AS LOGICAL   NO-UNDO.
DEFINE VARIABLE i0      AS INTEGER   NO-UNDO.
DEFINE VARIABLE iSeed   AS INT64     NO-UNDO INITIAL 12345.
DEFINE VARIABLE iBuild  AS INT64     NO-UNDO.
DEFINE VARIABLE iRun    AS INT64     NO-UNDO.
DEFINE VARIABLE iLive   AS INTEGER   NO-UNDO.
DEFINE VARIABLE iExtA   AS INTEGER   NO-UNDO EXTENT.
DEFINE VARIABLE iExtB   AS INTEGER   NO-UNDO EXTENT.
DEFINE VARIABLE mA      AS MEMPTR    NO-UNDO.
DEFINE VARIABLE mB      AS MEMPTR    NO-UNDO.

DEFINE TEMP-TABLE ttCell NO-UNDO
    FIELD x AS INTEGER
    FIELD y AS INTEGER
    FIELD s AS INTEGER
    FIELD n AS INTEGER
    INDEX ixy IS PRIMARY UNIQUE x y
    INDEX ixs s.
DEFINE TEMP-TABLE ttLive NO-UNDO
    FIELD x AS INTEGER
    FIELD y AS INTEGER
    INDEX ixy IS PRIMARY UNIQUE x y.
DEFINE TEMP-TABLE ttNext NO-UNDO
    FIELD x AS INTEGER
    FIELD y AS INTEGER
    INDEX ixy IS PRIMARY UNIQUE x y.
DEFINE TEMP-TABLE ttCnt NO-UNDO
    FIELD x AS INTEGER
    FIELD y AS INTEGER
    FIELD n AS INTEGER
    INDEX ixy IS PRIMARY UNIQUE x y.
DEFINE TEMP-TABLE ttT NO-UNDO
    FIELD x AS INTEGER
    FIELD y AS INTEGER
    FIELD v AS INTEGER
    INDEX ixy IS PRIMARY UNIQUE x y.

DEFINE BUFFER bCell FOR ttCell.
DEFINE BUFFER bCnt  FOR ttCnt.

FUNCTION NextRand RETURNS DECIMAL ():
    iSeed = (iSeed * 1103515245 + 12345) MODULO 2147483648.
    RETURN DECIMAL(iSeed) / 2147483648.
END FUNCTION.

DEFINE VARIABLE cParam AS CHARACTER NO-UNDO.
cParam = SESSION:PARAMETER.
cMode = ENTRY(1, cParam).
IF cMode = "extf" OR cMode = "memf" THEN ASSIGN lFast = TRUE cMode = SUBSTRING(cMode, 1, 3).
iW    = INTEGER(ENTRY(2, cParam)).
iH    = INTEGER(ENTRY(3, cParam)).
dDens = DECIMAL(ENTRY(4, cParam)).
iGens = INTEGER(ENTRY(5, cParam)).

DEFINE VARIABLE i AS INTEGER NO-UNDO.
DEFINE VARIABLE x AS INTEGER NO-UNDO.
DEFINE VARIABLE y AS INTEGER NO-UNDO.

ETIME(TRUE).
CASE cMode:
    WHEN "ext" THEN DO:
        EXTENT(iExtA) = iW * iH.
        EXTENT(iExtB) = iW * iH.
        DO i = 1 TO iW * iH:
            iExtA[i] = IF NextRand() < dDens THEN 1 ELSE 0.
        END.
        iBuild = ETIME.
        ETIME(TRUE).
        DO i = 1 TO iGens:
            RUN StepExt.
        END.
        iRun = ETIME.
        DO i = 1 TO iW * iH: iLive = iLive + iExtA[i]. END.
    END.
    WHEN "mem" THEN DO:
        SET-SIZE(mA) = iW * iH * 4.
        SET-SIZE(mB) = iW * iH * 4.
        DO i = 0 TO iW * iH - 1:
            PUT-LONG(mA, i * 4 + 1) = IF NextRand() < dDens THEN 1 ELSE 0.
        END.
        iBuild = ETIME.
        ETIME(TRUE).
        DO i = 1 TO iGens:
            IF i MODULO 2 = 1 THEN RUN StepMem (mA, mB). ELSE RUN StepMem (mB, mA).
        END.
        iRun = ETIME.
        IF iGens MODULO 2 = 1 THEN
            DO i = 0 TO iW * iH - 1: iLive = iLive + GET-LONG(mB, i * 4 + 1). END.
        ELSE
            DO i = 0 TO iW * iH - 1: iLive = iLive + GET-LONG(mA, i * 4 + 1). END.
    END.
    WHEN "tt" THEN DO:
        DO y = 0 TO iH - 1:
            DO x = 0 TO iW - 1:
                CREATE ttCell.
                ASSIGN ttCell.x = x ttCell.y = y
                       ttCell.s = IF NextRand() < dDens THEN 1 ELSE 0.
            END.
        END.
        iBuild = ETIME.
        ETIME(TRUE).
        DO i = 1 TO iGens:
            RUN StepTT.
        END.
        iRun = ETIME.
        FOR EACH ttCell WHERE ttCell.s = 1: iLive = iLive + 1. END.
    END.
    WHEN "sparse" THEN DO:
        DO y = 0 TO iH - 1:
            DO x = 0 TO iW - 1:
                IF NextRand() < dDens THEN DO:
                    CREATE ttLive.
                    ASSIGN ttLive.x = x ttLive.y = y.
                END.
            END.
        END.
        iBuild = ETIME.
        ETIME(TRUE).
        DO i = 1 TO iGens:
            RUN StepSparse.
        END.
        iRun = ETIME.
        FOR EACH ttLive: iLive = iLive + 1. END.
    END.
    WHEN "rowclear" THEN DO:
        RUN RowClearBench.
    END.
END CASE.

MESSAGE SUBSTITUTE("RESULT mode=&1 size=&2x&3 density=&4 gens=&5 build_ms=&6 run_ms=&7 ms_per_gen=&8 live=&9",
    cMode + (IF lFast THEN "f" ELSE ""), iW, iH, dDens, iGens, iBuild, iRun,
    IF iGens > 0 THEN STRING(DECIMAL(iRun) / iGens, ">>>>>9.9") ELSE "n/a", iLive).
QUIT.

PROCEDURE StepExt:
    DEFINE VARIABLE px AS INTEGER NO-UNDO.
    DEFINE VARIABLE py AS INTEGER NO-UNDO.
    DEFINE VARIABLE dx AS INTEGER NO-UNDO.
    DEFINE VARIABLE dy AS INTEGER NO-UNDO.
    DEFINE VARIABLE nx AS INTEGER NO-UNDO.
    DEFINE VARIABLE ny AS INTEGER NO-UNDO.
    DEFINE VARIABLE cnt AS INTEGER NO-UNDO.
    DEFINE VARIABLE st  AS INTEGER NO-UNDO.
    DO py = 0 TO iH - 1:
        DO px = 0 TO iW - 1:
            IF lFast AND px > 0 AND px < iW - 1 AND py > 0 AND py < iH - 1 THEN DO:
                i0 = py * iW + px.
                cnt = iExtA[i0 - iW - 1 + 1] + iExtA[i0 - iW + 1] + iExtA[i0 - iW + 1 + 1] + iExtA[i0 - 1 + 1] + iExtA[i0 + 1 + 1] + iExtA[i0 + iW - 1 + 1] + iExtA[i0 + iW + 1] + iExtA[i0 + iW + 1 + 1].
            END.
            ELSE DO:
            cnt = 0.
            DO dy = -1 TO 1:
                ny = py + dy.
                IF ny < 0 OR ny >= iH THEN NEXT.
                DO dx = -1 TO 1:
                    IF dx = 0 AND dy = 0 THEN NEXT.
                    nx = px + dx.
                    IF nx < 0 OR nx >= iW THEN NEXT.
                    cnt = cnt + iExtA[ny * iW + nx + 1].
                END.
            END.
            END.
            st = iExtA[py * iW + px + 1].
            iExtB[py * iW + px + 1] = IF cnt = 3 OR (st = 1 AND cnt = 2) THEN 1 ELSE 0.
        END.
    END.
    DO px = 1 TO iW * iH: iExtA[px] = iExtB[px]. END.
END PROCEDURE.

PROCEDURE StepMem:
    DEFINE INPUT PARAMETER src AS MEMPTR NO-UNDO.
    DEFINE INPUT PARAMETER dst AS MEMPTR NO-UNDO.
    DEFINE VARIABLE px AS INTEGER NO-UNDO.
    DEFINE VARIABLE py AS INTEGER NO-UNDO.
    DEFINE VARIABLE dx AS INTEGER NO-UNDO.
    DEFINE VARIABLE dy AS INTEGER NO-UNDO.
    DEFINE VARIABLE nx AS INTEGER NO-UNDO.
    DEFINE VARIABLE ny AS INTEGER NO-UNDO.
    DEFINE VARIABLE cnt AS INTEGER NO-UNDO.
    DEFINE VARIABLE st  AS INTEGER NO-UNDO.
    DO py = 0 TO iH - 1:
        DO px = 0 TO iW - 1:
            IF lFast AND px > 0 AND px < iW - 1 AND py > 0 AND py < iH - 1 THEN DO:
                i0 = py * iW + px.
                cnt = GET-LONG(src, (i0 - iW - 1) * 4 + 1) + GET-LONG(src, (i0 - iW) * 4 + 1) + GET-LONG(src, (i0 - iW + 1) * 4 + 1) + GET-LONG(src, (i0 - 1) * 4 + 1) + GET-LONG(src, (i0 + 1) * 4 + 1) + GET-LONG(src, (i0 + iW - 1) * 4 + 1) + GET-LONG(src, (i0 + iW) * 4 + 1) + GET-LONG(src, (i0 + iW + 1) * 4 + 1).
            END.
            ELSE DO:
            cnt = 0.
            DO dy = -1 TO 1:
                ny = py + dy.
                IF ny < 0 OR ny >= iH THEN NEXT.
                DO dx = -1 TO 1:
                    IF dx = 0 AND dy = 0 THEN NEXT.
                    nx = px + dx.
                    IF nx < 0 OR nx >= iW THEN NEXT.
                    cnt = cnt + GET-LONG(src, (ny * iW + nx) * 4 + 1).
                END.
            END.
            END.
            st = GET-LONG(src, (py * iW + px) * 4 + 1).
            PUT-LONG(dst, (py * iW + px) * 4 + 1) = IF cnt = 3 OR (st = 1 AND cnt = 2) THEN 1 ELSE 0.
        END.
    END.
END PROCEDURE.

PROCEDURE StepTT:
    DEFINE VARIABLE dx AS INTEGER NO-UNDO.
    DEFINE VARIABLE dy AS INTEGER NO-UNDO.
    DEFINE VARIABLE nx AS INTEGER NO-UNDO.
    DEFINE VARIABLE ny AS INTEGER NO-UNDO.
    /* Counts are all computed before any state changes, so no second buffer is needed. */
    FOR EACH ttCell: ttCell.n = 0. END.
    FOR EACH ttCell WHERE ttCell.s = 1:
        DO dy = -1 TO 1:
            ny = ttCell.y + dy.
            IF ny < 0 OR ny >= iH THEN NEXT.
            DO dx = -1 TO 1:
                IF dx = 0 AND dy = 0 THEN NEXT.
                nx = ttCell.x + dx.
                IF nx < 0 OR nx >= iW THEN NEXT.
                FIND bCell WHERE bCell.x = nx AND bCell.y = ny NO-ERROR.
                bCell.n = bCell.n + 1.
            END.
        END.
    END.
    FOR EACH ttCell:
        ttCell.s = IF ttCell.n = 3 OR (ttCell.s = 1 AND ttCell.n = 2) THEN 1 ELSE 0.
    END.
END PROCEDURE.

PROCEDURE StepSparse:
    DEFINE VARIABLE dx AS INTEGER NO-UNDO.
    DEFINE VARIABLE dy AS INTEGER NO-UNDO.
    DEFINE VARIABLE nx AS INTEGER NO-UNDO.
    DEFINE VARIABLE ny AS INTEGER NO-UNDO.
    EMPTY TEMP-TABLE ttCnt.
    FOR EACH ttLive:
        DO dy = -1 TO 1:
            ny = ttLive.y + dy.
            IF ny < 0 OR ny >= iH THEN NEXT.
            DO dx = -1 TO 1:
                IF dx = 0 AND dy = 0 THEN NEXT.
                nx = ttLive.x + dx.
                IF nx < 0 OR nx >= iW THEN NEXT.
                FIND bCnt WHERE bCnt.x = nx AND bCnt.y = ny NO-ERROR.
                IF NOT AVAILABLE bCnt THEN DO:
                    CREATE bCnt.
                    ASSIGN bCnt.x = nx bCnt.y = ny bCnt.n = 0.
                END.
                bCnt.n = bCnt.n + 1.
            END.
        END.
    END.
    EMPTY TEMP-TABLE ttNext.
    FOR EACH ttCnt:
        IF ttCnt.n = 3 OR (ttCnt.n = 2 AND CAN-FIND(ttLive WHERE ttLive.x = ttCnt.x AND ttLive.y = ttCnt.y)) THEN DO:
            CREATE ttNext.
            ASSIGN ttNext.x = ttCnt.x ttNext.y = ttCnt.y.
        END.
    END.
    EMPTY TEMP-TABLE ttLive.
    FOR EACH ttNext:
        CREATE ttLive.
        BUFFER-COPY ttNext TO ttLive.
    END.
END PROCEDURE.

PROCEDURE RowClearBench:
    /* 10 x 20 board. Bottom 4 rows full, plus scattered cells above. Time the
       clear of every full row followed by shifting the rows above down. */
    DEFINE VARIABLE rep   AS INTEGER NO-UNDO.
    DEFINE VARIABLE cy    AS INTEGER NO-UNDO.
    DEFINE VARIABLE total AS INT64   NO-UNDO.
    DEFINE VARIABLE t0    AS INT64   NO-UNDO.
    DEFINE VARIABLE cnt   AS INTEGER NO-UNDO.
    DO rep = 1 TO iGens:
        EMPTY TEMP-TABLE ttT.
        DO y = 0 TO 19:
            DO x = 0 TO 9:
                IF y >= 16 OR NextRand() < 0.3 THEN DO:
                    CREATE ttT.
                    ASSIGN ttT.x = x ttT.y = y ttT.v = 1.
                END.
            END.
        END.
        ETIME(TRUE).
        cy = 19.
        DO WHILE cy >= 0:
            cnt = 0.
            FOR EACH ttT WHERE ttT.y = cy: cnt = cnt + 1. END.
            IF cnt = 10 THEN DO:
                FOR EACH ttT WHERE ttT.y = cy: DELETE ttT. END.
                FOR EACH ttT WHERE ttT.y < cy BY ttT.y DESCENDING:
                    ttT.y = ttT.y + 1.
                END.
                /* same row index is checked again after the shift */
            END.
            ELSE cy = cy - 1.
        END.
        total = total + ETIME.
    END.
    iRun = total.
    FOR EACH ttT: iLive = iLive + 1. END.
END PROCEDURE.
