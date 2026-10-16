/* The numbers of the buddy physics of Blast Buddies, in one place to tune by feel. Lengths are pixels, and positions and speeds are in
   256ths of a pixel (a speed is that much a frame at 60 frames a second), so everything is whole numbers and the same every time. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.BlastBuddies.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.BlastBuddies.BuddyRules FINAL:

    /* How many parts of a pixel there are: 256. */
    METHOD PUBLIC STATIC INTEGER Scale():
        RETURN 256.
    END METHOD.

    /* The pull of gravity on anything in the air, as speed gained every frame (0.15 of a pixel). */
    METHOD PUBLIC STATIC INTEGER Gravity():
        RETURN 38.
    END METHOD.

    /* The fastest anything falls, 8 pixels a frame. */
    METHOD PUBLIC STATIC INTEGER TerminalSpeed():
        RETURN 2048.
    END METHOD.

    /* How tall a buddy is, in pixels above its feet. */
    METHOD PUBLIC STATIC INTEGER BuddyHeight():
        RETURN 11.
    END METHOD.

    /* The biggest step up a walking buddy makes in one pixel of walking. */
    METHOD PUBLIC STATIC INTEGER StepUp():
        RETURN 3.
    END METHOD.

    /* The row where the water starts. A buddy whose feet reach it is drowned. */
    METHOD PUBLIC STATIC INTEGER WaterRow():
        RETURN 226.
    END METHOD.

    /* The health every buddy starts with. */
    METHOD PUBLIC STATIC INTEGER StartHealth():
        RETURN 100.
    END METHOD.

    /* A fall of this many pixels or fewer does no harm. */
    METHOD PUBLIC STATIC INTEGER FallFree():
        RETURN 24.
    END METHOD.

    /* The upward speed of a hop (6 pixels high), and the speed it goes forward. */
    METHOD PUBLIC STATIC INTEGER HopLift():
        RETURN 343.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER HopForward():
        RETURN 154.
    END METHOD.

    /* The upward speed of a backflip (11 pixels high), and the speed it goes back (9 pixels over the flip). */
    METHOD PUBLIC STATIC INTEGER FlipLift():
        RETURN 465.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER FlipBack():
        RETURN 96.
    END METHOD.

    /* How long the phases last, in frames of a sixtieth of a second: the arrival 5 s, the banner 1.5 s, a turn 45 s, the retreat after a
       shot 3 s. Resolve ends when everything has been still for SettleFrames. */
    METHOD PUBLIC STATIC INTEGER ArrivalFrames():
        RETURN 300.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BannerFrames():
        RETURN 90.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER TurnFrames():
        RETURN 2700.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER RetreatFrames():
        RETURN 180.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER SettleFrames():
        RETURN 30.
    END METHOD.

    /* The wind is a whole number from minus this to this each turn. */
    METHOD PUBLIC STATIC INTEGER WindMax():
        RETURN 10.
    END METHOD.

    /* The aim is a number of steps from straight up (0) through level (16) to straight down (32), and a new turn starts at AimStart. A
       held aim key moves it one step every AimRepeatFrames. */
    METHOD PUBLIC STATIC INTEGER AimStart():
        RETURN 12.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER AimRepeatFrames():
        RETURN 3.
    END METHOD.

    /* Holding the fire key for this many frames (1.5 s) is full power, and the shot goes by itself when it is reached. */
    METHOD PUBLIC STATIC INTEGER ChargeFrames():
        RETURN 90.
    END METHOD.

    /* A second jump key within this many frames (250 ms) of a hop turns it into a backflip. */
    METHOD PUBLIC STATIC INTEGER DoubleJumpFrames():
        RETURN 15.
    END METHOD.

    /* Walking is one pixel every 40 ms: a held direction adds WalkGain every frame, and a pixel is walked each time WalkNeeded is reached. */
    METHOD PUBLIC STATIC INTEGER WalkGain():
        RETURN 5.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER WalkNeeded():
        RETURN 12.
    END METHOD.

    /* A number of 256ths of a pixel as whole pixels, rounding down (so -1 is pixel -1, not 0). */
    METHOD PUBLIC STATIC INTEGER Pixel(INPUT piValue AS INTEGER):
        IF piValue >= 0 THEN RETURN INTEGER(TRUNCATE(piValue / 256, 0)).
        RETURN - INTEGER(TRUNCATE((255 - piValue) / 256, 0)).
    END METHOD.

    /* The bazooka rocket: its blast radius and the damage at the very middle of the blast. The damage falls away in a straight line to
       nothing at the edge of the blast plus BlastReach pixels. */
    METHOD PUBLIC STATIC INTEGER BazookaRadius():
        RETURN 20.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BazookaDamage():
        RETURN 50.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER BlastReach():
        RETURN 8.
    END METHOD.

    /* The speed a buddy is thrown at by a blast right at its middle, in 256ths of a pixel a frame (4 pixels), and the lift added to it. */
    METHOD PUBLIC STATIC INTEGER KnockbackMax():
        RETURN 1024.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER KnockbackLift():
        RETURN 64.
    END METHOD.

    /* The speed of a shot by the power: 0.5 pixel a frame at no power, 6 at full power. */
    METHOD PUBLIC STATIC INTEGER ShotSpeedMin():
        RETURN 128.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ShotSpeedMax():
        RETURN 1536.
    END METHOD.

    /* How many frames a shot may fly before it is given up, and how many frames its own buddy cannot be hit by it. */
    METHOD PUBLIC STATIC INTEGER ShotMaxFrames():
        RETURN 1200.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ShotSafeFrames():
        RETURN 8.
    END METHOD.

    /* How long a dying buddy is shown before it is buried, 1 second. */
    METHOD PUBLIC STATIC INTEGER DeathFrames():
        RETURN 60.
    END METHOD.

END CLASS.
