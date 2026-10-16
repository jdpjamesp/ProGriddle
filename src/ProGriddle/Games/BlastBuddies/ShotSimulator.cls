/* Flies a rocket through the ground without a game, for the computer player to try shots with. It does what the game does with a shell
   (gravity and wind every frame, moved a pixel at a time so nothing is skipped over, stopped by ground, lost in the water or off the sides)
   but ignores the buddies, which only the blast at the end needs. The numbers are the same, so the same shot lands in the same place. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.ShotSimulator FINAL:

    /* How many flights have been worked out. */
    DEFINE PUBLIC PROPERTY Flights AS INTEGER NO-UNDO GET. PRIVATE SET.

    /* Flies a shell from a place (256ths of a pixel) with a speed (256ths of a pixel a frame) in the wind. Returns true if it hit the
       ground, and gives the pixel it hit; false if it was lost in the water, off the sides or after too long in the air. */
    METHOD PUBLIC LOGICAL Fly(INPUT poTerrain AS Terrain, INPUT piX256 AS INTEGER, INPUT piY256 AS INTEGER, INPUT piVx AS INTEGER, INPUT piVy AS INTEGER,
                              INPUT piWind AS INTEGER, OUTPUT piHitX AS INTEGER, OUTPUT piHitY AS INTEGER):
        DEFINE VARIABLE x0  AS INTEGER NO-UNDO.
        DEFINE VARIABLE y0  AS INTEGER NO-UNDO.
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE vx  AS INTEGER NO-UNDO.
        DEFINE VARIABLE vy  AS INTEGER NO-UNDO.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DEFINE VARIABLE k   AS INTEGER NO-UNDO.
        DEFINE VARIABLE px  AS INTEGER NO-UNDO.
        DEFINE VARIABLE py  AS INTEGER NO-UNDO.
        DEFINE VARIABLE age AS INTEGER NO-UNDO.
        IF NOT VALID-OBJECT(poTerrain) THEN UNDO, THROW NEW GridException("A simulated shot needs a terrain").
        Flights = Flights + 1.
        x = piX256.
        y = piY256.
        vx = piVx.
        vy = piVy.
        DO WHILE age <= BuddyRules:ShotMaxFrames():
            age = age + 1.
            vx = vx + piWind.
            vy = vy + BuddyRules:Gravity().
            x0 = x.
            y0 = y.
            n = INTEGER(TRUNCATE(MAXIMUM(ABSOLUTE(vx), ABSOLUTE(vy)) / 256, 0)) + 1.
            DO k = 1 TO n:
                x = x0 + INTEGER(TRUNCATE(vx * k / n, 0)).
                y = y0 + INTEGER(TRUNCATE(vy * k / n, 0)).
                px = BuddyRules:Pixel(x).
                py = BuddyRules:Pixel(y).
                IF px < 0 OR px >= Terrain:Width() THEN RETURN FALSE.
                IF py >= BuddyRules:WaterRow() THEN RETURN FALSE.
                IF poTerrain:IsSolid(px, py) THEN DO:
                    piHitX = px.
                    piHitY = py.
                    RETURN TRUE.
                END.
            END.
        END.
        RETURN FALSE.
    END METHOD.

END CLASS.
