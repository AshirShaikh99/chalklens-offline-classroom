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
                      child: _PrimaryLessonCommand(),
                    ),
                    const SizedBox(height: 26),
                    SoftReveal(
                      delay: const Duration(milliseconds: 160),
                      child: const _ToolsList(),
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
  const _PrimaryLessonCommand();

  @override
  State<_PrimaryLessonCommand> createState() => _PrimaryLessonCommandState();
}

class _PrimaryLessonCommandState extends State<_PrimaryLessonCommand> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final content = AnimatedScale(
      scale: _down ? 0.985 : 1,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: _HomeActionRow(
          icon: AppIcons.camera(context),
          title: 'Make a lesson kit',
          detail: 'Scan or paste a textbook page.',
          pressed: _down,
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

class _HomeSectionLabel extends StatelessWidget {
  const _HomeSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Text(
      label,
      style: TextStyle(
        color: tokens.inkSubtle,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
        fontSize: 11,
      ),
    );
  }
}

class _HomeActionRow extends StatelessWidget {
  const _HomeActionRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.pressed = false,
  });

  final IconData icon;
  final String title;
  final String detail;
  final bool pressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: tokens.oat),
          top: BorderSide(color: tokens.oat),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: pressed ? tokens.surfaceRaised : tokens.surfaceMuted,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: tokens.ink),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: TextStyle(
                    color: tokens.inkMuted,
                    fontSize: 14,
                    height: 1.35,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(AppIcons.chevronRight(context), size: 18, color: tokens.ink),
        ],
      ),
    );
  }
}

class _ToolsList extends StatelessWidget {
  const _ToolsList();

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
        detail: 'Answer questions from a selected lesson.',
        onTap: () => context.goNamed(AppRoute.studentHelp),
      ),
      _ToolItem(
        icon: AppIcons.settings(context),
        label: 'Settings',
        detail: 'Model setup and appearance.',
        onTap: () => context.goNamed(AppRoute.settings),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _HomeSectionLabel('TOOLS'),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: tokens.oat)),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                Divider(height: 1, color: tokens.oat),
              ],
            ],
          ),
        ),
      ],
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
        color: Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _down ? tokens.surfaceRaised : tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(7),
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
