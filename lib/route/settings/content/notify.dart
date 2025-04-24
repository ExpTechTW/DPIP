import "package:dpip/models/settings/notify.dart";
import "package:dpip/util/extension/build_context.dart";
import "package:dpip/widget/list/tile_group_header.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";

class SettingsNotifyView extends StatefulWidget {
  const SettingsNotifyView({super.key});

  @override
  State<SettingsNotifyView> createState() => _SettingsNotifyViewState();
}

class _SettingsNotifyViewState extends State<SettingsNotifyView> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: ListView(
        padding: EdgeInsets.only(bottom: context.padding.bottom),
        controller: context.findAncestorStateOfType<NestedScrollViewState>()?.innerController,
        children: [
          Consumer<SettingsNotificationModel>(
            child: const ListTileGroupHeader(title: '地震速報'),
            builder: (context, model, title) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  title!,
                  ListTile(
                    title: const Text('地震速報'),
                    subtitle: Text(switch (model.eew) {
                      EewNotifyType.localIntensityAbove4 => '所在地震度4以上',
                      EewNotifyType.localIntensityAbove1 => '所在地震度1以上',
                      EewNotifyType.all => '全部',
                    }),
                    onTap: () async {
                      final result = await showDialog<EewNotifyType>(
                        context: context,
                        builder: (context) {
                          return SimpleDialog(
                            title: const Text('地震速報'),
                            children: [
                              RadioListTile(
                                title: const Text('所在地震度4以上'),
                                value: EewNotifyType.localIntensityAbove4,
                                groupValue: model.eew,
                                onChanged: (value) => Navigator.pop(context, value),
                              ),
                              RadioListTile(
                                title: const Text('所在地震度1以上'),
                                value: EewNotifyType.localIntensityAbove1,
                                groupValue: model.eew,
                                onChanged: (value) => Navigator.pop(context, value),
                              ),
                              RadioListTile(
                                title: const Text('全部'),
                                value: EewNotifyType.all,
                                groupValue: model.eew,
                                onChanged: (value) => Navigator.pop(context, value),
                              ),
                            ],
                          );
                        },
                      );
                      if (result == null) return;
                      model.setEew(result);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
