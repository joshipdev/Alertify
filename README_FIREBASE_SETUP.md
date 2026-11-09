# Alertify Firebase + ESP32 setup

This package is an integration-ready Flutter source project. It does not contain your Firebase project credentials or generated platform configuration; those must be created in your Firebase account.

## A. Create/configure Firebase

1. Open https://console.firebase.google.com/ and create a project.
2. Add your Android app using the exact Android application ID you will use.
3. In Authentication > Sign-in method, enable **Email/Password**.
4. Create a Realtime Database in a region close to your users (for example Singapore/Asia Southeast).
5. Copy the database URL.
6. Register a Firebase app for Android/iOS as needed.

## B. Configure FlutterFire

Install Flutter and Firebase CLI, then:

```bash
dart pub global activate flutterfire_cli
firebase login
cd alertify
flutter create . --platforms=android,ios
flutterfire configure
flutter pub get
flutter run
```

`flutterfire configure` generates `lib/firebase_options.dart`. It is intentionally not included because it contains project-specific identifiers. Never paste service-account private keys into the Flutter app.

For Android, verify the generated `android/app/google-services.json` exists. For iOS, verify `ios/Runner/GoogleService-Info.plist` exists.

## C. Multi-User Access & Database Rules

The project is configured for **full multi-user household support**:
- **Any user** who signs up or logs into the Alertify app with their email/password can view live sensors, receive alerts, and arm/disarm the system.
- When any user toggles Arm/Disarm, all connected users' apps update in real time.
- No manual UID copying or database editing is required!

Publish `firebase/database.rules.json` in **Firebase Console > Realtime Database > Rules**:
```json
{
  "rules": {
    "devices": {
      "$deviceId": {
        ".read": "auth != null",
        "status": { ".write": "auth != null" },
        "sensors": { ".write": "auth != null" },
        "commands": {
          "armed": { ".write": "auth != null" }
        }
      }
    },
    "events": {
      "$deviceId": {
        ".read": "auth != null",
        "$eventId": { ".write": "auth != null" }
      }
    }
  }
}
```
These rules require valid authentication (`auth != null`) while allowing all verified family/team members and the ESP32 controller to communicate seamlessly.

## D. Configure ESP32 firmware

1. Open `firmware/AlertifyESP32/config.example.h` and make a private copy named `config.h`.
2. Enter Wi-Fi SSID/password, Firebase Web API key, RTDB URL, and the dedicated ESP32 account email/password.
3. Ensure `DEVICE_ID` is `esp32_001`.
4. Install ESP32 board support, `FirebaseClient` by Mobizt (2.x), and `LiquidCrystal_I2C`.
5. Open the `.ino` file in Arduino IDE and select **ESP32 Dev Module**.
6. Upload and open Serial Monitor at 115200 baud.

Wire the sensors as documented in `firmware/README` / the comments in the sketch. In particular, MQ-2 AO must use a voltage divider and never exceed the ESP32 GPIO voltage limit.

## E. What the Flutter app now does

- Uses Firebase Authentication for login and account creation.
- Listens to `/devices/esp32_001/sensors`, `/status`, and `/events/esp32_001`.
- Sends arm/disarm commands to `/devices/esp32_001/commands/armed`.
- Displays live motion and online/armed state through the existing dashboard widgets.

The supplied hardware list has no camera, battery monitor, or night-vision output. Those original demo UI fields are not real hardware telemetry and should be hidden or replaced with door, smoke/gas, and gas raw-value cards before release. The demo simulator has been removed from the main navigation.

## F. Test checklist

- Create an app account and confirm a Firebase Auth user appears.
- Add that user's UID to `/deviceOwners/esp32_001`.
- Confirm the ESP32 device account UID is in `/deviceAuthUids/esp32_001`.
- Power the ESP32 and confirm `/status/online`, `/sensors/motion`, `/sensors/doorOpen`, `/sensors/smoke`, and `/sensors/gasRaw` update.
- Trigger PIR and open the MC-38 contact; confirm events appear in the app.
- Toggle Security Mode and confirm `/commands/armed` changes and the ESP32 mirrors the value into `/status/armed`.
- Disconnect Wi-Fi; local alarm behavior should continue, then reconnect and verify cloud sync.

## Production caveats

This is not a certified security or fire alarm. MQ-2 raw ADC counts are not ppm and must be calibrated against the actual module; MQ-2 needs manufacturer-recommended burn-in/conditioning. Use certified smoke/CO alarms as primary life-safety devices.

The example ESP32 sketch's `setInsecure()` TLS setting is for initial bench testing only. Replace it with certificate validation before deployment. Device credentials stored in firmware can be extracted; use unique per-device credentials and a trusted backend/token design for production. Configure a server-side stale-heartbeat monitor to mark devices offline when `lastSeen` stops advancing.
