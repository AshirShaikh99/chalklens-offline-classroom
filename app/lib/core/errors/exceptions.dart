/// Data-layer exceptions. Throw these from datasources; repositories
/// translate them to `Failure` types so the domain layer never deals with
/// raw I/O concerns.
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
