#!/bin/bash

# Загружаем переменные из .env файла
if [ -f .env ]; then
    export $(grep -v '^#' .env | tr -d '\r' | xargs)
else
    echo "Ошибка: Файл .env не найден!"
    exit 1
fi

# Проверяем наличие необходимых переменных
if [ -z "$ACME_SH_EMAIL" ]; then
    echo "Ошибка: Переменная ACME_SH_EMAIL не задана в файле .env"
    exit 1
fi

# Разбор параметров
DOMAIN=""
FORCE_UPDATE=false
FORCE_RELOAD=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force-update|-f)
            FORCE_UPDATE=true
            shift
            ;;
        --force-reload|-r)
            FORCE_RELOAD=true
            shift
            ;;
        *)
            if [ -z "$DOMAIN" ]; then
                DOMAIN="$1"
            else
                echo "Предупреждение: Проигнорирован лишний аргумент: $1"
            fi
            shift
            ;;
    esac
done

# Проверяем, что домен задан
if [ -z "$DOMAIN" ]; then
    echo "Ошибка: Передайте домен параметром"
    echo "Использование: $0 <домен> [--force-update|-f] [--force-reload|-r]"
    exit 1
fi

# Создаем необходимые директории
mkdir -p ./acme.sh
mkdir -p ./nginx/ssl/$DOMAIN

# Устанавливаем правильные разрешения
chmod 755 ./acme.sh
chmod -R 755 ./nginx/ssl

# Определяем провайдера DNS (по умолчанию manual)
PROVIDER="${DNS_PROVIDER:-manual}"

# Если используется автоматический режим, проверяем наличие скрипта DNS API
if [ "$PROVIDER" != "manual" ]; then
    # Поддерживаем имена как с префиксом dns_, так и без него
    PROVIDER_FILE="$PROVIDER"
    if [[ "$PROVIDER" != dns_* ]]; then
        PROVIDER_FILE="dns_${PROVIDER}"
    fi
    SCRIPT_PATH="./dnsapi/${PROVIDER_FILE}.sh"

    if [ ! -f "$SCRIPT_PATH" ]; then
        INIT_SCRIPT="./dnsapi/${PROVIDER_FILE}/init.sh"
        if [ -f "$INIT_SCRIPT" ]; then
            echo "Скрипт DNS API $SCRIPT_PATH не найден. Запуск автоматической инициализации через $INIT_SCRIPT..."
            chmod +x "$INIT_SCRIPT"
            "$INIT_SCRIPT"

            # Повторно проверяем наличие файла после инициализации
            if [ -f "$SCRIPT_PATH" ]; then
                echo "Инициализация успешна."
            else
                echo "Ошибка: Скрипт инициализации выполнился, но файл $SCRIPT_PATH не появился."
                exit 1
            fi
        else
            echo "Ошибка: Скрипт DNS API $SCRIPT_PATH не найден!"
            exit 1
        fi
    fi
fi

# Подготавливаем дополнительные аргументы для acme.sh
EXTRA_ARGS=()
if [ "$FORCE_UPDATE" = true ]; then
    EXTRA_ARGS+=("--force")
fi

# Определяем, запущен ли скрипт в интерактивном терминале.
# Если нет (например, под cron), добавляем -T к docker-compose run.
TTY_FLAG=""
if [ ! -t 0 ]; then
    TTY_FLAG="-T"
fi

if [ "$PROVIDER" = "manual" ]; then
    echo "Получение wildcard сертификата для $DOMAIN в РУЧНОМ режиме..."
    echo "Вам потребуется создать TXT-записи в DNS вашего домена."

    # Запускаем acme.sh для получения wildcard сертификата в ручном режиме
    docker-compose -f docker-compose.acme.yml run $TTY_FLAG --rm acme --issue --dns \
      --server letsencrypt \
      -d $DOMAIN \
      -d "*.$DOMAIN" \
      --keylength 2048 \
      --yes-I-know-dns-manual-mode-enough-go-ahead-please \
      "${EXTRA_ARGS[@]}"

    # Ждем, пока пользователь создаст DNS-записи
    echo "Пожалуйста, создайте указанные выше DNS TXT записи в вашей DNS-панели."
    echo "После создания записей, подождите некоторое время для их распространения (обычно 5-10 минут)."
    echo "Посмотреть распространились ли TXT записи можно по ссылке: https://www.nslookup.io/domains/_acme-challenge.$DOMAIN/dns-records/txt/"
    read -p "Нажмите Enter, когда DNS-записи будут созданы и распространены..."

    # Проверяем DNS-записи и завершаем получение сертификата
    docker-compose -f docker-compose.acme.yml run $TTY_FLAG --rm acme --renew \
      --server letsencrypt \
      -d $DOMAIN \
      -d "*.$DOMAIN" \
      --yes-I-know-dns-manual-mode-enough-go-ahead-please \
      "${EXTRA_ARGS[@]}"
else
    echo "Получение wildcard сертификата для $DOMAIN в АВТОМАТИЧЕСКОМ режиме через DNS API ($PROVIDER)..."
    echo "Убедитесь, что все необходимые API ключи/токены для $PROVIDER заданы в .env файле."

    # Запускаем acme.sh в автоматическом режиме с указанным провайдером
    docker-compose -f docker-compose.acme.yml run $TTY_FLAG --rm acme --issue --dns "$PROVIDER" \
      --server letsencrypt \
      -d $DOMAIN \
      -d "*.$DOMAIN" \
      --keylength 2048 \
      --dnssleep "${ACME_DNS_SLEEP:-120}" \
      "${EXTRA_ARGS[@]}"
fi

# Проверяем результат выполнения предыдущей команды
# acme.sh возвращает 0 при успешном получении и 2, если обновление пропущено (сертификат еще актуален)
EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ] && [ $EXIT_CODE -ne 2 ]; then
    echo "Ошибка при получении сертификата! (Код ошибки: $EXIT_CODE)"
    exit 1
fi

SHOULD_INSTALL=false
SHOULD_RELOAD=false

if [ $EXIT_CODE -eq 0 ]; then
    echo "Сертификат успешно получен/обновлен."
    SHOULD_INSTALL=true
    SHOULD_RELOAD=true
elif [ $EXIT_CODE -eq 2 ]; then
    if [ "$FORCE_RELOAD" = true ]; then
        echo "Сертификат уже получен, но задан принудительный перезапуск Nginx."
        SHOULD_RELOAD=true
    else
        echo "Сертификат уже получен и не требует обновления (Skipped). Перезапуск Nginx пропущен."
    fi
fi

if [ "$SHOULD_INSTALL" = true ]; then
    echo "Установка сертификата для Nginx..."

    # Устанавливаем сертификаты в нужную директорию для Nginx
    docker-compose -f docker-compose.acme.yml run $TTY_FLAG --rm acme --install-cert \
      -d $DOMAIN \
      --server letsencrypt \
      --key-file "/etc/nginx/ssl/$DOMAIN/$DOMAIN.key" \
      --fullchain-file "/etc/nginx/ssl/$DOMAIN/fullchain.cer" \
      --reloadcmd "touch /etc/nginx/ssl/$DOMAIN/reload.txt"

    # Проверяем результат выполнения предыдущей команды
    if [ $? -ne 0 ]; then
        echo "Ошибка при установке сертификата!"
        exit 1
    fi

    # Устанавливаем правильные разрешения для созданных сертификатов
    chmod -R 755 ./nginx/ssl/$DOMAIN
fi

if [ "$SHOULD_RELOAD" = true ]; then
    # Перезапускаем Nginx для применения новых сертификатов, если он не запущен
    echo "Перезапускаем Nginx для применения конфигурации/сертификатов..."
    if docker-compose ps | grep -q "nginx.*Up"; then
        docker-compose restart nginx
    else
        echo "Nginx не запущен."
    fi

    echo "Операция завершена (Nginx перезапущен)."
else
    echo "Операция завершена (перезапуск Nginx не требовался)."
fi
