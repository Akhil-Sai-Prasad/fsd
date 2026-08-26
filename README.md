# FSD

FSD is the source Flutter app in the customer handoff demo, and the **owner of the
shared store** the whole suite reads and writes. It fetches a customer record,
writes it straight into the shared store, and hands off to the QT and LT apps.

## Methodology: the data never travels in the link

Earlier versions of this demo URL-encoded the customer JSON into the deep link.
They no longer do. FSD hosts a `ContentProvider` over MMKV; every app reaches it
through `ContentResolver`, and the deep links carry nothing but a pointer:

```text
qtapp://customer?id=<customer_id>    # "open this record"
ltapp://customers                    # "come and look"
```

Nothing sensitive ends up in a URL, there is no payload length limit, and there
is a single copy of each record instead of one per app. The full contract —
authority, permission, envelope, provider surface — lives in
[`packages/shared_store/README.md`](../packages/shared_store/README.md).

FSD is both the host and a client: its own reads and writes go through
`ContentResolver` like everyone else's, so there is one code path. For FSD the
call resolves in-process and never crosses Binder.

## What This App Does

- Fetches customer details from `https://jsonplaceholder.typicode.com/users/{id}`,
  where `id` is random between 1 and 10, with a 6-second timeout.
- Falls back to dynamically generated mock customer data when the endpoint is
  unreachable or returns a non-200. **The fetch never throws** — a failure here
  degrades to mock data rather than surfacing an error.
- **Auto-saves on fetch.** A freshly fetched record goes straight into the shared
  store via `CustomerStore.upsert`; there is no separate "Store Customers" step.
  Records accumulate under `entity.customers`, replacing any entry with the same id.
- Opens QT pointed at the current record.
- Opens LT, which reads the whole list for itself.

## Shared Store Ownership

FSD declares the provider and is the only app that links MMKV:

```xml
<provider
    android:name=".SharedStoreProvider"
    android:authorities="com.techmirus.sharedstore.provider"
    android:exported="true"
    android:permission="com.techmirus.sharedstore.permission.ACCESS" />
```

The permission is `signature`-level, so **all three apps must be signed with the
same certificate**. In development that is automatic — they share the debug
keystore.

Writes call `notifyChange` on `content://<authority>/entity/customers`, which
wakes the `ContentObserver` registered by QT and LT. That is why LT redraws
without anyone firing a deep link at it.

Uninstalling FSD destroys the store, and QT and LT will report it as unavailable.

## Main Files

- `lib/screens/home_screen.dart` - fetch, auto-save, and "Go to QT/LT" actions.
- `lib/services/api_service.dart` - demo API call and mock fallback payload.
- `lib/widgets/connectivity_banner.dart` - online/offline banner.
- `android/app/src/main/kotlin/com/techmirus/fsd/SharedStoreProvider.kt` - the
  provider that owns the MMKV instance.
- `android/app/src/main/AndroidManifest.xml` - provider declaration, permission,
  and `qtapp`/`ltapp` package-visibility queries.
- `android/app/build.gradle.kts` - MMKV dependency and the `SHARED_STORE_KEY`
  build config field.

The customer model and store accessors are **not** in this app — they live in the
shared `packages/shared_store` package, so FSD, QT and the store agree on one
definition.

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
flutter build apk --debug
```

Install the APK with ADB:

```bash
adb install -r build/app/outputs/apk/debug/app-debug.apk
```

Because the shared store is a path dependency, **changing
`packages/shared_store` means rebuilding FSD and QT both** — a stale build keeps
its old copy of the package.

## Manual Test Flow

1. Install FSD, QT and LT on the same device, all from the same keystore.
2. Launch FSD. The connectivity banner should read `Online`.
3. Tap `Fetch Customer Details`. A record appears with a green `Stored` badge —
   it is already in the shared store at this point.
4. Tap it again a few times. Each fetch adds another customer to the list.
5. Tap `Go to QT`. QT opens showing the record you just fetched.
6. Tap `Go to LT`. LT lists every customer fetched so far.

## Verification Commands

Check that Android can resolve the target app links:

```bash
adb shell cmd package resolve-activity -a android.intent.action.VIEW -d qtapp://customer
adb shell cmd package resolve-activity -a android.intent.action.VIEW -d ltapp://customers
```

Launch FSD directly:

```bash
adb shell am start -W -n com.techmirus.fsd/.MainActivity
```

Inspect what is actually in the shared store (debug builds only):

```bash
adb shell "run-as com.techmirus.fsd base64 \
  /data/data/com.techmirus.fsd/files/mmkv/techmirus-shared-store" \
  | tr -d '\r\n' | base64 -d | strings -n 6
```

Expect one `entity.customers` key holding
`{"schemaVersion":1,"updatedAt":...,"data":[...]}`.

Watch the store come up:

```bash
adb logcat -c && adb logcat | grep -i mmkv
```

`loaded [techmirus-shared-store] with N key-values` confirms the provider opened
the store; `N` is 0 before the first fetch.

## Analyze and Test

```bash
flutter analyze
flutter test
```
