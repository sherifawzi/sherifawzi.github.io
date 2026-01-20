@echo off
setlocal

:: ------------------------------ Delete test restart file
del "%APPDATA%\MetaQuotes\Terminal\Common\Files\restart.txt"

:: ------------------------------ Set main download URL
set "snrurl=https://sherifawzi.github.io/Batch/"

:: ------------------------------ Create Batch Folders
set "batchpath=%USERPROFILE%\Desktop\BAT"
md "%batchpath%" 2>nul
ping -n 3 127.0.0.1 >nul

:: ------------------------------ Download Batch file
::set "snrbatch=Tester.bat"
::set "snrbatch=Trader.bat"
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"
ping -n 3 127.0.0.1 >nul

:: ------------------------------ Download Restart from
set "snrfile=restart.bat"
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%batchpath%\%snrfile%'"
ping -n 3 127.0.0.1 >nul

:: ------------------------------ Create MT5 Folder
set "mt5path=%USERPROFILE%\Desktop\001"
md "%mt5path%" 2>nul
ping -n 3 127.0.0.1 >nul

:: ------------------------------ Download from GitHub
set "snrfile=CleanOnly.bat"
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%mt5path%\%snrfile%'"
ping -n 3 127.0.0.1 >nul

:: ------------------------------ Download from GitHub
set "snrfile=CleanStart.bat"
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%mt5path%\%snrfile%'"
ping -n 3 127.0.0.1 >nul

:: ------------------------------ Start MT5s
ping -n 10 127.0.0.1 >nul
cd "%batchpath%" 2>nul
start %batchpath%\%snrbatch%

endlocal
exit
