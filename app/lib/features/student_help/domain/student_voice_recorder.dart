import 'dart:typed_data';

/// Domain-layer contract for capturing a short student voice question.
/// The data layer provides the platform-specific recorder; presentation and
/// other features depend on this interface only.
abstract class StudentVoiceRecorder {
  Future<void> start();

  Future<Uint8List> stop();

  Future<void> cancel();
}
