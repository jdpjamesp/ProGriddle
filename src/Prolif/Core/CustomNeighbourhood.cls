/* A neighbourhood made from any list of offsets, for example a knight's move or a ring of
   radius two. Moore and Von Neumann are built on it. Throws GridException when the list is
   empty, the arrays differ in length, an offset is (0, 0), or an offset repeats. The
   arrays are copied. */
USING Progress.Lang.*.
USING Prolif.Core.CustomNeighbourhood.
USING Prolif.Core.GridException.
USING Prolif.Core.INeighbourhood.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS Prolif.Core.CustomNeighbourhood IMPLEMENTS INeighbourhood:

    DEFINE PRIVATE VARIABLE mXs AS INTEGER NO-UNDO EXTENT.
    DEFINE PRIVATE VARIABLE mYs AS INTEGER NO-UNDO EXTENT.

    DEFINE PUBLIC PROPERTY OffsetCount AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    DEFINE PUBLIC PROPERTY Reach AS INTEGER NO-UNDO
        GET.
        PRIVATE SET.

    CONSTRUCTOR PUBLIC CustomNeighbourhood(INPUT piXs AS INTEGER EXTENT, INPUT piYs AS INTEGER EXTENT):
        DEFINE VARIABLE i AS INTEGER NO-UNDO.
        DEFINE VARIABLE j AS INTEGER NO-UNDO.

        IF EXTENT(piXs) = ? OR EXTENT(piYs) = ? THEN
            UNDO, THROW NEW GridException("A neighbourhood needs at least one offset").
        IF EXTENT(piXs) <> EXTENT(piYs) THEN
            UNDO, THROW NEW GridException("Neighbourhood x and y offset arrays differ in length").

        OffsetCount = EXTENT(piXs).
        EXTENT(mXs) = OffsetCount.
        EXTENT(mYs) = OffsetCount.
        DO i = 1 TO OffsetCount:
            mXs[i] = piXs[i].
            mYs[i] = piYs[i].
            IF mXs[i] = 0 AND mYs[i] = 0 THEN
                UNDO, THROW NEW GridException("A cell cannot be its own neighbour: offset (0,0)").
            DO j = 1 TO i - 1:
                IF mXs[j] = mXs[i] AND mYs[j] = mYs[i] THEN
                    UNDO, THROW NEW GridException(SUBSTITUTE("Neighbourhood offset (&1,&2) repeats", mXs[i], mYs[i])).
            END.
            Reach = MAXIMUM(Reach, MAXIMUM(ABSOLUTE(mXs[i]), ABSOLUTE(mYs[i]))).
        END.
    END CONSTRUCTOR.

    METHOD PUBLIC INTEGER OffsetX(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mXs[piIndex].
    END METHOD.

    METHOD PUBLIC INTEGER OffsetY(INPUT piIndex AS INTEGER):
        CheckIndex(piIndex).
        RETURN mYs[piIndex].
    END METHOD.

    METHOD PRIVATE VOID CheckIndex(INPUT piIndex AS INTEGER):
        IF piIndex < 1 OR piIndex > OffsetCount THEN
            UNDO, THROW NEW GridException(SUBSTITUTE("Neighbourhood offset &1 is outside 1 to &2", piIndex, OffsetCount)).
    END METHOD.

END CLASS.
