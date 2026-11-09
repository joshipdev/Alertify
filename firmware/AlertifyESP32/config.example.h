#pragma once

// Copy this file to config.h and fill in your own values.
// Do not commit config.h to a public repository.
#define WIFI_SSID       "YOUR_WIFI_NAME"
#define WIFI_PASSWORD   "YOUR_WIFI_PASSWORD"

#define FIREBASE_API_KEY       "YOUR_FIREBASE_WEB_API_KEY"
#define FIREBASE_DATABASE_URL  "https://alertify-6c595-default-rtdb.asia-southeast1.firebasedatabase.app"
#define FIREBASE_DEVICE_EMAIL  "esp32-device@your-project.firebaseapp.com"
#define FIREBASE_DEVICE_PASSWORD "CREATE_A_DEDICATED_DEVICE_ACCOUNT_PASSWORD"

#define DEVICE_ID "esp32_001"

// Calibrate this value after observing clean-air and test readings.
// MQ-2 analogRead is a raw ADC count, not a ppm measurement.
#define MQ2_ALARM_THRESHOLD 1800
