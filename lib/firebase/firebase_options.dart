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
    apiKey: 'AIzaSyAZn4NCeVG7pGoTkomuYnSaYO9yitQoZN8',
    appId: '1:429437450152:web:4e026160903e7b1aab8f9d',
    messagingSenderId: '429437450152',
    projectId: 'cursor-c2233',
    authDomain: 'cursor-c2233.firebaseapp.com',
    storageBucket: 'cursor-c2233.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD9TLliimKFPBVGLGxWWK_3ZIQf3CCwSS0',
    appId: '1:429437450152:android:ee8b5befdf729eccab8f9d',
    messagingSenderId: '429437450152',
    projectId: 'cursor-c2233',
    storageBucket: 'cursor-c2233.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBg5sFwEA36Z7DNW9KP4bT3k9tnEUgPsRY',
    appId: '1:429437450152:ios:4b467e388d5c4baeab8f9d',
    messagingSenderId: '429437450152',
    projectId: 'cursor-c2233',
    storageBucket: 'cursor-c2233.appspot.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBg5sFwEA36Z7DNW9KP4bT3k9tnEUgPsRY',
    appId: '1:429437450152:ios:4b467e388d5c4baeab8f9d',
    messagingSenderId: '429437450152',
    projectId: 'cursor-c2233',
    storageBucket: 'cursor-c2233.appspot.com',
    iosBundleId: 'com.example.flutterApplication1',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAZn4NCeVG7pGoTkomuYnSaYO9yitQoZN8',
    appId: '1:429437450152:web:0bb0792103e3cdd7ab8f9d',
    messagingSenderId: '429437450152',
    projectId: 'cursor-c2233',
    authDomain: 'cursor-c2233.firebaseapp.com',
    storageBucket: 'cursor-c2233.appspot.com',
  );
}
