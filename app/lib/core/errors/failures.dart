/// Domain-layer failure types. Use these in repository / use case return
/// values to make recoverable error states first-class. Distinct from raw
/// exceptions, which represent programmer errors.
sealed class Failure {
  const Failure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      '$runtimeType: $message${cause != null ? ' ($cause)' : ''}';
}

/// Model failed to produce valid output (parse error, schema mismatch).
class ModelOutputFailure extends Failure {
  const ModelOutputFailure(super.message, {super.cause});
}

/// Required model file is missing or device cannot run the model.
class ModelUnavailableFailure extends Failure {
  const ModelUnavailableFailure(super.message, {super.cause});
}

/// Local storage read/write failed.
class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause});
}

/// Catch-all for unexpected failures so callers always have a typed value.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause});
}
