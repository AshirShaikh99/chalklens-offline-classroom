import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'adaptive_components.dart';

class ReasoningToggle extends StatelessWidget {
  const ReasoningToggle({
    super.key,
    required this.enabled,
    required this.onChanged,
    this.compact = false,
    this.detail,
  });

  final bool enabled;
  final ValueChanged<bool>? onChanged;
  final bool compact;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final disabled = onChanged == null;
    final switchControl = useCupertino(context)
        ? CupertinoSwitch(
            value: enabled,
            activeTrackColor: tokens.ink,
            onChanged: onChanged,
          )
        : Switch(value: enabled, onChanged: onChanged);

    return Container(
      decoration: BoxDecoration(
        color: compact ? tokens.canvas : tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.oat),
      ),
      padding: EdgeInsets.fromLTRB(12, compact ? 8 : 12, 10, compact ? 8 : 12),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: enabled
                  ? tokens.ink.withValues(alpha: disabled ? 0.08 : 0.12)
                  : tokens.surface,
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: tokens.oat),
            ),
            child: Icon(
              AppIcons.idea(context),
              color: enabled && !disabled ? tokens.ink : tokens.inkMuted,
              size: compact ? 16 : 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'Reasoning',
                      style: TextStyle(
                        color: disabled ? tokens.inkMuted : tokens.ink,
                        fontSize: compact ? 13 : 14,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      enabled ? 'ON' : 'OFF',
                      style: TextStyle(
                        color: tokens.inkSubtle,
                        fontFamily: 'monospace',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                if (detail != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    detail!,
                    maxLines: compact ? 1 : 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.inkMuted,
                      fontSize: compact ? 12 : 13,
                      height: 1.35,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          switchControl,
        ],
      ),
    );
  }
}
