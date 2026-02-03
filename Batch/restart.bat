@echo off

if exist "%APPDATA%\MetaQuotes\Terminal\Common\Files\restart.txt" (
    echo Restart signal file detected. Restarting the system...
    timeout /t 10 /nobreak >nul
    del "%APPDATA%\MetaQuotes\Terminal\Common\Files\restart.txt"
    timeout /t 10 /nobreak >nul
    curl -s -X POST "https://api.telegram.org/bot8450507003:AAHhqJg_6x_ajStvx2_eoZRHnVIRpexzQc4/sendMessage" -d chat_id=-1003285305833 -d text="<b>WIN01 Server Restart</b>" -d parse_mode=HTML
    shutdown /r /f /t 10
    exit
)

