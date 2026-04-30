import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
import '../../../../core/widgets/reasoning_toggle.dart';
import '../../../lesson_kit/domain/entities/lesson_kit.dart';
import '../../../lesson_kit/presentation/providers/lesson_kit_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../data/gemma_student_help_service.dart';

final studentHelpServiceProvider = Provider<GemmaStudentHelpService>(
  (ref) => GemmaStudentHelpService(
    settingsReader: () => ref.read(settingsProvider).modelSettings,
  ),
);

class StudentHelpPage extends ConsumerStatefulWidget {
  const StudentHelpPage({super.key});

  @override
  ConsumerState<StudentHelpPage> createState() => _StudentHelpPageState();
}

class _ChatMessage {
  const _ChatMessage({
    required this.fromStudent,
    required this.text,
    this.reasoning,
  });

  final bool fromStudent;
  final String text;
  final String? reasoning;
}

class _StudentHelpPageState extends ConsumerState<StudentHelpPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _busy = false;
  bool _thinkingActive = false;
  bool _thinkingEnabledForCurrentRun = false;
  String _thinkingText = '';
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromStudent: false,
      text: 'Salaam. Ask me anything about the lesson kit you just generated.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final lesson = ref
        .read(lessonKitGenerationProvider)
        .maybeWhen(data: (kit) => kit, orElse: () => null);

    setState(() {
      _busy = true;
      _messages.add(_ChatMessage(fromStudent: true, text: text));
      _controller.clear();
    });
    _scrollToBottom();

    final localReply = _localReplyFor(question: text, lessonKit: lesson);
    if (localReply != null) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(fromStudent: false, text: localReply));
        _busy = false;
      });
      _scrollToBottom();
      return;
    }

    final thinkingMode = ref.read(settingsProvider).modelSettings.thinkingMode;
    setState(() {
      _thinkingActive = true;
      _thinkingEnabledForCurrentRun = thinkingMode;
      _thinkingText = '';
    });
    _scrollToBottom();

    try {
      final language = lesson?.language;
      final answer = await ref
          .read(studentHelpServiceProvider)
          .answer(
            question: text,
            language: language ?? AppLanguage.english,
            lessonKit: lesson,
            onThinking: (content) {
              if (!mounted || content.trim().isEmpty) return;
              setState(() {
                _thinkingText = _appendReasoningText(_thinkingText, content);
              });
              _scrollToBottom();
            },
          );
      if (!mounted) return;
      final reasoning = _thinkingText.trim();
      setState(() {
        _messages.add(
          _ChatMessage(
            fromStudent: false,
            text: answer,
            reasoning: reasoning.isEmpty ? null : reasoning,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(fromStudent: false, text: _errorReplyFor(e)),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _thinkingActive = false;
          _thinkingText = '';
        });
      }
      _scrollToBottom();
    }
  }

  String _appendReasoningText(String current, String chunk) {
    final next = '$current$chunk'.trimLeft();
    const limit = 1800;
    if (next.length <= limit) return next;
    return '...${next.substring(next.length - limit).trimLeft()}';
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String? _localReplyFor({
    required String question,
    required LessonKit? lessonKit,
  }) {
    if (_isGreeting(question)) {
      if (lessonKit == null) {
        return 'Salaam. I am ready, but I need a lesson kit first. Generate or open a lesson, then ask me about that topic.';
      }
      return 'Salaam. I am ready to help with "${lessonKit.lessonTitle}". Ask me which part feels confusing.';
    }

    if (lessonKit == null) {
      return 'I need an active lesson kit before I can answer safely. Generate a lesson kit or open a saved lesson, then ask me again.';
    }

    return null;
  }

  bool _isGreeting(String text) {
    final normalized = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z\s]'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    const greetings = {
      'hi',
      'hello',
      'hey',
      'salam',
      'salaam',
      'assalamualaikum',
      'assalamu alaikum',
    };
    return greetings.contains(normalized);
  }

  String _errorReplyFor(Object error) {
    if (error is ModelUnavailableException) {
      return error.message;
    }
    return 'I could not reach Gemma 4 for this answer. Please try again in a moment.';
  }

  @override
  Widget build(BuildContext context) {
    final thinkingMode = ref.watch(
      settingsProvider.select(
        (settings) => settings.modelSettings.thinkingMode,
      ),
    );
    final showModelActivity = _thinkingActive;

    return AdaptivePageScaffold(
      title: 'Student help',
      onBack: () => context.goNamed(AppRoute.home),
      bottomBar: _StudentHelpComposer(
        controller: _controller,
        busy: _busy,
        thinkingMode: thinkingMode,
        onSubmitted: (_) => _send(),
        onSend: _send,
        onThinkingModeChanged: ref
            .read(settingsProvider.notifier)
            .setThinkingMode,
        onVoiceTap: () => showAdaptiveMessage(
          context,
          'Voice input is planned for the next build. Text questions are active now.',
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        itemCount: _messages.length + (showModelActivity ? 1 : 0),
        itemBuilder: (context, index) {
          if (showModelActivity && index == _messages.length) {
            return _ModelActivityBubble(
              thinkingEnabled: _thinkingEnabledForCurrentRun,
              reasoning: _thinkingText,
            );
          }
          return _Bubble(message: _messages[index]);
        },
      ),
    );
  }
}

class _StudentHelpComposer extends StatelessWidget {
  const _StudentHelpComposer({
    required this.controller,
    required this.busy,
    required this.thinkingMode,
    required this.onSubmitted,
    required this.onSend,
    required this.onThinkingModeChanged,
    required this.onVoiceTap,
  });

  final TextEditingController controller;
  final bool busy;
  final bool thinkingMode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSend;
  final ValueChanged<bool> onThinkingModeChanged;
  final VoidCallback onVoiceTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.canvas,
          border: Border(top: BorderSide(color: tokens.oat)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ReasoningToggle(
                compact: true,
                enabled: thinkingMode,
                onChanged: busy ? null : onThinkingModeChanged,
                detail: busy
                    ? 'Applies to the next answer.'
                    : 'Show the model trace while answering.',
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _VoiceButton(onTap: onVoiceTap),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChatInputField(
                      controller: controller,
                      placeholder: 'Ask a question',
                      onSubmitted: onSubmitted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final canSend = value.text.trim().isNotEmpty && !busy;
                      return _SendButton(
                        busy: busy,
                        onTap: canSend ? onSend : null,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceButton extends StatelessWidget {
  const _VoiceButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final icon = AppIcons.mic(context);
    final button = SizedBox.square(
      dimension: 44,
      child: Center(child: Icon(icon, color: tokens.ink, size: 20)),
    );

    if (useCupertino(context)) {
      return Semantics(
        label: 'Voice input',
        button: true,
        child: CupertinoButton(
          minimumSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(6),
          onPressed: onTap,
          child: button,
        ),
      );
    }

    return Tooltip(
      message: 'Voice input',
      child: Material(
        color: tokens.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: tokens.oat),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: button,
        ),
      ),
    );
  }
}

class _ChatInputField extends StatelessWidget {
  const _ChatInputField({
    required this.controller,
    required this.placeholder,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String placeholder;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final borderRadius = BorderRadius.circular(6);
    final border = Border.all(color: tokens.oat);

    if (useCupertino(context)) {
      return Container(
        height: 44,
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: borderRadius,
          border: border,
        ),
        child: CupertinoTextField(
          controller: controller,
          placeholder: placeholder,
          placeholderStyle: TextStyle(color: tokens.inkSubtle),
          decoration: null,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          textInputAction: TextInputAction.send,
          textAlignVertical: TextAlignVertical.center,
          onSubmitted: onSubmitted,
          cursorColor: tokens.ink,
          style: TextStyle(color: tokens.ink, fontSize: 16, letterSpacing: 0),
        ),
      );
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: borderRadius,
        border: border,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: placeholder,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        style: Theme.of(context).textTheme.bodyMedium,
        cursorColor: tokens.ink,
        textInputAction: TextInputAction.send,
        textAlignVertical: TextAlignVertical.center,
        onSubmitted: onSubmitted,
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final bg = busy ? tokens.inkMuted : tokens.ink;
    final inactive = onTap == null && !busy;
    final content = SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: busy
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokens.canvas,
                ),
              )
            : Icon(
                AppIcons.send(context),
                color: inactive ? tokens.inkSubtle : tokens.canvas,
                size: 18,
              ),
      ),
    );

    if (useCupertino(context)) {
      return CupertinoButton(
        minimumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(6),
        color: inactive ? tokens.surface : bg,
        disabledColor: inactive ? tokens.surface : bg,
        onPressed: onTap,
        child: content,
      );
    }

    return Material(
      color: inactive ? tokens.surface : bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: inactive ? tokens.oat : bg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: content,
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final isStudent = message.fromStudent;
    final reasoning = message.reasoning?.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: isStudent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isStudent ? tokens.ink : tokens.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isStudent ? 12 : 4),
                  bottomRight: Radius.circular(isStudent ? 4 : 12),
                ),
                border: isStudent ? null : Border.all(color: tokens.oat),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isStudent &&
                      reasoning != null &&
                      reasoning.isNotEmpty) ...[
                    _ReasoningTrace(
                      content: reasoning,
                      active: false,
                      enabled: true,
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isStudent ? tokens.canvas : tokens.ink,
                      fontSize: 15,
                      height: 1.5,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelActivityBubble extends StatelessWidget {
  const _ModelActivityBubble({
    required this.thinkingEnabled,
    required this.reasoning,
  });

  final bool thinkingEnabled;
  final String reasoning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            child: _ReasoningTrace(
              content: reasoning.trim(),
              active: true,
              enabled: thinkingEnabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReasoningTrace extends StatefulWidget {
  const _ReasoningTrace({
    required this.content,
    required this.active,
    required this.enabled,
  });

  final String content;
  final bool active;
  final bool enabled;

  @override
  State<_ReasoningTrace> createState() => _ReasoningTraceState();
}

class _ReasoningTraceState extends State<_ReasoningTrace> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final hasContent = widget.content.trim().isNotEmpty;
    final displayText = hasContent
        ? widget.content.trim()
        : widget.enabled
        ? 'Reasoning through the active lesson context...'
        : 'Writing a direct answer.';
    final canExpand = hasContent && displayText.length > 160;

    return Container(
      decoration: BoxDecoration(
        color: widget.enabled ? tokens.surfaceMuted : tokens.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tokens.oat),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: canExpand
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Row(
              children: [
                if (widget.active && widget.enabled)
                  const CupertinoActivityIndicator(radius: 7)
                else
                  Icon(
                    AppIcons.idea(context),
                    color: widget.enabled ? tokens.ink : tokens.inkMuted,
                    size: 15,
                  ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.enabled
                        ? widget.active
                              ? 'Reasoning'
                              : 'Reasoning trace'
                        : 'Direct answer',
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                if (canExpand)
                  Icon(
                    _expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    color: tokens.inkMuted,
                    size: 14,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayText,
            maxLines: _expanded ? null : 3,
            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(
              color: tokens.inkMuted,
              fontSize: 12,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}
