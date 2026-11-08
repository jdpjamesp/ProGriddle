/* The drawing half of preview-cuber.p. Draws a picture of Cuber into a BMP file, with no window and no keyboard. The scenario is
   one of: title (the number of the frame after a colon, "title:300"), play (level 2 part way: Pip mid hop, a Coil, a Thorn, a Frost,
   Snuff, halos and lamps in every state), three (level 3, rings and a freeze), ready, over, clear. The picture is drawn three times as
   big as the canvas. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Cuber.*.

VAR CHARACTER cScenario.
VAR CHARACTER cFile.
VAR CuberGame oGame.
VAR CuberPainter oPainter.
VAR PixelCanvas oCanvas.
VAR MEMPTR mBmp.
VAR INTEGER x.
VAR INTEGER y.
VAR INTEGER c.
VAR INTEGER iPos.
VAR INTEGER iScale = 3.
VAR INTEGER iWidth.
VAR INTEGER iHeight.
VAR INTEGER i.
VAR INTEGER r.
VAR INTEGER k.

cScenario = ENTRY(1, SESSION:PARAMETER, "|").
cFile = ENTRY(2, SESSION:PARAMETER, "|").

DO ON ERROR UNDO, THROW:
    oGame = CuberFactory:Create(NEW SeededRandom(7)).
    oPainter = NEW CuberPainter(NEW CuberRecordingRenderer(), oGame).
    CASE ENTRY(1, cScenario, ":"):
        WHEN "title" THEN DO i = 1 TO INTEGER(ENTRY(2, cScenario, ":")):
            oGame:Advance().
        END.
        WHEN "ready" THEN DO:
            oGame:StartGame().
            DO i = 1 TO 20:
                oGame:Advance().
            END.
        END.
        WHEN "play" THEN DO:
            oGame:StartGame().
            oGame:BeginRound(2, 1).
            DO i = 1 TO 90:
                oGame:Advance().
            END.
            oGame:ClearEnemies().
            oGame:StopSpawns().
            oGame:SetLamp(1, 0, 2).
            oGame:SetLamp(2, 0, 2).
            oGame:SetLamp(2, 1, 2).
            oGame:SetLamp(3, 1, 2).
            oGame:SetLamp(3, 2, 2).
            oGame:SetLamp(4, 1, 2).
            oGame:SetLamp(4, 2, 2).
            oGame:SetLamp(5, 2, 2).
            oGame:PlacePip(4, 2).
            oGame:SpawnEnemy(CuberKind:Coil, 3, 0).
            oGame:SetEnemyRest(0, 900).
            oGame:SpawnEnemy(CuberKind:Thorn, 6, 3).
            oGame:SetEnemyRest(1, 900).
            oGame:SpawnEnemy(CuberKind:Frost, 7, 5).
            oGame:SetEnemyRest(2, 900).
            oGame:SpawnEnemy(CuberKind:Snuff, 7, 0).
            oGame:SetEnemyRest(3, 900).
            oGame:RequestHop(CuberDir:DownLeft).
            DO i = 1 TO 7:
                oGame:Advance().
            END.
        END.
        WHEN "three" THEN DO:
            oGame:StartGame().
            oGame:BeginRound(3, 2).
            DO i = 1 TO 90:
                oGame:Advance().
            END.
            oGame:ClearEnemies().
            oGame:StopSpawns().
            DO r = 1 TO 7:
                DO k = 0 TO r - 1:
                    oGame:SetLamp(r, k, (r + k) MODULO 3).
                END.
            END.
            oGame:PlacePip(3, 1).
            oGame:SpawnEnemy(CuberKind:Frost, 3, 1).
            oGame:SpawnEnemy(CuberKind:Thorn, 5, 2).
            oGame:SpawnEnemy(CuberKind:Seed, 6, 1).
            oGame:SpawnEnemy(CuberKind:Puff, 5, 4).
            oGame:SetEnemyRest(1, 900).
            oGame:SetEnemyRest(2, 900).
            oGame:SetEnemyRest(3, 900).
            DO i = 1 TO 4:
                oGame:Advance().
            END.
        END.
        WHEN "over" THEN DO:
            oGame:StartGame().
            oGame:AddScore(4325).
            DO i = 1 TO 3:
                DO k = 1 TO 90:
                    oGame:Advance().
                END.
                oGame:ClearEnemies().
                oGame:StopSpawns().
                oGame:SpawnEnemy(CuberKind:Thorn, 1, 0).
                DO k = 1 TO 62:
                    oGame:Advance().
                END.
            END.
        END.
        WHEN "clear" THEN DO:
            oGame:StartGame().
            DO i = 1 TO 90:
                oGame:Advance().
            END.
            oGame:ClearEnemies().
            oGame:StopSpawns().
            DO r = 1 TO 7:
                DO k = 0 TO r - 1:
                    oGame:SetLamp(r, k, 2).
                END.
            END.
            oGame:SetLamp(2, 1, 0).
            oGame:RequestHop(CuberDir:DownRight).
            DO i = 1 TO 14 + INTEGER(ENTRY(2, cScenario, ":")):
                oGame:Advance().
            END.
        END.
    END CASE.
    oPainter:Render(oGame:Grid, oGame).
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
