@echo off
setlocal enabledelayedexpansion

:: ============================================================
::                      USER CONFIGURATION
:: ============================================================

set INSTANCE_COUNT=4
set BASE_DIR=%USERPROFILE%\Desktop
set SOURCE_INSTANCE=001

set BOT_FILES=HISTORY.ex5, SNRL7.ex5, PriceRunner.ex5
set DOWNLOAD_URL=https://sherifawzi.github.io/Tools/

set CLEAN_FOLDERS=logs, profiles, Tester

set DELAY_SHORT=5
set DELAY_LONG=20

:: ============================================================
::                      MAIN SCRIPT
:: ============================================================

set "source_path=%BASE_DIR%\%SOURCE_INSTANCE%"
set "source_exe=%source_path%\terminal64.exe"

echo Creating folders and ensuring terminal64.exe exists in all instances...

:: --- Create folders for all instances & copy terminal64.exe if missing ---
for /L %%i in (1,1,%INSTANCE_COUNT%) do (
    set "num=00%%i"
    set "num=!num:~-3!"
    set "instance_path=%BASE_DIR%\!num!"
    set "experts_path=!instance_path!\MQL5\Experts"

    md "!experts_path!" 2>nul

    if %%i neq 1 (
        if not exist "!instance_path!\terminal64.exe" (
            echo Copying terminal64.exe to !num! ...
            copy "%source_exe%" "!instance_path!" >nul
        )
    )

    timeout /t %DELAY_SHORT% /nobreak >nul
)

:: --- Download bots into the source instance (001) ---
set "source_experts=%source_path%\MQL5\Experts"

for %%b in (%BOT_FILES%) do (
    set "bot=%%b"
    set "bot=!bot: =!"
    echo Downloading !bot! ...
    powershell -Command "Invoke-WebRequest -Uri '%DOWNLOAD_URL%!bot!' -OutFile '%source_experts%\!bot!'"
    timeout /t %DELAY_SHORT% /nobreak >nul
)

:: --- Copy bots from source to all other instances ---
for /L %%i in (2,1,%INSTANCE_COUNT%) do (
    set "num=00%%i"
    set "num=!num:~-3!"
    set "target_experts=%BASE_DIR%\!num!\MQL5\Experts"
    for %%b in (%BOT_FILES%) do (
        set "bot=%%b"
        set "bot=!bot: =!"
        echo Copying !bot! to instance !num! ...
        copy "%source_experts%\!bot!" "!target_experts!" >nul
        timeout /t %DELAY_SHORT% /nobreak >nul
    )
)

:: --- Start each MT5 instance (clean + launch) ---
echo Starting MT5 instances...

for /L %%i in (1,1,%INSTANCE_COUNT%) do (
    set "num=00%%i"
    set "num=!num:~-3!"
    set "instance_path=%BASE_DIR%\!num!"
    cd /d "!instance_path!" 2>nul

    echo Cleaning instance !num! ...
    for %%f in (%CLEAN_FOLDERS%) do (
        rmdir /S /Q "%%f" 2>nul
    )
    
    timeout /t %DELAY_SHORT% /nobreak >nul

    echo Launching instance !num! ...
    %COMSPEC% /C start terminal64.exe /portable

    if %%i neq %INSTANCE_COUNT% (
        timeout /t %DELAY_LONG% /nobreak >nul
    )
)

endlocal
exit
