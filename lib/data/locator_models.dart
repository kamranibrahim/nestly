/// Nest Locator models and pure helpers (no Firebase / plugins).
library;

import 'dart:math' as math;

import '../l10n/app_localizations.dart';

const locatorSharingMetaKey = 'locatorSharingEnabled';
const locatorLastLatMetaKey = 'locatorLastLat';
const locatorLastLngMetaKey = 'locatorLastLng';
const locatorLastAtMetaKey = 'locatorLastAt';
const locatorLastLabelMetaKey = 'locatorLastLabel';
const locatorLastAccuracyMetaKey = 'locatorLastAccuracyM';

const Duration locatorStaleAfter = Duration(hours: 24);

class NestLocation {
  const NestLocation({
    required this.memberId,
    required this.lat,
    required this.lng,
    required this.updatedAt,
    required this.sharingEnabled,
    this.accuracyM,
    this.label,
  });

  final String memberId;
  final double lat;
  final double lng;
  final DateTime updatedAt;
  final bool sharingEnabled;
  final double? accuracyM;
  final String? label;

  bool get hasCoordinates =>
      lat.isFinite && lng.isFinite && !(lat == 0 && lng == 0);

  bool isStale([DateTime? now]) {
    final n = now ?? DateTime.now();
    return n.difference(updatedAt) > locatorStaleAfter;
  }
}

/// Human age for “Updated …” / “Last seen …”.
String formatLocatorAge(
  DateTime updatedAt, {
  DateTime? now,
  AppLocalizations? l10n,
}) {
  final n = now ?? DateTime.now();
  var diff = n.difference(updatedAt);
  if (diff.isNegative) diff = Duration.zero;

  if (diff.inSeconds < 45) return l10n?.widgetJustNow ?? 'just now';
  if (diff.inMinutes < 60) {
    return l10n?.widgetMinutesAgo(diff.inMinutes) ??
        (diff.inMinutes == 1 ? '1m ago' : '${diff.inMinutes}m ago');
  }
  if (diff.inHours < 24) {
    return l10n?.widgetHoursAgo(diff.inHours) ??
        (diff.inHours == 1 ? '1h ago' : '${diff.inHours}h ago');
  }
  final d = diff.inDays;
  if (d < 7) {
    return l10n?.widgetDaysAgo(d) ?? (d == 1 ? '1d ago' : '${d}d ago');
  }
  return l10n?.syncOverWeekAgo ?? 'over a week ago';
}

String locatorMapsUrl(double lat, double lng) {
  return 'https://maps.apple.com/?ll=$lat,$lng&q=$lat,$lng';
}

String locatorGoogleMapsUrl(double lat, double lng) {
  return 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
}

String locatorDirectionsUrl(double lat, double lng) {
  return 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';
}

String locatorGoogleDirectionsUrl(double lat, double lng) {
  return 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng';
}

/// Approximate great-circle distance in meters.
double haversineMeters({
  required double lat1,
  required double lng1,
  required double lat2,
  required double lng2,
}) {
  const earthM = 6371000.0;
  double rad(double deg) => deg * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLng = rad(lng2 - lng1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return earthM * c;
}

String formatLocatorDistance(double meters) {
  if (!meters.isFinite || meters < 0) return '';
  if (meters < 1000) {
    final m = meters.round();
    return m < 1 ? '<1 m' : '$m m';
  }
  final km = meters / 1000;
  if (km < 10) return '${km.toStringAsFixed(1)} km';
  return '${km.round()} km';
}

String formatLocatorAccuracy(double? accuracyM) {
  if (accuracyM == null || !accuracyM.isFinite || accuracyM <= 0) {
    return '';
  }
  if (accuracyM < 1000) return '±${accuracyM.round()} m';
  return '±${(accuracyM / 1000).toStringAsFixed(1)} km';
}

/// Builds a short human label from reverse-geocode fields.
String formatPlaceLabel({
  String? locality,
  String? subLocality,
  String? thoroughfare,
  String? administrativeArea,
  String? name,
}) {
  final street = (thoroughfare ?? '').trim();
  final hood = (subLocality ?? '').trim();
  final city = (locality ?? '').trim();
  final area = (administrativeArea ?? '').trim();
  final n = (name ?? '').trim();

  if (hood.isNotEmpty && city.isNotEmpty) return '$hood, $city';
  if (street.isNotEmpty && city.isNotEmpty) return '$street, $city';
  if (city.isNotEmpty) return city;
  if (hood.isNotEmpty) return hood;
  if (street.isNotEmpty) return street;
  if (area.isNotEmpty) return area;
  if (n.isNotEmpty && n.toLowerCase() != 'near me') return n;
  return 'Near me';
}

String displayLocatorLabel(String? label, AppLocalizations l10n) {
  final text = (label ?? '').trim();
  if (text.isEmpty) return '';
  if (text.toLowerCase() == 'near me') return l10n.locatorNearMe;
  return text;
}

/// Axis-aligned bounds for fitting a nest map camera.
class LocatorLatLngBounds {
  const LocatorLatLngBounds({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });

  final double south;
  final double west;
  final double north;
  final double east;

  double get centerLat => (south + north) / 2;
  double get centerLng => (west + east) / 2;
}

/// Returns null when there are no usable coordinates.
LocatorLatLngBounds? boundsForLocations(Iterable<NestLocation> locations) {
  final pts = locations.where((l) => l.hasCoordinates).toList();
  if (pts.isEmpty) return null;

  var south = pts.first.lat;
  var north = pts.first.lat;
  var west = pts.first.lng;
  var east = pts.first.lng;
  for (final p in pts.skip(1)) {
    if (p.lat < south) south = p.lat;
    if (p.lat > north) north = p.lat;
    if (p.lng < west) west = p.lng;
    if (p.lng > east) east = p.lng;
  }

  // Single pin / tiny cluster — pad so GoogleMap can zoom sensibly.
  const minPad = 0.01;
  if ((north - south).abs() < minPad) {
    south -= minPad / 2;
    north += minPad / 2;
  }
  if ((east - west).abs() < minPad) {
    west -= minPad / 2;
    east += minPad / 2;
  }

  return LocatorLatLngBounds(
    south: south,
    west: west,
    north: north,
    east: east,
  );
}
