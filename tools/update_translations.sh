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
echo -e "${BLUE}$ dart run i18n_extension_importer:getstrings --output-file ./.crowdin/strings.pot${RESET}"
dart run i18n_extension_importer:getstrings --output-file ./.crowdin/strings.pot
echo

# 更新每個 .po 檔案（跳過 zh-Hant.po）
for po_file in "$PO_DIR"/*.po; do
    if [ -f "$po_file" ] && [ "$(basename "$po_file")" != "zh-Hant.po" ]; then
        echo -e -n "${BLUE}更新 $(basename "$po_file") ${RESET}"
        LC_ALL=C msgmerge --update --backup=off "$po_file" "$POT_FILE"
    fi
done 

# 確保所有 .po 檔案中的路徑都有 ./ 前綴
echo -e "${BLUE}統一路徑格式...${RESET}"
for po_file in "$PO_DIR"/*.po; do
    if [ -f "$po_file" ] && [ "$(basename "$po_file")" != "zh-Hant.po" ]; then
        # 為路徑添加 ./ 前綴（如果還沒有的話）
        LC_ALL=C sed -i '' 's|^#: \([^.]\)|#: ./\1|g' "$po_file"
    fi
done

# 重新產生 zh-Hant.po（使用固定標頭並直接從 .pot 檔案複製內容）
ZH_HANT_PO="$PO_DIR/zh-Hant.po"
echo -e "${BLUE}重新產生 zh-Hant.po...${RESET}"

# 創建帶有固定標頭的新檔案
cat > "$ZH_HANT_PO" << 'EOF'
msgid ""
msgstr ""
"Project-Id-Version: dpip\n"
"Language-Team: Chinese Traditional\n"
"Language: zh_TW\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Plural-Forms: nplurals=1; plural=0;\n"
"X-Crowdin-Project: dpip\n"
"X-Crowdin-Project-ID: 696803\n"
"X-Crowdin-Language: zh-TW\n"
"X-Crowdin-File: /main/.crowdin/strings.pot\n"
"X-Crowdin-File-ID: 20\n"

EOF

# 直接從 .pot 檔案複製內容並將 msgstr 設為 msgid 的內容
LC_ALL=C sed 's/^msgstr ""/msgstr/' "$POT_FILE" | LC_ALL=C awk '
/^#/ { print; next }
/^msgid / { 
    msgid_line = $0
    msgid_content = substr($0, 7)
    print msgid_line
    # 輸出對應的 msgstr（複製 msgid 的內容）
    print "msgstr " msgid_content
    next
}
/^msgstr/ { next }  # 跳過原有的空 msgstr 行
/^$/ { print; next }  # 保留空行
{ print }  # 輸出其他所有行
' >> "$ZH_HANT_PO"

# 最後確保所有 .po 檔案（包括 zh-Hant.po）的路徑格式一致
echo -e "${BLUE}統一所有檔案的路徑格式...${RESET}"
for po_file in "$PO_DIR"/*.po; do
    if [ -f "$po_file" ]; then
        # 為路徑添加 ./ 前綴（如果還沒有的話）
        LC_ALL=C sed -i '' 's|^#: \([^.]\)|#: ./\1|g' "$po_file"
    fi
done
