/* The drawing half of preview-rogue.p. Draws a picture of Rogue into a BMP file, with no window and no keyboard, so the look can be checked from a script. Run it under _progres
   from the repository root:

     _progres -b -T "%TEMP%\ProGriddle" -p tools/preview-rogue.p -param "seed|scenario|file.bmp"

   The scenario is one of: start, explore (the hero runs about a bit), pack, help, deep (level 20, where the rooms are dark), discoveries,
   messages, ask (waiting for a potion to quaff), death. The picture is drawn twice as big as the screen. */


USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

VAR CHARACTER cSeed.
VAR CHARACTER cScenario.
VAR CHARACTER cFile.
VAR RogueGame oGame.
VAR RoguePainter oPainter.
VAR RogueScores oScores.
VAR PixelCanvas oCanvas.
VAR MEMPTR mBmp.
VAR INTEGER x.
VAR INTEGER y.
VAR INTEGER c.
VAR INTEGER iPos.
VAR INTEGER iScale = 2.
VAR INTEGER iWidth.
VAR INTEGER iHeight.
VAR INTEGER i.
VAR CHARACTER cRuns = "run6,run2,run4,run8,run3,run7,run9,run1,run6,run2,run6,run8".

cSeed = ENTRY(1, SESSION:PARAMETER, "|").
cScenario = ENTRY(2, SESSION:PARAMETER, "|").
cFile = ENTRY(3, SESSION:PARAMETER, "|").

DO ON ERROR UNDO, THROW:
    oGame = NEW RogueGame(LevelMap:CreateGrid(), NEW SeededRandom(INT64(cSeed))).
    oGame:Initialise().
    oScores = NEW RogueScores(NEW MemorySettings()).
    ETIME(TRUE).
    CASE cScenario:
        WHEN "explore" THEN DO i = 1 TO NUM-ENTRIES(cRuns):
            oGame:Command(ENTRY(i, cRuns)).
        END.
        WHEN "pack" THEN oGame:Command("i").
        WHEN "help" THEN oGame:Command("?").
        WHEN "deep" THEN DO:
            oGame:World:NewLevel(20).
            oGame:World:Hero:Hp = 500.
            oGame:World:Hero:MaxHp = 500.
            Sight:Look(oGame:World).
            DO i = 1 TO NUM-ENTRIES(cRuns):
                oGame:Command(ENTRY(i, cRuns)).
            END.
        END.
        WHEN "discoveries" THEN DO:
            oGame:World:Names:Learn(ItemType:Potion, 5).
            oGame:World:Names:Learn(ItemType:Scroll, 0).
            oGame:Command("S-d").
        END.
        WHEN "messages" THEN DO:
            DO i = 1 TO 6:
                oGame:Command(".").
            END.
            oGame:Command("S-m").
        END.
        WHEN "ask" THEN oGame:Command("q").
        WHEN "death" THEN DO:
            oScores:Add(1520, 6, "an orc", FALSE).
            oScores:Add(310, 3, "a bat", FALSE).
            oGame:World:Hero:Gold = 640.
            oGame:Command("S-q").
            oGame:Command("y").
        END.
    END CASE.

    MESSAGE "The scenario took" ETIME "ms (" oGame:Turn "turns)".
    oPainter = NEW RoguePainter(NEW RogueRecordingRenderer(), oGame, oScores).
    ETIME(TRUE).
    DO i = 1 TO 5:
        oPainter:Render(oGame:Grid, oGame).
    END.
    MESSAGE "A render takes" INTEGER(ETIME / 5) "ms".
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
