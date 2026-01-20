@echo off
setlocal

:: ------------------------------ Set batch file name
  :: set "snrbatch=Tester.bat"
  :: set "snrbatch=Trader.bat"

:: ------------------------------ Delete test restart file
  del "%APPDATA%\MetaQuotes\Terminal\Common\Files\restart.txt"

:: ------------------------------ Set download URL
  set "snrurl=https://sherifawzi.github.io/Batch/"

:: ------------------------------ Create batch folders
  set "batchpath=%USERPROFILE%\Desktop\BAT"
  md "%batchpath%" 2>nul
  ping -n 3 127.0.0.1 >nul

:: ------------------------------ Download batch file
  powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbatch%' -OutFile '%batchpath%\%snrbatch%'"
  ping -n 3 127.0.0.1 >nul

:: ------------------------------ Download restart file
  set "snrfile=restart.bat"
  powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%batchpath%\%snrfile%'"
  ping -n 3 127.0.0.1 >nul

:: ------------------------------ Create MT5 Folder
  set "mt5path=%USERPROFILE%\Desktop\001"
  md "%mt5path%" 2>nul
  ping -n 3 127.0.0.1 >nul

:: ------------------------------ Download clean only batch file
  set "snrfile=CleanOnly.bat"
  powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%mt5path%\%snrfile%'"
  ping -n 3 127.0.0.1 >nul

:: ------------------------------ Download clean start file
  set "snrfile=CleanStart.bat"
  powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%mt5path%\%snrfile%'"
  ping -n 3 127.0.0.1 >nul

:: ------------------------------ Set download URL
  set "snrurl=https://snrobotix.com/MT5/"

:: ------------------------------ Download mt5 main file
  set "snrfile=terminal64.exe"
  powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrfile%' -OutFile '%mt5path%\%snrfile%'"
  ping -n 3 127.0.0.1 >nul

:: ------------------------------ Run batch file
  ping -n 10 127.0.0.1 >nul
  cd "%batchpath%" 2>nul
  start %batchpath%\%snrbatch%

endlocal
exit
