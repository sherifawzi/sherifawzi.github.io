@echo off

if exist "%APPDATA%\MetaQuotes\Terminal\Common\Files\restart.txt" (
    echo Restart signal file detected. Restarting the system...
    timeout /t 10 /nobreak >nul
    del "%APPDATA%\MetaQuotes\Terminal\Common\Files\restart.txt"
    timeout /t 10 /nobreak >nul
    shutdown /r /f /t 10
    exit
)
