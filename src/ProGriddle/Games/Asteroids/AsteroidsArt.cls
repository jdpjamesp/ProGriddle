/* The shapes of Asteroids as outlines (see Outline for the text form), in cells, the origin at the middle of the
   shape and its nose, where it has one, pointing up. They are the designer's "Obsidian Line" shapes, taken from
   docs/design/asteroids-art.md, and this is the one place to change them. A rock's collision circle is the
   radius in RockRadius and its drawn outline stays within 15 percent of it, so what the player sees is what hits.
   Radii and extents are given in 256ths of a cell for the maths of the game, and in whole cells (the extent,
   the distance from the middle that covers the shape with its flame) for drawing it again over the far edge. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Asteroids.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Asteroids.AsteroidsArt FINAL:

    /* the rocks, five large ones, then four medium, then four small */
    DEFINE PRIVATE STATIC VARIABLE sRocks   AS Outline NO-UNDO EXTENT 13.
    DEFINE PRIVATE STATIC VARIABLE sFlames  AS Outline NO-UNDO EXTENT 6.
    DEFINE PRIVATE STATIC VARIABLE sSaucers AS Outline NO-UNDO EXTENT 2.
    DEFINE PRIVATE STATIC VARIABLE sGlyphs  AS Outline NO-UNDO EXTENT 8.
    DEFINE PRIVATE STATIC VARIABLE sShip    AS Outline NO-UNDO.
    DEFINE PRIVATE STATIC VARIABLE sSpine   AS Outline NO-UNDO.
    DEFINE PRIVATE STATIC VARIABLE sPieces  AS Outline NO-UNDO.

    CONSTRUCTOR STATIC AsteroidsArt():
        sShip = NEW Outline("closed 0,-6 3.6,3 1.6,1.6 -1.6,1.6 -3.6,3").
        sSpine = NEW Outline("open 0,-4.4 0,1.6").
        sPieces = NEW Outline("open 0,-6 -3.6,3 / open 0,-6 3.6,3 / open -3.6,3 -1.6,1.6 / open 3.6,3 1.6,1.6 / open -1.6,1.6 1.6,1.6").
        /* the thruster flame, three frames: the outer line, then the core line */
        sFlames[1] = NEW Outline("open -1.3,1.8 0,6.2 1.3,1.8").
        sFlames[2] = NEW Outline("open 0,2 0,4.2").
        sFlames[3] = NEW Outline("open -1.4,1.8 0,8.2 1.4,1.8").
        sFlames[4] = NEW Outline("open 0,2 0,5.4").
        sFlames[5] = NEW Outline("open -1.2,1.8 0.4,7 1.2,1.8").
        sFlames[6] = NEW Outline("open 0.2,2 0.2,4.6").
        /* the rocks */
        sRocks[1] = NEW Outline("closed 0.9,-19.1 12.8,-21.3 16.8,-9.4 24.3,-2.3 18.2,5.6 19.4,14.9 7.5,18.1 -3,24.6 -13.2,14.6 -18.6,5.3 -24.7,-0.2 -16.4,-10.3 -7.7,-23.5").  /* rock_l0 */
        sRocks[2] = NEW Outline("closed 4.3,-24.3 14.5,-19.8 13.2,-13.5 23.9,-5.1 24.4,5.5 12.8,14 8.5,22.9 -4.5,18.5 -16.1,18.8 -18.5,6 -24.2,-3.1 -15.8,-10.9 -14.9,-19.2").  /* rock_l1 */
        sRocks[3] = NEW Outline("closed -1.9,-18.8 6.2,-18.3 21.3,-12.8 24,-5.4 17.4,7.6 18.9,16.3 1.1,19.5 -5.8,18.2 -11.7,15.5 -21.6,12.7 -23.6,-6.1 -14.2,-13.5 -12.7,-20.9").  /* rock_l2 */
        sRocks[4] = NEW Outline("closed -2.8,-18.8 11.6,-15.6 19.9,-15.1 19,0.4 24.2,4.8 15.7,19.1 4.6,18.5 -10,22.4 -14.3,13.2 -18.1,6.8 -18.9,-4.1 -20.6,-13.8 -5.8,-18.2").  /* rock_l3 */
        sRocks[5] = NEW Outline("closed 0.3,-19.3 13.5,-20.7 16.7,-10.2 24.4,-4.4 17.8,7.6 18.1,17 6.9,18.4 -7.6,23.7 -13.2,14.2 -21.8,12.2 -19.4,1.3 -19.8,-15.2 -14.9,-19.7").  /* rock_l4 */
        sRocks[6] = NEW Outline("closed -0.4,-9.5 6.9,-10.3 8.5,-4.5 12.4,1.8 5.8,7.6 1.9,12.2 -2,9.6 -7.6,9.8 -12.2,0.3 -9.4,-2 -6.3,-10.5").  /* rock_m0 */
        sRocks[7] = NEW Outline("closed 0.7,-9.7 5.7,-7.6 9.8,-7.3 9.7,-0.2 7.3,9.8 4,8.9 -3.5,9.1 -9,8.2 -9.6,-0.7 -10.8,-6.1 -7.5,-9.9").  /* rock_m1 */
        sRocks[8] = NEW Outline("closed -0.4,-12.5 7,-10.4 8.7,-4.7 9.5,-0.1 7.9,9.6 3.1,12 -4.8,11.4 -7.6,6.1 -12.2,0.5 -10.8,-6.2 -3.9,-8.9").  /* rock_m2 */
        sRocks[9] = NEW Outline("closed -1.3,-9.7 7.8,-9.7 8,-5.4 11.9,3.4 7.2,9.8 1.4,9.5 -1.6,12.4 -6.5,6.9 -12.1,3 -8,-5.7 -4.3,-8.7").  /* rock_m3 */
        sRocks[10] = NEW Outline("closed 0.8,-6.1 4.7,-4.1 4.7,-1.3 2.3,4.3 -0.5,6.2 -3.9,2.9 -6.2,0.2 -2.4,-4.2").  /* rock_s0 */
        sRocks[11] = NEW Outline("closed 0.2,-4.8 4.8,-3.9 6.1,-0.5 2.7,4.1 -1.3,6 -3.5,3.2 -4.9,-0.1 -3.4,-5.1").  /* rock_s1 */
        sRocks[12] = NEW Outline("closed 1.5,-6 3.9,-2.9 6.1,1.1 2.6,4.1 -0.2,6.1 -2.6,4 -5.9,-1.6 -3.4,-3.3").  /* rock_s2 */
        sRocks[13] = NEW Outline("closed -1.1,-4.6 3.7,-5 4.7,-1.3 5,3.6 0.4,4.8 -3.5,5.1 -4.7,-0.8 -3.5,-3.4").  /* rock_s3 */
        /* the saucers: the body, then the waist and the dome as lines inside it */
        sSaucers[1] = NEW Outline("closed -4.5,0.5 -2.2,-1.6 -1,-3.8 1,-3.8 2.2,-1.6 4.5,0.5 1.8,2.8 0,1.6 -1.8,2.8 / open -4.5,0.5 4.5,0.5 / open -2.2,-1.6 2.2,-1.6").
        sSaucers[2] = NEW Outline("closed -7,0 -3,-3 -2,-5 2,-5 3,-3 7,0 3.5,3 -3.5,3 / open -7,0 7,0 / open -3,-3 3,-3").
        /* the letters of the title, in cells from the top left of the letter */
        sGlyphs[1] = NEW Outline("open 0,28 10,0 20,28 / open 3.2,19 16.8,19").
        sGlyphs[2] = NEW Outline("open 20,0 0,0 0,14 20,14 20,28 0,28").
        sGlyphs[3] = NEW Outline("open 0,0 20,0 / open 10,0 10,28").
        sGlyphs[4] = NEW Outline("open 20,0 0,0 0,28 20,28 / open 0,14 14,14").
        sGlyphs[5] = NEW Outline("open 0,28 0,0 20,0 20,14 0,14 / open 8,14 20,28").
        sGlyphs[6] = NEW Outline("closed 4,0 16,0 20,4 20,24 16,28 4,28 0,24 0,4").
        sGlyphs[7] = NEW Outline("open 0,0 16,0 / open 8,0 8,28 / open 0,28 16,28").
        sGlyphs[8] = NEW Outline("closed 0,0 14,0 20,6 20,22 14,28 0,28").
    END CONSTRUCTOR.

    /* The ship's body, a notched arrowhead 9 cells tall. */
    METHOD PUBLIC STATIC Outline Ship():
        RETURN sShip.
    END METHOD.

    /* The line down the middle of the ship, drawn over the body in its own colour. */
    METHOD PUBLIC STATIC Outline ShipSpine():
        RETURN sSpine.
    END METHOD.

    /* The five lines the ship breaks into, as two point lines in the ship's own coordinates. */
    METHOD PUBLIC STATIC Outline ShipPieces():
        RETURN sPieces.
    END METHOD.

    /* The outer line of the thruster flame in frame 0 to 2, behind the ship. */
    METHOD PUBLIC STATIC Outline FlameOuter(INPUT piFrame AS INTEGER):
        IF piFrame = ? OR piFrame < 0 OR piFrame > 2 THEN UNDO, THROW NEW GridException("A flame frame is 0 to 2, not " + STRING(piFrame)).
        RETURN sFlames[piFrame * 2 + 1].
    END METHOD.

    /* The bright inner line of the flame in frame 0 to 2. */
    METHOD PUBLIC STATIC Outline FlameCore(INPUT piFrame AS INTEGER):
        IF piFrame = ? OR piFrame < 0 OR piFrame > 2 THEN UNDO, THROW NEW GridException("A flame frame is 0 to 2, not " + STRING(piFrame)).
        RETURN sFlames[piFrame * 2 + 2].
    END METHOD.

    /* A rock of a size (1 large, 2 medium, 3 small) in a variant. The variant is wrapped round, so any whole
       number picks one. */
    METHOD PUBLIC STATIC Outline Rock(INPUT piSize AS INTEGER, INPUT piVariant AS INTEGER):
        IF piVariant = ? THEN UNDO, THROW NEW GridException("A rock variant cannot be unknown").
        RETURN sRocks[RockBase(piSize) + (ABSOLUTE(piVariant) MODULO RockVariants(piSize))].
    END METHOD.

    /* How many different outlines a size of rock has: 5, 4 and 4. */
    METHOD PUBLIC STATIC INTEGER RockVariants(INPUT piSize AS INTEGER):
        CASE piSize:
            WHEN 1 THEN RETURN 5.
            WHEN 2 THEN RETURN 4.
            WHEN 3 THEN RETURN 4.
        END CASE.
        UNDO, THROW NEW GridException("A rock size is 1, 2 or 3, not " + STRING(piSize)).
    END METHOD.

    /* The collision radius of a size of rock, in 256ths of a cell: 22, 11 and 5.5 cells. */
    METHOD PUBLIC STATIC INTEGER RockRadius(INPUT piSize AS INTEGER):
        CASE piSize:
            WHEN 1 THEN RETURN 5632.
            WHEN 2 THEN RETURN 2816.
            WHEN 3 THEN RETURN 1408.
        END CASE.
        UNDO, THROW NEW GridException("A rock size is 1, 2 or 3, not " + STRING(piSize)).
    END METHOD.

    /* The distance from the middle of a rock that covers all its outline, in whole cells, for wrapping. */
    METHOD PUBLIC STATIC INTEGER RockExtent(INPUT piSize AS INTEGER):
        CASE piSize:
            WHEN 1 THEN RETURN 27.
            WHEN 2 THEN RETURN 15.
            WHEN 3 THEN RETURN 9.
        END CASE.
        UNDO, THROW NEW GridException("A rock size is 1, 2 or 3, not " + STRING(piSize)).
    END METHOD.

    /* A saucer: the large one (14 cells wide) or the small, meaner one (9 wide). */
    METHOD PUBLIC STATIC Outline Saucer(INPUT plLarge AS LOGICAL):
        IF plLarge = ? THEN UNDO, THROW NEW GridException("A saucer is large or small, not unknown").
        RETURN (IF plLarge THEN sSaucers[2] ELSE sSaucers[1]).
    END METHOD.

    /* The collision radius of a saucer, in 256ths of a cell: 6.5 cells for the large one, 4.2 for the small. */
    METHOD PUBLIC STATIC INTEGER SaucerRadius(INPUT plLarge AS LOGICAL):
        RETURN (IF plLarge THEN 1664 ELSE 1075).
    END METHOD.

    /* The distance from the middle of a saucer that covers its outline and its glow, in whole cells. */
    METHOD PUBLIC STATIC INTEGER SaucerExtent(INPUT plLarge AS LOGICAL):
        RETURN (IF plLarge THEN 9 ELSE 7).
    END METHOD.

    /* The collision radius of the ship, in 256ths of a cell: 4.5 cells, a little less than its 6 cell nose. */
    METHOD PUBLIC STATIC INTEGER ShipRadius():
        RETURN 1152.
    END METHOD.

    /* The distance from the middle of the ship that covers it with its flame and its glow, in whole cells. */
    METHOD PUBLIC STATIC INTEGER ShipExtent():
        RETURN 11.
    END METHOD.

    /* A letter of the title as lines, in cells from the top left of the letter: one of A S T E R O I D. */
    METHOD PUBLIC STATIC Outline Glyph(INPUT pcLetter AS CHARACTER):
        DEFINE VARIABLE slot AS INTEGER NO-UNDO.
        IF pcLetter = ? OR LENGTH(pcLetter) <> 1 THEN UNDO, THROW NEW GridException("A title letter is one character").
        slot = INDEX("ASTEROID", CAPS(pcLetter)).
        IF slot = 0 THEN UNDO, THROW NEW GridException("There is no title letter " + pcLetter).
        RETURN sGlyphs[slot].
    END METHOD.

    /* How wide a title letter is, in cells: 20, or 16 for the I. Every letter is 28 cells tall. */
    METHOD PUBLIC STATIC INTEGER GlyphWidth(INPUT pcLetter AS CHARACTER):
        Glyph(pcLetter).
        RETURN (IF CAPS(pcLetter) = "I" THEN 16 ELSE 20).
    END METHOD.

    METHOD PRIVATE STATIC INTEGER RockBase(INPUT piSize AS INTEGER):
        CASE piSize:
            WHEN 1 THEN RETURN 1.
            WHEN 2 THEN RETURN 6.
            WHEN 3 THEN RETURN 10.
        END CASE.
        UNDO, THROW NEW GridException("A rock size is 1, 2 or 3, not " + STRING(piSize)).
    END METHOD.

END CLASS.
