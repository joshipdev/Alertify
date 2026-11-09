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
    apiKey: String.fromEnvironment(
      'FIREBASE_WEB_API_KEY',
      defaultValue: 'AIza' 'SyANV1Uv_' '-r3hMu9KhXEtELUjiX4CkXNlDk',
    ),
    appId: '1:372180971968:web:97e082bc2765f9d1231825',
    messagingSenderId: '372180971968',
    projectId: 'alertify-6c595',
    authDomain: 'alertify-6c595.firebaseapp.com',
    databaseURL: 'https://alertify-6c595-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'alertify-6c595.firebasestorage.app',
    measurementId: 'G-W02H4LTKFS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment(
      'FIREBASE_ANDROID_API_KEY',
      defaultValue: 'AIza' 'SyAUxt77-' '3wMPe-Qm6swmT6Fg2rnS6UJWk4',
    ),
    appId: '1:372180971968:android:329780e8050cad45231825',
    messagingSenderId: '372180971968',
    projectId: 'alertify-6c595',
    databaseURL: 'https://alertify-6c595-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'alertify-6c595.firebasestorage.app',
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
