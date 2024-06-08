   @echo off
   setlocal

   :: ------------------------------ Download Variables
   set "snrbot=DASHBOARD.ex5"
   set "snrurl=https://sherifawzi.github.io/Tools/"

   :: ------------------------------ Create MT5 Folders
   ping -n 3 127.0.0.1 >nul
   set "mtmainpath=%USERPROFILE%\Desktop\001"
   set "mtbotpath=%mtmainpath%\MQL5\Experts"
   md "%mtbotpath%" 2>nul

   :: ------------------------------ Download from GitHub
   ping -n 3 127.0.0.1 >nul
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"

   :: ------------------------------ Other Download [ If Applicable ]
   ping -n 3 127.0.0.1 >nul
   set "snrbot=ANALYZER.ex5"
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"

   :: ------------------------------ Other Download [ If Applicable ]
   ping -n 3 127.0.0.1 >nul
   set "snrbot=RESULTER.ex5"
   powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"

   :: ------------------------------ Start MT5s
   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath%" 2>nul
   %COMSPEC% /C start %mtmainpath%\terminal64.exe /portable

   endlocal
