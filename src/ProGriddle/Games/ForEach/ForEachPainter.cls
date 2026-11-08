/* Draws FOR EACH in the "Night Shift" look (docs/design/foreach-art.md). It reads a ForEachGame, never changes it, and paints the picture on a
   pixel canvas of its own, 224 x 288: a strip of numbers (24 pixels), the maze (28 x 31 tiles of 8 pixels) and a strip of lives and
   items (16 pixels). The canvas is handed to the window's renderer (the inner one), so the game's own grid is left as it is.

   What is kept in the picture's background: the floor, the studs, the walls, the door and the bits of data. A bit eaten is taken off by
   painting its four pixels back to the floor, one tile at a time (the game says which). What is drawn every frame, over the background:
   the commit tokens, the item, the characters (each with its glow), the pop-ups, the words and the strips. The flash after a level
   is a second background, with the lines in white, that is switched to and fro; the title and the cartoons use a third, the plain floor.

   The animations are functions of the game's own clock (FrameCount and the age of the phase), as in the other games, so a test can
   look at any moment. The painter owns canvases and stamps: the owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.ForEachPainter FINAL IMPLEMENTS IGridRenderer:

    /* the picture is 224 pixels across and 24 + 8 * rows + 16 down; the strip above the maze is 24 pixels */
    &SCOPED-DEFINE STRIP 24
    /* which background is showing: the maze, the maze with white lines, or the plain floor */
    &SCOPED-DEFINE BACK-MAZE 1
    &SCOPED-DEFINE BACK-FLASH 2
    &SCOPED-DEFINE BACK-BLANK 3
    /* how a stamp is looked up: ((picture - 1) * 9 + colourRow) + 1, with 0 for the picture's own row */
    &SCOPED-DEFINE ROWS 9

    VAR PRIVATE IGridRenderer mInner.
    VAR PRIVATE ForEachGame mGame.
    VAR PRIVATE MazeMap mMaze.
    VAR PRIVATE Grid mGrid.
    VAR PRIVATE Grid mBaseGrid.
    VAR PRIVATE Grid mFlashGrid.
    VAR PRIVATE Grid mBlankGrid.
    VAR PRIVATE PixelCanvas mCanvas.
    VAR PRIVATE PixelCanvas mBase.
    VAR PRIVATE PixelCanvas mFlash.
    VAR PRIVATE PixelCanvas mBlank.
    VAR PRIVATE TextStampCache mText.
    /* the pictures, made when first needed */
    VAR PRIVATE PixelStamp[600] mStamp.
    VAR PRIVATE ForEachHalo[600] mHalo.
    VAR PRIVATE PixelStamp[16] mDibby.
    VAR PRIVATE ForEachHalo[16] mDibbyHalo.
    VAR PRIVATE PixelStamp[256] mWall.
    VAR PRIVATE PixelStamp[256] mWallFlash.
    VAR PRIVATE PixelStamp[2] mGiant.
    VAR PRIVATE PixelStamp[4] mAngryEyes.
    VAR PRIVATE PixelStamp mFloorTile.
    VAR PRIVATE PixelStamp mTunnelTile.
    VAR PRIVATE PixelStamp mDoorTile.
    VAR PRIVATE PixelStamp mDoorSwap.
    /* the commit tokens' tiles, found when the maze is baked */
    VAR PRIVATE INTEGER[16] mTokenCol.
    VAR PRIVATE INTEGER[16] mTokenRow.
    VAR PRIVATE INTEGER mTokens.
    /* what is showing in the background, and what it was made from */
    VAR PRIVATE INTEGER mShowing.
    VAR PRIVATE INTEGER mSerial = -1.
    VAR PRIVATE INTEGER mEatenSeen.
    VAR PRIVATE LOGICAL mBitsDirty.
    /* how far Dibby has walked, for his mouth, and where he was last */
    VAR PRIVATE INTEGER mTravel.
    VAR PRIVATE INTEGER mLastX.
    VAR PRIVATE INTEGER mLastY.
    VAR PRIVATE INTEGER mWidth.
    VAR PRIVATE INTEGER mHeight.
    VAR PRIVATE LOGICAL mDisposed.
    /* true while the maze is showing, where a character going off one edge comes in at the other (the tunnel); the title and the cartoons do not wrap */
    VAR PRIVATE LOGICAL mWrap.

    /* The canvas the picture is drawn on, and the grid it is on (what the window's renderer is given). */
    DEFINE PUBLIC PROPERTY Canvas AS PixelCanvas NO-UNDO
        GET():
            RETURN mCanvas.
        END GET.

    DEFINE PUBLIC PROPERTY CanvasGrid AS Grid NO-UNDO
        GET():
            RETURN mGrid.
        END GET.

    /* Throws GridException for no renderer or no game. */
    CONSTRUCTOR PUBLIC ForEachPainter(INPUT poInner AS IGridRenderer, INPUT poGame AS ForEachGame):
        IF NOT VALID-OBJECT(poInner) THEN UNDO, THROW NEW GridException("A FOR EACH painter needs a renderer to hand the picture to").
        IF NOT VALID-OBJECT(poGame) THEN UNDO, THROW NEW GridException("A FOR EACH painter needs a game").
        mInner = poInner.
        mGame = poGame.
        mMaze = poGame:Maze.
        mWidth = poGame:Grid:Width.
        mHeight = poGame:Grid:Height.
        mText = NEW TextStampCache(96).
        mGrid = NEW Grid(NEW ArrayStore(mWidth, mHeight, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        BuildBases().
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC ForEachPainter():
        Dispose().
    END DESTRUCTOR.

    /* Draws the game on the canvas and gives the canvas to the window's renderer. Throws GridException for a game that is not a FOR EACH game. */
    METHOD PUBLIC VOID Render(INPUT poGrid AS Grid, INPUT poGame AS IGame):
        IF NOT VALID-OBJECT(poGame) OR NOT TYPE-OF(poGame, ForEachGame) THEN UNDO, THROW NEW GridException("A FOR EACH painter draws a FOR EACH game").
        SyncBackground().
        mWrap = mGame:Phase <> ForEachPhase:Title AND mGame:Phase <> ForEachPhase:Intermission.
        mCanvas:BeginBatch().
        mCanvas:Restore().
        CASE mGame:Phase:
            WHEN ForEachPhase:Title THEN DrawTitle().
            WHEN ForEachPhase:Intermission THEN DrawCartoon().
            OTHERWISE DrawPlay().
        END CASE.
        DrawStrips().
        mCanvas:EndBatch().
        mInner:Render(mGrid, poGame).
    END METHOD.

    /* Frees the canvases and the stamps. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        VAR INTEGER i.
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        DO i = 1 TO EXTENT(mStamp):
            IF VALID-OBJECT(mStamp[i]) THEN mStamp[i]:Dispose().
        END.
        DO i = 1 TO EXTENT(mDibby):
            IF VALID-OBJECT(mDibby[i]) THEN mDibby[i]:Dispose().
        END.
        DO i = 1 TO EXTENT(mWall):
            IF VALID-OBJECT(mWall[i]) THEN mWall[i]:Dispose().
            IF VALID-OBJECT(mWallFlash[i]) THEN mWallFlash[i]:Dispose().
        END.
        DO i = 1 TO EXTENT(mGiant):
            IF VALID-OBJECT(mGiant[i]) THEN mGiant[i]:Dispose().
        END.
        DO i = 1 TO EXTENT(mAngryEyes):
            IF VALID-OBJECT(mAngryEyes[i]) THEN mAngryEyes[i]:Dispose().
        END.
        IF VALID-OBJECT(mFloorTile) THEN mFloorTile:Dispose().
        IF VALID-OBJECT(mTunnelTile) THEN mTunnelTile:Dispose().
        IF VALID-OBJECT(mDoorTile) THEN mDoorTile:Dispose().
        IF VALID-OBJECT(mDoorSwap) THEN mDoorSwap:Dispose().
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        IF VALID-OBJECT(mBase) THEN mBase:Dispose().
        IF VALID-OBJECT(mFlash) THEN mFlash:Dispose().
        IF VALID-OBJECT(mBlank) THEN mBlank:Dispose().
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        IF VALID-OBJECT(mBaseGrid) THEN mBaseGrid:Dispose().
        IF VALID-OBJECT(mFlashGrid) THEN mFlashGrid:Dispose().
        IF VALID-OBJECT(mBlankGrid) THEN mBlankGrid:Dispose().
        IF VALID-OBJECT(mText) THEN mText:Dispose().
    END METHOD.

    /* ================================ colours and small helpers ================================ */

    METHOD PRIVATE INTEGER Tint(INPUT poTint AS ForEachTint):
        RETURN ForEachLook:Colour(poTint).
    END METHOD.

    /* The row of colours of a phantom. */
    METHOD PRIVATE ForEachRow RowOf(INPUT poKind AS PhantomKind):
        CASE poKind:
            WHEN PhantomKind:Mary THEN RETURN ForEachRow:Mary.
            WHEN PhantomKind:Rich THEN RETURN ForEachRow:Rich.
            WHEN PhantomKind:Brian THEN RETURN ForEachRow:Brian.
            OTHERWISE RETURN ForEachRow:Chip.
        END CASE.
    END METHOD.

    /* A picture in its colours as a stamp, made once. poRow is the colour row to take the tones from, or unknown for the picture's own. */
    METHOD PRIVATE PixelStamp StampOf(INPUT poPicture AS ForEachPicture, INPUT poRow AS ForEachRow):
        VAR INTEGER slot.
        slot = (INTEGER(poPicture) - 1) * {&ROWS} + (IF poRow = ? THEN 0 ELSE INTEGER(poRow)) + 1.
        IF NOT VALID-OBJECT(mStamp[slot]) THEN mStamp[slot] = TileOf(poPicture):Colourise(TonesFor(poPicture, poRow), ForEachArt:Legend(poPicture)).
        RETURN mStamp[slot].
    END METHOD.

    /* The glow of a picture, made once, in the colour of its row. */
    METHOD PRIVATE ForEachHalo HaloOf(INPUT poPicture AS ForEachPicture, INPUT poRow AS ForEachRow):
        VAR INTEGER slot.
        slot = (INTEGER(poPicture) - 1) * {&ROWS} + (IF poRow = ? THEN 0 ELSE INTEGER(poRow)) + 1.
        IF NOT VALID-OBJECT(mHalo[slot]) THEN mHalo[slot] = NEW ForEachHalo(TileOf(poPicture)).
        RETURN mHalo[slot].
    END METHOD.

    METHOD PRIVATE Tile TileOf(INPUT poPicture AS ForEachPicture):
        RETURN NEW Tile(ForEachArt:Rows(poPicture)).
    END METHOD.

    /* The five tones for a picture: those of the row given, else those of its own row, else five floor colours (it has none). */
    METHOD PRIVATE CHARACTER TonesFor(INPUT poPicture AS ForEachPicture, INPUT poRow AS ForEachRow):
        VAR ForEachRow colourRow.
        colourRow = (IF poRow <> ? THEN poRow ELSE ForEachArt:ToneRow(poPicture)).
        IF colourRow <> ? THEN RETURN ForEachLook:Tones(colourRow).
        RETURN SUBSTITUTE("&1,&1,&1,&1,&1", ForEachLook:Hex(ForEachTint:Floor)).
    END METHOD.

    /* The colour of a character's glow: its tone 3 mixed most of the way to the floor. */
    METHOD PRIVATE INTEGER GlowOf(INPUT poRow AS ForEachRow):
        RETURN ColourMath:Mix(ForEachLook:Tone(poRow, 3), Tint(ForEachTint:Floor), 72, 100).
    END METHOD.

    /* Draws a picture with its top left at a canvas position, and again a canvas width away on the other side if it goes off an edge
       (a character in the tunnel). */
    METHOD PRIVATE VOID Blit(INPUT poStamp AS PixelStamp, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        poStamp:DrawTo(mCanvas, piX, piY).
        IF NOT mWrap THEN RETURN.
        IF piX < 0 THEN poStamp:DrawTo(mCanvas, piX + mWidth, piY).
        IF piX + poStamp:Width > mWidth THEN poStamp:DrawTo(mCanvas, piX - mWidth, piY).
    END METHOD.

    METHOD PRIVATE VOID BlitHalo(INPUT poHalo AS ForEachHalo, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piColour AS INTEGER):
        VAR INTEGER a.
        VAR INTEGER b.
        VAR INTEGER c.
        ASSIGN a = Tint(ForEachTint:Floor)
               b = Tint(ForEachTint:FloorStud)
               c = Tint(ForEachTint:Tunnel).
        poHalo:DrawTo(mCanvas, piX, piY, piColour, a, b, c).
        IF piX < 0 THEN poHalo:DrawTo(mCanvas, piX + mWidth, piY, piColour, a, b, c).
        IF piX + 16 > mWidth THEN poHalo:DrawTo(mCanvas, piX - mWidth, piY, piColour, a, b, c).
    END METHOD.

    /* Words in one colour. */
    METHOD PRIVATE VOID Say(INPUT pcText AS CHARACTER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT poTint AS ForEachTint):
        mText:Get(pcText, 1, Tint(poTint), Tint(poTint), -1):DrawTo(mCanvas, piX, piY).
    END METHOD.

    /* Words in one colour with their right end at piRight. */
    METHOD PRIVATE VOID SayRight(INPUT pcText AS CHARACTER, INPUT piRight AS INTEGER, INPUT piY AS INTEGER, INPUT poTint AS ForEachTint):
        Say(pcText, piRight + 1 - PixelCanvas:ScaledWidth(pcText, 1), piY, poTint).
    END METHOD.

    /* Words in the middle of the picture. */
    METHOD PRIVATE VOID SayCentred(INPUT pcText AS CHARACTER, INPUT piY AS INTEGER, INPUT poTint AS ForEachTint):
        Say(pcText, INTEGER(TRUNCATE((mWidth - PixelCanvas:ScaledWidth(pcText, 1)) / 2, 0)), piY, poTint).
    END METHOD.

    /* ================================ the backgrounds ================================ */

    /* Builds the three backgrounds: the maze with its bits left to draw, the same with the lines white, and the plain floor. */
    METHOD PRIVATE VOID BuildBases():
        VAR INTEGER cc.
        VAR INTEGER rr.
        mBaseGrid = NEW Grid(NEW ArrayStore(mWidth, mHeight, "view,kind,back")).
        mBlankGrid = NEW Grid(NEW ArrayStore(mWidth, mHeight, "view,kind,back")).
        mBase = NEW PixelCanvas(mBaseGrid).
        mBlank = NEW PixelCanvas(mBlankGrid).
        mFloorTile = NEW Tile("......../......../......../......../......../......../......../........"):Colourise(
            SUBSTITUTE("&1,&1,&1,&1,&1", ForEachLook:Hex(ForEachTint:Floor)), "").
        BuildBlank().
        BuildMazeBase(mBase, FALSE).
        /* the commit tokens' tiles */
        DO rr = 0 TO mMaze:Rows - 1:
            DO cc = 0 TO mMaze:Cols - 1:
                IF mMaze:KindAt(cc, rr) = TileKind:Commit AND mTokens < EXTENT(mTokenCol) THEN DO:
                    mTokens = mTokens + 1.
                    mTokenCol[mTokens] = cc.
                    mTokenRow[mTokens] = rr.
                END.
            END.
        END.
    END METHOD.

    /* The plain floor, which is also the strips above and below the maze. */
    METHOD PRIVATE VOID BuildBlank():
        mBlank:BeginBatch().
        mBlank:FillRect(0, 0, mWidth, mHeight, 0, Tint(ForEachTint:Floor)).
        mBlank:EndBatch().
        mBlank:BakeView().
    END METHOD.

    /* True when a tile counts as wall for the wall rule: a wall or the door. A tile off the maze is taken as the nearest tile on it. */
    METHOD PRIVATE LOGICAL IsWallAt(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        VAR TileKind kind.
        kind = mMaze:KindAt(MAXIMUM(0, MINIMUM(mMaze:Cols - 1, piCol)), MAXIMUM(0, MINIMUM(mMaze:Rows - 1, piRow))).
        RETURN kind = TileKind:Wall OR kind = TileKind:Door.
    END METHOD.

    /* The mask of the eight neighbours of a wall tile (see ForEachArt:WallRows): a corner counts only when both its sides are walls. */
    METHOD PRIVATE INTEGER MaskAt(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        VAR LOGICAL n.
        VAR LOGICAL e.
        VAR LOGICAL s.
        VAR LOGICAL w.
        VAR INTEGER m.
        ASSIGN n = IsWallAt(piCol, piRow - 1)
               e = IsWallAt(piCol + 1, piRow)
               s = IsWallAt(piCol, piRow + 1)
               w = IsWallAt(piCol - 1, piRow).
        IF n THEN m = m + 1.
        IF e THEN m = m + 2.
        IF s THEN m = m + 4.
        IF w THEN m = m + 8.
        IF n AND e AND IsWallAt(piCol + 1, piRow - 1) THEN m = m + 16.
        IF s AND e AND IsWallAt(piCol + 1, piRow + 1) THEN m = m + 32.
        IF s AND w AND IsWallAt(piCol - 1, piRow + 1) THEN m = m + 64.
        IF n AND w AND IsWallAt(piCol - 1, piRow - 1) THEN m = m + 128.
        RETURN m.
    END METHOD.

    /* The picture of a wall tile for a mask, made once: lines on a transparent floor, in the normal colours or with the white of the flash. */
    METHOD PRIVATE PixelStamp WallStamp(INPUT piMask AS INTEGER, INPUT plFlash AS LOGICAL):
        VAR CHARACTER legend.
        IF plFlash THEN DO:
            IF VALID-OBJECT(mWallFlash[piMask + 1]) THEN RETURN mWallFlash[piMask + 1].
            legend = SUBSTITUTE("G=&1,L=&2,A=&3,I=&2,F=&4", ForEachLook:Hex(ForEachTint:FlashGlow), ForEachLook:Hex(ForEachTint:FlashLine),
                                ForEachLook:Hex(ForEachTint:Gap), ForEachLook:Hex(ForEachTint:Fill)).
            mWallFlash[piMask + 1] = NEW Tile(ForEachArt:WallRows(piMask)):Colourise(SUBSTITUTE("&1,&1,&1,&1,&1", ForEachLook:Hex(ForEachTint:Floor)), legend).
            RETURN mWallFlash[piMask + 1].
        END.
        IF VALID-OBJECT(mWall[piMask + 1]) THEN RETURN mWall[piMask + 1].
        legend = SUBSTITUTE("G=&1,L=&2,A=&3,I=&4,F=&5", ForEachLook:Hex(ForEachTint:Glow), ForEachLook:Hex(ForEachTint:Line),
                            ForEachLook:Hex(ForEachTint:Gap), ForEachLook:Hex(ForEachTint:Inner), ForEachLook:Hex(ForEachTint:Fill)).
        mWall[piMask + 1] = NEW Tile(ForEachArt:WallRows(piMask)):Colourise(SUBSTITUTE("&1,&1,&1,&1,&1", ForEachLook:Hex(ForEachTint:Floor)), legend).
        RETURN mWall[piMask + 1].
    END METHOD.

    /* Draws the floor, the walls and the door of the maze on a canvas and keeps them as its background. */
    METHOD PRIVATE VOID BuildMazeBase(INPUT poCanvas AS PixelCanvas, INPUT plFlash AS LOGICAL):
        VAR INTEGER cc.
        VAR INTEGER rr.
        VAR TileKind kind.
        poCanvas:BeginBatch().
        poCanvas:FillRect(0, 0, mWidth, mHeight, 0, Tint(ForEachTint:Floor)).
        DO rr = 0 TO mMaze:Rows - 1:
            DO cc = 0 TO mMaze:Cols - 1:
                kind = mMaze:KindAt(cc, rr).
                IF kind = TileKind:Wall THEN WallStamp(MaskAt(cc, rr), plFlash):DrawTo(poCanvas, cc * 8, {&STRIP} + rr * 8).
                ELSE IF kind = TileKind:Door THEN DrawDoor(poCanvas, cc * 8, {&STRIP} + rr * 8).
                ELSE DO:
                    /* an empty lane: the floor, a shade lighter in the tunnel, with the stud at the top left corner */
                    IF mMaze:IsTunnel(cc, rr) THEN poCanvas:FillRect(cc * 8, {&STRIP} + rr * 8, 8, 8, 0, Tint(ForEachTint:Tunnel)).
                    IF kind <> TileKind:Lobby THEN poCanvas:Plot(cc * 8, {&STRIP} + rr * 8, 0, Tint(ForEachTint:FloorStud)).
                END.
            END.
        END.
        poCanvas:EndBatch().
        poCanvas:BakeView().
    END METHOD.

    /* The door: two rows of hazard stripes, gold and black. */
    METHOD PRIVATE VOID DrawDoor(INPUT poCanvas AS PixelCanvas, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR INTEGER i.
        DO i = 0 TO 7:
            poCanvas:Plot(piX + i, piY + 3, 0, (IF (i MODULO 4) < 2 THEN Tint(ForEachTint:Door) ELSE Tint(ForEachTint:DoorShade))).
            poCanvas:Plot(piX + i, piY + 4, 0, (IF (i MODULO 4) < 2 THEN Tint(ForEachTint:DoorShade) ELSE Tint(ForEachTint:Door))).
        END.
    END METHOD.

    /* Chooses what the background should be for the phase and switches to it, and keeps the bits drawn in it up to date. */
    METHOD PRIVATE VOID SyncBackground():
        VAR INTEGER want.
        VAR INTEGER s.
        VAR INTEGER cc.
        VAR INTEGER rr.
        want = {&BACK-MAZE}.
        CASE mGame:Phase:
            WHEN ForEachPhase:Title OR WHEN ForEachPhase:Intermission THEN want = {&BACK-BLANK}.
            WHEN ForEachPhase:Cleared THEN IF FlashOn() THEN want = {&BACK-FLASH}.
        END CASE.
        IF want <> mShowing THEN DO:
            CASE want:
                WHEN {&BACK-MAZE} THEN mCanvas:LoadBack(mBase).
                WHEN {&BACK-FLASH} THEN DO:
                    IF NOT VALID-OBJECT(mFlash) THEN DO:
                        mFlashGrid = NEW Grid(NEW ArrayStore(mWidth, mHeight, "view,kind,back")).
                        mFlash = NEW PixelCanvas(mFlashGrid).
                        BuildMazeBase(mFlash, TRUE).
                    END.
                    mCanvas:LoadBack(mFlash).
                END.
                OTHERWISE mCanvas:LoadBack(mBlank).
            END CASE.
            mShowing = want.
            mBitsDirty = (want = {&BACK-MAZE}).
        END.
        IF mShowing <> {&BACK-MAZE} THEN DO:
            mEatenSeen = mGame:EatenSerial.
            mSerial = mGame:LevelSerial.
            RETURN.
        END.
        IF mSerial <> mGame:LevelSerial OR mGame:EatenSerial - mEatenSeen > 200 THEN mBitsDirty = TRUE.
        IF mBitsDirty THEN DO:
            /* the maze starts again or the picture has fallen behind: every bit is drawn from the maze */
            DO rr = 0 TO mMaze:Rows - 1:
                DO cc = 0 TO mMaze:Cols - 1:
                    IF mMaze:KindAt(cc, rr) = TileKind:Bit THEN PaintBit(cc, rr, Tint(ForEachTint:Bit)).
                END.
            END.
            ASSIGN mBitsDirty = FALSE
                   mSerial = mGame:LevelSerial
                   mEatenSeen = mGame:EatenSerial.
            RETURN.
        END.
        /* a bit eaten is painted back to the floor */
        DO s = mEatenSeen + 1 TO mGame:EatenSerial:
            PaintBit(mGame:EatenColAt(s), mGame:EatenRowAt(s), Tint(ForEachTint:Floor)).
        END.
        mEatenSeen = mGame:EatenSerial.
    END METHOD.

    /* The 2 x 2 pixels of the bit on a tile, painted into the background in a colour. */
    METHOD PRIVATE VOID PaintBit(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT piColour AS INTEGER):
        VAR INTEGER x.
        VAR INTEGER y.
        DO y = 3 TO 4:
            DO x = 3 TO 4:
                mCanvas:SetBack(piCol * 8 + x, {&STRIP} + piRow * 8 + y, piColour).
            END.
        END.
    END METHOD.

    /* ================================ the flash ================================ */

    /* True when the lines are white at this moment of the end of a level: a second of stillness, then eight swaps 12 frames apart. */
    METHOD PRIVATE LOGICAL FlashOn():
        VAR INTEGER n.
        IF mGame:PhaseAge < 60 THEN RETURN FALSE.
        n = INTEGER(TRUNCATE((mGame:PhaseAge - 60) / 12, 0)).
        RETURN n < 8 AND n MODULO 2 = 0.
    END METHOD.

    /* ================================ the characters ================================ */

    /* Dibby's picture for a mouth (0 closed, 1 half, 2 wide, 3 happy) facing a way: the right-facing picture, mirrored for left and turned for up and down. */
    METHOD PRIVATE PixelStamp DibbyStamp(INPUT piMouth AS INTEGER, INPUT poDir AS MazeDir):
        VAR INTEGER slot.
        VAR ForEachPicture picture.
        VAR Tile tile.
        slot = piMouth * 4 + (IF poDir = MazeDir:Left THEN 1 ELSE IF poDir = MazeDir:Down THEN 2 ELSE IF poDir = MazeDir:Up THEN 3 ELSE 0) + 1.
        IF VALID-OBJECT(mDibby[slot]) THEN RETURN mDibby[slot].
        picture = (IF piMouth = 0 THEN ForEachPicture:DibbyClosed ELSE IF piMouth = 1 THEN ForEachPicture:DibbyHalf
                   ELSE IF piMouth = 2 THEN ForEachPicture:DibbyWide ELSE ForEachPicture:DibbyHappy).
        tile = TileOf(picture).
        CASE poDir:
            WHEN MazeDir:Left THEN tile = Mirrored(tile).
            WHEN MazeDir:Down THEN tile = tile:Turned(1).
            WHEN MazeDir:Up THEN tile = tile:Turned(3).
        END CASE.
        mDibby[slot] = tile:Colourise(ForEachLook:Tones(ForEachRow:Dibby), ForEachArt:Legend(picture)).
        mDibbyHalo[slot] = NEW ForEachHalo(tile).
        RETURN mDibby[slot].
    END METHOD.

    /* A picture the other way round. */
    METHOD PRIVATE Tile Mirrored(INPUT poTile AS Tile):
        VAR INTEGER x.
        VAR INTEGER y.
        VAR CHARACTER rows.
        VAR CHARACTER cells.
        DO y = 0 TO poTile:Height - 1:
            cells = "".
            DO x = poTile:Width - 1 TO 0 BY -1:
                cells = cells + poTile:PixelAt(x, y).
            END.
            rows = rows + (IF y > 0 THEN "/" ELSE "") + cells.
        END.
        RETURN NEW Tile(rows).
    END METHOD.

    /* Draws Dibby at a place in the maze (pixels) with his glow. The mouth is 0 closed, 1 half, 2 wide, 3 happy. */
    METHOD PRIVATE VOID DrawDibbyAt(INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT piMouth AS INTEGER, INPUT poDir AS MazeDir):
        VAR PixelStamp stamp.
        VAR INTEGER slot.
        stamp = DibbyStamp(piMouth, poDir).
        slot = piMouth * 4 + (IF poDir = MazeDir:Left THEN 1 ELSE IF poDir = MazeDir:Down THEN 2 ELSE IF poDir = MazeDir:Up THEN 3 ELSE 0) + 1.
        BlitHalo(mDibbyHalo[slot], piX - 8, {&STRIP} + piY - 8, GlowOf(ForEachRow:Dibby)).
        Blit(stamp, piX - 8, {&STRIP} + piY - 8).
    END METHOD.

    /* Which mouth Dibby has: closed at the start of a level, half when he cannot go on, otherwise one frame for every 2 pixels walked. */
    METHOD PRIVATE INTEGER MouthOf():
        VAR INTEGER moved.
        IF mGame:Phase = ForEachPhase:Ready THEN RETURN 0.
        moved = ABSOLUTE(mGame:DibbyX - mLastX) + ABSOLUTE(mGame:DibbyY - mLastY).
        IF moved < 16 THEN mTravel = mTravel + moved.
        ASSIGN mLastX = mGame:DibbyX
               mLastY = mGame:DibbyY.
        IF NOT mGame:DibbyMoving THEN RETURN 1.
        CASE INTEGER(TRUNCATE(mTravel / 2, 0)) MODULO 4:
            WHEN 0 THEN RETURN 0.
            WHEN 2 THEN RETURN 2.
            OTHERWISE RETURN 1.
        END CASE.
    END METHOD.

    /* A phantom: its glow, its body (the tail swishing), its eyes looking the way it goes, its mark and, for Mary, her anger. Rolled back it is a
       puddle, flashing near the end, and returning it is only a pair of eyes. */
    METHOD PRIVATE VOID DrawPhantom(INPUT poKind AS PhantomKind):
        VAR INTEGER x.
        VAR INTEGER y.
        VAR INTEGER wobble.
        VAR ForEachPicture body.
        VAR ForEachRow colourRow.
        VAR MazeDir dir.
        IF NOT mGame:PhantomPresent(poKind) THEN RETURN.
        ASSIGN x = mGame:PhantomX(poKind) - 8
               y = {&STRIP} + mGame:PhantomY(poKind) - 8
               dir = mGame:PhantomDir(poKind)
               wobble = INTEGER(TRUNCATE(mGame:FrameCount / 8, 0)) MODULO 2.
        CASE mGame:ModeOf(poKind):
            WHEN PhantomMode:Returning THEN DO:
                Blit(StampOf(ReturningPicture(dir), ?), x, y).
                RETURN.
            END.
            WHEN PhantomMode:RolledBack THEN DO:
                /* in the last two seconds it flips between the puddle and the white one every 125 ms */
                IF mGame:RollbackFramesLeft <= 120 AND ForEachRules:FlashCount(mGame:Level) > 0 AND INTEGER(TRUNCATE(mGame:RollbackFramesLeft / 8, 0)) MODULO 2 = 0 THEN
                    ASSIGN body = (IF wobble = 0 THEN ForEachPicture:Flash1 ELSE ForEachPicture:Flash2)
                           colourRow = ForEachRow:Flash.
                ELSE
                    ASSIGN body = (IF wobble = 0 THEN ForEachPicture:Rolledback1 ELSE ForEachPicture:Rolledback2)
                           colourRow = ForEachRow:Rollback.
                BlitHalo(HaloOf(body, ?), x, y, GlowOf(colourRow)).
                Blit(StampOf(body, ?), x, y).
                RETURN.
            END.
        END CASE.
        colourRow = RowOf(poKind).
        body = (IF wobble = 0 THEN ForEachPicture:PhantomBody1 ELSE ForEachPicture:PhantomBody2).
        BlitHalo(HaloOf(body, colourRow), x, y, GlowOf(colourRow)).
        Blit(StampOf(body, colourRow), x, y).
        IF poKind = PhantomKind:Mary AND mGame:RageStage = 2 THEN Blit(AngryEyes(dir), x, y).
        ELSE Blit(StampOf(EyesPicture(dir), ?), x, y).
        Blit(StampOf(MarkPicture(poKind), ?), x, y).
        IF poKind = PhantomKind:Mary AND mGame:RageStage > 0 THEN
            Blit(StampOf((IF mGame:RageStage = 1 THEN ForEachPicture:MaryAngry1 ELSE ForEachPicture:MaryAngry2), ?), x, y).
    END METHOD.

    METHOD PRIVATE ForEachPicture EyesPicture(INPUT poDir AS MazeDir):
        CASE poDir:
            WHEN MazeDir:Left THEN RETURN ForEachPicture:PhantomEyesLeft.
            WHEN MazeDir:Up THEN RETURN ForEachPicture:PhantomEyesUp.
            WHEN MazeDir:Down THEN RETURN ForEachPicture:PhantomEyesDown.
            OTHERWISE RETURN ForEachPicture:PhantomEyesRight.
        END CASE.
    END METHOD.

    METHOD PRIVATE ForEachPicture ReturningPicture(INPUT poDir AS MazeDir):
        CASE poDir:
            WHEN MazeDir:Left THEN RETURN ForEachPicture:ReturningLeft.
            WHEN MazeDir:Up THEN RETURN ForEachPicture:ReturningUp.
            WHEN MazeDir:Down THEN RETURN ForEachPicture:ReturningDown.
            OTHERWISE RETURN ForEachPicture:ReturningRight.
        END CASE.
    END METHOD.

    METHOD PRIVATE ForEachPicture MarkPicture(INPUT poKind AS PhantomKind):
        CASE poKind:
            WHEN PhantomKind:Mary THEN RETURN ForEachPicture:MarkMary.
            WHEN PhantomKind:Rich THEN RETURN ForEachPicture:MarkRich.
            WHEN PhantomKind:Brian THEN RETURN ForEachPicture:MarkBrian.
            OTHERWISE RETURN ForEachPicture:MarkChip.
        END CASE.
    END METHOD.

    /* Mary's eyes in her second stage of anger: the pupils are red. */
    METHOD PRIVATE PixelStamp AngryEyes(INPUT poDir AS MazeDir):
        VAR INTEGER i.
        VAR ForEachPicture picture.
        i = INTEGER(poDir).
        IF VALID-OBJECT(mAngryEyes[i]) THEN RETURN mAngryEyes[i].
        picture = EyesPicture(poDir).
        mAngryEyes[i] = TileOf(picture):Colourise(SUBSTITUTE("&1,&1,&1,&1,&1", ForEachLook:Hex(ForEachTint:Floor)),
                                                  REPLACE(ForEachArt:Legend(picture), ForEachLook:Hex(ForEachTint:Pupil), ForEachLook:Hex(ForEachTint:Angry))).
        RETURN mAngryEyes[i].
    END METHOD.

    /* ================================ playing ================================ */

    /* Everything over the maze while the maze is showing. */
    METHOD PRIVATE VOID DrawPlay():
        VAR INTEGER i.
        VAR LOGICAL showUp.
        DrawCommits().
        showUp = TRUE.
        CASE mGame:Phase:
            WHEN ForEachPhase:Ready THEN showUp = mGame:ReadyLength <= 60 OR mGame:PhaseAge >= 120.
            WHEN ForEachPhase:Cleared OR WHEN ForEachPhase:GameOver THEN showUp = FALSE.
        END CASE.
        IF mGame:ItemActive AND mGame:Phase = ForEachPhase:Playing THEN DrawItem().
        CASE mGame:Phase:
            WHEN ForEachPhase:Dying THEN DrawCrash().
            WHEN ForEachPhase:Cleared THEN DO:
                /* the maze flashes with Dibby standing in it, and smiling on the last white flash */
                DrawDibbyAt(mGame:DibbyX, mGame:DibbyY, (IF FlashOn() AND mGame:PhaseAge >= 60 + 6 * 12 THEN 3 ELSE 1), mGame:DibbyDir).
            END.
            OTHERWISE DO:
                IF showUp THEN DO:
                    IF mGame:Phase <> ForEachPhase:Caught THEN DO:
                        DrawPhantom(PhantomKind:Brian).
                        DrawPhantom(PhantomKind:Chip).
                        DrawPhantom(PhantomKind:Rich).
                        DrawPhantom(PhantomKind:Mary).
                    END.
                    DrawDibbyAt(mGame:DibbyX, mGame:DibbyY, MouthOf(), mGame:DibbyDir).
                END.
            END.
        END CASE.
        IF mGame:ShowTargets AND mGame:Phase = ForEachPhase:Playing THEN
            DO i = 1 TO 4:
                DrawTarget(PhantomKind:GetEnum(i)).
            END.
        IF mGame:PopupFramesLeft > 0 AND mGame:Phase = ForEachPhase:Playing THEN DrawPopup().
        DrawBanner().
    END METHOD.

    /* The commit tokens, which flashing: lit for 10 frames and dim for 10. */
    METHOD PRIVATE VOID DrawCommits():
        VAR INTEGER i.
        DO i = 1 TO mTokens:
            IF mMaze:KindAt(mTokenCol[i], mTokenRow[i]) = TileKind:Commit THEN
                StampOf((IF INTEGER(TRUNCATE(mGame:FrameCount / 10, 0)) MODULO 2 = 0 THEN ForEachPicture:CommitOn ELSE ForEachPicture:CommitDim), ?):DrawTo(
                    mCanvas, mTokenCol[i] * 8 + 1, {&STRIP} + mTokenRow[i] * 8 + 1).
        END.
    END METHOD.

    /* The bonus item under the lobby, a pixel higher for 8 frames in every 32. */
    METHOD PRIVATE VOID DrawItem():
        Blit(StampOf(ItemPicture(mGame:ItemOnShow), ?), mGame:ItemX - 8, {&STRIP} + mGame:ItemY - 8 - (IF mGame:FrameCount MODULO 32 < 8 THEN 1 ELSE 0)).
    END METHOD.

    METHOD PRIVATE ForEachPicture ItemPicture(INPUT poItem AS ItemKind):
        CASE poItem:
            WHEN ItemKind:Floppy THEN RETURN ForEachPicture:ItemFloppy.
            WHEN ItemKind:Tape THEN RETURN ForEachPicture:ItemTape.
            WHEN ItemKind:Key THEN RETURN ForEachPicture:ItemKey.
            WHEN ItemKind:Table THEN RETURN ForEachPicture:ItemTable.
            WHEN ItemKind:Query THEN RETURN ForEachPicture:ItemQuery.
            WHEN ItemKind:Trigger THEN RETURN ForEachPicture:ItemTrigger.
            WHEN ItemKind:Lock THEN RETURN ForEachPicture:ItemLock.
            OTHERWISE RETURN ForEachPicture:ItemServer.
        END CASE.
    END METHOD.

    /* The crash: a second standing still, then eleven frames of 8 game frames, then two of the pop. */
    METHOD PRIVATE VOID DrawCrash():
        VAR INTEGER n.
        n = mGame:PhaseAge.
        IF n < 88 THEN
            Blit(StampOf(CrashPicture(INTEGER(TRUNCATE(n / 8, 0)) + 1), ?), mGame:DibbyX - 8, {&STRIP} + mGame:DibbyY - 8).
        ELSE IF n < 94 THEN Blit(StampOf(ForEachPicture:CrashPop1, ?), mGame:DibbyX - 8, {&STRIP} + mGame:DibbyY - 8).
        ELSE IF n < 100 THEN Blit(StampOf(ForEachPicture:CrashPop2, ?), mGame:DibbyX - 8, {&STRIP} + mGame:DibbyY - 8).
    END METHOD.

    METHOD PRIVATE ForEachPicture CrashPicture(INPUT piStep AS INTEGER):
        RETURN ForEachPicture:GetEnum(INTEGER(ForEachPicture:Crash1) + MINIMUM(10, MAXIMUM(0, piStep - 1))).
    END METHOD.

    /* The points just earned, in 3 x 5 digits, where the phantom or the item was, and a pixel higher for the first 6 frames. */
    METHOD PRIVATE VOID DrawPopup():
        VAR ForEachPicture picture.
        VAR PixelStamp stamp.
        VAR INTEGER x.
        VAR INTEGER age.
        picture = PopupPicture(mGame:PopupPoints, mGame:PopupIsItem).
        stamp = StampOf(picture, ?).
        age = (IF mGame:PopupIsItem THEN 120 ELSE 60) - mGame:PopupFramesLeft.
        x = MAXIMUM(0, MINIMUM(mWidth - stamp:Width, mGame:PopupX - ForEachArt:OriginX(picture))).
        stamp:DrawTo(mCanvas, x, {&STRIP} + mGame:PopupY - ForEachArt:OriginY(picture) - (IF age < 6 THEN 1 ELSE 0)).
    END METHOD.

    METHOD PRIVATE ForEachPicture PopupPicture(INPUT piPoints AS INTEGER, INPUT plItem AS LOGICAL):
        CASE piPoints:
            WHEN 200 THEN RETURN ForEachPicture:Pop200.
            WHEN 400 THEN RETURN ForEachPicture:Pop400.
            WHEN 800 THEN RETURN ForEachPicture:Pop800.
            WHEN 1600 THEN RETURN ForEachPicture:Pop1600.
            WHEN 100 THEN RETURN ForEachPicture:Pop100Item.
            WHEN 300 THEN RETURN ForEachPicture:Pop300Item.
            WHEN 500 THEN RETURN ForEachPicture:Pop500Item.
            WHEN 700 THEN RETURN ForEachPicture:Pop700Item.
            WHEN 1000 THEN RETURN ForEachPicture:Pop1000Item.
            WHEN 2000 THEN RETURN ForEachPicture:Pop2000Item.
            WHEN 3000 THEN RETURN ForEachPicture:Pop3000Item.
            OTHERWISE RETURN ForEachPicture:Pop5000Item.
        END CASE.
    END METHOD.

    /* The debug overlay: a cross at the tile each phantom is heading for, in its colour. */
    METHOD PRIVATE VOID DrawTarget(INPUT poKind AS PhantomKind):
        VAR INTEGER tc.
        VAR INTEGER rw.
        IF NOT mGame:PhantomPresent(poKind) THEN RETURN.
        tc = mGame:PhantomTargetCol(poKind).
        rw = mGame:PhantomTargetRow(poKind).
        IF tc = ? OR rw = ? THEN RETURN.
        StampOf(ForEachPicture:Target, RowOf(poKind)):DrawTo(mCanvas, tc * 8 + 4 - 2, {&STRIP} + rw * 8 + 4 - 2).
    END METHOD.

    /* READY!, PLAYER ONE, GAME OVER and PAUSED, in the lane under the lobby. */
    METHOD PRIVATE VOID DrawBanner():
        VAR LOGICAL flashing.
        flashing = INTEGER(TRUNCATE(mGame:FrameCount / 32, 0)) MODULO 2 = 0.
        IF mGame:Paused AND mGame:Phase <> ForEachPhase:GameOver AND mGame:Phase <> ForEachPhase:Title THEN DO:
            IF flashing THEN SayCentred("PAUSED", {&STRIP} + 136, ForEachTint:Player).
            RETURN.
        END.
        CASE mGame:Phase:
            WHEN ForEachPhase:Ready THEN DO:
                IF mGame:ReadyLength > 60 AND mGame:PhaseAge < 72 THEN RETURN.
                IF mGame:ReadyLength > 60 AND mGame:PhaseAge < 120 THEN SayCentred("PLAYER ONE", {&STRIP} + 88, ForEachTint:PopPhantom).
                SayCentred("READY!", {&STRIP} + 136, ForEachTint:Player).
            END.
            WHEN ForEachPhase:GameOver THEN DO:
                IF mGame:NewHiScore AND mGame:PhaseAge >= 90 THEN SayCentred("NEW HIGH SCORE", {&STRIP} + 136, ForEachTint:Player).
                ELSE SayCentred("GAME OVER", {&STRIP} + 136, ForEachTint:Over).
            END.
        END CASE.
    END METHOD.

    /* ================================ the strips ================================ */

    /* The score above the maze and the lives and items below it. */
    METHOD PRIVATE VOID DrawStrips():
        VAR INTEGER i.
        VAR INTEGER spare.
        VAR LOGICAL lit.
        /* 1UP blinks while a game is on and stays lit when it is over */
        lit = mGame:Phase = ForEachPhase:GameOver OR INTEGER(TRUNCATE(mGame:FrameCount / 16, 0)) MODULO 2 = 0.
        IF mGame:Phase <> ForEachPhase:Title AND lit THEN Say("1UP", 24, 1, ForEachTint:Player).
        SayRight(IF mGame:Phase = ForEachPhase:Title THEN "00" ELSE STRING(mGame:Score), 63, 9, ForEachTint:Text).
        Say("HIGH SCORE", 82, 1, (IF mGame:NewHiScore AND mGame:Phase <> ForEachPhase:Title THEN ForEachTint:Player ELSE ForEachTint:LabelText)).
        SayRight(STRING(mGame:HiScore), 136, 9, ForEachTint:Text).
        IF mGame:Phase = ForEachPhase:Title THEN RETURN.
        /* the spare lives, 14 pixels apart, up to five */
        spare = MINIMUM(5, MAXIMUM(0, mGame:Lives - 1)).
        DO i = 0 TO spare - 1:
            Blit(StampOf(ForEachPicture:DibbyLife, ?), 22 - 6 + i * 14, 279 - 6).
        END.
        /* the items of the last seven levels, the newest on the right */
        DO i = 0 TO 6:
            IF mGame:Level - i >= 1 THEN Blit(StampOf(ItemPicture(ForEachRules:ItemFor(mGame:Level - i)), ?), 200 - 16 * i - 8, 280 - 8).
        END.
    END METHOD.

    /* ================================ the title ================================ */

    /* The title screen: the name, the giant Dibby, the roll call of the phantoms one by one, the points, and the chase. It plays round every 20 seconds. */
    METHOD PRIVATE VOID DrawTitle():
        VAR INTEGER t.
        t = mGame:PhaseAge MODULO 1200.
        DrawLogo().
        DrawGiant(t).
        DrawRollCall(t).
        IF t >= 390 THEN DrawPoints().
        IF t >= 450 THEN DrawChase(t - 450).
        IF INTEGER(TRUNCATE(mGame:FrameCount / 32, 0)) MODULO 2 = 0 THEN SayCentred("PUSH START", 268, ForEachTint:Player).
        Say("CREDIT  0", 4, 280, ForEachTint:LabelText).
    END METHOD.

    /* FOR and EACH in big letters, shaded from yellow to orange with a black edge. */
    METHOD PRIVATE VOID DrawLogo():
        VAR TextStamp stamp.
        stamp = mText:Get("FOR", 3, Tint(ForEachTint:TitleTop), Tint(ForEachTint:TitleBottom), Tint(ForEachTint:Outline)).
        stamp:DrawTo(mCanvas, INTEGER(TRUNCATE((mWidth - PixelCanvas:ScaledWidth("FOR", 3)) / 2, 0)), 30).
        stamp = mText:Get("EACH", 3, Tint(ForEachTint:TitleTop), Tint(ForEachTint:TitleBottom), Tint(ForEachTint:Outline)).
        stamp:DrawTo(mCanvas, INTEGER(TRUNCATE((mWidth - PixelCanvas:ScaledWidth("EACH", 3)) / 2, 0)), 56).
    END METHOD.

    /* The giant Dibby beside the name: the half frame and the closed frame at twice the size, every 16 frames. */
    METHOD PRIVATE VOID DrawGiant(INPUT piAge AS INTEGER):
        VAR INTEGER i.
        i = INTEGER(TRUNCATE(piAge / 16, 0)) MODULO 2.
        IF NOT VALID-OBJECT(mGiant[i + 1]) THEN
            mGiant[i + 1] = (IF i = 0 THEN TileOf(ForEachPicture:DibbyGiant):Colourise(ForEachLook:Tones(ForEachRow:Dibby), ForEachArt:Legend(ForEachPicture:DibbyGiant))
                             ELSE Doubled(ForEachPicture:DibbyClosed):Colourise(ForEachLook:Tones(ForEachRow:Dibby), ForEachArt:Legend(ForEachPicture:DibbyClosed))).
        mGiant[i + 1]:DrawTo(mCanvas, 186 - 16, 54 - 16).
    END METHOD.

    /* A picture at twice the size. */
    METHOD PRIVATE Tile Doubled(INPUT poPicture AS ForEachPicture):
        VAR Tile tile.
        VAR INTEGER x.
        VAR INTEGER y.
        VAR CHARACTER rows.
        VAR CHARACTER cells.
        VAR CHARACTER ch.
        tile = TileOf(poPicture).
        DO y = 0 TO tile:Height - 1:
            cells = "".
            DO x = 0 TO tile:Width - 1:
                ch = tile:PixelAt(x, y).
                cells = cells + ch + ch.
            END.
            rows = rows + (IF y > 0 THEN "/" ELSE "") + cells + "/" + cells.
        END.
        RETURN NEW Tile(rows).
    END METHOD.

    /* The roll call: PHANTOM, NAME and STYLE, then each phantom in turn, its picture, 30 frames later its name and 30 later its style. */
    METHOD PRIVATE VOID DrawRollCall(INPUT piAge AS INTEGER):
        VAR INTEGER i.
        VAR INTEGER start.
        VAR PhantomKind kind.
        IF piAge >= 60 THEN DO:
            Say("PHANTOM", 34, 92, ForEachTint:LabelText).
            Say("NAME", 98, 92, ForEachTint:LabelText).
            Say("STYLE", 148, 92, ForEachTint:LabelText).
        END.
        DO i = 0 TO 3:
            start = 90 + i * 60.
            IF piAge < start THEN LEAVE.
            kind = PhantomKind:GetEnum(i + 1).
            DrawRollPhantom(kind, 26, 111 + 22 * i).
            IF piAge >= start + 30 THEN SayRow(NameOf(kind), 98, 108 + 22 * i, kind).
            IF piAge >= start + 60 OR (i = 3 AND piAge >= start + 30) THEN SayRow(StyleOf(kind), 148, 108 + 22 * i, kind).
        END.
    END METHOD.

    /* A phantom of the roll call: its body, eyes looking right, and its mark. */
    METHOD PRIVATE VOID DrawRollPhantom(INPUT poKind AS PhantomKind, INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        VAR ForEachRow colourRow.
        colourRow = RowOf(poKind).
        Blit(StampOf(ForEachPicture:PhantomBody1, colourRow), piX - 8, piY - 8).
        Blit(StampOf(ForEachPicture:PhantomEyesRight, ?), piX - 8, piY - 8).
        Blit(StampOf(MarkPicture(poKind), ?), piX - 8, piY - 8).
    END METHOD.

    /* Words in the second tone of a phantom's colour row. */
    METHOD PRIVATE VOID SayRow(INPUT pcText AS CHARACTER, INPUT piX AS INTEGER, INPUT piY AS INTEGER, INPUT poKind AS PhantomKind):
        VAR INTEGER c.
        c = ForEachLook:Tone(RowOf(poKind), 2).
        mText:Get(pcText, 1, c, c, -1):DrawTo(mCanvas, piX, piY).
    END METHOD.

    METHOD PRIVATE CHARACTER NameOf(INPUT poKind AS PhantomKind):
        CASE poKind:
            WHEN PhantomKind:Mary THEN RETURN "MARY".
            WHEN PhantomKind:Rich THEN RETURN "RICH".
            WHEN PhantomKind:Brian THEN RETURN "BRIAN".
            OTHERWISE RETURN "CHIP".
        END CASE.
    END METHOD.

    METHOD PRIVATE CHARACTER StyleOf(INPUT poKind AS PhantomKind):
        CASE poKind:
            WHEN PhantomKind:Mary THEN RETURN "CHASER".
            WHEN PhantomKind:Rich THEN RETURN "AMBUSH".
            WHEN PhantomKind:Brian THEN RETURN "FICKLE".
            OTHERWISE RETURN "SHY".
        END CASE.
    END METHOD.

    /* What a bit and a commit token are worth. */
    METHOD PRIVATE VOID DrawPoints():
        mCanvas:FillRect(77, 202, 2, 2, 0, Tint(ForEachTint:Bit)).
        Say("10 PTS", 90, 200, ForEachTint:Text).
        StampOf(ForEachPicture:CommitOn, ?):DrawTo(mCanvas, 78 - 3, 215 - 3).
        Say("50 PTS", 90, 212, ForEachTint:Text).
    END METHOD.

    /* The chase on the lane at the bottom: Dibby runs in, eats a commit token, and the four phantoms, which came the other way, are rolled back
       and run; he eats them one by one, for 200, 400, 800 and 1600. piAge counts from the start of the chase. */
    METHOD PRIVATE VOID DrawChase(INPUT piAge AS INTEGER):
        VAR DECIMAL dibbyX.
        VAR DECIMAL eatAt.
        VAR INTEGER i.
        VAR DECIMAL px.
        VAR DECIMAL x0.
        VAR DECIMAL caught.
        VAR PhantomKind kind.
        dibbyX = -16 + 1.4 * piAge.
        eatAt = (60 + 16) / 1.4.
        IF dibbyX < 60 THEN StampOf(ForEachPicture:CommitOn, ?):DrawTo(mCanvas, 60 - 3, 248 - 3).
        DO i = 0 TO 3:
            kind = PhantomKind:GetEnum(i + 1).
            x0 = 250 + 18 * i - 1.2 * eatAt.
            IF piAge < eatAt THEN DO:
                px = 250 + 18 * i - 1.2 * piAge.
                DrawChasePhantom(kind, INTEGER(px), MazeDir:Left, FALSE).
            END.
            ELSE DO:
                /* he catches it when he has run up to it */
                caught = (x0 - 1.0 * eatAt - 6 + 16) / (1.4 - 1.0).
                px = x0 + 1.0 * (piAge - eatAt).
                IF piAge < caught THEN DrawChasePhantom(kind, INTEGER(px), MazeDir:Right, TRUE).
                ELSE IF piAge < caught + 30 THEN DO:
                    DrawChasePop(INTEGER(px), i).
                END.
            END.
        END.
        IF dibbyX < 240 THEN Blit(StampOf(ForEachPicture:DibbyHalf, ForEachRow:Dibby), INTEGER(dibbyX) - 8, 248 - 8).
    END METHOD.

    METHOD PRIVATE VOID DrawChasePhantom(INPUT poKind AS PhantomKind, INPUT piX AS INTEGER, INPUT poDir AS MazeDir, INPUT plRolledBack AS LOGICAL):
        VAR INTEGER wobble.
        wobble = INTEGER(TRUNCATE(mGame:FrameCount / 8, 0)) MODULO 2.
        IF plRolledBack THEN
            Blit(StampOf((IF wobble = 0 THEN ForEachPicture:Rolledback1 ELSE ForEachPicture:Rolledback2), ?), piX - 8, 248 - 8).
        ELSE DO:
            Blit(StampOf((IF wobble = 0 THEN ForEachPicture:PhantomBody1 ELSE ForEachPicture:PhantomBody2), RowOf(poKind)), piX - 8, 248 - 8).
            Blit(StampOf(EyesPicture(poDir), ?), piX - 8, 248 - 8).
            Blit(StampOf(MarkPicture(poKind), ?), piX - 8, 248 - 8).
        END.
    END METHOD.

    METHOD PRIVATE VOID DrawChasePop(INPUT piX AS INTEGER, INPUT piNth AS INTEGER):
        VAR ForEachPicture picture.
        picture = PopupPicture(ForEachRules:PhantomPoints(piNth + 1), FALSE).
        StampOf(picture, ?):DrawTo(mCanvas, MAXIMUM(0, MINIMUM(mWidth - 17, piX - ForEachArt:OriginX(picture))), 248 - ForEachArt:OriginY(picture)).
    END METHOD.

    /* ================================ the cartoons ================================ */

    /* The cartoon between levels, on the plain floor along the lane at y 160, about five seconds. Three small stories (see section 5.3 of the design). */
    METHOD PRIVATE VOID DrawCartoon():
        VAR INTEGER t.
        t = mGame:PhaseAge.
        CASE mGame:IntermissionAct:
            WHEN 1 THEN DrawDeadlock(t).
            WHEN 2 THEN DrawRollbackStory(t).
            OTHERWISE DrawNightBatch(t).
        END CASE.
    END METHOD.

    /* A phantom on the cartoon lane, rolled back or in its colours, facing a way. */
    METHOD PRIVATE VOID CartoonPhantom(INPUT poKind AS PhantomKind, INPUT piX AS INTEGER, INPUT poDir AS MazeDir, INPUT plRolledBack AS LOGICAL):
        VAR INTEGER wobble.
        wobble = INTEGER(TRUNCATE(mGame:FrameCount / 8, 0)) MODULO 2.
        IF plRolledBack THEN
            Blit(StampOf((IF wobble = 0 THEN ForEachPicture:Rolledback1 ELSE ForEachPicture:Rolledback2), ?), piX - 8, 160 - 8).
        ELSE DO:
            Blit(StampOf((IF wobble = 0 THEN ForEachPicture:PhantomBody1 ELSE ForEachPicture:PhantomBody2), RowOf(poKind)), piX - 8, 160 - 8).
            Blit(StampOf(EyesPicture(poDir), ?), piX - 8, 160 - 8).
            Blit(StampOf(MarkPicture(poKind), ?), piX - 8, 160 - 8).
        END.
    END METHOD.

    METHOD PRIVATE VOID CartoonDibby(INPUT piX AS INTEGER, INPUT piMouth AS INTEGER, INPUT poDir AS MazeDir):
        Blit(StampOf(ForEachPicture:DibbyHalf, ForEachRow:Dibby), piX - 8, 160 - 8).
        IF piMouth <> 1 THEN Blit(DibbyStamp(piMouth, poDir), piX - 8, 160 - 8).
    END METHOD.

    /* DEADLOCK: Mary chases Dibby in from the left, Rich comes the other way, Dibby is squashed between them and they bonk heads, a lock appears
       over them and they are stuck. Dibby trots off. */
    METHOD PRIVATE VOID DrawDeadlock(INPUT piAge AS INTEGER):
        VAR INTEGER x.
        IF piAge < 90 THEN DO:
            x = INTEGER(-10 + 1.3 * piAge).
            CartoonPhantom(PhantomKind:Mary, x - 28, MazeDir:Right, FALSE).
            CartoonPhantom(PhantomKind:Rich, 234 - INTEGER(1.3 * piAge), MazeDir:Left, FALSE).
            Blit(DibbyStamp(INTEGER(TRUNCATE(piAge / 4, 0)) MODULO 3, MazeDir:Right), x - 8, 160 - 8).
            RETURN.
        END.
        IF piAge < 230 THEN DO:
            Blit(StampOf(ForEachPicture:Crash5, ?), 112 - 8, 160 - 8 + 2).
            CartoonPhantom(PhantomKind:Mary, 112 - 14, MazeDir:Right, FALSE).
            CartoonPhantom(PhantomKind:Rich, 112 + 14, MazeDir:Left, FALSE).
            Blit(StampOf(ForEachPicture:Stars, ?), 112 - 6, 160 - 8 - 6 - 2).
            IF piAge >= 130 THEN Blit(StampOf(ForEachPicture:ItemLock, ?), 112 - 8, 160 - 8 - 22).
            RETURN.
        END.
        x = 112 + INTEGER(1.5 * (piAge - 230)).
        CartoonPhantom(PhantomKind:Mary, 112 - 14, MazeDir:Right, FALSE).
        CartoonPhantom(PhantomKind:Rich, 112 + 14, MazeDir:Left, FALSE).
        Blit(StampOf(ForEachPicture:ItemLock, ?), 112 - 8, 160 - 8 - 22).
        Blit(DibbyStamp(3, MazeDir:Right), x - 8, 160 - 8).
    END METHOD.

    /* ROLLBACK: Brian chases Dibby, who turns and says UNDO, and Brian is played backwards, twice, with rewind marks behind him. */
    METHOD PRIVATE VOID DrawRollbackStory(INPUT piAge AS INTEGER):
        VAR INTEGER x.
        IF piAge < 100 THEN DO:
            x = INTEGER(-10 + 1.3 * piAge).
            CartoonPhantom(PhantomKind:Brian, x - 28, MazeDir:Right, FALSE).
            Blit(DibbyStamp(INTEGER(TRUNCATE(piAge / 4, 0)) MODULO 3, MazeDir:Right), x - 8, 160 - 8).
            RETURN.
        END.
        x = INTEGER(-10 + 1.3 * 100).
        Blit(DibbyStamp(1, MazeDir:Left), x - 8, 160 - 8).
        IF piAge < 240 THEN DO:
            Say("UNDO", x - 12, 160 - 20, ForEachTint:Player).
            /* Brian runs backwards to the left, with the rewind marks behind him, back in again, and is rewound again */
            x = x - 28 - INTEGER(MINIMUM(1.8 * (piAge - 100), 160)).
            IF x > -16 THEN DO:
                CartoonPhantom(PhantomKind:Brian, x, MazeDir:Right, FALSE).
                Blit(StampOf(ForEachPicture:Rewind, ?), x + 12, 160 - 2).
            END.
            RETURN.
        END.
        Blit(DibbyStamp(INTEGER(TRUNCATE(piAge / 4, 0)) MODULO 3, MazeDir:Left), INTEGER(130 - 1.2 * (piAge - 240)) - 8, 160 - 8).
    END METHOD.

    /* NIGHT BATCH: Chip drifts in asleep, the others race in after Dibby and pile into him, and when they get up they are rolled back and Chip is still asleep. */
    METHOD PRIVATE VOID DrawNightBatch(INPUT piAge AS INTEGER):
        VAR INTEGER x.
        IF piAge < 80 THEN DO:
            CartoonPhantom(PhantomKind:Chip, INTEGER(-10 + 3 * piAge) - 60, MazeDir:Right, FALSE).
            Blit(StampOf(ForEachPicture:Zz, ?), INTEGER(-10 + 3 * piAge) - 60, 160 - 24).
            RETURN.
        END.
        x = 112.
        IF piAge < 150 THEN DO:
            CartoonPhantom(PhantomKind:Chip, 112, MazeDir:Right, FALSE).
            Blit(StampOf(ForEachPicture:Zz, ?), 112, 160 - 24).
            Blit(DibbyStamp(INTEGER(TRUNCATE(piAge / 4, 0)) MODULO 3, MazeDir:Right), INTEGER(-10 + 3 * (piAge - 80)) - 8, 160 - 8).
            CartoonPhantom(PhantomKind:Mary, INTEGER(-40 + 3.2 * (piAge - 80)), MazeDir:Right, FALSE).
            CartoonPhantom(PhantomKind:Rich, INTEGER(-60 + 3.2 * (piAge - 80)), MazeDir:Right, FALSE).
            CartoonPhantom(PhantomKind:Brian, INTEGER(-80 + 3.2 * (piAge - 80)), MazeDir:Right, FALSE).
            RETURN.
        END.
        Blit(StampOf(ForEachPicture:Crash5, ?), x - 8, 160 - 8 + 2).
        CartoonPhantom(PhantomKind:Chip, x, MazeDir:Right, FALSE).
        Blit(StampOf(ForEachPicture:Zz, ?), x, 160 - 24).
        IF piAge < 200 THEN Blit(StampOf(ForEachPicture:Stars, ?), x - 6, 160 - 8 - 8).
        ELSE DO:
            CartoonPhantom(PhantomKind:Mary, x - 26, MazeDir:Right, TRUE).
            CartoonPhantom(PhantomKind:Rich, x + 26, MazeDir:Left, TRUE).
            CartoonPhantom(PhantomKind:Brian, x, MazeDir:Left, TRUE).
            Blit(DibbyStamp(3, MazeDir:Right), x - 8, 160 - 8 - 20).
        END.
    END METHOD.

END CLASS.
