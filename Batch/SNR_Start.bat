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



:: ------------------------------ Download Batch File
set "snrurl=https://sherifawzi.github.io/Batch/"

:: ------------------------------ Create Folders
ping -n 3 127.0.0.1 >nul
set "batchpath=%USERPROFILE%\Desktop\BAT"
md "%batchpath%" 2>nul

:: ------------------------------ Download from GitHub
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"

:: ------------------------------ Download from GitHub
set "snrbatch=restart.bat"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"



:: ------------------------------ Create MT5 Folder
ping -n 3 127.0.0.1 >nul
set "batchpath=%USERPROFILE%\Desktop\001"
md "%batchpath%" 2>nul



:: ------------------------------ Download MT5
set "snrurl=http://3.66.106.21/MT5/"

:: ------------------------------ Download from GitHub
set "snrbatch=MetaEditor64.exe"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"

:: ------------------------------ Download from GitHub
set "snrbatch=_CleanOnly.bat"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"

:: ------------------------------ Download from GitHub
set "snrbatch=_CleanStart.bat"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"

:: ------------------------------ Download from GitHub
set "snrbatch=metatester64.exe"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"

:: ------------------------------ Download from GitHub
set "snrbatch=terminal64.exe"
ping -n 3 127.0.0.1 >nul
powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"



:: ------------------------------ Start MT5s
ping -n 10 127.0.0.1 >nul
cd "%batchpath%" 2>nul
start %batchpath%\%snrbatch%

endlocal
exit
