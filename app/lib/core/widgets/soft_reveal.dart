import 'package:flutter/material.dart';

/// Quiet entrance motion for page sections. It only animates opacity and
/// transform, keeping the UI calm while still feeling responsive.
class SoftReveal extends StatefulWidget {
  const SoftReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 620),
    this.offset = const Offset(0, 0.045),
  });

  final Widget child;
  final Duration delay;
  final Duration duration;
  final Offset offset;

  @override
  State<SoftReveal> createState() => _SoftRevealState();
}

class _SoftRevealState extends State<SoftReveal>
    with SingleTickerProviderStateMixin {
  static const Curve _curve = Cubic(0.16, 1, 0.3, 1);

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    final curved = CurvedAnimation(parent: _controller, curve: _curve);
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curved);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant SoftReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
