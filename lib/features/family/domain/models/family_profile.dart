import 'package:flutter/foundation.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';

/// Explicit permission roles for shared family profiles.
enum AccessRole {
  view('View Only', 'view', 'Can view measurements, daily checks, trends, and medications.'),
  contribute('Contributor', 'contribute', 'Can view and record measurements, daily checks, and medication doses.'),
  manage('Manager', 'manage', 'Full control: can view, log data, edit profile, and manage sharing.');

  const AccessRole(this.displayName, this.dbValue, this.description);

  final String displayName;
  final String dbValue;
  final String description;

  static AccessRole fromDbValue(String value) => switch (value) {
        'view' => AccessRole.view,
        'contribute' => AccessRole.contribute,
        'manage' => AccessRole.manage,
        _ => AccessRole.view,
      };

  int get rank => switch (this) {
        AccessRole.view => 1,
        AccessRole.contribute => 2,
        AccessRole.manage => 3,
      };

  bool satisfies(AccessRole minRole) => rank >= minRole.rank;
}

/// Lifecycle status for profile sharing grants.
enum AccessStatus {
  pending('Pending', 'pending'),
  active('Active', 'active'),
  revoked('Revoked', 'revoked');

  const AccessStatus(this.displayName, this.dbValue);

  final String displayName;
  final String dbValue;

  static AccessStatus fromDbValue(String value) => switch (value) {
        'pending' => AccessStatus.pending,
        'active' => AccessStatus.active,
        'revoked' => AccessStatus.revoked,
        _ => AccessStatus.pending,
      };
}

/// Suggested common relationship options (strictly without biological assumptions).
class RelationshipCategory {
  RelationshipCategory._();

  static const List<String> commonOptions = [
    'Mum',
    'Dad',
    'Spouse',
    'Partner',
    'Grandparent',
    'Child',
    'Sibling',
    'Dependent',
    'Friend',
    'Other',
  ];

  static const String clinicalDisclaimer =
      'HealthBase supports all families and does not assume biological relationships. '
      'Labels are customizable for your identification purposes.';
}

/// A family member's health profile with user-effective permission scope.
@immutable
class FamilyProfile {
  const FamilyProfile({
    required this.id,
    required this.ownerAccountId,
    required this.isSelf,
    required this.displayName,
    this.relationshipLabel,
    this.isManaged = true,
    this.dateOfBirth,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.effectiveRole = AccessRole.manage,
    this.isOwner = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String ownerAccountId;
  final bool isSelf;
  final String displayName;
  final String? relationshipLabel;
  final bool isManaged;
  final DateTime? dateOfBirth;
  final SexType? sex;
  final double? heightCm;
  final double? weightKg;
  final AccessRole effectiveRole;
  final bool isOwner;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get canView => isOwner || effectiveRole.satisfies(AccessRole.view);
  bool get canContribute => isOwner || effectiveRole.satisfies(AccessRole.contribute);
  bool get canManage => isOwner || effectiveRole.satisfies(AccessRole.manage);

  String get relationshipDisplay {
    if (isSelf) return 'Self (Primary)';
    if (relationshipLabel != null && relationshipLabel!.trim().isNotEmpty) {
      return relationshipLabel!.trim();
    }
    return 'Family Member';
  }

  factory FamilyProfile.fromJson(
    Map<String, dynamic> json, {
    required String currentUserId,
  }) {
    final ownerId = json['owner_account_id'] as String;
    final isSelf = json['is_self'] as bool? ?? false;
    final isOwner = ownerId == currentUserId;

    AccessRole role = AccessRole.manage;
    if (!isOwner && json.containsKey('granted_role')) {
      role = AccessRole.fromDbValue(json['granted_role'] as String);
    } else if (!isOwner) {
      role = AccessRole.view;
    }

    return FamilyProfile(
      id: json['id'] as String,
      ownerAccountId: ownerId,
      isSelf: isSelf,
      displayName: json['display_name'] as String? ?? 'Family Member',
      relationshipLabel: json['relationship_label'] as String?,
      isManaged: json['is_managed'] as bool? ?? true,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      sex: SexType.fromDbValue(json['sex'] as String?),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      effectiveRole: role,
      isOwner: isOwner,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  HealthProfile toHealthProfile() {
    return HealthProfile(
      id: id,
      ownerAccountId: ownerAccountId,
      isSelf: isSelf,
      displayName: displayName,
      dateOfBirth: dateOfBirth,
      sex: sex,
      heightCm: heightCm,
      weightKg: weightKg,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// An explicit access grant record shared between accounts.
@immutable
class ProfileAccessGrant {
  const ProfileAccessGrant({
    required this.id,
    required this.profileId,
    required this.granteeAccountId,
    required this.role,
    required this.status,
    this.granteeEmail,
    this.grantedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final String granteeAccountId;
  final AccessRole role;
  final AccessStatus status;
  final String? granteeEmail;
  final String? grantedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ProfileAccessGrant.fromJson(Map<String, dynamic> json) {
    return ProfileAccessGrant(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      granteeAccountId: json['grantee_account_id'] as String,
      role: AccessRole.fromDbValue(json['role'] as String),
      status: AccessStatus.fromDbValue(json['status'] as String),
      granteeEmail: json['grantee_email'] as String?,
      grantedBy: json['granted_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// An active or pending share invitation token.
@immutable
class ProfileInvite {
  const ProfileInvite({
    required this.id,
    required this.profileId,
    required this.role,
    required this.inviteCode,
    this.invitedEmail,
    required this.createdBy,
    required this.expiresAt,
    required this.isUsed,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final AccessRole role;
  final String inviteCode;
  final String? invitedEmail;
  final String createdBy;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  factory ProfileInvite.fromJson(Map<String, dynamic> json) {
    return ProfileInvite(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      role: AccessRole.fromDbValue(json['role'] as String),
      inviteCode: json['invite_code'] as String,
      invitedEmail: json['invited_email'] as String?,
      createdBy: json['created_by'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      isUsed: json['is_used'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
