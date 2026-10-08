import 'package:flutter/foundation.dart';

enum SexType {
  female,
  male,
  intersex,
  preferNotToSay;

  String toDbValue() {
    return switch (this) {
      SexType.female => 'female',
      SexType.male => 'male',
      SexType.intersex => 'intersex',
      SexType.preferNotToSay => 'prefer_not_to_say',
    };
  }

  static SexType? fromDbValue(String? value) {
    if (value == null) return null;
    return switch (value) {
      'female' => SexType.female,
      'male' => SexType.male,
      'intersex' => SexType.intersex,
      'prefer_not_to_say' => SexType.preferNotToSay,
      _ => null,
    };
  }

  String get displayName => switch (this) {
        SexType.female => 'Female',
        SexType.male => 'Male',
        SexType.intersex => 'Intersex',
        SexType.preferNotToSay => 'Prefer not to say',
      };
}

enum UnitSystem {
  metric,
  imperial;

  String toDbValue() => name;

  static UnitSystem fromDbValue(String? value) {
    if (value == 'imperial') return UnitSystem.imperial;
    return UnitSystem.metric;
  }
}

/// Represents a HealthBase user or family health profile.
@immutable
class HealthProfile {
  const HealthProfile({
    required this.id,
    required this.ownerAccountId,
    required this.isSelf,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.dateOfBirth,
    this.sex,
    this.heightCm,
    this.weightKg,
    this.preferredUnits = UnitSystem.metric,
    this.onboardingCompletedAt,
  });

  final String id;
  final String ownerAccountId;
  final bool isSelf;
  final String? displayName;
  final DateTime? dateOfBirth;
  final SexType? sex;
  final double? heightCm;
  final double? weightKg;
  final UnitSystem preferredUnits;
  final DateTime? onboardingCompletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOnboardingCompleted => onboardingCompletedAt != null;

  factory HealthProfile.fromJson(
    Map<String, dynamic> json, {
    UnitSystem preferredUnits = UnitSystem.metric,
  }) {
    return HealthProfile(
      id: json['id'] as String,
      ownerAccountId: json['owner_account_id'] as String,
      isSelf: json['is_self'] as bool? ?? false,
      displayName: json['display_name'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      sex: SexType.fromDbValue(json['sex'] as String?),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      preferredUnits: preferredUnits,
      onboardingCompletedAt: json['onboarding_completed_at'] != null
          ? DateTime.tryParse(json['onboarding_completed_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      if (displayName != null) 'display_name': displayName!.trim(),
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth!.toIso8601String().split('T').first,
      if (sex != null) 'sex': sex!.toDbValue(),
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (onboardingCompletedAt != null)
        'onboarding_completed_at': onboardingCompletedAt!.toIso8601String(),
    };
  }

  HealthProfile copyWith({
    String? displayName,
    DateTime? dateOfBirth,
    SexType? sex,
    double? heightCm,
    double? weightKg,
    UnitSystem? preferredUnits,
    DateTime? onboardingCompletedAt,
  }) {
    return HealthProfile(
      id: id,
      ownerAccountId: ownerAccountId,
      isSelf: isSelf,
      displayName: displayName ?? this.displayName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
