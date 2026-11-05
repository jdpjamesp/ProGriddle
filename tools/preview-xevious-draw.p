/* The drawing half of preview-xevious.p. Draws a picture of Xevious into a BMP file, with no window and no keyboard, so the look can be
   checked from a script. Run it under _progres from the repository root:

     _progres -b -T "%TEMP%\ProGriddle" -p tools/preview-xevious.p -param "seed|scenario|file.bmp"

   The scenario is one of: title, area (the area start band), play (a wave, a target, the sight, a bomb, shots), boss (the Citadel),
   bonus (the end of a stage), dying (the ship breaking up), over (game over). The picture is drawn three times as big as it is. */

USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

DEFINE VARIABLE cSeed     AS CHARACTER          NO-UNDO.
DEFINE VARIABLE cScenario AS CHARACTER          NO-UNDO.
DEFINE VARIABLE cFile     AS CHARACTER          NO-UNDO.
DEFINE VARIABLE oGame     AS XeviousGame        NO-UNDO.
DEFINE VARIABLE oPainter  AS XeviousPainter     NO-UNDO.
DEFINE VARIABLE oCanvas   AS PixelCanvas        NO-UNDO.
DEFINE VARIABLE mBmp      AS MEMPTR             NO-UNDO.
DEFINE VARIABLE x         AS INTEGER            NO-UNDO.
DEFINE VARIABLE y         AS INTEGER            NO-UNDO.
DEFINE VARIABLE c         AS INTEGER            NO-UNDO.
DEFINE VARIABLE iPos      AS INTEGER            NO-UNDO.
DEFINE VARIABLE iScale    AS INTEGER            NO-UNDO INITIAL 3.
DEFINE VARIABLE iWidth    AS INTEGER            NO-UNDO.
DEFINE VARIABLE iHeight   AS INTEGER            NO-UNDO.
DEFINE VARIABLE i         AS INTEGER            NO-UNDO.
DEFINE VARIABLE iStage    AS INTEGER            NO-UNDO INITIAL 3.

cSeed = ENTRY(1, SESSION:PARAMETER, "|").
cScenario = ENTRY(2, SESSION:PARAMETER, "|").
cFile = ENTRY(3, SESSION:PARAMETER, "|").
IF NUM-ENTRIES(SESSION:PARAMETER, "|") >= 4 THEN iStage = INTEGER(ENTRY(4, SESSION:PARAMETER, "|")).

DO ON ERROR UNDO, THROW:
    oGame = XeviousFactory:Create(NEW SeededRandom(INT64(cSeed))).
    oPainter = NEW XeviousPainter(NEW XeviousRecordingRenderer(), oGame).
    CASE cScenario:
        WHEN "title" THEN DO i = 1 TO 20:
            oGame:Advance().
        END.
        WHEN "area" THEN DO:
            oGame:StartGame().
            oGame:BeginStage(iStage).
            DO i = 1 TO 40:
                oGame:Advance().
            END.
        END.
        WHEN "play" THEN DO:
            oGame:StartGame().
            oGame:BeginStage(iStage).
            DO i = 1 TO 600:
                oGame:Advance().
                oGame:ClearBullets().
            END.
            oGame:ZapHeld = TRUE.
            oGame:BombHeld = TRUE.
            oGame:SpawnAir(XeviousAir:Toroid, 40, 40).
            oGame:SpawnAir(XeviousAir:Kapi, 120, 20).
            oGame:SpawnAir(XeviousAir:Jara, 170, 60).
            oGame:SpawnAir(XeviousAir:Bacura, 90, 90).
            DO i = 1 TO 18:
                oGame:Advance().
            END.
        END.
        WHEN "boss" THEN DO:
            oGame:StartGame().
            oGame:BeginStage(4).
            oGame:StopWaves().
            oGame:SpawnBoss().
            DO i = 1 TO 200:
                oGame:Advance().
                oGame:ClearBullets().
            END.
        END.
        WHEN "bonus" THEN DO:
            oGame:StartGame().
            oGame:BeginStage(1).
            oGame:StopWaves().
            DO i = 1 TO 2900:
                oGame:Advance().
            END.
            DO i = 1 TO 60:
                oGame:Advance().
            END.
        END.
        WHEN "dying" THEN DO:
            oGame:StartGame().
            oGame:StopWaves().
            oGame:SpawnAir(XeviousAir:Toroid, oGame:PlayerX, oGame:PlayerY).
            DO i = 1 TO 14:
                oGame:Advance().
            END.
        END.
        WHEN "over" THEN DO:
            oGame:StartGame().
            oGame:StopWaves().
            DO i = 1 TO 3:
                oGame:StopWaves().
                oGame:ClearAir().
                DO y = 1 TO 160:
                    oGame:Advance().
                    oGame:ClearBullets().
                END.
                oGame:SpawnAir(XeviousAir:Toroid, oGame:PlayerX, oGame:PlayerY).
                DO y = 1 TO 100:
                    oGame:Advance().
                    oGame:ClearBullets().
                END.
            END.
        END.
    END CASE.
    MESSAGE "Phase" STRING(oGame:Phase) "frames" oGame:Frames "distance" oGame:Distance.
    ETIME(TRUE).
    oPainter:Render(oGame:Grid, oGame).
    MESSAGE "The first render takes" ETIME "ms".
    ETIME(TRUE).
    DO i = 1 TO 10:
        oGame:Advance().
        oPainter:Render(oGame:Grid, oGame).
    END.
    MESSAGE "A frame and a render take" INTEGER(ETIME / 10) "ms".
    oCanvas = oPainter:Canvas.
    iWidth = oCanvas:Width * iScale.
    iHeight = oCanvas:Height * iScale.
    SET-SIZE(mBmp) = 54 + iWidth * 3 * iHeight.
    PUT-STRING(mBmp, 1, 2) = "BM".
    PUT-LONG(mBmp, 3) = 54 + iWidth * 3 * iHeight.
    PUT-LONG(mBmp, 11) = 54.
    PUT-LONG(mBmp, 15) = 40.
    PUT-LONG(mBmp, 19) = iWidth.
    PUT-LONG(mBmp, 23) = iHeight.
    PUT-SHORT(mBmp, 27) = 1.
    PUT-SHORT(mBmp, 29) = 24.
    iPos = 55.
    /* a BMP is written from the bottom row up, each pixel as blue, green, red */
    DO y = iHeight - 1 TO 0 BY -1:
        DO x = 0 TO iWidth - 1:
            c = oCanvas:ColourAt(INTEGER(TRUNCATE(x / iScale, 0)), INTEGER(TRUNCATE(y / iScale, 0))).
            PUT-BYTE(mBmp, iPos) = c MODULO 256.
            PUT-BYTE(mBmp, iPos + 1) = INTEGER(TRUNCATE(c / 256, 0)) MODULO 256.
            PUT-BYTE(mBmp, iPos + 2) = INTEGER(TRUNCATE(c / 65536, 0)).
            iPos = iPos + 3.
        END.
    END.
    COPY-LOB FROM mBmp TO FILE cFile.
    MESSAGE "Wrote" cFile "(" iWidth "x" iHeight ")".

    CATCH eAny AS Progress.Lang.Error:
        MESSAGE "Preview failed:" eAny:GetMessage(1).
    END CATCH.
    FINALLY:
        SET-SIZE(mBmp) = 0.
        IF VALID-OBJECT(oPainter) THEN oPainter:Dispose().
        IF VALID-OBJECT(oGame) THEN oGame:Dispose().
    END FINALLY.
END.
QUIT.
