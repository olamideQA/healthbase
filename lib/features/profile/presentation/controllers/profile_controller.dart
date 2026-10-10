import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/safety/safety_boundaries.dart';
import '../../data/profile_repository.dart';
import '../../domain/models/health_profile.dart';

final profileControllerProvider =
    StateNotifierProvider<ProfileController, AsyncValue<HealthProfile?>>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileController(repo, ref);
});

class ProfileController extends StateNotifier<AsyncValue<HealthProfile?>> {
  ProfileController(this._repo, this._ref) : super(const AsyncValue.loading()) {
    loadProfile();
  }

  final ProfileRepository _repo;
  final Ref _ref;

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repo.getMyProfile();
      state = AsyncValue.data(profile);
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
    }
  }

  /// Optimistically update preferred unit system without wiping out screen state.
  Future<bool> updatePreferredUnits(UnitSystem newUnits) async {
    final current = state.value;
    if (current != null) {
      state = AsyncValue.data(current.copyWith(preferredUnits: newUnits));
    }
    try {
      await _repo.updatePreferredUnits(newUnits);
      _ref.invalidate(myProfileProvider);
      return true;
    } on Failure catch (f, st) {
      if (current != null) state = AsyncValue.data(current);
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      if (current != null) state = AsyncValue.data(current);
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }

  /// Update profile attributes with strict physical plausibility validation.
  Future<bool> updateProfile({
    String? displayName,
    DateTime? dateOfBirth,
    SexType? sex,
    double? heightCm,
    double? weightKg,
    UnitSystem? preferredUnits,
  }) async {
    // 1. Validation
    final validationError = _validateInputs(
      displayName: displayName,
      dateOfBirth: dateOfBirth,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    if (validationError != null) {
      state = AsyncValue.error(
        ValidationFailure(message: validationError),
        StackTrace.current,
      );
      return false;
    }

    final previous = state.value;
    state = const AsyncValue.loading();
    try {
      if (preferredUnits != null) {
        await _repo.updatePreferredUnits(preferredUnits);
      }

      final hasProfileFields = displayName != null ||
          dateOfBirth != null ||
          sex != null ||
          heightCm != null ||
          weightKg != null;

      final updated = hasProfileFields
          ? await _repo.updateMyProfile(
              displayName: displayName,
              dateOfBirth: dateOfBirth,
              sex: sex,
              heightCm: heightCm,
              weightKg: weightKg,
            )
          : (await _repo.getMyProfile() ??
              previous?.copyWith(preferredUnits: preferredUnits));

      if (updated != null) {
        state = AsyncValue.data(updated);
      }
      _ref.invalidate(myProfileProvider);
      return true;
    } on Failure catch (f, st) {
      if (previous != null) {
        state = AsyncValue.data(previous);
      } else {
        state = AsyncValue.error(f, st);
      }
      return false;
    } catch (e, st) {
      if (previous != null) {
        state = AsyncValue.data(previous);
      } else {
        state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      }
      return false;
    }
  }

  /// Complete the onboarding flow, optionally saving profile data.
  Future<bool> completeOnboarding({
    String? displayName,
    DateTime? dateOfBirth,
    SexType? sex,
    double? heightCm,
    double? weightKg,
    UnitSystem? preferredUnits,
  }) async {
    final validationError = _validateInputs(
      displayName: displayName,
      dateOfBirth: dateOfBirth,
      heightCm: heightCm,
      weightKg: weightKg,
    );
    if (validationError != null) {
      state = AsyncValue.error(
        ValidationFailure(message: validationError),
        StackTrace.current,
      );
      return false;
    }

    state = const AsyncValue.loading();
    try {
      if (preferredUnits != null) {
        await _repo.updatePreferredUnits(preferredUnits);
      }

      final updated = await _repo.updateMyProfile(
        displayName: displayName,
        dateOfBirth: dateOfBirth,
        sex: sex,
        heightCm: heightCm,
        weightKg: weightKg,
        onboardingCompletedAt: DateTime.now().toUtc(),
      );

      state = AsyncValue.data(updated);
      _ref.invalidate(myProfileProvider);
      return true;
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }

  /// Skip optional onboarding fields and mark setup complete immediately.
  Future<bool> skipOnboarding({UnitSystem? preferredUnits}) async {
    state = const AsyncValue.loading();
    try {
      if (preferredUnits != null) {
        await _repo.updatePreferredUnits(preferredUnits);
      }

      final updated = await _repo.updateMyProfile(
        onboardingCompletedAt: DateTime.now().toUtc(),
      );

      state = AsyncValue.data(updated);
      _ref.invalidate(myProfileProvider);
      return true;
    } on Failure catch (f, st) {
      state = AsyncValue.error(f, st);
      return false;
    } catch (e, st) {
      state = AsyncValue.error(UnexpectedFailure(cause: e), st);
      return false;
    }
  }

  String? _validateInputs({
    String? displayName,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
  }) {
    if (displayName != null && displayName.trim().length > 80) {
      return 'Display name cannot exceed 80 characters.';
    }

    if (dateOfBirth != null) {
      final now = DateTime.now();
      if (dateOfBirth.isAfter(now)) {
        return 'Date of birth cannot be in the future.';
      }
      if (dateOfBirth.year < 1900) {
        return 'Date of birth year must be 1900 or later.';
      }
      final age = now.year - dateOfBirth.year;
      if (age > 125) {
        return 'Please enter a plausible birth year.';
      }
    }

    if (heightCm != null) {
      if (heightCm < 40.0 || heightCm > 260.0) {
        return 'Height must be between 40 cm and 260 cm.';
      }
    }

    if (weightKg != null) {
      if (weightKg < SafetyBoundaries.minWeightKg ||
          weightKg > SafetyBoundaries.maxWeightKg) {
        return 'Weight must be between 1 kg and 400 kg.';
      }
    }

    return null;
  }
}
