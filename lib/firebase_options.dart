// File generated as a starter template for Alertify.
// When connecting to your live Firebase project, run:
//   flutterfire configure
// to regenerate this file with your project's exact keys and identifiers.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PASTE_YOUR_WEB_API_KEY_HERE',
    appId: '1:alertify:web:client',
    messagingSenderId: 'alertify-6c595',
    projectId: 'alertify-6c595',
    authDomain: 'alertify-6c595.firebaseapp.com',
    databaseURL: 'https://alertify-6c595-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'alertify-6c595.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'PASTE_YOUR_WEB_API_KEY_HERE',
    appId: '1:alertify:android:client',
    messagingSenderId: 'alertify-6c595',
    projectId: 'alertify-6c595',
    databaseURL: 'https://alertify-6c595-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'alertify-6c595.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PASTE_YOUR_WEB_API_KEY_HERE',
    appId: '1:alertify:ios:client',
    messagingSenderId: 'alertify-6c595',
    projectId: 'alertify-6c595',
    databaseURL: 'https://alertify-6c595-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'alertify-6c595.appspot.com',
    iosBundleId: 'com.example.alertify',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'PASTE_YOUR_WEB_API_KEY_HERE',
    appId: '1:alertify:ios:client',
    messagingSenderId: 'alertify-6c595',
    projectId: 'alertify-6c595',
    databaseURL: 'https://alertify-6c595-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'alertify-6c595.appspot.com',
    iosBundleId: 'com.example.alertify',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'PASTE_YOUR_WEB_API_KEY_HERE',
    appId: '1:alertify:web:client',
    messagingSenderId: 'alertify-6c595',
    projectId: 'alertify-6c595',
    authDomain: 'alertify-6c595.firebaseapp.com',
    databaseURL: 'https://alertify-6c595-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'alertify-6c595.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'PASTE_YOUR_WEB_API_KEY_HERE',
    appId: '1:alertify:web:client',
    messagingSenderId: 'alertify-6c595',
    projectId: 'alertify-6c595',
    authDomain: 'alertify-6c595.firebaseapp.com',
    databaseURL: 'https://alertify-6c595-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'alertify-6c595.appspot.com',
  );
}
