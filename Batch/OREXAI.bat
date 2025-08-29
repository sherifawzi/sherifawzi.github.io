
@echo off
setlocal

   :: https://sherifawzi.github.io
   :: https://t.me
   :: https://api.telegram.org
   :: http://3.66.106.21

   :: ------------------------------ Create MT5 Folders
   ping -n 3 127.0.0.1 >nul
   set "mtmainpath=%USERPROFILE%\Desktop\001"
   set "mtbotpath=%mtmainpath%\MQL5\Experts"
   set "mtsetpath=%mtmainpath%\MQL5\Profiles\Tester"

   md "%mtbotpath%" 2>nul
   md "%mtsetpath%" 2>nul

   :: ------------------------------ Download URL
   set "snrurl=https://sherifawzi.github.io/Tools/"
   set "snrconfig=%USERPROFILE%\AppData\Roaming\MetaQuotes\Terminal\Common\Files\orexconf.ini"

   :: ------------------------------ Bot File Name
   set "snrbot=OREXAI.ex5"

   :: ------------------------------ Download from GitHub
   ping -n 3 127.0.0.1 >nul
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"

   :: ------------------------------ Bot File Name
   set "snrbot=OREXAI.set"

   :: ------------------------------ Download from GitHub
   ping -n 3 127.0.0.1 >nul
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtsetpath%\%snrbot%'"

   :: ------------------------------ Start MT5s
   ping -n 10 127.0.0.1 >nul
   cd "%mtmainpath%" 2>nul
   %COMSPEC% /C start %mtmainpath%\terminal64.exe /config:%snrconfig% /portable
   ::%COMSPEC% /C start %mtmainpath%\_CleanStart.bat

endlocal
exit
