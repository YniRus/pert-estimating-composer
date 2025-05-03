#!/bin/bash

if [ ! -z "$1" ]; then
    BRANCH="$1"
else
    BRANCH="master"
fi

# Клонирование репозиториев или их обновление
if [ -d "pert-estimating-server" ]; then
    echo "Обновляю pert-estimating-server [$BRANCH] ..."
    cd pert-estimating-server
    git pull origin $BRANCH || exit 1
    cd ..
else
    echo "Скачиваю pert-estimating-server [$BRANCH] ..."
    git clone -b $BRANCH --single-branch https://github.com/YniRus/pert-estimating-server.git || exit 1
fi

if [ -d "pert-estimating-client" ]; then
    echo "Обновляю pert-estimating-client [$BRANCH] ..."
    cd pert-estimating-client
    git pull origin $BRANCH || exit 1
    cd ..
else
    echo "Скачиваю pert-estimating-client [$BRANCH] ..."
    git clone -b $BRANCH --single-branch https://github.com/YniRus/pert-estimating-client.git || exit 1
fi

# Копирование .env файлов в соответствующие директории
echo "Копирую .env файлы..."
if [ -f ".env.client" ]; then
    cp .env.client pert-estimating-client/.env
else
    echo "Файл .env.client не найден!"
    exit 1
fi

if [ -f ".env.server" ]; then
    cp .env.server pert-estimating-server/.env
else
    echo "Файл .env.server не найден!"
    exit 1
fi

# Запуск Docker Compose
echo "Запускаю docker-compose..."
docker-compose down && docker-compose up --build
