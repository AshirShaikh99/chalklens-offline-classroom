/// Base class for all use cases. A use case represents one user-facing
/// action and depends only on domain repository abstractions — never on
/// data-layer implementations directly.
abstract class UseCase<T, P> {
  const UseCase();
  Future<T> call(P params);
}

/// Marker for use cases that take no parameters. Prefer this over making
/// `Params` nullable so call sites stay explicit.
class NoParams {
  const NoParams();
}
