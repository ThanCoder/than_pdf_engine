sealed class Result<T, E> {
  const Result();

  bool get isOk => this is Ok<T, E>;
  bool get isErr => this is Err<T, E>;

  T fold({required T Function(T value) ok, required T Function(E error) err}) {
    return switch (this) {
      Ok(value: final value) => ok(value),
      Err(value: final val) => err(val),
    };
  }

  E unwrapError() {
    return switch (this) {
      Ok() => throw StateError('Called unwrapError() on Ok'),
      Err(value: final val) => val,
    };
  }

  T unwrap() {
    return switch (this) {
      Ok(value: final val) => val,
      Err(value: final val) => throw StateError('Called unwrap() on Err: $val'),
    };
  }

  T unwrapOr(T fallback) {
    return switch (this) {
      Ok(value: final val) => val,
      Err() => fallback,
    };
  }
}

class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);
  final T value;
}

class Err<T, E> extends Result<T, E> {
  const Err(this.value);
  final E value;
}
