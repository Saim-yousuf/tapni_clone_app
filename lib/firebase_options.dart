// Generated from android/app/google-services.json (project: barqody-2fb4e)
// For iOS: add app in Firebase Console, download GoogleService-Info.plist,
// then run `flutterfire configure` after installing Firebase CLI.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDaS-iYGsThfzquD1oYN1E31ux6x61XvCw',
    appId: '1:335461782414:android:3ca4867fe13c1857188adf',
    messagingSenderId: '335461782414',
    projectId: 'barqody-2fb4e',
    authDomain: 'barqody-2fb4e.firebaseapp.com',
    storageBucket: 'barqody-2fb4e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDaS-iYGsThfzquD1oYN1E31ux6x61XvCw',
    appId: '1:335461782414:android:3ca4867fe13c1857188adf',
    messagingSenderId: '335461782414',
    projectId: 'barqody-2fb4e',
    storageBucket: 'barqody-2fb4e.firebasestorage.app',
  );

  // Add iOS app in Firebase Console and run flutterfire configure to replace these.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDaS-iYGsThfzquD1oYN1E31ux6x61XvCw',
    appId: '1:335461782414:android:3ca4867fe13c1857188adf',
    messagingSenderId: '335461782414',
    projectId: 'barqody-2fb4e',
    storageBucket: 'barqody-2fb4e.firebasestorage.app',
    iosBundleId: 'com.example.tapniApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDaS-iYGsThfzquD1oYN1E31ux6x61XvCw',
    appId: '1:335461782414:android:3ca4867fe13c1857188adf',
    messagingSenderId: '335461782414',
    projectId: 'barqody-2fb4e',
    storageBucket: 'barqody-2fb4e.firebasestorage.app',
    iosBundleId: 'com.example.tapniApp',
  );
}
