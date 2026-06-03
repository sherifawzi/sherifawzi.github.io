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
   md "%mtbotpath%" 2>nul

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath2=%USERPROFILE%\Desktop\002"
   set "mtbotpath2=%mtmainpath2%\MQL5\Experts"
   md "%mtbotpath2%" 2>nul

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath3=%USERPROFILE%\Desktop\003"
   set "mtbotpath3=%mtmainpath3%\MQL5\Experts"
   md "%mtbotpath3%" 2>nul

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath4=%USERPROFILE%\Desktop\004"
   set "mtbotpath4=%mtmainpath4%\MQL5\Experts"
   md "%mtbotpath4%" 2>nul

   :: ------------------------------ Download URL
   set "snrurl=https://sherifawzi.github.io/Tools/"





   :: ------------------------------ Bot File Name
   set "snrbot=HISTORY.ex5"

   :: ------------------------------ Download from GitHub
   ping -n 3 127.0.0.1 >nul
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"

   :: ------------------------------ Copy to other MT5s
   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath2%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath3%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath4%"





   :: ------------------------------ Bot File Name
   set "snrbot=SNRL3.ex5"

   :: ------------------------------ Download from GitHub
   ping -n 3 127.0.0.1 >nul
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"

   :: ------------------------------ Copy to other MT5s
   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath2%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath3%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath4%"





   endlocal
   exit