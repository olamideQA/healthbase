import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter Pure Math Tests', () {
    test('kg to lbs and lbs to kg roundtrips accurately', () {
      const kg = 70.0;
      final lbs = UnitConverter.kgToLbs(kg);
      expect(lbs, closeTo(154.32, 0.05));

      final backToKg = UnitConverter.lbsToKg(lbs);
      expect(backToKg, closeTo(kg, 0.001));
    });

    test('cm to inches conversions', () {
      const cm = 175.26;
      final inches = UnitConverter.cmToInches(cm);
      expect(inches, closeTo(69.0, 0.01));
    });

    test('cm to feet and inches breakdown', () {
      // 175 cm ~= 68.89 inches -> 69 inches -> 5 ft 9 in
      final result175 = UnitConverter.cmToFeetAndInches(175.0);
      expect(result175.feet, 5);
      expect(result175.inches, 9);

      // 182.88 cm = 72 inches = 6 ft 0 in
      final result183 = UnitConverter.cmToFeetAndInches(182.88);
      expect(result183.feet, 6);
      expect(result183.inches, 0);

      // Feet & inches to cm
      final cmReconstructed = UnitConverter.feetAndInchesToCm(5, 9);
      expect(cmReconstructed, closeTo(175.26, 0.01));
    });

    test('Celsius to Fahrenheit and vice versa', () {
      expect(UnitConverter.celsiusToFahrenheit(0.0), 32.0);
      expect(UnitConverter.celsiusToFahrenheit(100.0), 212.0);
      expect(UnitConverter.celsiusToFahrenheit(37.0), closeTo(98.6, 0.01));

      expect(UnitConverter.fahrenheitToCelsius(32.0), 0.0);
      expect(UnitConverter.fahrenheitToCelsius(212.0), 100.0);
      expect(UnitConverter.fahrenheitToCelsius(98.6), closeTo(37.0, 0.01));
    });

    test('formatHeight formats metric and imperial correctly', () {
      expect(UnitConverter.formatHeight(null, isMetric: true), '--');
      expect(UnitConverter.formatHeight(null, isMetric: false), '--');

      expect(UnitConverter.formatHeight(175.0, isMetric: true), '175.0 cm');
      expect(UnitConverter.formatHeight(175.0, isMetric: false), '5\'9"');
    });

    test('formatWeight formats metric and imperial correctly', () {
      expect(UnitConverter.formatWeight(null, isMetric: true), '--');
      expect(UnitConverter.formatWeight(null, isMetric: false), '--');

      expect(UnitConverter.formatWeight(70.0, isMetric: true), '70.0 kg');
      expect(UnitConverter.formatWeight(70.0, isMetric: false), '154.3 lbs');
    });
  });
}
