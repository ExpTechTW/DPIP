import "package:dpip/route/settings/settings.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

Future<void> showLocationDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return AlertDialog(
        icon: const Icon(Symbols.error),
        title: const Text("尚未設定所在地"),
        content: const Text(
          "DPIP 需要設定所在地才能正常運作。點擊「前往設定」設定所在地後再試一次。",
        ),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            child: const Text("前往設定"),
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: "/settings"),
                  builder: (context) => const SettingsRoute(
                    initialRoute: "/location",
                  ),
                ),
              );
            },
          ),
        ],
      );
    },
  );
}
