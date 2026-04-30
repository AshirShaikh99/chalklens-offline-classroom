import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/quiz_question.dart';

/// Numbered list of oral quiz questions. Each row exposes a "Show expected
/// answer" expansion so the teacher can peek without reading the answer
/// aloud first.
class QuizSection extends StatelessWidget {
  const QuizSection({super.key, required this.questions});

  final List<QuizQuestion> questions;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (questions.isEmpty) {
      return Text(
        'No quiz questions.',
        style: TextStyle(
          color: tokens.inkSubtle,
          fontSize: 13,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < questions.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: tokens.oat),
            ),
          _QuizRow(index: i + 1, question: questions[i]),
        ],
      ],
    );
  }
}

class _QuizRow extends StatefulWidget {
  const _QuizRow({required this.index, required this.question});

  final int index;
  final QuizQuestion question;

  @override
  State<_QuizRow> createState() => _QuizRowState();
}

class _QuizRowState extends State<_QuizRow> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasAnswer =
        widget.question.expectedAnswer != null &&
        widget.question.expectedAnswer!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 22,
              child: Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Text(
                  '${widget.index}.',
                  style: TextStyle(
                    color: tokens.inkSubtle,
                    fontSize: 15,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                widget.question.question,
                style: TextStyle(
                  color: tokens.ink,
                  fontSize: 15,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        if (hasAnswer)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _expanded = !_expanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? '−' : '+',
                        style: TextStyle(
                          color: tokens.inkMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _expanded
                            ? 'Hide expected answer'
                            : 'Show expected answer',
                        style: TextStyle(
                          color: tokens.inkMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_expanded && hasAnswer)
          Padding(
            padding: const EdgeInsets.only(left: 22, top: 8, right: 4),
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              decoration: BoxDecoration(
                color: tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                widget.question.expectedAnswer!,
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
