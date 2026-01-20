rmdir /S /Q "logs" >nul
rmdir /S /Q "profiles" >nul
rmdir /S /Q "Tester" >nul
set "snrconfig=%USERPROFILE%\AppData\Roaming\MetaQuotes\Terminal\Common\Files\configur.ini"
%COMSPEC% /C start terminal64.exe /config:"%snrconfig%" /portable
