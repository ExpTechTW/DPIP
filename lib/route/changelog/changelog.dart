import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChangelogPage extends StatelessWidget {
  const ChangelogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('更新日誌'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '最新更新',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                      ),
                      const SizedBox(height: 8),
                      const Text('我們持續改進應用程式，為您帶來更好的體驗。'),
                      const SizedBox(height: 16),
                      const Icon(Icons.new_releases, size: 48, color: Colors.amber),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Markdown(
                      data: '''
                      # 版本 2.0.0

## 新功能
- 添加了實時地震通知
- 優化了用戶界面

## 改進
- 提高了地圖加載速度
- 修復了若干已知問題

# 版本 1.9.0

## 新功能
- 新增歷史地震數據查詢
- 添加了震度等級說明

## 改進
- 優化了應用程序性能
- 更新了 UI 設計
                      ''',
                      styleSheet: MarkdownStyleSheet(
                        h1: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        h2: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        p: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
