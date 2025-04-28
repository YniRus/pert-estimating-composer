#!/bin/bash

# Остановка текущего процесса, если он запущен
if [ -f run.pid ]; then
    kill $(cat run.pid) 2>/dev/null || true
    rm run.pid
fi

# Запуск нового процесса
nohup bash run.sh > run.log 2>&1 &
echo $! > run.pid
echo "Скрипт запущен с PID: $(cat run.pid)"

echo "Лог в режиме реального времени (Ctrl+C для выхода)..."
tail -f run.log
