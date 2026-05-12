import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/languages.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
import '../../../../core/widgets/reasoning_toggle.dart';
import '../../../lesson_kit/domain/entities/lesson_kit.dart';
import '../../../lesson_kit/presentation/providers/lesson_kit_providers.dart';
import '../../../saved_lessons/domain/entities/saved_lesson.dart';
import '../../../saved_lessons/presentation/providers/saved_lessons_providers.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../providers/student_help_providers.dart';

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

class _SelectedLessonContext {
  const _SelectedLessonContext({
    required this.kit,
    required this.source,
    this.savedLessonId,
  });

  final LessonKit? kit;
  final String source;
  final String? savedLessonId;

  bool get hasLesson => kit != null;
}

class _StudentHelpPageState extends ConsumerState<StudentHelpPage> {
  static const Duration _maxVoiceRecordingDuration = Duration(seconds: 30);

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _busy = false;
  bool _thinkingActive = false;
  bool _thinkingEnabledForCurrentRun = false;
  bool _recordingVoice = false;
  Duration _voiceRecordingDuration = Duration.zero;
  Timer? _voiceRecordingTimer;
  LessonKit? _voiceLessonContext;
  String _thinkingText = '';
  String? _selectedSavedLessonId;
  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      fromStudent: false,
      text: 'Salaam. Choose a lesson context, then ask me what feels unclear.',
    ),
  ];

  @override
  void dispose() {
    _voiceRecordingTimer?.cancel();
    if (_recordingVoice) {
      unawaited(ref.read(studentVoiceRecorderProvider).cancel());
    }
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final lesson = await _selectedLessonKitForSend();
    if (!mounted) return;

    await _submitStudentQuestion(
      displayText: text,
      question: text,
      lesson: lesson,
    );
  }

  Future<void> _submitStudentQuestion({
    required String displayText,
    required String question,
    required LessonKit? lesson,
    Uint8List? audioBytes,
  }) async {
    setState(() {
      _busy = true;
      _messages.add(_ChatMessage(fromStudent: true, text: displayText));
      _controller.clear();
    });
    _scrollToBottom();

    final localReply = audioBytes == null
        ? _localReplyFor(question: question, lessonKit: lesson)
        : null;
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
            question: question,
            language: language ?? AppLanguage.english,
            audioBytes: audioBytes,
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

  Future<void> _toggleVoiceRecording() async {
    if (_busy) return;
    unawaited(HapticFeedback.selectionClick());
    if (_recordingVoice) {
      await _stopVoiceRecordingAndSend();
    } else {
      await _startVoiceRecording();
    }
  }

  Future<void> _startVoiceRecording() async {
    final lesson = await _selectedLessonKitForSend();
    if (!mounted) return;
    if (lesson == null) {
      await showAdaptiveMessage(
        context,
        'Choose or generate a lesson before asking by voice.',
      );
      return;
    }

    try {
      await ref.read(studentVoiceRecorderProvider).start();
    } on PlatformException catch (e) {
      if (!mounted) return;
      await showAdaptiveMessage(context, _voiceErrorMessage(e));
      return;
    } catch (e) {
      if (!mounted) return;
      await showAdaptiveMessage(context, 'Could not start voice recording: $e');
      return;
    }

    if (!mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    _voiceRecordingTimer?.cancel();
    setState(() {
      _recordingVoice = true;
      _voiceLessonContext = lesson;
      _voiceRecordingDuration = Duration.zero;
    });
    _voiceRecordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _voiceRecordingDuration + const Duration(seconds: 1);
      setState(() => _voiceRecordingDuration = next);
      if (next >= _maxVoiceRecordingDuration) {
        unawaited(_stopVoiceRecordingAndSend());
      }
    });
  }

  Future<void> _stopVoiceRecordingAndSend() async {
    _voiceRecordingTimer?.cancel();
    _voiceRecordingTimer = null;
    final duration = _voiceRecordingDuration;
    final lesson = _voiceLessonContext;

    Uint8List audioBytes;
    try {
      audioBytes = await ref.read(studentVoiceRecorderProvider).stop();
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _recordingVoice = false;
          _voiceLessonContext = null;
          _voiceRecordingDuration = Duration.zero;
        });
        await showAdaptiveMessage(context, _voiceErrorMessage(e));
      }
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _recordingVoice = false;
          _voiceLessonContext = null;
          _voiceRecordingDuration = Duration.zero;
        });
        await showAdaptiveMessage(context, 'Could not save voice question: $e');
      }
      return;
    }

    if (!mounted) return;
    unawaited(HapticFeedback.lightImpact());
    setState(() {
      _recordingVoice = false;
      _voiceLessonContext = null;
      _voiceRecordingDuration = Duration.zero;
    });

    if (audioBytes.isEmpty) {
      await showAdaptiveMessage(context, 'No voice was recorded. Try again.');
      return;
    }

    await _submitStudentQuestion(
      displayText: 'Voice question · ${_formatDuration(duration)}',
      question:
          'Student voice question recorded for ${_formatDuration(duration)}.',
      lesson: lesson,
      audioBytes: audioBytes,
    );
  }

  String _voiceErrorMessage(PlatformException error) {
    return switch (error.code) {
      'permissionDenied' =>
        'Microphone permission is needed for voice questions.',
      'alreadyRecording' => 'Voice recording is already running.',
      'notRecording' => 'No voice recording is active.',
      'emptyRecording' => 'No voice was recorded. Try again.',
      _ => error.message ?? 'Voice recording is not available on this device.',
    };
  }

  String _appendReasoningText(String current, String chunk) {
    final next = '$current$chunk'.trimLeft();
    const limit = 1800;
    if (next.length <= limit) return next;
    return '...${next.substring(next.length - limit).trimLeft()}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<LessonKit?> _selectedLessonKitForSend() async {
    final activeLesson = ref
        .read(lessonKitGenerationProvider)
        .maybeWhen(data: (kit) => kit, orElse: () => null);

    var savedLessons = _savedLessonsFrom(ref.read(savedLessonsProvider));
    if (savedLessons.isEmpty && activeLesson == null) {
      try {
        savedLessons = await ref.read(savedLessonsProvider.future);
      } catch (_) {
        savedLessons = const <SavedLesson>[];
      }
    }

    return _selectedContextFor(
      activeLesson: activeLesson,
      savedLessons: savedLessons,
    ).kit;
  }

  List<SavedLesson> _savedLessonsFrom(
    AsyncValue<List<SavedLesson>> savedState,
  ) {
    return savedState.maybeWhen(
      data: (lessons) => lessons,
      orElse: () => const <SavedLesson>[],
    );
  }

  _SelectedLessonContext _selectedContextFor({
    required LessonKit? activeLesson,
    required List<SavedLesson> savedLessons,
  }) {
    final selectedId = _selectedSavedLessonId;
    if (selectedId != null) {
      for (final saved in savedLessons) {
        if (saved.id == selectedId) {
          return _SelectedLessonContext(
            kit: saved.kit,
            source: 'Saved lesson',
            savedLessonId: saved.id,
          );
        }
      }
    }

    if (activeLesson != null) {
      return _SelectedLessonContext(
        kit: activeLesson,
        source: 'Current lesson',
      );
    }

    if (savedLessons.isNotEmpty) {
      final saved = savedLessons.first;
      return _SelectedLessonContext(
        kit: saved.kit,
        source: 'Saved lesson',
        savedLessonId: saved.id,
      );
    }

    return const _SelectedLessonContext(kit: null, source: 'No lesson');
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
        return 'Salaam. I am ready, but I need a selected lesson first. Generate or open a saved lesson, then ask me about that topic.';
      }
      return 'Salaam. I am ready to help with "${lessonKit.lessonTitle}". Ask me which part feels confusing.';
    }

    if (lessonKit == null) {
      return 'I need a selected lesson before I can answer safely. Generate a lesson kit or open a saved lesson, then ask me again.';
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
    final activeLesson = ref
        .watch(lessonKitGenerationProvider)
        .maybeWhen(data: (kit) => kit, orElse: () => null);
    final savedLessonsState = ref.watch(savedLessonsProvider);
    final savedLessons = _savedLessonsFrom(savedLessonsState);
    final selectedContext = _selectedContextFor(
      activeLesson: activeLesson,
      savedLessons: savedLessons,
    );
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
        recordingVoice: _recordingVoice,
        recordingDuration: _voiceRecordingDuration,
        thinkingMode: thinkingMode,
        onSubmitted: (_) => _send(),
        onSend: _send,
        onThinkingModeChanged: ref
            .read(settingsProvider.notifier)
            .setThinkingMode,
        onVoiceTap: _toggleVoiceRecording,
      ),
      body: ListView.builder(
        controller: _scrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        itemCount: _messages.length + 1 + (showModelActivity ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _LessonContextSelector(
              activeLesson: activeLesson,
              savedLessons: savedLessons,
              savedLessonsLoading: savedLessonsState.isLoading,
              selected: selectedContext,
              onSelectCurrent: activeLesson == null
                  ? null
                  : () => setState(() => _selectedSavedLessonId = null),
              onSelectSaved: (lessonId) =>
                  setState(() => _selectedSavedLessonId = lessonId),
              onOpenSavedLessons: () => context.goNamed(AppRoute.savedLessons),
            );
          }

          final messageIndex = index - 1;
          if (showModelActivity && messageIndex == _messages.length) {
            return _ModelActivityBubble(
              thinkingEnabled: _thinkingEnabledForCurrentRun,
              reasoning: _thinkingText,
            );
          }
          return _Bubble(message: _messages[messageIndex]);
        },
      ),
    );
  }
}

class _LessonContextSelector extends StatelessWidget {
  const _LessonContextSelector({
    required this.activeLesson,
    required this.savedLessons,
    required this.savedLessonsLoading,
    required this.selected,
    required this.onSelectCurrent,
    required this.onSelectSaved,
    required this.onOpenSavedLessons,
  });

  static const String _currentValue = '__current_lesson__';

  final LessonKit? activeLesson;
  final List<SavedLesson> savedLessons;
  final bool savedLessonsLoading;
  final _SelectedLessonContext selected;
  final VoidCallback? onSelectCurrent;
  final ValueChanged<String> onSelectSaved;
  final VoidCallback onOpenSavedLessons;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final kit = selected.kit;
    final hasChoices = activeLesson != null || savedLessons.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: tokens.oat),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected.hasLesson
                    ? tokens.washBlue
                    : tokens.surfaceMuted,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                selected.hasLesson
                    ? AppIcons.lesson(context)
                    : AppIcons.bookmark(context),
                size: 18,
                color: selected.hasLesson
                    ? tokens.washBlueInk
                    : tokens.inkSubtle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    kit?.lessonTitle ?? 'No lesson selected',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 5),
                  if (kit == null)
                    Text(
                      savedLessonsLoading
                          ? 'Loading saved lessons'
                          : 'Create or open a saved lesson',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: tokens.inkMuted,
                        fontSize: 12,
                        height: 1.25,
                        letterSpacing: 0,
                      ),
                    )
                  else
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _LessonContextTag(label: selected.source),
                        _LessonContextTag(label: kit.grade),
                        _LessonContextTag(label: kit.subject),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (savedLessonsLoading && !hasChoices)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: SizedBox.square(
                  dimension: 20,
                  child: const AdaptiveProgressIndicator(),
                ),
              )
            else if (hasChoices)
              Material(
                color: Colors.transparent,
                child: PopupMenuButton<String>(
                  tooltip: 'Choose lesson context',
                  position: PopupMenuPosition.under,
                  onSelected: (value) {
                    if (value == _currentValue) {
                      onSelectCurrent?.call();
                      return;
                    }
                    onSelectSaved(value);
                  },
                  itemBuilder: (context) => [
                    if (activeLesson != null)
                      PopupMenuItem<String>(
                        value: _currentValue,
                        child: _LessonMenuItem(
                          title: activeLesson!.lessonTitle,
                          detail: 'Current lesson',
                          selected: selected.savedLessonId == null,
                        ),
                      ),
                    for (final lesson in savedLessons)
                      PopupMenuItem<String>(
                        value: lesson.id,
                        child: _LessonMenuItem(
                          title: lesson.kit.lessonTitle,
                          detail:
                              '${lesson.context.grade} · ${lesson.context.subject}',
                          selected: selected.savedLessonId == lesson.id,
                        ),
                      ),
                  ],
                  child: SizedBox.square(
                    dimension: 40,
                    child: Center(
                      child: Icon(
                        useCupertino(context)
                            ? CupertinoIcons.chevron_down
                            : Icons.expand_more,
                        color: tokens.inkMuted,
                        size: 19,
                      ),
                    ),
                  ),
                ),
              )
            else
              Tooltip(
                message: 'Saved lessons',
                child: IconButton(
                  onPressed: onOpenSavedLessons,
                  icon: Icon(
                    AppIcons.chevronRight(context),
                    color: tokens.inkMuted,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LessonContextTag extends StatelessWidget {
  const _LessonContextTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: tokens.inkMuted,
          fontFamily: 'monospace',
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1.1,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _LessonMenuItem extends StatelessWidget {
  const _LessonMenuItem({
    required this.title,
    required this.detail,
    required this.selected,
  });

  final String title;
  final String detail;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Row(
      children: [
        Icon(
          selected ? AppIcons.check(context) : AppIcons.lesson(context),
          color: selected ? tokens.washGreenInk : tokens.inkMuted,
          size: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.inkMuted,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StudentHelpComposer extends StatelessWidget {
  const _StudentHelpComposer({
    required this.controller,
    required this.busy,
    required this.recordingVoice,
    required this.recordingDuration,
    required this.thinkingMode,
    required this.onSubmitted,
    required this.onSend,
    required this.onThinkingModeChanged,
    required this.onVoiceTap,
  });

  final TextEditingController controller;
  final bool busy;
  final bool recordingVoice;
  final Duration recordingDuration;
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
              if (recordingVoice) ...[
                const SizedBox(height: 10),
                _RecordingStatus(duration: recordingDuration),
              ],
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _VoiceButton(
                    busy: busy,
                    recording: recordingVoice,
                    onTap: onVoiceTap,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ChatInputField(
                      controller: controller,
                      placeholder: 'Ask a question',
                      enabled: !recordingVoice,
                      onSubmitted: onSubmitted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      final canSend =
                          value.text.trim().isNotEmpty &&
                          !busy &&
                          !recordingVoice;
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

class _RecordingStatus extends StatelessWidget {
  const _RecordingStatus({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: tokens.washRed,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.oat),
      ),
      child: Row(
        children: [
          _RecordingWaveform(color: tokens.washRedInk),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Listening to voice question',
              style: TextStyle(
                color: tokens.washRedInk,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ),
          Text(
            '$minutes:$seconds / 00:30',
            style: TextStyle(
              color: tokens.washRedInk,
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingWaveform extends StatefulWidget {
  const _RecordingWaveform({required this.color});

  final Color color;

  @override
  State<_RecordingWaveform> createState() => _RecordingWaveformState();
}

class _RecordingWaveformState extends State<_RecordingWaveform>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 18,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(5, (index) {
              final phase = (_controller.value * math.pi * 2) + index * 0.7;
              final height = 6 + (math.sin(phase).abs() * 12);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _VoiceButton extends StatefulWidget {
  const _VoiceButton({
    required this.busy,
    required this.recording,
    required this.onTap,
  });

  final bool busy;
  final bool recording;
  final VoidCallback onTap;

  @override
  State<_VoiceButton> createState() => _VoiceButtonState();
}

class _VoiceButtonState extends State<_VoiceButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.recording) _pulseController.repeat();
  }

  @override
  void didUpdateWidget(covariant _VoiceButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.recording && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.recording && _pulseController.isAnimating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final disabled = widget.busy;
    final icon = widget.recording
        ? AppIcons.stop(context)
        : AppIcons.mic(context);
    final foreground = widget.recording ? tokens.canvas : tokens.ink;
    final background = widget.recording ? tokens.washRedInk : tokens.surface;
    final border = widget.recording ? tokens.washRedInk : tokens.oat;
    final tooltip = widget.recording ? 'Stop voice recording' : 'Voice input';
    return Tooltip(
      message: tooltip,
      child: Semantics(
        label: tooltip,
        button: true,
        enabled: !disabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled ? null : widget.onTap,
          child: AnimatedOpacity(
            opacity: disabled ? 0.45 : 1,
            duration: const Duration(milliseconds: 160),
            child: SizedBox.square(
              dimension: 52,
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      if (widget.recording)
                        for (final offset in const [0.0, 0.48])
                          _PulseRing(
                            progress: (_pulseController.value + offset) % 1,
                            color: tokens.washRedInk,
                          ),
                      child!,
                    ],
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: widget.recording ? 50 : 44,
                  height: widget.recording ? 50 : 44,
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(
                      widget.recording ? 25 : 8,
                    ),
                    border: Border.all(color: border),
                    boxShadow: widget.recording
                        ? [
                            BoxShadow(
                              color: tokens.washRedInk.withValues(alpha: 0.22),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                          ]
                        : const [],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    switchInCurve: Curves.easeOutBack,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Icon(
                      icon,
                      key: ValueKey(icon),
                      color: foreground,
                      size: widget.recording ? 22 : 20,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseRing extends StatelessWidget {
  const _PulseRing({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final eased = Curves.easeOutCubic.transform(progress);
    return Positioned.fill(
      child: Transform.scale(
        scale: 0.92 + eased * 0.42,
        child: Opacity(
          opacity: (1 - eased).clamp(0, 1) * 0.36,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.4),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatInputField extends StatelessWidget {
  const _ChatInputField({
    required this.controller,
    required this.placeholder,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String placeholder;
  final bool enabled;
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
          enabled: enabled,
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
        enabled: enabled,
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
        ? 'Waiting for Gemma reasoning tokens...'
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
