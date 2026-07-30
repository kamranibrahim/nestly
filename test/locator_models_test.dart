import 'package:flutter_test/flutter_test.dart';
import 'package:nestly/data/locator_models.dart';

void main() {
  group('formatLocatorAge', () {
    final now = DateTime(2026, 7, 30, 12);

    test('just now under 45 seconds', () {
      expect(
        formatLocatorAge(now.subtract(const Duration(seconds: 20)), now: now),
        'just now',
      );
    });

    test('minutes', () {
      expect(
        formatLocatorAge(now.subtract(const Duration(minutes: 1)), now: now),
        '1m ago',
      );
      expect(
        formatLocatorAge(now.subtract(const Duration(minutes: 12)), now: now),
        '12m ago',
      );
    });

    test('hours and days', () {
      expect(
        formatLocatorAge(now.subtract(const Duration(hours: 1)), now: now),
        '1h ago',
      );
      expect(
        formatLocatorAge(now.subtract(const Duration(hours: 5)), now: now),
        '5h ago',
      );
      expect(
        formatLocatorAge(now.subtract(const Duration(days: 1)), now: now),
        '1d ago',
      );
      expect(
        formatLocatorAge(now.subtract(const Duration(days: 3)), now: now),
        '3d ago',
      );
    });

    test('over a week', () {
      expect(
        formatLocatorAge(now.subtract(const Duration(days: 10)), now: now),
        'over a week ago',
      );
    });
  });

  group('NestLocation.isStale', () {
    test('fresh under 24h', () {
      final loc = NestLocation(
        memberId: 'a',
        lat: 1,
        lng: 2,
        updatedAt: DateTime(2026, 7, 30, 10),
        sharingEnabled: true,
      );
      expect(loc.isStale(DateTime(2026, 7, 30, 12)), isFalse);
    });

    test('stale after 24h', () {
      final loc = NestLocation(
        memberId: 'a',
        lat: 1,
        lng: 2,
        updatedAt: DateTime(2026, 7, 29, 10),
        sharingEnabled: true,
      );
      expect(loc.isStale(DateTime(2026, 7, 30, 12)), isTrue);
    });

    test('zero coords are not useful', () {
      final loc = NestLocation(
        memberId: 'a',
        lat: 0,
        lng: 0,
        updatedAt: DateTime(2026, 7, 30),
        sharingEnabled: true,
      );
      expect(loc.hasCoordinates, isFalse);
    });
  });

  test('maps urls contain coordinates', () {
    expect(locatorMapsUrl(37.7, -122.4), contains('37.7'));
    expect(locatorGoogleMapsUrl(37.7, -122.4), contains('37.7'));
    expect(locatorDirectionsUrl(37.7, -122.4), contains('daddr'));
    expect(locatorGoogleDirectionsUrl(37.7, -122.4), contains('destination'));
  });

  group('formatPlaceLabel', () {
    test('prefers hood + city', () {
      expect(
        formatPlaceLabel(subLocality: 'Mission', locality: 'San Francisco'),
        'Mission, San Francisco',
      );
    });

    test('falls back to Near me', () {
      expect(formatPlaceLabel(), 'Near me');
    });

    test('uses city alone', () {
      expect(formatPlaceLabel(locality: 'Austin'), 'Austin');
    });
  });

  group('distance helpers', () {
    test('haversine roughly SF to Oakland', () {
      final m = haversineMeters(
        lat1: 37.7749,
        lng1: -122.4194,
        lat2: 37.8044,
        lng2: -122.2712,
      );
      expect(m, greaterThan(10000));
      expect(m, lessThan(20000));
    });

    test('formatLocatorDistance', () {
      expect(formatLocatorDistance(80), '80 m');
      expect(formatLocatorDistance(1500), '1.5 km');
      expect(formatLocatorDistance(12000), '12 km');
    });

    test('formatLocatorAccuracy', () {
      expect(formatLocatorAccuracy(null), '');
      expect(formatLocatorAccuracy(12), '±12 m');
    });
  });

  group('boundsForLocations', () {
    test('null when empty', () {
      expect(boundsForLocations(const []), isNull);
    });

    test('pads a single pin', () {
      final b = boundsForLocations([
        NestLocation(
          memberId: 'a',
          lat: 37.7,
          lng: -122.4,
          updatedAt: DateTime(2026, 7, 30),
          sharingEnabled: true,
        ),
      ]);
      expect(b, isNotNull);
      expect(b!.north - b.south, greaterThan(0.009));
      expect(b.east - b.west, greaterThan(0.009));
    });

    test('spans multiple pins', () {
      final b = boundsForLocations([
        NestLocation(
          memberId: 'a',
          lat: 37.0,
          lng: -122.0,
          updatedAt: DateTime(2026, 7, 30),
          sharingEnabled: true,
        ),
        NestLocation(
          memberId: 'b',
          lat: 38.0,
          lng: -121.0,
          updatedAt: DateTime(2026, 7, 30),
          sharingEnabled: true,
        ),
      ]);
      expect(b!.south, 37.0);
      expect(b.north, 38.0);
      expect(b.west, -122.0);
      expect(b.east, -121.0);
    });
  });
}
