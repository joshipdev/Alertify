/*
 * Alertify ESP32 firmware
 * Board: ESP32 Dev Module / ESP-WROOM-32
 * Framework: Arduino-ESP32
 *
 * Libraries (Arduino Library Manager):
 *   - FirebaseClient by Mobizt (2.x)
 *   - LiquidCrystal_I2C
 *
 * IMPORTANT:
 *   - MQ-2 AO must pass through a voltage divider before GPIO34.
 *   - Never apply 5V to an ESP32 GPIO.
 *   - This is a reference implementation, not a certified life-safety alarm.
 */

#define ENABLE_USER_AUTH
#define ENABLE_DATABASE

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <FirebaseClient.h>
#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <time.h>
#include "config.h"

// ----------------------------- Pin mapping -----------------------------
namespace Pins {
  constexpr uint8_t PIR = 27;
  constexpr uint8_t MQ2 = 34;       // ADC1 input-only pin
  constexpr uint8_t CONTACT = 26;   // MC-38 contact to GND
  constexpr uint8_t BUZZER = 25;    // Use transistor driver if needed
  constexpr uint8_t SDA = 21;
  constexpr uint8_t SCL = 22;
}

// ----------------------------- Timing ----------------------------------
namespace Timing {
  constexpr uint32_t SENSOR_POLL_MS = 100;
  constexpr uint32_t CLOUD_UPDATE_MS = 5000;
  constexpr uint32_t LCD_UPDATE_MS = 500;
  constexpr uint32_t WIFI_RETRY_MS = 10000;
  constexpr uint32_t MQ2_WARMUP_MS = 60000; // sensor needs much longer initial burn-in
  constexpr uint32_t EVENT_COOLDOWN_MS = 3000;
}

// ----------------------------- Firebase --------------------------------
WiFiClientSecure sslClient;
using AsyncClient = AsyncClientClass;
AsyncClient firebaseClient(sslClient);
UserAuth deviceAuth(FIREBASE_API_KEY, FIREBASE_DEVICE_EMAIL, FIREBASE_DEVICE_PASSWORD);
FirebaseApp firebaseApp;
RealtimeDatabase rtdb;

String deviceRoot = String("/devices/") + DEVICE_ID;
String eventsRoot = String("/events/") + DEVICE_ID;

void firebaseResult(AsyncResult &result) {
  if (!result.isResult()) return;
  if (result.isError()) {
    Serial.printf("[Firebase] %s (%d)\n",
      result.error().message().c_str(), result.error().code());
  } else if (result.isDebug()) {
    Serial.printf("[Firebase] %s\n", result.debug().c_str());
  }
}

// ----------------------------- Models ----------------------------------
struct SensorState {
  bool motion = false;
  bool smoke = false;
  bool doorOpen = false;
  int gasRaw = 0;
  bool armed = true;
  bool alarm = false;
};

SensorState currentState;
SensorState previousState;

LiquidCrystal_I2C lcd(0x27, 16, 2);

uint32_t bootAt = 0;
uint32_t lastSensorPoll = 0;
uint32_t lastCloudUpdate = 0;
uint32_t lastLcdUpdate = 0;
uint32_t lastWifiAttempt = 0;
uint32_t lastEventAt = 0;
bool firebaseReady = false;
bool mq2Ready = false;
bool alarmOutput = false;

// ----------------------------- Hardware --------------------------------
void setupHardware() {
  pinMode(Pins::PIR, INPUT);
  pinMode(Pins::CONTACT, INPUT_PULLUP);
  pinMode(Pins::BUZZER, OUTPUT);
  digitalWrite(Pins::BUZZER, LOW);

  analogReadResolution(12);
  analogSetPinAttenuation(Pins::MQ2, ADC_11db);

  Wire.begin(Pins::SDA, Pins::SCL);
  lcd.init();
  lcd.backlight();
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print("Alertify Booting");
  lcd.setCursor(0, 1);
  lcd.print("Please wait...");
}

void connectWiFi() {
  if (WiFi.status() == WL_CONNECTED) return;
  if (millis() - lastWifiAttempt < Timing::WIFI_RETRY_MS) return;
  lastWifiAttempt = millis();

  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.println("[WiFi] Connecting...");
}

void setupClock() {
  // Philippines time (UTC+8). Change if deploying elsewhere.
  configTime(8 * 3600, 0, "pool.ntp.org", "time.google.com");
}

void setupFirebase() {
  // NOTE: setInsecure() disables TLS certificate validation.
  // For production, configure a trusted CA certificate instead.
  sslClient.setInsecure();
  sslClient.setConnectionTimeout(1000);
  sslClient.setHandshakeTimeout(5);

  initializeApp(firebaseClient, firebaseApp, getAuth(deviceAuth),
                 firebaseResult, "firebaseAuth");
  firebaseApp.getApp<RealtimeDatabase>(rtdb);
  rtdb.url(FIREBASE_DATABASE_URL);
}

uint64_t unixTime() {
  time_t now = time(nullptr);
  if (now > 1700000000) return static_cast<uint64_t>(now);
  return 0; // zero means NTP time is not ready yet
}

// ----------------------------- Sensor logic ----------------------------
void readSensors() {
  currentState.motion = digitalRead(Pins::PIR) == HIGH;

  // Assumes the contact is wired from GPIO26 to GND when closed.
  // INPUT_PULLUP: LOW = closed, HIGH = open.
  currentState.doorOpen = digitalRead(Pins::CONTACT) == HIGH;

  currentState.gasRaw = analogRead(Pins::MQ2);
  mq2Ready = (millis() - bootAt) >= Timing::MQ2_WARMUP_MS;
  currentState.smoke = mq2Ready &&
                       currentState.gasRaw >= MQ2_ALARM_THRESHOLD;

  // Smoke/gas is always treated as an alarm, even when security is disarmed.
  currentState.alarm = currentState.smoke ||
    (currentState.armed && (currentState.motion || currentState.doorOpen));
}

void setAlarmOutput() {
  alarmOutput = currentState.alarm;
  digitalWrite(Pins::BUZZER, alarmOutput ? HIGH : LOW);
}

void displayStatus() {
  lcd.clear();
  lcd.setCursor(0, 0);
  if (currentState.smoke) lcd.print("WARNING: GAS!");
  else if (currentState.alarm) lcd.print("SECURITY ALERT");
  else lcd.print(currentState.armed ? "System: ARMED" : "System: SAFE");

  lcd.setCursor(0, 1);
  if (currentState.doorOpen) lcd.print("Door: OPEN");
  else if (currentState.motion) lcd.print("Motion detected");
  else if (!mq2Ready) lcd.print("MQ2 warming up");
  else lcd.print("Gas:");
  if (!currentState.doorOpen && !currentState.motion && mq2Ready) {
    lcd.setCursor(4, 1);
    lcd.print(currentState.gasRaw);
  }
}

// ----------------------------- Firebase writes ------------------------
void writeValue(const String &path, bool value) {
  rtdb.set<bool>(firebaseClient, path, value, firebaseResult, "rtdbWrite");
}
void writeValue(const String &path, int value) {
  rtdb.set<int>(firebaseClient, path, value, firebaseResult, "rtdbWrite");
}
void writeValue(const String &path, uint64_t value) {
  rtdb.set<uint64_t>(firebaseClient, path, value, firebaseResult, "rtdbWrite");
}
void writeValue(const String &path, const String &value) {
  rtdb.set<String>(firebaseClient, path, value, firebaseResult, "rtdbWrite");
}

void publishSnapshot() {
  if (!firebaseApp.ready() || WiFi.status() != WL_CONNECTED) return;

  writeValue(deviceRoot + "/status/online", true);
  writeValue(deviceRoot + "/status/armed", currentState.armed);
  writeValue(deviceRoot + "/status/alarm", currentState.alarm);
  writeValue(deviceRoot + "/status/lastSeen", unixTime());
  writeValue(deviceRoot + "/sensors/motion", currentState.motion);
  writeValue(deviceRoot + "/sensors/smoke", currentState.smoke);
  writeValue(deviceRoot + "/sensors/doorOpen", currentState.doorOpen);
  writeValue(deviceRoot + "/sensors/gasRaw", currentState.gasRaw);
  writeValue(deviceRoot + "/sensors/mq2Ready", mq2Ready);
}

void publishEvent(const char *type, const char *message) {
  if (!firebaseApp.ready() || WiFi.status() != WL_CONNECTED) return;
  if (millis() - lastEventAt < Timing::EVENT_COOLDOWN_MS) return;
  lastEventAt = millis();

  // Millis-based key is unique within a boot. Include a boot ID in production
  // or use a backend-generated push key to avoid collisions after reboot.
  String eventPath = eventsRoot + "/" + String(millis());
  writeValue(eventPath + "/type", String(type));
  writeValue(eventPath + "/message", String(message));
  writeValue(eventPath + "/timestamp", unixTime());
  writeValue(eventPath + "/gasRaw", currentState.gasRaw);
}

void detectTransitions() {
  if (currentState.motion && !previousState.motion)
    publishEvent("motion", "Motion detected");

  if (currentState.doorOpen && !previousState.doorOpen)
    publishEvent("door_open", "Door or window opened");

  if (currentState.smoke && !previousState.smoke)
    publishEvent("smoke", "Smoke/gas threshold exceeded");

  previousState = currentState;
}

// ----------------------------- Remote commands -------------------------
// Mobile app writes /devices/DEVICE_ID/commands/armed.
// Polling is intentionally slow to avoid excessive requests.
uint32_t lastCommandPoll = 0;

void processCommandResult(AsyncResult &result) {
  if (!result.isResult() || !result.available()) return;
  RealtimeDatabaseResult &data = result.to<RealtimeDatabaseResult>();
  const bool requested = data.to<bool>();
  if (requested != currentState.armed) {
    currentState.armed = requested;
    publishEvent(requested ? "armed" : "disarmed",
                 requested ? "System armed remotely" : "System disarmed remotely");
    publishSnapshot();
  }
}

void pollRemoteCommand() {
  if (!firebaseApp.ready() || WiFi.status() != WL_CONNECTED) return;
  if (millis() - lastCommandPoll < 3000) return;
  lastCommandPoll = millis();
  rtdb.get(firebaseClient, deviceRoot + "/commands/armed",
           processCommandResult, "getArmedCommand");
}

// ----------------------------- Arduino entry points --------------------
void setup() {
  Serial.begin(115200);
  bootAt = millis();
  setupHardware();
  connectWiFi();
  setupClock();
  setupFirebase();
}

void loop() {
  firebaseApp.loop();
  connectWiFi();

  const uint32_t now = millis();

  if (now - lastSensorPoll >= Timing::SENSOR_POLL_MS) {
    lastSensorPoll = now;
    readSensors();
    setAlarmOutput();
    detectTransitions();
  }

  if (now - lastLcdUpdate >= Timing::LCD_UPDATE_MS) {
    lastLcdUpdate = now;
    displayStatus();
  }

  if (now - lastCloudUpdate >= Timing::CLOUD_UPDATE_MS) {
    lastCloudUpdate = now;
    publishSnapshot();
  }

  pollRemoteCommand();
}
