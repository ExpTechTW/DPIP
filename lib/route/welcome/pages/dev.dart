import "package:dpip/global.dart";
import "package:dpip/route/welcome/welcome.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

class WelcomeDevPage extends StatefulWidget {
  const WelcomeDevPage({super.key});

  @override
  State<WelcomeDevPage> createState() => _WelcomeDevPageState();
}

class _WelcomeDevPageState extends State<WelcomeDevPage> {
  final ScrollController controller = ScrollController();
  bool _isEnabled = false;
  double progress = 0;

  @override
  void initState() {
    super.initState();
    controller.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback(_checkInitialScroll);
  }

  void _checkInitialScroll(_) {
    if (controller.position.maxScrollExtent == 0) {
      setState(() => _isEnabled = true);
    }
  }

  void _scrollListener() {
    if (!_isEnabled && controller.offset >= controller.position.maxScrollExtent) {
      setState(() => _isEnabled = true);
    }
  }

  @override
  void dispose() {
    controller.removeListener(_scrollListener);
    controller.dispose();
    super.dispose();
  }

  void complete(bool status) {
    Global.preference.setBool("dev", status);
    final state = WelcomeRouteState.of(context);
    if (state != null) {
      state.complete();
    } else {
      Navigator.pop(context);
    }
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
                onPressed: () => complete(false),
                child: Text(
                  context.i18n.disagree,
                  style: TextStyle(fontSize: 16, color: context.colors.onSurface),
                ),
              ),
              FilledButton(
                onPressed: _isEnabled ? () => complete(true) : null,
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
                    context.i18n.dev,
                    style: context.theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                context.i18n.dev_service_description,
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
                context.i18n.dev_warning,
                style: context.theme.textTheme.bodyLarge!.copyWith(
                  color: context.colors.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
