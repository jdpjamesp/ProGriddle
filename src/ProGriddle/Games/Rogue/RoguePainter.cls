/* Draws Rogue as the original is drawn, on a screen of 80 x 24 characters of 8 x 14 pixels (640 x 336 pixels on a pixel canvas of its own):
   the message line on the top row, the map of 80 x 21 below it, and the two status lines at the bottom. It reads a RogueGame, never
   changes it, and hands the canvas to the window's renderer.

   The map shows what the hero sees now at full brightness and what the hero remembers at half. Walls, corners and the floor dot are the
   extra glyphs of AsciiFont (so the walls join up), doors are +, passages #, the stairs %, traps that have been found ^, and things lie as
   the original draws them: gold *, food :, weapons ), armour ], potions !, scrolls ?, wands /, rings =, the amulet comma. Things and
   monsters are drawn only where the hero can see them (or has sensed them by a potion or a scroll), and a monster is coloured by how
   dangerous it is. A hallucinating hero sees the wrong letters and signs. The hero is @.

   Over the map come the screens: the pack (also shown by itself while the game asks which thing), the help, the past messages, what has
   been discovered, and, at the end of a game, the tombstone with the list of the ten best games. Anything that moves is a function of the
   game's own counts, so the painter keeps no clock and the same game always looks the same.

   The painter owns a canvas and the stamps of an AsciiPen: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Rogue.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Rogue.RoguePainter FINAL IMPLEMENTS IGridRenderer:

    DEFINE PRIVATE VARIABLE mInner    AS IGridRenderer NO-UNDO.
    DEFINE PRIVATE VARIABLE mGame     AS RogueGame     NO-UNDO.
    DEFINE PRIVATE VARIABLE mScores   AS RogueScores   NO-UNDO.
    DEFINE PRIVATE VARIABLE mGrid     AS Grid          NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas   AS PixelCanvas   NO-UNDO.
    DEFINE PRIVATE VARIABLE mPen      AS AsciiPen      NO-UNDO.
    DEFINE PRIVATE VARIABLE mDisposed AS LOGICAL       NO-UNDO.

    /* The canvas the picture is drawn on, and its grid (what the window's renderer is given). */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    DEFINE PUBLIC PROPERTY CanvasGrid AS Grid NO-UNDO
        GET():
            RETURN mGrid.
        END GET.

    /* Throws GridException for no renderer, no game or no scores. */
    CONSTRUCTOR PUBLIC RoguePainter(INPUT poInner AS IGridRenderer, INPUT poGame AS RogueGame, INPUT poScores AS RogueScores):
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Rogue painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Rogue painter needs a game").
        IF NOT VALID-OBJECT(poScores) THEN UNDO, THROW NEW GridException("A Rogue painter needs the list of scores").
        mInner = poInner.
        mGame = poGame.
        mScores = poScores.
        mGrid = NEW Grid(NEW ArrayStore(RogueRules:ScreenColumns() * AsciiFont:GlyphWidth(), RogueRules:ScreenRows() * AsciiFont:GlyphHeight(), "view,kind,back")).
        mGrid:Store:FillLayer(mGrid:Store:LayerIndex("back"), RogueLook:Colour(RogueTint:Background)).
        mCanvas = NEW PixelCanvas(mGrid).
        mPen = NEW AsciiPen().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC RoguePainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the canvas to the window's renderer. Throws GridException for a game that is not Rogue. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, RogueGame) THEN UNDO, THROW NEW GridException("A Rogue painter draws a Rogue game").
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DrawMap().
        DrawStatus().
        CASE mGame:Mode:
            WHEN RogueMode:PickItem THEN DrawPack(TRUE).
            WHEN RogueMode:Overlay THEN DrawOverlay().
            WHEN RogueMode:Over THEN DrawTombstone().
        END CASE.
        DrawMessageLine().
        mCanvas:EndBatch().
        mInner:Render(mGrid, poGame).
    END METHOD.

    /* Frees the canvas and the stamps. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        IF VALID-OBJECT(mPen) THEN mPen:Dispose().
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
    END METHOD.

    /* ================================== text and glyphs ================================== */

    /* A glyph in the character cell (piCol, piRow) of the screen. */
    METHOD PRIVATE VOID Stamp(INPUT piCode AS INTEGER, INPUT piColour AS INTEGER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        mPen:Glyph(mCanvas, piCode, piColour, piCol * AsciiFont:GlyphWidth(), piRow * AsciiFont:GlyphHeight()).
    END METHOD.

    /* Text starting in the character cell (piCol, piRow). Gives the column after it. */
    METHOD PRIVATE INTEGER Say(INPUT pcText AS CHARACTER, INPUT piColour AS INTEGER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        mPen:Text(mCanvas, pcText, piColour, piCol * AsciiFont:GlyphWidth(), piRow * AsciiFont:GlyphHeight()).
        RETURN piCol + LENGTH(pcText).
    END METHOD.

    /* Fills a block of character cells with a colour. */
    METHOD PRIVATE VOID Block(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT piCols AS INTEGER, INPUT piRows AS INTEGER, INPUT piColour AS INTEGER):
        mCanvas:FillRect(piCol * AsciiFont:GlyphWidth(), piRow * AsciiFont:GlyphHeight(), piCols * AsciiFont:GlyphWidth(), piRows * AsciiFont:GlyphHeight(), 0, piColour).
    END METHOD.

    /* ================================== the map ================================== */

    METHOD PRIVATE VOID DrawMap():
        DEFINE VARIABLE x        AS INTEGER NO-UNDO.
        DEFINE VARIABLE y        AS INTEGER NO-UNDO.
        DEFINE VARIABLE i        AS INTEGER NO-UNDO.
        DEFINE VARIABLE oMonster AS Monster NO-UNDO.
        DEFINE VARIABLE oWorld   AS RogueWorld NO-UNDO.
        oWorld = mGame:World.
        DO y = 0 TO RogueRules:MapHeight() - 1:
            DO x = 0 TO RogueRules:MapWidth() - 1:
                IF oWorld:Cave:InView(x, y) OR oWorld:Cave:IsSeen(x, y) THEN DrawTerrain(x, y, oWorld:Cave:InView(x, y)).
            END.
        END.
        DrawThings().
        DO i = 0 TO RogueRules:MostMonsters() - 1:
            oMonster = oWorld:MonsterInSlot(i).
            IF VALID-OBJECT(oMonster) AND (Sight:CanSee(oWorld, oMonster) OR oWorld:Hero:SensesMonsters > 0) THEN DrawMonster(oMonster).
        END.
        Stamp(ASC("@"), RogueLook:Colour(RogueTint:Hero), oWorld:Hero:X, oWorld:Hero:Y + 1).
    END METHOD.

    /* One square of the dungeon: its terrain, and a trap when one has been found. */
    METHOD PRIVATE VOID DrawTerrain(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plInView AS LOGICAL):
        DEFINE VARIABLE code   AS INTEGER NO-UNDO.
        DEFINE VARIABLE colour AS INTEGER NO-UNDO.
        DEFINE VARIABLE t      AS INTEGER NO-UNDO.
        t = mGame:World:Cave:TerrainAt(piX, piY).
        CASE Terrain:GetEnum(t):
            WHEN Terrain:Rock THEN RETURN.
            WHEN Terrain:Floor THEN ASSIGN
                code = INTEGER(AsciiExtra:Dot)
                colour = RogueLook:Colour(IF plInView THEN RogueTint:Floor ELSE RogueTint:FloorSeen).
            WHEN Terrain:WallAcross OR WHEN Terrain:SecretAcross THEN ASSIGN
                code = INTEGER(AsciiExtra:WallAcross)
                colour = RogueLook:Colour(RogueTint:Wall).
            WHEN Terrain:WallDown OR WHEN Terrain:SecretDown THEN ASSIGN
                code = INTEGER(AsciiExtra:WallDown)
                colour = RogueLook:Colour(RogueTint:Wall).
            WHEN Terrain:CornerTopLeft THEN ASSIGN
                code = INTEGER(AsciiExtra:CornerTopLeft)
                colour = RogueLook:Colour(RogueTint:Wall).
            WHEN Terrain:CornerTopRight THEN ASSIGN
                code = INTEGER(AsciiExtra:CornerTopRight)
                colour = RogueLook:Colour(RogueTint:Wall).
            WHEN Terrain:CornerBottomLeft THEN ASSIGN
                code = INTEGER(AsciiExtra:CornerBottomLeft)
                colour = RogueLook:Colour(RogueTint:Wall).
            WHEN Terrain:CornerBottomRight THEN ASSIGN
                code = INTEGER(AsciiExtra:CornerBottomRight)
                colour = RogueLook:Colour(RogueTint:Wall).
            WHEN Terrain:Door THEN ASSIGN
                code = ASC("+")
                colour = RogueLook:Colour(RogueTint:Door).
            WHEN Terrain:Passage THEN ASSIGN
                code = ASC("#")
                colour = RogueLook:Colour(RogueTint:Passage).
            WHEN Terrain:Stairs THEN ASSIGN
                code = ASC("%")
                colour = RogueLook:Colour(RogueTint:Stairs).
        END CASE.
        IF NOT plInView AND t <> INTEGER(Terrain:Floor) THEN colour = RogueLook:Faded(colour).
        Stamp(code, colour, piX, piY + 1).
        IF mGame:World:Cave:TrapFound(piX, piY) AND mGame:World:Cave:TrapAt(piX, piY) > 0 THEN Stamp(ASC("^"), RogueLook:Colour(RogueTint:Trap), piX, piY + 1).
    END METHOD.

    /* The things lying on the floor: where the hero can see, and the ones a potion or a scroll has shown. */
    METHOD PRIVATE VOID DrawThings():
        DEFINE VARIABLE x     AS INTEGER NO-UNDO.
        DEFINE VARIABLE y     AS INTEGER NO-UNDO.
        DEFINE VARIABLE oItem AS Item    NO-UNDO.
        DEFINE VARIABLE show  AS LOGICAL NO-UNDO.
        DO y = 0 TO RogueRules:MapHeight() - 1:
            DO x = 0 TO RogueRules:MapWidth() - 1:
                IF mGame:World:Cave:ItemAt(x, y) > 0 THEN DO:
                    oItem = mGame:World:FloorItemAt(x, y).
                    show = mGame:World:Cave:InView(x, y)
                        OR (mGame:World:Hero:SensesMagic > 0 AND Magic:IsMagic(oItem))
                        OR (mGame:World:Hero:SensesFood > 0 AND oItem:Category = ItemType:Food).
                    IF show THEN DO:
                        IF mGame:World:Hero:Hallucinating > 0 THEN Stamp(ASC(SUBSTRING("*:)]!?/=,", (x * 7 + y * 3 + mGame:World:Turns) MODULO 9 + 1, 1)), RogueLook:OfItem(ItemType:GetEnum((x * 7 + y * 3 + mGame:World:Turns) MODULO 9)), x, y + 1).
                        ELSE Stamp(ASC(RogueLook:GlyphOfItem(oItem:Category)), RogueLook:OfItem(oItem:Category), x, y + 1).
                    END.
                END.
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID DrawMonster(INPUT poMonster AS Monster):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        IF mGame:World:Hero:Hallucinating > 0 THEN DO:
            n = (poMonster:X * 5 + poMonster:Y * 11 + mGame:World:Turns) MODULO 26.
            Stamp(ASC("A") + n, RogueLook:OfMonster(MonsterKind:GetEnum((n * 7) MODULO 26)), poMonster:X, poMonster:Y + 1).
        END.
        ELSE Stamp(ASC(poMonster:Letter()), RogueLook:OfMonster(poMonster:Kind), poMonster:X, poMonster:Y + 1).
    END METHOD.

    /* ================================== the lines ================================== */

    /* The top row: what is being asked, or else what was said this turn. */
    METHOD PRIVATE VOID DrawMessageLine():
        DEFINE VARIABLE words AS CHARACTER NO-UNDO.
        Block(0, 0, RogueRules:ScreenColumns(), 1, RogueLook:Colour(RogueTint:Background)).
        IF mGame:Asking <> "" THEN Say(mGame:Asking, RogueLook:Colour(RogueTint:Title), 0, 0).
        ELSE DO:
            words = mGame:World:Messages:Line(RogueRules:ScreenColumns()).
            Say(words, RogueLook:Colour(RogueTint:Text), 0, 0).
        END.
    END METHOD.

    /* The two bottom rows: the numbers of the hero, and how the hero is. */
    METHOD PRIVATE VOID DrawStatus():
        DEFINE VARIABLE w   AS RogueWorld NO-UNDO.
        DEFINE VARIABLE across AS INTEGER    NO-UNDO.
        DEFINE VARIABLE hpColour AS INTEGER NO-UNDO.
        w = mGame:World.
        across = Pair("Level:", STRING(w:Depth), RogueLook:Colour(RogueTint:Value), 0, 22).
        across = Pair("Gold:", STRING(w:Hero:Gold), RogueLook:Colour(RogueTint:Gold), across + 2, 22).
        hpColour = (IF w:Hero:Hp * 4 < w:Hero:MaxHp THEN RogueLook:Colour(RogueTint:Danger) ELSE IF w:Hero:Hp * 2 < w:Hero:MaxHp THEN RogueLook:Colour(RogueTint:Warn) ELSE RogueLook:Colour(RogueTint:Value)).
        across = Pair("Hp:", SUBSTITUTE("&1(&2)", w:Hero:Hp, w:Hero:MaxHp), hpColour, across + 2, 22).
        across = Pair("Str:", SUBSTITUTE("&1(&2)", Fighting:EffectiveStrength(w), w:Hero:MaxStrength), RogueLook:Colour(RogueTint:Value), across + 2, 22).
        across = Pair("Arm:", STRING(Fighting:ArmourClass(w)), RogueLook:Colour(RogueTint:Value), across + 2, 22).
        across = Pair("Exp:", SUBSTITUTE("&1/&2", w:Hero:Rank, w:Hero:Experience), RogueLook:Colour(RogueTint:Value), across + 2, 22).
        across = 0.
        CASE mGame:HungerState:
            WHEN Hunger:Hungry THEN across = Say("Hungry", RogueLook:Colour(RogueTint:Warn), across, 23) + 2.
            WHEN Hunger:Weak THEN across = Say("Weak", RogueLook:Colour(RogueTint:Danger), across, 23) + 2.
            WHEN Hunger:Faint OR WHEN Hunger:Starved THEN across = Say("Faint", RogueLook:Colour(RogueTint:Danger), across, 23) + 2.
        END CASE.
        IF w:Hero:Confused > 0 THEN across = Say("Confused", RogueLook:Colour(RogueTint:Warn), across, 23) + 2.
        IF w:Hero:Blind > 0 THEN across = Say("Blind", RogueLook:Colour(RogueTint:Warn), across, 23) + 2.
        IF w:Hero:Hallucinating > 0 THEN across = Say("Hallucinating", RogueLook:Colour(RogueTint:Warn), across, 23) + 2.
        IF w:Hero:Hasted > 0 THEN across = Say("Hasted", RogueLook:Colour(RogueTint:Good), across, 23) + 2.
        IF w:Hero:Levitating > 0 THEN across = Say("Levitating", RogueLook:Colour(RogueTint:Good), across, 23) + 2.
        IF w:Hero:Asleep > 0 THEN across = Say("Asleep", RogueLook:Colour(RogueTint:Danger), across, 23) + 2.
        IF w:Hero:Stuck > 0 THEN across = Say("Stuck", RogueLook:Colour(RogueTint:Danger), across, 23) + 2.
        IF VALID-OBJECT(w:Hero:HeldBy) THEN across = Say("Held", RogueLook:Colour(RogueTint:Danger), across, 23) + 2.
        IF w:Pack:HasAmulet() THEN across = Say("Amulet", RogueLook:Colour(RogueTint:Amulet), across, 23) + 2.
        Say("Turn " + STRING(w:Turns) + "   ? for help", RogueLook:Colour(RogueTint:Dim), RogueRules:ScreenColumns() - 22, 23).
    END METHOD.

    /* A label and its value on a status line: gives the column after them. */
    METHOD PRIVATE INTEGER Pair(INPUT pcLabel AS CHARACTER, INPUT pcValue AS CHARACTER, INPUT piColour AS INTEGER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        DEFINE VARIABLE across AS INTEGER NO-UNDO.
        across = Say(pcLabel, RogueLook:Colour(RogueTint:Label), piCol, piRow) + 1.
        RETURN Say(pcValue, piColour, across, piRow).
    END METHOD.

    /* ================================== the screens ================================== */

    /* A panel: a filled block of cells with a border drawn in the wall glyphs. */
    METHOD PRIVATE VOID Panel(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT piCols AS INTEGER, INPUT piRows AS INTEGER, INPUT pcTitle AS CHARACTER):
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE edge   AS INTEGER NO-UNDO.
        edge = RogueLook:Colour(RogueTint:PanelEdge).
        Block(piCol, piRow, piCols, piRows, RogueLook:Colour(RogueTint:PanelBack)).
        DO i = 1 TO piCols - 2:
            Stamp(INTEGER(AsciiExtra:WallAcross), edge, piCol + i, piRow).
            Stamp(INTEGER(AsciiExtra:WallAcross), edge, piCol + i, piRow + piRows - 1).
        END.
        DO i = 1 TO piRows - 2:
            Stamp(INTEGER(AsciiExtra:WallDown), edge, piCol, piRow + i).
            Stamp(INTEGER(AsciiExtra:WallDown), edge, piCol + piCols - 1, piRow + i).
        END.
        Stamp(INTEGER(AsciiExtra:CornerTopLeft), edge, piCol, piRow).
        Stamp(INTEGER(AsciiExtra:CornerTopRight), edge, piCol + piCols - 1, piRow).
        Stamp(INTEGER(AsciiExtra:CornerBottomLeft), edge, piCol, piRow + piRows - 1).
        Stamp(INTEGER(AsciiExtra:CornerBottomRight), edge, piCol + piCols - 1, piRow + piRows - 1).
        IF pcTitle <> "" THEN DO:
            /* the title interrupts the border: the cells behind it are cleared first */
            Block(piCol + 2, piRow, LENGTH(pcTitle) + 2, 1, RogueLook:Colour(RogueTint:PanelBack)).
            Say(" " + pcTitle + " ", RogueLook:Colour(RogueTint:Title), piCol + 2, piRow).
        END.
    END METHOD.

    /* The pack, a thing to a line, the letter in front. While the game asks which thing, the pack has no border and sits at the top. */
    METHOD PRIVATE VOID DrawPack(INPUT plAsking AS LOGICAL):
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE row   AS INTEGER NO-UNDO.
        DEFINE VARIABLE oItem AS Item    NO-UNDO.
        IF mGame:World:Pack:Count = 0 THEN DO:
            Panel(20, 1, 40, 3, "Pack").
            Say("You are carrying nothing.", RogueLook:Colour(RogueTint:Dim), 22, 2).
            RETURN.
        END.
        Block(10, 1, 70, mGame:World:Pack:Count + 1, RogueLook:Colour(RogueTint:PanelBack)).
        row = 1.
        DO i = 0 TO RogueRules:PackSize() - 1:
            IF mGame:World:Pack:Holds(i) THEN DO:
                oItem = mGame:World:Pack:At(i).
                Say(mGame:World:Pack:LetterOf(i) + ")", RogueLook:Colour(RogueTint:Label), 11, row).
                Say(SUBSTRING(Gear:Line(mGame:World, i), 4), RogueLook:OfItem(oItem:Category), 14, row).
                row = row + 1.
            END.
        END.
        IF NOT plAsking THEN Say("Press any key to go back", RogueLook:Colour(RogueTint:Dim), 11, row).
    END METHOD.

    METHOD PRIVATE VOID DrawOverlay():
        DEFINE VARIABLE lines AS CHARACTER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER   NO-UNDO.
        DEFINE VARIABLE n     AS INTEGER   NO-UNDO.
        CASE mGame:Showing:
            WHEN RogueOverlay:Inventory THEN DrawPack(FALSE).
            WHEN RogueOverlay:Help THEN DO:
                lines = RogueHelp:Text().
                Panel(2, 1, 76, NUM-ENTRIES(lines, CHR(10)) + 2, "Help").
                DrawLines(lines, 4, 2, RogueLook:Colour(RogueTint:Text)).
            END.
            WHEN RogueOverlay:Discoveries THEN DO:
                lines = RogueHelp:Discoveries(mGame:World).
                IF lines = "" THEN lines = "You have not discovered anything yet.".
                Panel(20, 1, 40, MINIMUM(NUM-ENTRIES(lines, CHR(10)) + 2, 22), "Discoveries").
                DrawLines(lines, 22, 2, RogueLook:Colour(RogueTint:Text)).
            END.
            WHEN RogueOverlay:Messages THEN DO:
                n = MINIMUM(mGame:World:Messages:Count, 20).
                Panel(1, 1, 78, n + 2, "Messages").
                DO i = 1 TO n:
                    Say(SUBSTRING(mGame:World:Messages:At(n - i), 1, 74), RogueLook:Colour(RogueTint:Text), 3, i + 1).
                END.
            END.
        END CASE.
    END METHOD.

    /* Lines of text (separated by CHR(10)) from a column and a row, one to a row. */
    METHOD PRIVATE VOID DrawLines(INPUT pcLines AS CHARACTER, INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT piColour AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO NUM-ENTRIES(pcLines, CHR(10)):
            Say(ENTRY(i, pcLines, CHR(10)), piColour, piCol, piRow + i - 1).
        END.
    END METHOD.

    /* The end of a game: a tombstone for a hero who has died, a word of triumph for one who has got out, and the ten best games. */
    METHOD PRIVATE VOID DrawTombstone():
        DEFINE VARIABLE w   AS RogueWorld NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER    NO-UNDO.
        DEFINE VARIABLE row AS INTEGER    NO-UNDO.
        w = mGame:World.
        Panel(14, 1, 52, 21, (IF w:Won THEN "A WINNER" ELSE "R.I.P.")).
        IF w:Won THEN DO:
            Say("You escaped with the Amulet of Yendor!", RogueLook:Colour(RogueTint:Good), 22, 3).
        END.
        ELSE DO:
            Say("      ___________", RogueLook:Colour(RogueTint:Wall), 22, 3).
            Say("     /           \", RogueLook:Colour(RogueTint:Wall), 22, 4).
            Say("    /   REST IN   \", RogueLook:Colour(RogueTint:Wall), 22, 5).
            Say("   /    PEACE      \", RogueLook:Colour(RogueTint:Wall), 22, 6).
            Say("  |                 |", RogueLook:Colour(RogueTint:Wall), 22, 7).
            Say("  |                 |", RogueLook:Colour(RogueTint:Wall), 22, 8).
            Say(RogueScores:Ending(FALSE, w:Cause), RogueLook:Colour(RogueTint:Danger), 28, 9).
        END.
        Say(SUBSTITUTE("on level &1 with &2 gold: score &3", w:DeepestDepth, w:Hero:Gold, w:Score), RogueLook:Colour(RogueTint:Text), 22, 11).
        Say("The ten best games", RogueLook:Colour(RogueTint:Title), 16, 13).
        row = 14.
        DO i = 1 TO MINIMUM(mScores:Count, 7):
            Say(mScores:Line(i), RogueLook:Colour(RogueTint:Label), 16, row).
            row = row + 1.
        END.
        Say("Press ENTER (or F2) for a new game", RogueLook:Colour(RogueTint:Dim), 16, 20).
    END METHOD.

END CLASS.
