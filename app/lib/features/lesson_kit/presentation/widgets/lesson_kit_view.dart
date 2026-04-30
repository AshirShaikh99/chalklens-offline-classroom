import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
import '../../domain/entities/lesson_kit.dart';
import 'glossary_section.dart';
import 'lesson_section.dart';
import 'quiz_section.dart';

/// Renders a finished LessonKit as a scrollable editorial document.
class LessonKitView extends StatelessWidget {
  const LessonKitView({super.key, required this.kit});

  final LessonKit kit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 48),
      children: [
        _Hero(kit: kit),
        const SizedBox(height: 32),
        if (kit.learningObjectives.isNotEmpty) ...[
          LessonSection(
            icon: AppIcons.objective(context),
            title: 'Learning objectives',
            child: BulletList(items: kit.learningObjectives),
          ),
          const SizedBox(height: 12),
        ],
        LessonSection(
          icon: AppIcons.lesson(context),
          title: 'Simple explanation',
          child: Text(
            kit.simpleExplanation,
            style: TextStyle(
              color: tokens.ink,
              fontSize: 16,
              height: 1.6,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (kit.blackboardNotes.isNotEmpty) ...[
          LessonSection(
            icon: AppIcons.notes(context),
            title: 'Blackboard notes',
            child: BulletList(items: kit.blackboardNotes),
          ),
          const SizedBox(height: 12),
        ],
        if (kit.localExample.isNotEmpty) ...[
          LessonSection(
            icon: AppIcons.idea(context),
            title: 'Local example',
            child: CalloutBox(
              text: kit.localExample,
              accent: tokens.washYellowInk,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (kit.oralQuiz.isNotEmpty) ...[
          LessonSection(
            icon: AppIcons.quiz(context),
            title: 'Oral quiz',
            child: QuizSection(questions: kit.oralQuiz),
          ),
          const SizedBox(height: 12),
        ],
        if (kit.groupActivity.isNotEmpty) ...[
          LessonSection(
            icon: AppIcons.group(context),
            title: 'Group activity',
            child: CalloutBox(
              text: kit.groupActivity,
              accent: tokens.washBlueInk,
            ),
          ),
          const SizedBox(height: 12),
        ],
        if (kit.homework.isNotEmpty) ...[
          LessonSection(
            icon: AppIcons.homework(context),
            title: 'Homework',
            child: BulletList(items: kit.homework, numbered: true),
          ),
          const SizedBox(height: 12),
        ],
        if (kit.glossary.isNotEmpty) ...[
          LessonSection(
            icon: AppIcons.glossary(context),
            title: 'Glossary',
            child: GlossarySection(terms: kit.glossary),
          ),
          const SizedBox(height: 12),
        ],
        if (kit.easyVersion.isNotEmpty) _EasyVersionCard(text: kit.easyVersion),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.kit});

  final LessonKit kit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LESSON KIT',
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
          kit.lessonTitle,
          style: TextStyle(
            color: tokens.ink,
            fontSize: 32,
            fontWeight: FontWeight.w500,
            height: 1.04,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _MetaChip(label: kit.grade),
            _MetaChip(label: kit.subject),
            _MetaChip(label: kit.language.label),
            if (kit.confidence > 0)
              _MetaChip(
                label: '${(kit.confidence * 100).round()}% confidence',
                muted: true,
              ),
          ],
        ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.muted = false});

  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: muted ? tokens.surfaceMuted : tokens.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.oat),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: tokens.inkMuted,
          fontFamily: 'monospace',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _EasyVersionCard extends StatefulWidget {
  const _EasyVersionCard({required this.text});

  final String text;

  @override
  State<_EasyVersionCard> createState() => _EasyVersionCardState();
}

class _EasyVersionCardState extends State<_EasyVersionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.washGreen,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.oat),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: tokens.washGreenInk,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'EASIER EXPLANATION',
                      style: TextStyle(
                        color: tokens.washGreenInk,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Text(
                    _expanded ? '−' : '+',
                    style: TextStyle(
                      color: tokens.washGreenInk,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'For students who need extra support',
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: 13,
                  height: 1.4,
                  letterSpacing: 0,
                ),
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Text(
                    widget.text,
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 15,
                      height: 1.55,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 180),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
