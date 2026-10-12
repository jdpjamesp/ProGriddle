/* The set of offsets that count as a cell's neighbours. Offsets are numbered from 1.
   An offset is never (0, 0) and never repeats. */
USING ProGriddle.Core.*.

INTERFACE ProGriddle.Core.INeighbourhood:

    DEFINE PUBLIC PROPERTY OffsetCount AS INTEGER NO-UNDO
        GET.

    /* The largest absolute x or y offset. A cell at least this far from every edge has all
       of its neighbours on the board whatever the topology. */
    DEFINE PUBLIC PROPERTY Reach AS INTEGER NO-UNDO
        GET.

    METHOD PUBLIC INTEGER OffsetX(INPUT piIndex AS INTEGER).

    METHOD PUBLIC INTEGER OffsetY(INPUT piIndex AS INTEGER).

END INTERFACE.
