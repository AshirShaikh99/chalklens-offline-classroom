import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Editorial mono-style eyebrow label. Compact weight, subdued ink.
/// No icon background — the label carries the structure, the section's
/// content carries the weight.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 13, color: tokens.inkSubtle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                color: tokens.inkSubtle,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
                fontSize: 11,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
