// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
    apiKey: 'AIzaSyAkTknZDfwrYgpUX2LmMmq2MShWYWFKTWc',
    appId: '1:436919223526:web:7ff1548f1576f67a72a727',
    messagingSenderId: '436919223526',
    projectId: 'collectorhub-f6fc7',
    authDomain: 'collectorhub-f6fc7.firebaseapp.com',
    storageBucket: 'collectorhub-f6fc7.appspot.com',
    measurementId: 'G-ZC922LQBT8',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAUkmx0MqoeyIn1sxo4xZO_Xsh1I94hh98',
    appId: '1:436919223526:android:b4b547ae48d1cb2c72a727',
    messagingSenderId: '436919223526',
    projectId: 'collectorhub-f6fc7',
    storageBucket: 'collectorhub-f6fc7.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDhnB6xX1jcWDPT4cPZqBOhgv3kHn_6Y9o',
    appId: '1:436919223526:ios:f62c41ba20ecc7d172a727',
    messagingSenderId: '436919223526',
    projectId: 'collectorhub-f6fc7',
    storageBucket: 'collectorhub-f6fc7.appspot.com',
    iosBundleId: 'com.example.collectorhub',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDhnB6xX1jcWDPT4cPZqBOhgv3kHn_6Y9o',
    appId: '1:436919223526:ios:f62c41ba20ecc7d172a727',
    messagingSenderId: '436919223526',
    projectId: 'collectorhub-f6fc7',
    storageBucket: 'collectorhub-f6fc7.appspot.com',
    iosBundleId: 'com.example.collectorhub',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAkTknZDfwrYgpUX2LmMmq2MShWYWFKTWc',
    appId: '1:436919223526:web:e02e8c91543c32d872a727',
    messagingSenderId: '436919223526',
    projectId: 'collectorhub-f6fc7',
    authDomain: 'collectorhub-f6fc7.firebaseapp.com',
    storageBucket: 'collectorhub-f6fc7.appspot.com',
    measurementId: 'G-GRGQBR3VHN',
  );

}