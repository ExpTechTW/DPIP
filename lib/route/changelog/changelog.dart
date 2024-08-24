import "package:dpip/api/exptech.dart";
import "package:dpip/route/changelog/update_card.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";
import "package:flutter_markdown/flutter_markdown.dart";

class ChangelogPage extends StatelessWidget {
  const ChangelogPage({super.key});

  Future<String> _fetchChangelog() async {
    try {
      var data = await ExpTech().getChangelog();
      return data["content"] as String;
    } catch (e) {
      return "# 📛 錯誤\n- 無法載入更新日誌，請稍後再重試。";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("更新日誌"),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const UpdateCard(
                title: "更新日誌",
                description: "我們持續改進應用程式，為您帶來更好的體驗。",
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: FutureBuilder<String>(
                      future: _fetchChangelog(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(child: Text("Error: ${snapshot.error}"));
                        } else {
                          return Markdown(
                            data: snapshot.data ?? "",
                            styleSheet: MarkdownStyleSheet(
                              h1: context.theme.textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
                              h2: context.theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                              p: context.theme.textTheme.bodyMedium,
                            ),
                          );
                        }
                      },
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
