/* Phase 7 performance check of the real Life classes (LifeFactory, DenseLifeEngine and
   SparseLifeEngine), as opposed to the Phase 0 storage experiments in phase0-storage.p.
   It builds a square board, fills it at random from a fixed seed, steps it and prints one line:
     mode side density gens build_ms run_ms ms_per_generation alive_at_start alive_at_end
   Run it through bench/run-life-bench.ps1, or directly:
     _progres -b -T <folder> -p tools/launch.p -param "bench/life-bench.p,mode,side,density,gens"
   mode is dense or sparse, which decides the engine by the live share the factory is told. */
USING ProGriddle.Core.*.
USING ProGriddle.Games.Life.*.

DEFINE VARIABLE cMode   AS CHARACTER NO-UNDO.
DEFINE VARIABLE iSide   AS INTEGER   NO-UNDO.
DEFINE VARIABLE dDens   AS DECIMAL   NO-UNDO.
DEFINE VARIABLE iGens   AS INTEGER   NO-UNDO.
DEFINE VARIABLE i       AS INTEGER   NO-UNDO.
DEFINE VARIABLE iBuild  AS INTEGER   NO-UNDO.
DEFINE VARIABLE iRun    AS INTEGER   NO-UNDO.
DEFINE VARIABLE iStart  AS INTEGER   NO-UNDO.
DEFINE VARIABLE oGame   AS LifeGame  NO-UNDO.

cMode = ENTRY(2, SESSION:PARAMETER).
iSide = INTEGER(ENTRY(3, SESSION:PARAMETER)).
dDens = DECIMAL(ENTRY(4, SESSION:PARAMETER)).
iGens = INTEGER(ENTRY(5, SESSION:PARAMETER)).

ETIME(TRUE).
/* the live share given to the factory picks the engine: 0.5 is dense, 0.01 is sparse */
oGame = LifeFactory:Create(iSide, iSide, FALSE, LifeRules:Conway(), (IF cMode = "sparse" THEN 0.01 ELSE 0.5)).
oGame:Randomise(NEW SeededRandom(12345), dDens).
iStart = oGame:AliveCount.
iBuild = ETIME.

ETIME(TRUE).
DO i = 1 TO iGens:
    oGame:Step().
END.
iRun = ETIME.

PUT UNFORMATTED SUBSTITUTE("&1 &2 &3 &4 &5 &6 &7 &8 &9", cMode, iSide, dDens, iGens, iBuild, iRun,
                           TRUNCATE(iRun / iGens, 0), iStart, oGame:AliveCount) SKIP.
oGame:Dispose().
QUIT.
