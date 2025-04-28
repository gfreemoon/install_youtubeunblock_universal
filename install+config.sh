#!/bin/sh

echo "1. Установка youtubeUnblock..."
wget -qO- https://raw.githubusercontent.com/gfreemoon/install_youtubeunblock_universal/refs/heads/main/install_youtubeUnblock.sh | sh

echo "2. Генерация конфигурации..."
wget -qO- https://raw.githubusercontent.com/gfreemoon/install_youtubeunblock_universal/refs/heads/main/ytu_config_generator.sh | sh

echo "3. Перезапуск youtubeUnblock..."
if [ -f "/etc/init.d/youtubeUnblock" ]; then
    /etc/init.d/youtubeUnblock restart
else
    echo "⚠️ Сервис youtubeUnblock не найден. Возможно, установка не удалась."
fi

echo "✅ Установка и настройка завершены!"
