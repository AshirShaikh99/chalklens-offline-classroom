import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
import '../../../../core/widgets/soft_reveal.dart';
import '../../../saved_lessons/domain/entities/saved_lesson.dart';
import '../../../saved_lessons/presentation/providers/saved_lessons_providers.dart';
import '../../domain/entities/lesson_context.dart';
import '../../domain/entities/lesson_generation_progress.dart';
import '../../domain/entities/lesson_kit.dart';
import '../../domain/entities/student_level.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/lesson_kit_providers.dart';
import '../widgets/lesson_kit_view.dart';

class LessonKitPage extends ConsumerWidget {
  const LessonKitPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(lessonKitGenerationProvider);

    return AdaptivePageScaffold(
      title: 'Lesson kit',
      onBack: () => context.goNamed(AppRoute.home),
      actions: [
        AdaptiveTextAction(
          label: 'Save',
          onPressed: state.maybeWhen(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            data: (kit) => kit == null
                ? null
                : () async {
                    final lesson = SavedLesson(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      kit: kit,
                      context: LessonContext(
                        grade: kit.grade,
                        subject: kit.subject,
                        language: kit.language,
                        studentLevel: StudentLevel.standard,
                      ),
                      savedAt: DateTime.now(),
                    );
                    await ref.read(savedLessonsProvider.notifier).save(lesson);
                    if (!context.mounted) return;
                    await showAdaptiveMessage(context, 'Saved.');
                  },
            orElse: () => null,
          ),
        ),
        AdaptiveTextAction(
          label: 'Copy',
          onPressed: state.maybeWhen(
            skipLoadingOnRefresh: false,
            skipLoadingOnReload: false,
            data: (kit) => kit == null
                ? null
                : () async {
                    await Clipboard.setData(
                      ClipboardData(text: _lessonKitAsText(kit)),
                    );
                    if (!context.mounted) return;
                    await showAdaptiveMessage(
                      context,
                      'Lesson copied to clipboard.',
                    );
                  },
            orElse: () => null,
          ),
        ),
      ],
      body: state.when(
        skipLoadingOnRefresh: false,
        skipLoadingOnReload: false,
        data: (kit) {
          if (kit == null) return const _EmptyState();
          return LessonKitView(kit: kit);
        },
        loading: () => const _LoadingState(),
        error: (error, stack) => _ErrorState(error: error.toString()),
      ),
    );
  }
}

String _lessonKitAsText(LessonKit kit) {
  final buffer = StringBuffer()
    ..writeln(kit.lessonTitle)
    ..writeln('${kit.grade} · ${kit.subject} · ${kit.language.label}')
    ..writeln()
    ..writeln('Simple explanation')
    ..writeln(kit.simpleExplanation)
    ..writeln();

  if (kit.blackboardNotes.isNotEmpty) {
    buffer
      ..writeln('Blackboard notes')
      ..writeln(kit.blackboardNotes.map((note) => '- $note').join('\n'))
      ..writeln();
  }
  if (kit.localExample.isNotEmpty) {
    buffer
      ..writeln('Local example')
      ..writeln(kit.localExample)
      ..writeln();
  }
  if (kit.oralQuiz.isNotEmpty) {
    buffer
      ..writeln('Oral quiz')
      ..writeln(kit.oralQuiz.map((q) => '- ${q.question}').join('\n'))
      ..writeln();
  }
  if (kit.homework.isNotEmpty) {
    buffer
      ..writeln('Homework')
      ..writeln(kit.homework.map((item) => '- $item').join('\n'))
      ..writeln();
  }
  if (kit.easyVersion.isNotEmpty) {
    buffer
      ..writeln('Easier explanation')
      ..writeln(kit.easyVersion);
  }

  return buffer.toString().trim();
}

class _LoadingState extends ConsumerWidget {
  const _LoadingState();

  static const _steps = [
    _GenerationStep(title: 'Read page'),
    _GenerationStep(title: 'Start model'),
    _GenerationStep(title: 'Write lesson'),
    _GenerationStep(title: 'Make practice'),
    _GenerationStep(title: 'Review'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.tokens;
    final progress = ref.watch(lessonGenerationProgressProvider);
    final thinkingMode = ref.watch(
      settingsProvider.select(
        (settings) => settings.modelSettings.thinkingMode,
      ),
    );
    final active = _GenerationStatusCopy.from(progress.phase);
    final activeStep = _stepIndexFor(progress.phase);

    return LayoutBuilder(
      builder: (context, constraints) {
        return ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            constraints.maxHeight > 620 ? 48 : 24,
            20,
            32,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 660),
                child: SoftReveal(
                  child: Container(
                    decoration: BoxDecoration(
                      color: tokens.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: tokens.oat),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _LiveGenerationPulse(progress: progress),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'LIVE GENERATION',
                                    style: TextStyle(
                                      color: tokens.inkSubtle,
                                      fontFamily: 'monospace',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Generating lesson kit',
                                    style: TextStyle(
                                      color: tokens.ink,
                                      fontSize: 27,
                                      fontWeight: FontWeight.w600,
                                      height: 1.06,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    thinkingMode
                                        ? 'Gemma is reasoning locally on this device.'
                                        : 'Gemma is working locally on this device.',
                                    style: TextStyle(
                                      color: tokens.inkMuted,
                                      fontSize: 14,
                                      height: 1.4,
                                      letterSpacing: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 26),
                        _ReasoningRunPanel(
                          enabled: thinkingMode,
                          progress: progress,
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 260),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          child: Column(
                            key: ValueKey(active.title),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active.title,
                                style: TextStyle(
                                  color: tokens.ink,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  height: 1.18,
                                  letterSpacing: 0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                active.detail,
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
                        const SizedBox(height: 24),
                        _LiveTokenMeter(progress: progress),
                        const SizedBox(height: 18),
                        _GenerationProgressBar(value: progress.progress),
                        const SizedBox(height: 22),
                        for (var i = 0; i < _steps.length; i++) ...[
                          _GenerationStepRow(
                            step: _steps[i],
                            index: i,
                            activeIndex: activeStep,
                          ),
                          if (i < _steps.length - 1) const SizedBox(height: 10),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  int _stepIndexFor(LessonGenerationPhase phase) {
    return switch (phase) {
      LessonGenerationPhase.idle || LessonGenerationPhase.readingSource => 0,
      LessonGenerationPhase.startingModel => 1,
      LessonGenerationPhase.namingLesson ||
      LessonGenerationPhase.writingObjectives ||
      LessonGenerationPhase.draftingExplanation ||
      LessonGenerationPhase.preparingBoardNotes => 2,
      LessonGenerationPhase.makingActivities ||
      LessonGenerationPhase.makingQuestions ||
      LessonGenerationPhase.addingHomework ||
      LessonGenerationPhase.buildingGlossary => 3,
      LessonGenerationPhase.checkingKit || LessonGenerationPhase.complete => 4,
    };
  }
}

class _ReasoningRunPanel extends StatelessWidget {
  const _ReasoningRunPanel({required this.enabled, required this.progress});

  final bool enabled;
  final LessonGenerationProgress progress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = enabled
        ? progress.reasoningPreview.isEmpty
              ? 'Planning the classroom structure before writing the final kit.'
              : progress.reasoningPreview
        : 'Fast direct generation for this run.';
    final countLabel = progress.reasoningCharacters == 1
        ? '1 reasoning character'
        : '${progress.reasoningCharacters} reasoning characters';

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.oat),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: tokens.oat),
            ),
            child: enabled && !progress.hasReasoning
                ? const CupertinoActivityIndicator(radius: 8)
                : Icon(
                    AppIcons.idea(context),
                    color: enabled ? tokens.ink : tokens.inkMuted,
                    size: 17,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      enabled ? 'REASONING ON' : 'REASONING OFF',
                      style: TextStyle(
                        color: tokens.inkSubtle,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    if (enabled && progress.hasReasoning) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          countLabel,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: tokens.inkMuted,
                            fontSize: 12,
                            height: 1.2,
                            letterSpacing: 0,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: tokens.ink,
                    fontSize: 13,
                    height: 1.45,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveGenerationPulse extends StatefulWidget {
  const _LiveGenerationPulse({required this.progress});

  final LessonGenerationProgress progress;

  @override
  State<_LiveGenerationPulse> createState() => _LiveGenerationPulseState();
}

class _LiveGenerationPulseState extends State<_LiveGenerationPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final complete = widget.progress.phase == LessonGenerationPhase.complete;

    return SizedBox(
      width: 50,
      height: 50,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final pulse = complete ? 0.0 : _controller.value;
          return Stack(
            alignment: Alignment.center,
            children: [
              Transform.scale(
                scale: 0.88 + pulse * 0.28,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: tokens.ink.withValues(
                        alpha: complete ? 0.08 : 0.16 * (1 - pulse),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.oat),
                ),
                child: Center(
                  child: complete
                      ? Icon(
                          useCupertino(context)
                              ? CupertinoIcons.checkmark
                              : Icons.check,
                          size: 21,
                          color: tokens.ink,
                        )
                      : const CupertinoActivityIndicator(radius: 10),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LiveTokenMeter extends StatelessWidget {
  const _LiveTokenMeter({required this.progress});

  final LessonGenerationProgress progress;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tokenLabel = progress.generatedTokens == 1 ? 'token' : 'tokens';
    final detail = progress.hasGeneratedText
        ? '${progress.generatedCharacters} characters drafted'
        : 'Waiting for the first token';

    return Container(
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.oat),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LIVE OUTPUT',
                  style: TextStyle(
                    color: tokens.inkSubtle,
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: 0,
                    end: progress.generatedTokens.toDouble(),
                  ),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      '${value.round()} $tokenLabel',
                      style: TextStyle(
                        color: tokens.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                        letterSpacing: 0,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              detail,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: tokens.inkMuted,
                fontSize: 13,
                height: 1.35,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenerationProgressBar extends StatelessWidget {
  const _GenerationProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: value.clamp(0.04, 1).toDouble()),
        duration: const Duration(milliseconds: 360),
        curve: Curves.easeOutCubic,
        builder: (context, animatedValue, _) {
          return LinearProgressIndicator(
            value: animatedValue,
            minHeight: 5,
            color: tokens.ink,
            backgroundColor: tokens.surfaceMuted,
          );
        },
      ),
    );
  }
}

class _GenerationStepRow extends StatelessWidget {
  const _GenerationStepRow({
    required this.step,
    required this.index,
    required this.activeIndex,
  });

  final _GenerationStep step;
  final int index;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final completed = index < activeIndex;
    final active = index == activeIndex;
    final ink = completed || active ? tokens.ink : tokens.inkSubtle;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: completed ? tokens.ink : tokens.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: active || completed ? tokens.ink : tokens.oat,
            ),
          ),
          alignment: Alignment.center,
          child: completed
              ? Icon(
                  useCupertino(context)
                      ? CupertinoIcons.checkmark
                      : Icons.check,
                  color: tokens.canvas,
                  size: 15,
                )
              : active
              ? Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: tokens.ink,
                    shape: BoxShape.circle,
                  ),
                )
              : Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: tokens.oat,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: ink,
              fontSize: 14,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              height: 1.35,
              letterSpacing: 0,
            ),
            child: Text(step.title),
          ),
        ),
      ],
    );
  }
}

class _GenerationStep {
  const _GenerationStep({required this.title});

  final String title;
}

class _GenerationStatusCopy {
  const _GenerationStatusCopy({required this.title, required this.detail});

  final String title;
  final String detail;

  factory _GenerationStatusCopy.from(LessonGenerationPhase phase) {
    return switch (phase) {
      LessonGenerationPhase.idle ||
      LessonGenerationPhase.readingSource => const _GenerationStatusCopy(
        title: 'Reading your page',
        detail: 'Finding the topic, headings, and important words.',
      ),
      LessonGenerationPhase.startingModel => const _GenerationStatusCopy(
        title: 'Starting Gemma on this device',
        detail: 'Loading the offline model and preparing the classroom prompt.',
      ),
      LessonGenerationPhase.namingLesson => const _GenerationStatusCopy(
        title: 'Naming the lesson',
        detail: 'Creating the lesson title and matching it to the class.',
      ),
      LessonGenerationPhase.writingObjectives => const _GenerationStatusCopy(
        title: 'Writing learning objectives',
        detail: 'Turning the page into clear goals for the class.',
      ),
      LessonGenerationPhase.draftingExplanation => const _GenerationStatusCopy(
        title: 'Drafting the explanation',
        detail: 'Making the main idea simple enough to teach right away.',
      ),
      LessonGenerationPhase.preparingBoardNotes => const _GenerationStatusCopy(
        title: 'Preparing board notes',
        detail: 'Condensing the lesson into short blackboard points.',
      ),
      LessonGenerationPhase.makingActivities => const _GenerationStatusCopy(
        title: 'Making classroom activities',
        detail: 'Adding a local example and group work for the room.',
      ),
      LessonGenerationPhase.makingQuestions => const _GenerationStatusCopy(
        title: 'Making oral questions',
        detail: 'Preparing quick checks for student understanding.',
      ),
      LessonGenerationPhase.addingHomework => const _GenerationStatusCopy(
        title: 'Adding homework',
        detail: 'Writing small follow-up tasks for after class.',
      ),
      LessonGenerationPhase.buildingGlossary => const _GenerationStatusCopy(
        title: 'Building the glossary',
        detail: 'Explaining useful words in simple classroom language.',
      ),
      LessonGenerationPhase.checkingKit => const _GenerationStatusCopy(
        title: 'Checking the final kit',
        detail: 'Validating the structured lesson before it appears.',
      ),
      LessonGenerationPhase.complete => const _GenerationStatusCopy(
        title: 'Lesson kit ready',
        detail: 'Opening the generated lesson now.',
      ),
    };
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
                AppIcons.lesson(context),
                color: tokens.inkMuted,
                size: 24,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No lesson kit yet',
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
              'Scan a textbook page to make your first kit.',
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

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                color: tokens.washRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                AppIcons.error(context),
                color: tokens.washRedInk,
                size: 24,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Could not generate',
              style: TextStyle(
                color: tokens.ink,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                height: 1.08,
              ),
            ),
            const SizedBox(height: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: 13,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 28),
            AdaptiveSecondaryButton(
              onPressed: () => context.goNamed(AppRoute.scan),
              label: 'Try again',
              fullWidth: false,
            ),
          ],
        ),
      ),
    );
  }
}
