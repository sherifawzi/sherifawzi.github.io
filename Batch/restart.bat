@echo off

if exist "%APPDATA%\MetaQuotes\Terminal\Common\Files\restart.me" (
    echo Restart signal file detected. Restarting the system...
    timeout /t 5 /nobreak >nul
    del "%APPDATA%\MetaQuotes\Terminal\Common\Files\restart.me"
    echo Waiting 20 seconds before restart...
    timeout /t 20 /nobreak >nul
    shutdown /r /t 20
    exit
)
