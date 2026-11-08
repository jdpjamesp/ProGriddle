/* Where each phantom is heading, as a tile. Scatter: each has a corner outside the maze. Chase: Mary aims at Dibby; Rich at the
   tile four ahead of him; Brian at the point as far beyond the tile two ahead of Dibby as Mary is behind it; Chip at Dibby until he
   is within 8 tiles and then at his own corner. When Dibby faces up, "ahead" also counts the same number of tiles to the left:
   that is part of the rule, and it is kept. Returning phantoms head for the tile above the door. A target may be outside the
   maze. Rows are counted from the top of the maze. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.ForEach.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.ForEach.PhantomTargeting FINAL:

    /* The corner of a phantom: Mary top right, Rich top left, Brian bottom right, Chip bottom left. */
    METHOD PUBLIC STATIC Coord ScatterTarget(INPUT poKind AS PhantomKind):
        IF poKind = ? THEN UNDO, THROW NEW GridException("A phantom cannot be unknown").
        CASE poKind:
            WHEN PhantomKind:Mary THEN RETURN NEW Coord(25, -3).
            WHEN PhantomKind:Rich THEN RETURN NEW Coord(2, -3).
            WHEN PhantomKind:Brian THEN RETURN NEW Coord(27, 33).
            OTHERWISE RETURN NEW Coord(0, 33).
        END CASE.
    END METHOD.

    /* The tile a phantom hunting Dibby is heading for. The phantom is at piCol, piRow, Dibby is at piDibbyCol, piDibbyRow facing
       poDibbyDir (unknown counts as no way), and Mary is at piMaryCol, piMaryRow. */
    METHOD PUBLIC STATIC Coord ChaseTarget(INPUT poKind AS PhantomKind,
                                           INPUT piCol AS INTEGER, INPUT piRow AS INTEGER,
                                           INPUT piDibbyCol AS INTEGER, INPUT piDibbyRow AS INTEGER, INPUT poDibbyDir AS MazeDir,
                                           INPUT piMaryCol AS INTEGER, INPUT piMaryRow AS INTEGER):
        VAR INTEGER dx.
        VAR INTEGER dy.
        VAR INTEGER pc.
        VAR INTEGER pr.
        IF poKind = ? THEN UNDO, THROW NEW GridException("A phantom cannot be unknown").
        IF poDibbyDir <> ? THEN ASSIGN dx = MazeDirs:Dx(poDibbyDir)
                                       dy = MazeDirs:Dy(poDibbyDir).
        CASE poKind:
            WHEN PhantomKind:Mary THEN RETURN NEW Coord(piDibbyCol, piDibbyRow).
            WHEN PhantomKind:Rich THEN RETURN Ahead(piDibbyCol, piDibbyRow, dx, dy, 4).
            WHEN PhantomKind:Brian THEN DO:
                pc = Ahead(piDibbyCol, piDibbyRow, dx, dy, 2):X.
                pr = Ahead(piDibbyCol, piDibbyRow, dx, dy, 2):Y.
                RETURN NEW Coord(2 * pc - piMaryCol, 2 * pr - piMaryRow).
            END.
            OTHERWISE DO:
                IF EXP(piCol - piDibbyCol, 2) + EXP(piRow - piDibbyRow, 2) >= 64 THEN RETURN NEW Coord(piDibbyCol, piDibbyRow).
                RETURN ScatterTarget(PhantomKind:Chip).
            END.
        END CASE.
    END METHOD.

    /* The tile above the door of the lobby, which a returning phantom runs to. */
    METHOD PUBLIC STATIC Coord ReturningTarget():
        RETURN NEW Coord(13, 11).
    END METHOD.

    /* The tile piTiles ahead of a tile along a step. Heading up, the same number of tiles to the left as well. */
    METHOD PRIVATE STATIC Coord Ahead(INPUT piCol AS INTEGER, INPUT piRow AS INTEGER, INPUT piDx AS INTEGER, INPUT piDy AS INTEGER,
                                      INPUT piTiles AS INTEGER):
        RETURN NEW Coord(piCol + piDx * piTiles - (IF piDy < 0 THEN piTiles ELSE 0), piRow + piDy * piTiles).
    END METHOD.

END CLASS.
