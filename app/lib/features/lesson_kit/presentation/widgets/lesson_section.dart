import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/section_header.dart';

/// Standard wrapper for one section of the LessonKit. Plain oat-bordered
/// surface; spacing carries structure rather than chrome.
class LessonSection extends StatelessWidget {
  const LessonSection({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.oat),
      ),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(icon: icon, title: title, trailing: trailing),
          child,
        ],
      ),
    );
  }
}

/// Vertically-listed bullet content used by Objectives, Blackboard Notes,
/// Homework. Plain bullets in subtle ink — never colored markers.
class BulletList extends StatelessWidget {
  const BulletList({super.key, required this.items, this.numbered = false});

  final List<String> items;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (items.isEmpty) {
      return Text(
        'No items.',
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
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: Text(
                      numbered ? '${i + 1}.' : '—',
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
                    items[i],
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
          ),
      ],
    );
  }
}

/// Editorial pull-quote / aside used for Local Example and Group Activity.
/// Single hairline rule on the left, no fill — keeps the kit feeling like
/// one document.
class CalloutBox extends StatelessWidget {
  const CalloutBox({super.key, required this.text, this.accent});

  final String text;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: accent ?? tokens.inkSubtle, width: 2),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: tokens.inkMuted,
          fontSize: 15,
          fontStyle: FontStyle.italic,
          height: 1.55,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
