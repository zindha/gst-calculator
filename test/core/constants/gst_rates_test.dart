import 'package:flutter_test/flutter_test.dart';
import 'package:gst_calculator/core/constants/gst_rates.dart';

void main() {
  group('GstRates', () {
    test('standardSlabs contains exactly 6 rates', () {
      expect(GstRates.standardSlabs.length, 6);
    });

    test('standardSlabs are in ascending order', () {
      for (var i = 1; i < GstRates.standardSlabs.length; i++) {
        expect(
          GstRates.standardSlabs[i],
          greaterThan(GstRates.standardSlabs[i - 1]),
        );
      }
    });

    test('standardSlabs contains expected Indian GST rates', () {
      // The active slabs: 0.25% (rough diamonds), 3% (gold / cut & polished
      // diamonds), 5%, 12%, 18%, 28%. The 0% nil-rated slab is not offered.
      expect(GstRates.standardSlabs, [0.25, 3.0, 5.0, 12.0, 18.0, 28.0]);
    });

    test('defaultSlab is 18%', () {
      expect(GstRates.defaultSlab, 18.0);
    });

    test('defaultSlab is in the standard slabs list', () {
      expect(GstRates.standardSlabs, contains(GstRates.defaultSlab));
    });

    test('minCustomSlab is 0.25', () {
      expect(GstRates.minCustomSlab, 0.25);
    });

    test('maxCustomSlab is 100', () {
      expect(GstRates.maxCustomSlab, 100.0);
    });

    test('percentageFactor is 100', () {
      expect(GstRates.percentageFactor, 100.0);
    });

    test('minCustomSlab is less than maxCustomSlab', () {
      expect(GstRates.minCustomSlab, lessThan(GstRates.maxCustomSlab));
    });
  });
}
