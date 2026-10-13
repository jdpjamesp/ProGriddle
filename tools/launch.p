/* Bootstrap for running a program from the command line. The program is compiled
   only after PROPATH is set, so its USING statements resolve.
     prowin.exe -T "%TEMP%\ProGriddle" -p tools/launch.p -param "run/run-spike.p,arg2,arg3"
   Entry 1 is the program to run. Programs read their own arguments from
   SESSION:PARAMETER, entries 2 onwards. Run from the repository root. */
DEFINE VARIABLE cProgram AS CHARACTER NO-UNDO.

PROPATH = "src,tests,run," + PROPATH.
cProgram = ENTRY(1, SESSION:PARAMETER).
RUN VALUE(cProgram).
