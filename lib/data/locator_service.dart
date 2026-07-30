import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import 'db/app_database.dart';
import 'locator_models.dart';

class LocatorException implements Exception {
  LocatorException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Opt-in last-known nest locations — when-in-use only, no background tracking.
class LocatorService {
  LocatorService(this._db);

  final AppDatabase _db;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _locationsCol(String nestId) {
    return _firestore.collection('nests').doc(nestId).collection('locations');
  }

  Future<String?> _nestId() async {
    final fromMeta = await _db.getMeta('nestId');
    if (fromMeta != null && fromMeta.isNotEmpty) return fromMeta;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final userDoc = await _firestore.collection('users').doc(uid).get();
    return userDoc.data()?['nestId'] as String?;
  }

  Future<bool> isSharingEnabled() async {
    return await _db.getMeta(locatorSharingMetaKey) == '1';
  }

  Future<void> setSharingEnabled(bool enabled) async {
    await _db.setMeta(locatorSharingMetaKey, enabled ? '1' : '0');
    if (!enabled) {
      await clearPublishedLocation();
    }
  }

  Stream<List<NestLocation>> watchNestLocations() async* {
    final nestId = await _nestId();
    if (nestId == null || nestId.isEmpty) {
      yield const [];
      return;
    }

    yield* _locationsCol(nestId).snapshots().map((snap) {
      final out = <NestLocation>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['sharingEnabled'] != true) continue;
        final loc = _fromDoc(doc.id, data);
        if (loc.hasCoordinates) out.add(loc);
      }
      out.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return out;
    });
  }

  Future<NestLocation?> loadCachedSelfLocation() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final latS = await _db.getMeta(locatorLastLatMetaKey);
    final lngS = await _db.getMeta(locatorLastLngMetaKey);
    final atS = await _db.getMeta(locatorLastAtMetaKey);
    if (latS == null || lngS == null || atS == null) return null;
    final lat = double.tryParse(latS);
    final lng = double.tryParse(lngS);
    final atMs = int.tryParse(atS);
    if (lat == null || lng == null || atMs == null) return null;
    final accuracyS = await _db.getMeta(locatorLastAccuracyMetaKey);
    final label = await _db.getMeta(locatorLastLabelMetaKey);
    return NestLocation(
      memberId: uid,
      lat: lat,
      lng: lng,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(atMs),
      sharingEnabled: await isSharingEnabled(),
      accuracyM: accuracyS == null ? null : double.tryParse(accuracyS),
      label: label,
    );
  }

  /// Requests when-in-use permission and publishes current position.
  Future<NestLocation> shareNow() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw LocatorException('Sign in to share your location.');
    }
    final nestId = await _nestId();
    if (nestId == null || nestId.isEmpty) {
      throw LocatorException('Join a nest before sharing location.');
    }

    final permitted = await ensureWhenInUsePermission();
    if (!permitted) {
      throw LocatorException(
        'Location permission is needed to share where you are.',
      );
    }

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocatorException('Turn on Location Services to share.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      ),
    );

    final now = DateTime.now();
    final label = await reverseGeocodeLabel(
      position.latitude,
      position.longitude,
    );
    final loc = NestLocation(
      memberId: user.uid,
      lat: position.latitude,
      lng: position.longitude,
      updatedAt: now,
      sharingEnabled: true,
      accuracyM: position.accuracy,
      label: label,
    );

    await _db.setMeta(locatorSharingMetaKey, '1');
    await _cacheSelf(loc);

    await _locationsCol(nestId).doc(user.uid).set({
      'lat': loc.lat,
      'lng': loc.lng,
      'updatedAt': FieldValue.serverTimestamp(),
      'sharingEnabled': true,
      'accuracyM': loc.accuracyM,
      'label': loc.label,
    }, SetOptions(merge: true));

    return loc;
  }

  /// Best-effort place label; falls back to “Near me”.
  Future<String> reverseGeocodeLabel(double lat, double lng) async {
    try {
      final places = await Geocoding().placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return 'Near me';
      final p = places.first;
      return formatPlaceLabel(
        locality: p.locality,
        subLocality: p.subLocality,
        thoroughfare: p.thoroughfare,
        administrativeArea: p.administrativeArea,
        name: p.name,
      );
    } catch (e) {
      debugPrint('Locator geocode failed: $e');
      return 'Near me';
    }
  }

  Future<void> clearPublishedLocation() async {
    final user = _auth.currentUser;
    final nestId = await _nestId();
    if (user != null && nestId != null && nestId.isNotEmpty) {
      try {
        await _locationsCol(nestId).doc(user.uid).delete();
      } catch (e) {
        debugPrint('Locator clear failed: $e');
      }
    }
    await _db.setMeta(locatorLastLatMetaKey, '');
    await _db.setMeta(locatorLastLngMetaKey, '');
    await _db.setMeta(locatorLastAtMetaKey, '');
    await _db.setMeta(locatorLastLabelMetaKey, '');
    await _db.setMeta(locatorLastAccuracyMetaKey, '');
  }

  /// Returns true if when-in-use location is granted (or limited on iOS).
  Future<bool> ensureWhenInUsePermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return false;
    }
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always ||
        permission == LocationPermission.unableToDetermine;
  }

  Future<bool> hasWhenInUsePermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  /// Best-effort device position for distance chips (does not publish).
  Future<({double lat, double lng})?> peekDevicePosition() async {
    if (!await hasWhenInUsePermission()) {
      final cached = await loadCachedSelfLocation();
      if (cached != null && cached.hasCoordinates) {
        return (lat: cached.lat, lng: cached.lng);
      }
      return null;
    }
    try {
      final last = await Geolocator.getLastKnownPosition();
      if (last != null) {
        return (lat: last.latitude, lng: last.longitude);
      }
    } catch (_) {}
    final cached = await loadCachedSelfLocation();
    if (cached != null && cached.hasCoordinates) {
      return (lat: cached.lat, lng: cached.lng);
    }
    return null;
  }

  Future<void> _cacheSelf(NestLocation loc) async {
    await _db.setMeta(locatorLastLatMetaKey, loc.lat.toString());
    await _db.setMeta(locatorLastLngMetaKey, loc.lng.toString());
    await _db.setMeta(
      locatorLastAtMetaKey,
      loc.updatedAt.millisecondsSinceEpoch.toString(),
    );
    await _db.setMeta(locatorLastLabelMetaKey, loc.label ?? '');
    await _db.setMeta(
      locatorLastAccuracyMetaKey,
      loc.accuracyM?.toString() ?? '',
    );
  }

  NestLocation _fromDoc(String memberId, Map<String, dynamic> data) {
    final updatedRaw = data['updatedAt'];
    DateTime updatedAt;
    if (updatedRaw is Timestamp) {
      updatedAt = updatedRaw.toDate();
    } else if (updatedRaw is DateTime) {
      updatedAt = updatedRaw;
    } else {
      updatedAt = DateTime.fromMillisecondsSinceEpoch(0);
    }
    return NestLocation(
      memberId: memberId,
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      updatedAt: updatedAt,
      sharingEnabled: data['sharingEnabled'] == true,
      accuracyM: (data['accuracyM'] as num?)?.toDouble(),
      label: (data['label'] as String?)?.trim(),
    );
  }
}
