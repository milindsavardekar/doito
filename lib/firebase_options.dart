// File generated based on doito Firebase project (doito-40aa5)
// google-services.json package: com.example.doito

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'iOS is not configured. Add GoogleService-Info.plist and update this file.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBbxnJZ6ozwr7umCHiSxzk0M2mEvuwmRJQ',
    appId: '1:775345098426:web:doito',
    messagingSenderId: '775345098426',
    projectId: 'doito-40aa5',
    authDomain: 'doito-40aa5.firebaseapp.com',
    storageBucket: 'doito-40aa5.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBbxnJZ6ozwr7umCHiSxzk0M2mEvuwmRJQ',
    appId: '1:775345098426:android:e99f62cba60d772867fc83',
    messagingSenderId: '775345098426',
    projectId: 'doito-40aa5',
    storageBucket: 'doito-40aa5.firebasestorage.app',
  );
}
