# FSD

FSD is the source Flutter app in the customer handoff demo. It fetches a customer record, stores selected customers locally with MMKV, and forwards customer data to the QT and LT apps through Android deep links.

## What This App Does

- Fetches customer details from a random `https://jsonplaceholder.typicode.com/users/{id}` endpoint, where `id` is between 1 and 10.
- Falls back to dynamically generated mock customer data when the network endpoint is unavailable.
- Stores customers in MMKV only when the user taps `Store Customers`.
- Opens QT with the current customer record.
- Opens LT with the saved customer records.

## App Links

FSD sends these outbound deep links:

```text
qtapp://customer?data=<url_encoded_customer_json>
ltapp://customers?data=<url_encoded_customer_array_json>
```

The Android manifest includes package visibility queries for `qtapp` and `ltapp` so `url_launcher` can discover and open the target apps on Android 11+.

## Main Files

- `lib/screens/home_screen.dart` - fetch, store, and "Go to QT/LT" actions.
- `lib/services/api_service.dart` - demo API call and fallback payload.
- `lib/services/storage_service.dart` - MMKV persistence for saved customers.
- `lib/models/customer.dart` - customer JSON model.
- `android/app/src/main/AndroidManifest.xml` - Android package visibility config.

## Run Locally

Install Flutter dependencies:

```bash
flutter pub get
```

Run on a connected Android device:

```bash
flutter run
```

Build a debug APK:

```bash
cd android
./gradlew assembleDebug
```

Install the APK with ADB:

```bash
cd ..
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

## Manual Test Flow

1. Install QT and LT on the same device.
2. Launch FSD.
3. Tap `Fetch Customer Details`.
4. Tap `Store Customers` for each customer you want LT to receive later.
5. Tap `Go to QT` to send the current customer to QT.
6. Tap `Go to LT` to send saved customers to LT.

## Verification Commands

Check that Android can resolve the target app links:

```bash
adb shell cmd package resolve-activity -a android.intent.action.VIEW -d qtapp://customer
adb shell cmd package resolve-activity -a android.intent.action.VIEW -d ltapp://customers
```

Launch FSD directly:

```bash
adb shell am start -W -n com.example.fsd/.MainActivity
```
