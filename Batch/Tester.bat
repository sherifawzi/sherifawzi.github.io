@echo off

   :: https://sherifawzi.github.io
   :: https://t.me
   :: https://api.telegram.org
   :: http://3.66.106.21

   del "%APPDATA%\MetaQuotes\Terminal\Common\Files\restart.txt"
   ping -n 3 127.0.0.1 >nul

setlocal

:: ------------------------------ Set all variables
   set "snrconfig=%USERPROFILE%\AppData\Roaming\MetaQuotes\Terminal\Common\Files\configur.ini"
   set "mtmainpath=%USERPROFILE%\Desktop\001"
   set "mtbotpath=%mtmainpath%\MQL5\Experts"
   set "mtsetpath=%mtmainpath%\MQL5\Profiles\Tester"

:: ------------------------------ Set dowbload URL
   set "snrurl=https://sherifawzi.github.io/Tools/"

:: ------------------------------ Create MT5 Folders
   md "%mtmainpath%" 2>nul
   md "%mtbotpath%" 2>nul
   md "%mtsetpath%" 2>nul
   ping -n 3 127.0.0.1 >nul

:: ------------------------------ Bot File Name
   set "snrbot=SNRC.ex5"
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"
   ping -n 3 127.0.0.1 >nul

:: ------------------------------ Set File Name
   set "snrbot=SNRC.set"
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtsetpath%\%snrbot%'"
   ping -n 3 127.0.0.1 >nul

:: ------------------------------ Start MT5s
   start "" "%mtmainpath%\terminal64.exe" /config:"%snrconfig%" /portable

endlocal
exit
