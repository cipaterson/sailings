# Sailings — Android app

A Jetpack Compose companion app for the Rails app in the parent directory. Members
can browse upcoming voyages, register and cancel, see their own registrations, and
check whether their qualifications are still current. It talks to the same
`/api/v1` JSON API as the iOS app in `../ios`.

Stack: Kotlin, Jetpack Compose (Material 3), Ktor client + kotlinx.serialization,
coroutines. `minSdk 26`.

## Before it will build

This app builds with **Android Studio** (or the Android SDK + `./gradlew`). The
machine it was written on had no Android SDK, so the UI was not compiled here — the
networking and model layer was compiled and tested on the JVM against a live server
(see "How this was verified"), and the Compose screens are standard Material 3 that
Android Studio will build on first sync.

Open the `android/` directory in Android Studio, let it sync Gradle (it uses the
pinned wrapper, Gradle 8.9 + AGP 8.7.3), and the SDK components it needs are fetched
automatically.

## Pointing it at a server

`app/src/main/java/org/sailings/app/Config.kt` holds the base URL.

| Running against | `BASE_URL` | Also needed |
| --- | --- | --- |
| Emulator → local server | `http://10.0.2.2:3000` (default) | — |
| Physical device → local server | `http://<your-Mac's-LAN-IP>:3000` | `bin/rails server -b 0.0.0.0`; add that IP to `network_security_config.xml`; same Wi-Fi |
| Production | the HTTPS URL | — |

**`10.0.2.2`, not `localhost`.** Inside the emulator, `localhost` is the emulated
device itself; `10.0.2.2` is the special alias for your Mac. This is the single most
common first-run mistake — the iOS equivalent was just `localhost`, which trips
people the other way.

Plain HTTP is blocked by default (Android's App Transport Security equivalent).
`res/xml/network_security_config.xml` carries a cleartext exception for `10.0.2.2`
and `localhost` so development works; production over HTTPS needs no exception. To
test on a physical device, add your Mac's exact LAN IP there (it matches IPs, not
CIDR ranges).

## Running it

- **Emulator:** create one in Android Studio's Device Manager, then Run.
- **Physical device:** enable Developer Options + USB debugging, plug in, Run. Or
  build a debug APK (`./gradlew assembleDebug`) and `adb install` it, or sideload
  the file with "install unknown apps" enabled.

Unlike iOS, there is **no 7-day expiry and no paid account** — a debug build installs
and keeps working. Sharing more widely later means a signed release build or Play
Store, but nothing is needed for your own device.

## How this was verified

The `ApiClient.kt` and `Models.kt` in this project have no Android dependencies —
they are pure Ktor + kotlinx.serialization. They were compiled for the JVM and run
against a live Rails instance, exercising the full loop (login, list, register,
cancel, logout) and both JSON date shapes: ISO-8601 timestamps (`departs_at`) decode
as `Instant`, bare `yyyy-MM-dd` dates (`expires_on`, `last_sailed`) as `LocalDate`.
All checks passed. The Compose UI on top was reviewed but not compiled here.

## Layout

```
app/src/main/java/org/sailings/app/
  Config.kt          base URL (10.0.2.2 for the emulator)
  Models.kt          Voyage, Registration, Profile, Qualification
  ApiClient.kt       Ktor client; bearer auth, typed ApiException, JSON decoding
  TokenStore.kt      token in EncryptedSharedPreferences (the Keychain analog)
  AuthViewModel.kt   StateFlow auth state; signs out on any 401
  MainActivity.kt    hosts the login/root switch
  ui/                LoginScreen, RootScreen (bottom nav), VoyageList,
                     VoyageDetail, MyRegistrations, Profile, theme/
```

The API contract it expects is `/api/v1` in the Rails app — see
`app/controllers/api/v1/` and the tests in `test/controllers/api/v1/`.

The app says **Voyage** throughout (matching the web UI and iOS), while the Rails
models and JSON keys say `sailing`.
