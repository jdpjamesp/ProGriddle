/* Phase 0 GUI spike launcher. Run under prowin from the repository root:
     prowin.exe -p tools/launch.p -param "run/run-spike.p,build/gui-spike.log,0"
   Parameter entries after the program: logfile, autoExitSeconds (0 = stay open). */
USING Prolif.UI.WinForms.SpikeWindow.
USING System.Windows.Forms.Application FROM ASSEMBLY.

DEFINE VARIABLE win   AS SpikeWindow NO-UNDO.
DEFINE VARIABLE cLog  AS CHARACTER   NO-UNDO INITIAL "build/gui-spike.log".
DEFINE VARIABLE iAuto AS INTEGER     NO-UNDO.

IF NUM-ENTRIES(SESSION:PARAMETER) >= 2 THEN cLog = ENTRY(2, SESSION:PARAMETER).
IF NUM-ENTRIES(SESSION:PARAMETER) >= 3 THEN iAuto = INTEGER(ENTRY(3, SESSION:PARAMETER)).

win = NEW SpikeWindow(cLog, iAuto).
WAIT-FOR Application:Run(win).
QUIT.
