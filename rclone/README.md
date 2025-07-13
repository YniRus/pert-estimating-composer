# Автоматическое резервное копирование с помощью rclone

Этот скрипт (`clone.sh`) создает резервные копии директорий `server-storage` и `server-assets` в Google Drive с использованием rclone.

## Предварительные требования

1. Установленный и настроенный [rclone](https://rclone.org/install/)
2. Настроенное удаленное хранилище Google Drive в rclone

## Настройка rclone

Если вы еще не настроили rclone для работы с Google Drive:

```bash
rclone config
```

Следуйте инструкциям для создания нового удаленного хранилища с именем "gdrive" (или любым другим именем который зададите в `RCLONE_REMOTE_NAME` в скрипте).
Также можно воспользоваться следующей подробной [инструкцией](https://green.cloud/docs/how-to-use-rclone-to-back-up-to-google-drive-on-linux/).

## Запуск скрипта вручную

```bash
./rclone/clone.sh
```

## Настройка автоматического запуска через cron

1. Откройте редактор cron:

```bash
crontab -e
```

2. Добавьте строку для запуска скрипта по расписанию, например (каждый день в 3 часа ночи):

```
0 3 * * * ~/pert-estimating-composer/rclone/clone.sh >> ~/pert-estimating-composer/rclone/clone.log 2>&1
```

3. Сохраните и закройте редактор.

## Проверка настройки cron

Чтобы проверить, что задача cron добавлена корректно:

```bash
crontab -l
```
