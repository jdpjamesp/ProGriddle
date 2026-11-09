/* The menu screens of Football Manager, drawn on the chalkboard (the board and its wooden frame are already in the background of the
   canvas): the set up, the manager's office, the squad, the status, the loan and the level, the sale, the pick the team, the results,
   the table, the accounts, the end of the season, the transfer offer and the sack, with the status bar over the top and the key bar
   under. It reads the game and the screen state (FootballUi) and draws on the canvas it is given, with the colours and sprites of the
   design (docs/design/footballmanager-art.md section 6). Text cannot be drawn inside a canvas batch, so these are drawn plainly. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.FootballManager.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.FootballManager.FootballScreens FINAL:

    VAR PRIVATE PixelCanvas mCanvas.
    VAR PRIVATE FootballGame mGame.
    VAR PRIVATE FootballUi mUi.
    VAR PRIVATE INTEGER[128] mPal.

    CONSTRUCTOR PUBLIC FootballScreens(INPUT poCanvas AS PixelCanvas, INPUT poGame AS FootballGame, INPUT poUi AS FootballUi):
        IF NOT VALID-OBJECT(poCanvas) THEN UNDO, THROW NEW GridException("The screens need a canvas").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("The screens need a game").
        IF NOT VALID-OBJECT(poUi) THEN UNDO, THROW NEW GridException("The screens need the screen state").
        mCanvas = poCanvas.
        mGame = poGame.
        mUi = poUi.
    END CONSTRUCTOR.

    /* ================================ drawing helpers ================================ */

    METHOD PRIVATE INTEGER Hue(INPUT poTint AS FootballTint):
        RETURN FootballLook:Colour(poTint).
    END METHOD.

    METHOD PRIVATE VOID Paint(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT piColour AS INTEGER):
        mCanvas:FillRect(piX, piY, piW, piH, 0, piColour).
    END METHOD.

    METHOD PRIVATE VOID Say(INPUT pcText AS CHARACTER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT poTint AS FootballTint):
        mCanvas:DrawText(pcText, piX, piY, Hue(poTint)).
    END METHOD.

    /* Text ending at piRight. */
    METHOD PRIVATE VOID SayRight(INPUT pcText AS CHARACTER, INPUT piRight AS INTEGER, INPUT piY AS INTEGER, INPUT poTint AS FootballTint):
        mCanvas:DrawText(pcText, piRight - PixelCanvas:ScaledWidth(pcText, 1), piY, Hue(poTint)).
    END METHOD.

    /* Text centred on piMid. */
    METHOD PRIVATE VOID SayCentre(INPUT pcText AS CHARACTER, INPUT piMid AS INTEGER, INPUT piY AS INTEGER, INPUT poTint AS FootballTint):
        mCanvas:DrawText(pcText, piMid - INTEGER(TRUNCATE(PixelCanvas:ScaledWidth(pcText, 1) / 2, 0)), piY, Hue(poTint)).
    END METHOD.

    /* An amount ending at piRight, its digits in groups of three with a gap of two pixels, and a sign in front when it is wanted: + in green, - in red. */
    METHOD PRIVATE VOID Amount(INPUT piValue AS INTEGER, INPUT piRight AS INTEGER, INPUT piY AS INTEGER, INPUT plSigned AS LOGICAL, INPUT poPlain AS FootballTint):
        VAR CHARACTER s = STRING(ABSOLUTE(piValue)).
        VAR CHARACTER chunk.
        VAR INTEGER x = piRight.
        VAR FootballTint tint.
        tint = (IF plSigned AND piValue <> 0 THEN (IF piValue < 0 THEN FootballTint:ChalkRed ELSE FootballTint:ChalkGreen) ELSE poPlain).
        DO WHILE LENGTH(s) > 0:
            chunk = SUBSTRING(s, MAXIMUM(1, LENGTH(s) - 2)).
            s = SUBSTRING(s, 1, LENGTH(s) - LENGTH(chunk)).
            x = x - 6 * LENGTH(chunk).
            Say(chunk, x, piY, tint).
            x = x - 2.
        END.
        IF plSigned AND piValue <> 0 THEN Say((IF piValue < 0 THEN "-" ELSE "+"), x - 4, piY, tint).
    END METHOD.

    /* The colours of a sprite's letters (and the tones of a row for the few that have them), then the sprite with its top left on piX, piY. */
    METHOD PRIVATE VOID Glyph(INPUT poSprite AS FootballSprite, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR CHARACTER cells.
        VAR CHARACTER pal.
        VAR CHARACTER one.
        VAR INTEGER w.
        VAR INTEGER h.
        VAR INTEGER cx.
        VAR INTEGER cy.
        VAR INTEGER i.
        VAR INTEGER code.
        VAR INTEGER v.
        VAR INTEGER d.
        VAR FootballRow row.
        pal = FootballArt:Palette(poSprite).
        DO i = 1 TO NUM-ENTRIES(pal, ";"):
            one = ENTRY(i, pal, ";").
            IF one = "" THEN NEXT.
            v = 0.
            DO d = 3 TO 8:
                v = v * 16 + INDEX("0123456789ABCDEF", SUBSTRING(one, d, 1)) - 1.
            END.
            mPal[ASC(SUBSTRING(one, 1, 1)) + 1] = v.
        END.
        CASE poSprite:
            WHEN FootballSprite:MagnetOn THEN row = FootballRow:MagnetRed.
            WHEN FootballSprite:MagnetRes THEN row = FootballRow:MagnetBlue.
            WHEN FootballSprite:ShirtWhite OR WHEN FootballSprite:KitWhite THEN row = FootballRow:White.
            WHEN FootballSprite:ShirtBlack OR WHEN FootballSprite:KitBlack THEN row = FootballRow:Black.
            WHEN FootballSprite:TrophyLeague OR WHEN FootballSprite:CabLeague THEN row = FootballRow:Gold.
            OTHERWISE row = FootballRow:Silver.
        END CASE.
        DO i = 1 TO 5:
            mPal[ASC(STRING(i)) + 1] = FootballLook:Tone(row, i).
        END.
        cells = FootballArt:Cells(poSprite).
        w = FootballArt:Width(poSprite).
        h = FootballArt:Height(poSprite).
        DO cy = 0 TO h - 1:
            DO cx = 0 TO w - 1:
                code = ASC(SUBSTRING(cells, cy * w + cx + 1, 1)).
                IF code <> 46 THEN mCanvas:Plot(piX + cx, piY + cy, 0, mPal[code + 1]).
            END.
        END.
    END METHOD.

    /* The badge of the club in a slot (16 x 16 or the 8 x 8 mini one): by its place in its division, (slot - 1) mod 8. */
    METHOD PRIVATE VOID Badge(INPUT piSlot AS INTEGER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plMini AS LOGICAL):
        VAR INTEGER n = (piSlot - 1) MODULO 8.
        IF plMini THEN
            CASE n:
                WHEN 0 THEN Glyph(FootballSprite:MiniStar, piX, piY).
                WHEN 1 THEN Glyph(FootballSprite:MiniHoops, piX, piY).
                WHEN 2 THEN Glyph(FootballSprite:MiniTower, piX, piY).
                WHEN 3 THEN Glyph(FootballSprite:MiniAnchor, piX, piY).
                WHEN 4 THEN Glyph(FootballSprite:MiniTree, piX, piY).
                WHEN 5 THEN Glyph(FootballSprite:MiniChevron, piX, piY).
                WHEN 6 THEN Glyph(FootballSprite:MiniFish, piX, piY).
                OTHERWISE Glyph(FootballSprite:MiniKettle, piX, piY).
            END CASE.
        ELSE
            CASE n:
                WHEN 0 THEN Glyph(FootballSprite:BadgeStar, piX, piY).
                WHEN 1 THEN Glyph(FootballSprite:BadgeHoops, piX, piY).
                WHEN 2 THEN Glyph(FootballSprite:BadgeTower, piX, piY).
                WHEN 3 THEN Glyph(FootballSprite:BadgeAnchor, piX, piY).
                WHEN 4 THEN Glyph(FootballSprite:BadgeTree, piX, piY).
                WHEN 5 THEN Glyph(FootballSprite:BadgeChevron, piX, piY).
                WHEN 6 THEN Glyph(FootballSprite:BadgeFish, piX, piY).
                OTHERWISE Glyph(FootballSprite:BadgeKettle, piX, piY).
            END CASE.
    END METHOD.

    /* The status bar: the club, the week, the division, the cash and the loan and the morale. */
    METHOD PRIVATE VOID StatusBar():
        VAR FootballWorld w = mGame:World.
        Paint(0, 0, 320, 13, Hue(FootballTint:Tunnel)).
        Paint(0, 13, 320, 1, Hue(FootballTint:TunnelRule)).
        IF mGame:Phase = FootballPhase:Setup THEN RETURN.
        Badge(w:Slot, 3, 3, TRUE).
        Say(CAPS(SUBSTRING(w:ClubName(w:Slot), 1, 12)), 14, 4, FootballTint:ChalkYellow).
        Say("WK " + STRING(mGame:Turn), 94, 4, FootballTint:ChalkBlue).
        Say("DIV " + STRING(w:Division), 128, 4, FootballTint:ChalkBlue).
        Glyph((IF w:Cash < 0 THEN FootballSprite:MoneyOwed ELSE FootballSprite:MoneyCoin), 162, 3).
        Amount(w:Cash, 222, 4, TRUE, FootballTint:Chalk).
        Glyph(FootballSprite:MoneyLoan, 228, 3).
        Amount(w:Loan, 284, 4, FALSE, FootballTint:Chalk).
        Glyph(FootballSprite:Morale, 288, 3).
        SayRight(STRING(w:Morale), 316, 4, FootballTint:ChalkBlue).
    END METHOD.

    /* The title band of a board, with the words at its right. */
    METHOD PRIVATE VOID BoardTitle(INPUT pcTitle AS CHARACTER, INPUT pcRight AS CHARACTER):
        Paint(4, 18, 312, 14, Hue(FootballTint:BoardHead)).
        Paint(4, 32, 312, 1, Hue(FootballTint:BoardRule)).
        Say(pcTitle, 10, 21, FootballTint:ChalkYellow).
        SayRight(pcRight, 310, 21, FootballTint:ChalkDim).
    END METHOD.

    /* The key bar: pairs of a key and its meaning, "ENTER|NEXT,UP DOWN|LEVEL". */
    METHOD PRIVATE VOID KeyBar(INPUT pcKeys AS CHARACTER):
        VAR INTEGER i.
        VAR INTEGER x = 6.
        VAR CHARACTER one.
        Paint(0, 228, 320, 12, Hue(FootballTint:Tunnel)).
        Paint(0, 228, 320, 1, Hue(FootballTint:TunnelRule)).
        DO i = 1 TO NUM-ENTRIES(pcKeys):
            one = ENTRY(i, pcKeys).
            Say(ENTRY(1, one, "|"), x, 231, FootballTint:ChalkYellow).
            x = x + PixelCanvas:ScaledWidth(ENTRY(1, one, "|"), 1) + 4.
            Say(ENTRY(2, one, "|"), x, 231, FootballTint:ChalkDim).
            x = x + PixelCanvas:ScaledWidth(ENTRY(2, one, "|"), 1) + 10.
        END.
    END METHOD.

    /* A line of news near the bottom of the board. */
    METHOD PRIVATE VOID News():
        IF mUi:News <> "" THEN SayCentre(mUi:News, 160, 210, FootballTint:ChalkAmber).
    END METHOD.

    /* Squares for a skill (1 to 5): the first piSkill lit. */
    METHOD PRIVATE VOID Pips(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piLit AS INTEGER, INPUT piCount AS INTEGER, INPUT poLit AS FootballTint):
        VAR INTEGER i.
        DO i = 1 TO piCount:
            Paint(piX + (i - 1) * 5, piY, 3, 3, (IF i <= piLit THEN Hue(poLit) ELSE Hue(FootballTint:BarEmpty))).
        END.
    END METHOD.

    /* A bar of 20 units, piUnit pixels each, piLit of them filled. Green from 13, amber from 7, red below, and the last lit unit in chalk. */
    METHOD PRIVATE VOID Bar(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piLit AS INTEGER, INPUT piUnit AS INTEGER, INPUT piHeight AS INTEGER, INPUT plLevels AS LOGICAL,
                            INPUT poPlain AS FootballTint):
        VAR INTEGER colour.
        Paint(piX, piY, 20 * piUnit, piHeight, Hue(FootballTint:BarEmpty)).
        IF piLit < 1 THEN RETURN.
        IF plLevels THEN colour = (IF piLit >= 13 THEN Hue(FootballTint:ChalkGreen) ELSE IF piLit >= 7 THEN Hue(FootballTint:ChalkAmber) ELSE Hue(FootballTint:ChalkRed)).
        ELSE colour = Hue(poPlain).
        Paint(piX, piY, piLit * piUnit, piHeight, colour).
        Paint(piX + (piLit - 1) * piUnit, piY, piUnit, piHeight, Hue(FootballTint:Chalk)).
    END METHOD.

    METHOD PRIVATE FootballSprite PositionIcon(INPUT piPlayer AS INTEGER):
        CASE FootballNames:PositionOf(piPlayer):
            WHEN FootballPosition:Defender THEN RETURN FootballSprite:PosDf.
            WHEN FootballPosition:Midfielder THEN RETURN FootballSprite:PosMf.
            OTHERWISE RETURN FootballSprite:PosFw.
        END CASE.
    END METHOD.

    /* A line of the squad list at y: the position, the name, skill, energy, state and value. The cursor band and the magnet are the caller's. */
    METHOD PRIVATE VOID PlayerLine(INPUT piPlayer AS INTEGER, INPUT piY AS INTEGER, INPUT piX AS INTEGER):
        VAR FootballWorld w = mGame:World.
        Glyph(PositionIcon(piPlayer), piX, piY).
        Say(CAPS(FootballNames:Player(piPlayer)), piX + 10, piY + 1, (IF w:RoleOf(piPlayer) = SquadRole:Injured THEN FootballTint:ChalkDim ELSE FootballTint:Chalk)).
        Pips(piX + 82, piY + 3, w:SkillOf(piPlayer), 5, FootballTint:ChalkYellow).
        Bar(piX + 112, piY + 1, w:EnergyOf(piPlayer), 2, 5, TRUE, FootballTint:BarPlain).
        IF w:RoleOf(piPlayer) = SquadRole:Injured THEN Glyph(FootballSprite:StateInjured, piX + 156, piY).
        Amount(w:WorthOf(piPlayer), piX + 228, piY + 1, FALSE, FootballTint:Chalk).
    END METHOD.

    /* The text of a level 1 to 7. */
    METHOD PRIVATE VOID LevelRow(INPUT piLevel AS INTEGER, INPUT piY AS INTEGER, INPUT piChosen AS INTEGER, INPUT piBand AS INTEGER):
        IF piBand = piLevel THEN Paint(4, piY - 3, 312, 13, Hue(FootballTint:CursorRow)).
        Say(STRING(piLevel), 20, piY, FootballTint:ChalkDim).
        Say(CAPS(FootballNames:Level(piLevel)), 32, piY, (IF piLevel = piChosen THEN FootballTint:ChalkYellow ELSE FootballTint:Chalk)).
        Pips(120, piY + 2, piLevel, 7, FootballTint:ChalkAmber).
        IF piBand = piLevel THEN Glyph(FootballSprite:Cursor1, 8, piY - 1).
    END METHOD.

    /* ================================ the set up ================================ */

    METHOD PRIVATE VOID ScreenName():
        VAR INTEGER i.
        StatusBar().
        BoardTitle("NEW GAME", "STEP 1 OF 3").
        Say("YOUR NAME", 16, 40, FootballTint:ChalkDim).
        Paint(14, 50, 126, 13, Hue(FootballTint:BoardHead)).
        Paint(14, 62, 126, 1, Hue(FootballTint:ChalkDim)).
        Say(CAPS(mUi:ManagerName), 17, 53, FootballTint:Chalk).
        Paint(17 + PixelCanvas:ScaledWidth(mUi:ManagerName, 1), 53, 5, 7, Hue(FootballTint:ChalkYellow)).
        Say("SKILL LEVEL", 16, 76, FootballTint:ChalkDim).
        DO i = 1 TO 7:
            LevelRow(i, 88 + 13 * (i - 1), mUi:Level, mUi:Level).
        END.
        Paint(222, 46, 30, 30, FootballLook:Tone(FootballRow:Wood, 3)).
        Glyph(FootballSprite:Face8, 225, 49).
        SayCentre("THE MANAGER", 237, 82, FootballTint:ChalkDim).
        News().
        KeyBar("ENTER|NEXT,UP DOWN|LEVEL").
    END METHOD.

    METHOD PRIVATE VOID ScreenClub():
        VAR INTEGER i.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER slot.
        StatusBar().
        BoardTitle("PICK A CLUB", "DIVISION " + STRING(mUi:ClubDivision) + " PAGE " + STRING(mUi:ClubDivision) + " OF 4").
        DO i = 0 TO 15:
            x = 14 + 152 * INTEGER(TRUNCATE(i / 8, 0)).
            y = 38 + 23 * (i MODULO 8).
            slot = (mUi:ClubDivision - 1) * 16 + i + 1.
            IF i = mUi:ClubCursor THEN Paint(x - 4, y - 2, 148, 20, Hue(FootballTint:CursorRow)).
            Badge(slot, x, y, FALSE).
            Say(CAPS(FootballNames:Club(slot)), x + 22, y + 5, (IF i = mUi:ClubCursor THEN FootballTint:ChalkYellow ELSE FootballTint:Chalk)).
        END.
        KeyBar("ARROWS|MOVE,ENTER|PICK,PAGE|DIVISION,ESC|BACK").
    END METHOD.

    METHOD PRIVATE VOID ScreenKit():
        StatusBar().
        BoardTitle("YOUR COLOURS", "STEP 3 OF 3").
        SayCentre("YOU PLAY IN", 160, 42, FootballTint:ChalkDim).
        Paint(52, 60, 88, 104, (IF mUi:Kit = 7 THEN Hue(FootballTint:CursorRow) ELSE Hue(FootballTint:BoardStripe))).
        Paint(180, 60, 88, 104, (IF mUi:Kit = 0 THEN Hue(FootballTint:CursorRow) ELSE Hue(FootballTint:BoardStripe))).
        Glyph(FootballSprite:ShirtWhite, 84, 70).
        Glyph(FootballSprite:ShirtBlack, 212, 70).
        SayCentre("WHITE", 96, 124, (IF mUi:Kit = 7 THEN FootballTint:ChalkYellow ELSE FootballTint:Chalk)).
        SayCentre("A BLACK HOOP", 96, 146, FootballTint:ChalkDim).
        SayCentre("BLACK", 224, 124, (IF mUi:Kit = 0 THEN FootballTint:ChalkYellow ELSE FootballTint:Chalk)).
        SayCentre("PINSTRIPES", 224, 146, FootballTint:ChalkDim).
        Glyph(FootballSprite:Cursor1, (IF mUi:Kit = 7 THEN 40 ELSE 268), 108).
        SayCentre("THE OTHER SIDE WEARS " + (IF mUi:Kit = 7 THEN "BLACK" ELSE "WHITE"), 160, 182, FootballTint:Chalk).
        KeyBar("LEFT RIGHT|CHOOSE,ENTER|START,ESC|BACK").
    END METHOD.

    /* ================================ the office ================================ */

    /* The words about the next match: what it is, and who and where. */
    METHOD PRIVATE CHARACTER NextMatch(INPUT piLine AS INTEGER):
        VAR FootballWorld w = mGame:World.
        VAR INTEGER slot.
        IF NOT w:CupOver AND w:Cycle = 2 THEN RETURN (IF piLine = 1 THEN "F.A. CUP ROUND " + STRING(w:CupRound + 1) ELSE "DRAWN WHEN YOU PLAY").
        slot = w:DivisionBase + w:LeagueMatch + 1.
        IF slot = w:Slot THEN slot = w:DivisionBase + 16.
        IF w:LeagueMatch >= 15 THEN RETURN (IF piLine = 1 THEN "THE CUP" ELSE "TO FINISH").
        IF piLine = 1 THEN RETURN "LEAGUE MATCH " + STRING(w:LeagueMatch + 1).
        RETURN "V " + CAPS(w:ClubName(MINIMUM(64, slot))) + (IF w:NextHome = 2 THEN " HOME" ELSE " AWAY").
    END METHOD.

    METHOD PRIVATE VOID ScreenMain():
        VAR INTEGER i.
        VAR FootballWorld w = mGame:World.
        StatusBar().
        BoardTitle("MANAGER OFFICE", "SEASON " + STRING(w:Seasons + 1)).
        DO i = 0 TO 5:
            IF i = mUi:MenuCursor THEN Paint(4, 42 + 18 * i, 160, 16, Hue(FootballTint:CursorRow)).
            Say(ENTRY(i + 1, "C,A,L,P,S,V"), 12, 46 + 18 * i, FootballTint:ChalkYellow).
            Say(ENTRY(i + 1, "CONTINUE,SQUAD AND SALES,TAKE A LOAN,PAY BACK A LOAN,STATUS,SKILL LEVEL"), 26, 46 + 18 * i, FootballTint:Chalk).
        END.
        Say("NEXT", 180, 44, FootballTint:ChalkDim).
        Say(NextMatch(1), 180, 56, FootballTint:Chalk).
        Say(NextMatch(2), 180, 68, FootballTint:Chalk).
        Say("MANAGER", 180, 82, FootballTint:ChalkDim).
        Say(CAPS(w:ManagerName), 180, 94, FootballTint:ChalkYellow).
        Say("LEVEL " + CAPS(FootballNames:Level(w:Level)), 180, 110, FootballTint:Chalk).
        Say("RATING " + STRING(w:ManagerRating), 180, 122, FootballTint:Chalk).
        Say("MORALE", 180, 142, FootballTint:ChalkDim).
        Bar(180, 154, w:Morale, 5, 5, TRUE, FootballTint:BarPlain).
        News().
        KeyBar("UP DOWN|CHOOSE,ENTER|OK").
    END METHOD.

    METHOD PRIVATE VOID ScreenSquad():
        VAR INTEGER p.
        VAR INTEGER listRow.
        VAR FootballWorld w = mGame:World.
        StatusBar().
        BoardTitle("YOUR SQUAD", STRING(w:OwnedCount()) + " PLAYERS").
        Say("NAME", 36, 36, FootballTint:ChalkDim).
        Say("SKILL", 92, 36, FootballTint:ChalkDim).
        Say("ENERGY", 128, 36, FootballTint:ChalkDim).
        Say("VALUE", 218, 36, FootballTint:ChalkDim).
        listRow = 0.
        DO p = 1 TO 24:
            IF w:RoleOf(p) = SquadRole:NotOwned THEN NEXT.
            IF p = mUi:PlayerCursor THEN Paint(4, 46 + 11 * listRow - 1, 312, 11, Hue(FootballTint:CursorRow)).
            IF p = mUi:PlayerCursor THEN Glyph(FootballSprite:Cursor1, 6, 46 + 11 * listRow).
            PlayerLine(p, 46 + 11 * listRow, 16).
            listRow = listRow + 1.
        END.
        News().
        KeyBar("UP DOWN|CHOOSE,ENTER|SELL,ESC|BACK").
    END METHOD.

    METHOD PRIVATE VOID ScreenStatus():
        VAR FootballWorld w = mGame:World.
        VAR INTEGER place.
        StatusBar().
        BoardTitle("STATUS", "").
        Say("CLUB", 16, 44, FootballTint:ChalkDim).
        Say(CAPS(w:ClubName(w:Slot)), 100, 44, FootballTint:ChalkYellow).
        Say("MANAGER", 16, 58, FootballTint:ChalkDim).
        Say(CAPS(w:ManagerName), 100, 58, FootballTint:Chalk).
        Say("COLOURS", 16, 72, FootballTint:ChalkDim).
        Say((IF w:KitColour = 7 THEN "WHITE" ELSE "BLACK"), 100, 72, FootballTint:Chalk).
        Say("LEVEL", 16, 86, FootballTint:ChalkDim).
        Say(STRING(w:Level) + " " + CAPS(FootballNames:Level(w:Level)), 100, 86, FootballTint:Chalk).
        Say("SEASONS", 16, 100, FootballTint:ChalkDim).
        Say(STRING(w:Seasons), 100, 100, FootballTint:Chalk).
        Say("MORALE", 16, 114, FootballTint:ChalkDim).
        Say(STRING(w:Morale), 100, 114, FootballTint:ChalkBlue).
        Say("DIVISION", 16, 128, FootballTint:ChalkDim).
        Say(STRING(w:Division), 100, 128, FootballTint:Chalk).
        place = w:PlaceOf(w:Slot - w:DivisionBase).
        Say("LEAGUE POSITION", 16, 142, FootballTint:ChalkDim).
        Say((IF place = 0 THEN "NONE YET" ELSE STRING(place)), 100, 142, FootballTint:Chalk).
        Say("LEAGUE MATCH", 16, 156, FootballTint:ChalkDim).
        Say(STRING(w:LeagueMatch), 100, 156, FootballTint:Chalk).
        KeyBar("ANY KEY|BACK").
    END METHOD.

    METHOD PRIVATE VOID ScreenMoney():
        VAR FootballWorld w = mGame:World.
        VAR LOGICAL loan = mUi:Mode = FootballMode:Loan.
        StatusBar().
        BoardTitle((IF loan THEN "TAKE A LOAN" ELSE "PAY BACK A LOAN"), "").
        Glyph(FootballSprite:MoneyCoin, 16, 44).
        Say("CASH", 30, 44, FootballTint:ChalkDim).
        Amount(w:Cash, 200, 44, TRUE, FootballTint:Chalk).
        Glyph(FootballSprite:MoneyLoan, 16, 58).
        Say("LOAN", 30, 58, FootballTint:ChalkDim).
        Amount(w:Loan, 200, 58, FALSE, FootballTint:Chalk).
        Glyph(FootballSprite:MoneyBank, 16, 72).
        Say("THE LIMIT", 30, 72, FootballTint:ChalkDim).
        Amount(Bank:LoanLimit(w), 200, 72, FALSE, FootballTint:Chalk).
        Paint(16, 88, 124, 6, Hue(FootballTint:BarEmpty)).
        Paint(16, 88, MINIMUM(124, INTEGER(TRUNCATE(124 * w:Loan / Bank:LoanLimit(w), 0))), 6, Hue(FootballTint:BarPlain)).
        Say(IF loan THEN "HOW MUCH WOULD YOU LIKE" ELSE "HOW MUCH WILL YOU PAY BACK", 16, 110, FootballTint:Chalk).
        Paint(14, 122, 126, 13, Hue(FootballTint:BoardHead)).
        Paint(14, 134, 126, 1, Hue(FootballTint:ChalkDim)).
        Say(mUi:Digits, 17, 125, FootballTint:ChalkYellow).
        Paint(17 + PixelCanvas:ScaledWidth(mUi:Digits, 1), 125, 5, 7, Hue(FootballTint:ChalkYellow)).
        News().
        KeyBar("DIGITS|AMOUNT,ENTER|OK,ESC|BACK").
    END METHOD.

    METHOD PRIVATE VOID ScreenLevels():
        VAR INTEGER i.
        StatusBar().
        BoardTitle("SKILL LEVEL", "").
        DO i = 1 TO 7:
            LevelRow(i, 50 + 13 * (i - 1), mGame:World:Level, mUi:LevelCursor).
        END.
        KeyBar("UP DOWN|CHOOSE,ENTER|SET,ESC|BACK").
    END METHOD.

    METHOD PRIVATE VOID ScreenSelling():
        VAR FootballWorld w = mGame:World.
        StatusBar().
        BoardTitle("AN OFFER", "").
        Badge(mGame:SaleBuyer, 16, 44, FALSE).
        Say(CAPS(FootballNames:Club(mGame:SaleBuyer)) + " HAVE OFFERED", 40, 44, FootballTint:Chalk).
        Amount(mGame:SaleAmount, 160, 58, FALSE, FootballTint:ChalkGreen).
        Say("FOR " + CAPS(FootballNames:Player(mGame:OfferedPlayer)), 40, 72, FootballTint:ChalkYellow).
        Say("HE IS WORTH", 40, 90, FootballTint:ChalkDim).
        Amount(w:WorthOf(mGame:OfferedPlayer), 160, 90, FALSE, FootballTint:Chalk).
        SayCentre("DO YOU ACCEPT", 160, 130, FootballTint:Chalk).
        SayCentre("IF YOU REFUSE HE MAY BE UPSET", 160, 146, FootballTint:ChalkDim).
        KeyBar("Y|SELL HIM,N|KEEP HIM").
    END METHOD.

    /* ================================ the match week ================================ */

    METHOD PRIVATE VOID ScreenPick():
        VAR INTEGER p.
        VAR INTEGER listRow.
        VAR INTEGER i.
        VAR FootballWorld w = mGame:World.
        VAR Fixture f = mGame:ThisFixture.
        StatusBar().
        BoardTitle("PICK THE TEAM", "PICKED " + STRING(w:StarterCount()) + " OF 11").
        Say("V " + CAPS(w:ClubName(f:OpponentSlot)) + (IF f:ManagerIsHome THEN " HOME" ELSE " AWAY"), 10, 36, FootballTint:ChalkBlue).
        listRow = 0.
        DO p = 1 TO 24:
            IF w:RoleOf(p) = SquadRole:NotOwned THEN NEXT.
            IF p = mUi:PlayerCursor THEN Paint(4, 48 + 11 * listRow - 1, 190, 11, Hue(FootballTint:CursorRow)).
            IF w:RoleOf(p) = SquadRole:Starter THEN Glyph(FootballSprite:MagnetOn, 8, 48 + 11 * listRow).
            Glyph(PositionIcon(p), 18, 48 + 11 * listRow).
            Say(CAPS(FootballNames:Player(p)), 28, 49 + 11 * listRow, (IF w:RoleOf(p) = SquadRole:Starter THEN FootballTint:ChalkYellow ELSE IF w:RoleOf(p) = SquadRole:Injured THEN FootballTint:ChalkDim ELSE FootballTint:Chalk)).
            Pips(92, 51 + 11 * listRow, w:SkillOf(p), 5, FootballTint:ChalkYellow).
            Bar(122, 49 + 11 * listRow, w:EnergyOf(p), 3, 5, TRUE, FootballTint:BarPlain).
            IF w:RoleOf(p) = SquadRole:Injured THEN Glyph(FootballSprite:StateInjured, 184, 48 + 11 * listRow).
            listRow = listRow + 1.
        END.
        Say("YOU", 208, 44, FootballTint:ChalkYellow).
        Say("THEM", 262, 44, FootballTint:ChalkBlue).
        DO i = 1 TO 5:
            Say(CAPS(TeamStrength:AttributeName(i)), 198, 56 + 24 * (i - 1), FootballTint:ChalkDim).
            Bar(198, 66 + 24 * (i - 1), TeamStrength:Value(w, i), 5, 4, FALSE, FootballTint:ChalkYellow).
            Bar(198, 71 + 24 * (i - 1), f:OppositionNumber(i), 5, 4, FALSE, FootballTint:ChalkBlue).
            SayRight(STRING(TeamStrength:Value(w, i)), 306, 56 + 24 * (i - 1), (IF TeamStrength:Value(w, i) >= f:OppositionNumber(i) THEN FootballTint:ChalkGreen ELSE FootballTint:ChalkRed)).
        END.
        News().
        KeyBar("UP DOWN|CHOOSE,SPACE|PICK,K|KICK OFF").
    END METHOD.

    /* The plate over the last picture of the match: the score and who won. */
    METHOD PUBLIC VOID FullTimePlate():
        VAR INTEGER mine.
        VAR INTEGER theirs.
        VAR INTEGER homeGoals.
        VAR INTEGER awayGoals.
        VAR FootballTint tint.
        VAR CHARACTER words.
        homeGoals = mGame:Played:GoalsOf(1).
        awayGoals = mGame:Played:GoalsOf(2).
        mine = MatchDay:ManagerGoals(mGame:ThisFixture, mGame:Played).
        theirs = MatchDay:OpponentGoals(mGame:ThisFixture, mGame:Played).
        IF mine > theirs THEN
        DO:
            words = "WON".
            tint = FootballTint:ChalkGreen.
        END.
        ELSE IF mine < theirs THEN
        DO:
            words = "LOST".
            tint = FootballTint:ChalkRed.
        END.
        ELSE
        DO:
            words = "DRAWN".
            tint = FootballTint:Chalk.
        END.
        Paint(64, 50, 192, 120, Hue(FootballTint:Outline)).
        Paint(65, 51, 190, 118, Hue(FootballTint:Tunnel)).
        Paint(67, 53, 186, 1, Hue(tint)).
        Paint(67, 166, 186, 1, Hue(tint)).
        SayCentre("FULL TIME", 160, 57, FootballTint:ChalkYellow).
        mCanvas:DrawTextScaled(STRING(homeGoals), 150 - PixelCanvas:ScaledWidth(STRING(homeGoals), 3), 70, Hue(FootballTint:ChalkYellow), Hue(FootballTint:ChalkYellow), 3).
        mCanvas:DrawTextScaled("-", 153, 70, Hue(FootballTint:ChalkDim), Hue(FootballTint:ChalkDim), 3).
        mCanvas:DrawTextScaled(STRING(awayGoals), 170, 70, Hue(FootballTint:ChalkYellow), Hue(FootballTint:ChalkYellow), 3).
        SayCentre(words, 160, 96, tint).
        SayCentre("ATTACKS " + STRING(mGame:Played:AttackCount), 160, 118, FootballTint:ChalkDim).
        IF mGame:ThisFixture:Kind = FixtureKind:Cup AND mine = theirs THEN SayCentre("LEVEL: A REPLAY", 160, 134, FootballTint:ChalkAmber).
        SayCentre("PRESS SPACE", 160, 150, FootballTint:ChalkYellow).
    END METHOD.

    /* The club of a team of the division. */
    METHOD PRIVATE CHARACTER TeamName(INPUT piTeam AS INTEGER):
        RETURN CAPS(mGame:World:ClubName(mGame:World:DivisionBase + piTeam)).
    END METHOD.

    METHOD PRIVATE VOID ScreenResults():
        VAR INTEGER i.
        VAR FootballWorld w = mGame:World.
        VAR Fixture f = mGame:ThisFixture.
        VAR CHARACTER homeName.
        VAR CHARACTER awayName.
        StatusBar().
        BoardTitle("RESULTS", "DIVISION " + STRING(w:Division) + " MATCH " + STRING(w:LeagueMatch)).
        IF f:ManagerIsHome THEN
        DO:
            homeName = CAPS(w:ClubName(w:Slot)).
            awayName = CAPS(w:ClubName(f:OpponentSlot)).
        END.
        ELSE
        DO:
            homeName = CAPS(w:ClubName(f:OpponentSlot)).
            awayName = CAPS(w:ClubName(w:Slot)).
        END.
        Paint(4, 38, 312, 12, Hue(FootballTint:YourRow)).
        Say(homeName, 14, 40, FootballTint:ChalkYellow).
        SayCentre(STRING(mGame:Played:GoalsOf(1)) + " - " + STRING(mGame:Played:GoalsOf(2)), 160, 40, FootballTint:ChalkYellow).
        Say(awayName, 190, 40, FootballTint:ChalkYellow).
        DO i = 1 TO mGame:OtherResults:Count:
            Say(TeamName(mGame:OtherResults:TeamA(i)), 14, 58 + 14 * (i - 1), FootballTint:Chalk).
            SayCentre(STRING(mGame:OtherResults:GoalsA(i)) + " - " + STRING(mGame:OtherResults:GoalsB(i)), 160, 58 + 14 * (i - 1), FootballTint:Chalk).
            Say(TeamName(mGame:OtherResults:TeamB(i)), 190, 58 + 14 * (i - 1), FootballTint:Chalk).
        END.
        KeyBar("SPACE|THE TABLE").
    END METHOD.

    METHOD PRIVATE VOID ScreenTable():
        VAR INTEGER i.
        VAR INTEGER t.
        VAR FootballWorld w = mGame:World.
        VAR INTEGER myTeam = w:Slot - w:DivisionBase.
        StatusBar().
        BoardTitle("DIVISION " + STRING(w:Division), "MATCH " + STRING(w:LeagueMatch)).
        Say("TEAM", 34, 36, FootballTint:ChalkDim).
        SayRight("F", 210, 36, FootballTint:ChalkDim).
        SayRight("A", 240, 36, FootballTint:ChalkDim).
        SayRight("PTS", 290, 36, FootballTint:ChalkDim).
        DO i = 1 TO 16:
            t = w:TeamAt(i).
            IF t = myTeam THEN Paint(4, 44 + 11 * (i - 1) - 1, 312, 11, Hue(FootballTint:YourRow)).
            ELSE IF i MODULO 2 = 0 THEN Paint(4, 44 + 11 * (i - 1) - 1, 312, 11, Hue(FootballTint:BoardStripe)).
            IF w:Division > 1 AND i <= 3 THEN Glyph(FootballSprite:MarkUp, 6, 44 + 11 * (i - 1)).
            IF w:Division < 4 AND i >= 14 THEN Glyph(FootballSprite:MarkDown, 6, 44 + 11 * (i - 1)).
            SayRight(STRING(i), 30, 44 + 11 * (i - 1) + 1, FootballTint:ChalkDim).
            Badge(w:DivisionBase + t, 36, 44 + 11 * (i - 1), TRUE).
            Say(TeamName(t), 48, 44 + 11 * (i - 1) + 1, (IF t = myTeam THEN FootballTint:ChalkYellow ELSE FootballTint:Chalk)).
            SayRight(STRING(w:GoalsForOf(t)), 210, 44 + 11 * (i - 1) + 1, FootballTint:Chalk).
            SayRight(STRING(w:GoalsAgainstOf(t)), 240, 44 + 11 * (i - 1) + 1, FootballTint:Chalk).
            SayRight(STRING(w:PointsOf(t)), 290, 44 + 11 * (i - 1) + 1, (IF t = myTeam THEN FootballTint:ChalkYellow ELSE FootballTint:Chalk)).
        END.
        KeyBar("SPACE|ON").
    END METHOD.

    METHOD PRIVATE VOID ScreenAccounts():
        VAR FootballWorld w = mGame:World.
        StatusBar().
        BoardTitle("THE ACCOUNTS", "WEEK " + STRING(mGame:Turn)).
        Glyph(FootballSprite:MoneyCoin, 16, 44).
        Say("GATE MONEY", 30, 44, FootballTint:Chalk).
        Amount(mGame:ThisFixture:Gate, 250, 44, TRUE, FootballTint:Chalk).
        Glyph(FootballSprite:MoneyWages, 16, 62).
        Say("WAGE BILL", 30, 62, FootballTint:Chalk).
        Amount(- mGame:WageBill, 250, 62, TRUE, FootballTint:Chalk).
        Glyph(FootballSprite:MoneyGround, 16, 76).
        Say("GROUND RENT", 30, 76, FootballTint:Chalk).
        Amount(- mGame:RentBill, 250, 76, TRUE, FootballTint:Chalk).
        Glyph(FootballSprite:MoneyLoan, 16, 90).
        Say("LOAN INTEREST", 30, 90, FootballTint:Chalk).
        Amount(- mGame:InterestBill, 250, 90, TRUE, FootballTint:Chalk).
        Paint(16, 106, 234, 1, Hue(FootballTint:BoardRule)).
        Say("WEEKLY BALANCE", 30, 112, FootballTint:ChalkYellow).
        Amount(mGame:Balance, 250, 112, TRUE, FootballTint:Chalk).
        Say("YOU HAVE", 30, 140, FootballTint:ChalkDim).
        Amount(w:Cash, 250, 140, TRUE, FootballTint:Chalk).
        Say("YOU OWE", 30, 154, FootballTint:ChalkDim).
        Amount(w:Loan, 250, 154, FALSE, FootballTint:Chalk).
        KeyBar("SPACE|ON").
    END METHOD.

    METHOD PRIVATE VOID ScreenSeasonEnd():
        VAR FootballWorld w = mGame:World.
        StatusBar().
        BoardTitle("THE SEASON IS OVER", "").
        Say("YOU FINISHED", 30, 50, FootballTint:ChalkDim).
        Say(STRING(mGame:FinalPlace) + (IF mGame:FinalPlace = 1 THEN "ST" ELSE IF mGame:FinalPlace = 2 THEN "ND" ELSE IF mGame:FinalPlace = 3 THEN "RD" ELSE "TH"), 130, 50, FootballTint:ChalkYellow).
        Say("PRIZE MONEY", 30, 66, FootballTint:ChalkDim).
        Amount(mGame:SeasonPrize, 250, 66, TRUE, FootballTint:Chalk).
        CASE mGame:SeasonResult:
            WHEN SeasonMove:Promoted THEN
            DO:
                Glyph(FootballSprite:MarkUp, 30, 92).
                Say("YOU ARE PROMOTED TO DIVISION " + STRING(w:Division), 44, 92, FootballTint:ChalkGreen).
            END.
            WHEN SeasonMove:Relegated THEN
            DO:
                Glyph(FootballSprite:MarkDown, 30, 92).
                Say("YOU ARE RELEGATED TO DIVISION " + STRING(w:Division), 44, 92, FootballTint:ChalkRed).
            END.
            WHEN SeasonMove:Champions THEN
            DO:
                Glyph(FootballSprite:TrophyLeague, 30, 84).
                Say("YOU ARE LEAGUE CHAMPIONS", 70, 92, FootballTint:ChalkYellow).
            END.
            OTHERWISE Say("YOU STAY IN DIVISION " + STRING(w:Division), 30, 92, FootballTint:Chalk).
        END CASE.
        Say("MANAGER RATING", 30, 120, FootballTint:ChalkDim).
        Say(STRING(w:ManagerRating), 150, 120, FootballTint:Chalk).
        KeyBar("SPACE|NEXT SEASON").
    END METHOD.

    METHOD PRIVATE VOID ScreenTransfer():
        VAR FootballWorld w = mGame:World.
        VAR INTEGER p = mGame:OfferedPlayer.
        StatusBar().
        BoardTitle("TRANSFER MARKET", "").
        IF mGame:TransferBlocked THEN
        DO:
            SayCentre("YOU CANNOT BUY A PLAYER", 160, 70, FootballTint:ChalkRed).
            SayCentre("YOUR SQUAD HAS 16 PLAYERS: THE MOST ALLOWED", 160, 86, FootballTint:ChalkDim).
            KeyBar("SPACE|ON").
            RETURN.
        END.
        Glyph(PositionIcon(p), 16, 44).
        Say(CAPS(FootballNames:Player(p)), 30, 44, FootballTint:ChalkYellow).
        Say("SKILL", 16, 62, FootballTint:ChalkDim).
        Pips(70, 63, w:SkillOf(p), 5, FootballTint:ChalkYellow).
        Say("ENERGY", 16, 76, FootballTint:ChalkDim).
        Bar(70, 76, w:EnergyOf(p), 3, 5, TRUE, FootballTint:BarPlain).
        Say("HE IS WORTH", 16, 92, FootballTint:ChalkDim).
        Amount(w:WorthOf(p), 200, 92, FALSE, FootballTint:Chalk).
        Say("YOU HAVE", 16, 106, FootballTint:ChalkDim).
        Amount(w:Cash, 200, 106, TRUE, FootballTint:Chalk).
        Say("WHAT WILL YOU BID", 16, 128, FootballTint:Chalk).
        Paint(14, 140, 126, 13, Hue(FootballTint:BoardHead)).
        Paint(14, 152, 126, 1, Hue(FootballTint:ChalkDim)).
        Say(mUi:Digits, 17, 143, FootballTint:ChalkYellow).
        Paint(17 + PixelCanvas:ScaledWidth(mUi:Digits, 1), 143, 5, 7, Hue(FootballTint:ChalkYellow)).
        News().
        KeyBar("DIGITS|BID,ENTER|OK,P|NO THANKS").
    END METHOD.

    METHOD PRIVATE VOID ScreenSacked():
        StatusBar().
        BoardTitle("SACKED", "").
        Paint(40, 70, 240, 90, Hue(FootballTint:Outline)).
        Paint(41, 71, 238, 88, Hue(FootballTint:Tunnel)).
        Paint(43, 73, 234, 1, Hue(FootballTint:ChalkRed)).
        Paint(43, 156, 234, 1, Hue(FootballTint:ChalkRed)).
        SayCentre("YOU HAVE BEEN SACKED", 160, 90, FootballTint:ChalkRed).
        SayCentre("YOUR LOAN IS OVER THE LIMIT", 160, 108, FootballTint:Chalk).
        SayCentre("THE BANK HAS LOST PATIENCE", 160, 120, FootballTint:ChalkDim).
        SayCentre("PRESS ENTER TO TRY AGAIN", 160, 142, FootballTint:ChalkYellow).
        KeyBar("ENTER|NEW GAME").
    END METHOD.

    /* Draws the screen the manager is looking at (everything but the match itself and the full time plate). */
    METHOD PUBLIC VOID Draw():
        CASE mUi:Mode:
            WHEN FootballMode:Name THEN ScreenName().
            WHEN FootballMode:Club THEN ScreenClub().
            WHEN FootballMode:Kit THEN ScreenKit().
            WHEN FootballMode:Main THEN ScreenMain().
            WHEN FootballMode:Squad THEN ScreenSquad().
            WHEN FootballMode:Status THEN ScreenStatus().
            WHEN FootballMode:Loan OR WHEN FootballMode:Repay THEN ScreenMoney().
            WHEN FootballMode:Levels THEN ScreenLevels().
            WHEN FootballMode:Selling THEN ScreenSelling().
            WHEN FootballMode:PickTeam THEN ScreenPick().
            WHEN FootballMode:Results THEN ScreenResults().
            WHEN FootballMode:Table THEN ScreenTable().
            WHEN FootballMode:Accounts THEN ScreenAccounts().
            WHEN FootballMode:SeasonEnd THEN ScreenSeasonEnd().
            WHEN FootballMode:Transfer THEN ScreenTransfer().
            WHEN FootballMode:Sacked THEN ScreenSacked().
            OTHERWISE RETURN.
        END CASE.
    END METHOD.

END CLASS.
