import "package:dpip/route/welcome/welcome.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";

class WelcomeAboutPage extends StatelessWidget {
  const WelcomeAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: FilledButton(
            child: Text(context.i18n.next_step),
            onPressed: () {
              WelcomeRouteState.of(context)!.nextPage();
            },
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: context.padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset("assets/DPIP.png", width: 120, height: 120),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      context.i18n.welcome_message,
                      style: context.theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Text(
                          "Disaster Prevention Information Platform",
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.primary.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          context.i18n.disaster_info_platform,
                          style: context.theme.textTheme.titleMedium?.copyWith(
                            color: context.colors.primary.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  context.i18n.dpip_description,
                  style: context.theme.textTheme.bodyLarge,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
