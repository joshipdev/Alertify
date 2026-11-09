import 'package:firebase_database/firebase_database.dart';

/// Replace the simulated DeviceService data source with this Firebase service.
/// Ensure Firebase.initializeApp() and Firebase Authentication are configured
/// in main() before constructing this class.
class AlertifyFirebaseService {
  AlertifyFirebaseService({
    FirebaseDatabase? database,
    this.deviceId = 'esp32_001',
  }) : _db = database ?? FirebaseDatabase.instance;

  final FirebaseDatabase _db;
  final String deviceId;

  DatabaseReference get _device => _db.ref('devices/$deviceId');
  DatabaseReference get _sensors => _device.child('sensors');
  DatabaseReference get _status => _device.child('status');
  DatabaseReference get _events => _db.ref('events/$deviceId');

  Stream<DatabaseEvent> watchSensors() => _sensors.onValue;
  Stream<DatabaseEvent> watchStatus() => _status.onValue;
  Stream<DatabaseEvent> watchEvents() => _events.orderByKey().limitToLast(100).onValue;

  Future<void> setArmed(bool armed) =>
      _device.child('commands/armed').set(armed);

  Future<void> dispose() async {
    // Firebase Database streams are cancelled by cancelling their StreamSubscriptions
    // in the widgets/controllers that listen to them.
  }
}
