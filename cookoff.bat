@echo off
rem Starts the ProGriddle Cookoff, the window with a button for every game.
rem Double click it, or run it from anywhere: it works from the folder it lives in.
rem It uses the OpenEdge install named by the DLC environment variable, or C:\Progress\OpenEdge.

setlocal
if "%DLC%"=="" set "DLC=C:\Progress\OpenEdge"

if not exist "%DLC%\bin\prowin.exe" (
    echo Could not find prowin.exe in "%DLC%\bin".
    echo Set the DLC environment variable to your OpenEdge install folder and try again.
    pause
    exit /b 1
)

cd /d "%~dp0"
start "" "%DLC%\bin\prowin.exe" -p tools/launch.p -param "run/run-arcade.p"
endlocal
