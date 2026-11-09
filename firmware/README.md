# ESP32 wiring quick reference

| Component | ESP32 pin |
|---|---|
| HC-SR501 OUT | GPIO27 |
| MQ-2 AO | GPIO34 through divider |
| MC-38 contact | GPIO26 to GND |
| LCD SDA | GPIO21 |
| LCD SCL | GPIO22 |
| Active buzzer driver input | GPIO25 |
| Grounds | Common GND |

MQ-2 module supply is typically 5V. Do not connect its AO directly to an ESP32 GPIO. Example divider: 10kΩ from AO to GPIO34 and 20kΩ from GPIO34 to GND, after confirming the module output does not exceed the design limit. Check LCD backpack pull-up voltage; ESP32 I2C pins are not 5V tolerant.

MC-38 assumes closed = GPIO pulled LOW, open = HIGH. Adjust firmware if your wiring/module logic differs. Use a transistor driver for a buzzer whose current exceeds safe GPIO drive.
