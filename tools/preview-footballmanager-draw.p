/* The drawing half of preview-footballmanager.p. Draws a picture of Football Manager into a BMP file, three times as big as the canvas. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

VAR CHARACTER cScenario.
VAR CHARACTER cFile.
VAR FootballGame oGame.
VAR FootballPainter oPainter.
VAR PixelCanvas oCanvas.
VAR MEMPTR mBmp.
VAR INTEGER x.
VAR INTEGER y.
VAR INTEGER c.
VAR INTEGER iPos.
VAR INTEGER iScale = 3.
VAR INTEGER iWidth.
VAR INTEGER iHeight.

cScenario = ENTRY(1, SESSION:PARAMETER, "|").
cFile = ENTRY(2, SESSION:PARAMETER, "|").

DO ON ERROR UNDO, THROW:
    oGame = NEW FootballGame(NEW Grid(NEW ArrayStore(1, 1, "state")), NEW SeededRandom(7)).
    oGame:StartNewGame("Bob", 1, 3, 7).
    oGame:World:Cash = 10000000.
    CASE ENTRY(1, cScenario, ":"):
        WHEN "match" THEN DO:
            oGame:Continue().
            oGame:KickOff().
            oGame:Tick(INTEGER(ENTRY(2, cScenario, ":"))).
        END.
    END CASE.
    oPainter = NEW FootballPainter(NEW RecordingRenderer(), oGame).
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
