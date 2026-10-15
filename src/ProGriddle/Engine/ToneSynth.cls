/* The tone synthesiser: turns a recipe into 8 bit unsigned mono sound at 11025 Hz, in a MEMPTR, with integer maths only (it is
   fast enough to make every sound of a game at start up). 128 is silence, a swing of 127 is the full volume.

   A recipe is a comma separated list of parts, played one after another, each one  spec:ms  or  spec:ms:decay
     spec   440       a square wave of that pitch in Hz (20 to 5000)
            880>440   a square wave sliding from one pitch to the other over the part
            t440      a triangle wave (softer), t880>440 slides it
            n         noise (a register that changes level every three samples)
            r         a rest, silence
     ms     how long the part lasts, 1 to 5000
     decay  the percentage of its swing the part loses by its end, 0 to 100 (50 when left out)
   Every part rises over a few milliseconds from silence and falls back to it at the end, so there is no click. The same
   recipe always gives the same bytes.

   Inside, a phase is a whole number of 2 to the 40th parts of a cycle, so a pitch is a whole number added to it for each
   sample and a slide is a whole number added to that, and nothing needs a division but the swing of each sample. */
USING Progress.Lang.*.
USING ProGriddle.Core.*.
USING ProGriddle.Engine.*.

BLOCK-LEVEL ON ERROR UNDO, THROW.

CLASS ProGriddle.Engine.ToneSynth FINAL:

    &SCOPED-DEFINE RATE 11025
    &SCOPED-DEFINE MAXPARTS 64

    DEFINE PRIVATE VARIABLE mKind   AS CHARACTER NO-UNDO EXTENT {&MAXPARTS}.
    DEFINE PRIVATE VARIABLE mFrom   AS INTEGER   NO-UNDO EXTENT {&MAXPARTS}.
    DEFINE PRIVATE VARIABLE mTo     AS INTEGER   NO-UNDO EXTENT {&MAXPARTS}.
    DEFINE PRIVATE VARIABLE mMs     AS INTEGER   NO-UNDO EXTENT {&MAXPARTS}.
    DEFINE PRIVATE VARIABLE mDecay  AS INTEGER   NO-UNDO EXTENT {&MAXPARTS}.
    DEFINE PRIVATE VARIABLE mParts  AS INTEGER   NO-UNDO.

    /* Samples a second: 11025. */
    METHOD PUBLIC STATIC INTEGER SampleRate():
        RETURN {&RATE}.
    END METHOD.

    /* How many samples a recipe makes. Throws GridException for a recipe that cannot be read. */
    METHOD PUBLIC INTEGER SampleCount(INPUT pcRecipe AS CHARACTER):
        RETURN Parse(pcRecipe).
    END METHOD.

    /* Makes the sound of a recipe at a volume of 0 to 100 percent into pmData, which gets the exact size. The caller owns the
       memory and sets its size to 0 when done. Throws GridException for a recipe that cannot be read or a volume outside 0 to 100
       (nothing is allocated then). */
    METHOD PUBLIC VOID Make(INPUT pcRecipe AS CHARACTER, INPUT piVolume AS INTEGER, OUTPUT pmData AS MEMPTR):
        DEFINE VARIABLE total     AS INTEGER NO-UNDO.
        DEFINE VARIABLE pos       AS INTEGER NO-UNDO.
        DEFINE VARIABLE part      AS INTEGER NO-UNDO.
        DEFINE VARIABLE i         AS INTEGER NO-UNDO.
        DEFINE VARIABLE cnt       AS INTEGER NO-UNDO.
        DEFINE VARIABLE fadeIn    AS INTEGER NO-UNDO.
        DEFINE VARIABLE fadeOut   AS INTEGER NO-UNDO.
        DEFINE VARIABLE inStep    AS INTEGER NO-UNDO.
        DEFINE VARIABLE outStep   AS INTEGER NO-UNDO.
        DEFINE VARIABLE rise      AS INTEGER NO-UNDO.
        DEFINE VARIABLE fall      AS INTEGER NO-UNDO.
        DEFINE VARIABLE peak      AS INTEGER NO-UNDO.
        DEFINE VARIABLE amp       AS INTEGER NO-UNDO.
        DEFINE VARIABLE sample    AS INTEGER NO-UNDO.
        DEFINE VARIABLE kind      AS CHARACTER NO-UNDO.
        DEFINE VARIABLE swing     AS INT64   NO-UNDO.
        DEFINE VARIABLE swingStep AS INT64   NO-UNDO.
        DEFINE VARIABLE cycle     AS INT64   NO-UNDO INITIAL 1099511627776.
        DEFINE VARIABLE half      AS INT64   NO-UNDO INITIAL 549755813888.
        DEFINE VARIABLE phase     AS INT64   NO-UNDO.
        DEFINE VARIABLE pitch     AS INT64   NO-UNDO.
        DEFINE VARIABLE slope     AS INT64   NO-UNDO.
        DEFINE VARIABLE lfsr      AS INT64   NO-UNDO INITIAL 12345.
        DEFINE VARIABLE noiseHold AS INTEGER NO-UNDO.
        DEFINE VARIABLE noiseHigh AS LOGICAL NO-UNDO.
        IF piVolume = ? OR piVolume < 0 OR piVolume > 100 THEN UNDO, THROW NEW GridException("A volume is 0 to 100 percent, not " + STRING(piVolume)).
        total = Parse(pcRecipe).
        SET-SIZE(pmData) = total.
        peak = TRUNCATE(127 * piVolume / 100, 0).
        DO part = 1 TO mParts:
            kind = mKind[part].
            cnt = TRUNCATE({&RATE} * mMs[part] / 1000, 0).
            fadeIn = MINIMUM(40, TRUNCATE(cnt / 4, 0)).
            fadeOut = MINIMUM(60, TRUNCATE(cnt / 3, 0)).
            inStep = (IF fadeIn > 0 THEN TRUNCATE(1024 / fadeIn, 0) ELSE 1024).
            outStep = (IF fadeOut > 0 THEN TRUNCATE(1024 / fadeOut, 0) ELSE 1024).
            swing = peak * 65536.
            swingStep = TRUNCATE(swing * mDecay[part] / 100 / cnt, 0).
            IF kind = "s" OR kind = "t" THEN ASSIGN
                pitch = TRUNCATE(mFrom[part] * cycle / {&RATE}, 0)
                slope = TRUNCATE((TRUNCATE(mTo[part] * cycle / {&RATE}, 0) - pitch) / cnt, 0).
            DO i = 0 TO cnt - 1:
                /* the rise and fall over the ends of the part, 0 to 1024 each, and the swing now */
                rise = MINIMUM(1024, i * inStep).
                fall = MINIMUM(1024, (cnt - 1 - i) * outStep).
                IF rise = 1024 AND fall = 1024 THEN amp = TRUNCATE(swing / 65536, 0).
                ELSE amp = TRUNCATE(swing * rise * fall / 68719476736, 0).
                swing = swing - swingStep.
                CASE kind:
                    WHEN "s" THEN DO:
                        phase = phase + pitch.
                        IF phase >= cycle THEN phase = phase - cycle.
                        pitch = pitch + slope.
                        sample = 128 + (IF phase < half THEN amp ELSE 0 - amp).
                    END.
                    WHEN "t" THEN DO:
                        phase = phase + pitch.
                        IF phase >= cycle THEN phase = phase - cycle.
                        pitch = pitch + slope.
                        IF phase < half THEN sample = 128 + TRUNCATE(amp * (4 * phase - cycle) / cycle, 0).
                        ELSE sample = 128 + TRUNCATE(amp * (3 * cycle - 4 * phase) / cycle, 0).
                    END.
                    WHEN "n" THEN DO:
                        noiseHold = noiseHold - 1.
                        IF noiseHold <= 0 THEN DO:
                            noiseHold = 3.
                            lfsr = (lfsr * 1103515245 + 12345) MODULO 2147483648.
                            noiseHigh = (lfsr >= 1073741824).
                        END.
                        sample = 128 + (IF noiseHigh THEN amp ELSE 0 - amp).
                    END.
                    OTHERWISE sample = 128.
                END CASE.
                PUT-BYTE(pmData, pos + i + 1) = sample.
            END.
            pos = pos + cnt.
        END.
    END METHOD.

    /* Reads a recipe into the part tables and returns how many samples it makes. Throws GridException for a recipe that cannot be read. */
    METHOD PRIVATE INTEGER Parse(INPUT pcRecipe AS CHARACTER):
        DEFINE VARIABLE j       AS INTEGER   NO-UNDO.
        DEFINE VARIABLE total   AS INTEGER   NO-UNDO.
        DEFINE VARIABLE seg     AS CHARACTER NO-UNDO.
        DEFINE VARIABLE spec    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE kind    AS CHARACTER NO-UNDO.
        DEFINE VARIABLE pitchA  AS CHARACTER NO-UNDO.
        DEFINE VARIABLE pitchB  AS CHARACTER NO-UNDO.
        IF pcRecipe = ? OR pcRecipe = "" THEN UNDO, THROW NEW GridException("A sound recipe is empty").
        mParts = NUM-ENTRIES(pcRecipe).
        IF mParts > {&MAXPARTS} THEN UNDO, THROW NEW GridException("A sound recipe has " + STRING({&MAXPARTS}) + " parts or fewer, not " + STRING(mParts)).
        DO j = 1 TO mParts:
            seg = ENTRY(j, pcRecipe).
            IF NUM-ENTRIES(seg, ":") < 2 OR NUM-ENTRIES(seg, ":") > 3 THEN UNDO, THROW NEW GridException("A sound part is spec:ms or spec:ms:decay, not " + seg).
            spec = ENTRY(1, seg, ":").
            IF NOT IsWhole(ENTRY(2, seg, ":")) THEN UNDO, THROW NEW GridException("A sound part needs a whole number of milliseconds, not " + seg).
            mMs[j] = INTEGER(ENTRY(2, seg, ":")).
            IF mMs[j] < 1 OR mMs[j] > 5000 THEN UNDO, THROW NEW GridException("A sound part lasts 1 to 5000 ms, not " + seg).
            mDecay[j] = 50.
            IF NUM-ENTRIES(seg, ":") = 3 THEN DO:
                IF NOT IsWhole(ENTRY(3, seg, ":")) THEN UNDO, THROW NEW GridException("A sound part needs a whole number for its decay, not " + seg).
                mDecay[j] = INTEGER(ENTRY(3, seg, ":")).
                IF mDecay[j] > 100 THEN UNDO, THROW NEW GridException("A sound part decays 0 to 100 percent, not " + seg).
            END.
            IF spec = "n" OR spec = "r" THEN DO:
                kind = spec.
                mFrom[j] = 0.
                mTo[j] = 0.
            END.
            ELSE DO:
                kind = "s".
                IF SUBSTRING(spec, 1, 1) = "t" THEN ASSIGN
                    kind = "t"
                    spec = SUBSTRING(spec, 2).
                IF NUM-ENTRIES(spec, ">") > 2 THEN UNDO, THROW NEW GridException("A sound part has one slide at most, not " + seg).
                pitchA = ENTRY(1, spec, ">").
                pitchB = (IF NUM-ENTRIES(spec, ">") = 2 THEN ENTRY(2, spec, ">") ELSE pitchA).
                IF NOT IsWhole(pitchA) OR NOT IsWhole(pitchB) THEN UNDO, THROW NEW GridException("A sound part needs a pitch in Hz, not " + seg).
                mFrom[j] = INTEGER(pitchA).
                mTo[j] = INTEGER(pitchB).
                IF mFrom[j] < 20 OR mFrom[j] > 5000 OR mTo[j] < 20 OR mTo[j] > 5000 THEN UNDO, THROW NEW GridException("A pitch is 20 to 5000 Hz, not " + seg).
            END.
            mKind[j] = kind.
            total = total + TRUNCATE({&RATE} * mMs[j] / 1000, 0).
        END.
        RETURN total.
    END METHOD.

    /* True for one to six digits and nothing else. */
    METHOD PRIVATE LOGICAL IsWhole(INPUT pcText AS CHARACTER):
        RETURN pcText <> ? AND pcText <> "" AND LENGTH(pcText) <= 6 AND TRIM(pcText, "0123456789") = "".
    END METHOD.

END CLASS.
