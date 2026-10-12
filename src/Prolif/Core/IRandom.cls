/* The only source of randomness in the framework. Games take one as a constructor or method
   argument, so tests can pass a seeded one and get the same board every time. */
USING Prolif.Core.IRandom.

INTERFACE Prolif.Core.IRandom:

    /* A decimal from 0 up to but not including 1. */
    METHOD PUBLIC DECIMAL NextDecimal().

    /* A whole number from 0 up to but not including piBelow. Throws GridException when
       piBelow is less than 1. */
    METHOD PUBLIC INTEGER NextInt(INPUT piBelow AS INTEGER).

END INTERFACE.
