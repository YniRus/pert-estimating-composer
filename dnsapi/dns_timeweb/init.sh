#!/bin/bash
# Скрипт для инициализации (загрузки) кастомного DNS API провайдера Timeweb Cloud

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$(dirname "$SCRIPT_DIR")"
TARGET_FILE="$TARGET_DIR/dns_timeweb.sh"

echo "Загрузка скрипта dns_timeweb.sh..."
curl -f -sS --connect-timeout 10 --max-time 30 -L "https://raw.githubusercontent.com/YniRus/acme.sh_dnsapi_timeweb.cloud/main/dns_timeweb.sh" -o "$TARGET_FILE"

if [ $? -eq 0 ]; then
    chmod +x "$TARGET_FILE"
    echo "Скрипт успешно загружен и сохранен в: $TARGET_FILE"
else
    echo "Ошибка при загрузке скрипта!"
    exit 1
fi
