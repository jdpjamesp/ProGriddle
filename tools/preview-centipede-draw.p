/* The drawing half of preview-centipede.p. Draws a picture of Centipede into a BMP file, with no window and no keyboard. The scenario is
   one of: title, play (a wave under way, firing), busy (the three pests out, a blighted bulb, a late night), over (the Wick breaking up).
   The picture is drawn three times as big as the canvas. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Centipede.*.

VAR CHARACTER cScenario.
VAR CHARACTER cFile.
VAR CentipedeGame oGame.
VAR CentipedePainter oPainter.
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

cScenario = ENTRY(1, SESSION:PARAMETER, "|").
cFile = ENTRY(2, SESSION:PARAMETER, "|").

DO ON ERROR UNDO, THROW:
    oGame = CentipedeFactory:Create(NEW SeededRandom(7)).
    oPainter = NEW CentipedePainter(NEW CentipedeRecordingRenderer(), oGame).
    CASE cScenario:
        WHEN "title" THEN DO i = 1 TO 100:
            oGame:Advance().
        END.
        WHEN "play" THEN DO:
            oGame:StartGame().
            oGame:MoveX = 1.
            oGame:FireHeld = TRUE.
            DO i = 1 TO 200:
                oGame:Advance().
            END.
        END.
        WHEN "busy" THEN DO:
            oGame:StartGame().
            oGame:PoisonMushroom(4, 6).
            oGame:PlaceMushroom(4, 6, 3).
            oGame:PoisonMushroom(4, 6).
            oGame:SpawnFlea(8).
            oGame:SpawnSpider(TRUE, 22).
            oGame:SpawnScorpion(5, TRUE).
            DO i = 1 TO 130:
                oGame:Advance().
            END.
        END.
        WHEN "over" THEN DO:
            oGame:StartGame().
            oGame:ClearCentipede().
            oGame:PlacePlayer(112, 224).
            oGame:AddSegment(14, 28, -1, TRUE).
            DO i = 1 TO 25:
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
