#!/bin/bash

# Функция для создания директории, если она не существует
function create_directory_if_not_exists() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

# Диапазон IP-адресов для подключения
IP_START="192.168.0.1"
IP_END="192.168.0.10"

# Параметры SFTP-сервера
SFTP_HOST="192.168.2.1"
SFTP_USER="your_username"
SFTP_PASSWORD="your_password"
SFTP_DIRECTORY="/path/to/backup/directory"

# Перебор IP-адресов в диапазоне и выполнение действий
for IP in $(seq -f '%.0f' $(echo $IP_START | tr '.' ' ') $(echo $IP_END | tr '.' ' ')); do
    # Получение имени устройства
    IDENTITY=$(sshpass -p "your_password" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no admin@$IP '/system identity print value-name=name')

    # Генерация имени файла резервной копии (Identity + дата)
    DATE=$(date +"%Y-%m-%d")
    BACKUP_FILENAME="$IDENTITY-$DATE-backup.backup"
    EXPORT_FILENAME="$IDENTITY-$DATE-export.rsc"

    # Создание резервной копии конфигурации
    sshpass -p "your_password" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no admin@$IP "/system backup save name=$BACKUP_FILENAME"

    # Экспорт конфигурации в файл
    sshpass -p "your_password" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no admin@$IP "/export file=$EXPORT_FILENAME"

    # Копирование файлов на SFTP-сервер
    create_directory_if_not_exists "$SFTP_DIRECTORY"
    sshpass -p "$SFTP_PASSWORD" scp -o StrictHostKeyChecking=no "$BACKUP_FILENAME" "$SFTP_USER@$SFTP_HOST:$SFTP_DIRECTORY"
    sshpass -p "$SFTP_PASSWORD" scp -o StrictHostKeyChecking=no "$EXPORT_FILENAME" "$SFTP_USER@$SFTP_HOST:$SFTP_DIRECTORY"

    # Удаление временных файлов резервной копии
    sshpass -p "your_password" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no admin@$IP "/file remove $BACKUP_FILENAME"
    sshpass -p "your_password" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no admin@$IP "/file remove $EXPORT_FILENAME"
done