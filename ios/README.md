# Sailings — iOS app

A SwiftUI companion app for the Rails app in the parent directory. Members can
browse upcoming voyages, register and cancel, see their own registrations, and
check whether their qualifications are still current.

No third-party dependencies: URLSession and `Codable` only.

## Before it will build

Xcode is installed on this machine, but the **iOS platform component is not**
(`xcodebuild` reports "iOS 26.5 is not installed"). Download it once via
**Xcode → Settings → Components → iOS**, otherwise there is no simulator or
device destination to build against.

## Pointing it at a server

`Sailings/Config.swift` holds the base URL.

| Running against | `baseURL` | Also needed |
| --- | --- | --- |
| Simulator → local server | `http://localhost:3000` | — |
| Device → local server | `http://<your-Mac's-LAN-IP>:3000` | Start Rails with `bin/rails server -b 0.0.0.0`; same Wi-Fi |
| Production | the HTTPS URL | — |

Plain HTTP is blocked by App Transport Security in general; `Sailings-Info.plist`
carries an `NSAllowsLocalNetworking` exception so localhost and LAN addresses
work in development. Production over HTTPS needs no exception.

## Running on your own iPhone

With a **free** Apple ID: open `Sailings.xcodeproj`, select the target, and under
Signing & Capabilities pick your personal team and change the bundle identifier
to something unique (`org.sailings.app` is taken as a placeholder). Plug the
phone in and run.

Two limits of the free tier worth knowing: the build **expires after 7 days** and
must be reinstalled from Xcode, and it only runs on devices you physically
connect. Sharing it with other club members means a paid Apple Developer account
($99/yr) and TestFlight.

## Layout

```
Sailings/
  Config.swift          base URL
  Models.swift          Voyage, Registration, Profile, Qualification
  APIClient.swift       actor over URLSession; bearer auth, JSON decoding
  KeychainStore.swift   the token lives here, not in UserDefaults
  AuthStore.swift       observable auth state; signs out on any 401
  Views/                Login, Root (tabs), VoyageList, VoyageDetail,
                        MyRegistrations, Profile
```

The API contract it expects is `/api/v1` in the Rails app — see
`app/controllers/api/v1/` and the request tests in `test/controllers/api/v1/`.

Note the app says **Voyage** throughout, matching the web UI, while the Rails
models and JSON keys say `sailing`.
