#!/bin/sh
# Этот скрипт копирует все кастомные DNS API скрипты из смонтированной папки
# во внутреннюю папку dnsapi контейнера acme.sh, а затем запускает оригинальный entrypoint.

# Копируем только файлы, начинающиеся с dns_, чтобы не копировать README и служебные файлы
cp -f /custom_dnsapi/dns_*.sh /root/.acme.sh/dnsapi/ 2>/dev/null || true

# Запускаем оригинальный entrypoint контейнера acme.sh с переданными аргументами
exec /entrypoint.sh "$@"
