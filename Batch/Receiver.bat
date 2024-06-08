   @echo off
   setlocal

   :: ------------------------------ Download Variables
   set "snrbot=RADIO3XL.ex5"
   set "snrurl=https://sherifawzi.github.io/Tools/"

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

   :: ------------------------------ Start MT5s
   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath%" 2>nul
   %COMSPEC% /C start %mtmainpath%\terminal64.exe /portable

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath2%" 2>nul
   %COMSPEC% /C start %mtmainpath2%\terminal64.exe /portable

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath3%" 2>nul
   %COMSPEC% /C start %mtmainpath3%\terminal64.exe /portable

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath4%" 2>nul
   %COMSPEC% /C start %mtmainpath4%\terminal64.exe /portable

   endlocal
