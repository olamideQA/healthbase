/// Pure utilities for unit conversions and formatting.
/// 
/// Canonical database storage units are ALWAYS:
/// - Height: centimeters (cm)
/// - Weight: kilograms (kg)
/// - Temperature: Celsius (°C)
/// - Blood glucose: mmol/L
/// - Blood pressure: mmHg
class UnitConverter {
  const UnitConverter._();

  static const double _cmPerInch = 2.54;
  static const double _lbsPerKg = 2.20462262185;

  /// Convert kilograms to pounds (lbs).
  static double kgToLbs(double kg) {
    return kg * _lbsPerKg;
  }

  /// Convert pounds (lbs) to kilograms.
  static double lbsToKg(double lbs) {
    return lbs / _lbsPerKg;
  }

  /// Convert centimeters to total inches.
  static double cmToInches(double cm) {
    return cm / _cmPerInch;
  }

  /// Convert centimeters to a breakdown of feet and remaining inches.
  static ({int feet, int inches}) cmToFeetAndInches(double cm) {
    final totalInches = (cm / _cmPerInch).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return (feet: feet, inches: inches);
  }

  /// Convert feet and inches to centimeters.
  static double feetAndInchesToCm(int feet, int inches) {
    final totalInches = (feet * 12) + inches;
    return totalInches * _cmPerInch;
  }

  /// Convert Celsius to Fahrenheit.
  static double celsiusToFahrenheit(double c) {
    return (c * 9.0 / 5.0) + 32.0;
  }

  /// Convert Fahrenheit to Celsius.
  static double fahrenheitToCelsius(double f) {
    return (f - 32.0) * 5.0 / 9.0;
  }

  /// Format height for display based on preference.
  static String formatHeight(double? heightCm, {required bool isMetric}) {
    if (heightCm == null) return '--';
    if (isMetric) {
      return '${heightCm.toStringAsFixed(1)} cm';
    }
    final broken = cmToFeetAndInches(heightCm);
    return "${broken.feet}'${broken.inches}\"";
  }

  /// Format weight for display based on preference.
  static String formatWeight(double? weightKg, {required bool isMetric}) {
    if (weightKg == null) return '--';
    if (isMetric) {
      return '${weightKg.toStringAsFixed(1)} kg';
    }
    final lbs = kgToLbs(weightKg);
    return '${lbs.toStringAsFixed(1)} lbs';
  }
}
