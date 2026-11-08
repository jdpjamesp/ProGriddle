/* Draws a picture of Cuber into a BMP file with no window and no keyboard, so the look can be checked from a script. It sets the
   PROPATH (a program that names classes cannot do it before its own USING statements) and runs tools/preview-cuber-draw.p. From
   the repository root:

     _progres -b -T "%TEMP%\ProGriddle" -p tools/preview-cuber.p -param "scenario|file.bmp" */
PROPATH = "src,tests," + PROPATH.
RUN tools/preview-cuber-draw.p.
