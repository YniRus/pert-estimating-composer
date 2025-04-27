#!/bin/bash

# Клонирование репозиториев или их обновление
if [ -d "pert-estimating-server" ]; then
    echo "Обновляю pert-estimating-server..."
    cd pert-estimating-server
    git pull origin develop || exit 1
    cd ..
else
    echo "Скачиваю pert-estimating-server..."
    git clone -b develop --single-branch https://github.com/YniRus/pert-estimating-server.git || exit 1
fi

if [ -d "pert-estimating-client" ]; then
    echo "Обновляю pert-estimating-client..."
    cd pert-estimating-client
    git pull origin develop || exit 1
    cd ..
else
    echo "Скачиваю pert-estimating-client..."
    git clone -b develop --single-branch https://github.com/YniRus/pert-estimating-client.git || exit 1
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
docker-compose up --build
