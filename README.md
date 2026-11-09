# Alertify — Setup Requirements & Installation Guide

This document lists everything needed to run the Alertify Flutter app, connect it to your existing Firebase project, and connect the ESP32 security hardware.

## 1. What you need

### Software

- Flutter SDK (stable channel)
- Dart SDK (included with Flutter)
- Android Studio or VS Code
- Android SDK and platform tools
- Firebase CLI
- FlutterFire CLI
- Arduino IDE 2.x (for ESP32 firmware)
- ESP32 board support package for Arduino
- Arduino libraries:
  - `FirebaseClient` by Mobizt (2.x; use the API version compatible with the supplied sketch)
  - `LiquidCrystal_I2C`

### Accounts and Firebase services

- An existing Google/Firebase account and Firebase project
- Firebase Authentication with **Email/Password** enabled
- Firebase Realtime Database created in the project
- An Android Firebase app registered with the exact Android application ID/package name
- A dedicated Firebase Authentication account for the ESP32 device
- A normal Firebase Authentication account for the Alertify mobile-app user

Do not use a Firebase service-account private key in the Flutter app or ESP32 firmware.

## 2. Firebase information to prepare

Find these values in Firebase Console:

| Item | Where to find it | Used by |
|---|---|---|
| Firebase Project ID | Project settings → General | FlutterFire configuration |
| Web API key | Project settings → General → Web API key | ESP32 `config.h` |
| Realtime Database URL | Build → Realtime Database → Data | Flutter app and ESP32 |
| Android package name | Android app registration / `android/app/build.gradle` or `build.gradle.kts` | Firebase Android app registration |
| App user's Firebase UID | Authentication → Users | RTDB ownership mapping |
| ESP32 account's Firebase UID | Authentication → Users | RTDB device-auth mapping |

The project uses device ID `esp32_001` by default. If you change it, change it in both Flutter's `DeviceService` and the ESP32 firmware.

Never put passwords, private keys, or service-account JSON files in a public repository. Do not share passwords in chat.

## 3. Configure Firebase

1. Open https://console.firebase.google.com/ and select your existing project.
2. Go to **Build → Authentication → Sign-in method**.
3. Enable **Email/Password** and save.
4. Go to **Build → Realtime Database** and create a database if one does not exist.
5. Register the Android app in **Project settings → General → Your apps**. Use the exact Android package/application ID.
6. Create an app-user account using Alertify's **Create Account** button, or create one in Authentication.
7. Create a separate Email/Password authentication user for the ESP32.
8. Copy the two user UIDs from Authentication → Users.
9. In Realtime Database, create these ownership mapping values (replace the placeholders):

```json
{
  "deviceOwners": {
    "esp32_001": "FIREBASE_UID_OF_ALERTIFY_APP_USER"
  },
  "deviceAuthUids": {
    "esp32_001": "FIREBASE_UID_OF_ESP32_DEVICE_ACCOUNT"
  }
}
```

10. Open Realtime Database → Rules. Review and publish `firebase/database.rules.json` from this project. Test the rules in the Firebase Rules simulator before deploying.

The rules file is a starting point for this single-device design. Keep the ownership mapping protected and only allow trusted administrators to create or update it.

## 4. Configure and run the Flutter app

From a terminal, change directory to the `Alertify` folder (the folder containing `pubspec.yaml`).

Install Flutter dependencies:

```bash
flutter doctor
flutter pub get
```

Install and sign in to Firebase CLI:

```bash
npm install -g firebase-tools
firebase login
```

Install FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
```

Configure the existing Firebase project (select the existing project when prompted):

```bash
flutterfire configure
```

This generates `lib/firebase_options.dart` and the platform-specific Firebase configuration. Do not create `firebase_options.dart` by hand.

For Android, verify that the generated `android/app/google-services.json` exists if the FlutterFire setup for your project generates it. The Android application ID must match the app registered in Firebase.

Run the app:

```bash
flutter run
```

If Android build tooling has not yet been generated, run this once from the project folder:

```bash
flutter create . --platforms=android
```

Then rerun `flutterfire configure`, `flutter pub get`, and `flutter run`.

### First app login

- Open Alertify.
- Select **Create Account** to register the human app user.
- Copy that user's UID from Firebase Authentication → Users.
- Add the UID to `/deviceOwners/esp32_001` in Realtime Database.
- Sign out and log in again if needed.

## 5. Configure ESP32 firmware

### Hardware

- ESP32 Dev Board (ESP-WROOM-32)
- HC-SR501 PIR motion sensor
- MQ-2 smoke/combustible-gas sensor module
- MC-38 magnetic contact switch
- 16x2 LCD with I2C backpack
- 5V active buzzer
- Stable regulated 5V supply suitable for the sensors
- Common ground between the ESP32 and sensor supply
- Resistors for the MQ-2 analog-output voltage divider
- Transistor/MOSFET driver and suitable resistor for the buzzer if its current exceeds safe ESP32 GPIO limits
- Jumper wires and breadboard or suitable enclosure/PCB

### Pin connections

| Component | ESP32 pin |
|---|---|
| HC-SR501 OUT | GPIO 27 |
| MQ-2 AO | GPIO 34 through a voltage divider |
| MC-38 contact signal | GPIO 26 to GND |
| LCD SDA | GPIO 21 |
| LCD SCL | GPIO 22 |
| Buzzer control | GPIO 25 (through a driver if required) |

The supplied MC-38 logic assumes the contact closes GPIO26 to GND when the door/window is closed. With `INPUT_PULLUP`, LOW means closed and HIGH means open. Reverse the logic in firmware if your wiring/module is different.

### Electrical warnings

- **Never connect a 5V signal directly to an ESP32 GPIO.** ESP32 GPIOs are 3.3V logic and are not 5V tolerant.
- The MQ-2 module is commonly powered from 5V. Its AO pin must be reduced to no more than 3.3V before GPIO34. An example divider is 10kΩ from AO to GPIO34 and 20kΩ from GPIO34 to GND; verify the real output voltage with a multimeter.
- Confirm the LCD I2C backpack pull-up voltage. If it pulls SDA/SCL to 5V, use a bidirectional I2C level shifter or safe 3.3V pull-ups.
- Do not power a high-current buzzer directly from an ESP32 pin. Use a transistor/MOSFET driver as appropriate.
- Use a stable power supply and common ground.

### Firmware setup

1. Install ESP32 board support in Arduino IDE.
2. Install `FirebaseClient` by Mobizt (2.x) and `LiquidCrystal_I2C`.
3. Open `firmware/AlertifyESP32/`.
4. Copy `config.example.h` to `config.h`.
5. Fill in:
   - Wi-Fi SSID and password
   - Firebase Web API key
   - Realtime Database URL
   - Dedicated ESP32 Firebase account email and password
6. Keep `DEVICE_ID` set to `esp32_001` unless you also change the Flutter app.
7. Open `AlertifyESP32.ino`, select **ESP32 Dev Module**, choose the correct port, and upload.
8. Open Serial Monitor at 115200 baud.

## 6. Database paths used by the app and device

```text
devices/
  esp32_001/
    status/
      online
      armed
      alarm
      lastSeen
    sensors/
      motion
      smoke
      doorOpen
      gasRaw
      mq2Ready
    commands/
      armed

events/
  esp32_001/
    EVENT_ID/
      type
      message
      timestamp
      gasRaw
```

- ESP32 writes device status, sensor readings, and events.
- Alertify listens to status, sensors, and events.
- Alertify writes `/devices/esp32_001/commands/armed`.
- ESP32 reads the arm/disarm command and publishes the authoritative armed state.

## 7. Test checklist

- [ ] `flutter doctor` reports no blocking Android toolchain issues.
- [ ] Firebase Email/Password provider is enabled.
- [ ] Realtime Database exists.
- [ ] Android package ID matches the Firebase Android app registration.
- [ ] `flutterfire configure` generated `lib/firebase_options.dart`.
- [ ] App can create an account and sign in.
- [ ] `/deviceOwners/esp32_001` contains the app user's UID.
- [ ] `/deviceAuthUids/esp32_001` contains the ESP32 account UID.
- [ ] Firebase rules are published and tested.
- [ ] ESP32 connects to Wi-Fi and Firebase.
- [ ] Sensor values and `lastSeen` update in Realtime Database.
- [ ] Motion and door events appear in Alertify.
- [ ] Smoke/gas threshold behavior is tested safely.
- [ ] Arm/disarm control writes the command and ESP32 receives it.
- [ ] Local buzzer still works when Wi-Fi is disconnected.

## 8. Important limitations and production safety

This is a development integration and must be bench-tested with your exact hardware, Firebase project, library versions, and rules before deployment. It is not a certified security or fire alarm.

- MQ-2 raw ADC counts are **not ppm**. The threshold is a placeholder and must be calibrated against your module and environment.
- MQ-2 sensors require manufacturer-recommended conditioning/burn-in; a short startup delay is not calibration.
- Use certified smoke and carbon-monoxide alarms as the primary life-safety devices.
- The example ESP32 firmware uses `setInsecure()` for initial connectivity testing. This disables TLS certificate validation. Replace it with trusted CA validation before production.
- Credentials embedded in firmware can be extracted from a physical device. Use unique device credentials and consider a trusted backend/token architecture.
- The firmware's example event key is based on `millis()` and can collide after a reboot. Use collision-resistant IDs for production.
- A server-side process should mark devices offline when their `lastSeen` heartbeat becomes stale. A device cannot reliably report its own power failure.
- Do not expose the database with public read/write rules.

## 9. Troubleshooting

**`firebase_options.dart` not found**
Run `flutterfire configure` from the folder containing `pubspec.yaml`.

**Permission denied / database rules error**
Check that the signed-in app UID matches `/deviceOwners/esp32_001`, and the ESP32's authenticated UID matches `/deviceAuthUids/esp32_001`. Verify the published rules.

**ESP32 authentication fails**
Check the API key, device account email/password, database URL, and that Email/Password authentication is enabled.

**ESP32 connects but no values appear**
Confirm Wi-Fi, device ID, RTDB URL, database rules, and Serial Monitor output.

**Door state is reversed**
Check the MC-38 wiring and invert `digitalRead(Pins::CONTACT) == HIGH` if necessary.

**LCD is blank**
Check power, ground, SDA/SCL, contrast, and I2C address. Common addresses are `0x27` and `0x3F`.

**MQ-2 always triggers**
Check the voltage divider, sensor warm-up/conditioning, raw ADC readings, and threshold calibration. Do not interpret raw ADC counts as a gas concentration.

---

For the existing Firebase project, keep your actual credentials in local configuration files only. Never upload `config.h`, service-account keys, or passwords to a public repository.
