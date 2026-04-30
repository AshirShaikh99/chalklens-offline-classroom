import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 32,
    this.showName = true,
    this.subtitle,
  });

  final double size;
  final bool showName;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final radius = (size * 0.22).clamp(5.0, 10.0);

    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tokens.ink,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Text(
        'S',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.56,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: 0,
        ),
      ),
    );

    if (!showName) return mark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.38),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ChalkLens',
              style: TextStyle(
                color: tokens.ink,
                fontSize: (size * 0.48).clamp(15.0, 22.0),
                fontWeight: FontWeight.w700,
                height: 1.05,
                letterSpacing: 0,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 3),
              Text(
                subtitle!,
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: (size * 0.32).clamp(11.0, 14.0),
                  height: 1.2,
                  letterSpacing: 0,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
