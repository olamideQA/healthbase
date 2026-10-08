import 'package:flutter/foundation.dart';
import '../../../../core/utils/unit_converter.dart';
import '../../../profile/domain/models/health_profile.dart';

enum MeasurementType {
  heartRate,
  bloodPressure,
  temperature,
  weight,
  bloodGlucose;

  String toDbValue() => switch (this) {
        MeasurementType.heartRate => 'heart_rate',
        MeasurementType.bloodPressure => 'blood_pressure',
        MeasurementType.temperature => 'temperature',
        MeasurementType.weight => 'weight',
        MeasurementType.bloodGlucose => 'blood_glucose',
      };

  static MeasurementType fromDbValue(String value) => switch (value) {
        'heart_rate' => MeasurementType.heartRate,
        'blood_pressure' => MeasurementType.bloodPressure,
        'temperature' => MeasurementType.temperature,
        'weight' => MeasurementType.weight,
        'blood_glucose' => MeasurementType.bloodGlucose,
        _ => throw ArgumentError('Unknown measurement type: $value'),
      };

  String get displayName => switch (this) {
        MeasurementType.heartRate => 'Heart Rate',
        MeasurementType.bloodPressure => 'Blood Pressure',
        MeasurementType.temperature => 'Body Temperature',
        MeasurementType.weight => 'Body Weight',
        MeasurementType.bloodGlucose => 'Blood Glucose',
      };
}

enum MeasurementSource {
  manual,
  camera,
  device,
  importSource;

  String toDbValue() => switch (this) {
        MeasurementSource.manual => 'manual',
        MeasurementSource.camera => 'camera',
        MeasurementSource.device => 'device',
        MeasurementSource.importSource => 'import',
      };

  static MeasurementSource fromDbValue(String value) => switch (value) {
        'manual' => MeasurementSource.manual,
        'camera' => MeasurementSource.camera,
        'device' => MeasurementSource.device,
        'import' => MeasurementSource.importSource,
        _ => MeasurementSource.manual,
      };

  String get displayName => switch (this) {
        MeasurementSource.manual => 'Manual Entry',
        MeasurementSource.camera => 'Camera Pulse (PPG)',
        MeasurementSource.device => 'Connected Device',
        MeasurementSource.importSource => 'Imported File',
      };
}

enum MeasurementProvenance {
  measured,
  manuallyEntered,
  estimated;

  String toDbValue() => switch (this) {
        MeasurementProvenance.measured => 'measured',
        MeasurementProvenance.manuallyEntered => 'manually_entered',
        MeasurementProvenance.estimated => 'estimated',
      };

  static MeasurementProvenance fromDbValue(String value) => switch (value) {
        'measured' => MeasurementProvenance.measured,
        'manually_entered' => MeasurementProvenance.manuallyEntered,
        'estimated' => MeasurementProvenance.estimated,
        _ => MeasurementProvenance.manuallyEntered,
      };

  String get displayName => switch (this) {
        MeasurementProvenance.measured => 'Measured',
        MeasurementProvenance.manuallyEntered => 'Manually Entered',
        MeasurementProvenance.estimated => 'Estimated',
      };
}

enum SyncStatus {
  synced,
  pendingInsert,
  pendingUpdate,
  pendingDelete,
  syncError;

  String toDbValue() => name;

  static SyncStatus fromDbValue(String? value) => switch (value) {
        'pendingInsert' || 'pending_insert' => SyncStatus.pendingInsert,
        'pendingUpdate' || 'pending_update' => SyncStatus.pendingUpdate,
        'pendingDelete' || 'pending_delete' => SyncStatus.pendingDelete,
        'syncError' || 'sync_error' => SyncStatus.syncError,
        _ => SyncStatus.synced,
      };
}

/// Represents a single recorded physiological metric in HealthBase.
@immutable
class Measurement {
  const Measurement({
    required this.id,
    required this.profileId,
    required this.type,
    this.heartRateBpm,
    this.systolicMmhg,
    this.diastolicMmhg,
    this.pulseBpm,
    this.temperatureCelsius,
    this.weightKg,
    this.glucoseMmolL,
    this.source = MeasurementSource.manual,
    this.provenance = MeasurementProvenance.manuallyEntered,
    this.quality,
    required this.recordedAt,
    this.recordedUtcOffset = 0,
    this.notes,
    this.dailyCheckId,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.synced,
    this.version = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final MeasurementType type;

  // Canonical metrics
  final double? heartRateBpm;
  final double? systolicMmhg;
  final double? diastolicMmhg;
  final double? pulseBpm;
  final double? temperatureCelsius;
  final double? weightKg;
  final double? glucoseMmolL;

  // Provenance & context
  final MeasurementSource source;
  final MeasurementProvenance provenance;
  final Map<String, dynamic>? quality;
  final DateTime recordedAt;
  final int recordedUtcOffset;
  final String? notes;
  final String? dailyCheckId;

  // Sync state
  final bool isDeleted;
  final SyncStatus syncStatus;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Returns the primary numerical value formatted according to user unit preference.
  String formattedPrimaryValue(UnitSystem units) {
    return switch (type) {
      MeasurementType.heartRate =>
        heartRateBpm != null ? heartRateBpm!.round().toString() : '--',
      MeasurementType.bloodPressure =>
        (systolicMmhg != null && diastolicMmhg != null)
            ? '${systolicMmhg!.round()}/${diastolicMmhg!.round()}'
            : '--',
      MeasurementType.temperature => temperatureCelsius != null
          ? (units == UnitSystem.metric
              ? '${temperatureCelsius!.toStringAsFixed(1)} °C'
              : '${UnitConverter.celsiusToFahrenheit(temperatureCelsius!).toStringAsFixed(1)} °F')
          : '--',
      MeasurementType.weight =>
        UnitConverter.formatWeight(weightKg, isMetric: units == UnitSystem.metric),
      MeasurementType.bloodGlucose => glucoseMmolL != null
          ? (units == UnitSystem.metric
              ? '${glucoseMmolL!.toStringAsFixed(1)} mmol/L'
              : '${(glucoseMmolL! * 18.0182).toStringAsFixed(0)} mg/dL')
          : '--',
    };
  }

  /// Returns the canonical unit label for this measurement type.
  String unitLabel(UnitSystem units) {
    return switch (type) {
      MeasurementType.heartRate => 'bpm',
      MeasurementType.bloodPressure => 'mmHg',
      MeasurementType.temperature => units == UnitSystem.metric ? '°C' : '°F',
      MeasurementType.weight => units == UnitSystem.metric ? 'kg' : 'lbs',
      MeasurementType.bloodGlucose => units == UnitSystem.metric ? 'mmol/L' : 'mg/dL',
    };
  }

  factory Measurement.fromJson(Map<String, dynamic> json) {
    return Measurement(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      type: MeasurementType.fromDbValue(json['type'] as String),
      heartRateBpm: (json['heart_rate_bpm'] as num?)?.toDouble(),
      systolicMmhg: (json['systolic_mmhg'] as num?)?.toDouble(),
      diastolicMmhg: (json['diastolic_mmhg'] as num?)?.toDouble(),
      pulseBpm: (json['pulse_bpm'] as num?)?.toDouble(),
      temperatureCelsius: (json['temperature_celsius'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      glucoseMmolL: (json['glucose_mmol_l'] as num?)?.toDouble(),
      source: json['source'] != null
          ? MeasurementSource.fromDbValue(json['source'] as String)
          : MeasurementSource.manual,
      provenance: json['provenance'] != null
          ? MeasurementProvenance.fromDbValue(json['provenance'] as String)
          : MeasurementProvenance.manuallyEntered,
      quality: json['quality'] as Map<String, dynamic>?,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      recordedUtcOffset: json['recorded_utc_offset'] as int? ?? 0,
      notes: json['notes'] as String?,
      dailyCheckId: json['daily_check_id'] as String?,
      isDeleted: json['is_deleted'] as bool? ?? false,
      syncStatus: SyncStatus.synced,
      version: json['version'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toRemoteJson() {
    return <String, dynamic>{
      'id': id,
      'profile_id': profileId,
      'type': type.toDbValue(),
      if (heartRateBpm != null) 'heart_rate_bpm': heartRateBpm,
      if (systolicMmhg != null) 'systolic_mmhg': systolicMmhg,
      if (diastolicMmhg != null) 'diastolic_mmhg': diastolicMmhg,
      if (pulseBpm != null) 'pulse_bpm': pulseBpm,
      if (temperatureCelsius != null) 'temperature_celsius': temperatureCelsius,
      if (weightKg != null) 'weight_kg': weightKg,
      if (glucoseMmolL != null) 'glucose_mmol_l': glucoseMmolL,
      'source': source.toDbValue(),
      'provenance': provenance.toDbValue(),
      if (quality != null) 'quality': quality,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
      'recorded_utc_offset': recordedUtcOffset,
      if (notes != null) 'notes': notes,
      if (dailyCheckId != null) 'daily_check_id': dailyCheckId,
      'is_deleted': isDeleted,
    };
  }

  Measurement copyWith({
    String? id,
    String? profileId,
    MeasurementType? type,
    double? heartRateBpm,
    double? systolicMmhg,
    double? diastolicMmhg,
    double? pulseBpm,
    double? temperatureCelsius,
    double? weightKg,
    double? glucoseMmolL,
    MeasurementSource? source,
    MeasurementProvenance? provenance,
    Map<String, dynamic>? quality,
    DateTime? recordedAt,
    int? recordedUtcOffset,
    String? notes,
    String? dailyCheckId,
    bool? isDeleted,
    SyncStatus? syncStatus,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Measurement(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      type: type ?? this.type,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      systolicMmhg: systolicMmhg ?? this.systolicMmhg,
      diastolicMmhg: diastolicMmhg ?? this.diastolicMmhg,
      pulseBpm: pulseBpm ?? this.pulseBpm,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      weightKg: weightKg ?? this.weightKg,
      glucoseMmolL: glucoseMmolL ?? this.glucoseMmolL,
      source: source ?? this.source,
      provenance: provenance ?? this.provenance,
      quality: quality ?? this.quality,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedUtcOffset: recordedUtcOffset ?? this.recordedUtcOffset,
      notes: notes ?? this.notes,
      dailyCheckId: dailyCheckId ?? this.dailyCheckId,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
