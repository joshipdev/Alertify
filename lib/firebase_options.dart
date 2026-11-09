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
    apiKey: 'AIzaSyDemo-WebKey-Alertify-Default',
    appId: '1:1234567890:web:demo-alertify',
    messagingSenderId: '1234567890',
    projectId: 'alertify-demo-project',
    authDomain: 'alertify-demo-project.firebaseapp.com',
    databaseURL: 'https://alertify-demo-project-default-rtdb.firebaseio.com',
    storageBucket: 'alertify-demo-project.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDemo-AndroidKey-Alertify-Default',
    appId: '1:1234567890:android:demo-alertify',
    messagingSenderId: '1234567890',
    projectId: 'alertify-demo-project',
    databaseURL: 'https://alertify-demo-project-default-rtdb.firebaseio.com',
    storageBucket: 'alertify-demo-project.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDemo-IosKey-Alertify-Default',
    appId: '1:1234567890:ios:demo-alertify',
    messagingSenderId: '1234567890',
    projectId: 'alertify-demo-project',
    databaseURL: 'https://alertify-demo-project-default-rtdb.firebaseio.com',
    storageBucket: 'alertify-demo-project.appspot.com',
    iosBundleId: 'com.example.alertify',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDemo-IosKey-Alertify-Default',
    appId: '1:1234567890:ios:demo-alertify',
    messagingSenderId: '1234567890',
    projectId: 'alertify-demo-project',
    databaseURL: 'https://alertify-demo-project-default-rtdb.firebaseio.com',
    storageBucket: 'alertify-demo-project.appspot.com',
    iosBundleId: 'com.example.alertify',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDemo-WebKey-Alertify-Default',
    appId: '1:1234567890:web:demo-alertify',
    messagingSenderId: '1234567890',
    projectId: 'alertify-demo-project',
    authDomain: 'alertify-demo-project.firebaseapp.com',
    databaseURL: 'https://alertify-demo-project-default-rtdb.firebaseio.com',
    storageBucket: 'alertify-demo-project.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyDemo-WebKey-Alertify-Default',
    appId: '1:1234567890:web:demo-alertify',
    messagingSenderId: '1234567890',
    projectId: 'alertify-demo-project',
    authDomain: 'alertify-demo-project.firebaseapp.com',
    databaseURL: 'https://alertify-demo-project-default-rtdb.firebaseio.com',
    storageBucket: 'alertify-demo-project.appspot.com',
  );
}
