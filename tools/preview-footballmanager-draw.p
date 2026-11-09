/* The drawing half of preview-footballmanager.p. Draws a picture of Football Manager into a BMP file, three times as big as the canvas. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

VAR CHARACTER cScenario.
VAR CHARACTER cFile.
VAR FootballGame oGame.
VAR FootballPainter oPainter.
VAR FootballInput oInput.
VAR FootballUi oUi.
VAR LOGICAL lRich.
VAR INTEGER k.
VAR CHARACTER cKeys.
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
    oUi = NEW FootballUi().
    oInput = NEW FootballInput(oGame, oUi).
    oPainter = NEW FootballPainter(NEW RecordingRenderer(), oGame, oUi).
    /* keys:LIST:TICK presses the keys of LIST (such as B,O,B,Return) one at a time, the club having plenty of cash once the game starts, then ticks the match TICK milliseconds */
    IF ENTRY(1, cScenario, ":") = "keys" THEN DO:
        cKeys = ENTRY(2, cScenario, ":").
        DO k = 1 TO NUM-ENTRIES(cKeys):
            oInput:HandleKey(ENTRY(k, cKeys)).
            IF NOT lRich AND oGame:Phase = FootballPhase:Menu THEN ASSIGN
                oGame:World:Cash = 10000000
                lRich = TRUE.
        END.
        IF NUM-ENTRIES(cScenario, ":") >= 3 AND oGame:Phase = FootballPhase:Match THEN oGame:Tick(INTEGER(ENTRY(3, cScenario, ":"))).
    END.
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
