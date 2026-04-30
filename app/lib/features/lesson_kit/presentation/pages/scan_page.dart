import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/curriculum.dart';
import '../../../../core/constants/languages.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/adaptive_components.dart';
import '../../../../core/widgets/soft_reveal.dart';
import '../../domain/entities/lesson_context.dart';
import '../../domain/entities/student_level.dart';
import '../providers/lesson_kit_providers.dart';

class ScanPage extends ConsumerStatefulWidget {
  const ScanPage({super.key});

  @override
  ConsumerState<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends ConsumerState<ScanPage> {
  String _grade = Curriculum.grades[4];
  String _subject = Curriculum.subjects.first;
  AppLanguage _language = AppLanguage.english;
  StudentLevel _studentLevel = StudentLevel.standard;
  double _classDuration = 35;
  Uint8List? _imageBytes;
  String? _validationMessage;
  final TextEditingController _passageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _passageController.addListener(_clearValidationWhenReady);
  }

  @override
  void dispose() {
    _passageController.removeListener(_clearValidationWhenReady);
    _passageController.dispose();
    super.dispose();
  }

  void _clearValidationWhenReady() {
    if (_validationMessage == null) return;
    if (_passageController.text.trim().isEmpty) return;
    setState(() => _validationMessage = null);
  }

  Future<void> _onCapturePressed() async {
    final isApple = useCupertino(context);
    final tokens = context.tokens;
    final cameraIcon = AppIcons.camera(context);
    final photoIcon = AppIcons.photo(context);

    ImageSource? source;
    if (isApple) {
      source = await showCupertinoModalPopup<ImageSource>(
        context: context,
        builder: (sheetContext) => CupertinoActionSheet(
          title: const Text('Add textbook page'),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () =>
                  Navigator.of(sheetContext).pop(ImageSource.camera),
              child: const Text('Take Photo'),
            ),
            CupertinoActionSheetAction(
              onPressed: () =>
                  Navigator.of(sheetContext).pop(ImageSource.gallery),
              child: const Text('Choose From Library'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(sheetContext).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: tokens.surface,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (sheetContext) => SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(cameraIcon, size: 22, color: tokens.ink),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
              ),
              ListTile(
                leading: Icon(photoIcon, size: 22, color: tokens.ink),
                title: const Text('Pick from gallery'),
                onTap: () =>
                    Navigator.of(sheetContext).pop(ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    }

    if (!mounted || source == null) return;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2048,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _validationMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      await showAdaptiveMessage(context, 'Could not capture image: $e');
    }
  }

  Future<void> _onGeneratePressed() async {
    final passage = _passageController.text.trim();
    if (_imageBytes == null && passage.isEmpty) {
      setState(() {
        _validationMessage = 'Add a photo or paste the textbook words first.';
      });
      return;
    }

    final ctx = LessonContext(
      grade: _grade,
      subject: _subject,
      language: _language,
      classDurationMinutes: _classDuration.round(),
      studentLevel: _studentLevel,
    );

    unawaited(
      ref
          .read(lessonKitGenerationProvider.notifier)
          .generate(
            context: ctx,
            passage: passage.isEmpty ? null : passage,
            imageBytes: _imageBytes,
          ),
    );

    if (!mounted) return;
    context.goNamed(AppRoute.lessonKit);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return AdaptivePageScaffold(
      title: 'Make a lesson',
      onBack: () => context.goNamed(AppRoute.home),
      bottomBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        decoration: BoxDecoration(
          color: tokens.canvas,
          border: Border(top: BorderSide(color: tokens.oat)),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: AdaptivePrimaryButton(
              onPressed: _onGeneratePressed,
              icon: AppIcons.lesson(context),
              label: 'Generate lesson kit',
            ),
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 880;
          return SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              isWide ? 40 : 20,
              14,
              isWide ? 40 : 20,
              28,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 980),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SoftReveal(child: _ScanIntro()),
                    const SizedBox(height: 28),
                    if (isWide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SoftReveal(
                              delay: const Duration(milliseconds: 80),
                              child: _SourcePanel(
                                imageBytes: _imageBytes,
                                validationMessage: _validationMessage,
                                passageController: _passageController,
                                onCapturePressed: _onCapturePressed,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          SizedBox(
                            width: 360,
                            child: SoftReveal(
                              delay: const Duration(milliseconds: 160),
                              child: _ClassSetupPanel(
                                grade: _grade,
                                subject: _subject,
                                language: _language,
                                classDuration: _classDuration,
                                studentLevel: _studentLevel,
                                onGradeChanged: (v) =>
                                    setState(() => _grade = v ?? _grade),
                                onSubjectChanged: (v) =>
                                    setState(() => _subject = v ?? _subject),
                                onLanguageChanged: (v) =>
                                    setState(() => _language = v ?? _language),
                                onDurationChanged: (v) =>
                                    setState(() => _classDuration = v),
                                onStudentLevelChanged: (v) =>
                                    setState(() => _studentLevel = v),
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      SoftReveal(
                        delay: const Duration(milliseconds: 80),
                        child: _SourcePanel(
                          imageBytes: _imageBytes,
                          validationMessage: _validationMessage,
                          passageController: _passageController,
                          onCapturePressed: _onCapturePressed,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SoftReveal(
                        delay: const Duration(milliseconds: 160),
                        child: _ClassSetupPanel(
                          grade: _grade,
                          subject: _subject,
                          language: _language,
                          classDuration: _classDuration,
                          studentLevel: _studentLevel,
                          onGradeChanged: (v) =>
                              setState(() => _grade = v ?? _grade),
                          onSubjectChanged: (v) =>
                              setState(() => _subject = v ?? _subject),
                          onLanguageChanged: (v) =>
                              setState(() => _language = v ?? _language),
                          onDurationChanged: (v) =>
                              setState(() => _classDuration = v),
                          onStudentLevelChanged: (v) =>
                              setState(() => _studentLevel = v),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ScanIntro extends StatelessWidget {
  const _ScanIntro();

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Two choices, then teach.',
          style: TextStyle(
            color: tokens.ink,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.06,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Give ChalkLens the source material, confirm the classroom '
            'context, and the offline model will draft the kit.',
            style: TextStyle(
              color: tokens.inkMuted,
              fontSize: 15,
              height: 1.45,
              letterSpacing: 0,
            ),
          ),
        ),
      ],
    );
  }
}

class _SourcePanel extends StatelessWidget {
  const _SourcePanel({
    required this.imageBytes,
    required this.validationMessage,
    required this.passageController,
    required this.onCapturePressed,
  });

  final Uint8List? imageBytes;
  final String? validationMessage;
  final TextEditingController passageController;
  final VoidCallback onCapturePressed;

  @override
  Widget build(BuildContext context) {
    return _StepPanel(
      number: '01',
      icon: AppIcons.camera(context),
      title: 'Source material',
      detail:
          'A photo is best. Pasted text works when the page is already typed.',
      child: Column(
        children: [
          _CaptureArea(imageBytes: imageBytes, onTap: onCapturePressed),
          const SizedBox(height: 14),
          _PassageField(controller: passageController),
          if (validationMessage != null) ...[
            const SizedBox(height: 10),
            _InlineNotice(message: validationMessage!),
          ],
        ],
      ),
    );
  }
}

class _ClassSetupPanel extends StatelessWidget {
  const _ClassSetupPanel({
    required this.grade,
    required this.subject,
    required this.language,
    required this.classDuration,
    required this.studentLevel,
    required this.onGradeChanged,
    required this.onSubjectChanged,
    required this.onLanguageChanged,
    required this.onDurationChanged,
    required this.onStudentLevelChanged,
  });

  final String grade;
  final String subject;
  final AppLanguage language;
  final double classDuration;
  final StudentLevel studentLevel;
  final ValueChanged<String?> onGradeChanged;
  final ValueChanged<String?> onSubjectChanged;
  final ValueChanged<AppLanguage?> onLanguageChanged;
  final ValueChanged<double> onDurationChanged;
  final ValueChanged<StudentLevel> onStudentLevelChanged;

  @override
  Widget build(BuildContext context) {
    return _StepPanel(
      number: '02',
      icon: AppIcons.settings(context),
      title: 'Class setup',
      detail: 'These details keep the generated lesson practical for the room.',
      child: Column(
        children: [
          AdaptiveSelectField<String>(
            label: 'Class',
            value: grade,
            items: Curriculum.grades,
            labelOf: (g) => g,
            onChanged: onGradeChanged,
          ),
          const SizedBox(height: 14),
          AdaptiveSelectField<String>(
            label: 'Subject',
            value: subject,
            items: Curriculum.subjects,
            labelOf: (s) => s,
            onChanged: onSubjectChanged,
          ),
          const SizedBox(height: 14),
          AdaptiveSelectField<AppLanguage>(
            label: 'Output language',
            value: language,
            items: AppLanguage.primaryTeachingLanguages,
            labelOf: (l) => '${l.label}  ·  ${l.native}',
            onChanged: onLanguageChanged,
          ),
          const SizedBox(height: 22),
          _DurationSlider(value: classDuration, onChanged: onDurationChanged),
          const SizedBox(height: 18),
          _StudentLevelSelector(
            value: studentLevel,
            onChanged: onStudentLevelChanged,
          ),
        ],
      ),
    );
  }
}

class _StepPanel extends StatelessWidget {
  const _StepPanel({
    required this.number,
    required this.icon,
    required this.title,
    required this.detail,
    required this.child,
  });

  final String number;
  final IconData icon;
  final String title;
  final String detail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.oat),
      ),
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tokens.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tokens.oat),
                ),
                child: Icon(icon, size: 19, color: tokens.ink),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number,
                      style: TextStyle(
                        color: tokens.inkSubtle,
                        fontFamily: 'monospace',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      title,
                      style: TextStyle(
                        color: tokens.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        height: 1.12,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      detail,
                      style: TextStyle(
                        color: tokens.inkMuted,
                        fontSize: 13,
                        height: 1.4,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

class _PassageField extends StatelessWidget {
  const _PassageField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AdaptiveTextField(
      controller: controller,
      minLines: 3,
      maxLines: 6,
      textInputAction: TextInputAction.newline,
      label: 'Textbook words',
      placeholder: 'Paste the textbook words here.',
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.washYellow,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.oat),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: tokens.washYellowInk,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.4,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _CaptureArea extends StatelessWidget {
  const _CaptureArea({required this.imageBytes, required this.onTap});

  final Uint8List? imageBytes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final captured = imageBytes != null;
    final content = captured
        ? Stack(
            fit: StackFit.expand,
            children: [
              Image.memory(imageBytes!, fit: BoxFit.cover),
              Positioned(
                right: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: tokens.ink.withValues(alpha: 0.82),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        AppIcons.refresh(context),
                        size: 12,
                        color: tokens.canvas,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'CHANGE PAGE',
                        style: TextStyle(
                          color: tokens.canvas,
                          fontFamily: 'monospace',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          )
        : Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: tokens.surfaceMuted,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      AppIcons.addPhoto(context),
                      size: 22,
                      color: tokens.inkMuted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Take a photo of the page',
                    style: TextStyle(
                      color: tokens.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'You can also paste the words below.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: tokens.inkMuted,
                      fontSize: 13,
                      letterSpacing: 0,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          );

    return AspectRatio(
      aspectRatio: 16 / 10,
      child: useCupertino(context)
          ? GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tokens.oat),
                  ),
                  child: content,
                ),
              ),
            )
          : Material(
              color: tokens.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: tokens.oat),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onTap, child: content),
            ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  const _DurationSlider({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'LESSON TIME',
              style: TextStyle(
                color: tokens.inkSubtle,
                fontFamily: 'monospace',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
            const Spacer(),
            Text(
              '${value.round()} min',
              style: TextStyle(
                color: tokens.ink,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 0,
              ),
            ),
          ],
        ),
        AdaptiveSlider(
          value: value,
          min: 15,
          max: 90,
          divisions: 15,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _StudentLevelSelector extends StatelessWidget {
  const _StudentLevelSelector({required this.value, required this.onChanged});

  final StudentLevel value;
  final ValueChanged<StudentLevel> onChanged;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'HELP LEVEL',
          style: TextStyle(
            color: tokens.inkSubtle,
            fontFamily: 'monospace',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 10),
        AdaptiveSegmentedControl<StudentLevel>(
          value: value,
          values: StudentLevel.values,
          labelOf: _levelLabel,
          onChanged: onChanged,
        ),
      ],
    );
  }

  String _levelLabel(StudentLevel level) {
    return switch (level) {
      StudentLevel.easy => 'Extra help',
      StudentLevel.standard => 'Regular',
      StudentLevel.advanced => 'Challenge',
    };
  }
}
