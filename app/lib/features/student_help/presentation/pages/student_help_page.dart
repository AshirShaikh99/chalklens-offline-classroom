import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
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
  const _ChatMessage({required this.fromStudent, required this.text});
  final bool fromStudent;
  final String text;
}

class _StudentHelpPageState extends ConsumerState<StudentHelpPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _busy = false;
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
    setState(() {
      _busy = true;
      _messages.add(_ChatMessage(fromStudent: true, text: text));
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final lesson = ref
          .read(lessonKitGenerationProvider)
          .maybeWhen(data: (kit) => kit, orElse: () => null);
      final language = lesson?.language;
      final answer = await ref
          .read(studentHelpServiceProvider)
          .answer(
            question: text,
            language: language ?? AppLanguage.english,
            lessonKit: lesson,
          );
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(fromStudent: false, text: answer));
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(
            fromStudent: false,
            text: 'I could not reach Gemma 4 for this answer: $e',
          ),
        );
      });
    } finally {
      if (mounted) setState(() => _busy = false);
      _scrollToBottom();
    }
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

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AdaptivePageScaffold(
      title: 'Student help',
      onBack: () => context.goNamed(AppRoute.home),
      bottomBar: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
        decoration: BoxDecoration(
          color: tokens.canvas,
          border: Border(top: BorderSide(color: tokens.oat)),
        ),
        child: Row(
          children: [
            AdaptiveIconButton(
              materialIcon: Icons.mic_none_outlined,
              cupertinoIcon: AppIcons.mic(context),
              tooltip: 'Voice input',
              onPressed: () => showAdaptiveMessage(
                context,
                'Voice input is planned for the next build. Text questions are active now.',
              ),
            ),
            Expanded(
              child: AdaptiveInlineTextField(
                controller: _controller,
                placeholder: 'Ask a question',
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            _SendButton(busy: _busy, onTap: _busy ? null : _send),
          ],
        ),
      ),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        itemCount: _messages.length,
        itemBuilder: (context, index) => _Bubble(message: _messages[index]),
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
    final content = SizedBox(
      width: 40,
      height: 40,
      child: Icon(AppIcons.send(context), color: tokens.canvas, size: 18),
    );

    if (useCupertino(context)) {
      return CupertinoButton(
        minimumSize: const Size(40, 40),
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(4),
        color: bg,
        onPressed: onTap,
        child: content,
      );
    }

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
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
              child: Text(
                message.text,
                style: TextStyle(
                  color: isStudent ? tokens.canvas : tokens.ink,
                  fontSize: 15,
                  height: 1.5,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
