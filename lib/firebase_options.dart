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
        throw UnsupportedError('iOS not configured.');
      default:
        throw UnsupportedError('Unsupported platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDpm5VyWRk_SNyBH0ECOMPOzfJVIZ55bOo',
    appId: '1:720451154201:android:e28f8f65705729e5ffd588',
    messagingSenderId: '720451154201',
    projectId: 'dailyserv-d65aa',
    storageBucket: 'dailyserv-d65aa.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCH1SSADXDXaSz2VgVaSPvRLugD_a47EKg',
    appId: '1:720451154201:web:6fad27c139bbc349ffd588',
    messagingSenderId: '720451154201',
    projectId: 'dailyserv-d65aa',
    authDomain: 'dailyserv-d65aa.firebaseapp.com',
    storageBucket: 'dailyserv-d65aa.firebasestorage.app',
    measurementId: 'G-1X558Z39SE',
  );
}
