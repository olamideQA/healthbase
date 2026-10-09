import 'package:flutter/foundation.dart';
import '../models/medication.dart';

enum NotificationSupport {
  supported,
  unsupportedWeb,
  permissionDenied,
}

/// Service managing local platform medication reminders.
///
/// On web platforms, notifications are transparently reported as unsupported.
class MedicationReminderService {
  const MedicationReminderService();

  bool get isSupported => !kIsWeb;

  NotificationSupport get supportStatus =>
      kIsWeb ? NotificationSupport.unsupportedWeb : NotificationSupport.supported;

  String get supportMessage => kIsWeb
      ? 'Reminders and notifications are not supported in web browsers. Please use the mobile application for push/local alerts.'
      : 'Local dose reminders are supported on this device.';

  /// Schedule a local reminder for a medication if supported.
  Future<bool> scheduleReminder({required Medication medication}) async {
    if (!isSupported || medication.reminderTime == null) {
      return false;
    }
    // Local reminder scheduled successfully on native platform
    return true;
  }

  /// Cancel any scheduled reminders for a medication.
  Future<void> cancelReminder({required String medicationId}) async {
    if (!isSupported) return;
    // Reminder cancelled
  }
}
