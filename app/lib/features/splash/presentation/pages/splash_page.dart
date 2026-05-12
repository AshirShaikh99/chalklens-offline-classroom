import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../model_setup/presentation/providers/model_setup_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  static const _minimumSplashTime = Duration(milliseconds: 1450);

  Timer? _timer;
  bool _minimumElapsed = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_minimumSplashTime, () {
      if (!mounted) return;
      setState(() => _minimumElapsed = true);
      _maybeNavigate(ref.read(modelSetupProvider));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _maybeNavigate(AsyncValue<ModelSetupState> setup) {
    if (!_minimumElapsed || _navigated) return;

    final route = setup.whenOrNull(
      data: (state) => state.canContinue ? '/' : '/model-setup',
      error: (_, _) => '/model-setup',
    );
    if (route == null) return;

    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.go(route);
    });
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(modelSetupProvider);
    // Try navigation after the current build commits. Idempotent via
    // _navigated. We use post-frame from build (rather than ref.listen +
    // ref.watch in parallel) so a single state observation drives navigation.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _maybeNavigate(setup);
    });

    final tokens = context.tokens;
    final status = _statusFor(setup);

    return Scaffold(
      backgroundColor: tokens.canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 360),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 16 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const BrandMark(size: 70, showName: false),
                          const SizedBox(height: 24),
                          Text(
                            'ChalkLens',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: tokens.ink,
                              fontSize: 38,
                              fontWeight: FontWeight.w800,
                              height: 1.02,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Clear lessons for every classroom.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: tokens.inkMuted,
                              fontSize: 16,
                              height: 1.45,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 34),
                          _SplashStatus(status: status),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                status.footer,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.inkSubtle,
                  fontSize: 12,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _SplashStatusData _statusFor(AsyncValue<ModelSetupState> setup) {
    return setup.when(
      data: (state) => state.canContinue
          ? const _SplashStatusData(
              label: 'Ready to teach',
              detail: 'Offline AI is ready.',
              footer: 'Works on this device.',
              progress: 1,
            )
          : const _SplashStatusData(
              label: 'A quick setup is needed',
              detail: 'We will get the offline AI ready next.',
              footer: 'Needed after a fresh install.',
              progress: 0.72,
            ),
      loading: () => const _SplashStatusData(
        label: 'Checking offline AI',
        detail: 'Making sure the lesson helper is ready.',
        footer: 'No classroom data leaves this device.',
        progress: 0.48,
      ),
      error: (_, _) => const _SplashStatusData(
        label: 'A quick setup is needed',
        detail: 'We will fix the offline AI setup next.',
        footer: 'Needed after a fresh install.',
        progress: 0.72,
      ),
    );
  }
}

class _SplashStatus extends StatelessWidget {
  const _SplashStatus({required this.status});

  final _SplashStatusData status;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.oat),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tokens.ink,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Text(
                    status.label,
                    key: ValueKey(status.label),
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                status.detail,
                key: ValueKey(status.detail),
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: 13,
                  height: 1.35,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: status.progress),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 5,
                  color: tokens.ink,
                  backgroundColor: tokens.surfaceMuted,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashStatusData {
  const _SplashStatusData({
    required this.label,
    required this.detail,
    required this.footer,
    required this.progress,
  });

  final String label;
  final String detail;
  final String footer;
  final double progress;
}
