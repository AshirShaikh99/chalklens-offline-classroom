import 'package:flutter/services.dart';

import '../domain/student_voice_recorder.dart';

export '../domain/student_voice_recorder.dart' show StudentVoiceRecorder;

class MethodChannelStudentVoiceRecorder implements StudentVoiceRecorder {
  const MethodChannelStudentVoiceRecorder();

  static const MethodChannel _channel = MethodChannel(
    'chalk_lens/audio_recorder',
  );

  @override
  Future<void> start() async {
    await _channel.invokeMethod<void>('start');
  }

  @override
  Future<Uint8List> stop() async {
    final result = await _channel.invokeMethod<Object>('stop');
    if (result is Uint8List) return result;
    if (result is List<int>) return Uint8List.fromList(result);
    throw PlatformException(
      code: 'emptyRecording',
      message: 'No voice recording was returned.',
    );
  }

  @override
  Future<void> cancel() async {
    await _channel.invokeMethod<void>('cancel');
  }
}
