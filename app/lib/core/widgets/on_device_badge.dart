import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Mono uppercase status chip. The tiny green dot is the only color here:
/// a semantic signal that the lesson helper runs on this device.
class OnDeviceBadge extends StatelessWidget {
  const OnDeviceBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: tokens.oat),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: tokens.washGreenInk,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ON-DEVICE',
            style: TextStyle(
              color: tokens.ink,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
