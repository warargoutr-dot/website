@echo off
setlocal enabledelayedexpansion
chcp 65001 > nul
title Образовательная платформа — публичный запуск (ngrok)
cd /d "%~dp0"

echo ============================================
echo   Публичный запуск сайта через ngrok
echo ============================================
echo.

REM ---- 1. Проверка Node.js ----
where node >nul 2>&1
if errorlevel 1 (
    echo [X] Node.js не найден. Установите LTS с https://nodejs.org/
    pause
    exit /b 1
)

REM ---- 2. ngrok.exe рядом со скриптом ----
set "NGROK_EXE=%~dp0ngrok.exe"
if not exist "%NGROK_EXE%" (
    echo [+] ngrok.exe не найден. Скачиваю...
    curl.exe -sSL -o "%~dp0ngrok.zip" "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-windows-amd64.zip"
    if errorlevel 1 goto :download_fail
    tar.exe -xf "%~dp0ngrok.zip" -C "%~dp0"
    if errorlevel 1 goto :download_fail
    del /q "%~dp0ngrok.zip"
)
if not exist "%NGROK_EXE%" goto :download_fail

REM ---- 3. authtoken (один раз) ----
"%NGROK_EXE%" config check >nul 2>&1
if errorlevel 1 (
    echo.
    echo Перед первым запуском нужно сохранить ngrok authtoken.
    echo Получить токен: https://dashboard.ngrok.com/get-started/your-authtoken
    echo.
    set /p "NGROK_TOKEN=Введите authtoken: "
    "%NGROK_EXE%" config add-authtoken !NGROK_TOKEN!
    if errorlevel 1 (
        echo [X] Не удалось сохранить authtoken.
        pause
        exit /b 1
    )
)

REM ---- 4. Зависимости ----
if not exist "%~dp0node_modules" (
    echo [+] Устанавливаю зависимости (npm install)...
    call npm install
    if errorlevel 1 (
        echo [X] npm install не удался.
        pause
        exit /b 1
    )
)

REM ---- 5. Остановить старые процессы ----
echo [1/3] Останавливаю старые процессы node и ngrok...
taskkill /F /IM node.exe >nul 2>&1
taskkill /F /IM ngrok.exe >nul 2>&1
timeout /t 2 /nobreak >nul

REM ---- 6. Запуск сервера ----
echo [2/3] Запускаю Node.js сервер на порту 3000...
start "Сервер сайта" /MIN cmd /c "node server.js > server.log 2>&1"
timeout /t 5 /nobreak >nul

REM ---- 7. Запуск ngrok ----
echo [3/3] Запускаю ngrok туннель...
echo.
echo ============================================
echo   Адрес сайта появится ниже в строке Forwarding.
echo   Также его видно в панели http://localhost:4040
echo   Чтобы остановить — закройте это окно.
echo ============================================
echo.

start "" /B cmd /c "timeout /t 4 /nobreak >nul && start http://localhost:4040"

"%NGROK_EXE%" http 3000

REM Когда ngrok закрывается — убираем сервер
taskkill /F /IM node.exe >nul 2>&1
endlocal
exit /b 0

:download_fail
echo.
echo [X] Не удалось скачать ngrok автоматически.
echo     Скачайте вручную: https://ngrok.com/download
echo     Распакуйте ngrok.exe в эту же папку и запустите скрипт снова.
pause
exit /b 1
