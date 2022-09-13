
rmdir /s /q bases
rmdir /s /q logs
rmdir /s /q profiles
rmdir /s /q Tester

rmdir /s /q MQL5\Files
rmdir /s /q MQL5\Images
rmdir /s /q MQL5\Indicators
rmdir /s /q MQL5\Libraries
rmdir /s /q MQL5\Logs
rmdir /s /q MQL5\Profiles
rmdir /s /q MQL5\Scripts
rmdir /s /q MQL5\Services
rmdir /s /q MQL5\Shared Projects

rmdir /s /q MQL5\Experts\Advisors
rmdir /s /q MQL5\Experts\Examples

del /f /s /q Config\*.ini
del /f /s /q Config\agents.dat
del /f /s /q Config\servers.dat

del /f /s /q MQL5\experts.dat

robocopy "Z:\FOREX\MT5" "Z:\FOREX\MT5" /S /move

pause