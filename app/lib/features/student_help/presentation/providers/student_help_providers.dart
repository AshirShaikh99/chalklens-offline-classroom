import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/student_voice_recorder.dart' show MethodChannelStudentVoiceRecorder;
import '../../domain/student_help_service.dart';
import '../../domain/student_voice_recorder.dart';

final studentHelpServiceProvider = Provider<StudentHelpService>((ref) {
  throw UnimplementedError('studentHelpServiceProvider must be overridden.');
});

final studentVoiceRecorderProvider = Provider<StudentVoiceRecorder>(
  (ref) => const MethodChannelStudentVoiceRecorder(),
);
