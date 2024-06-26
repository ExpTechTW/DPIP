name: "\U0001F6A7問題回報"
title: "[Bug]: "
labels: ["錯誤"]
projects: ["ExpTech 問題回報"]
description: |
  請詳細描述你遇到的問題協助我們排除問題
body:
- type: dropdown
  id: platform
  attributes:
    label: 平台
    options:
      - iOS
      - Android
    default: 0
  validations:
    required: true
