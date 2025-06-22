@echo off
chcp 437 > nul
title BingBlocker

echo BingBlocker - Disable Bing Search Tool
echo.
echo This tool requires administrator privileges.
echo.

REM Check for admin rights
NET SESSION >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo Please run this script as Administrator.
    echo Right-click on the batch file and select "Run as administrator".
    echo.
    pause
    exit
)

REM Run PowerShell script
echo Running PowerShell script...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0BingBlocker.ps1"

echo.
echo Process completed.
pause