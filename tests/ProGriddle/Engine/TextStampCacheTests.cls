/* The cache of text stamps: asking twice for the same text, size and colours gives the same stamp, and when it is full the
   oldest goes (and is freed). */
USING OpenEdge.Core.*.
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.TextStampCacheTests:

    DEFINE PRIVATE VARIABLE mCache  AS TextStampCache NO-UNDO.
    DEFINE PRIVATE VARIABLE mGrid   AS Grid           NO-UNDO.
    DEFINE PRIVATE VARIABLE mCanvas AS PixelCanvas    NO-UNDO.

    @Setup.
    METHOD PUBLIC VOID BuildCache():
        mCache = NEW TextStampCache(3).
        mGrid = NEW Grid(NEW ArrayStore(40, 20, "view,kind,back")).
        mCanvas = NEW PixelCanvas(mGrid).
        mCanvas:Restore().
    END METHOD.

    @TearDown.
    METHOD PUBLIC VOID ReleaseCache():
        IF VALID-OBJECT(mCache) THEN mCache:Dispose().
        mCache = ?.
        IF VALID-OBJECT(mCanvas) THEN mCanvas:Dispose().
        mCanvas = ?.
        IF VALID-OBJECT(mGrid) THEN mGrid:Dispose().
        mGrid = ?.
    END METHOD.

    @Test.
    METHOD PUBLIC VOID TheSameTextAndLookGivesTheSameStampAndAnotherLookAnotherOne():
        DEFINE VARIABLE a AS TextStamp NO-UNDO.
        DEFINE VARIABLE b AS TextStamp NO-UNDO.
        DEFINE VARIABLE c AS TextStamp NO-UNDO.
        a = mCache:Get("HI", 1, 100, 100, -1).
        b = mCache:Get("HI", 1, 100, 100, -1).
        c = mCache:Get("HI", 2, 100, 100, -1).
        Assert:IsTrue(a = b).
        Assert:IsFalse(a = c).
        Assert:Equals(2, mCache:Count).
        Assert:Equals(11, a:Width).
        Assert:Equals(22, c:Width).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID WhenFullTheOldestStampIsFreedAndTheNewestIsKept():
        DEFINE VARIABLE first1 AS TextStamp NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER   NO-UNDO.
        first1 = mCache:Get("A", 1, 1, 1, -1).
        mCache:Get("B", 1, 1, 1, -1).
        mCache:Get("C", 1, 1, 1, -1).
        Assert:Equals(3, mCache:Count).
        /* a fourth takes the place of the oldest, which has been disposed of */
        mCache:Get("D", 1, 1, 1, -1).
        Assert:Equals(3, mCache:Count).
        DO ON ERROR UNDO, THROW:
            first1:DrawTo(mCanvas, 0, 0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(1, thrown).
        /* B, C and D are still there and A is made again */
        mCache:Get("D", 1, 1, 1, -1):DrawTo(mCanvas, 0, 0).
        Assert:IsFalse(mCache:Get("A", 1, 1, 1, -1) = first1).
    END METHOD.

    @Test.
    METHOD PUBLIC VOID ACacheNeedsAtLeastOneSlotAndDisposeFreesEverythingAndCanBeRepeated():
        DEFINE VARIABLE a      AS TextStamp NO-UNDO.
        DEFINE VARIABLE thrown AS INTEGER   NO-UNDO.
        DO ON ERROR UNDO, THROW:
            NEW TextStampCache(0).
            CATCH e1 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        a = mCache:Get("A", 1, 1, 1, -1).
        mCache:Dispose().
        mCache:Dispose().
        DO ON ERROR UNDO, THROW:
            a:DrawTo(mCanvas, 0, 0).
            CATCH e2 AS GridException:
                thrown = thrown + 1.
            END CATCH.
        END.
        Assert:Equals(2, thrown).
        Assert:Equals(0, mCache:Count).
    END METHOD.

END CLASS.
