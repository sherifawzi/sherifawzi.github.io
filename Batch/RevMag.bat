@echo off
setlocal

rmdir /S /Q "C:\Users\ubuntu\Desktop\001\logs" >nul
rmdir /S /Q "C:\Users\ubuntu\Desktop\001\profiles" >nul
rmdir /S /Q "C:\Users\ubuntu\Desktop\001\Tester" >nul
del /F /Q "C:\Users\ubuntu\AppData\Roaming\MetaQuotes\Terminal\Common\Files\restart.me" >nul

set "snrbot=RevMag.ex5"
set "snrset=RML02.set"

set "snrurl=https://sherifawzi.github.io/Tools/"
set "snrconfig=%USERPROFILE%\AppData\Roaming\MetaQuotes\Terminal\Common\Files\snrconfig.ini"

set "mtmainpath=%USERPROFILE%\Desktop\001"
set "mtbotpath=%mtmainpath%\MQL5\Experts"
set "mtsetpath=%mtmainpath%\MQL5\Profiles\Tester"

md "%mtbotpath%" 2>nul

ping -n 3 127.0.0.1 >nul

powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrbot%' -OutFile '%mtbotpath%\%snrbot%'"

ping -n 5 127.0.0.1 >nul

powershell -Command "Invoke-WebRequest -Uri '%snrurl%%snrset%' -OutFile '%mtsetpath%\%snrset%'"

ping -n 10 127.0.0.1 >nul

cd "%mtmainpath%" 2>nul
%COMSPEC% /C start %mtmainpath%\terminal64.exe /config:%snrconfig% /portable

endlocal
exit
