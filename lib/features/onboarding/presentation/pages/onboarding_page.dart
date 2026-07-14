/// First-launch onboarding: intro → terms → permissions, shown until completed.
library;

import 'package:dpip/app/theme/app_motion.dart';
import 'package:dpip/core/settings/onboarding_store.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_intro.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_permissions.dart';
import 'package:dpip/features/onboarding/presentation/widgets/onboarding_terms.dart';
import 'package:dpip/shared/navigation/app_routes.dart';
import 'package:dpip/shared/widgets/language_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

/// Hosts the three onboarding steps in a swipe-locked pager (navigation is via
/// each step's action), with progress dots and a back affordance. Finishing
/// marks onboarding complete, and the router redirect then lets Home through.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const int _pageCount = 3;

  final PageController _controller = PageController();
  int _index = 0;

  void _go(int page) {
    _controller.animateToPage(
      page,
      duration: AppMotion.medium,
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  Future<void> _finish() async {
    await context.read<OnboardingStore>().complete();
    if (mounted) context.goNamed(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Can't skip onboarding; a system back steps to the previous page instead.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index > 0) _go(_index - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              _TopBar(
                index: _index,
                pageCount: _pageCount,
                onBack: _index > 0 ? () => _go(_index - 1) : null,
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    OnboardingIntroPage(onNext: () => _go(1)),
                    OnboardingTermsPage(onAccept: () => _go(2)),
                    OnboardingPermissionsPage(onFinish: _finish),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A back button (when not on the first step) beside centred progress dots.
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.index,
    required this.pageCount,
    required this.onBack,
  });

  final int index;
  final int pageCount;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: onBack == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: onBack,
                  ),
          ),
          Expanded(
            child: Center(
              child: _Dots(count: pageCount, index: index),
            ),
          ),
          // Language selector in the top-right.
          const LanguagePicker(),
        ],
      ),
    );
  }
}

/// Progress dots; the active step is a wider primary pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppMotion.medium,
            curve: Curves.easeInOutCubicEmphasized,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == index
                  ? colors.primary
                  : colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
