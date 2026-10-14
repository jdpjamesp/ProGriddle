/* Test double: a real time game that adds up the time it is given, is over once LimitMs milliseconds have passed and then
   goes on animating for AnimateMs more. Not a test class itself (the name does not end in Tests). */
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.AnimatedRealTimeGame INHERITS AbstractGame IMPLEMENTS IRealTimeGame, IAnimated:

    DEFINE PRIVATE VARIABLE mLimit   AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mAnimate AS INTEGER NO-UNDO.
    DEFINE PRIVATE VARIABLE mOverAt  AS INTEGER NO-UNDO.

    DEFINE PUBLIC PROPERTY Paused AS LOGICAL NO-UNDO
        GET.
        SET.

    DEFINE PUBLIC PROPERTY TotalMs AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Animating AS LOGICAL NO-UNDO
        GET():
            RETURN IsOver AND TotalMs < mOverAt + mAnimate.
        END GET.

    CONSTRUCTOR PUBLIC AnimatedRealTimeGame(INPUT poGrid AS Grid, INPUT piLimitMs AS INTEGER, INPUT piAnimateMs AS INTEGER):
        SUPER("animated real time", poGrid).
        mLimit = piLimitMs.
        mAnimate = piAnimateMs.
    END CONSTRUCTOR.

    METHOD PUBLIC LOGICAL Tick(INPUT piElapsedMs AS INTEGER):
        IF Paused THEN RETURN FALSE.
        TotalMs = TotalMs + piElapsedMs.
        IF NOT IsOver AND TotalMs >= mLimit THEN DO:
            IsOver = TRUE.
            mOverAt = TotalMs.
        END.
        RETURN piElapsedMs > 0.
    END METHOD.

    METHOD PROTECTED OVERRIDE VOID OnInitialise():
        TotalMs = 0.
        mOverAt = 0.
    END METHOD.

END CLASS.
