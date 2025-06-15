#!/bin/bash

# 用於更新 .po 檔案與 .pot 檔案中最新翻譯的腳本
# 此腳本應從專案根目錄執行

# 檢查終端機是否支援顏色
if [ -t 1 ] && [ -n "$TERM" ] && command -v tput >/dev/null 2>&1; then
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    RESET='\033[0m'
else
    BLUE=''
    YELLOW=''
    RED=''
    RESET=''
fi

# 檢查是否已安裝 msgmerge
if ! command -v msgmerge &> /dev/null; then
    echo -e "${RED}msgmerge: command not found${RESET}"
    echo
    echo -e "${YELLOW}你需要安裝 gettext 套件來更新翻譯檔案。${RESET}"
    echo
    echo -e "${BLUE}如果你是 macOS 使用者：${RESET}"
    echo "  brew install gettext"
    echo
    echo -e "${BLUE}如果你是 Ubuntu/Debian 使用者：${RESET}"
    echo "  sudo apt-get update && sudo apt-get install gettext"
    echo
    echo -e "${BLUE}如果你是 Windows 使用者：${RESET}"
    echo "  choco install gettext    # 使用 Chocolatey"
    echo "  pacman -S gettext        # 使用 MSYS2"
    echo
    exit 1
fi

# .po 檔案所在目錄
PO_DIR="./assets/translations"
POT_FILE="$PO_DIR/strings.pot"

# 檢查 .pot 檔案是否存在
if [ ! -f "$POT_FILE" ]; then
  # 執行 i18n 擴充功能匯入器
  echo -e "${BLUE}$ dart run i18n_extension_importer:getstrings --output-file ./assets/translations/strings.pot${RESET}"
  dart run i18n_extension_importer:getstrings --output-file ./assets/translations/strings.pot
  echo
fi

# 更新每個 .po 檔案
for po_file in "$PO_DIR"/*.po; do
    if [ -f "$po_file" ]; then
        echo -e -n "${BLUE}更新 $(basename "$po_file") ${RESET}"
        msgmerge --update "$po_file" "$POT_FILE"
    fi
done 