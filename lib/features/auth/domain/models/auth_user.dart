import 'package:flutter/foundation.dart';

/// Representation of an authenticated account.
@immutable
class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.emailConfirmedAt,
    this.displayName,
  });

  final String id;
  final String email;
  final DateTime? emailConfirmedAt;
  final String? displayName;

  bool get isEmailConfirmed => emailConfirmedAt != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuthUser &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          emailConfirmedAt == other.emailConfirmedAt &&
          displayName == other.displayName;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      emailConfirmedAt.hashCode ^
      displayName.hashCode;

  @override
  String toString() =>
      'AuthUser(id: $id, email: $email, isEmailConfirmed: $isEmailConfirmed)';
}
