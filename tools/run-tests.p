/* Batch entry point for ABLUnit. Sets PROPATH (the PROPATH environment
   variable is ignored by this install) then hands over to ABLUnitCore.p.
   Run from the repository root via tools/run-tests.ps1. */
PROPATH = "src,tests," + PROPATH.
RUN ABLUnitCore.p.
