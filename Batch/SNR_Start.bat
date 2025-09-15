@echo off
setlocal

:: ------------------------------ File to download
::set "snrbatch=Analyzer.bat"
::set "snrbatch=Beacon.bat"
set "snrbatch=History.bat"
::set "snrbatch=Receiver.bat"
::set "snrbatch=restart.bat"
::set "snrbatch=RevMag.bat"
::set "snrbatch=RevMagLive.bat"
::set "snrbatch=Swapie.bat"
::set "snrbatch=Tester.bat"
::set "snrbatch=RevMagNew.bat"
::set "snrbatch=OREXAI.bat"
::set "snrbatch=OrexAiLive.bat"



:: ------------------------------ Create Folders
ping -n 3 127.0.0.1 >nul
set "batchpath=%USERPROFILE%\Desktop\BAT"
md "%batchpath%" 2>nul



:: ------------------------------ Download Batch File
set "snrurl=https://sherifawzi.github.io/Batch/"

:: ------------------------------ Download from GitHub
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"

:: ------------------------------ Download from GitHub
set "snrfile=restart.bat"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%batchpath%\%snrfile%'"



:: ------------------------------ Create MT5 Folder
ping -n 3 127.0.0.1 >nul
set "batchpath=%USERPROFILE%\Desktop\001"
md "%batchpath%" 2>nul



:: ------------------------------ Download MT5
set "snrurl=http://3.66.106.21/MT5/"

:: ------------------------------ Download from GitHub
set "snrfile=MetaEditor64.exe"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%batchpath%\%snrfile%'"

:: ------------------------------ Download from GitHub
set "snrfile=_CleanOnly.bat"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%batchpath%\%snrfile%'"

:: ------------------------------ Download from GitHub
set "snrfile=_CleanStart.bat"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%batchpath%\%snrfile%'"

:: ------------------------------ Download from GitHub
set "snrfile=metatester64.exe"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%batchpath%\%snrfile%'"

:: ------------------------------ Download from GitHub
set "snrfile=terminal64.exe"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%batchpath%\%snrfile%'"



:: ------------------------------ Start MT5s
ping -n 10 127.0.0.1 >nul
set "batchpath=%USERPROFILE%\Desktop\BAT"
cd "%batchpath%" 2>nul
start %batchpath%\%snrbatch%

endlocal
exit
