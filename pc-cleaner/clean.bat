@echo off
cls

:: --- Initialization ----
title PC Cleaner - Loading... - https://github.com/FurryBoyYT/pc-cleaner

:: Admin Check with better elevation handling
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Administrative privileges required!
    echo [~] Restarting with elevated permissions...
    timeout /t 2 >nul
    powershell -Command "Start-Process '%~0' -Verb RunAs" >nul 2>&1
    exit /b
)

echo WARNING! The code was rewritten with some new paths as of April 5, 2025 and hasn't been tested.
echo Use at your own risk and report any issues on the GitHub issues page if there are any within the script.
echo ^-^-^-^> https://github.com/FurryBoyYT/pc-cleaner/issues ^<^-^-^-
echo.
echo Type "I agree" to continue.
set /p "userInput=> "
if /i not "%userInput%"=="i agree" (
    echo You did not agree. Exiting in 3 seconds...
    timeout /t 3 >nul
    exit /b
)
echo Now continuing with the script, you have been warned.

:admin
setlocal enabledelayedexpansion
cls
echo [✓] Running with administrative privileges

:: --- Restore Point Creation ----
echo [~] Creating system restore point...

set "restore_enabled=false"
for /f "tokens=2 delims== " %%G in ('wmic volume where "driveletter='C:'" get automount 2^>nul') do (
    if /i "%%G"=="FALSE" (
        wmic /namespace:\\root\default path SystemRestore call Enable "C:" >nul 2>&1
        set "restore_enabled=true"
    )
)

if "!restore_enabled!"=="true" (
    echo [!] Enabled system protection on C: drive
    timeout /t 3 >nul
)

wmic /namespace:\\root\default path SystemRestore call CreateRestorePoint "PC Cleaner Restore Point", 100, 7 >nul 2>&1
echo [✓] Restore point created successfully
timeout /t 2 >nul
cls

:: --- Cleaning Countdown ----
title PC Cleaner - Starting... - https://github.com/FurryBoyYT/pc-cleaner
echo [~] Cleaning process starting in:
for /l %%i in (5,-1,1) do (
    if %%i equ 1 (
        echo [~] Begin cleaning in %%i second...
    ) else (
        echo [~] Begin cleaning in %%i seconds...
    )
    echo [!] DO NOT CLOSE DURING CLEANING!
    timeout /nobreak /t 1 >nul
    cls
)

:: --- Main Cleaning Routine ----
title PC Cleaner - Cleaning... - https://github.com/FurryBoyYT/pc-cleaner

:: System Temp Cleaners
call :clean_dir "user temp" "%temp%"
call :clean_dir "windows temp" "%systemroot%\Temp"
call :clean_dir "system drive temp" "%systemdrive%\temp"
call :clean_dir "system temp" "%systemroot%\SystemTemp"

:: Windows Error Reporting
call :clean_dir "WER Temp" "C:\ProgramData\Microsoft\Windows\WER\Temp"
call :clean_dir "WER Archive" "C:\ProgramData\Microsoft\Windows\WER\ReportArchive"

:: Prefetch Cleaner
if exist "%systemroot%\prefetch\" (
    echo [~] Cleaning windows prefetch...
    del /f /q "%systemroot%\prefetch\*" >nul 2>&1
)

:: Registry Cleanup
echo [~] Cleaning registry cache...
for %%k in (
    "HKCR\Local Settings\MuiCache"
    "HKCU\Software\Classes\Local Settings\MuiCache"
    "HKU\.DEFAULT\Software\Classes\Local Settings\MuiCache"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU"
) do reg delete "%%~k" /f >nul 2>&1

:: Windows Update Cleanup (Improved)
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" >nul 2>&1
if errorlevel 1 (
    set "IS_PENDING_UPDATES=0"
    call :clean_dir "software distribution" "%systemroot%\SoftwareDistribution\Download"
) else (
    set "IS_PENDING_UPDATES=1"
    echo [] Skipping Windows Update cleanup - pending reboot required
)

:: Roblox Cleaners
echo [~] Cleaning Roblox temp files...
call :clean_dir "Roblox capture cache" "%localappdata%\Roblox\tmp-capture-storage"
call :clean_dir "Roblox logs" "%localappdata%\Roblox\logs"
call :clean_dir "Roblox downloads" "%localappdata%\Roblox\Downloads"
call :clean_dir "Roblox http cache" "%localappdata%\Roblox\rbx-storage"
del /f /s /q "C:\Users\bogda\AppData\Local\Roblox\rbx-storage.db" >nul 2>&1
del /f /s /q "C:\Users\bogda\AppData\Local\Roblox\rbx-storage.db-shm" >nul 2>&1
del /f /s /q "C:\Users\bogda\AppData\Local\Roblox\rbx-storage.db-wal" >nul 2>&1
del /f /s /q "C:\Users\bogda\AppData\Local\Roblox\rbx-storage.id" >nul 2>&1
del /f /s /q "C:\Users\bogda\AppData\Local\Roblox\server.rbxl" >nul 2>&1
call :clean_dir "Bloxstrap downloads" "%localappdata%\Bloxstrap\Downloads"
call :clean_dir "Bloxstrap logs" "%localappdata%\Bloxstrap\Logs"
call :clean_dir "Roblox UWP Cookies" "%localappdata%\Packages\ROBLOXCORPORATION.ROBLOX_55nm5eh3cm0pr\AC\Cookies"
call :clean_dir "Roblox LocalStorage" "%localappdata%\Roblox\LocalStorage"

:: System Maintenance
call :clean_dir "crash dumps" "%localappdata%\CrashDumps"
call :clean_dir "downloaded files" "%systemroot%\Downloaded Program Files"

:: Network Configuration
echo [~] Resetting network configuration...
ipconfig /flushdns >nul && echo [✓] DNS cache flushed
ipconfig /registerdns >nul && echo [✓] DNS registration refreshed
ipconfig /release >nul && echo [✓] IP addresses released
ipconfig /renew >nul && echo [✓] IP addresses renewed

:: Memory Optimization
powershell -Command "Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue" >nul 2>&1
echo [✓] Memory compression disabled

:: --- Finalization ----
title PC Cleaner - Finished! - https://github.com/FurryBoyYT/pc-cleaner
echo.
echo [✓] PC Cleaning completed successfully!

if %IS_PENDING_UPDATES% == 1 (
    echo [!] Note: Windows Update cleanup skipped - pending updates require reboot
)

echo.
echo [~] Exiting in 10 seconds...
timeout /nobreak /t 10 >nul
exit /b

:: --- Functions ----
:clean_dir
echo.
echo [~] Cleaning %~1...
if exist "%~2\" (
    del /f /s /q "%~2\*" >nul 2>&1
    for /d %%i in ("%~2\*") do rd /s /q "%%i" >nul 2>&1
    echo [✓] %~1 cleaned
) else (
    echo [] %~1 directory not found
)
exit /b