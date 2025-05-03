import 'package:dpip/app/settings/location/page.dart';
import 'package:dpip/global.dart';
import 'package:dpip/models/settings/location.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class LocationButton extends StatelessWidget {
  const LocationButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHighest.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: InkWell(
            onTap: () => context.push(SettingsLocationPage.route),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Selector<SettingsLocationModel, String?>(
                selector: (context, model) => model.code,
                builder: (context, code, child) {
                  final location = Global.location[code];

                  if (location == null) {
                    return Text(
                      context.i18n.location_Not_set,
                      style: context.textTheme.bodyLarge!.copyWith(color: context.colors.outline),
                    );
                  }

                  return Text(
                    '${location.city} ${location.town}',
                    style: context.textTheme.bodyLarge!.copyWith(color: context.colors.outline),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
