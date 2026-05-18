import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
import '../../../lesson_kit/presentation/providers/lesson_kit_providers.dart';
import '../../domain/entities/saved_lesson.dart';
import '../providers/saved_lessons_providers.dart';

class SavedLessonsPage extends ConsumerWidget {
  const SavedLessonsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedLessonsProvider);
    final tokens = context.tokens;

    return AdaptivePageScaffold(
      title: 'Saved',
      onBack: () => context.goNamed(AppRoute.home),
      body: state.when(
        data: (lessons) {
          if (lessons.isEmpty) return const _EmptyState();
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            itemCount: lessons.length,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: tokens.oat),
            itemBuilder: (context, index) {
              final lesson = lessons[index];
              return _SavedLessonTile(
                lesson: lesson,
                onTap: () {
                  ref
                      .read(lessonKitGenerationProvider.notifier)
                      .loadFromSaved(lesson.kit);
                  context.goNamed(AppRoute.lessonKit);
                },
                onDelete: () =>
                    ref.read(savedLessonsProvider.notifier).delete(lesson.id),
              );
            },
          );
        },
        loading: () => const Center(child: AdaptiveProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Could not load saved lessons.\n$e',
              style: TextStyle(
                color: tokens.inkMuted,
                fontSize: 15,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SavedLessonTile extends StatelessWidget {
  const _SavedLessonTile({
    required this.lesson,
    required this.onTap,
    required this.onDelete,
  });

  final SavedLesson lesson;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  String _relativeTime(DateTime ts) {
    final diff = DateTime.now().difference(ts);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inDays < 1) return '${diff.inHours} hr ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${ts.day}/${ts.month}/${ts.year}';
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    return Dismissible(
      key: ValueKey(lesson.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: tokens.washRed,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        child: Icon(
          AppIcons.delete(context),
          color: tokens.washRedInk,
          size: 20,
        ),
      ),
      child: _AdaptiveLessonTileSurface(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      lesson.kit.lessonTitle,
                      style: TextStyle(
                        color: tokens.ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _relativeTime(lesson.savedAt),
                    style: TextStyle(
                      color: tokens.inkSubtle,
                      fontSize: 11,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _MiniTag(label: lesson.context.grade),
                  _MiniTag(label: lesson.context.subject),
                  _MiniTag(label: lesson.context.language.label),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                lesson.kit.simpleExplanation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: 14,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdaptiveLessonTileSurface extends StatefulWidget {
  const _AdaptiveLessonTileSurface({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_AdaptiveLessonTileSurface> createState() =>
      _AdaptiveLessonTileSurfaceState();
}

class _AdaptiveLessonTileSurfaceState
    extends State<_AdaptiveLessonTileSurface> {
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
      child: AnimatedScale(
        scale: _down ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: _down ? tokens.surfaceMuted : Colors.transparent,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: tokens.inkMuted,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w500,
          letterSpacing: 0,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                AppIcons.bookmark(context),
                color: tokens.inkMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No saved lessons',
              style: TextStyle(
                color: tokens.ink,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Save a generated kit and it will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: tokens.inkMuted,
                fontSize: 15,
                height: 1.5,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 28),
            AdaptivePrimaryButton(
              onPressed: () => context.goNamed(AppRoute.scan),
              icon: AppIcons.camera(context),
              label: 'Scan a page',
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
