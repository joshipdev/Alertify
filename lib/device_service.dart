import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

enum AlertType {
  motion, armed, disarmed, lowBattery, cameraOffline,
  doorOpen, smoke, gas, deviceOnline, unknown
}

class AlertEvent {
  final AlertType type;
  final String title;
  final String subtitle;
  final DateTime time;
  AlertEvent(this.type, this.title, this.subtitle, this.time);
}

/// Live gateway between Alertify UI and ESP32 data in Firebase RTDB.
/// The ESP32 device ID must match the firmware DEVICE_ID.
class DeviceService extends ChangeNotifier {
  DeviceService({
    FirebaseDatabase? database,
    FirebaseAuth? auth,
    this.deviceId = 'esp32_001',
  })  : _db = database ?? FirebaseDatabase.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseDatabase _db;
  final FirebaseAuth _auth;
  final String deviceId;

  String userEmail = '';
  bool armed = true;
  bool cameraOnline = false;
  bool motionActive = false;
  bool doorOpen = false;
  bool smokeDetected = false;
  bool alarmActive = false;
  bool nightVision = false; // Not supported by the listed ESP32 hardware.
  double sensitivity = 0.6; // Threshold is configured in firmware for now.
  int battery = 0; // No battery sensor is included in this hardware list.
  int gasRaw = 0;
  bool mq2Ready = false;
  bool connected = false;

  final List<AlertEvent> events = [];
  StreamSubscription<DatabaseEvent>? _sensorsSub;
  StreamSubscription<DatabaseEvent>? _statusSub;
  StreamSubscription<DatabaseEvent>? _eventsSub;
  StreamSubscription<DatabaseEvent>? _onlineSub;

  DatabaseReference get _device => _db.ref('devices/$deviceId');
  DatabaseReference get _sensors => _device.child('sensors');
  DatabaseReference get _status => _device.child('status');
  DatabaseReference get _commands => _device.child('commands');
  DatabaseReference get _eventRef => _db.ref('events/$deviceId');

  bool get isSafe => cameraOnline && !alarmActive && armed;

  Future<void> connect() async {
    if (_sensorsSub != null) return;
    userEmail = _auth.currentUser?.email ?? userEmail;
    _sensorsSub = _sensors.onValue.listen(_onSensors, onError: _onError);
    _statusSub = _status.onValue.listen(_onStatus, onError: _onError);
    _eventsSub = _eventRef.orderByKey().limitToLast(100).onValue
        .listen(_onEvents, onError: _onError);
    // RTDB onDisconnect is not configured from the app; online is derived
    // from ESP32's lastSeen heartbeat and should be marked stale server-side.
    connected = true;
    notifyListeners();
  }

  void _onSensors(DatabaseEvent event) {
    final data = _map(event.snapshot.value);
    motionActive = data['motion'] == true;
    smokeDetected = data['smoke'] == true;
    doorOpen = data['doorOpen'] == true;
    gasRaw = _int(data['gasRaw']);
    mq2Ready = data['mq2Ready'] == true;
    notifyListeners();
  }

  void _onStatus(DatabaseEvent event) {
    final data = _map(event.snapshot.value);
    final lastSeenSeconds = _int(data['lastSeen']);
    final lastSeen = lastSeenSeconds > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastSeenSeconds * 1000)
        : null;
    // Treat a heartbeat older than 30 seconds as offline in this app.
    cameraOnline = data['online'] == true &&
        lastSeen != null &&
        DateTime.now().difference(lastSeen).inSeconds <= 30;
    armed = data['armed'] == true;
    alarmActive = data['alarm'] == true;
    notifyListeners();
  }

  void _onEvents(DatabaseEvent event) {
    final raw = _map(event.snapshot.value);
    final parsed = <AlertEvent>[];
    raw.forEach((key, value) {
      final item = _map(value);
      final type = (item['type'] ?? 'unknown').toString();
      final timestamp = _int(item['timestamp']);
      final time = timestamp > 0
          ? DateTime.fromMillisecondsSinceEpoch(timestamp * 1000)
          : DateTime.now();
      final mapped = _eventType(type);
      parsed.add(AlertEvent(mapped, _eventTitle(type),
          (item['message'] ?? '').toString(), time));
    });
    parsed.sort((a, b) => b.time.compareTo(a.time));
    events
      ..clear()
      ..addAll(parsed.take(100));
    notifyListeners();
  }

  AlertType _eventType(String type) {
    switch (type) {
      case 'motion': return AlertType.motion;
      case 'door_open': return AlertType.doorOpen;
      case 'smoke': return AlertType.smoke;
      case 'gas': return AlertType.gas;
      case 'armed': return AlertType.armed;
      case 'disarmed': return AlertType.disarmed;
      default: return AlertType.unknown;
    }
  }

  String _eventTitle(String type) {
    switch (type) {
      case 'motion': return 'Motion Detected';
      case 'door_open': return 'Door / Window Open';
      case 'smoke': return 'Smoke / Gas Warning';
      case 'armed': return 'System Armed';
      case 'disarmed': return 'System Disarmed';
      default: return 'Security Event';
    }
  }

  Map<String, dynamic> _map(Object? value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  int _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;

  void _onError(Object error) {
    debugPrint('Alertify Firebase stream error: $error');
    connected = false;
    notifyListeners();
  }

  Future<void> setArmed(bool value) async {
    // Optimistically update local state for immediate UI feedback;
    // and attempt to write command to ESP32 via Firebase RTDB if available.
    armed = value;
    notifyListeners();
    try {
      await _commands.child('armed').set(value);
    } catch (e) {
      debugPrint('Note: RTDB armed command write skipped or offline: $e');
    }
  }

  void setNightVision(bool value) {
    nightVision = value;
    notifyListeners();
  }

  void setSensitivity(double value) {
    sensitivity = value;
    notifyListeners();
  }

  // Interactive testing / simulation methods (useful for demos and bench testing)
  Timer? _motionResetTimer;

  void setCameraOnline(bool value) {
    cameraOnline = value;
    notifyListeners();
  }

  void triggerMotion() {
    motionActive = true;
    events.insert(
      0,
      AlertEvent(
        AlertType.motion,
        'Motion Detected',
        'Front Door (Simulated)',
        DateTime.now(),
      ),
    );
    notifyListeners();
    _motionResetTimer?.cancel();
    _motionResetTimer = Timer(const Duration(seconds: 4), () {
      motionActive = false;
      notifyListeners();
    });
  }

  void toggleDoor() {
    doorOpen = !doorOpen;
    events.insert(
      0,
      AlertEvent(
        AlertType.doorOpen,
        doorOpen ? 'Door / Window Opened' : 'Door / Window Closed',
        'Main Entrance (Simulated)',
        DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void toggleSmoke() {
    smokeDetected = !smokeDetected;
    gasRaw = smokeDetected ? 2400 : 350;
    mq2Ready = true;
    if (smokeDetected) {
      events.insert(
        0,
        AlertEvent(
          AlertType.smoke,
          'Smoke / Gas Warning',
          'Threshold exceeded (Simulated)',
          DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  void drainBattery() {
    battery = (battery <= 0 ? 100 : battery - 20).clamp(0, 100);
    if (battery <= 20) {
      events.insert(
        0,
        AlertEvent(
          AlertType.lowBattery,
          'Battery Low',
          'Camera battery at $battery%',
          DateTime.now(),
        ),
      );
    }
    notifyListeners();
  }

  void clearEvents() {
    events.clear();
    notifyListeners();
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {}
    await disposeStreams();
  }

  Future<void> disposeStreams() async {
    _motionResetTimer?.cancel();
    await _sensorsSub?.cancel();
    await _statusSub?.cancel();
    await _eventsSub?.cancel();
    await _onlineSub?.cancel();
    _sensorsSub = null;
    _statusSub = null;
    _eventsSub = null;
    connected = false;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeStreams();
    super.dispose();
  }
}

final DeviceService device = DeviceService();
