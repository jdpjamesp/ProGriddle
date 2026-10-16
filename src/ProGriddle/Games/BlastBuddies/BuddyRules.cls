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

END CLASS.
