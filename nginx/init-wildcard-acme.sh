#!/bin/bash

# Переходим в корневую директорию проекта
cd "$(dirname "$0")/.." || { echo "Ошибка: Не удалось перейти в корневую директорию проекта"; exit 1; }

# Загружаем переменные из .env файла
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo "Ошибка: Файл .env не найден!"
    exit 1
fi

# Проверяем наличие необходимых переменных
if [ -z "$ACME_SH_EMAIL" ]; then
    echo "Ошибка: Переменная ACME_SH_EMAIL не задана в файле .env"
    exit 1
fi

if [ -z "$DOMAIN" ]; then
    echo "Ошибка: Переменная DOMAIN не задана в файле .env"
    exit 1
fi

# Создаем необходимые директории
mkdir -p ./acme.sh
mkdir -p ./nginx/ssl/$DOMAIN

# Устанавливаем правильные разрешения
chmod 755 ./acme.sh
chmod -R 755 ./nginx/ssl

echo "Получение wildcard сертификата для домена $DOMAIN в ручном режиме..."
echo "Вам потребуется создать TXT-записи в DNS вашего домена."

# Запускаем acme.sh для получения wildcard сертификата
docker-compose -f docker-compose.acme.yml run --rm  acme --issue --dns \
  --server letsencrypt \
  -d $DOMAIN \
  -d "*.$DOMAIN" \
  --keylength 2048 \
  --yes-I-know-dns-manual-mode-enough-go-ahead-please

# Ждем, пока пользователь создаст DNS-записи
echo "Пожалуйста, создайте указанные выше DNS TXT записи в вашей DNS-панели."
echo "После создания записей, подождите некоторое время для их распространения (обычно 5-10 минут)."
read -p "Нажмите Enter, когда DNS-записи будут созданы и распространены..."

# Проверяем DNS-записи
docker-compose -f docker-compose.acme.yml run --rm acme --renew \
  --server letsencrypt \
  -d $DOMAIN \
  -d "*.$DOMAIN" \
  --yes-I-know-dns-manual-mode-enough-go-ahead-please

# Проверяем результат выполнения предыдущей команды
if [ $? -ne 0 ]; then
    echo "Ошибка при получении сертификата! Возможно, DNS-записи еще не распространились."
    echo "Подождите некоторое время и попробуйте запустить скрипт снова."
    exit 1
fi

echo "Установка сертификата для Nginx..."

# Устанавливаем сертификаты в нужную директорию для Nginx
docker-compose -f docker-compose.acme.yml --rm acme --install-cert \
  -d $DOMAIN \
  --server letsencrypt \
  --key-file /etc/nginx/ssl/$DOMAIN/$DOMAIN.key \
  --fullchain-file /etc/nginx/ssl/$DOMAIN/fullchain.cer \
  --reloadcmd "touch /etc/nginx/ssl/$DOMAIN/reload.txt"

# Проверяем результат выполнения предыдущей команды
if [ $? -ne 0 ]; then
    echo "Ошибка при установке сертификата!"
    exit 1
fi

# Перезапускаем Nginx для применения новых сертификатов, если он не запущен
echo "Перезапускаем Nginx для применения новых сертификатов..."
if docker-compose ps | grep -q "nginx.*Up"; then
    docker-compose restart nginx
else
    echo "Nginx не запущен."
fi

echo "SSL сертификаты успешно получены и установлены!"
echo "Проверьте наличие файлов в директории ./nginx/ssl/$DOMAIN/"
ls -la ./nginx/ssl/$DOMAIN/
