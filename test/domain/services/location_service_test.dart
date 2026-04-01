import 'package:flutter_test/flutter_test.dart';
import 'package:specialist_finder/domain/services/location_service.dart';

void main() {
  group('LocationService', () {
    late LocationService service;

    setUp(() {
      service = LocationService();
    });

    test('calculates distance between two points correctly', () {
      // London coordinates
      const lat1 = 51.5074;
      const lon1 = -0.1278;

      // Manchester coordinates (~200km from London)
      const lat2 = 53.4808;
      const lon2 = -2.2426;

      final distance = service.calculateDistance(lat1, lon1, lat2, lon2);

      // Should be approximately 200km (allowing 10% error)
      expect(distance, greaterThan(180.0));
      expect(distance, lessThan(220.0));
    });

    test('returns zero distance for same coordinates', () {
      const lat = 51.5074;
      const lon = -0.1278;

      final distance = service.calculateDistance(lat, lon, lat, lon);

      expect(distance, closeTo(0.0, 0.1));
    });

    test('formats distance correctly', () {
      expect(service.formatDistance(0.5), contains('m'));
      expect(service.formatDistance(5.0), contains('km'));
      expect(service.formatDistance(50.0), contains('km'));
    });

    test('calculates short distances accurately', () {
      // Two points ~1km apart
      const lat1 = 51.5074;
      const lon1 = -0.1278;
      const lat2 = 51.5084;
      const lon2 = -0.1288;

      final distance = service.calculateDistance(lat1, lon1, lat2, lon2);

      expect(distance, greaterThan(0.5));
      expect(distance, lessThan(2.0));
    });
  });
}

