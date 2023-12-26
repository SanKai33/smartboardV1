// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCKyhR2YsPJCIHCacEafOBWaSQg_23gUfw',
    appId: '1:869187566575:web:4cb4f73d84229dc643141a',
    messagingSenderId: '869187566575',
    projectId: 'smartboard-d1392',
    authDomain: 'smartboard-d1392.firebaseapp.com',
    databaseURL: 'https://smartboard-d1392-default-rtdb.firebaseio.com',
    storageBucket: 'smartboard-d1392.appspot.com',
    measurementId: 'G-Q0MHPR1WDX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDaUpsvUtgoJAwZLhSMznXzzZYjneJhFd0',
    appId: '1:869187566575:android:97b00f154210d97f43141a',
    messagingSenderId: '869187566575',
    projectId: 'smartboard-d1392',
    databaseURL: 'https://smartboard-d1392-default-rtdb.firebaseio.com',
    storageBucket: 'smartboard-d1392.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAzWdKPSHSi_Eies7T6NP8u-X5dKvMX9Kc',
    appId: '1:869187566575:ios:931b8da4b3254d0f43141a',
    messagingSenderId: '869187566575',
    projectId: 'smartboard-d1392',
    databaseURL: 'https://smartboard-d1392-default-rtdb.firebaseio.com',
    storageBucket: 'smartboard-d1392.appspot.com',
    iosBundleId: 'com.smartboard1.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAzWdKPSHSi_Eies7T6NP8u-X5dKvMX9Kc',
    appId: '1:869187566575:ios:81292e3963a52cc943141a',
    messagingSenderId: '869187566575',
    projectId: 'smartboard-d1392',
    databaseURL: 'https://smartboard-d1392-default-rtdb.firebaseio.com',
    storageBucket: 'smartboard-d1392.appspot.com',
    iosBundleId: 'com.smartboard.app.smartboard.RunnerTests',
  );
}
