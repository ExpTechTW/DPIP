import 'dart:async';

import 'package:flutter/material.dart';

import 'package:m3e_collection/m3e_collection.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';
import 'package:option_result/result.dart';

import 'package:dpip/api/exptech.dart';
import 'package:dpip/api/model/changelog/changelog.dart';
import 'package:dpip/core/i18n.dart';
import 'package:dpip/global.dart';
import 'package:dpip/utils/extensions/build_context.dart';
import 'package:dpip/utils/extensions/datetime.dart';
import 'package:dpip/utils/extensions/string.dart';
import 'package:dpip/widgets/markdown.dart';
import 'package:dpip/widgets/typography.dart';
import 'package:dpip/widgets/ui/icon_container.dart';

class ChangelogPage extends StatefulWidget {
  const ChangelogPage({super.key});

  @override
  State<ChangelogPage> createState() => _ChangelogPageState();
}

class _ChangelogPageState extends State<ChangelogPage> {
  final _refreshIndicatorKey = GlobalKey<ExpressiveRefreshIndicatorState>();
  Result<List<GithubRelease>, String>? releases;

  Future<void> _refresh() async {
    if (_refreshIndicatorKey.currentState case final state?) {
      state.show();
    }

    final result = await ExpTech().getReleases();
    setState(() => releases = result);
  }

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ExpressiveRefreshIndicator.contained(
        key: _refreshIndicatorKey,
        backgroundColor: context.colors.primaryContainer,
        onRefresh: _refresh,
        edgeOffset: context.padding.top + 64,
        child: CustomScrollView(
          slivers: [
            SliverAppBarM3E(
              variant: .small,
              title: Text('更新日誌'),
              pinned: true,
            ),
            switch (releases) {
              null => SliverFillRemaining(
                child: Center(
                  child: ExpressiveLoadingIndicator(),
                ),
              ),
              Err(:final value) => SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: .min,
                    spacing: 8,
                    children: [
                      ContainedIcon(
                        Symbols.error_rounded,
                        color: context.colors.error,
                        size: 32,
                        margin: .only(bottom: 8),
                      ),
                      TitleText.large(
                        '發生錯誤'.i18n,
                        weight: .bold,
                        align: .center,
                      ),
                      BodyText.large(
                        value,
                        color: context.colors.onSurfaceVariant,
                        align: .center,
                      ),
                      FilledButton.tonalIcon(
                        onPressed: _refresh,
                        icon: Icon(Symbols.refresh_rounded),
                        label: Text('再試一次'.i18n),
                      ),
                    ],
                  ),
                ),
              ),
              Ok(:final value) => SliverMainAxisGroup(
                slivers: [
                  for (final (index, release) in value.indexed)
                    SliverMainAxisGroup(
                      slivers: [
                        SliverPersistentHeader(
                          delegate: _ReleaseHeaderDelegate(release),
                          pinned: true,
                        ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const .symmetric(horizontal: 24),
                            child: Markdown(release.body),
                          ),
                        ),
                        if (index != value.length - 1)
                          SliverToBoxAdapter(
                            child: Center(
                              child: Icon(
                                Symbols.more_horiz_rounded,
                                size: 48,
                                weight: 700,
                                color: context.colors.outlineVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            },
            SliverPadding(padding: .only(bottom: context.padding.bottom)),
          ],
        ),
      ),
    );
  }
}

class _ReleaseHeaderDelegate extends SliverPersistentHeaderDelegate {
  final GithubRelease release;

  const _ReleaseHeaderDelegate(this.release);

  static const height = kToolbarHeight + 32;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          stops: [.5, 1],
          colors: [
            context.colors.surface,
            context.colors.surface.withValues(alpha: 0),
          ],
          begin: .topCenter,
          end: .bottomCenter,
        ),
      ),
      padding: .symmetric(horizontal: 24, vertical: 8),
      child: Row(
        spacing: 16,
        children: [
          ContainedIcon(
            switch (release.prerelease) {
              true => Symbols.experiment_rounded,
              false => Symbols.package_2_rounded,
            },
            color: switch (release.prerelease) {
              true => Colors.orangeAccent,
              false => Colors.greenAccent,
            },
            size: 28,
          ),
          Expanded(
            child: Column(
              mainAxisSize: .min,
              crossAxisAlignment: .start,
              children: [
                TitleText.large(release.name, weight: .bold),
                BodyText.medium(
                  DateTime.parse(
                    release.publishedAt,
                  ).toLocaleFullDateString(context),
                  color: context.colors.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if ('v${Global.packageInfo.version}' == release.name)
            Container(
              padding: .symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: .circular(8),
                border: .all(color: context.colors.primary),
                color: context.colors.primaryContainer,
              ),
              child: LabelText.large('目前版本'.i18n),
            ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ReleaseHeaderDelegate oldDelegate) => true;
}
