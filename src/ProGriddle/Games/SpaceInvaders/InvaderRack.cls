/* The rack of 55 invaders (5 rows of 11) and the way it moves, which is what gives Space Invaders its feel.
   The rack holds no pictures, only where each invader is and which are alive, and says what moves.

   The arcade moved ONE invader a frame, not the whole rack at once. Step moves the next live invader along
   by 2 cells, going bottom row first, left to right, and when the last live invader of a pass has moved the
   pass is over and the walking pose of the pictures changes. So a full rack takes 55 frames to cross one
   step (about a second at 60 frames a second), and as invaders are shot the passes get shorter and the rack
   speeds up, down to one invader that moves every frame. Nothing is timed: the speed-up is simply how many
   are left.

   When any invader reaches the edge of the field (8 cells in from either side) the pass finishes as usual
   and the next pass is a drop: every invader moves 8 cells down instead of sideways, and the direction turns
   round. The pass after that goes the other way.

   Invaders are numbered row * 11 + column, row 0 the top (the squid, 30 points), rows 1 and 2 the crabs
   (20) and rows 3 and 4 the octopuses (10). They are 16 cells apart each way, with each picture centred in
   its 16 cell slot. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.SpaceInvaders.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.SpaceInvaders.InvaderRack FINAL:

    &SCOPED-DEFINE ROWS 5
    &SCOPED-DEFINE COLS 11
    &SCOPED-DEFINE COUNT 55
    &SCOPED-DEFINE LEFT-LIMIT 8
    &SCOPED-DEFINE RIGHT-LIMIT 216

    DEFINE PRIVATE VARIABLE mAlive   AS LOGICAL NO-UNDO EXTENT 55.
    DEFINE PRIVATE VARIABLE mX       AS INTEGER NO-UNDO EXTENT 55.
    DEFINE PRIVATE VARIABLE mY       AS INTEGER NO-UNDO EXTENT 55.
    /* where in the order of moving (0 to 54, bottom row first) the next invader to move is */
    DEFINE PRIVATE VARIABLE mCursor  AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mEdgeHit AS LOGICAL NO-UNDO.

    /* 1 while the rack goes right, -1 while it goes left. */
    DEFINE PUBLIC PROPERTY Direction AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* True while the pass being made is the drop, and not a step sideways. */
    DEFINE PUBLIC PROPERTY Dropping AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    /* The walking pose of the pictures, 0 or 1. It changes at the end of every pass. */
    DEFINE PUBLIC PROPERTY Pose AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Passes finished since Reset. */
    DEFINE PUBLIC PROPERTY Passes AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Invaders still alive. */
    DEFINE PUBLIC PROPERTY AliveCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* Where the invader that Step moved last was before it moved. */
    DEFINE PUBLIC PROPERTY OldX AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY OldY AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    /* True when the last Step finished a pass. */
    DEFINE PUBLIC PROPERTY PassEnded AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC InvaderRack():
        Reset(0).
    END CONSTRUCTOR.

    METHOD PUBLIC STATIC INTEGER Rows():
        RETURN {&ROWS}.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Columns():
        RETURN {&COLS}.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER Total():
        RETURN {&COUNT}.
    END METHOD.

    /* The distance between two invaders, across and down, and the height of every picture. */
    METHOD PUBLIC STATIC INTEGER Pitch():
        RETURN 16.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER SpriteHeight():
        RETURN 8.
    END METHOD.

    /* The cell the left side of the rack's first slot starts at, so the rack is centred in 224. */
    METHOD PUBLIC STATIC INTEGER FirstSlotX():
        RETURN 24.
    END METHOD.

    /* An invader's x may not go below this, and its right side may not go past RightLimit. */
    METHOD PUBLIC STATIC INTEGER LeftLimit():
        RETURN {&LEFT-LIMIT}.
    END METHOD.

    METHOD PUBLIC STATIC INTEGER RightLimit():
        RETURN {&RIGHT-LIMIT}.
    END METHOD.

    /* The kind of invader in a row: 0 squid, 1 crab, 2 octopus. */
    METHOD PUBLIC STATIC INTEGER KindOfRow(INPUT piRow AS INTEGER):
        IF piRow = ? OR piRow < 0 OR piRow >= {&ROWS} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A rack row is 0 to &1, not &2", {&ROWS} - 1, piRow)).
        RETURN (IF piRow = 0 THEN 0 ELSE IF piRow <= 2 THEN 1 ELSE 2).
    END METHOD.

    /* The width of the picture of a kind of invader: 8, 11 or 12. */
    METHOD PUBLIC STATIC INTEGER WidthOfKind(INPUT piKind AS INTEGER):
        IF piKind = ? OR piKind < 0 OR piKind > 2 THEN
            UNDO, THROW NEW GridException("An invader kind is 0, 1 or 2, not " + STRING(piKind)).
        RETURN (IF piKind = 0 THEN 8 ELSE IF piKind = 1 THEN 11 ELSE 12).
    END METHOD.

    /* The points an invader of a kind is worth: 30, 20 or 10. */
    METHOD PUBLIC STATIC INTEGER PointsOfKind(INPUT piKind AS INTEGER):
        IF piKind = ? OR piKind < 0 OR piKind > 2 THEN
            UNDO, THROW NEW GridException("An invader kind is 0, 1 or 2, not " + STRING(piKind)).
        RETURN (IF piKind = 0 THEN 30 ELSE IF piKind = 1 THEN 20 ELSE 10).
    END METHOD.

    /* Puts all 55 invaders back, alive, with the top row of pictures at row piTopY, the rack going
       right and the next invader to move the bottom left one. */
    METHOD PUBLIC VOID Reset(INPUT piTopY AS INTEGER):
        DEFINE VARIABLE rw  AS INTEGER NO-UNDO.
        DEFINE VARIABLE cl  AS INTEGER NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DO rw = 0 TO {&ROWS} - 1:
            DO cl = 0 TO {&COLS} - 1:
                i = rw * {&COLS} + cl + 1.
                mAlive[i] = TRUE.
                mX[i] = FirstSlotX() + cl * Pitch() + INTEGER(TRUNCATE((Pitch() - WidthOfKind(KindOfRow(rw))) / 2, 0)).
                mY[i] = piTopY + rw * Pitch().
            END.
        END.
        AliveCount = {&COUNT}.
        Direction = 1.
        Dropping = FALSE.
        Pose = 0.
        Passes = 0.
        mCursor = 0.
        mEdgeHit = FALSE.
        PassEnded = FALSE.
    END METHOD.

    METHOD PUBLIC LOGICAL Alive(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mAlive[piIndex + 1].
    END METHOD.

    /* The left side of an invader's picture, and its top. They go on being the last place the invader was
       after it is shot. */
    METHOD PUBLIC INTEGER X(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mX[piIndex + 1].
    END METHOD.

    METHOD PUBLIC INTEGER Y(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mY[piIndex + 1].
    END METHOD.

    /* The row (0 at the top) and the column (0 at the left) an invader started in. */
    METHOD PUBLIC STATIC INTEGER RowOf(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN INTEGER(TRUNCATE(piIndex / {&COLS}, 0)).
    END METHOD.

    METHOD PUBLIC STATIC INTEGER ColumnOf(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN piIndex MODULO {&COLS}.
    END METHOD.

    /* 0 squid, 1 crab, 2 octopus. */
    METHOD PUBLIC STATIC INTEGER KindOf(INPUT piIndex AS INTEGER):
        RETURN KindOfRow(RowOf(piIndex)).
    END METHOD.

    METHOD PUBLIC INTEGER WidthOf(INPUT piIndex AS INTEGER):
        RETURN WidthOfKind(KindOf(piIndex)).
    END METHOD.

    /* Shoots an invader. Throws GridException when it is dead already. */
    METHOD PUBLIC VOID Kill(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        IF NOT mAlive[piIndex + 1] THEN UNDO, THROW NEW GridException("Invader " + STRING(piIndex) + " is dead already").
        mAlive[piIndex + 1] = FALSE.
        AliveCount = AliveCount - 1.
        /* when the one that was next to move dies, the cursor still points at its place, which Step skips */
    END METHOD.

    /* Moves the next live invader on: 2 cells sideways, or 8 down in a drop pass. Returns its number, or -1 when
       none is alive. OldX and OldY say where it was, so the game can take its picture off and put it on
       again. PassEnded says whether it was the last of the pass. */
    METHOD PUBLIC INTEGER Step():
        DEFINE VARIABLE p     AS INTEGER NO-UNDO.
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE nextP AS INTEGER NO-UNDO.
        PassEnded = FALSE.
        IF AliveCount = 0 THEN RETURN -1.
        p = NextAliveFrom(mCursor).
        IF p < 0 THEN p = NextAliveFrom(0).
        i = IndexOfOrder(p).
        OldX = mX[i + 1].
        OldY = mY[i + 1].
        IF Dropping THEN mY[i + 1] = mY[i + 1] + 8.
        ELSE DO:
            mX[i + 1] = mX[i + 1] + 2 * Direction.
            IF mX[i + 1] <= LeftLimit() OR mX[i + 1] + WidthOf(i) >= RightLimit() THEN mEdgeHit = TRUE.
        END.
        nextP = NextAliveFrom(p + 1).
        IF nextP < 0 THEN DO:
            EndPass().
            mCursor = 0.
        END.
        ELSE mCursor = nextP.
        RETURN i.
    END METHOD.

    /* The lowest live invader in a column (0 to 10), or -1 when the column is empty. */
    METHOD PUBLIC INTEGER LowestInColumn(INPUT piColumn AS INTEGER):
        DEFINE VARIABLE rw AS INTEGER NO-UNDO.
        IF piColumn = ? OR piColumn < 0 OR piColumn >= {&COLS} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("A rack column is 0 to &1, not &2", {&COLS} - 1, piColumn)).
        DO rw = {&ROWS} - 1 TO 0 BY -1:
            IF mAlive[rw * {&COLS} + piColumn + 1] THEN RETURN rw * {&COLS} + piColumn.
        END.
        RETURN -1.
    END METHOD.

    /* The row just below the lowest live invader's picture, or -1 when none is alive. */
    METHOD PUBLIC INTEGER Bottom():
        DEFINE VARIABLE i      AS INTEGER NO-UNDO.
        DEFINE VARIABLE lowest AS INTEGER NO-UNDO INITIAL -1.
        DO i = 1 TO {&COUNT}:
            IF mAlive[i] AND mY[i] + SpriteHeight() > lowest THEN lowest = mY[i] + SpriteHeight().
        END.
        RETURN lowest.
    END METHOD.

    /* The live invader whose picture covers a cell, or -1. A box test, which is enough to tell which
       invader a cell that is known to belong to one of them belongs to. */
    METHOD PUBLIC INTEGER At(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DO i = 0 TO {&COUNT} - 1:
            IF mAlive[i + 1] AND piX >= mX[i + 1] AND piX < mX[i + 1] + WidthOf(i)
               AND piY >= mY[i + 1] AND piY < mY[i + 1] + SpriteHeight() THEN RETURN i.
        END.
        RETURN -1.
    END METHOD.

    /* The place in the order of moving (0 to 54) of the first live invader at or after piFrom, or -1. */
    METHOD PRIVATE INTEGER NextAliveFrom(INPUT piFrom AS INTEGER):
        DEFINE VARIABLE p AS INTEGER NO-UNDO.
        DO p = piFrom TO {&COUNT} - 1:
            IF mAlive[IndexOfOrder(p) + 1] THEN RETURN p.
        END.
        RETURN -1.
    END METHOD.

    /* The invader that moves at a place in the order: the bottom row first, each row left to right. */
    METHOD PRIVATE STATIC INTEGER IndexOfOrder(INPUT piPlace AS INTEGER):
        RETURN ({&ROWS} - 1 - INTEGER(TRUNCATE(piPlace / {&COLS}, 0))) * {&COLS} + piPlace MODULO {&COLS}.
    END METHOD.

    METHOD PRIVATE VOID EndPass():
        PassEnded = TRUE.
        Passes = Passes + 1.
        Pose = 1 - Pose.
        IF Dropping THEN Dropping = FALSE.
        ELSE IF mEdgeHit THEN DO:
            Dropping = TRUE.
            Direction = - Direction.
        END.
        mEdgeHit = FALSE.
    END METHOD.

    METHOD PRIVATE STATIC VOID CheckIndex(INPUT piIndex AS INTEGER):
        IF piIndex = ? OR piIndex < 0 OR piIndex >= {&COUNT} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("An invader is 0 to &1, not &2", {&COUNT} - 1, piIndex)).
    END METHOD.

END CLASS.
