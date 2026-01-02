#!/bin/sh

echo "=== Автоматическая установка youtubeUnblock и luci-app-youtubeUnblock ==="

ARCH=$(opkg print-architecture | grep -vE 'all|noarch' | awk '{print $2}' | tail -n1)
if [ -z "$ARCH" ]; then
  echo "Ошибка: не удалось определить архитектуру."
  exit 1
fi
echo "Обнаружена архитектура: $ARCH"

echo "Проверяем установленные модули kmod..."
KMOD_NFT_QUEUE_INSTALLED=$(opkg list-installed | grep -q "kmod-nft-queue" && echo "yes" || echo "no")
KMOD_NFNETLINK_QUEUE_INSTALLED=$(opkg list-installed | grep -q "kmod-nfnetlink-queue" && echo "yes" || echo "no")

if [ "$KMOD_NFT_QUEUE_INSTALLED" = "yes" ] && [ "$KMOD_NFNETLINK_QUEUE_INSTALLED" = "yes" ]; then
    echo "  Модули kmod-nft-queue и kmod-nfnetlink-queue уже установлены"
else
    echo "  Один или оба модуля kmod не установлены. Выполняем обновление и установку..."
    
    echo "Обновляем список пакетов..."
    opkg update
    
    echo "Устанавливаем зависимости (curl, ca-bundle)..."
    opkg install curl ca-bundle

    opkg install kmod-nft-queue kmod-nfnetlink-queue
fi

opkg list-installed | grep kmod-nft
[ $? -eq 0 ] && echo "  Пакеты kmod-nft обнаружены" || { echo "  Ошибка: пакеты kmod-nft не найдены"; exit 1; }

LATEST_TAG=$(wget -qO- https://github.com/Waujito/youtubeUnblock/releases/latest/ | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | head -n1)
if [ -z "$LATEST_TAG" ]; then
  echo "Ошибка: не удалось получить latest версию."
  exit 1
fi
echo "Последняя версия: $LATEST_TAG"

RELEASE_URL="https://github.com/Waujito/youtubeUnblock/releases/download/$LATEST_TAG"

ASSETS=$(wget -qO- "https://github.com/Waujito/youtubeUnblock/releases/expanded_assets/$LATEST_TAG" | grep -oE "youtubeUnblock-${LATEST_TAG//v}-[0-9]-[0-9a-f]+-[^\"]+\.ipk" | grep -v "entware" | sort -u)

PKG=$(echo "$ASSETS" | grep -E "youtubeUnblock-${LATEST_TAG//v}-[0-9]-[0-9a-f]+.*${ARCH}.*-openwrt-[0-9]+\.[0-9]+\.ipk" | head -n1)
if [ -z "$PKG" ]; then
  echo "Ошибка: не найден пакет для архитектуры $ARCH в latest релизе."
  exit 1
fi
echo "Выбран пакет youtubeUnblock: $PKG"

LUCI_PKG=$(wget -qO- "https://github.com/Waujito/youtubeUnblock/releases/expanded_assets/$LATEST_TAG" | grep -oE "luci-app-youtubeUnblock-${LATEST_TAG//v}-[0-9]-[0-9a-f]+\.ipk" | grep -v "entware" | head -n1)
if [ -z "$LUCI_PKG" ]; then
  echo "Ошибка: не найден luci-app в latest релизе."
  exit 1
fi
echo "Выбран пакет luci-app: $LUCI_PKG"

echo "Скачиваем пакет youtubeUnblock..."
wget -O "/tmp/$PKG" "$RELEASE_URL/$PKG"
[ $? -eq 0 ] && echo "  Пакет youtubeUnblock скачан" || { echo "  Ошибка скачивания youtubeUnblock"; exit 1; }

if [ ! -f "/tmp/$PKG" ]; then
    echo "Ошибка: файл $PKG не был найден в /tmp"
    exit 1
fi

echo "Устанавливаем youtubeUnblock..."
opkg install "/tmp/$PKG"
[ $? -eq 0 ] && echo "  youtubeUnblock установлен успешно" || { echo "  Ошибка установки youtubeUnblock"; exit 1; }

/etc/init.d/youtubeUnblock stop

echo "Скачиваем пакет luci-app-youtubeUnblock..."
wget -O "/tmp/$LUCI_PKG" "$RELEASE_URL/$LUCI_PKG"
[ $? -eq 0 ] && echo "  Пакет luci-app-youtubeUnblock скачан" || { echo "  Ошибка скачивания luci-app-youtubeUnblock"; exit 1; }

echo "Устанавливаем luci-app-youtubeUnblock..."
opkg install "/tmp/$LUCI_PKG"
[ $? -eq 0 ] && echo "  luci-app-youtubeUnblock установлен успешно" || { echo "  Ошибка установки luci-app-youtubeUnblock"; exit 1; }

echo "Включаем автозапуск youtubeUnblock..."
/etc/init.d/youtubeUnblock enable
/etc/init.d/youtubeUnblock start
[ $? -eq 0 ] && echo "  youtubeUnblock настроен на автозапуск" || { echo "  Ошибка включения автозапуска youtubeUnblock"; exit 1; }

rm -f /tmp/*.ipk

echo "=== Установка завершена успешно ==="
