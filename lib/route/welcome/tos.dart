import "package:dpip/app/dpip.dart";
import "package:dpip/global.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

class TOSPage extends StatefulWidget {
  const TOSPage({super.key});

  @override
  State<TOSPage> createState() => _TOSPageState();
}

class _TOSPageState extends State<TOSPage> {
  late ScrollController controller;
  bool isEnabled = false;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    controller = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _checkScrollExtent();
      }
    });
  }

  void _checkScrollExtent() {
    if (controller.position.maxScrollExtent > 0) {
      controller.addListener(_scrollListener);
    } else {
      setState(() => isEnabled = true);
    }
  }

  void _scrollListener() {
    final bottom = controller.position.pixels >= controller.position.maxScrollExtent;
    if (bottom && !isEnabled) {
      setState(() => isEnabled = true);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  Global.preference.setBool("monitor", false);
                  Global.preference.setBool("welcome-1.0.0", true);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Dpip()),
                  );
                },
                child: Text(
                  context.i18n.disagree,
                  style: TextStyle(fontSize: 16, color: context.colors.onSurface),
                ),
              ),
              FilledButton(
                onPressed: isEnabled
                    ? () {
                        Global.preference.setBool("monitor", true);
                        Global.preference.setBool("welcome-1.0.0", true);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const Dpip()),
                        );
                      }
                    : null,
                child: Text(context.i18n.agree),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: controller,
          padding: const EdgeInsets.all(24),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Icon(
                    Symbols.monitor_heart,
                    size: 36,
                    color: context.colors.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.i18n.monitor,
                    style: context.theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                context.i18n.trem_service_description,
                style: context.theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.i18n.real_time_magnitude_warning,
                style: context.theme.textTheme.bodyLarge!.copyWith(
                  color: context.colors.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.i18n.trem_station_warning,
                style: context.theme.textTheme.bodyLarge!.copyWith(
                  color: context.colors.onErrorContainer,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.i18n.trem_monitor_description,
                style: context.theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.i18n.station_noise_warning,
                style: context.theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.i18n.trem_net_deployment,
                style: context.theme.textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
