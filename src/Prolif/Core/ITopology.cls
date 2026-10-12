/* What happens at the edges of a grid. A topology holds no state: the grid size is passed
   in on every call, so one topology object works for any grid. x and y start at 0 and the
   cell index is (y * width) + x. */
USING Prolif.Core.ITopology.

INTERFACE Prolif.Core.ITopology:

    /* True when coordinates that leave the board come back in on the other side. Used by
       the grid to decide whether neighbour lists can contain duplicates on tiny boards. */
    DEFINE PUBLIC PROPERTY Wraps AS LOGICAL NO-UNDO
        GET.

    /* True when (piX, piY) names a real cell once the topology has been applied. */
    METHOD PUBLIC LOGICAL IsValid(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER,
                                  INPUT piX AS INTEGER, INPUT piY AS INTEGER).

    /* Cell index that (piX, piY) refers to, or the unknown value when there is no such cell.
       Any integer x and y are accepted, including ones far off the board. */
    METHOD PUBLIC INTEGER Resolve(INPUT piWidth AS INTEGER, INPUT piHeight AS INTEGER,
                                  INPUT piX AS INTEGER, INPUT piY AS INTEGER).

END INTERFACE.
