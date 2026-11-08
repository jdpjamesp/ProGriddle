/* How the air enemies fly. Each one's place is a function of its age in frames (and a few numbers fixed when it appeared), so it
   needs no state of its own and a test can ask where it is at any age. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Games.Xevious.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Games.Xevious.XeviousMotion FINAL:

    /* Whole division, towards zero. */
    METHOD PUBLIC STATIC INTEGER Div(INPUT piA AS INTEGER, INPUT piB AS INTEGER):
        RETURN INTEGER(TRUNCATE(piA / piB, 0)).
    END METHOD.

    /* A triangle wave that starts at 0, rises to piAmp, falls to -piAmp and comes back to 0 every piPeriod frames. The period must
       be a multiple of 4 and the age 0 or more. */
    METHOD PUBLIC STATIC INTEGER Wave(INPUT piAge AS INTEGER, INPUT piPeriod AS INTEGER, INPUT piAmp AS INTEGER):
        VAR INTEGER q.
        VAR INTEGER h.
        q = Div(piPeriod, 4).
        h = piAge MODULO piPeriod.
        IF h < q THEN RETURN Div(h * piAmp, q).
        IF h < 3 * q THEN RETURN piAmp - Div((h - q) * 2 * piAmp, 2 * q).
        RETURN Div((h - 3 * q) * piAmp, q) - piAmp.
    END METHOD.

    /* Where an air enemy is across the field (its left side) at an age. piAnchor is the column it began in, piWay is 1 or -1
       (the side a Torkan comes from) and piAimX is the column a Terrazi was aimed at. */
    METHOD PUBLIC STATIC INTEGER AirX(INPUT poKind AS XeviousAir, INPUT piAnchor AS INTEGER, INPUT piAge AS INTEGER,
                                      INPUT piWay AS INTEGER, INPUT piAimX AS INTEGER):
        CASE poKind:
            WHEN XeviousAir:Toroid THEN RETURN piAnchor + Wave(piAge, 90, 40).
            WHEN XeviousAir:Torkan THEN RETURN piAnchor + piWay * Div(piAge * 3, 2).
            WHEN XeviousAir:GiddoSpario THEN RETURN piAnchor + Wave(piAge, 60, 12).
            WHEN XeviousAir:Kapi THEN RETURN piAnchor + Wave(piAge, 100, 20).
            WHEN XeviousAir:Jara THEN RETURN piAnchor + Wave(piAge, 48, 28).
            WHEN XeviousAir:Terrazi THEN RETURN piAnchor + Div((piAimX - piAnchor) * piAge, 70).
            OTHERWISE RETURN piAnchor.
        END CASE.
    END METHOD.

    /* Where an air enemy is down the field (its top) at an age. piStart is the row it began in and piPush is how far (in
       shots) a Bacura has been pushed back. */
    METHOD PUBLIC STATIC INTEGER AirY(INPUT poKind AS XeviousAir, INPUT piStart AS INTEGER, INPUT piAge AS INTEGER, INPUT piPush AS INTEGER):
        CASE poKind:
            WHEN XeviousAir:Toroid THEN RETURN piStart + Div(piAge * 5, 4).
            WHEN XeviousAir:Torkan THEN RETURN (IF piAge < 60 THEN piStart + 2 * piAge ELSE piStart + 120 - 2 * (piAge - 60)).
            WHEN XeviousAir:GiddoSpario THEN RETURN piStart + Div(piAge * 3, 4).
            WHEN XeviousAir:Kapi THEN RETURN (IF piAge <= 45 THEN piStart + 2 * piAge ELSE piStart + 90 - 3 * (piAge - 45)).
            WHEN XeviousAir:Jara THEN RETURN piStart + piAge.
            WHEN XeviousAir:Terrazi THEN RETURN piStart + 3 * piAge.
            WHEN XeviousAir:Bacura THEN RETURN piStart + piAge - 2 * piPush.
            OTHERWISE RETURN piStart.
        END CASE.
    END METHOD.

END CLASS.
