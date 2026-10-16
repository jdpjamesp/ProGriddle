/* How a buddy moves over the ground of Blast Buddies, for one buddy at a time on one map, in whole numbers only.

     Walk       one pixel along the ground: up a rise of 3 pixels or less, down a slope or off a ledge (it then falls), never into rock
     Hop        a small jump forward (6 pixels high); Backflip a high jump back (11 high, 9 back); Launch is a push from a blast
     Step       one frame at 60 frames a second: a buddy in the air falls under gravity, a buddy whose ground has gone starts to fall,
                a buddy that lands takes fall damage (1 for every 2 pixels beyond 24 of fall), and one that reaches the water row or leaves
                the sides of the map drowns

   A buddy is 9 pixels wide and 11 tall, standing with the middle of its feet on the first row of ground. Only the column of its middle is
   tested for the ground, and only that column for rock in the way, as the genre does. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddyPhysics FINAL:

    /* Whether the 11 rows above a feet row, in a column, are all air, so a buddy fits there. */
    METHOD PRIVATE LOGICAL BodyClear(INPUT poTerrain AS Terrain, INPUT piX AS INTEGER, INPUT piFeetY AS INTEGER):
        DEFINE VARIABLE y AS INTEGER NO-UNDO.
        DO y = piFeetY - BuddyRules:BuddyHeight() TO piFeetY - 1:
            IF poTerrain:IsSolid(piX, y) THEN RETURN FALSE.
        END.
        RETURN TRUE.
    END METHOD.

    /* Sets the buddy drowned, with no health and nowhere to go. */
    METHOD PRIVATE VOID Drown(INPUT poBuddy AS Buddy):
        poBuddy:State = BuddyState:Drowned.
        poBuddy:Health = 0.
        poBuddy:VX = 0.
        poBuddy:VY = 0.
    END METHOD.

    /* Whether the buddy is out of the map at the sides or in the water. Drowns it if so. */
    METHOD PRIVATE LOGICAL CheckDrowned(INPUT poBuddy AS Buddy):
        IF poBuddy:X() < 0 OR poBuddy:X() >= Terrain:Width() OR poBuddy:Y() >= BuddyRules:WaterRow() THEN DO:
            Drown(poBuddy).
            RETURN TRUE.
        END.
        RETURN FALSE.
    END METHOD.

    /* Lets go of the ground: the buddy is in the air from where it is, with the speed given. */
    METHOD PRIVATE VOID LetGo(INPUT poBuddy AS Buddy, INPUT piVx AS INTEGER, INPUT piVy AS INTEGER):
        IF poBuddy:State <> BuddyState:Airborne THEN poBuddy:PeakY = poBuddy:Y().
        poBuddy:State = BuddyState:Airborne.
        poBuddy:VX = piVx.
        poBuddy:VY = piVy.
        poBuddy:Landed = FALSE.
    END METHOD.

    /* Walks the buddy one pixel in a direction (-1 for left, 1 for right), turning it to face that way. Returns true if it moved. It cannot
       step up 4 pixels or more, or into a gap too low for its body. Where the ground falls away by more than 3 pixels it walks off and
       is then in the air; a walk past the side of the map or into the water drowns it. Only a buddy standing on the ground can walk. */
    METHOD PUBLIC LOGICAL Walk(INPUT poBuddy AS Buddy, INPUT poTerrain AS Terrain, INPUT piDirection AS INTEGER):
        DEFINE VARIABLE nx AS INTEGER NO-UNDO.
        DEFINE VARIABLE y  AS INTEGER NO-UNDO.
        DEFINE VARIABLE r  AS INTEGER NO-UNDO.
        IF piDirection <> -1 AND piDirection <> 1 THEN UNDO, THROW NEW GridException("A direction is -1 or 1, not " + STRING(piDirection)).
        poBuddy:Facing = piDirection.
        IF poBuddy:State <> BuddyState:Standing THEN RETURN FALSE.
        nx = poBuddy:X() + piDirection.
        y = poBuddy:Y().
        IF nx < 0 OR nx >= Terrain:Width() THEN DO:
            poBuddy:X256 = nx * 256.
            Drown(poBuddy).
            RETURN TRUE.
        END.
        /* the rise: a pixel 4 above the feet that is rock is a step too high */
        IF poTerrain:IsSolid(nx, y - BuddyRules:StepUp() - 1) THEN RETURN FALSE.
        DO r = y - BuddyRules:StepUp() TO y + BuddyRules:StepUp():
            IF poTerrain:IsSolid(nx, r) THEN LEAVE.
        END.
        IF r > y + BuddyRules:StepUp() THEN DO:
            /* nothing to stand on within reach: walk off the ledge and fall */
            IF NOT BodyClear(poTerrain, nx, y) THEN RETURN FALSE.
            poBuddy:X256 = nx * 256.
            LetGo(poBuddy, 0, 0).
            RETURN TRUE.
        END.
        IF NOT BodyClear(poTerrain, nx, r) THEN RETURN FALSE.
        poBuddy:X256 = nx * 256.
        poBuddy:Y256 = r * 256.
        poBuddy:PeakY = r.
        CheckDrowned(poBuddy).
        RETURN TRUE.
    END METHOD.

    /* A small hop in the way the buddy faces. Returns true if it left the ground (only a buddy standing can). */
    METHOD PUBLIC LOGICAL Hop(INPUT poBuddy AS Buddy):
        IF poBuddy:State <> BuddyState:Standing THEN RETURN FALSE.
        LetGo(poBuddy, poBuddy:Facing * BuddyRules:HopForward(), - BuddyRules:HopLift()).
        RETURN TRUE.
    END METHOD.

    /* A high flip backwards, away from the way the buddy faces. Returns true if it left the ground. */
    METHOD PUBLIC LOGICAL Backflip(INPUT poBuddy AS Buddy):
        IF poBuddy:State <> BuddyState:Standing THEN RETURN FALSE.
        LetGo(poBuddy, - poBuddy:Facing * BuddyRules:FlipBack(), - BuddyRules:FlipLift()).
        RETURN TRUE.
    END METHOD.

    /* Throws the buddy with a speed (256ths of a pixel a frame, down is positive), as a blast does. A buddy already in the air keeps the
       height it has fallen from. A drowned buddy is not moved. */
    METHOD PUBLIC VOID Launch(INPUT poBuddy AS Buddy, INPUT piVx AS INTEGER, INPUT piVy AS INTEGER):
        IF poBuddy:State = BuddyState:Drowned THEN RETURN.
        LetGo(poBuddy, piVx, piVy).
    END METHOD.

    /* One frame. A buddy standing on nothing starts to fall; a buddy in the air moves, one pixel at a time so nothing is skipped over, and
       lands, bumps its head, hits a wall or drowns. Landed is true afterwards if it came down in this frame. */
    METHOD PUBLIC VOID Step(INPUT poBuddy AS Buddy, INPUT poTerrain AS Terrain):
        DEFINE VARIABLE px  AS INTEGER NO-UNDO.
        DEFINE VARIABLE py  AS INTEGER NO-UNDO.
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DEFINE VARIABLE dir AS INTEGER NO-UNDO.
        DEFINE VARIABLE fall AS INTEGER NO-UNDO.
        DEFINE VARIABLE moves AS INTEGER NO-UNDO.
        poBuddy:Landed = FALSE.
        poBuddy:LastFallDamage = 0.
        CASE poBuddy:State:
            WHEN BuddyState:Drowned THEN RETURN.
            WHEN BuddyState:Standing THEN DO:
                IF CheckDrowned(poBuddy) THEN RETURN.
                IF poTerrain:IsSolid(poBuddy:X(), poBuddy:Y()) THEN RETURN.
                LetGo(poBuddy, 0, 0).
            END.
        END CASE.
        /* in the air: gravity, then along the way it is going */
        poBuddy:VY = MINIMUM(poBuddy:VY + BuddyRules:Gravity(), BuddyRules:TerminalSpeed()).
        /* sideways */
        px = poBuddy:X().
        poBuddy:X256 = poBuddy:X256 + poBuddy:VX.
        dir = (IF poBuddy:X() > px THEN 1 ELSE -1).
        moves = ABSOLUTE(poBuddy:X() - px).
        DO n = 1 TO moves:
            IF CanMoveTo(poBuddy, poTerrain, px + dir) THEN px = px + dir.
            ELSE DO:
                /* a wall: stop at the edge of the pixel it is in */
                poBuddy:VX = 0.
                poBuddy:X256 = px * 256 + (IF dir > 0 THEN 255 ELSE 0).
                LEAVE.
            END.
        END.
        IF CheckDrowned(poBuddy) THEN RETURN.
        /* up and down */
        py = poBuddy:Y().
        poBuddy:Y256 = poBuddy:Y256 + poBuddy:VY.
        dir = (IF poBuddy:Y() > py THEN 1 ELSE -1).
        moves = ABSOLUTE(poBuddy:Y() - py).
        DO n = 1 TO moves:
            IF dir < 0 THEN DO:
                IF poTerrain:IsSolid(poBuddy:X(), py - 1 - BuddyRules:BuddyHeight()) THEN DO:
                    /* the head hits rock */
                    poBuddy:VY = 0.
                    poBuddy:Y256 = py * 256.
                    LEAVE.
                END.
                py = py - 1.
                poBuddy:PeakY = MINIMUM(poBuddy:PeakY, py).
            END.
            ELSE DO:
                py = py + 1.
                IF py >= BuddyRules:WaterRow() THEN DO:
                    poBuddy:Y256 = py * 256.
                    Drown(poBuddy).
                    RETURN.
                END.
                IF poTerrain:IsSolid(poBuddy:X(), py) THEN DO:
                    fall = py - poBuddy:PeakY.
                    poBuddy:Y256 = py * 256.
                    poBuddy:VX = 0.
                    poBuddy:VY = 0.
                    poBuddy:State = BuddyState:Standing.
                    poBuddy:Landed = TRUE.
                    poBuddy:LastFallDamage = MAXIMUM(INTEGER(TRUNCATE((fall - BuddyRules:FallFree()) / 2, 0)), 0).
                    poBuddy:Hurt(poBuddy:LastFallDamage).
                    poBuddy:PeakY = py.
                    RETURN.
                END.
            END.
        END.
        IF poBuddy:Y() >= BuddyRules:WaterRow() THEN Drown(poBuddy).
        poBuddy:PeakY = MINIMUM(poBuddy:PeakY, poBuddy:Y()).
    END METHOD.

    /* Whether a buddy in the air can move into a column: its body has to be clear of rock there. */
    METHOD PRIVATE LOGICAL CanMoveTo(INPUT poBuddy AS Buddy, INPUT poTerrain AS Terrain, INPUT piX AS INTEGER):
        IF piX < 0 OR piX >= Terrain:Width() THEN RETURN TRUE.
        RETURN BodyClear(poTerrain, piX, poBuddy:Y()).
    END METHOD.

END CLASS.
