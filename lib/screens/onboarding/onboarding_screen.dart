import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/app_database.dart';
import '../../theme/app_motion.dart';
import '../../widgets/motion.dart';
import 'onboarding_illustrations.dart';

const _onboardingMetaKey = 'onboardingSeen';

final onboardingSeenProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(databaseProvider);
  return await db.getMeta(_onboardingMetaKey) == '1';
});

Future<void> markOnboardingSeen(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  await db.setMeta(_onboardingMetaKey, '1');
  ref.invalidate(onboardingSeenProvider);
}

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _finishing = false;

  static const _pages = [
    (
      title: 'Perfectly Organize\nYour Family Life',
      body:
          'Manage events, chores, groceries, and daily plans in one simple shared place.',
      cta: 'Next',
    ),
    (
      title: 'AI That Organizes\nFor Your Family',
      body:
          'AI suggests schedules, assigns chores, reminds tasks, and plans family activities.',
      cta: 'Next',
    ),
    (
      title: 'Stay Connected\nTogether',
      body:
          'Share plans, assign tasks, and keep your whole family perfectly in sync.',
      cta: 'Get Started',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    await markOnboardingSeen(ref);
  }

  void _next() {
    if (_index >= _pages.length - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
    );
  }

  void _back() {
    if (_index == 0) return;
    _controller.previousPage(
      duration: AppMotion.medium,
      curve: AppMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_index];

    return Scaffold(
      backgroundColor: OnboardColors.cream,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF8F2),
              OnboardColors.cream,
              Color(0xFFF7EFE6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 44,
                      child: _index > 0
                          ? IconButton(
                              onPressed: _back,
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: OnboardColors.cocoa,
                              ),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 0; i < _pages.length; i++) ...[
                            Expanded(
                              child: AnimatedContainer(
                                duration: AppMotion.fast,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: i <= _index
                                      ? OnboardColors.cocoa
                                      : OnboardColors.cocoaMuted
                                          .withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                            if (i != _pages.length - 1) const SizedBox(width: 6),
                          ],
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _finishing ? null : _finish,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: OnboardColors.inkSoft,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _index = i),
                  children: [
                    OnboardFadeSlide(
                      pageKey: 0,
                      child: const Center(child: OnboardHeroOrganize()),
                    ),
                    OnboardFadeSlide(
                      pageKey: 1,
                      child: const Center(child: OnboardHeroAi()),
                    ),
                    OnboardFadeSlide(
                      pageKey: 2,
                      child: const Center(child: OnboardHeroConnect()),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
                child: OnboardFadeSlide(
                  pageKey: 'copy-$_index',
                  child: Column(
                    children: [
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 28,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: OnboardColors.cocoa,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        page.body,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15.5,
                          height: 1.45,
                          fontWeight: FontWeight.w500,
                          color: OnboardColors.inkSoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Pressable(
                  onTap: _finishing ? null : _next,
                  child: AnimatedContainer(
                    duration: AppMotion.fast,
                    width: double.infinity,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: OnboardColors.cocoa,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: OnboardColors.cocoa.withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: _finishing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                page.cta,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
