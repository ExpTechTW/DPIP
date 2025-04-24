import "package:dpip/util/extension/build_context.dart";
import "package:flutter/material.dart";
import "package:material_symbols_icons/symbols.dart";

class ThemeRadioTile extends StatelessWidget {
  final ThemeMode value;
  final ThemeMode groupValue;
  final void Function()? onTap;
  final void Function(ThemeMode?)? onChanged;
  final String title;
  final ThemeData theme;

  const ThemeRadioTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.title,
    required this.theme,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 96,
              decoration: BoxDecoration(color: theme.colorScheme.surfaceContainer),
              child: Center(
                child: Icon(
                  switch (value) {
                    ThemeMode.light => Symbols.light_mode,
                    ThemeMode.dark => Symbols.dark_mode,
                    ThemeMode.system => Symbols.smartphone,
                  },
                  color: theme.colorScheme.onSurface,
                  size: 32,
                ),
              ),
            ),
            Row(
              children: [
                Radio(
                  value: value,
                  groupValue: groupValue,
                  onChanged: onChanged,
                  fillColor: WidgetStateProperty.resolveWith<Color>((Set<WidgetState> states) {
                    if (states.contains(WidgetState.selected)) {
                      return context.colors.primary;
                    }
                    return context.colors.outline;
                  }),
                ),
                Text(title),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
