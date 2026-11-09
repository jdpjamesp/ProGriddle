/* Draws a picture of Football Manager into a BMP file with no window and no keyboard, so the look can be checked from a script. It
   sets the PROPATH (a program that names classes cannot do it before its own USING statements) and runs
   tools/preview-footballmanager-draw.p. From the repository root:

     _progres -b -T "%TEMP%\ProGriddle" -p tools/preview-footballmanager.p -param "match:2000|file.bmp"

   The scenario is match:ms, the match played to ms milliseconds into its highlights (seed 7, the club in the fourth division). */
PROPATH = "src,tests," + PROPATH.
RUN tools/preview-footballmanager-draw.p.
