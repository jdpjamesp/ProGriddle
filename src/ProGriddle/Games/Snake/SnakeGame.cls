/* The rules of Snake, as a real time game. A snake crawls across a bounded board, one cell at a
   time, always the way it is facing. The player steers with TurnUp, TurnRight, TurnDown and
   TurnLeft. Eating the food makes the snake one cell longer and scores 10, and a new piece of
   food appears in a random empty cell. The game is over when the head hits a wall or the snake's
   own body. Filling the whole board wins.

   Rules and numbers:
   - The snake moves one cell every StepMs milliseconds: 150 at first, 5 less for each piece of
     food eaten, never under 60. Tick adds up the time it is given, so a test drives the game
     with plain numbers, and a stall of more than half a second (a dragged window) is cut to half
     a second rather than catching up with a burst of steps.
   - A turn is kept until the next step. Up to two turns can wait, so two quick key presses (up
     then left) make both turns on successive steps. A turn that would send the snake straight
     back on itself, judged against the last turn waiting, is refused, as is a turn that repeats
     the way it is already going.
   - The tail leaves its cell on the step the head arrives, so the head may enter the cell the
     tail is just leaving.
   - The game asks its random source once for each piece of food, for a number below the count
     of empty cells (the nth empty cell, counting along the rows).
   - While Paused, or after the game is over, Tick and every turn do nothing.
   - With WaitForKey on, a new game does not start moving until the first turn key: the snake waits
     (Waiting is true) and Tick does nothing. The first turn starts it, and a turn that repeats the way
     it is facing does too, since it is only a way to say "go". A turn that would reverse it does not.

   The snake lives in a ring of cell indexes, tail to head, made once, so a step allocates
   nothing. The grid shows one layer, "view" (see ViewCodes.i). The game owns its grid, and
   Dispose releases it. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.
USING ProGriddle.Games.Snake.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Snake.SnakeGame FINAL INHERITS AbstractGame IMPLEMENTS IRealTimeGame:

    {ProGriddle/Games/Snake/ViewCodes.i}

    /* the slowest and the fastest step, and how much faster each piece of food makes it */
    &SCOPED-DEFINE SLOWEST-MS 150
    &SCOPED-DEFINE FASTEST-MS 60
    &SCOPED-DEFINE SPEED-UP-MS 5
    /* the most time one Tick will count */
    &SCOPED-DEFINE MOST-MS 500

    DEFINE PRIVATE VARIABLE mRandom    AS IRandom NO-UNDO.
    DEFINE PRIVATE VARIABLE mWidth     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mHeight    AS INTEGER NO-UNDO.
    /* the ring of cell indexes, tail to head: positions mTail to mHead, wrapping at the cell count */
    DEFINE PRIVATE VARIABLE mBody      AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mTail      AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mHead      AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mLength    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mDirection AS INTEGER NO-UNDO.
    /* turns waiting for a step, oldest first: 0 up, 1 right, 2 down, 3 left */
    DEFINE PRIVATE VARIABLE mQueue1    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mQueue2    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mQueued    AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mFood      AS INTEGER NO-UNDO INITIAL -1.
    DEFINE PRIVATE VARIABLE mEaten     AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mAcc       AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mWaitForKey AS LOGICAL NO-UNDO.

    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    /* True while a new game is waiting for its first turn key. Tick does nothing then. */
    DEFINE PUBLIC PROPERTY Waiting AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    /* When true, each new game waits for the first turn key before it moves (see Waiting). Setting it on
       a game that has not begun to move makes that game wait now. Off by default, so a test or a script
       that drives the clock gets a snake that moves. */
    DEFINE PUBLIC PROPERTY WaitForKey AS LOGICAL NO-UNDO
        GET():
            RETURN mWaitForKey.
        END GET.
        SET(INPUT plValue AS LOGICAL):
            mWaitForKey = plValue.
            IF NOT plValue THEN Waiting = FALSE.
            ELSE IF Generation = 0 AND NOT IsOver THEN Waiting = TRUE.
        END SET.

    /* Points: 10 for each piece of food eaten. */
    DEFINE PUBLIC PROPERTY Score AS INTEGER NO-UNDO
        GET():
            RETURN mEaten * 10.
        END GET.

    /* Cells the snake covers. */
    DEFINE PUBLIC PROPERTY Length AS INTEGER NO-UNDO
        GET():
            RETURN mLength.
        END GET.

    /* Pieces of food eaten in this game. */
    DEFINE PUBLIC PROPERTY FoodEaten AS INTEGER NO-UNDO
        GET():
            RETURN mEaten.
        END GET.

    /* 1 at the start, one more for each piece of food, until the speed stops rising at level 19. */
    DEFINE PUBLIC PROPERTY Level AS INTEGER NO-UNDO
        GET():
            RETURN LevelFor(mEaten).
        END GET.

    /* Milliseconds between steps now. */
    DEFINE PUBLIC PROPERTY StepMs AS INTEGER NO-UNDO
        GET():
            RETURN StepMsFor(mEaten).
        END GET.

    /* The way the snake is facing now, 0 up, 1 right, 2 down, 3 left. A turn that is waiting for the
       next step does not show here until the step is made. */
    DEFINE PUBLIC PROPERTY Direction AS INTEGER NO-UNDO
        GET():
            RETURN mDirection.
        END GET.

    /* Up, Right, Down or Left. */
    DEFINE PUBLIC PROPERTY DirectionName AS CHARACTER NO-UNDO
        GET():
            RETURN ENTRY(mDirection + 1, "Up,Right,Down,Left").
        END GET.

    /* True when the snake has filled the board. The game is over then as well. */
    DEFINE PUBLIC PROPERTY HasWon AS LOGICAL NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY HeadX AS INTEGER NO-UNDO
        GET():
            RETURN mBody[mHead + 1] MODULO mWidth.
        END GET.

    DEFINE PUBLIC PROPERTY HeadY AS INTEGER NO-UNDO
        GET():
            RETURN INTEGER(TRUNCATE(mBody[mHead + 1] / mWidth, 0)).
        END GET.

    /* Where the food is, or -1 when there is none (the board is full). */
    DEFINE PUBLIC PROPERTY FoodX AS INTEGER NO-UNDO
        GET():
            RETURN (IF mFood < 0 THEN -1 ELSE mFood MODULO mWidth).
        END GET.

    DEFINE PUBLIC PROPERTY FoodY AS INTEGER NO-UNDO
        GET():
            RETURN (IF mFood < 0 THEN -1 ELSE INTEGER(TRUNCATE(mFood / mWidth, 0))).
        END GET.

    /* The grid must have exactly one layer, named "view", and be at least 5 x 5. */
    CONSTRUCTOR PUBLIC SnakeGame(INPUT poGrid AS Grid, INPUT poRandom AS IRandom):
        SUPER("Snake", poGrid).
        CheckGrid(poGrid).
        IF NOT VALID-OBJECT(poRandom) THEN UNDO, THROW NEW GridException("A Snake game needs a random source").
        mRandom = poRandom.
        mWidth = poGrid:Width.
        mHeight = poGrid:Height.
        EXTENT(mBody) = poGrid:CellCount.
        Initialise().
    END CONSTRUCTOR.

    /* Swaps the board for another, which is how the window changes the board size, and starts a new game
       on it. The old grid is disposed. Throws GridException, and changes nothing, unless the grid has
       exactly one layer, named "view", and is at least 5 x 5. */
    METHOD PUBLIC VOID Replace(INPUT poGrid AS Grid):
        DEFINE VARIABLE oldGrid AS Grid NO-UNDO.
        CheckGrid(poGrid).
        oldGrid = Grid.
        Grid = poGrid.
        mWidth = poGrid:Width.
        mHeight = poGrid:Height.
        EXTENT(mBody) = poGrid:CellCount.
        mFood = -1.
        Initialise().
        oldGrid:Dispose().
    END METHOD.

    /* Milliseconds between steps after piEaten pieces of food. */
    METHOD PUBLIC STATIC INTEGER StepMsFor(INPUT piEaten AS INTEGER):
        RETURN MAX({&FASTEST-MS}, {&SLOWEST-MS} - {&SPEED-UP-MS} * MAX(0, piEaten)).
    END METHOD.

    /* The level after piEaten pieces of food: 1, then one more for each, to 19. */
    METHOD PUBLIC STATIC INTEGER LevelFor(INPUT piEaten AS INTEGER):
        RETURN INTEGER(({&SLOWEST-MS} - StepMsFor(piEaten)) / {&SPEED-UP-MS}) + 1.
    END METHOD.

    /* Turns the snake to face up at the next step. Returns true when the turn was taken, false when it
       was refused: the snake is paused or over, the turn repeats the way it is going (or the turn
       before it), it would reverse the snake, or two turns are already waiting. */
    METHOD PUBLIC LOGICAL TurnUp():
        RETURN Steer(0).
    END METHOD.

    METHOD PUBLIC LOGICAL TurnRight():
        RETURN Steer(1).
    END METHOD.

    METHOD PUBLIC LOGICAL TurnDown():
        RETURN Steer(2).
    END METHOD.

    METHOD PUBLIC LOGICAL TurnLeft():
        RETURN Steer(3).
    END METHOD.

    /* Moves time on. Makes a step each time StepMs has gone by. Returns true when at least one step
       was made, so the controller redraws only when it has to. */
    METHOD PUBLIC LOGICAL Tick(INPUT piElapsedMs AS INTEGER):
        DEFINE VARIABLE moved AS LOGICAL NO-UNDO.
        IF Paused OR IsOver OR Waiting OR piElapsedMs <= 0 THEN RETURN FALSE.
        mAcc = mAcc + MIN(piElapsedMs, {&MOST-MS}).
        DO WHILE mAcc >= StepMs AND NOT IsOver:
            mAcc = mAcc - StepMs.
            Step().
            moved = TRUE.
        END.
        RETURN moved.
    END METHOD.

    /* Starts a game with the snake made of the cells in pcBody, tail first, head last, each written
       "x,y" and separated by semicolons, as in "2,4;3,4;4,4", facing pcDirection (Up, Right, Down
       or Left). Food goes in a random empty cell as usual. The score and the speed start again.
       Throws GridException, and leaves the game as it was, when a cell is off the board, repeats,
       or is not next to the one before it, or when the head faces back along the body. */
    METHOD PUBLIC VOID StartWith(INPUT pcBody AS CHARACTER, INPUT pcDirection AS CHARACTER):
        DEFINE VARIABLE n   AS INTEGER NO-UNDO.
        DEFINE VARIABLE i   AS INTEGER NO-UNDO.
        DEFINE VARIABLE j   AS INTEGER NO-UNDO.
        DEFINE VARIABLE x   AS INTEGER NO-UNDO.
        DEFINE VARIABLE y   AS INTEGER NO-UNDO.
        DEFINE VARIABLE dir AS INTEGER NO-UNDO.
        DEFINE VARIABLE xs  AS INTEGER NO-UNDO EXTENT.
        DEFINE VARIABLE ys  AS INTEGER NO-UNDO EXTENT.
        dir = LOOKUP(pcDirection, "Up,Right,Down,Left") - 1.
        IF pcDirection = ? OR dir < 0 THEN UNDO, THROW NEW GridException("Unknown Snake direction: " + STRING(pcDirection)).
        IF pcBody = ? OR pcBody = "" THEN UNDO, THROW NEW GridException("A snake needs at least one cell").
        n = NUM-ENTRIES(pcBody, ";").
        EXTENT(xs) = n.
        EXTENT(ys) = n.
        /* check everything before changing anything */
        DO i = 1 TO n:
            IF NUM-ENTRIES(ENTRY(i, pcBody, ";")) <> 2 THEN
                UNDO, THROW NEW GridException("A snake cell is written x,y, not " + ENTRY(i, pcBody, ";")).
            x = INTEGER(ENTRY(1, ENTRY(i, pcBody, ";"))) NO-ERROR.
            IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW GridException("A snake cell is written x,y, not " + ENTRY(i, pcBody, ";")).
            y = INTEGER(ENTRY(2, ENTRY(i, pcBody, ";"))) NO-ERROR.
            IF ERROR-STATUS:ERROR THEN UNDO, THROW NEW GridException("A snake cell is written x,y, not " + ENTRY(i, pcBody, ";")).
            IF x < 0 OR x >= mWidth OR y < 0 OR y >= mHeight THEN
                UNDO, THROW NEW GridException(SUBSTITUTE("The snake cell &1,&2 is off the board", x, y)).
            DO j = 1 TO i - 1:
                IF xs[j] = x AND ys[j] = y THEN UNDO, THROW NEW GridException(SUBSTITUTE("The snake covers &1,&2 twice", x, y)).
            END.
            IF i > 1 AND ABSOLUTE(x - xs[i - 1]) + ABSOLUTE(y - ys[i - 1]) <> 1 THEN
                UNDO, THROW NEW GridException(SUBSTITUTE("The snake cell &1,&2 is not next to the one before it", x, y)).
            xs[i] = x.
            ys[i] = y.
        END.
        IF n > 1 AND xs[n] + (IF dir = 1 THEN 1 ELSE IF dir = 3 THEN -1 ELSE 0) = xs[n - 1]
                 AND ys[n] + (IF dir = 2 THEN 1 ELSE IF dir = 0 THEN -1 ELSE 0) = ys[n - 1] THEN
            UNDO, THROW NEW GridException("The snake cannot face back along its own body").
        /* now start the game */
        Generation = 0.
        IsOver = FALSE.
        HasWon = FALSE.
        Grid:Store:FillLayer(1, {&VIEW-EMPTY}).
        mTail = 0.
        mHead = n - 1.
        mLength = n.
        DO i = 1 TO n:
            mBody[i] = ys[i] * mWidth + xs[i].
            Grid:Store:SetCellAt(1, mBody[i], (IF i = n THEN {&VIEW-HEAD} ELSE {&VIEW-BODY})).
        END.
        mDirection = dir.
        mQueued = 0.
        mEaten = 0.
        mAcc = 0.
        mFood = -1.
        PlaceFood().
        Waiting = mWaitForKey AND NOT IsOver.
    END METHOD.

    /* Puts the food in the empty cell at piX, piY, taking it from where it was. Throws GridException
       when the cell is off the board or the snake is on it. */
    METHOD PUBLIC VOID SetFood(INPUT piX AS INTEGER, INPUT piY AS INTEGER):
        DEFINE VARIABLE target AS INTEGER NO-UNDO.
        IF piX < 0 OR piX >= mWidth OR piY < 0 OR piY >= mHeight THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("The food cannot go at &1,&2, which is off the board", piX, piY)).
        target = piY * mWidth + piX.
        IF target <> mFood AND Grid:Store:GetCellAt(1, target) <> {&VIEW-EMPTY} THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("The food cannot go at &1,&2, where the snake is", piX, piY)).
        IF mFood >= 0 THEN Grid:Store:SetCellAt(1, mFood, {&VIEW-EMPTY}).
        mFood = target.
        Grid:Store:SetCellAt(1, mFood, {&VIEW-FOOD}).
    END METHOD.

    /* A new game: the snake of three cells in the middle of the board, facing right, and one piece of food. */
    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        DEFINE VARIABLE cx AS INTEGER NO-UNDO.
        DEFINE VARIABLE cy AS INTEGER NO-UNDO.
        cx = INTEGER(TRUNCATE(mWidth / 2, 0)).
        cy = INTEGER(TRUNCATE(mHeight / 2, 0)).
        StartWith(SUBSTITUTE("&1,&3;&2,&3;&4,&3", cx - 2, cx - 1, cy, cx), "Right").
    END METHOD.

    /* Checks a grid is one a Snake game can use. */
    METHOD PRIVATE VOID CheckGrid(INPUT poGrid AS Grid):
        IF NOT VALID-OBJECT(poGrid) THEN UNDO, THROW NEW GridException("A Snake game needs a grid").
        IF poGrid:Store:LayerCount <> 1 OR poGrid:Store:LayerName(1) <> "view" THEN
            UNDO, THROW NEW GridException("A Snake grid has exactly one layer, named view").
        IF poGrid:Width < 5 OR poGrid:Height < 5 THEN
            UNDO, THROW NEW GridException("A Snake board is at least 5 x 5").
    END METHOD.

    /* Queues a turn to face piDirection. See TurnUp for when it is refused. */
    METHOD PRIVATE LOGICAL Steer(INPUT piDirection AS INTEGER):
        DEFINE VARIABLE previous AS INTEGER NO-UNDO.
        IF Paused OR IsOver THEN RETURN FALSE.
        IF Waiting THEN DO:
            /* the first key starts the snake. Reversing into its own body is no way to start */
            IF piDirection = (mDirection + 2) MODULO 4 THEN RETURN FALSE.
            Waiting = FALSE.
            IF piDirection <> mDirection THEN DO:
                mQueue1 = piDirection.
                mQueued = 1.
            END.
            RETURN TRUE.
        END.
        IF mQueued >= 2 THEN RETURN FALSE.
        previous = (IF mQueued = 0 THEN mDirection ELSE IF mQueued = 1 THEN mQueue1 ELSE mQueue2).
        IF piDirection = previous OR piDirection = (previous + 2) MODULO 4 THEN RETURN FALSE.
        IF mQueued = 0 THEN mQueue1 = piDirection.
        ELSE mQueue2 = piDirection.
        mQueued = mQueued + 1.
        RETURN TRUE.
    END METHOD.

    /* One step: takes the oldest waiting turn, then moves the head one cell on. Ends the game when the
       head meets a wall or the body, and grows the snake when it meets the food. */
    METHOD PRIVATE VOID Step():
        DEFINE VARIABLE nx      AS INTEGER NO-UNDO.
        DEFINE VARIABLE ny      AS INTEGER NO-UNDO.
        DEFINE VARIABLE target  AS INTEGER NO-UNDO.
        DEFINE VARIABLE v       AS INTEGER NO-UNDO.
        DEFINE VARIABLE eating  AS LOGICAL NO-UNDO.
        IF mQueued > 0 THEN DO:
            mDirection = mQueue1.
            mQueue1 = mQueue2.
            mQueued = mQueued - 1.
        END.
        nx = HeadX + (IF mDirection = 1 THEN 1 ELSE IF mDirection = 3 THEN -1 ELSE 0).
        ny = HeadY + (IF mDirection = 2 THEN 1 ELSE IF mDirection = 0 THEN -1 ELSE 0).
        IF nx < 0 OR nx >= mWidth OR ny < 0 OR ny >= mHeight THEN DO:
            IsOver = TRUE.
            RETURN.
        END.
        target = ny * mWidth + nx.
        v = Grid:Store:GetCellAt(1, target).
        eating = (v = {&VIEW-FOOD}).
        /* the snake's own body is deadly, except the tail cell, which is being left this step */
        IF (v = {&VIEW-BODY} OR v = {&VIEW-HEAD}) AND target <> mBody[mTail + 1] THEN DO:
            IsOver = TRUE.
            RETURN.
        END.
        Generation = Generation + 1.
        Grid:Store:SetCellAt(1, mBody[mHead + 1], {&VIEW-BODY}).
        IF NOT eating THEN DO:
            Grid:Store:SetCellAt(1, mBody[mTail + 1], {&VIEW-EMPTY}).
            mTail = (mTail + 1) MODULO Grid:CellCount.
        END.
        mHead = (mHead + 1) MODULO Grid:CellCount.
        mBody[mHead + 1] = target.
        Grid:Store:SetCellAt(1, target, {&VIEW-HEAD}).
        IF eating THEN DO:
            mLength = mLength + 1.
            mEaten = mEaten + 1.
            mFood = -1.
            PlaceFood().
        END.
    END METHOD.

    /* Puts food in a random empty cell. A full board means the snake has won. */
    METHOD PRIVATE VOID PlaceFood():
        DEFINE VARIABLE i     AS INTEGER NO-UNDO.
        DEFINE VARIABLE pick  AS INTEGER NO-UNDO.
        IF mLength >= Grid:CellCount THEN DO:
            HasWon = TRUE.
            IsOver = TRUE.
            RETURN.
        END.
        pick = mRandom:NextInt(Grid:CellCount - mLength).
        DO i = 0 TO Grid:CellCount - 1:
            IF Grid:Store:GetCellAt(1, i) <> {&VIEW-EMPTY} THEN NEXT.
            IF pick = 0 THEN DO:
                mFood = i.
                Grid:Store:SetCellAt(1, i, {&VIEW-FOOD}).
                RETURN.
            END.
            pick = pick - 1.
        END.
    END METHOD.

END CLASS.
