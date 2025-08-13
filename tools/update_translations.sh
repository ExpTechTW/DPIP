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
POT_FILE="./.crowdin/strings.pot"

# 執行 i18n 擴充功能匯入器
echo -e "${BLUE}$ dart run i18n_extension_importer:getstrings --output-file ./assets/translations/strings.pot${RESET}"
dart run i18n_extension_importer:getstrings --output-file ./assets/translations/strings.pot
echo

# 更新每個 .po 檔案
for po_file in "$PO_DIR"/*.po; do
    if [ -f "$po_file" ]; then
        echo -e -n "${BLUE}更新 $(basename "$po_file") ${RESET}"
        msgmerge --update --backup=off "$po_file" "$POT_FILE"
    fi
done 

# 更新 zh-Hant.po
ZH_HANT_PO="$PO_DIR/zh-Hant.po"
if [ -f "$ZH_HANT_PO" ]; then
    echo -e "${BLUE}自動填入 zh-Hant.po 的 msgstr...${RESET}"
    awk '
    BEGIN {
        in_msgid = 0
        in_msgstr = 0
        msgid_content = ""
        msgstr_buffer = ""
        collecting_msgid = 0
        collecting_msgstr = 0
    }
    
    # 開始新的 msgid
    /^msgid / {
        # 處理前一個完整的 msgid/msgstr 對
        if (in_msgid && in_msgstr) {
            print "msgid " msgid_content
            print "msgstr " msgid_content
        }
        
        # 開始新的 msgid
        in_msgid = 1
        in_msgstr = 0
        msgid_content = substr($0, 7)  # 提取 msgid 後面的內容
        msgstr_buffer = ""
        collecting_msgid = 1
        collecting_msgstr = 0
        next
    }
    
    # 開始 msgstr
    /^msgstr / {
        collecting_msgid = 0
        collecting_msgstr = 1
        in_msgstr = 1
        msgstr_buffer = $0
        next
    }
    
    # 收集 msgid 或 msgstr 的內容行
    /^"/ {
        if (collecting_msgid) {
            msgid_content = msgid_content "\n" $0
        } else if (collecting_msgstr) {
            msgstr_buffer = msgstr_buffer "\n" $0
        }
        next
    }
    
    # 其他行（註解、空行等）
    {
        if (in_msgid && in_msgstr) {
            print "msgid " msgid_content
            print "msgstr " msgid_content
        }
        
        # 重置狀態
        in_msgid = 0
        in_msgstr = 0
        msgid_content = ""
        msgstr_buffer = ""
        collecting_msgid = 0
        collecting_msgstr = 0
        print
    }
    
    END {
        # 處理最後一個 msgid/msgstr 對
        if (in_msgid && in_msgstr) {
            print "msgid " msgid_content
            print "msgstr " msgid_content
        }
    }
    ' "$ZH_HANT_PO" > "$ZH_HANT_PO.tmp" && mv "$ZH_HANT_PO.tmp" "$ZH_HANT_PO"
fi
