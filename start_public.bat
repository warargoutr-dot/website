@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul
title Site - public launch via ngrok
cd /d "%~dp0"

echo ============================================
echo   Public launch of the site via ngrok
echo ============================================
echo.

REM ---- 1. Node.js ----
where node >nul 2>&1
if errorlevel 1 (
    echo [X] Node.js not found. Install LTS from https://nodejs.org/
    pause
    exit /b 1
)

REM ---- 2. ngrok.exe next to script ----
set "NGROK_EXE=%~dp0ngrok.exe"
if not exist "%NGROK_EXE%" (
    echo [+] ngrok.exe not found, downloading...
    curl.exe -sSL -o "%~dp0ngrok.zip" "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip"
    if errorlevel 1 goto DOWNLOAD_FAIL
    tar.exe -xf "%~dp0ngrok.zip" -C "%~dp0"
    if errorlevel 1 goto DOWNLOAD_FAIL
    del /q "%~dp0ngrok.zip"
)
if not exist "%NGROK_EXE%" goto DOWNLOAD_FAIL

REM ---- 3. authtoken (one-time) ----
"%NGROK_EXE%" config check >nul 2>&1
if errorlevel 1 (
    echo.
    echo Save your ngrok authtoken once.
    echo Get it at: https://dashboard.ngrok.com/get-started/your-authtoken
    echo.
    set /p "NGROK_TOKEN=Paste authtoken: "
    "%NGROK_EXE%" config add-authtoken !NGROK_TOKEN!
    if errorlevel 1 (
        echo [X] Failed to save authtoken.
        pause
        exit /b 1
    )
)

REM ---- 4. Dependencies ----
if not exist "%~dp0node_modules" (
    echo [+] Installing dependencies (npm install)...
    call npm install
    if errorlevel 1 (
        echo [X] npm install failed.
        pause
        exit /b 1
    )
)

REM ---- 5. Stop old processes ----
echo [1/3] Stopping old node and ngrok processes...
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM ngrok.exe >nul 2>&1
timeout /t 2 /nobreak >nul

REM ---- 6. Start Node server ----
echo [2/3] Starting Node.js server on port 3000...
start "Site server" /MIN cmd /c "node server.js > server.log 2>&1"
timeout /t 5 /nobreak >nul

REM ---- 7. Start ngrok ----
echo [3/3] Starting ngrok tunnel...
echo.
echo ============================================
echo   Public URL will appear below as "Forwarding ..."
echo   Inspector panel: http://localhost:4040
echo   Close this window to stop everything.
echo ============================================
echo.

start "" /B cmd /c "timeout /t 4 /nobreak >nul && start http://localhost:4040"

"%NGROK_EXE%" http 3000

REM Kill node when ngrok exits
taskkill /F /IM node.exe >nul 2>&1
endlocal
exit /b 0

:DOWNLOAD_FAIL
echo.
echo [X] Failed to download ngrok automatically.
echo     Download manually: https://ngrok.com/download
echo     Put ngrok.exe next to this script and run again.
pause
exit /b 1
