/* The maze, read from text, tile by tile: what each tile is, which are tunnel lanes (where phantoms are slow) and which are lanes
   where phantoms may not turn up, how many bits and commit tokens are left to eat, and where everyone starts. Columns wrap
   (a column off one edge is the one on the other side, which is how the tunnel works) and a row off the maze is refused.

   The text has one line for each row, with a line feed between them, and every line the same length. The symbols are
     #  wall                           _  empty lane                      .  a bit
     o  a commit token                 -  the door of the lobby           =  the floor of the lobby
     T  a tunnel lane (empty)          N  a bit where phantoms may not turn up
     U  an empty lane where they may not turn up
   and the starts, of which each may be written once (and P must be):
     P  Dibby      M  Mary      R  Rich      B  Brian      C  Chip      F  the bonus item
   D and W are P and M on a lane where phantoms may not turn up. A start sits on a tile: across it means the left edge of the
   tile and down it means the middle (so a start at column 5 of row 3 is at x 40, y 28). The tile under P, M and F is an empty
   lane and under R, B and C it is lobby floor. Positions are in pixels of the maze, 8 to a tile, with the origin at the top
   left of the maze. A comparison of letters ignores case, so a symbol must not be told from another by case alone.

   The tiles are kept as a number each: the TileKind in the low bits, 16 for a tunnel lane and 32 for no turning up. The map
   keeps the tiles as they were first read, so Refill can put every bit and commit token back for the next level. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.MazeMap FINAL:

    &SCOPED-DEFINE TUNNEL 16
    &SCOPED-DEFINE NO-UP 32

    VAR PRIVATE INTEGER[] mTiles.
    VAR PRIVATE INTEGER[] mOriginal.
    VAR PRIVATE LOGICAL[4] mHas.
    VAR PRIVATE INTEGER[4] mStartX.
    VAR PRIVATE INTEGER[4] mStartY.
    VAR PRIVATE LOGICAL mHasItem.
    VAR PRIVATE INTEGER mItemX.
    VAR PRIVATE INTEGER mItemY.

    DEFINE PUBLIC PROPERTY Cols AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Rows AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Every bit and commit token the maze starts with. */
    DEFINE PUBLIC PROPERTY BitsTotal AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* The bits and commit tokens still there to eat. */
    DEFINE PUBLIC PROPERTY BitsLeft AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Where Dibby starts, in pixels. */
    DEFINE PUBLIC PROPERTY DibbyStartX AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY DibbyStartY AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY HasItemSpot AS LOGICAL NO-UNDO
        GET():
            RETURN mHasItem.
        END GET.

    /* Where the bonus item sits, in pixels. Throws GridException when the maze has no spot for one. */
    DEFINE PUBLIC PROPERTY ItemX AS INTEGER NO-UNDO
        GET():
            IF NOT mHasItem THEN UNDO, THROW NEW GridException("This maze has no spot for the bonus item").
            RETURN mItemX.
        END GET.

    DEFINE PUBLIC PROPERTY ItemY AS INTEGER NO-UNDO
        GET():
            IF NOT mHasItem THEN UNDO, THROW NEW GridException("This maze has no spot for the bonus item").
            RETURN mItemY.
        END GET.

    /* Reads a maze. Throws GridException for no text, rows of different lengths, a symbol that is not one of the above, no start
       for Dibby, or a start written twice. */
    CONSTRUCTOR PUBLIC MazeMap(INPUT pcRows AS CHARACTER):
        VAR CHARACTER cells.
        VAR INTEGER cc.
        VAR INTEGER rr.
        VAR CHARACTER sym.
        VAR INTEGER v.
        VAR INTEGER who.
        VAR LOGICAL gotP.
        IF pcRows = ? OR pcRows = "" THEN UNDO, THROW NEW GridException("A maze needs some text").
        Rows = NUM-ENTRIES(pcRows, CHR(10)).
        Cols = LENGTH(RIGHT-TRIM(ENTRY(1, pcRows, CHR(10)), CHR(13))).
        IF Cols < 1 THEN UNDO, THROW NEW GridException("A maze needs at least one column").
        EXTENT(mTiles) = Cols * Rows.
        EXTENT(mOriginal) = Cols * Rows.
        DO rr = 0 TO Rows - 1:
            cells = RIGHT-TRIM(ENTRY(rr + 1, pcRows, CHR(10)), CHR(13)).
            IF LENGTH(cells) <> Cols THEN UNDO, THROW NEW GridException("Row " + STRING(rr) + " of the maze is not as long as the first").
            DO cc = 0 TO Cols - 1:
                sym = SUBSTRING(cells, cc + 1, 1).
                who = 0.
                CASE sym:
                    WHEN "#" THEN v = INTEGER(TileKind:Wall).
                    WHEN "_" THEN v = INTEGER(TileKind:Path).
                    WHEN "." THEN v = INTEGER(TileKind:Bit).
                    WHEN "o" THEN v = INTEGER(TileKind:Commit).
                    WHEN "-" THEN v = INTEGER(TileKind:Door).
                    WHEN "=" THEN v = INTEGER(TileKind:Lobby).
                    WHEN "T" THEN v = INTEGER(TileKind:Path) + {&TUNNEL}.
                    WHEN "N" THEN v = INTEGER(TileKind:Bit) + {&NO-UP}.
                    WHEN "U" THEN v = INTEGER(TileKind:Path) + {&NO-UP}.
                    WHEN "P" OR WHEN "D" THEN DO:
                        v = INTEGER(TileKind:Path) + (IF sym = "D" THEN {&NO-UP} ELSE 0).
                        IF gotP THEN UNDO, THROW NEW GridException("A maze has only one start for Dibby").
                        gotP = TRUE.
                        DibbyStartX = cc * 8.
                        DibbyStartY = rr * 8 + 4.
                    END.
                    WHEN "M" OR WHEN "W" THEN DO:
                        v = INTEGER(TileKind:Path) + (IF sym = "W" THEN {&NO-UP} ELSE 0).
                        who = INTEGER(PhantomKind:Mary).
                    END.
                    WHEN "R" THEN ASSIGN v = INTEGER(TileKind:Lobby)
                                         who = INTEGER(PhantomKind:Rich).
                    WHEN "B" THEN ASSIGN v = INTEGER(TileKind:Lobby)
                                         who = INTEGER(PhantomKind:Brian).
                    WHEN "C" THEN ASSIGN v = INTEGER(TileKind:Lobby)
                                         who = INTEGER(PhantomKind:Chip).
                    WHEN "F" THEN DO:
                        v = INTEGER(TileKind:Path).
                        IF mHasItem THEN UNDO, THROW NEW GridException("A maze has only one spot for the bonus item").
                        mHasItem = TRUE.
                        mItemX = cc * 8.
                        mItemY = rr * 8 + 4.
                    END.
                    OTHERWISE UNDO, THROW NEW GridException("The maze has a symbol that is not one of its own: " + sym).
                END CASE.
                IF who > 0 THEN DO:
                    IF mHas[who] THEN UNDO, THROW NEW GridException("A maze has only one start for each phantom").
                    ASSIGN mHas[who]    = TRUE
                           mStartX[who] = cc * 8
                           mStartY[who] = rr * 8 + 4.
                END.
                mTiles[rr * Cols + cc + 1] = v.
                mOriginal[rr * Cols + cc + 1] = v.
                IF v MODULO 16 = INTEGER(TileKind:Bit) OR v MODULO 16 = INTEGER(TileKind:Commit) THEN BitsTotal = BitsTotal + 1.
            END.
        END.
        IF NOT gotP THEN UNDO, THROW NEW GridException("A maze needs a start for Dibby").
        BitsLeft = BitsTotal.
    END CONSTRUCTOR.

    /* The index of a tile in the arrays. A column off the edge wraps, a row off the maze is refused. */
    METHOD PRIVATE INTEGER IndexOf(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        IF piCol = ? OR piRow = ? OR piRow < 0 OR piRow >= Rows THEN
            UNDO, THROW NEW GridException("Row " + STRING(piRow) + " is not in the maze").
        RETURN piRow * Cols + ((piCol MODULO Cols) + Cols) MODULO Cols + 1.
    END METHOD.

    /* What the tile is. */
    METHOD PUBLIC TileKind KindAt(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        RETURN TileKind:GetEnum(mTiles[IndexOf(piCol, piRow)] MODULO 16).
    END METHOD.

    /* True when Dibby, or with plPhantom a phantom, can step onto the tile: never a wall, and the door and the lobby only for a
       phantom. */
    METHOD PUBLIC LOGICAL CanEnter(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT plPhantom AS LOGICAL):
        CASE mTiles[IndexOf(piCol, piRow)] MODULO 16:
            WHEN INTEGER(TileKind:Wall) THEN RETURN FALSE.
            WHEN INTEGER(TileKind:Door) OR WHEN INTEGER(TileKind:Lobby) THEN RETURN plPhantom.
            OTHERWISE RETURN TRUE.
        END CASE.
    END METHOD.

    /* True for a tunnel lane, where phantoms slow down. */
    METHOD PUBLIC LOGICAL IsTunnel(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        RETURN INTEGER(TRUNCATE(mTiles[IndexOf(piCol, piRow)] / {&TUNNEL}, 0)) MODULO 2 = 1.
    END METHOD.

    /* True for a tile where a phantom heading somewhere else may not choose to turn up. */
    METHOD PUBLIC LOGICAL NoUpAt(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        RETURN INTEGER(TRUNCATE(mTiles[IndexOf(piCol, piRow)] / {&NO-UP}, 0)) MODULO 2 = 1.
    END METHOD.

    /* Eats what is on the tile. A bit or a commit token is taken off (the tile is an empty lane from now on, and BitsLeft goes
       down) and its kind is given back. On anything else nothing happens and the kind of the tile is given back. */
    METHOD PUBLIC TileKind Take(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER):
        VAR INTEGER i.
        VAR TileKind kind.
        i = IndexOf(piCol, piRow).
        kind = TileKind:GetEnum(mTiles[i] MODULO 16).
        IF kind = TileKind:Bit OR kind = TileKind:Commit THEN DO:
            mTiles[i] = mTiles[i] - INTEGER(kind) + INTEGER(TileKind:Path).
            BitsLeft = BitsLeft - 1.
        END.
        RETURN kind.
    END METHOD.

    /* Puts every bit and commit token back. */
    METHOD PUBLIC VOID Refill():
        VAR INTEGER i.
        DO i = 1 TO EXTENT(mTiles):
            mTiles[i] = mOriginal[i].
        END.
        BitsLeft = BitsTotal.
    END METHOD.

    /* True when the maze has a start for the phantom. */
    METHOD PUBLIC LOGICAL HasPhantomStart(INPUT poKind AS PhantomKind):
        IF poKind = ? THEN UNDO, THROW NEW GridException("A phantom cannot be unknown").
        RETURN mHas[INTEGER(poKind)].
    END METHOD.

    /* Where the phantom starts, in pixels. Throws GridException when the maze has no start for it. */
    METHOD PUBLIC INTEGER PhantomStartX(INPUT poKind AS PhantomKind):
        IF NOT HasPhantomStart(poKind) THEN UNDO, THROW NEW GridException("This maze has no start for " + STRING(poKind)).
        RETURN mStartX[INTEGER(poKind)].
    END METHOD.

    METHOD PUBLIC INTEGER PhantomStartY(INPUT poKind AS PhantomKind):
        IF NOT HasPhantomStart(poKind) THEN UNDO, THROW NEW GridException("This maze has no start for " + STRING(poKind)).
        RETURN mStartY[INTEGER(poKind)].
    END METHOD.

END CLASS.
