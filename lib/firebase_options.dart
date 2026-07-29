// File generated manually for Nestly (flutterfire could not resolve the new project).
// ignore_for_file: lines_longer_than_80_chars

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBjOi7n11m9Hc82fOyD4zFUx2BtrnHmEhg',
    appId: '1:165083787847:web:5919fb0537b3fa157c7762',
    messagingSenderId: '165083787847',
    projectId: 'nestly-family-os',
    authDomain: 'nestly-family-os.firebaseapp.com',
    storageBucket: 'nestly-family-os.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBDLNP2Gsubh2gFdw_ME-_4ZxfalyINgeU',
    appId: '1:165083787847:android:cffe3f15000e50267c7762',
    messagingSenderId: '165083787847',
    projectId: 'nestly-family-os',
    storageBucket: 'nestly-family-os.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBvQytr6-GY-MGDnR5MFOAUeAA3AtoUmqY',
    appId: '1:165083787847:ios:26d4d9aac40723297c7762',
    messagingSenderId: '165083787847',
    projectId: 'nestly-family-os',
    storageBucket: 'nestly-family-os.firebasestorage.app',
    iosBundleId: 'com.nestly.nestly',
  );
}
