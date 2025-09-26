@echo off
setlocal enabledelayedexpansion

:: =========================
:: CONFIGURATION
:: =========================
:: Make sure these are set before running
:: set URL=https://example.com/file.zip
:: set ZIPFILE=C:\path\to\file.zip
:: set EXTRACTDIR=C:\path\to\extract
:: set EXENAME=example.exe
:: set DESTDIR=C:\path\to\destination

:: =========================
:: MAIN
:: =========================
call :update_packages
call :windows_update
call :cleanup_temp_recycle
call :clear_windows_cache
call :download_and_install
echo All tasks completed.
exit /b 0

:: =========================
:: PACKAGE UPDATES
:: =========================
:update_packages
echo Updating packages...
:: Winget
winget upgrade --all --silent --accept-source-agreements --accept-package-agreements || echo Winget update failed

:: Scoop (single PS session)
powershell -NoProfile -Command "& {
    scoop update;
    scoop update *;
    scoop cleanup *;
}"

:: NPM
npm install -g npm
npm update -g

:: pip
powershell -NoProfile -Command "& {
    pip list --outdated --format=freeze | ForEach-Object {
        $pkg = ($_ -split '==')[0];
        Write-Host 'Updating' $pkg;
        pip install --upgrade $pkg;
    }
}"
goto :eof

:: =========================
:: WINDOWS UPDATE
:: =========================
:windows_update
echo Checking and installing Windows Updates...
powershell -NoProfile -Command "& {
    Import-Module PSWindowsUpdate;
    Write-Host 'Searching for updates...';
    Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot
}"
goto :eof

:: =========================
:: TEMP & RECYCLE BIN CLEANUP
:: =========================
:cleanup_temp_recycle
echo Clearing Temp folder...
if exist "%TEMP%\*" (
    del /q /f "%TEMP%\*.*" >nul 2>&1
    for /d %%i in ("%TEMP%\*") do rd /s /q "%%i" >nul 2>&1
)

echo Clearing Recycle Bin...
powershell -NoProfile -Command "Clear-RecycleBin -DriveLetter C -Force" >nul 2>&1
goto :eof

:: =========================
:: WINDOWS CACHE CLEAR
:: =========================
:clear_windows_cache
echo Clearing Windows Update and system caches...
for %%s in (wuauserv bits cryptsvc DoSvc DiagTrack) do (
    sc query %%s | find "RUNNING" >nul && net stop %%s
)

del /f /s /q %windir%\SoftwareDistribution\*.* >nul 2>&1
del /f /s /q %windir%\Logs\CBS\*.log >nul 2>&1
rd /s /q %windir%\SoftwareDistribution\DeliveryOptimization >nul 2>&1
rd /s /q %programdata%\Microsoft\Windows\DeliveryOptimization >nul 2>&1
rd /s /q "%localappdata%\Microsoft\Windows\INetCache" >nul 2>&1
rd /s /q "%localappdata%\Microsoft\Windows\WER" >nul 2>&1
rd /s /q "%programdata%\Microsoft\Diagnosis" >nul 2>&1
rd /s /q "%programdata%\Microsoft\Windows\Diagnosis" >nul 2>&1

cleanmgr /sagerun:1 >nul 2>&1

for %%s in (wuauserv bits cryptsvc DoSvc DiagTrack) do net start %%s >nul 2>&1
goto :eof

:: =========================
:: DOWNLOAD & INSTALL EXE
:: =========================
:download_and_install
echo Downloading file...
powershell -Command "Invoke-WebRequest -Uri '%URL%' -OutFile '%ZIPFILE%'" 

if not exist "%ZIPFILE%" (
    echo Failed to download file.
    exit /b 1
)

echo Extracting file...
powershell -Command "Expand-Archive -Path '%ZIPFILE%' -DestinationPath '%EXTRACTDIR%' -Force"

if not exist "%DESTDIR%" mkdir "%DESTDIR%"
move /Y "%EXTRACTDIR%\%EXENAME%" "%DESTDIR%"
goto :eof
