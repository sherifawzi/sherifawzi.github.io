@echo off
:loop
if exist "C:\Users\ubuntu\AppData\Roaming\MetaQuotes\Terminal\Common\Files\restart.me" (
    echo Restart signal file detected. Restarting the system...
    timeout /t 5 /nobreak >nul
    del "C:\Users\ubuntu\AppData\Roaming\MetaQuotes\Terminal\Common\Files\restart.me"
    echo Waiting 30 seconds before restart...
    timeout /t 30 /nobreak >nul
    shutdown /r /t 0
    exit
)
timeout /t 180 /nobreak >nul
goto loop
