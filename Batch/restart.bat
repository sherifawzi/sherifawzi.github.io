        @echo off
        :loop
        if exist "C:\Users\ubuntu\AppData\Roaming\MetaQuotes\Terminal\Common\Files\restart.me" (
            echo Restart signal file detected. Restarting the system...
            ping -n 5 127.0.0.1 >nul
            del "C:\Users\ubuntu\AppData\Roaming\MetaQuotes\Terminal\Common\Files\restart.me"
            ping -n 15 127.0.0.1 >nul
            shutdown /r /t 0
            exit
        )
        timeout /t 180 /nobreak >nul
        goto loop