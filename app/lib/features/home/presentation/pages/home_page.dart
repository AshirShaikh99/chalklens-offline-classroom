import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
import '../../../../core/widgets/brand_mark.dart';
import '../../../../core/widgets/on_device_badge.dart';
import '../../../../core/widgets/soft_reveal.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AdaptivePageScaffold(
      title: '',
      actions: const [OnDeviceBadge()],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 720;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 40 : 20,
              useCupertino(context) ? 24 : 14,
              isWide ? 40 : 20,
              44,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 940),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SoftReveal(child: _Greeting()),
                    const SizedBox(height: 32),
                    SoftReveal(
                      delay: const Duration(milliseconds: 80),
                      child: _PrimaryLessonCommand(isWide: isWide),
                    ),
                    const SizedBox(height: 14),
                    SoftReveal(
                      delay: const Duration(milliseconds: 160),
                      child: _ToolsList(isWide: isWide),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(size: 30, subtitle: 'Offline classroom helper'),
        const SizedBox(height: 28),
        Text(
          'CLASSROOM DESK',
          style: TextStyle(
            color: tokens.inkSubtle,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Start with\nthe page.',
          style: TextStyle(
            color: tokens.ink,
            fontSize: 44,
            fontWeight: FontWeight.w500,
            height: 1.00,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'Add a textbook page or paste the words. ChalkLens turns it '
            'into a lesson, practice, homework, and simpler explanations.',
            style: TextStyle(
              color: tokens.inkMuted,
              fontSize: 15,
              height: 1.5,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryLessonCommand extends StatefulWidget {
  const _PrimaryLessonCommand({required this.isWide});

  final bool isWide;

  @override
  State<_PrimaryLessonCommand> createState() => _PrimaryLessonCommandState();
}

class _PrimaryLessonCommandState extends State<_PrimaryLessonCommand> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final stepText = widget.isWide
        ? const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepMark(number: '1', label: 'Source'),
              SizedBox(width: 12),
              _StepMark(number: '2', label: 'Class'),
              SizedBox(width: 12),
              _StepMark(number: '3', label: 'Kit'),
            ],
          )
        : const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StepMark(number: '1', label: 'Source'),
              _StepMark(number: '2', label: 'Class'),
              _StepMark(number: '3', label: 'Kit'),
            ],
          );

    final content = AnimatedScale(
      scale: _down ? 0.992 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: _down ? tokens.surfaceRaised : tokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: tokens.oat),
        ),
        padding: EdgeInsets.all(widget.isWide ? 32 : 22),
        child: widget.isWide
            ? Row(
                children: [
                  Expanded(child: _CommandCopy(stepText: stepText)),
                  const SizedBox(width: 32),
                  _CommandAction(tokens: tokens),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CommandCopy(stepText: stepText),
                  const SizedBox(height: 24),
                  _CommandAction(tokens: tokens),
                ],
              ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: () => context.goNamed(AppRoute.scan),
      child: content,
    );
  }
}

class _CommandCopy extends StatelessWidget {
  const _CommandCopy({required this.stepText});

  final Widget stepText;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIMARY TASK',
          style: TextStyle(
            color: tokens.inkSubtle,
            fontFamily: 'monospace',
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Make a lesson kit',
          style: TextStyle(
            color: tokens.ink,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.04,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Scan a page, tune the class context, and generate a ready teaching '
          'document on this device.',
          style: TextStyle(
            color: tokens.inkMuted,
            fontSize: 15,
            height: 1.5,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 22),
        stepText,
      ],
    );
  }
}

class _CommandAction extends StatelessWidget {
  const _CommandAction({required this.tokens});

  final AppTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color: tokens.ink,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.camera(context), size: 18, color: tokens.canvas),
          const SizedBox(width: 9),
          Text(
            'Create lesson',
            style: TextStyle(
              color: tokens.canvas,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepMark extends StatelessWidget {
  const _StepMark({required this.number, required this.label});

  final String number;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: tokens.surfaceMuted,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: tokens.oat),
          ),
          child: Text(
            number,
            style: TextStyle(
              color: tokens.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              height: 1,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: tokens.inkMuted,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ToolsList extends StatelessWidget {
  const _ToolsList({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final rows = [
      _ToolItem(
        icon: AppIcons.bookmark(context),
        label: 'Saved lessons',
        detail: 'Open kits kept for later teaching.',
        onTap: () => context.goNamed(AppRoute.savedLessons),
      ),
      _ToolItem(
        icon: AppIcons.help(context),
        label: 'Student help',
        detail: 'Answer simple questions from the current lesson.',
        onTap: () => context.goNamed(AppRoute.studentHelp),
      ),
      _ToolItem(
        icon: AppIcons.settings(context),
        label: 'Settings',
        detail: 'Output, model behavior, and appearance.',
        onTap: () => context.goNamed(AppRoute.settings),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.oat),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(isWide ? 22 : 18, 16, 18, 10),
            child: Row(
              children: [
                Text(
                  'TOOLS',
                  style: TextStyle(
                    color: tokens.inkSubtle,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  'Offline first',
                  style: TextStyle(
                    color: tokens.inkMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) Divider(height: 1, color: tokens.oat),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _ToolItem extends StatefulWidget {
  const _ToolItem({
    required this.icon,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  State<_ToolItem> createState() => _ToolItemState();
}

class _ToolItemState extends State<_ToolItem> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        color: _down ? tokens.surfaceMuted : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: tokens.oat),
              ),
              child: Icon(widget.icon, size: 18, color: tokens.ink),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.detail,
                    style: TextStyle(
                      color: tokens.inkMuted,
                      fontSize: 13,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              AppIcons.chevronRight(context),
              size: 17,
              color: tokens.inkSubtle,
            ),
          ],
        ),
      ),
    );
  }
}
