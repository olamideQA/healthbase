import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import '../../../../core/errors/failures.dart';
import '../../../../core/security/security_service.dart';
import '../domain/models/health_profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(sb.Supabase.instance.client);
});

final myProfileProvider = FutureProvider<HealthProfile?>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getMyProfile();
});

/// Repository for managing health profile and account preferences.
class ProfileRepository {
  ProfileRepository(this._client);

  final sb.SupabaseClient _client;

  /// Fetch the active user's own health profile and unit preferences.
  Future<HealthProfile?> getMyProfile() async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) return null;

      // Fetch account preferred_units
      final accountData = await _client
          .from('accounts')
          .select('preferred_units')
          .eq('id', uid)
          .maybeSingle();

      final units = UnitSystem.fromDbValue(
        accountData?['preferred_units'] as String?,
      );

      // Fetch self profile
      final profileData = await _client
          .from('health_profiles')
          .select()
          .eq('owner_account_id', uid)
          .eq('is_self', true)
          .maybeSingle();

      if (profileData == null) return null;

      return HealthProfile.fromJson(
        profileData,
        preferredUnits: units,
      );
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Database error fetching profile: ${e.message}');
      throw DatabaseFailure(message: e.message, cause: e);
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.error('Unexpected error fetching profile', e);
      throw UnexpectedFailure(cause: e);
    }
  }

  /// Update the current user's profile information.
  Future<HealthProfile> updateMyProfile({
    String? displayName,
    DateTime? dateOfBirth,
    SexType? sex,
    double? heightCm,
    double? weightKg,
    DateTime? onboardingCompletedAt,
  }) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw const SecurityFailure(message: 'User is not authenticated.');
      }

      final updatePayload = <String, dynamic>{
        if (displayName != null) 'display_name': displayName.trim(),
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        if (sex != null) 'sex': sex.toDbValue(),
        if (heightCm != null) 'height_cm': heightCm,
        if (weightKg != null) 'weight_kg': weightKg,
        if (onboardingCompletedAt != null)
          'onboarding_completed_at': onboardingCompletedAt.toIso8601String(),
      };

      final response = await _client
          .from('health_profiles')
          .update(updatePayload)
          .eq('owner_account_id', uid)
          .eq('is_self', true)
          .select()
          .single();

      final myProfile = await getMyProfile();
      if (myProfile != null) return myProfile;

      return HealthProfile.fromJson(response);
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Database error updating profile: ${e.message}');
      if (e.message.contains('date_of_birth cannot be in the future')) {
        throw const ValidationFailure(
          message: 'Date of birth cannot be in the future.',
        );
      }
      throw DatabaseFailure(message: e.message, cause: e);
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.error('Unexpected error updating profile', e);
      throw UnexpectedFailure(cause: e);
    }
  }

  /// Update preferred unit system (metric vs imperial).
  Future<void> updatePreferredUnits(UnitSystem unitSystem) async {
    try {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) {
        throw const SecurityFailure(message: 'User is not authenticated.');
      }

      await _client.from('accounts').update(<String, dynamic>{
        'preferred_units': unitSystem.toDbValue(),
      }).eq('id', uid);

      AppLogger.info('Preferred units updated to ${unitSystem.name}');
    } on sb.PostgrestException catch (e) {
      AppLogger.error('Database error updating unit preferences: ${e.message}');
      throw DatabaseFailure(message: e.message, cause: e);
    } catch (e) {
      if (e is Failure) rethrow;
      AppLogger.error('Unexpected error updating unit preferences', e);
      throw UnexpectedFailure(cause: e);
    }
  }
}
