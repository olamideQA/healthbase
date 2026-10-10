/// Medical safety disclaimers, clinical boundary strings, and emergency indicators.
/// 
/// All health-related copy and disclaimers are centralized here to enable
/// systematic review and avoid scattered or contradictory medical claims in UI widgets.
class SafetyBoundaries {
  const SafetyBoundaries._();

  /// Primary disclaimer presented across onboarding, daily checks, and reports.
  static const String generalDisclaimer =
      'HealthBase is a personal health-monitoring and record-keeping tool. '
      'It does not diagnose medical conditions, prescribe medication, or provide clinical treatment advice.';

  /// Statement shown when personal baselines are displayed.
  static const String baselineExplanation =
      'Your recent personal range reflects your own historical measurements over time. '
      'It is a statistical baseline and does not represent a clinical diagnosis or general medical normal range.';

  /// Statement shown on the camera pulse feature.
  static const String cameraPulseDisclaimer =
      'This pulse estimate is for personal tracking purposes only and is not a clinical medical measurement. '
      'It cannot diagnose arrhythmias, heart disease, or cardiovascular conditions.';

  /// Statement shown on trends and charts views.
  static const String trendsDisclaimer =
      'Trend lines illustrate statistical progression across your personal logged entries. '
      'They do not constitute a clinical disease assessment or prognostic medical evaluation.';

  /// Statement shown on medication tracking views.
  static const String medicationsDisclaimer =
      'HealthBase records your medication schedule for personal tracking. '
      'It does not analyze pharmacological contraindications or replace professional prescription guidance.';

  /// Statement shown on PDF reports and summary exports.
  static const String reportsDisclaimer =
      'This summary is compiled from self-recorded measurements to assist in discussions with your physician. '
      'It is not a formal clinical diagnostic document or hospital lab result.';

  /// Emergency red-flag symptoms that require immediate medical attention.
  static const List<String> urgentSymptoms = <String>[
    'Chest discomfort or pain',
    'Severe shortness of breath',
    'Sudden numbness or weakness',
    'Difficulty speaking',
    'Severe sudden headache',
    'Loss of consciousness',
  ];

  /// Warning message displayed when red-flag symptoms are selected.
  static const String emergencyWarningMessage =
      'If you are experiencing chest discomfort, difficulty breathing, or severe sudden symptoms, '
      'please seek emergency medical care immediately or call your local emergency number.';

  /// Plausibility ranges for basic health inputs to prevent physically impossible entries.
  /// 
  /// NOTE: These are NOT clinical diagnostic boundaries; they are physical plausibility guards.
  static const double minHeartRateBpm = 25.0;
  static const double maxHeartRateBpm = 250.0;

  static const double minSystolicMmHg = 40.0;
  static const double maxSystolicMmHg = 300.0;

  static const double minDiastolicMmHg = 30.0;
  static const double maxDiastolicMmHg = 200.0;

  static const double minTemperatureCelsius = 30.0;
  static const double maxTemperatureCelsius = 45.0;

  static const double minWeightKg = 1.0;
  static const double maxWeightKg = 400.0;

  static const double minGlucoseMmol = 0.5;
  static const double maxGlucoseMmol = 45.0;
}
