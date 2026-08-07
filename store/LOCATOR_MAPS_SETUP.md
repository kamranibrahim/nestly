# Google Maps setup for Nest Locator

Casaio’s in-app Locator map uses the **Maps SDK for Android/iOS**.

## 1. Create keys (local only)

```bash
cp android/keys.properties.example android/keys.properties
cp ios/Flutter/Secrets.xcconfig.example ios/Flutter/Secrets.xcconfig
```

Put the same Maps API key in both files (`GOOGLE_MAPS_API_KEY=...`).

These files are **gitignored** — never commit them.

## 2. Google Cloud Console

Enable:

- Maps SDK for Android
- Maps SDK for iOS

Restrict the key:

- Android: package `app.nestly.family` + SHA-1
- iOS: bundle `app.nestly.family`

## 3. Rebuild

```bash
flutter clean
flutter pub get
cd ios && pod install && cd ..
flutter run
```

Without a key, the map area stays blank/grey; Share now and the member list still work.
