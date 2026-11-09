/* Draws a picture of Football Manager into a BMP file with no window and no keyboard, so the look can be checked from a script. It
   sets the PROPATH (a program that names classes cannot do it before its own USING statements) and runs
   tools/preview-footballmanager-draw.p. From the repository root:

     _progres -b -T "%TEMP%\ProGriddle" -p tools/preview-footballmanager.p -param "keys:B,O,B,Return,Return,Return|file.bmp"

   The scenario is keys:LIST or keys:LIST:ms, the keys of LIST pressed one at a time (names as the window gives them, such as B, Return, Down, Space, K), and
   then the match played to ms milliseconds into its highlights if it is being shown (seed 7). */
PROPATH = "src,tests," + PROPATH.
RUN tools/preview-footballmanager-draw.p.
