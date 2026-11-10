# Alertify

**A full-stack mobile and IoT home-alert system** built with Flutter, Firebase, and ESP32.

Alertify connects a mobile dashboard to a networked ESP32 device. The app provides account sign-in, live sensor status, event updates, and arm/disarm controls. Firebase Authentication and Realtime Database connect the client and device; Arduino firmware reads the sensors and controls local alert hardware.

> **Safety:** Alertify is a development project, not a certified security, smoke, or fire alarm. Use certified life-safety devices as your primary protection. See the [hardware safety notes](./firmware/README.md).

## Full-stack architecture

```text
Flutter mobile app
  ├─ Firebase Authentication — account sign-in
  └─ Firebase Realtime Database — live readings, events, and commands
                              ↕
ESP32 firmware — sensors, local buzzer/LCD, Wi-Fi, device telemetry
```

| Layer | Technologies | Responsibilities |
|---|---|---|
| Mobile client | Flutter, Dart, Material | Sign-in, live dashboard, sensor and event views, arm/disarm |
| Cloud services | Firebase Authentication, Realtime Database | User authentication and real-time data synchronization |
| IoT device | ESP32, Arduino framework, `FirebaseClient` | PIR, door-contact, and MQ-2 readings; local outputs; cloud updates |
| Development tooling | Python simulator, Flutter tests, GitHub Actions | Simulated device telemetry, app checks, Android release builds |

This repository contains the mobile client, firmware, Firebase rules, and a simulator. It does **not** contain a separate custom backend server.

## Features

- Email/password account flow through Firebase Authentication.
- Live device status, motion, door, smoke/gas, and event data from Realtime Database.
- Arm/disarm commands synchronized between the app and ESP32.
- ESP32 sensor polling, local buzzer/LCD output, and periodic cloud telemetry.
- Optional Python mock device for development without physical hardware.
- GitHub Actions workflow for building Android APK and App Bundle release artifacts.

## Get started

### Requirements

- Flutter SDK (stable) and Dart
- Android Studio or VS Code with Android SDK tools
- A Firebase project with Email/Password Authentication and Realtime Database
- Arduino IDE and ESP32 board support for physical-device development

### App

1. Follow [Firebase and Flutter setup](./README_FIREBASE_SETUP.md) to configure your Firebase project and platform files.
2. Install dependencies and run the app:

   ```sh
   flutter pub get
   flutter run
   ```

### ESP32

Follow the [firmware setup and wiring guide](./firmware/README.md). Copy `firmware/AlertifyESP32/config.example.h` to `config.h` and add your device's local credentials there. Never commit real credentials.

To develop without hardware, see the [mock ESP32 simulator](./tools/mock_esp32.py).

## Build and test

```sh
flutter analyze
flutter test
flutter build apk --release
```

The [GitHub release workflow](./.github/workflows/release.yml) builds an Android APK and App Bundle when a `v*` tag is pushed or the workflow is manually dispatched.

## Data flow

The default device ID is `esp32_001`. The app and device exchange data at:

```text
/devices/esp32_001/status
/devices/esp32_001/sensors
/devices/esp32_001/commands/armed
/events/esp32_001
```

Review and configure [Firebase Realtime Database rules](./firebase/database.rules.json) for your deployment. Do not use open read/write rules or production credentials for development.

## Contributing

Contributions across the app, Firebase integration, firmware, and documentation are welcome. Read [CONTRIBUTING.md](./CONTRIBUTING.md) before opening a pull request.
