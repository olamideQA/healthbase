import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/failures.dart';
import '../../../../core/security/security_service.dart';
import '../domain/models/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(sb.Supabase.instance.client);
});

final authStateChangesProvider = StreamProvider<AuthUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Production authentication repository interfacing with Supabase Auth.
class AuthRepository {
  AuthRepository(this._client);

  final sb.SupabaseClient _client;

  /// Stream of authentication state transitions.
  Stream<AuthUser?> get authStateChanges {
    return _client.auth.onAuthStateChange.map((data) {
      final user = data.session?.user ?? _client.auth.currentUser;
      if (user == null) return null;
      return _mapSupabaseUser(user);
    });
  }

  /// Current authenticated user, or null if unauthenticated.
  AuthUser? get currentUser {
    final user = _client.auth.currentUser;
    if (user == null) return null;
    return _mapSupabaseUser(user);
  }

  /// Sign up with email, password, and optional display name.
  Future<AuthUser> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final sanitizedEmail = email.trim().toLowerCase();
      final sanitizedName = displayName?.trim();

      final response = await _client.auth.signUp(
        email: sanitizedEmail,
        password: password,
        data: <String, dynamic>{
          if (sanitizedName != null && sanitizedName.isNotEmpty)
            'display_name': sanitizedName,
        },
      );

      final user = response.user;
      if (user == null) {
        throw const AuthFailure(
          message: 'Unable to complete registration. Please try again.',
        );
      }

      AppLogger.info('User registration successful: ${user.id}');
      return _mapSupabaseUser(user);
    } on sb.AuthException catch (e) {
      AppLogger.warning('Sign up auth error: ${e.message}');
      throw _mapAuthException(e);
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.error('Unexpected error during registration', e);
      throw UnexpectedFailure(cause: e);
    }
  }

  /// Sign in with email and password.
  Future<AuthUser> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final sanitizedEmail = email.trim().toLowerCase();

      final response = await _client.auth.signInWithPassword(
        email: sanitizedEmail,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        throw const AuthFailure(
          message: 'Invalid email or password.',
        );
      }

      AppLogger.info('User sign in successful: ${user.id}');
      return _mapSupabaseUser(user);
    } on sb.AuthException catch (e) {
      AppLogger.warning('Sign in auth error: ${e.message}');
      throw _mapAuthException(e);
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.error('Unexpected error during sign in', e);
      throw UnexpectedFailure(cause: e);
    }
  }

  /// Send password reset email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      final sanitizedEmail = email.trim().toLowerCase();
      await _client.auth.resetPasswordForEmail(
        sanitizedEmail,
        redirectTo: 'com.healthbase.healthbase://auth-callback',
      );
      AppLogger.info('Password reset email dispatched.');
    } on sb.AuthException catch (e) {
      AppLogger.warning('Password reset auth error: ${e.message}');
      throw _mapAuthException(e);
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.error('Unexpected error during password reset request', e);
      throw UnexpectedFailure(cause: e);
    }
  }

  /// Update the current authenticated user's password (used after reset callback).
  Future<void> updatePassword(String newPassword) async {
    try {
      await _client.auth.updateUser(
        sb.UserAttributes(password: newPassword),
      );
      AppLogger.info('Password updated successfully.');
    } on sb.AuthException catch (e) {
      AppLogger.warning('Update password auth error: ${e.message}');
      throw _mapAuthException(e);
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.error('Unexpected error during password update', e);
      throw UnexpectedFailure(cause: e);
    }
  }

  /// Sign out current user and clear local session.
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      AppLogger.info('User signed out.');
    } on sb.AuthException catch (e) {
      AppLogger.warning('Sign out error: ${e.message}');
      throw _mapAuthException(e);
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.error('Unexpected error during sign out', e);
      throw UnexpectedFailure(cause: e);
    }
  }

  /// Delete current user's account and all associated health records.
  Future<void> deleteAccount() async {
    try {
      await _client.rpc<void>('delete_my_account');
      await _client.auth.signOut();
      AppLogger.info('Account deleted and session terminated.');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Delete account database error: ${e.message}');
      throw DatabaseFailure(message: e.message, cause: e);
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.error('Unexpected error during account deletion', e);
      throw UnexpectedFailure(cause: e);
    }
  }

  AuthUser _mapSupabaseUser(sb.User user) {
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      emailConfirmedAt: user.emailConfirmedAt != null
          ? DateTime.tryParse(user.emailConfirmedAt!)
          : null,
      displayName: user.userMetadata?['display_name'] as String?,
    );
  }

  Failure _mapAuthException(sb.AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password')) {
      return const AuthFailure(
        message: 'Incorrect email or password. Please try again.',
        code: 'INVALID_CREDENTIALS',
      );
    }
    if (msg.contains('user already registered') ||
        msg.contains('already in use')) {
      return const AuthFailure(
        message: 'An account with this email address already exists.',
        code: 'USER_ALREADY_EXISTS',
      );
    }
    if (msg.contains('password should be at least') ||
        msg.contains('weak password')) {
      return const AuthFailure(
        message:
            'Password must be at least 8 characters long and include numbers and uppercase letters.',
        code: 'WEAK_PASSWORD',
      );
    }
    if (msg.contains('rate limit') || msg.contains('too many requests')) {
      return const AuthFailure(
        message: 'Too many attempts. Please wait a few moments before trying again.',
        code: 'RATE_LIMITED',
      );
    }
    if (msg.contains('network') || msg.contains('failed host lookup')) {
      return const NetworkFailure();
    }
    return AuthFailure(message: e.message, code: e.statusCode);
  }
}
