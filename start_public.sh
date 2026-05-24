#!/usr/bin/env bash
# Публичный запуск образовательной платформы через ngrok (Linux / macOS)
set -e
cd "$(dirname "$0")"

echo "============================================"
echo "  Публичный запуск сайта через ngrok"
echo "============================================"
echo

# ---- 1. Node.js ----
if ! command -v node >/dev/null 2>&1; then
  echo "[X] Node.js не найден. Установите: https://nodejs.org/"
  exit 1
fi

# ---- 2. ngrok (рядом со скриптом или в PATH) ----
NGROK=""
if [ -x "./ngrok" ]; then
  NGROK="./ngrok"
elif command -v ngrok >/dev/null 2>&1; then
  NGROK="ngrok"
else
  echo "[+] ngrok не найден. Скачиваю..."
  OS=$(uname -s | tr '[:upper:]' '[:lower:]')
  ARCH=$(uname -m)
  case "$OS-$ARCH" in
    linux-x86_64)        URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz" ;;
    linux-aarch64|linux-arm64) URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz" ;;
    darwin-x86_64)       URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.tgz" ;;
    darwin-arm64)        URL="https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.tgz" ;;
    *) echo "[X] Неподдерживаемая ОС: $OS-$ARCH. Установите ngrok вручную: https://ngrok.com/download"; exit 1 ;;
  esac
  curl -sSL -o ngrok.tgz "$URL"
  tar -xzf ngrok.tgz
  chmod +x ngrok
  rm -f ngrok.tgz
  NGROK="./ngrok"
fi

# ---- 3. authtoken (один раз) ----
if ! "$NGROK" config check >/dev/null 2>&1; then
  echo
  echo "Перед первым запуском нужно сохранить ngrok authtoken."
  echo "Получить токен: https://dashboard.ngrok.com/get-started/your-authtoken"
  read -rp "Введите authtoken: " TOKEN
  "$NGROK" config add-authtoken "$TOKEN"
fi

# ---- 4. Зависимости ----
if [ ! -d node_modules ]; then
  echo "[+] Устанавливаю зависимости (npm install)..."
  npm install
fi

# ---- 5. Остановить старые процессы ----
echo "[1/3] Останавливаю старые процессы..."
pkill -f "node server.js" 2>/dev/null || true
pkill -x ngrok 2>/dev/null || true
sleep 1

# ---- 6. Сервер ----
echo "[2/3] Запускаю Node.js сервер на :3000..."
nohup node server.js > server.log 2>&1 &
NODE_PID=$!
sleep 4

# При выходе — глушим сервер
trap 'kill $NODE_PID 2>/dev/null || true' EXIT

# ---- 7. ngrok ----
echo "[3/3] Запускаю ngrok туннель..."
echo
echo "============================================"
echo "  Адрес сайта появится в строке Forwarding"
echo "  Панель: http://localhost:4040"
echo "  Чтобы остановить — Ctrl+C"
echo "============================================"
echo
exec "$NGROK" http 3000
