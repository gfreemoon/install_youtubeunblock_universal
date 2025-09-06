#!/bin/sh

echo "=== Автоматическая установка youtubeUnblock и luci-app-youtubeUnblock ==="

# Определяем архитектуру OpenWRT (берём последнюю, исключая all и noarch)
ARCH=$(opkg print-architecture | grep -vE 'all|noarch' | awk '{print $2}' | tail -n1)
if [ -z "$ARCH" ]; then
  echo "Ошибка: не удалось определить архитектуру."
  exit 1
fi
echo "Обнаружена архитектура: $ARCH"

# Получаем latest tag из URL релиза
LATEST_TAG=$(wget -qO- https://github.com/Waujito/youtubeUnblock/releases/latest/ | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
if [ -z "$LATEST_TAG" ]; then
  echo "Ошибка: не удалось получить latest версию."
  exit 1
fi
echo "Последняя версия: $LATEST_TAG"

# Базовый URL для assets
RELEASE_URL="https://github.com/Waujito/youtubeUnblock/releases/download/$LATEST_TAG"

# Получаем список .ipk файлов из релиза, исключая entware
ASSETS=$(wget -qO- "https://github.com/Waujito/youtubeUnblock/releases/expanded_assets/$LATEST_TAG" | grep -oE "youtubeUnblock-${LATEST_TAG//v}-[0-9]-[0-9a-f]+-[^\"]+\.ipk" | grep -v "entware" | sort -u)

# Ищем youtubeUnblock .ipk, содержащий архитектуру
PKG=$(echo "$ASSETS" | grep -E "youtubeUnblock-${LATEST_TAG//v}-[0-9]-[0-9a-f]+.*${ARCH}.*-openwrt-[0-9]+\.[0-9]+\.ipk" | head -n1)
if [ -z "$PKG" ]; then
  echo "Ошибка: не найден пакет для архитектуры $ARCH в latest релизе."
  exit 1
fi
echo "Выбран пакет youtubeUnblock: $PKG"

# Ищем luci-app (он без arch и entware)
LUCI_PKG=$(wget -qO- "https://github.com/Waujito/youtubeUnblock/releases/expanded_assets/$LATEST_TAG" | grep -oE "luci-app-youtubeUnblock-${LATEST_TAG//v}-[0-9]-[0-9a-f]+\.ipk" | grep -v "entware" | head -n1)
if [ -z "$LUCI_PKG" ]; then
  echo "Ошибка: не найден luci-app в latest релизе."
  exit 1
fi
echo "Выбран пакет luci-app: $LUCI_PKG"

# Шаг 1. Обновление списка пакетов
echo "Обновляем список пакетов..."
opkg update
[ $? -eq 0 ] && echo "  Список пакетов обновлён" || { echo "  Ошибка обновления списка пакетов"; exit 1; }

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
wget -O "/tmp/$PKG" "$RELEASE_URL/$PKG"
[ $? -eq 0 ] && echo "  Пакет youtubeUnblock скачан" || { echo "  Ошибка скачивания youtubeUnblock"; exit 1; }

# Проверка существования файла
if [ ! -f "/tmp/$PKG" ]; then
    echo "Ошибка: файл $PKG не был найден в /tmp"
    exit 1
fi

echo "Устанавливаем youtubeUnblock..."
opkg install "/tmp/$PKG"
[ $? -eq 0 ] && echo "  youtubeUnblock установлен успешно" || { echo "  Ошибка установки youtubeUnblock"; exit 1; }

# Шаг 5. Установка luci-app-youtubeUnblock
echo "Скачиваем пакет luci-app-youtubeUnblock..."
wget -O "/tmp/$LUCI_PKG" "$RELEASE_URL/$LUCI_PKG"
[ $? -eq 0 ] && echo "  Пакет luci-app-youtubeUnblock скачан" || { echo "  Ошибка скачивания luci-app-youtubeUnblock"; exit 1; }

echo "Устанавливаем luci-app-youtubeUnblock..."
opkg install "/tmp/$LUCI_PKG"
[ $? -eq 0 ] && echo "  luci-app-youtubeUnblock установлен успешно" || { echo "  Ошибка установки luci-app-youtubeUnblock"; exit 1; }

# Шаг 6. Включение автозапуска youtubeUnblock
echo "Включаем автозапуск youtubeUnblock..."
/etc/init.d/youtubeUnblock enable
[ $? -eq 0 ] && echo "  youtubeUnblock настроен на автозапуск" || { echo "  Ошибка включения автозапуска youtubeUnblock"; exit 1; }

# Шаг 7. Чистим временные файлы
rm /tmp/*.ipk

echo "=== Установка завершена успешно ==="
