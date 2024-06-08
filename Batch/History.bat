   @echo off
   setlocal

   :: ------------------------------ Download Variables
   set "snrbot=HistoryWriter.ex5"
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

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath5=%USERPROFILE%\Desktop\005"
   set "mtbotpath5=%mtmainpath5%\MQL5\Experts"
   md "%mtbotpath5%" 2>nul

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath6=%USERPROFILE%\Desktop\006"
   set "mtbotpath6=%mtmainpath6%\MQL5\Experts"
   md "%mtbotpath6%" 2>nul

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath7=%USERPROFILE%\Desktop\007"
   set "mtbotpath7=%mtmainpath7%\MQL5\Experts"
   md "%mtbotpath7%" 2>nul

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath8=%USERPROFILE%\Desktop\008"
   set "mtbotpath8=%mtmainpath8%\MQL5\Experts"
   md "%mtbotpath8%" 2>nul

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath9=%USERPROFILE%\Desktop\009"
   set "mtbotpath9=%mtmainpath9%\MQL5\Experts"
   md "%mtbotpath9%" 2>nul

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath10=%USERPROFILE%\Desktop\010"
   set "mtbotpath10=%mtmainpath10%\MQL5\Experts"
   md "%mtbotpath10%" 2>nul

   ping -n 3 127.0.0.1 >nul
   set "mtmainpath11=%USERPROFILE%\Desktop\011"
   set "mtbotpath11=%mtmainpath11%\MQL5\Experts"
   md "%mtbotpath11%" 2>nul

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

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath5%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath6%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath7%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath8%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath9%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath10%"

   ping -n 5 127.0.0.1 >nul
   copy "%mtbotpath%\%snrbot%" "%mtbotpath11%"

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

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath5%" 2>nul
   %COMSPEC% /C start %mtmainpath5%\terminal64.exe /portable

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath6%" 2>nul
   %COMSPEC% /C start %mtmainpath6%\terminal64.exe /portable

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath7%" 2>nul
   %COMSPEC% /C start %mtmainpath7%\terminal64.exe /portable

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath8%" 2>nul
   %COMSPEC% /C start %mtmainpath8%\terminal64.exe /portable

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath9%" 2>nul
   %COMSPEC% /C start %mtmainpath9%\terminal64.exe /portable

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath10%" 2>nul
   %COMSPEC% /C start %mtmainpath10%\terminal64.exe /portable

   ping -n 90 127.0.0.1 >nul
   cd "%mtmainpath11%" 2>nul
   %COMSPEC% /C start %mtmainpath11%\terminal64.exe /portable

   endlocal
