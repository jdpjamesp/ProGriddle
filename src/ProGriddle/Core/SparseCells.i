/* The record layout of a sparse cell table: one record per non-zero cell, per layer.
   Shared by SparseStore and by engines that exchange whole tables with it, so the two
   always have identical schemas. Arguments:
     &NAME    the temp table name
     &ACCESS  PRIVATE or PROTECTED */
DEFINE {&ACCESS} TEMP-TABLE {&NAME} NO-UNDO
    FIELD layerNo  AS INTEGER
    FIELD cellIdx  AS INTEGER
    FIELD cellVal  AS INTEGER
    INDEX ixCell IS PRIMARY UNIQUE layerNo cellIdx
    INDEX ixVal layerNo cellVal.
