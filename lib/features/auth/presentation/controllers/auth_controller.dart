import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/db/encrypted_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/security_service.dart';
import '../../data/auth_repository.dart';
import '../../domain/models/auth_user.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  Future<void> wipe() => wipeLocalData(
        db: ref.read(appDatabaseProvider),
        security: ref.read(securityServiceProvider),
      );
  return AuthController(repo, onSignOutCleanup: wipe);
});

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._repo, {this._onSignOutCleanup})
      : super(AsyncValue.data(_repo.currentUser));

  final AuthRepository _repo;
  final Future<void> Function()? _onSignOutCleanup;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signInWithPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(user);
      return true;
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(user);
      return true;
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncValue.loading();
    try {
      await _repo.sendPasswordResetEmail(email);
      state = AsyncValue.data(_repo.currentUser);
      return true;
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }

  Future<bool> updatePassword(String newPassword) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updatePassword(newPassword);
      state = AsyncValue.data(_repo.currentUser);
      return true;
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }

  /// Signs out and wipes all local health data first, so nothing survives
  /// the session on this device.
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _onSignOutCleanup?.call();
      await _repo.signOut();
      state = const AsyncValue.data(null);
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
    }
  }

  /// Deletes the server account, then wipes local data. Local wipe runs
  /// only after the server confirms, so an offline failure keeps the
  /// account (and its data) intact for retry.
  Future<bool> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteAccount();
      await _onSignOutCleanup?.call();
      state = const AsyncValue.data(null);
      return true;
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }
}
