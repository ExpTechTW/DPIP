#!/bin/bash

# 用於更新 .pot 檔案與生成 zh-Hant.po 的腳本
# 此腳本應從專案根目錄執行
# 其他語言的 .po 檔案由 Crowdin 自動同步管理

# 設定語言環境為繁體中文
export LC_ALL=zh_TW.UTF-8

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

# .po 檔案所在目錄
PO_DIR="./assets/translations"
POT_FILE="./.crowdin/strings.pot"

# 執行 i18n 擴充功能匯入器來更新 .pot 檔案
echo -e "${BLUE}> (1/3) 更新 .pot 檔案...${RESET}"
dart run i18n_extension_importer:getstrings --output-file ./.crowdin/strings.pot
echo

# 重新產生 zh-Hant.po（使用固定標頭並直接從 .pot 檔案複製內容）
ZH_HANT_PO="$PO_DIR/zh-Hant.po"
echo -e "${BLUE}> (2/3) 重新產生 zh-Hant.po...${RESET}"

# 創建帶有固定標頭的新檔案
cat > "$ZH_HANT_PO" << 'EOF'
msgid ""
msgstr ""
"Plural-Forms: nplurals=1; plural=0;\n"
"X-Crowdin-Project: dpip\n"
"X-Crowdin-Project-ID: 696803\n"
"X-Crowdin-Language: zh-TW\n"
"X-Crowdin-File: /main/.crowdin/strings.pot\n"
"X-Crowdin-File-ID: 20\n"
"Project-Id-Version: dpip\n"
"Content-Type: text/plain; charset=UTF-8\n"
"Language-Team: Chinese Traditional\n"
"Language: zh_TW\n"

EOF

# 從 .pot 檔案複製內容並將 msgstr 設為 msgid 的內容
gawk '
BEGIN {
  collecting_msgid = 0
  msgid_lines = ""
  msgid_content = ""
}

# 註解行直接印出
/^#/ { print $0; next }

# 空行直接印出，並重置狀態
/^$/ {
  collecting_msgid = 0
  msgid_lines = ""
  msgid_content = ""
  print ""
  next
}

# msgid 開始
/^msgid/ {
  collecting_msgid = 1
  msgid_lines = ""
  msgid_content = ""
  print $0
  
  # 單行 msgid
  if ($0 ~ /^msgid ".+"$/) {
    msgid_content = substr($0, 7)  # 去掉 "msgid " 保留引號
    collecting_msgid = 0
  }
  next
}

# 多行 msgid 的續行
collecting_msgid && /^"/ {
  print $0
  if (msgid_lines == "") {
    msgid_lines = $0
  } else {
    msgid_lines = msgid_lines "\n" $0
  }
  next
}

# msgstr 行
/^msgstr/ {
  collecting_msgid = 0
  
  # 單行情況
  if (msgid_content != "") {
    print "msgstr " msgid_content
  }
  # 多行情況
  else if (msgid_lines != "") {
    print "msgstr \"\""
    print msgid_lines
  }
  # 空的情況
  else {
    print $0
  }
  
  msgid_content = ""
  msgid_lines = ""
  next
}

# 跳過原本的 msgstr 續行
/^"/ && !collecting_msgid { next }

# 其他行直接印出
{ print $0 }
' "$POT_FILE" >> "$ZH_HANT_PO"

# 統一路徑格式
echo -e "${BLUE}> (3/3) 統一路徑格式...${RESET}"
sed -i '' 's|^#: \([^.]\)|#: ./\1|g' "$ZH_HANT_PO"

echo -e "${BLUE}> 完成！${RESET}"
