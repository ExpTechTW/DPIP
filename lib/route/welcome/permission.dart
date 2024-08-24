import "package:dpip/core/notify.dart";
import "package:dpip/route/welcome/tos.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";
import "package:permission_handler/permission_handler.dart";

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  ScrollController controller = ScrollController();
  bool isEnabled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Icon(
                        Icons.security,
                        size: 80,
                        color: context.theme.primaryColor,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "隱私權聲明",
                        style: context.theme.textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          "我們一直和使用者站在一起，為使用者的隱私而不斷努力。",
                          style: context.theme.textTheme.bodyMedium,
                        ),
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.info_outline, color: context.theme.primaryColor),
                                  const SizedBox(width: 10),
                                  Text(
                                    "所需的資訊和權限列表：",
                                    style: context.theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: context.theme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              PermissionItem(
                                icon: Icons.notifications,
                                text: "通知",
                                description: "用於提供基於FCM&通知的服務",
                                color: Colors.yellow,
                                onTap: () async {
                                  final status = await requestNotificationPermission();
                                  if (status.isGranted) {
                                    setState(() => isEnabled = true);
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              const PermissionItem(
                                icon: Icons.location_on,
                                text: "位置",
                                description: "用於提供基於位置的服務",
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              const PermissionItem(
                                icon: Icons.storage,
                                text: "存儲",
                                description: "用於存儲中央氣象署或 ExpTech 提供之數據可視畫圖片",
                                color: Colors.green,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isEnabled
                    ? () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const TOSPage()),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("下一步"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PermissionItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final String description;
  final Color color;
  final VoidCallback? onTap;

  const PermissionItem({
    super.key,
    required this.icon,
    required this.text,
    required this.description,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: context.theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: context.theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
