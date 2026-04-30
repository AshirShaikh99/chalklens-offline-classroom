import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/glossary_term.dart';

/// Key-terms glossary as compact two-column rows with hairline dividers.
class GlossarySection extends StatelessWidget {
  const GlossarySection({super.key, required this.terms});

  final List<GlossaryTerm> terms;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (terms.isEmpty) {
      return Text(
        'No glossary terms.',
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
        for (var i = 0; i < terms.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: tokens.oat),
            ),
          _GlossaryRow(term: terms[i]),
        ],
      ],
    );
  }
}

class _GlossaryRow extends StatelessWidget {
  const _GlossaryRow({required this.term});

  final GlossaryTerm term;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasExample = term.example != null && term.example!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Text(
                term.term,
                style: TextStyle(
                  color: tokens.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 3,
              child: Text(
                term.meaning,
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: 15,
                  height: 1.45,
                  letterSpacing: 0,
                ),
              ),
            ),
          ],
        ),
        if (hasExample)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'e.g. ${term.example!}',
              style: TextStyle(
                color: tokens.inkSubtle,
                fontSize: 13,
                fontStyle: FontStyle.italic,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    );
  }
}
