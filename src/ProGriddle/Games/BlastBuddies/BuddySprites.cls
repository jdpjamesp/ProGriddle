/* The pictures of Blast Buddies as pixel stamps, made from the designer's tiles (BuddiesArt) the first time each is wanted and kept. A
   picture can be had in the colours of a team (the goon, drawn once in the Reds row, takes the tones of any team) and facing left (the
   art all faces right, so the columns are mirrored, and the origin with them). A weapon held in the hand can be had turned to any of the
   64 headings, nearest neighbour round its pivot, as the design says. The owner calls Dispose (a destructor does it as a safety net). */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddySprites FINAL:

    /* the stamps by sprite, tone row (0 for its own, 1 to 4 for a team) and mirror: ((sprite - 1) * 5 + row) * 2 + mirror + 1 */
    DEFINE PRIVATE VARIABLE mStamp  AS PixelStamp NO-UNDO EXTENT 720.
    /* the turned stamps by turnable sprite, mirror and heading: ((turnable - 1) * 2 + mirror) * 64 + heading + 1. Only the sprites that are turned
       have a place (a class can hold only about 32000 bytes of variables, so the table is small) */
    DEFINE PRIVATE VARIABLE mTurned AS PixelStamp NO-UNDO EXTENT 1024.
    DEFINE PRIVATE VARIABLE mNames  AS CHARACTER  NO-UNDO.
    DEFINE PRIVATE VARIABLE mDisposed AS LOGICAL  NO-UNDO.

    CONSTRUCTOR PUBLIC BuddySprites():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 1 TO BuddiesArt:Count():
            mNames = mNames + (IF i > 1 THEN "," ELSE "") + BuddiesArt:NameAt(i).
        END.
    END CONSTRUCTOR.

    DESTRUCTOR PUBLIC BuddySprites():
        Dispose().
    END DESTRUCTOR.

    /* Frees every stamp. Safe to call more than once. */
    METHOD PUBLIC VOID Dispose():
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        IF mDisposed THEN RETURN.
        mDisposed = TRUE.
        DO i = 1 TO EXTENT(mStamp):
            IF VALID-OBJECT(mStamp[i]) THEN mStamp[i]:Dispose().
        END.
        DO i = 1 TO EXTENT(mTurned):
            IF VALID-OBJECT(mTurned[i]) THEN mTurned[i]:Dispose().
        END.
    END METHOD.

    /* The place of a sprite in the design's list. Throws GridException for a name that is not in it. */
    METHOD PRIVATE INTEGER IndexOf(INPUT pcName AS CHARACTER):
        DEFINE VARIABLE n AS INTEGER NO-UNDO.
        n = LOOKUP(pcName, mNames).
        IF n = 0 THEN UNDO, THROW NEW GridException("There is no sprite " + STRING(pcName)).
        RETURN n.
    END METHOD.

    /* The tone row to colour a sprite with: the team's (1 to 4, Reds Blues Teals Grapes) when one is asked for, else its own. */
    METHOD PRIVATE CHARACTER RowFor(INPUT pcName AS CHARACTER, INPUT piTeam AS INTEGER):
        IF piTeam >= 1 AND piTeam <= 4 THEN RETURN ENTRY(piTeam, "Reds,Blues,Teals,Grapes").
        IF BuddiesArt:ToneRow(pcName) = "" THEN RETURN "Reds".
        RETURN BuddiesArt:ToneRow(pcName).
    END METHOD.

    /* The width and height of a sprite. */
    METHOD PUBLIC INTEGER WidthOf(INPUT pcName AS CHARACTER):
        RETURN BuddiesArt:Width(pcName).
    END METHOD.

    METHOD PUBLIC INTEGER HeightOf(INPUT pcName AS CHARACTER):
        RETURN BuddiesArt:Height(pcName).
    END METHOD.

    /* The column of the origin of a sprite, which for a mirrored one is the mirror of it. */
    METHOD PUBLIC INTEGER OriginX(INPUT pcName AS CHARACTER, INPUT plMirror AS LOGICAL):
        IF plMirror THEN RETURN BuddiesArt:Width(pcName) - 1 - BuddiesArt:OriginX(pcName).
        RETURN BuddiesArt:OriginX(pcName).
    END METHOD.

    METHOD PUBLIC INTEGER OriginY(INPUT pcName AS CHARACTER):
        RETURN BuddiesArt:OriginY(pcName).
    END METHOD.

    /* The first row of a picture that is not empty or the outline in its middle column: where a goon's head begins, for its mark. */
    METHOD PUBLIC INTEGER HeadTop(INPUT pcName AS CHARACTER):
        DEFINE VARIABLE t  AS Tile      NO-UNDO.
        DEFINE VARIABLE y  AS INTEGER   NO-UNDO.
        DEFINE VARIABLE ch AS CHARACTER NO-UNDO.
        t = BuddiesArt:TileOf(pcName).
        DO y = 0 TO t:Height - 1:
            ch = t:PixelAt(INTEGER(TRUNCATE(t:Width / 2, 0)), y).
            IF ch <> "." AND ch <> "I" THEN RETURN y.
        END.
        RETURN 0.
    END METHOD.

    /* A sprite as a stamp, in the colours of a team (1 to 4, or 0 for its own), mirrored if asked. */
    METHOD PUBLIC PixelStamp Stamp(INPUT pcName AS CHARACTER, INPUT piTeam AS INTEGER, INPUT plMirror AS LOGICAL):
        DEFINE VARIABLE slot AS INTEGER    NO-UNDO.
        DEFINE VARIABLE base AS PixelStamp NO-UNDO.
        DEFINE VARIABLE w    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE h    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE x    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE y    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE cols AS INTEGER    NO-UNDO EXTENT.
        IF piTeam < 0 OR piTeam > 4 THEN UNDO, THROW NEW GridException("A team is 1 to 4, or 0 for none").
        slot = ((IndexOf(pcName) - 1) * 5 + piTeam) * 2 + (IF plMirror THEN 1 ELSE 0) + 1.
        IF VALID-OBJECT(mStamp[slot]) THEN RETURN mStamp[slot].
        base = BuddiesArt:TileOf(pcName):Colourise(BuddiesLook:ToneRow(RowFor(pcName, piTeam)), BuddiesArt:Legend(pcName)).
        IF NOT plMirror THEN DO:
            mStamp[slot] = base.
            RETURN base.
        END.
        w = base:Width.
        h = base:Height.
        EXTENT(cols) = w * h.
        DO y = 0 TO h - 1:
            DO x = 0 TO w - 1:
                cols[y * w + x + 1] = base:ColourAt(w - 1 - x, y).
            END.
        END.
        base:Dispose().
        mStamp[slot] = NEW PixelStamp(w, h, cols).
        RETURN mStamp[slot].
    END METHOD.

    /* How far from the pivot a turned weapon reaches in every direction: its stamp is 2 x this + 1 square, with the pivot in the middle. */
    METHOD PUBLIC INTEGER Reach(INPUT pcName AS CHARACTER):
        RETURN INTEGER(ROUND(SQRT(DECIMAL(BuddiesArt:Width(pcName) * BuddiesArt:Width(pcName) + BuddiesArt:Height(pcName) * BuddiesArt:Height(pcName))), 0)) + 1.
    END METHOD.

    /* A held weapon turned to a heading (0 up, 16 right, 32 down, 48 left), for a buddy facing the way given. A weapon facing left is
       mirrored first and then turned by the heading it is given. The stamp is Reach x 2 + 1 square, and the pivot is its middle. */
    METHOD PUBLIC PixelStamp Turned(INPUT pcName AS CHARACTER, INPUT piHeading AS INTEGER, INPUT plMirror AS LOGICAL):
        DEFINE VARIABLE slot  AS INTEGER    NO-UNDO.
        DEFINE VARIABLE turnable AS INTEGER NO-UNDO.
        DEFINE VARIABLE src   AS PixelStamp NO-UNDO.
        DEFINE VARIABLE r     AS INTEGER    NO-UNDO.
        DEFINE VARIABLE size  AS INTEGER    NO-UNDO.
        DEFINE VARIABLE hd    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE c     AS INTEGER    NO-UNDO.
        DEFINE VARIABLE s     AS INTEGER    NO-UNDO.
        DEFINE VARIABLE ox    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE oy    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE dx    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE dy    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE sx    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE sy    AS INTEGER    NO-UNDO.
        DEFINE VARIABLE cols  AS INTEGER    NO-UNDO EXTENT.
        hd = Heading:Wrap(piHeading).
        turnable = LOOKUP(pcName, "held_bazooka,held_shotgun,rocket,exhaust_0,exhaust_1,missile,flare_0,flare_1").
        IF turnable = 0 THEN UNDO, THROW NEW GridException("The sprite " + STRING(pcName) + " is not one that is turned").
        slot = ((turnable - 1) * 2 + (IF plMirror THEN 1 ELSE 0)) * 64 + hd + 1.
        IF VALID-OBJECT(mTurned[slot]) THEN RETURN mTurned[slot].
        src = Stamp(pcName, 0, plMirror).
        r = Reach(pcName).
        size = 2 * r + 1.
        ox = OriginX(pcName, plMirror).
        oy = OriginY(pcName).
        c = Heading:Cos(hd - 16).
        s = Heading:Sin(hd - 16).
        EXTENT(cols) = size * size.
        DO dy = - r TO r:
            DO dx = - r TO r:
                sx = INTEGER(ROUND((c * dx + s * dy) / Heading:Scale(), 0)) + ox.
                sy = INTEGER(ROUND((- s * dx + c * dy) / Heading:Scale(), 0)) + oy.
                IF sx >= 0 AND sx < src:Width AND sy >= 0 AND sy < src:Height THEN cols[(dy + r) * size + dx + r + 1] = src:ColourAt(sx, sy).
                ELSE cols[(dy + r) * size + dx + r + 1] = -1.
            END.
        END.
        mTurned[slot] = NEW PixelStamp(size, size, cols).
        RETURN mTurned[slot].
    END METHOD.

END CLASS.
