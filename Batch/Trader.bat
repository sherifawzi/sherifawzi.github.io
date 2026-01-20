@echo off
setlocal

   :: https://sherifawzi.github.io
   :: https://t.me
   :: https://api.telegram.org
   :: http://3.66.106.21

   :: ------------------------------ Create MT5 Folders
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
   ping -n 3 127.0.0.1 >nul

   :: ------------------------------ Download URL
   set "snrurl=https://sherifawzi.github.io/Tools/"

   :: ------------------------------ Download from GitHub
   set "snrbot=SNRC.ex5"
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"
   ping -n 3 127.0.0.1 >nul

   :: ------------------------------ Copy to other MT5s
   copy "%mtbotpath%\%snrbot%" "%mtbotpath2%"
   copy "%mtbotpath%\%snrbot%" "%mtbotpath3%"
   copy "%mtbotpath%\%snrbot%" "%mtbotpath4%"
   ping -n 3 127.0.0.1 >nul

   :: ------------------------------ Bot File Name
   set "snrbot=HistoryWriter.ex5"
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"
   ping -n 3 127.0.0.1 >nul

   :: ------------------------------ Copy to other MT5s
   copy "%mtbotpath%\%snrbot%" "%mtbotpath2%"
   copy "%mtbotpath%\%snrbot%" "%mtbotpath3%"
   copy "%mtbotpath%\%snrbot%" "%mtbotpath4%"
   ping -n 3 127.0.0.1 >nul

   :: ------------------------------ Start MT5s
   cd "%mtmainpath%" 2>nul
   start %mtmainpath%\CleanStart.bat
   ping -n 10 127.0.0.1 >nul

   cd "%mtmainpath2%" 2>nul
   start %mtmainpath2%\CleanStart.bat
   ping -n 10 127.0.0.1 >nul

   cd "%mtmainpath3%" 2>nul
   start %mtmainpath3%\CleanStart.bat
   ping -n 10 127.0.0.1 >nul

   cd "%mtmainpath4%" 2>nul
   start %mtmainpath4%\CleanStart.bat

endlocal
exit


