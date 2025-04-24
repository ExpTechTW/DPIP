import "package:dpip/route/settings/settings.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";

class RegionOutOfService extends StatelessWidget {
  const RegionOutOfService({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(context.i18n.out_of_service_only_taiwan, style: context.theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          FilledButton(
            child: Text(context.i18n.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: "/settings"),
                  builder: (context) => const SettingsRoute(initialRoute: "/location"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
