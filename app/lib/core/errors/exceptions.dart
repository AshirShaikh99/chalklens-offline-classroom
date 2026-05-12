/// Typed exceptions used across data and presentation layers. The repository
/// layer lets these bubble through the domain contract; presentation classifies
/// by exception type to render appropriate recovery UI.
library;

class ModelOutputException implements Exception {
  const ModelOutputException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ModelOutputException: $message${cause != null ? ' ($cause)' : ''}';
}

class ModelUnavailableException implements Exception {
  const ModelUnavailableException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ModelUnavailableException: $message${cause != null ? ' ($cause)' : ''}';
}

class StorageException implements Exception {
  const StorageException(this.message, {this.cause});
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'StorageException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Thrown when a generation is cancelled by the caller (e.g. page popped
/// while streaming). Distinct from a failure so callers can differentiate
/// "user moved on" from "model errored".
class GenerationCancelled implements Exception {
  const GenerationCancelled();
  @override
  String toString() => 'GenerationCancelled';
}
