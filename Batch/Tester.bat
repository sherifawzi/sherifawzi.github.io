        @echo off
        setlocal

        set "snrbot=TESTER.ex5"
        set "snrset=nTR3.set"

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
        ::%COMSPEC% /C start %mtmainpath%\terminal64.exe /portable

        endlocal