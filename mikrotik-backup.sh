#!/bin/bash

# Импорт переменных из файла config.env
source config.env

# Функция для создания директории, если она не существует
function create_directory_if_not_exists() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
    fi
}

# Файл с IP-адресами MikroTik
MIKROTIK_IPS_FILE="mikrotik_ips.txt"

# Перебор IP-адресов из файла и выполнение действий
while IFS= read -r IP; do
    # Получение имени устройства
    IDENTITY=$(sshpass -p "$MikroTik_PASSWORD" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no $MikroTik_USERNAME@$IP '/system identity print value-name=name')

    # Генерация имени файла резервной копии (Identity + дата)
    DATE=$(date +"%Y-%m-%d")
    BACKUP_FILENAME="$BACKUP_DIRECTORY/$IDENTITY-$DATE-backup.backup"
    EXPORT_FILENAME="$EXPORT_DIRECTORY/$IDENTITY-$DATE-export.rsc"

    # Создание резервной копии конфигурации
    sshpass -p "$MikroTik_PASSWORD" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no $MikroTik_USERNAME@$IP "/system backup save name=$BACKUP_FILENAME"

    # Экспорт конфигурации в файл
    sshpass -p "$MikroTik_PASSWORD" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no $MikroTik_USERNAME@$IP "/export file=$EXPORT_FILENAME"

    # Копирование файлов на SFTP-сервер
    create_directory_if_not_exists "$EXPORT_DIRECTORY"
    create_directory_if_not_exists "$BACKUP_DIRECTORY"
    sshpass -p "$SFTP_PASSWORD" scp -o StrictHostKeyChecking=no "$BACKUP_FILENAME" "$SFTP_USER@$SFTP_HOST:$BACKUP_DIRECTORY"
    sshpass -p "$SFTP_PASSWORD" scp -o StrictHostKeyChecking=no "$EXPORT_FILENAME" "$SFTP_USER@$SFTP_HOST:$EXPORT_DIRECTORY"

    # Удаление временных файлов резервной копии
    sshpass -p "$MikroTik_PASSWORD" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no $MikroTik_USERNAME@$IP "/file remove $BACKUP_FILENAME"
    sshpass -p "$MikroTik_PASSWORD" ssh -o StrictHostKeyChecking=no -o PubkeyAuthentication=no $MikroTik_USERNAME@$IP "/file remove $EXPORT_FILENAME"
done < "$MIKROTIK_IPS_FILE"