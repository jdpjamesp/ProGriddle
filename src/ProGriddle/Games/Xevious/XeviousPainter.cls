/* Draws Xevious in the look of the design (docs/design/skylark-art.md, "First Light"; the colours and pictures are generated from it into
   XeviousLook, XeviousArt and XeviousTileArt). It reads a XeviousGame, never changes it, and paints the picture on a pixel canvas of its
   own, 224 x 288: a strip of 16 rows with the score, the field of 224 x 256, and a strip of 16 rows with the spare ships and the area.
   The canvas is handed to the window's renderer (the inner one), so the game's own grid is left as it is.

   The ground lives in the background layer of the canvas: it is built once for an area, then scrolled down a row at a time as the
   ground goes by (one block copy and the one new row of tiles at the top), so a frame costs a restore and what moves. Scorches are
   laid into that background where a target was destroyed, so they scroll with the land. Everything that moves, and every effect, is a
   function of the game's own frame counts (Frames, PhaseFrames and the age of each thing), so a test sees the same picture for the
   same game. The light of the design comes from the upper left: shadows fall down and to the right.

   Drawing order (section 5 of the design): ground (with the light of bursts on it), scorches, ground targets, shadows, haze, the sight, the
   bomb, air enemies, bursts, bullets, shots, the ship, the strips, words.

   The painter owns canvases, stamps and memory: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousPainter FINAL IMPLEMENTS IGridRenderer:

    /* the size of the picture: a strip of 16 rows, the field of 256 and a strip of 16 */
    &SCOPED-DEFINE STRIP 16
    &SCOPED-DEFINE WIDTH 224
    &SCOPED-DEFINE HEIGHT 288
    &SCOPED-DEFINE FIELD 256

    VAR PRIVATE IGridRenderer mInner.
    VAR PRIVATE XeviousGame mGame.
    VAR PRIVATE Grid mGrid.
    VAR PRIVATE PixelCanvas mCanvas.
    VAR PRIVATE TextStampCache mText.
    VAR PRIVATE XeviousSprites mSprites.
    VAR PRIVATE LOGICAL mDisposed.
    /* one row of colours, and a block of the whole field's rows, for writing the background */
    VAR PRIVATE MEMPTR mRowMem.
    VAR PRIVATE MEMPTR mBlock.
    /* what the background is built for: the stage and the distance gone by (-1 for nothing yet), and the map row whose tiles are known */
    VAR PRIVATE INTEGER mBakedStage.
    VAR PRIVATE INTEGER mBakedDistance = -1.
    VAR PRIVATE INTEGER mRowR = -1.
    VAR PRIVATE INTEGER[14] mRowTiles.
    /* the ground slots whose scorch is already in the background */
    VAR PRIVATE LOGICAL[28] mScorched.
    /* cell lists (three whole numbers each: across, down, colour) for the rings of bloom and the clouds of haze, and how many cells */
    VAR PRIVATE MEMPTR mBloomBullet.
    VAR PRIVATE MEMPTR mBloomZap.
    VAR PRIVATE MEMPTR mBloomSight.
    VAR PRIVATE MEMPTR mCloudA.
    VAR PRIVATE MEMPTR mCloudB.
    VAR PRIVATE INTEGER mBloomBulletN.
    VAR PRIVATE INTEGER mBloomZapN.
    VAR PRIVATE INTEGER mBloomSightN.
    VAR PRIVATE INTEGER mCloudAN.
    VAR PRIVATE INTEGER mCloudBN.
    /* the way the ship is banking, and the frame it last moved sideways */
    VAR PRIVATE INTEGER mBankWay.
    VAR PRIVATE INTEGER mBankFrame.

    /* The canvas the picture is drawn on, and the grid it is on (what the window's renderer is given). */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    DEFINE PUBLIC PROPERTY CanvasGrid AS Grid NO-UNDO
        GET():
            RETURN mGrid.
        END GET.

    /* The height of the strip of numbers above the field, in pixels. */
    DEFINE PUBLIC PROPERTY StripHeight AS INTEGER NO-UNDO
        GET():
            RETURN {&STRIP}.
        END GET.

    /* True (the default) to draw the haze: the soft clouds high over the land. */
    DEFINE PUBLIC PROPERTY Haze AS LOGICAL NO-UNDO INITIAL TRUE
        GET.
        SET.

    /* True to draw the optional scanlines (every odd row of the picture a little darker). It costs the whole field, so it is off. */
    DEFINE PUBLIC PROPERTY Scanlines AS LOGICAL NO-UNDO INITIAL FALSE
        GET.
        SET.

    /* Throws GridException for no renderer or no game. */
    CONSTRUCTOR PUBLIC XeviousPainter(INPUT poInner AS IGridRenderer, INPUT poGame AS XeviousGame):
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A Xevious painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A Xevious painter needs a game").
        mInner = poInner.
        mGame = poGame.
        mText = NEW TextStampCache(96).
        mSprites = NEW XeviousSprites().
        mGrid = NEW Grid(NEW ArrayStore({&WIDTH}, {&HEIGHT}, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        SET-SIZE(mRowMem) = {&WIDTH} * 4.
        SET-SIZE(mBlock) = {&WIDTH} * {&FIELD} * 4.
        BuildRing(5, 5, mBloomBullet, mBloomBulletN).
        BuildRing(3, 6, mBloomZap, mBloomZapN).
        BuildRing(15, 15, mBloomSight, mBloomSightN).
        BuildCloud(30, 10, 3, mCloudA, mCloudAN).
        BuildCloud(22, 8, 5, mCloudB, mCloudBN).
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC XeviousPainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the canvas to the window's renderer. Throws GridException for a game that is not a
       Xevious game. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, XeviousGame) THEN UNDO, THROW NEW GridException("A Xevious painter draws a Xevious game").
        SyncGround().
        BakeScorches().
        mCanvas:Restore().
        mCanvas:BeginBatch().
        DrawLight().
        IF mGame:Phase <> XeviousPhase:Title AND mGame:Phase <> XeviousPhase:GameOver THEN DrawWorld().
        DrawStrips().
        mCanvas:EndBatch().
        DrawVeils().
        mCanvas:BeginBatch().
        DrawWords().
        mCanvas:EndBatch().
        IF Scanlines THEN DrawScanlines().
        mInner:Render(mGrid, poGame).
    END METHOD.

    /* Frees the canvas, the stamps and the memory. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        IF VALID-OBJECT(mText) THEN mText:Dispose().
        IF VALID-OBJECT(mSprites) THEN mSprites:Dispose().
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        SET-SIZE(mRowMem) = 0.
        SET-SIZE(mBlock) = 0.
        SET-SIZE(mBloomBullet) = 0.
        SET-SIZE(mBloomZap) = 0.
        SET-SIZE(mBloomSight) = 0.
        SET-SIZE(mCloudA) = 0.
        SET-SIZE(mCloudB) = 0.
    END METHOD.

    /* ================================ small helpers ================================ */

    METHOD PRIVATE INTEGER Colour(INPUT poTint AS XeviousTint):
        RETURN XeviousLook:Colour(poTint).
    END METHOD.

    /* Draws a sprite with its top left at piX, piY (canvas cells). */
    METHOD PRIVATE VOID Blit(INPUT poPicture AS XeviousPicture, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        mSprites:Stamp(poPicture):DrawTo(mCanvas, piX, piY).
    END METHOD.

    /* Casts a sprite's shadow: its cells tinted toward Ink by 35 percent, offset by piDx, piDy. */
    METHOD PRIVATE VOID Shadow(INPUT poPicture AS XeviousPicture, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        mSprites:Stamp(poPicture):TintTo(mCanvas, piX, piY, Colour(XeviousTint:Ink), 35).
    END METHOD.

    /* A picture by its name and frame number, such as Whirl and 3. */
    METHOD PRIVATE XeviousPicture Pose(INPUT pcName AS CHARACTER, INPUT piFrame AS INTEGER):
        RETURN XeviousPicture:GetEnum(pcName + STRING(piFrame)).
    END METHOD.

    /* A list of the cells of a ring one cell wide round a picture of piW x piH (the picture itself is not in it). The cells are in
       the form PutCells reads, from the top left of the ring, which is one cell up and left of the picture. */
    METHOD PRIVATE VOID BuildRing(INPUT piW AS INTEGER, INPUT piH AS INTEGER, INPUT-OUTPUT pmCells AS MEMPTR, OUTPUT piCount AS INTEGER):
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER n.
        SET-SIZE(pmCells) = (piW + 2) * (piH + 2) * 12.
        DO y = 0 TO piH + 1:
            DO x = 0 TO piW + 1:
                IF x = 0 OR x = piW + 1 OR y = 0 OR y = piH + 1 THEN DO:
                    PUT-LONG(pmCells, n * 12 + 1) = x.
                    PUT-LONG(pmCells, n * 12 + 5) = y.
                    PUT-LONG(pmCells, n * 12 + 9) = 0.
                    n = n + 1.
                END.
            END.
        END.
        piCount = n.
    END METHOD.

    /* A soft cloud: an ellipse of piRx x piRy with a wobbling rim, the rim only every other cell (a checker), which reads as soft with no
       blending. The cells are from the top left of its bounding box. */
    METHOD PRIVATE VOID BuildCloud(INPUT piRx AS INTEGER, INPUT piRy AS INTEGER, INPUT piSeed AS INTEGER, INPUT-OUTPUT pmCells AS MEMPTR, OUTPUT piCount AS INTEGER):
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER n.
        VAR INTEGER dx.
        VAR INTEGER dy.
        VAR INTEGER d.
        VAR INTEGER wob.
        SET-SIZE(pmCells) = (2 * piRx + 1) * (2 * piRy + 1) * 12.
        DO y = 0 TO 2 * piRy:
            DO x = 0 TO 2 * piRx:
                dx = x - piRx.
                dy = y - piRy.
                d = XeviousMotion:Div(dx * dx * 100, piRx * piRx) + XeviousMotion:Div(dy * dy * 100, piRy * piRy).
                wob = ((x * 5 + y * 3 + piSeed) MODULO 7) * 5 - 15.
                IF d <= 55 OR (d <= 100 + wob AND (x + y) MODULO 2 = 0) THEN DO:
                    PUT-LONG(pmCells, n * 12 + 1) = x.
                    PUT-LONG(pmCells, n * 12 + 5) = y.
                    PUT-LONG(pmCells, n * 12 + 9) = 0.
                    n = n + 1.
                END.
            END.
        END.
        piCount = n.
    END METHOD.

    /* ================================ the ground ================================ */

    /* Makes the background the ground for the game as it is: built whole when the stage changes or the ground jumps (a stage
       begins, a ship comes back at a checkpoint), and scrolled down a row at a time as the ground goes by. */
    METHOD PRIVATE VOID SyncGround():
        VAR INTEGER d.
        VAR INTEGER veil.
        d = mGame:Distance.
        /* the title and the game over screen show the land under a veil of Ink, which is made in the colours of the tiles once, so it costs
           nothing in a frame */
        veil = (IF mGame:Phase = XeviousPhase:Title THEN 55 ELSE IF mGame:Phase = XeviousPhase:GameOver THEN 50 ELSE 0).
        IF veil <> mSprites:Veil THEN DO:
            mSprites:Veil = veil.
            mBakedDistance = -1.
        END.
        IF mBakedDistance < 0 OR mGame:Stage <> mBakedStage OR d < mBakedDistance OR d - mBakedDistance > 24 THEN DO:
            RebuildGround().
            RETURN.
        END.
        DO WHILE mBakedDistance < d:
            mBakedDistance = mBakedDistance + 1.
            mCanvas:ScrollBackDown({&STRIP}, {&FIELD}, 1).
            FillLine(mBakedDistance, 0, mRowMem, 1).
            mCanvas:PutBackRow({&STRIP}, mRowMem).
        END.
    END METHOD.

    METHOD PRIVATE VOID RebuildGround():
        VAR INTEGER y.
        mSprites:ForArea(mGame:Stage).
        mRowR = -1.
        DO y = 0 TO {&FIELD} - 1:
            FillLine(mGame:Distance, y, mBlock, y * {&WIDTH} * 4 + 1).
        END.
        mCanvas:PutBackRows({&STRIP}, mBlock).
        mBakedDistance = mGame:Distance.
        mBakedStage = mGame:Stage.
        DO y = 1 TO 28:
            mScorched[y] = FALSE.
        END.
    END METHOD.

    /* The colours of one line of the field (screen line piY, 0 at the top of the field) when the ground has gone by piDistance, written
       as 14 tile lines into pmTo from byte piAt. Row 0 of the map is the first at the bottom of the screen when the stage begins. */
    METHOD PRIVATE VOID FillLine(INPUT piDistance AS INTEGER, INPUT piY AS INTEGER, INPUT pmTo AS MEMPTR, INPUT piAt AS INTEGER):
        VAR INTEGER u.
        VAR INTEGER r.
        VAR INTEGER line.
        VAR INTEGER c.
        u = XeviousRules:FieldHeight() - 16 + piDistance - piY.
        r = (IF u <= 0 THEN 0 ELSE XeviousMotion:Div(u + 15, 16)).
        line = 16 * r - u.
        IF r <> mRowR THEN DO:
            DO c = 0 TO XeviousRules:Cols() - 1:
                mRowTiles[c + 1] = INTEGER(XeviousMap:PictureAt(mGame:Stage, c, r)).
            END.
            mRowR = r.
        END.
        DO c = 0 TO XeviousRules:Cols() - 1:
            mSprites:TileLine(XeviousTilePicture:GetEnum(mRowTiles[c + 1]), line, pmTo, piAt + c * 64).
        END.
    END METHOD.

    /* A target that has been destroyed leaves its scorch in the background, where it scrolls away with the land. */
    METHOD PRIVATE VOID BakeScorches():
        VAR INTEGER i.
        VAR XeviousGround kind.
        DO i = 0 TO mGame:GroundSlots - 1:
            IF mGame:GroundState(i) = 2 THEN DO:
                IF NOT mScorched[i + 1] THEN DO:
                    mScorched[i + 1] = TRUE.
                    kind = mGame:GroundKindAt(i).
                    mSprites:Stamp(ScorchOf(kind)):DrawBackTo(mCanvas, mGame:GroundX(i), {&STRIP} + mGame:GroundY(i)).
                END.
            END.
            ELSE mScorched[i + 1] = FALSE.
        END.
    END METHOD.

    METHOD PRIVATE XeviousPicture ScorchOf(INPUT poKind AS XeviousGround):
        CASE poKind:
            WHEN XeviousGround:Barra THEN RETURN XeviousPicture:CairnScorch.
            WHEN XeviousGround:Zolbak THEN RETURN XeviousPicture:DishScorch.
            WHEN XeviousGround:Logram THEN RETURN XeviousPicture:BurrScorch.
            WHEN XeviousGround:Derota THEN RETURN XeviousPicture:BastionScorch.
            WHEN XeviousGround:Grobda THEN RETURN XeviousPicture:BeetleScorch.
            WHEN XeviousGround:GaruBarra THEN RETURN XeviousPicture:HengeScorch.
            WHEN XeviousGround:GaruZakato THEN RETURN XeviousPicture:HiveScorch.
            OTHERWISE RETURN XeviousPicture:SpireScorch.
        END CASE.
    END METHOD.

    /* The light that a burst throws on the land: three rings of Glow Light (30 percent inside 8 cells, 20 to 16, 10 to 24), all scaled
       by how little of the first 8 frames is left. It warms the ground only, so it is drawn before anything stands on it. */
    METHOD PRIVATE VOID DrawLight():
        VAR INTEGER i.
        VAR XeviousFx fx.
        DO i = 0 TO mGame:FxSlots - 1:
            fx = mGame:FxKindAt(i).
            IF VALID-OBJECT(fx) AND (fx = XeviousFx:GroundBlast OR fx = XeviousFx:BossBlast) AND mGame:FxAge(i) < 8 THEN DO:
                Disk(mGame:FxX(i), {&STRIP} + mGame:FxY(i), 24, XeviousMotion:Div(10 * (8 - mGame:FxAge(i)), 8)).
                Disk(mGame:FxX(i), {&STRIP} + mGame:FxY(i), 16, XeviousMotion:Div(10 * (8 - mGame:FxAge(i)), 8)).
                Disk(mGame:FxX(i), {&STRIP} + mGame:FxY(i), 8, XeviousMotion:Div(12 * (8 - mGame:FxAge(i)), 8)).
            END.
        END.
    END METHOD.

    /* A disk of piR cells round piX, piY tinted piPercent toward Glow Light, row by row. */
    METHOD PRIVATE VOID Disk(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piR AS INTEGER, INPUT piPercent AS INTEGER):
        VAR INTEGER dy.
        VAR INTEGER half.
        IF piPercent <= 0 THEN RETURN.
        DO dy = - piR TO piR:
            half = XeviousMotion:Div(INTEGER(SQRT(piR * piR - dy * dy)) * 1, 1).
            IF piY + dy >= {&STRIP} AND piY + dy < {&STRIP} + {&FIELD} THEN
                mCanvas:DimRect(piX - half, piY + dy, 2 * half + 1, 1, piPercent, Colour(XeviousTint:GlowLight)).
        END.
    END METHOD.

    /* ================================ the world ================================ */

    METHOD PRIVATE VOID DrawWorld():
        DrawGroundTargets().
        DrawShadows().
        DrawHaze().
        DrawSight().
        DrawBomb().
        DrawAir().
        DrawBoss().
        DrawEffects().
        DrawBullets().
        DrawZaps().
        DrawPlayer().
    END METHOD.

    /* The ground targets. A hidden one shows nothing, except its flicker while the sight's centre is in its box. */
    METHOD PRIVATE VOID DrawGroundTargets():
        VAR INTEGER i.
        VAR INTEGER state.
        VAR XeviousGround kind.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER age.
        DO i = 0 TO mGame:GroundSlots - 1:
            state = mGame:GroundState(i).
            IF state = 0 OR state = 2 THEN NEXT.
            kind = mGame:GroundKindAt(i).
            x = mGame:GroundX(i).
            y = {&STRIP} + mGame:GroundY(i).
            age = mGame:GroundAge(i).
            CASE state:
                WHEN 3 THEN Blit(XeviousPicture:Spire, x, y).
                WHEN 4 THEN Blit((IF XeviousMotion:Div(age, 8) MODULO 2 = 0 THEN XeviousPicture:Pennant1 ELSE XeviousPicture:Pennant2), x, y).
                OTHERWISE DO:
                    CASE kind:
                        WHEN XeviousGround:Sol THEN DO:
                            IF mGame:Frames MODULO 16 < 2 AND Under(i) THEN Blit(XeviousPicture:SpireFlicker, x, y).
                        END.
                        WHEN XeviousGround:Flag THEN.
                        WHEN XeviousGround:Grobda THEN mSprites:Turned((IF XeviousMotion:Div(age, 4) MODULO 2 = 0 THEN XeviousPicture:Beetle1 ELSE XeviousPicture:Beetle2),
                                                                         (IF mGame:GroundWay(i) > 0 THEN 1 ELSE 3)):DrawTo(mCanvas, x, y).
                        WHEN XeviousGround:GaruZakato THEN Blit((IF age MODULO 180 >= 160 THEN XeviousPicture:HiveOpen ELSE XeviousPicture:HiveClosed), x, y).
                        OTHERWISE Blit(XeviousBoxes:GroundPicture(kind), x, y).
                    END CASE.
                END.
            END CASE.
        END.
    END METHOD.

    /* True when the centre of the sight is inside the box of the ground slot piIndex (0 up). */
    METHOD PRIVATE LOGICAL Under(INPUT piIndex AS INTEGER):
        VAR XeviousGround kind.
        kind = mGame:GroundKindAt(piIndex).
        RETURN mGame:SightX >= mGame:GroundX(piIndex) + XeviousBoxes:GroundLeft(kind)
           AND mGame:SightX < mGame:GroundX(piIndex) + XeviousBoxes:GroundLeft(kind) + XeviousBoxes:GroundWidth(kind)
           AND mGame:SightY >= mGame:GroundY(piIndex) + XeviousBoxes:GroundTop(kind)
           AND mGame:SightY < mGame:GroundY(piIndex) + XeviousBoxes:GroundTop(kind) + XeviousBoxes:GroundHeight(kind).
    END METHOD.

    /* Everything in the air casts its outline on the ground: the ship (+6, +10) and the enemies (+4, +6). */
    METHOD PRIVATE VOID DrawShadows():
        VAR INTEGER i.
        VAR XeviousAir kind.
        VAR XeviousPicture pic.
        DO i = 0 TO mGame:AirSlots - 1:
            IF mGame:AirActive(i) THEN DO:
                kind = mGame:AirKindAt(i).
                pic = AirFrame(kind, mGame:AirAge(i)).
                Shadow(pic, mGame:AirX(i) + XeviousBoxes:SlotOffset(pic) + 4, {&STRIP} + mGame:AirY(i) + XeviousBoxes:SlotOffset(pic) + 6).
            END.
        END.
        IF mGame:PlayerAlive THEN Shadow(XeviousPicture:Lark, mGame:PlayerX + 6, {&STRIP} + mGame:PlayerY + 10).
        IF mGame:BombActive THEN Shadow(XeviousPicture:BombShadow, mGame:BombX - 2, {&STRIP} + mGame:BombY - 1).
    END METHOD.

    /* Clouds high over the land: two soft lumps of Haze at 22 percent that move down 1.25 times as fast as the land and drift sideways,
       so the land seems to slide under them. */
    METHOD PRIVATE VOID DrawHaze():
        VAR INTEGER d.
        VAR INTEGER y.
        IF NOT Haze THEN RETURN.
        d = mGame:Distance.
        y = XeviousMotion:Div(d * 5, 4) MODULO ({&FIELD} + 40) - 20.
        mCanvas:TintCells(mCloudA, mCloudAN, 20 + XeviousMotion:Div(mGame:Frames, 64) MODULO 224, {&STRIP} + y, Colour(XeviousTint:Haze), 22).
        y = (XeviousMotion:Div(d * 5, 4) + 140) MODULO ({&FIELD} + 40) - 20.
        mCanvas:TintCells(mCloudB, mCloudBN, 150 - XeviousMotion:Div(mGame:Frames, 64) MODULO 224, {&STRIP} + y, Colour(XeviousTint:Haze), 22).
    END METHOD.

    /* The sight (15 x 15, its centre cell the aim point), in Sight Lock with a glow when a target is under it. */
    METHOD PRIVATE VOID DrawSight():
        VAR LOGICAL onTarget.
        IF NOT mGame:PlayerAlive THEN RETURN.
        onTarget = mGame:SightOnTarget.
        IF onTarget THEN mCanvas:TintCells(mBloomSight, mBloomSightN, mGame:SightX - 8, {&STRIP} + mGame:SightY - 8, Colour(XeviousTint:SightLock), 30).
        Blit((IF onTarget THEN XeviousPicture:SightLock ELSE XeviousPicture:Sight), mGame:SightX - 7, {&STRIP} + mGame:SightY - 7).
    END METHOD.

    /* The bomb in the air: three frames pulsing 1 2 3 2, and the last 4 frames on the third. From straight above it does not shrink: it
       is lifted up and left of its shadow by an amount that falls to nothing as it lands. */
    METHOD PRIVATE VOID DrawBomb():
        VAR INTEGER n.
        VAR INTEGER lift.
        IF NOT mGame:BombActive THEN RETURN.
        IF mGame:BombAge >= XeviousRules:BombFlight() - 4 THEN n = 3.
        ELSE n = INTEGER(ENTRY(XeviousMotion:Div(mGame:BombAge, 3) MODULO 4 + 1, "1,2,3,2")).
        lift = XeviousMotion:Div((XeviousRules:BombFlight() - mGame:BombAge) * 8, XeviousRules:BombFlight()).
        Blit(Pose("Bomb", n), mGame:BombX - 3 - XeviousMotion:Div(lift, 2), {&STRIP} + mGame:BombY - 3 - lift).
    END METHOD.

    /* The picture of an air enemy at an age, by the recipes of the design (section 4). */
    METHOD PRIVATE XeviousPicture AirFrame(INPUT poKind AS XeviousAir, INPUT piAge AS INTEGER):
        CASE poKind:
            WHEN XeviousAir:Toroid THEN RETURN Pose("Whirl", XeviousMotion:Div(piAge, 3) MODULO 4 + 1).
            WHEN XeviousAir:Torkan THEN DO:
                IF piAge < 60 THEN RETURN XeviousPicture:SkateDive.
                IF piAge < 68 THEN RETURN XeviousPicture:SkateRise.
                RETURN XeviousPicture:SkateFlat.
            END.
            WHEN XeviousAir:GiddoSpario THEN RETURN Pose("Kite", INTEGER(ENTRY(XeviousMotion:Div(piAge, 6) MODULO 6 + 1, "1,2,3,4,3,2"))).
            WHEN XeviousAir:Kapi THEN DO:
                IF piAge > 45 THEN RETURN XeviousPicture:Glint3.
                RETURN Pose("Glint", INTEGER(ENTRY(XeviousMotion:Div(piAge, 5) MODULO 6 + 1, "1,2,3,4,3,2"))).
            END.
            WHEN XeviousAir:Jara THEN RETURN Pose("Midge", XeviousMotion:Div(piAge, 2) MODULO 2 + 1).
            WHEN XeviousAir:Zakato THEN DO:
                IF piAge < 8 THEN RETURN XeviousPicture:Wisp1.
                IF piAge >= 28 THEN RETURN XeviousPicture:Wisp3.
                RETURN Pose("Wisp", XeviousMotion:Div(piAge - 8, 6) MODULO 2 + 2).
            END.
            WHEN XeviousAir:Terrazi THEN RETURN Pose("Swift", XeviousMotion:Div(piAge, 3) MODULO 2 + 1).
            OTHERWISE RETURN Pose("Anvil", XeviousMotion:Div(piAge, 4) MODULO 6 + 1).
        END CASE.
    END METHOD.

    METHOD PRIVATE VOID DrawAir():
        VAR INTEGER i.
        VAR XeviousPicture pic.
        DO i = 0 TO mGame:AirSlots - 1:
            IF mGame:AirActive(i) THEN DO:
                pic = AirFrame(mGame:AirKindAt(i), mGame:AirAge(i)).
                Blit(pic, mGame:AirX(i) + XeviousBoxes:SlotOffset(pic), {&STRIP} + mGame:AirY(i) + XeviousBoxes:SlotOffset(pic)).
            END.
        END.
    END METHOD.

    /* The Citadel: the core of eight plates, and the four shield plates round it (the north one turned for the other three). */
    METHOD PRIVATE VOID DrawBoss():
        VAR INTEGER x.
        VAR INTEGER y.
        IF NOT mGame:BossActive THEN RETURN.
        x = mGame:BossX.
        y = {&STRIP} + mGame:BossY.
        Shadow(XeviousPicture:CitadelCore, x + 4, y + 6).
        Blit(XeviousPicture:CitadelCore, x, y).
        Blit(XeviousPicture:ShieldN, x + 8, y - 13).
        mSprites:Turned(XeviousPicture:ShieldN, 1):DrawTo(mCanvas, x + 33, y + 8).
        mSprites:Turned(XeviousPicture:ShieldN, 2):DrawTo(mCanvas, x + 8, y + 33).
        mSprites:Turned(XeviousPicture:ShieldN, 3):DrawTo(mCanvas, x - 13, y + 8).
    END METHOD.

    /* Enemy bullets, always Hot, with a halo. */
    METHOD PRIVATE VOID DrawBullets():
        VAR INTEGER i.
        VAR INTEGER x.
        VAR INTEGER y.
        DO i = 0 TO mGame:BulletSlots - 1:
            IF mGame:BulletActive(i) THEN DO:
                x = mGame:BulletX(i) - 2.
                y = {&STRIP} + mGame:BulletY(i) - 2.
                mCanvas:TintCells(mBloomBullet, mBloomBulletN, x - 1, y - 1, Colour(XeviousTint:Hot), 40).
                Blit(Pose("Bullet", XeviousMotion:Div(mGame:Frames, 2) MODULO 2 + 1), x, y).
            END.
        END.
    END METHOD.

    METHOD PRIVATE VOID DrawZaps():
        VAR INTEGER i.
        DO i = 0 TO XeviousRules:ZapMax() - 1:
            IF mGame:ZapActive(i) THEN DO:
                mCanvas:TintCells(mBloomZap, mBloomZapN, mGame:ZapX(i) - 1, {&STRIP} + mGame:ZapY(i) - 1, Colour(XeviousTint:ZapGlow), 30).
                Blit(XeviousPicture:Zap, mGame:ZapX(i), {&STRIP} + mGame:ZapY(i)).
            END.
        END.
    END METHOD.

    /* The ship: level, or banking to the side it is moving (and back to level 4 frames after it stops), with a flame of two frames that
       stays on the second while it moves up. It blinks while protected. A ship that is breaking up is drawn in pieces. */
    METHOD PRIVATE VOID DrawPlayer():
        VAR INTEGER x.
        VAR INTEGER y.
        VAR XeviousPicture pic.
        IF mGame:MoveX <> 0 THEN ASSIGN mBankWay = mGame:MoveX mBankFrame = mGame:Frames.
        ELSE IF mGame:Frames - mBankFrame > 4 THEN mBankWay = 0.
        IF mGame:Phase = XeviousPhase:Dying THEN DO:
            DrawBreakup(mGame:PlayerX, {&STRIP} + mGame:PlayerY, mGame:PhaseFrames).
            RETURN.
        END.
        IF NOT mGame:PlayerAlive THEN RETURN.
        IF mGame:Protection > 0 AND mGame:Frames MODULO 8 < 4 THEN RETURN.
        x = mGame:PlayerX.
        y = {&STRIP} + mGame:PlayerY.
        IF mBankWay < 0 THEN pic = XeviousPicture:LarkBankLeft.
        ELSE IF mBankWay > 0 THEN pic = XeviousPicture:LarkBankRight.
        ELSE pic = XeviousPicture:Lark.
        IF mGame:MoveY < 0 OR XeviousMotion:Div(mGame:Frames, 4) MODULO 2 = 1 THEN Blit(XeviousPicture:Flame2, x, y + 13).
        ELSE Blit(XeviousPicture:Flame1, x, y + 13).
        Blit(pic, x, y).
    END METHOD.

    /* The ship in four pieces over 90 frames (section 3.7 of the design): each piece starts at an offset and drifts, and from frame 12
       each cell is mixed toward Smoke, and a cell goes when a pattern says so, so the pieces crumble rather than blink out. */
    METHOD PRIVATE VOID DrawBreakup(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piAge AS INTEGER):
        VAR INTEGER piece.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER c.
        VAR INTEGER ox.
        VAR INTEGER oy.
        VAR INTEGER dx.
        VAR INTEGER dy.
        VAR INTEGER smoke.
        VAR PixelStamp stamp.
        IF piAge >= 90 THEN RETURN.
        smoke = MINIMUM(100, XeviousMotion:Div(140 * MAXIMUM(0, piAge - 12), 90)).
        DO piece = 0 TO 3:
            /* start offset and drift (in tenths of a cell a quarter frame) of the nose, the left wing, the right wing and the tail */
            ox = INTEGER(ENTRY(piece + 1, "0,-1,1,0")).
            oy = INTEGER(ENTRY(piece + 1, "-1,0,0,1")).
            dx = INTEGER(ENTRY(piece + 1, "0,-7,7,0")).
            dy = INTEGER(ENTRY(piece + 1, "-6,2,2,5")).
            stamp = mSprites:Stamp(PieceOf(piece)).
            DO y = 0 TO 15:
                DO x = 0 TO 15:
                    c = stamp:ColourAt(x, y).
                    IF c < 0 THEN NEXT.
                    IF ((x * 7 + y * 11) MODULO 10) * 90 < piAge * 10 THEN NEXT.
                    IF smoke > 0 THEN c = ColourMath:Mix(c, Colour(XeviousTint:Smoke), smoke, 100).
                    mCanvas:Plot(piX + x + ox + XeviousMotion:Div(dx * piAge, 40), piY + y + oy + XeviousMotion:Div(dy * piAge, 40), 0, c).
                END.
            END.
        END.
    END METHOD.

    METHOD PRIVATE XeviousPicture PieceOf(INPUT piPiece AS INTEGER):
        CASE piPiece:
            WHEN 0 THEN RETURN XeviousPicture:LarkPieceNose.
            WHEN 1 THEN RETURN XeviousPicture:LarkPieceWingLeft.
            WHEN 2 THEN RETURN XeviousPicture:LarkPieceWingRight.
            OTHERWISE RETURN XeviousPicture:LarkPieceTail.
        END CASE.
    END METHOD.

    /* ================================ effects ================================ */

    METHOD PRIVATE VOID DrawEffects():
        VAR INTEGER i.
        VAR XeviousFx fx.
        VAR INTEGER age.
        DO i = 0 TO mGame:FxSlots - 1:
            fx = mGame:FxKindAt(i).
            IF NOT VALID-OBJECT(fx) THEN NEXT.
            age = mGame:FxAge(i).
            CASE fx:
                WHEN XeviousFx:AirBlast THEN Blit(Pose("AirBoom", MINIMUM(5, XeviousMotion:Div(age, 4) + 1)), mGame:FxX(i) - 8, {&STRIP} + mGame:FxY(i) - 8).
                WHEN XeviousFx:GroundBlast THEN Blit(Pose("GroundBoom", MINIMUM(6, XeviousMotion:Div(age, 5) + 1)), mGame:FxX(i) - 16, {&STRIP} + mGame:FxY(i) - 16).
                WHEN XeviousFx:ShipBlast THEN DO:
                    IF age < 20 THEN Blit(Pose("AirBoom", MINIMUM(5, XeviousMotion:Div(age, 4) + 1)), mGame:FxX(i) - 8, {&STRIP} + mGame:FxY(i) - 8).
                END.
                WHEN XeviousFx:BossBlast THEN DrawBossBlast(mGame:FxX(i), {&STRIP} + mGame:FxY(i), age).
                WHEN XeviousFx:Points THEN Words(STRING(mGame:FxValue(i)), 1, XeviousTint:Signal, XeviousTint:Signal,
                                                 MAXIMUM(1, MINIMUM({&WIDTH} - 26, mGame:FxX(i) - 8)), MAXIMUM({&STRIP}, {&STRIP} + mGame:FxY(i) - XeviousMotion:Div(age, 6)), FALSE).
            END CASE.
        END.
    END METHOD.

    /* The Citadel going: a burst at the core and one at each of the four plate sockets, 6 frames apart. */
    METHOD PRIVATE VOID DrawBossBlast(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piAge AS INTEGER):
        VAR INTEGER n.
        VAR INTEGER a.
        DO n = 0 TO 4:
            a = piAge - n * 6.
            IF a >= 0 AND a < 30 THEN
                Blit(Pose("GroundBoom", MINIMUM(6, XeviousMotion:Div(a, 5) + 1)),
                    piX - 16 + INTEGER(ENTRY(n + 1, "0,0,16,0,-16")), piY - 16 + INTEGER(ENTRY(n + 1, "0,-16,0,16,0"))).
        END.
    END METHOD.

    /* ================================ the strips and the words ================================ */

    /* The score strip above the field and the strip of spare ships and the area below it. */
    METHOD PRIVATE VOID DrawStrips():
        VAR INTEGER i.
        mCanvas:FillRect(0, 0, {&WIDTH}, {&STRIP}, 0, Colour(XeviousTint:Strip)).
        mCanvas:FillRect(0, {&STRIP} - 1, {&WIDTH}, 1, 0, Colour(XeviousTint:Ink)).
        mCanvas:FillRect(0, {&STRIP} + {&FIELD}, {&WIDTH}, {&STRIP}, 0, Colour(XeviousTint:Strip)).
        mCanvas:FillRect(0, {&STRIP} + {&FIELD}, {&WIDTH}, 1, 0, Colour(XeviousTint:Ink)).
        Words("SCORE", 1, XeviousTint:TextDim, XeviousTint:TextDim, 6, 1, FALSE).
        Words(STRING(mGame:Score), 1, XeviousTint:Signal, XeviousTint:Signal, 42, 1, FALSE).
        Words("HI", 1, XeviousTint:TextDim, XeviousTint:TextDim, 128, 1, FALSE).
        Words(STRING(mGame:HiScore), 1, XeviousTint:ZapGlow, XeviousTint:ZapGlow, 144, 1, FALSE).
        IF mGame:Phase <> XeviousPhase:Title THEN DO:
            DO i = 1 TO MINIMUM(8, mGame:Lives - 1):
                Blit(XeviousPicture:MiniLark, 6 + (i - 1) * 10, {&STRIP} + {&FIELD} + 4).
            END.
            WordsRight("AREA " + STRING(mGame:Stage, "99"), XeviousTint:Text, {&STRIP} + {&FIELD} + 4).
        END.
    END METHOD.

    /* Veils over the field for the screens that stop the game: game over and the pause. */
    METHOD PRIVATE VOID DrawVeils():
        IF mGame:Phase = XeviousPhase:Title OR mGame:Phase = XeviousPhase:GameOver THEN RETURN.
        IF mGame:Paused THEN mCanvas:DimRect(0, {&STRIP}, {&WIDTH}, {&FIELD}, 60, Colour(XeviousTint:Strip)).
        ELSE IF mGame:Phase = XeviousPhase:StageClear THEN mCanvas:DimRect(16, 56, 192, 160, 82, Colour(XeviousTint:Strip)).
        ELSE IF mGame:Phase = XeviousPhase:Playing AND mGame:StageAge < 120 THEN DO:
            /* the band of the area start opens from its middle line over 10 frames and closes over the last 10 */
            mCanvas:DimRect(0, 135 - BandHalf(), {&WIDTH}, 2 * BandHalf(), 80, Colour(XeviousTint:Strip)).
        END.
    END METHOD.

    /* Half the height of the area start band at this age: 15 rows once open. */
    METHOD PRIVATE INTEGER BandHalf():
        VAR INTEGER age.
        age = mGame:StageAge.
        IF age < 10 THEN RETURN XeviousMotion:Div(15 * age, 10).
        IF age >= 110 THEN RETURN XeviousMotion:Div(15 * (120 - age), 10).
        RETURN 15.
    END METHOD.

    /* The words of the screens, drawn after the veils so they are not dimmed. */
    METHOD PRIVATE VOID DrawWords():
        CASE mGame:Phase:
            WHEN XeviousPhase:Title THEN DrawTitle().
            WHEN XeviousPhase:GameOver THEN DrawGameOver().
            WHEN XeviousPhase:StageClear THEN DrawBonus().
            WHEN XeviousPhase:Playing THEN DO:
                IF mGame:Paused THEN DrawPause().
                ELSE IF mGame:StageAge < 120 THEN DrawAreaStart().
            END.
        END CASE.
        IF mGame:Paused AND mGame:Phase <> XeviousPhase:Playing AND mGame:Phase <> XeviousPhase:Title THEN DrawPause().
    END METHOD.

    METHOD PRIVATE VOID DrawTitle():
        VAR INTEGER i.
        VAR INTEGER x.
        Words("XEVIOUS", 4, XeviousTint:DawnTop, XeviousTint:DawnLow, -1, 40, TRUE).
        /* three horizon lines, like a sunrise */
        mCanvas:FillRect(37, 84, 150, 1, 0, Colour(XeviousTint:DawnLow)).
        mCanvas:FillRect(57, 87, 110, 1, 0, Colour(XeviousTint:WingMark)).
        mCanvas:FillRect(82, 90, 60, 1, 0, Colour(XeviousTint:DawnTop)).
        /* the roll call: five of the air and five of the ground, with what they are worth (the Anvil's points are a question mark) */
        Words("AIR", 1, XeviousTint:TextDim, XeviousTint:TextDim, 8, 102, FALSE).
        Words("GROUND", 1, XeviousTint:TextDim, XeviousTint:TextDim, 8, 160, FALSE).
        DO i = 0 TO 4:
            x = 20 + i * 40.
            Blit(XeviousBoxes:AirPicture(XeviousAir:GetEnum(CallAir(i))), x, 112).
            Words((IF CallAir(i) = INTEGER(XeviousAir:Bacura) THEN "?" ELSE STRING(XeviousRules:AirPoints(XeviousAir:GetEnum(CallAir(i))))),
                  1, XeviousTint:Signal, XeviousTint:Signal, x, 132, FALSE).
            Blit(XeviousBoxes:GroundPicture(XeviousGround:GetEnum(CallGround(i))), x, 170).
            Words(STRING(XeviousRules:GroundPoints(XeviousGround:GetEnum(CallGround(i)))), 1, XeviousTint:Signal, XeviousTint:Signal, x, 190, FALSE).
        END.
        IF mGame:Frames MODULO 60 < 40 THEN Words("PUSH FIRE", 2, XeviousTint:Text, XeviousTint:Text, -1, 216, TRUE).
        Words("ARROWS FLY  Z ZAP  X BOMB", 1, XeviousTint:TextDim, XeviousTint:TextDim, -1, 244, TRUE).
    END METHOD.

    /* The air enemies of the roll call, as numbers of XeviousAir: Whirl, Skate, Kite, Swift and Anvil. */
    METHOD PRIVATE INTEGER CallAir(INPUT piIndex AS INTEGER):
        RETURN INTEGER(ENTRY(piIndex + 1, "0,1,2,6,7")).
    END METHOD.

    /* The ground targets of the roll call, as numbers of XeviousGround: Barra, Zolbak, Logram, Derota and GaruBarra. */
    METHOD PRIVATE INTEGER CallGround(INPUT piIndex AS INTEGER):
        RETURN INTEGER(ENTRY(piIndex + 1, "0,1,2,3,5")).
    END METHOD.

    METHOD PRIVATE VOID DrawAreaStart():
        VAR INTEGER age.
        VAR INTEGER sweep.
        age = mGame:StageAge.
        IF age < 10 OR age >= 110 THEN RETURN.
        mCanvas:FillRect(0, 120, {&WIDTH}, 1, 0, Colour(XeviousTint:WingMark)).
        mCanvas:FillRect(0, 149, {&WIDTH}, 1, 0, Colour(XeviousTint:WingMark)).
        Words("AREA " + STRING(mGame:Stage), 3, XeviousTint:DawnTop, XeviousTint:DawnLow, -1, 127, TRUE).
        /* a short bar of white runs along the top line left to right and along the bottom line right to left */
        sweep = ((age - 10) * 6) MODULO ({&WIDTH} + 24) - 24.
        mCanvas:FillRect(MAXIMUM(0, sweep), 120, MAXIMUM(0, MINIMUM(24, MINIMUM(sweep + 24, {&WIDTH} - sweep))), 1, 0, Colour(XeviousTint:Flash)).
        mCanvas:FillRect(MAXIMUM(0, {&WIDTH} - sweep - 24), 149, MAXIMUM(0, MINIMUM(24, MINIMUM(sweep + 24, {&WIDTH} - sweep))), 1, 0, Colour(XeviousTint:Flash)).
    END METHOD.

    /* The end of a stage: the targets destroyed light up a square at a time, the percent and the hidden towers found, and the bonus
       that counts up with the squares. */
    METHOD PRIVATE VOID DrawBonus():
        VAR INTEGER total.
        VAR INTEGER lit.
        VAR INTEGER shown.
        VAR INTEGER i.
        total = MINIMUM(48, MAXIMUM(1, mGame:StageGround)).
        lit = MINIMUM(XeviousMotion:Div(mGame:StageKilled * total, MAXIMUM(1, mGame:StageGround)), XeviousMotion:Div(mGame:PhaseFrames, 3)).
        shown = (IF mGame:StageKilled = 0 THEN mGame:StageBonus
                 ELSE XeviousMotion:Div(mGame:StageBonus * lit, MAXIMUM(1, XeviousMotion:Div(mGame:StageKilled * total, MAXIMUM(1, mGame:StageGround))))).
        mCanvas:FillRect(16, 56, 192, 1, 0, Colour(XeviousTint:WingMark)).
        mCanvas:FillRect(16, 215, 192, 1, 0, Colour(XeviousTint:WingMark)).
        Words("AREA " + STRING(mGame:Stage) + " CLEAR", 2, XeviousTint:DawnTop, XeviousTint:DawnLow, -1, 64, TRUE).
        Words("TARGETS", 1, XeviousTint:TextDim, XeviousTint:TextDim, 28, 92, FALSE).
        Words(STRING(mGame:StageKilled) + " OF " + STRING(mGame:StageGround), 1, XeviousTint:Text, XeviousTint:Text, 130, 92, FALSE).
        Words("DESTROYED", 1, XeviousTint:TextDim, XeviousTint:TextDim, 28, 104, FALSE).
        Words(STRING(mGame:StagePercent) + " PCT", 1, XeviousTint:Text, XeviousTint:Text, 130, 104, FALSE).
        Words("SPIRES FOUND", 1, XeviousTint:TextDim, XeviousTint:TextDim, 28, 116, FALSE).
        Words(STRING(mGame:StageSols), 1, XeviousTint:Text, XeviousTint:Text, 130, 116, FALSE).
        DO i = 0 TO total - 1:
            mCanvas:FillRect(28 + (i MODULO 24) * 7, 134 + XeviousMotion:Div(i, 24) * 7, 5, 5, 0,
                             Colour(IF i < lit THEN XeviousTint:Signal ELSE XeviousTint:StoneDark)).
        END.
        Words("BONUS", 2, XeviousTint:Text, XeviousTint:Text, 28, 164, FALSE).
        Words(STRING(shown), 2, XeviousTint:Signal, XeviousTint:Signal, 110, 164, FALSE).
    END METHOD.

    METHOD PRIVATE VOID DrawGameOver():
        Words("GAME OVER", 3, XeviousTint:DawnTop, XeviousTint:DawnLow, -1, 100, TRUE).
        Words("AREA " + STRING(mGame:Stage) + "  " + STRING(mGame:StagePercent) + " PCT", 1, XeviousTint:TextDim, XeviousTint:TextDim, -1, 134, TRUE).
        Words("SCORE " + STRING(mGame:Score), 1, XeviousTint:Text, XeviousTint:Text, -1, 150, TRUE).
        IF mGame:PhaseFrames >= 90 AND mGame:Frames MODULO 60 < 40 THEN Words("PUSH FIRE", 2, XeviousTint:Text, XeviousTint:Text, -1, 176, TRUE).
    END METHOD.

    METHOD PRIVATE VOID DrawPause():
        Words("PAUSED", 3, XeviousTint:Text, XeviousTint:Text, -1, 112, TRUE).
        Words("P TO PLAY ON", 1, XeviousTint:TextDim, XeviousTint:TextDim, -1, 146, TRUE).
    END METHOD.

    /* Every odd row of the picture a little darker: the optional scanlines. */
    METHOD PRIVATE VOID DrawScanlines():
        VAR INTEGER y.
        DO y = 1 TO {&HEIGHT} - 1 BY 2:
            mCanvas:DimRect(0, y, {&WIDTH}, 1, 12, Colour(XeviousTint:Ink)).
        END.
    END METHOD.

    /* Text from a cache of stamps: a colour from poTop at the top of the letters to poBottom, with a dark edge when it is big.
       plCentre puts it in the middle of the picture across, else piX is where it starts. */
    METHOD PRIVATE VOID Words(INPUT pcText AS CHARACTER, INPUT piScale AS INTEGER, INPUT poTop AS XeviousTint, INPUT poBottom AS XeviousTint,
                              INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT plCentre AS LOGICAL):
        VAR TextStamp stamp.
        VAR INTEGER x.
        stamp = mText:Get(pcText, piScale, Colour(poTop), Colour(poBottom), (IF piScale > 1 THEN Colour(XeviousTint:Ink) ELSE -1)).
        x = (IF plCentre THEN INTEGER(TRUNCATE(({&WIDTH} - stamp:Width) / 2, 0)) ELSE piX).
        stamp:DrawTo(mCanvas, x, piY).
    END METHOD.

    /* One line of ordinary text, right aligned 6 cells from the edge. */
    METHOD PRIVATE VOID WordsRight(INPUT pcText AS CHARACTER, INPUT poTint AS XeviousTint, INPUT piY AS INTEGER):
        VAR TextStamp stamp.
        stamp = mText:Get(pcText, 1, Colour(poTint), Colour(poTint), -1).
        stamp:DrawTo(mCanvas, {&WIDTH} - 6 - stamp:Width, piY).
    END METHOD.

END CLASS.
