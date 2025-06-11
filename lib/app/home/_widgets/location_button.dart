import 'package:dpip/app/home/_widgets/blurred_button.dart';
import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';

class LocationButton extends StatelessWidget {
  const LocationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<SettingsLocationModel, String?>(
      selector: (context, model) => model.code,
      builder: (context, code, child) {
        final location = Global.location[code];

        final content = location == null ? '尚未設定' : '${location.city} ${location.town}';

        return BlurredTextButton(
          onPressed: () => context.push(SettingsLocationPage.route),
          text: content,
          textStyle: context.theme.textTheme.bodyLarge,
          elevation: 2,
        );
      },
    );
  }
}
