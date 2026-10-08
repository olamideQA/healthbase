/// Sealed failure hierarchy for domain and infrastructure errors.
/// 
/// All failures guarantee a user-friendly message that does not leak
/// raw stack traces or database internals to the user interface.
sealed class Failure {
  const Failure({
    required this.message,
    this.code,
    this.cause,
  });

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => 'Failure(message: $message, code: $code)';
}

/// Network connectivity failures (e.g., offline, timeout, DNS resolution failure).
final class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Unable to connect to the network. Your changes are saved locally.',
    super.code = 'NETWORK_ERROR',
    super.cause,
  });
}

/// Authentication and session failures (e.g. invalid credentials, expired session).
final class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code = 'AUTH_ERROR',
    super.cause,
  });
}

/// Database or persistence failures.
final class DatabaseFailure extends Failure {
  const DatabaseFailure({
    super.message = 'A local storage error occurred. Please try again.',
    super.code = 'DB_ERROR',
    super.cause,
  });
}

/// Input validation failures for health measurements or user profiles.
final class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.cause,
  });
}

/// Security or authorization failures (e.g., unauthorized profile access).
final class SecurityFailure extends Failure {
  const SecurityFailure({
    super.message = 'You do not have permission to view or modify this record.',
    super.code = 'UNAUTHORIZED',
    super.cause,
  });
}

/// Unexpected or unhandled runtime failures.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred. Please try again later.',
    super.code = 'UNEXPECTED',
    super.cause,
  });
}
