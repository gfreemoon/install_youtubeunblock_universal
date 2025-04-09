#!/bin/sh

echo "=== Автоматическая установка youtubeUnblock и luci-app-youtubeUnblock ==="

ARCH=$(uname -m)
echo "Обнаружена архитектура: $ARCH"

LUCI_PKG="luci-app-youtubeUnblock-1.0.0-10-f37c3dd.ipk"

case "$ARCH" in
    aarch64)
        PKG="youtubeUnblock-1.0.0-10-f37c3dd-aarch64_generic-openwrt-23.05.ipk"
        ;;
    armv7)
        PKG="youtubeUnblock-1.0.0-10-f37c3dd-armv7-static.tar.gz"
        ;;
    armv7sf)
        PKG="youtubeUnblock-1.0.0-10-f37c3dd-armv7sf-static.tar.gz"
        ;;
    armv6l)
        PKG="youtubeUnblock-1.0.0-10-f37c3dd-arm_arm1176jzf-s_vfp-openwrt-23.05.ipk"
        ;;
    armv5te)
        PKG="youtubeUnblock-1.0.0-10-f37c3dd-arm_arm926ej-s-openwrt-23.05.ipk"
        ;;
    x86_64)
        PKG="youtubeUnblock-1.0.0-10-f37c3dd-x86_64-openwrt-23.05.ipk"
        ;;
    mips)
        PKG="youtubeUnblock-1.0.0-10-f37c3dd-mips-static.tar.gz"
        ;;
    mipsel)
        PKG="youtubeUnblock-1.0.0-10-f37c3dd-mipsel-static.tar.gz"
        ;;
    *)
        echo "Ошибка: архитектура '$ARCH' не поддерживается этим скриптом"
        exit 1
        ;;
esac

# Шаг 1. Обновление списка пакетов
echo "Обновляем список пакетов..."
opkg update
[ $? -eq 0 ] && echo "  Список пакетов обновлен" || { echo "  Ошибка обновления списка пакетов"; exit 1; }

# Шаг 2. Установка модулей для nftables
echo "Устанавливаем модули kmod-nft-queue и kmod-nfnetlink-queue..."
opkg install kmod-nft-queue kmod-nfnetlink-queue
[ $? -eq 0 ] && echo "  Модули установлены" || { echo "  Ошибка установки модулей"; exit 1; }

# Шаг 3. Проверка установленных пакетов
echo "Проверяем установку kmod-nft..."
opkg list-installed | grep kmod-nft
[ $? -eq 0 ] && echo "  Пакеты kmod-nft обнаружены" || { echo "  Пакеты kmod-nft не найдены"; exit 1; }

# Шаг 4. Скачивание и установка youtubeUnblock
echo "Скачиваем пакет youtubeUnblock..."
wget "https://github.com/Waujito/youtubeUnblock/releases/download/v1.0.0/$PKG"
[ $? -eq 0 ] && echo "  Пакет youtubeUnblock скачан" || { echo "  Ошибка скачивания youtubeUnblock"; exit 1; }

echo "Устанавливаем youtubeUnblock..."
opkg install "/tmp/$PKG"
[ $? -eq 0 ] && echo "  youtubeUnblock установлен успешно" || { echo "  Ошибка установки youtubeUnblock"; exit 1; }

# Шаг 5. Установка luci-app-youtubeUnblock
echo "Скачиваем пакет luci-app-youtubeUnblock..."
wget "https://github.com/Waujito/youtubeUnblock/releases/download/v1.0.0/luci-app-youtubeUnblock-1.0.0-10-f37c3dd.ipk"
[ $? -eq 0 ] && echo "  Пакет luci-app-youtubeUnblock скачан" || { echo "  Ошибка скачивания luci-app-youtubeUnblock"; exit 1; }

echo "Устанавливаем luci-app-youtubeUnblock..."
opkg install "/tmp/luci-app-youtubeUnblock-1.0.0-10-f37c3dd.ipk"
[ $? -eq 0 ] && echo "  luci-app-youtubeUnblock установлен успешно" || { echo "  Ошибка установки luci-app-youtubeUnblock"; exit 1; }

# Шаг 6. Включение автозапуска youtubeUnblock
echo "Включаем автозапуск youtubeUnblock..."
/etc/init.d/youtubeUnblock enable
[ $? -eq 0 ] && echo "  youtubeUnblock настроен на автозапуск" || { echo "  Ошибка включения автозапуска youtubeUnblock"; exit 1; }

echo "=== Установка завершена успешно ==="