import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';

bool useCupertino(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.iOS;
}

/// Platform-adaptive icon set. Cupertino icons on iOS, Material outlined on
/// Android — both rendered through these helpers so the rest of the codebase
/// never has to branch.
class AppIcons {
  const AppIcons._();

  static IconData back(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.chevron_back : Icons.arrow_back;
  static IconData camera(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.camera : Icons.camera_alt_outlined;
  static IconData photo(BuildContext context) => useCupertino(context)
      ? CupertinoIcons.photo
      : Icons.photo_library_outlined;
  static IconData bookmark(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.bookmark : Icons.bookmark_outline;
  static IconData help(BuildContext context) => useCupertino(context)
      ? CupertinoIcons.question_circle
      : Icons.help_outline;
  static IconData settings(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.slider_horizontal_3 : Icons.tune;
  static IconData share(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.square_arrow_up : Icons.ios_share;
  static IconData delete(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.delete : Icons.delete_outline;
  static IconData addPhoto(BuildContext context) => useCupertino(context)
      ? CupertinoIcons.camera_viewfinder
      : Icons.add_a_photo_outlined;
  static IconData refresh(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.arrow_2_circlepath : Icons.refresh;
  static IconData download(BuildContext context) => useCupertino(context)
      ? CupertinoIcons.arrow_down_to_line
      : Icons.download_outlined;
  static IconData file(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.doc : Icons.insert_drive_file;
  static IconData check(BuildContext context) => useCupertino(context)
      ? CupertinoIcons.checkmark_circle
      : Icons.check_circle_outline;
  static IconData lesson(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.book : Icons.menu_book_outlined;
  static IconData objective(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.flag : Icons.flag_outlined;
  static IconData notes(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.pencil : Icons.edit_outlined;
  static IconData idea(BuildContext context) => useCupertino(context)
      ? CupertinoIcons.lightbulb
      : Icons.lightbulb_outline;
  static IconData quiz(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.question : Icons.quiz_outlined;
  static IconData group(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.person_2 : Icons.groups_outlined;
  static IconData homework(BuildContext context) => useCupertino(context)
      ? CupertinoIcons.doc_text
      : Icons.assignment_outlined;
  static IconData glossary(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.textformat : Icons.translate;
  static IconData error(BuildContext context) => useCupertino(context)
      ? CupertinoIcons.exclamationmark_triangle
      : Icons.error_outline;
  static IconData mic(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.mic : Icons.mic_none_outlined;
  static IconData send(BuildContext context) =>
      useCupertino(context) ? CupertinoIcons.arrow_up : Icons.arrow_upward;
  static IconData chevronRight(BuildContext context) => useCupertino(context)
      ? CupertinoIcons.chevron_forward
      : Icons.arrow_forward;
}

/// Page scaffold that swaps `CupertinoPageScaffold` on iOS and `Scaffold` on
/// Android. Background and chrome read from theme tokens so dark mode and
/// platform conventions both stay correct.
class AdaptivePageScaffold extends StatelessWidget {
  const AdaptivePageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.eyebrow,
    this.onBack,
    this.actions = const [],
    this.bottomBar,
  });

  final String title;
  final String? eyebrow;
  final Widget body;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final brightness = Theme.of(context).brightness;
    final overlayStyle = brightness == Brightness.light
        ? SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: tokens.canvas,
            systemNavigationBarIconBrightness: Brightness.dark,
          )
        : SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: tokens.canvas,
            systemNavigationBarIconBrightness: Brightness.light,
          );

    if (useCupertino(context)) {
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: overlayStyle,
        child: CupertinoPageScaffold(
          backgroundColor: tokens.canvas,
          // Quiet nav bar: no bottom border, transparent so it disappears
          // into the canvas. The page hero carries the weight, not chrome.
          navigationBar: CupertinoNavigationBar(
            backgroundColor: tokens.canvas,
            border: const Border(),
            middle: Text(
              title,
              style: TextStyle(
                color: tokens.ink,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            leading: onBack == null
                ? null
                : _CupertinoBackButton(onBack: onBack!),
            trailing: actions.isEmpty
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: actions),
          ),
          child: SafeArea(
            bottom: bottomBar == null,
            child: _BodyWithOptionalBottomBar(body: body, bottomBar: bottomBar),
          ),
        ),
      );
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: tokens.canvas,
        // No bottom hairline — the canvas is one continuous surface.
        appBar: AppBar(
          backgroundColor: tokens.canvas,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          elevation: 0,
          leading: onBack == null
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back, size: 22),
                  onPressed: onBack,
                ),
          title: Text(title),
          actions: actions,
        ),
        body: SafeArea(
          child: _BodyWithOptionalBottomBar(body: body, bottomBar: bottomBar),
        ),
      ),
    );
  }
}

class _BodyWithOptionalBottomBar extends StatelessWidget {
  const _BodyWithOptionalBottomBar({
    required this.body,
    required this.bottomBar,
  });

  final Widget body;
  final Widget? bottomBar;

  @override
  Widget build(BuildContext context) {
    if (bottomBar == null) return body;
    return Column(
      children: [
        Expanded(child: body),
        bottomBar!,
      ],
    );
  }
}

class _CupertinoBackButton extends StatelessWidget {
  const _CupertinoBackButton({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return CupertinoButton(
      minimumSize: const Size(36, 36),
      padding: EdgeInsets.zero,
      onPressed: onBack,
      child: Icon(CupertinoIcons.chevron_back, size: 24, color: tokens.ink),
    );
  }
}

class AdaptiveIconButton extends StatelessWidget {
  const AdaptiveIconButton({
    super.key,
    required this.materialIcon,
    required this.cupertinoIcon,
    required this.onPressed,
    this.tooltip,
    this.size = 22,
  });

  final IconData materialIcon;
  final IconData cupertinoIcon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final icon = useCupertino(context) ? cupertinoIcon : materialIcon;
    if (useCupertino(context)) {
      final button = CupertinoButton(
        minimumSize: const Size(36, 36),
        padding: const EdgeInsets.symmetric(horizontal: 6),
        onPressed: onPressed,
        child: Icon(
          icon,
          size: size,
          color: onPressed == null ? tokens.inkSubtle : tokens.ink,
        ),
      );
      return tooltip == null
          ? button
          : Semantics(label: tooltip, child: button);
    }

    return IconButton(
      icon: Icon(icon, size: size, color: tokens.ink),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}

/// Text-style nav bar action. Replaces busy icon buttons in the app bar
/// with a quiet label ("Save", "Copy"). Tightens to 0.97 on press; uses
/// `disabled` ink when the action isn't available so the nav bar stays
/// calm even in mid-state.
class AdaptiveTextAction extends StatelessWidget {
  const AdaptiveTextAction({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final disabled = onPressed == null;
    final color = disabled ? tokens.inkSubtle : tokens.ink;

    if (useCupertino(context)) {
      return CupertinoButton(
        minimumSize: const Size(36, 36),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        onPressed: onPressed,
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          minimumSize: const Size(36, 36),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

/// Sharp 4px primary action. On press the container subtly compresses
/// for a quiet physical response.
class AdaptivePrimaryButton extends StatefulWidget {
  const AdaptivePrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.fullWidth = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool fullWidth;

  @override
  State<AdaptivePrimaryButton> createState() => _AdaptivePrimaryButtonState();
}

class _AdaptivePrimaryButtonState extends State<AdaptivePrimaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final disabled = widget.onPressed == null;
    final bg = disabled ? tokens.oat : (_down ? tokens.inkMuted : tokens.ink);

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: tokens.canvas),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            color: tokens.canvas,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );

    final inner = AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(child: child),
      ),
    );

    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: inner,
    );

    if (widget.fullWidth) return SizedBox(width: double.infinity, child: body);
    return body;
  }
}

class AdaptiveSecondaryButton extends StatefulWidget {
  const AdaptiveSecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.fullWidth = true,
  });

  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final bool fullWidth;

  @override
  State<AdaptiveSecondaryButton> createState() =>
      _AdaptiveSecondaryButtonState();
}

class _AdaptiveSecondaryButtonState extends State<AdaptiveSecondaryButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final disabled = widget.onPressed == null;
    final bg = _down ? tokens.surfaceMuted : tokens.surface;

    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: 18, color: tokens.ink),
          const SizedBox(width: 8),
        ],
        Text(
          widget.label,
          style: TextStyle(
            color: disabled ? tokens.inkSubtle : tokens.ink,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );

    final inner = AnimatedScale(
      scale: _down ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: tokens.oat),
        ),
        child: Center(child: child),
      ),
    );

    final body = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: disabled ? null : (_) => setState(() => _down = true),
      onTapCancel: disabled ? null : () => setState(() => _down = false),
      onTapUp: disabled ? null : (_) => setState(() => _down = false),
      onTap: widget.onPressed,
      child: inner,
    );

    if (widget.fullWidth) return SizedBox(width: double.infinity, child: body);
    return body;
  }
}

class AdaptiveProgressIndicator extends StatelessWidget {
  const AdaptiveProgressIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (useCupertino(context)) {
      return CupertinoActivityIndicator(radius: 12, color: tokens.ink);
    }
    return SizedBox(
      width: 22,
      height: 22,
      child: CircularProgressIndicator(strokeWidth: 1.6, color: tokens.ink),
    );
  }
}

class AdaptiveTextField extends StatelessWidget {
  const AdaptiveTextField({
    super.key,
    required this.controller,
    this.label,
    this.placeholder,
    this.minLines = 1,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String? label;
  final String? placeholder;
  final int minLines;
  final int? maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (useCupertino(context)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!.toUpperCase(),
              style: TextStyle(
                color: tokens.inkSubtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const SizedBox(height: 8),
          ],
          CupertinoTextField(
            controller: controller,
            minLines: minLines,
            maxLines: maxLines,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            placeholder: placeholder,
            placeholderStyle: TextStyle(color: tokens.inkSubtle),
            style: TextStyle(
              color: tokens.ink,
              fontSize: 16,
              height: 1.4,
              letterSpacing: 0,
            ),
            cursorColor: tokens.ink,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: tokens.oat),
            ),
          ),
        ],
      );
    }

    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      cursorColor: tokens.ink,
      style: TextStyle(
        color: tokens.ink,
        fontSize: 16,
        height: 1.4,
        letterSpacing: 0,
      ),
      decoration: InputDecoration(labelText: label, hintText: placeholder),
    );
  }
}

class AdaptiveInlineTextField extends StatelessWidget {
  const AdaptiveInlineTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (useCupertino(context)) {
      return CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: TextStyle(color: tokens.inkSubtle),
        decoration: null,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        textInputAction: TextInputAction.send,
        onSubmitted: onSubmitted,
        cursorColor: tokens.ink,
        style: TextStyle(color: tokens.ink, fontSize: 16, letterSpacing: 0),
      );
    }

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: placeholder,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        filled: false,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      ),
      style: Theme.of(context).textTheme.bodyMedium,
      cursorColor: tokens.ink,
      textInputAction: TextInputAction.send,
      onSubmitted: onSubmitted,
    );
  }
}

class AdaptiveSelectField<T> extends StatelessWidget {
  const AdaptiveSelectField({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (useCupertino(context)) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final selected = await showCupertinoModalPopup<T>(
            context: context,
            builder: (sheetContext) {
              return CupertinoActionSheet(
                title: Text(label),
                actions: [
                  for (final item in items)
                    CupertinoActionSheetAction(
                      onPressed: () => Navigator.of(sheetContext).pop(item),
                      child: Text(labelOf(item)),
                    ),
                ],
                cancelButton: CupertinoActionSheetAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text('Cancel'),
                ),
              );
            },
          );
          if (selected != null) onChanged(selected);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: tokens.oat),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.toUpperCase(),
                      style: TextStyle(
                        color: tokens.inkSubtle,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      labelOf(value),
                      style: TextStyle(
                        color: tokens.ink,
                        fontSize: 16,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                CupertinoIcons.chevron_up_chevron_down,
                size: 15,
                color: tokens.inkSubtle,
              ),
            ],
          ),
        ),
      );
    }

    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(labelText: label),
      style: Theme.of(context).textTheme.bodyMedium,
      icon: Icon(Icons.keyboard_arrow_down, color: tokens.inkSubtle, size: 20),
      items: items
          .map(
            (item) =>
                DropdownMenuItem<T>(value: item, child: Text(labelOf(item))),
          )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class AdaptiveSegmentedControl<T extends Object> extends StatelessWidget {
  const AdaptiveSegmentedControl({
    super.key,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;

    if (useCupertino(context)) {
      return SizedBox(
        width: double.infinity,
        child: CupertinoSlidingSegmentedControl<T>(
          groupValue: value,
          backgroundColor: tokens.surfaceMuted,
          thumbColor: tokens.surface,
          children: {
            for (final item in values)
              item: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  labelOf(item),
                  style: TextStyle(
                    fontSize: 13,
                    color: tokens.ink,
                    letterSpacing: 0,
                  ),
                ),
              ),
          },
          onValueChanged: (next) {
            if (next != null) onChanged(next);
          },
        ),
      );
    }

    return SegmentedButton<T>(
      segments: values
          .map(
            (item) => ButtonSegment<T>(value: item, label: Text(labelOf(item))),
          )
          .toList(),
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
      showSelectedIcon: false,
    );
  }
}

class AdaptiveSlider extends StatelessWidget {
  const AdaptiveSlider({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (useCupertino(context)) {
      return CupertinoSlider(
        value: value,
        min: min,
        max: max,
        divisions: divisions,
        activeColor: tokens.ink,
        thumbColor: tokens.ink,
        onChanged: onChanged,
      );
    }
    return Slider(
      value: value,
      min: min,
      max: max,
      divisions: divisions,
      onChanged: onChanged,
    );
  }
}

Future<void> showAdaptiveMessage(BuildContext context, String message) async {
  if (useCupertino(context)) {
    await showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
