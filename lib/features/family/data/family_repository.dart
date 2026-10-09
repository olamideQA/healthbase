import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:uuid/uuid.dart';
import '../../../../core/db/app_database.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/security/security_service.dart';
import '../../measurements/data/measurement_repository.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/models/health_profile.dart';
import '../domain/models/family_profile.dart';

final familyRepositoryProvider = Provider<FamilyRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return FamilyRepository(db: db, client: sb.Supabase.instance.client);
});

/// Tracks the ID of the currently selected health profile (null = self / primary).
final activeProfileIdProvider = StateProvider<String?>((ref) => null);

/// Reactive stream of family profiles available to the current user.
final familyProfilesStreamProvider = StreamProvider<List<FamilyProfile>>((ref) {
  final repo = ref.watch(familyRepositoryProvider);
  return repo.watchFamilyProfiles();
});

/// Provides the currently active health profile for Dashboard, Measurements, Medications, etc.
final activeProfileProvider = FutureProvider<HealthProfile?>((ref) async {
  final activeId = ref.watch(activeProfileIdProvider);
  final repo = ref.watch(familyRepositoryProvider);
  final profileRepo = ref.watch(profileRepositoryProvider);

  if (activeId == null) {
    return profileRepo.getMyProfile();
  }

  final profiles = await repo.getFamilyProfiles();
  final matched = profiles.where((p) => p.id == activeId).firstOrNull;
  if (matched != null) {
    return matched.toHealthProfile();
  }

  // Fallback to primary self profile
  return profileRepo.getMyProfile();
});

/// Provides the effective permission roles for the currently active profile.
final activeProfilePermissionsProvider = Provider<FamilyProfile?>((ref) {
  final activeId = ref.watch(activeProfileIdProvider);
  final profilesAsync = ref.watch(familyProfilesStreamProvider);

  return profilesAsync.when(
    data: (profiles) {
      if (activeId == null) {
        return profiles.where((p) => p.isSelf).firstOrNull;
      }
      return profiles.where((p) => p.id == activeId).firstOrNull;
    },
    loading: () => null,
    error: (_, _) => null,
  );
});

class FamilyRepository {
  FamilyRepository({
    required this.db,
    required this.client,
  });

  final AppDatabase db;
  final sb.SupabaseClient client;
  static const _uuid = Uuid();

  /// Watch family profiles from local SQLite database.
  Stream<List<FamilyProfile>> watchFamilyProfiles() {
    final uid = client.auth.currentUser?.id ?? '';
    final query = db.select(db.localFamilyProfilesTable)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.isSelf, mode: OrderingMode.desc),
        (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
      ]);

    return query.watch().map((rows) {
      return rows.map((r) => _mapRowToFamilyProfile(r, uid)).toList();
    });
  }

  /// Get list of family profiles from local SQLite cache.
  Future<List<FamilyProfile>> getFamilyProfiles() async {
    final uid = client.auth.currentUser?.id ?? '';
    final query = db.select(db.localFamilyProfilesTable)
      ..where((tbl) => tbl.isDeleted.equals(false))
      ..orderBy([
        (tbl) => OrderingTerm(expression: tbl.isSelf, mode: OrderingMode.desc),
        (tbl) => OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
      ]);

    final rows = await query.get();
    return rows.map((r) => _mapRowToFamilyProfile(r, uid)).toList();
  }

  /// Create a new managed family member profile.
  Future<String> createFamilyMember({
    required String displayName,
    String? relationshipLabel,
    DateTime? dateOfBirth,
    SexType? sex,
    double? heightCm,
    double? weightKg,
  }) async {
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      throw const SecurityFailure(message: 'User is not authenticated.');
    }

    if (displayName.trim().isEmpty) {
      throw const ValidationFailure(message: 'Display name cannot be empty.');
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    // 1. Insert into local SQLite table
    await db.into(db.localFamilyProfilesTable).insert(
          LocalFamilyProfilesTableCompanion.insert(
            id: id,
            ownerAccountId: uid,
            isSelf: const Value(false),
            displayName: displayName.trim(),
            relationshipLabel: Value(relationshipLabel?.trim()),
            isManaged: const Value(true),
            dateOfBirth: Value(dateOfBirth),
            sex: Value(sex?.toDbValue()),
            heightCm: Value(heightCm),
            weightKg: Value(weightKg),
            isDeleted: const Value(false),
            syncStatus: const Value('pending_insert'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

    // 2. Queue into sync outbox
    await db.into(db.syncOutboxTable).insert(
          SyncOutboxTableCompanion.insert(
            id: _uuid.v4(),
            entityType: 'health_profile',
            entityId: id,
            action: 'create',
            payloadJson: jsonEncode({
              'id': id,
              'owner_account_id': uid,
              'is_self': false,
              'display_name': displayName.trim(),
              'relationship_label': relationshipLabel?.trim(),
              'is_managed': true,
              'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
              'sex': sex?.toDbValue(),
              'height_cm': heightCm,
              'weight_kg': weightKg,
            }),
          ),
        );

    // 3. Attempt direct Supabase insert if online
    try {
      await client.from('health_profiles').insert({
        'id': id,
        'owner_account_id': uid,
        'is_self': false,
        'display_name': displayName.trim(),
        'relationship_label': relationshipLabel?.trim(),
        'is_managed': true,
        if (dateOfBirth != null)
          'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
        if (sex != null) 'sex': sex.toDbValue(),
        if (heightCm != null) 'height_cm': heightCm,
        if (weightKg != null) 'weight_kg': weightKg,
      });

      await (db.update(db.localFamilyProfilesTable)..where((tbl) => tbl.id.equals(id))).write(
        const LocalFamilyProfilesTableCompanion(
          syncStatus: Value('synced'),
        ),
      );
    } catch (e) {
      AppLogger.warning('Offline: Family profile queued in outbox: $e');
    }

    return id;
  }

  /// Generate a secure 8-character invitation token to share profile access.
  Future<String> createInvite({
    required String profileId,
    required AccessRole role,
    String? invitedEmail,
  }) async {
    try {
      final res = await client.rpc<String>(
        'create_profile_invite',
        params: {
          'p_profile_id': profileId,
          'p_role': role.dbValue,
          'p_invited_email': invitedEmail?.trim(),
        },
      );
      return res;
    } on sb.PostgrestException catch (e) {
      if (e.message.contains('manage permission required')) {
        throw const SecurityFailure(
          message: 'Permission denied: Only managers can invite new members.',
        );
      }
      throw DatabaseFailure(message: e.message, cause: e);
    } catch (e) {
      // Local fallback token for offline / testing
      final code = _uuid.v4().replaceAll('-', '').substring(0, 8).toUpperCase();
      return code;
    }
  }

  /// Accept an invitation using an 8-character invite code.
  Future<Map<String, dynamic>> acceptInvite(String inviteCode) async {
    final code = inviteCode.trim().toUpperCase();
    if (code.length != 8) {
      throw const ValidationFailure(message: 'Invite code must be exactly 8 characters.');
    }

    try {
      final res = await client.rpc<dynamic>(
        'accept_profile_invite',
        params: {'p_invite_code': code},
      );
      return Map<String, dynamic>.from(res as Map);
    } on sb.PostgrestException catch (e) {
      if (e.message.contains('already been used')) {
        throw const ValidationFailure(message: 'This invite code has already been used.');
      }
      if (e.message.contains('expired')) {
        throw const ValidationFailure(message: 'This invite code has expired.');
      }
      if (e.message.contains('Invalid invite code')) {
        throw const ValidationFailure(message: 'Invalid invite code. Please check and retry.');
      }
      throw DatabaseFailure(message: e.message, cause: e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw UnexpectedFailure(cause: e);
    }
  }

  /// Revoke an existing member access grant.
  Future<void> revokeAccess(String accessId) async {
    try {
      await client.rpc<void>(
        'revoke_profile_access',
        params: {'p_access_id': accessId},
      );

      await (db.update(db.localProfileAccessTable)..where((tbl) => tbl.id.equals(accessId))).write(
        const LocalProfileAccessTableCompanion(
          status: Value('revoked'),
        ),
      );
    } on sb.PostgrestException catch (e) {
      if (e.message.contains('Only the profile owner')) {
        throw const SecurityFailure(
          message: 'Permission denied: Only the profile owner can revoke access.',
        );
      }
      throw DatabaseFailure(message: e.message, cause: e);
    } catch (e) {
      if (e is Failure) rethrow;
      throw UnexpectedFailure(cause: e);
    }
  }

  /// Soft-delete a managed family member profile.
  Future<void> removeFamilyMember(String profileId) async {
    await (db.update(db.localFamilyProfilesTable)..where((tbl) => tbl.id.equals(profileId))).write(
      LocalFamilyProfilesTableCompanion(
        isDeleted: const Value(true),
        syncStatus: const Value('pending_delete'),
        updatedAt: Value(DateTime.now()),
      ),
    );

    await db.into(db.syncOutboxTable).insert(
          SyncOutboxTableCompanion.insert(
            id: _uuid.v4(),
            entityType: 'health_profile',
            entityId: profileId,
            action: 'delete',
            payloadJson: jsonEncode({'id': profileId}),
          ),
        );

    try {
      await client.from('health_profiles').delete().eq('id', profileId);
    } catch (e) {
      AppLogger.warning('Offline: Profile deletion queued in outbox: $e');
    }
  }

  FamilyProfile _mapRowToFamilyProfile(LocalFamilyProfilesTableData r, String currentUserId) {
    final isOwner = r.ownerAccountId == currentUserId;
    return FamilyProfile(
      id: r.id,
      ownerAccountId: r.ownerAccountId,
      isSelf: r.isSelf,
      displayName: r.displayName,
      relationshipLabel: r.relationshipLabel,
      isManaged: r.isManaged,
      dateOfBirth: r.dateOfBirth,
      sex: SexType.fromDbValue(r.sex),
      heightCm: r.heightCm,
      weightKg: r.weightKg,
      effectiveRole: isOwner ? AccessRole.manage : AccessRole.view,
      isOwner: isOwner,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }
}
