import 'package:flutter/foundation.dart';
import '../../../measurements/domain/models/measurement.dart';

/// Frequency schedules for medication doses.
enum MedicationFrequency {
  daily('Once Daily', 'daily'),
  twiceDaily('Twice Daily', 'twice_daily'),
  threeTimesDaily('Three Times Daily', 'three_times_daily'),
  asNeeded('As Needed (PRN)', 'as_needed'),
  weekly('Weekly', 'weekly');

  const MedicationFrequency(this.displayName, this.dbValue);

  final String displayName;
  final String dbValue;

  static MedicationFrequency fromDbValue(String value) => switch (value) {
        'daily' => MedicationFrequency.daily,
        'twice_daily' => MedicationFrequency.twiceDaily,
        'three_times_daily' => MedicationFrequency.threeTimesDaily,
        'as_needed' => MedicationFrequency.asNeeded,
        'weekly' => MedicationFrequency.weekly,
        _ => MedicationFrequency.daily,
      };
}

/// Status of a scheduled medication dose event.
enum MedicationEventStatus {
  taken('Taken', 'taken'),
  missed('Missed', 'missed'),
  notRecorded('Not Recorded', 'not_recorded');

  const MedicationEventStatus(this.displayName, this.dbValue);

  final String displayName;
  final String dbValue;

  static MedicationEventStatus fromDbValue(String value) => switch (value) {
        'taken' => MedicationEventStatus.taken,
        'missed' => MedicationEventStatus.missed,
        'not_recorded' => MedicationEventStatus.notRecorded,
        _ => MedicationEventStatus.notRecorded,
      };
}

/// User-managed medication record.
///
/// SAFETY PRINCIPLE: HealthBase NEVER calculates or recommends medication dosage.
/// The user enters the exact instructions received from their healthcare provider.
@immutable
class Medication {
  const Medication({
    required this.id,
    required this.profileId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.reminderTime,
    this.notes,
    this.isActive = true,
    this.isDeleted = false,
    this.syncStatus = SyncStatus.synced,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final String name;

  /// User-entered dosage text (e.g., "10mg once daily in the morning with water").
  /// Never calculated or modified by the application.
  final String dosage;

  final MedicationFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String? reminderTime; // "HH:mm" formatted
  final String? notes;
  final bool isActive;
  final bool isDeleted;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool isCurrentlyActive(DateTime now) {
    if (!isActive || isDeleted) return false;
    if (now.isBefore(startDate)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    return true;
  }
}

/// An adherence logging event for a medication dose.
@immutable
class MedicationEvent {
  const MedicationEvent({
    required this.id,
    required this.profileId,
    required this.medicationId,
    required this.scheduledTime,
    this.recordedAt,
    required this.status,
    this.notes,
    this.syncStatus = SyncStatus.synced,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String profileId;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? recordedAt;
  final MedicationEventStatus status;
  final String? notes;
  final SyncStatus syncStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Medication adherence statistics.
///
/// Strictly distinguishes between taken, missed, and not recorded.
/// Never assumes "not recorded" means missed.
@immutable
class MedicationAdherenceStats {
  const MedicationAdherenceStats({
    required this.scheduledCount,
    required this.takenCount,
    required this.missedCount,
    required this.notRecordedCount,
  });

  final int scheduledCount;
  final int takenCount;
  final int missedCount;
  final int notRecordedCount;

  /// Adherence calculated strictly from explicitly recorded doses:
  /// taken / (taken + missed)
  double? get recordedAdherenceRate {
    final recordedTotal = takenCount + missedCount;
    if (recordedTotal == 0) return null;
    return (takenCount / recordedTotal) * 100.0;
  }

  /// Adherence against all scheduled doses:
  /// taken / scheduled
  double? get overallScheduledRate {
    if (scheduledCount == 0) return null;
    return (takenCount / scheduledCount) * 100.0;
  }

  factory MedicationAdherenceStats.fromEvents({
    required int scheduledCount,
    required List<MedicationEvent> events,
  }) {
    int taken = 0;
    int missed = 0;
    int notRecorded = 0;

    for (final e in events) {
      switch (e.status) {
        case MedicationEventStatus.taken:
          taken++;
          break;
        case MedicationEventStatus.missed:
          missed++;
          break;
        case MedicationEventStatus.notRecorded:
          notRecorded++;
          break;
      }
    }

    // Account for scheduled events that have no log entry yet
    final unlogged = scheduledCount - events.length;
    if (unlogged > 0) {
      notRecorded += unlogged;
    }

    return MedicationAdherenceStats(
      scheduledCount: scheduledCount,
      takenCount: taken,
      missedCount: missed,
      notRecordedCount: notRecorded,
    );
  }
}
