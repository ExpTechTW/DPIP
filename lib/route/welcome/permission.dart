import "package:dpip/core/fcm.dart";
import "package:dpip/core/notify.dart";
import "package:dpip/core/service.dart";
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
                        context.i18n.privacy_policy,
                        style: context.theme.textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          context.i18n.privacy_commitment,
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
                                  const Icon(Icons.info_outline),
                                  const SizedBox(width: 10),
                                  Text(
                                    context.i18n.required_info_permissions,
                                    style: context.theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              PermissionItem(
                                icon: Icons.notifications,
                                text: context.i18n.notification,
                                description: context.i18n.notification_service_description,
                                color: Colors.yellow,
                                onTap: () async {
                                  final status = await requestNotificationPermission();
                                  if (status.isGranted) {
                                    fcmInit();
                                    notifyInit();
                                    initBackgroundService();
                                    setState(() => isEnabled = true);
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              PermissionItem(
                                icon: Icons.location_on,
                                text: context.i18n.settings_position,
                                description: context.i18n.location_based_service,
                                color: Colors.blue,
                              ),
                              const SizedBox(height: 16),
                              PermissionItem(
                                icon: Icons.storage,
                                text: context.i18n.image_save,
                                description: context.i18n.data_visualization_storage,
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
                child: Text(context.i18n.next_step),
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
