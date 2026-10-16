/* One buddy (a goon in the design): where it stands, how it moves, its health, its name and its team. The position is that of the middle
   of its feet, in 256ths of a pixel (X256 and Y256), and X and Y are the pixel it is in. When it stands, Y is the first row of ground under
   its feet, so its body fills the rows above that. VX and VY are the speed in 256ths of a pixel a frame. PeakY is the highest row (smallest)
   reached since it left the ground, which is what a fall is measured from. Landed is true for the one step in which it came down, and
   LastFallDamage is what that fall cost. BuddyPhysics moves it; the game keeps the rest. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.Buddy FINAL:

    DEFINE PUBLIC PROPERTY X256 AS INTEGER NO-UNDO GET. SET.
    DEFINE PUBLIC PROPERTY Y256 AS INTEGER NO-UNDO GET. SET.
    DEFINE PUBLIC PROPERTY VX AS INTEGER NO-UNDO GET. SET.
    DEFINE PUBLIC PROPERTY VY AS INTEGER NO-UNDO GET. SET.
    DEFINE PUBLIC PROPERTY PeakY AS INTEGER NO-UNDO GET. SET.
    DEFINE PUBLIC PROPERTY Landed AS LOGICAL NO-UNDO GET. SET.
    DEFINE PUBLIC PROPERTY LastFallDamage AS INTEGER NO-UNDO GET. SET.

    /* True once the game has seen the buddy die and shown it (a dead buddy is buried one at a time at the end of a turn). A buried buddy
       stays as a gravestone and blasts leave it alone. */
    DEFINE PUBLIC PROPERTY Buried AS LOGICAL NO-UNDO GET. SET.

    /* 1 for facing right, -1 for facing left. */
    DEFINE PUBLIC PROPERTY Facing AS INTEGER NO-UNDO INITIAL 1 GET. SET.

    /* 0 to 100. A buddy at 0 is dead (the game decides when it is told so). */
    DEFINE PUBLIC PROPERTY Health AS INTEGER NO-UNDO GET. SET.

    DEFINE PUBLIC PROPERTY State AS BuddyState NO-UNDO GET. SET.

    /* The short name shown over the buddy, and the team number (1 to 4) it plays for. */
    DEFINE PUBLIC PROPERTY BuddyName AS CHARACTER NO-UNDO GET. PRIVATE SET.
    DEFINE PUBLIC PROPERTY Team AS INTEGER NO-UNDO GET. PRIVATE SET.

    CONSTRUCTOR PUBLIC Buddy(INPUT pcName AS CHARACTER, INPUT piTeam AS INTEGER, INPUT piX AS INTEGER, INPUT piGroundY AS INTEGER):
        IF pcName = ? OR pcName = "" THEN UNDO, THROW NEW GridException("A buddy needs a name").
        IF piTeam < 1 OR piTeam > 4 THEN UNDO, THROW NEW GridException("A team is 1 to 4, not " + STRING(piTeam)).
        BuddyName = pcName.
        Team = piTeam.
        Health = BuddyRules:StartHealth().
        State = BuddyState:Standing.
        PlaceAt(piX, piGroundY).
    END CONSTRUCTOR.

    /* The pixel column the feet are in. */
    METHOD PUBLIC INTEGER X():
        RETURN BuddyRules:Pixel(X256).
    END METHOD.

    /* The pixel row the feet are in. */
    METHOD PUBLIC INTEGER Y():
        RETURN BuddyRules:Pixel(Y256).
    END METHOD.

    /* Puts the buddy standing, still, with its feet on a pixel. */
    METHOD PUBLIC VOID PlaceAt(INPUT piX AS INTEGER, INPUT piGroundY AS INTEGER):
        X256 = piX * 256.
        Y256 = piGroundY * 256.
        VX = 0.
        VY = 0.
        PeakY = piGroundY.
        Landed = FALSE.
        LastFallDamage = 0.
        State = BuddyState:Standing.
    END METHOD.

    /* Takes health away, down to 0 and no lower. Returns what was really taken. */
    METHOD PUBLIC INTEGER Hurt(INPUT piAmount AS INTEGER):
        DEFINE VARIABLE taken AS INTEGER NO-UNDO.
        IF piAmount < 0 THEN UNDO, THROW NEW GridException("Damage cannot be negative").
        taken = MINIMUM(piAmount, Health).
        Health = Health - taken.
        RETURN taken.
    END METHOD.

    /* Whether the buddy has no health left, or has drowned. */
    METHOD PUBLIC LOGICAL IsDead():
        RETURN Health <= 0 OR State = BuddyState:Drowned.
    END METHOD.

END CLASS.
