import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'adaptive_components.dart';

/// Flat, oat-bordered card. Sharp 8px geometry per DESIGN.md. The icon tile
/// uses a subtle wash so the card scans as a single editorial unit, not a
/// stack of decorative pieces.
class ActionCard extends StatefulWidget {
  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.tileWash,
    this.tileInk,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? tileWash;
  final Color? tileInk;

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final tileWash = widget.tileWash ?? tokens.surfaceMuted;
    final tileInk = widget.tileInk ?? tokens.ink;

    final card = AnimatedScale(
      scale: _down ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: _down ? tokens.surfaceRaised : tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.oat),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tileWash,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(widget.icon, size: 20, color: tileInk),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                      height: 1.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: tokens.inkMuted,
                      fontSize: 13,
                      height: 1.45,
                      letterSpacing: 0,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              AppIcons.chevronRight(context),
              size: useCupertino(context) ? 16 : 18,
              color: tokens.inkSubtle,
            ),
          ],
        ),
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: card,
    );
  }
}
