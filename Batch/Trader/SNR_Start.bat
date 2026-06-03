   @echo off
   setlocal

   :: ------------------------------ File to download
   set "snrbatch=oem.bat"

   set "batchpath=%USERPROFILE%\Desktop\BAT"

   :: ------------------------------ Start MT5s
   ping -n 3 127.0.0.1 >nul
   cd "%batchpath%" 2>nul
   start %batchpath%\%snrbatch%

   endlocal
   exit

