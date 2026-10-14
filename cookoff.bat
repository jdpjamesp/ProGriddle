@echo off
rem Starts the ProGriddle Cookoff, the window with a button for every game.
rem Double click it, or run it from anywhere: it works from the folder it lives in.
rem It uses the OpenEdge install named by the DLC environment variable, or C:\Progress\OpenEdge,
rem and keeps OpenEdge's temp files in the ProGriddle folder under your TEMP folder.

setlocal
if "%DLC%"=="" set "DLC=C:\Progress\OpenEdge"

rem OpenEdge's temp files go to a folder of their own (the -T startup parameter).
if "%TEMP%"=="" set "TEMP=C:\temp"
set "PGTEMP=%TEMP%\ProGriddle"
if not exist "%PGTEMP%" mkdir "%PGTEMP%"

if not exist "%DLC%\bin\prowin.exe" (
    echo Could not find prowin.exe in "%DLC%\bin".
    echo Set the DLC environment variable to your OpenEdge install folder and try again.
    pause
    exit /b 1
)

cd /d "%~dp0"
start "" "%DLC%\bin\prowin.exe" -T "%PGTEMP%" -l 1024 -p tools/launch.p -param "run/run-arcade.p"
endlocal
