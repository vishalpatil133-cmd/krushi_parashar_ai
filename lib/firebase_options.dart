import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'config/secrets.dart';

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
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDv2qxVJS2Qu9npXKjhCO4zir-o_2iHdps',
    appId: '1:892957828820:android:0226ec24f3e2e89be0bd41', // Using android config for fallback
    messagingSenderId: '892957828820',
    projectId: 'gw-parashar-ai-based',
    authDomain: 'gw-parashar-ai-based.firebaseapp.com',
    databaseURL: Secrets.firebaseDatabaseUrl,
    storageBucket: 'gw-parashar-ai-based.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDv2qxVJS2Qu9npXKjhCO4zir-o_2iHdps',
    appId: '1:892957828820:android:0226ec24f3e2e89be0bd41',
    messagingSenderId: '892957828820',
    projectId: 'gw-parashar-ai-based',
    databaseURL: Secrets.firebaseDatabaseUrl,
    storageBucket: 'gw-parashar-ai-based.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDv2qxVJS2Qu9npXKjhCO4zir-o_2iHdps',
    appId: '1:892957828820:android:0226ec24f3e2e89be0bd41',
    messagingSenderId: '892957828820',
    projectId: 'gw-parashar-ai-based',
    databaseURL: Secrets.firebaseDatabaseUrl,
    storageBucket: 'gw-parashar-ai-based.firebasestorage.app',
    iosBundleId: 'com.agritech.krishiParasharaAi',
  );
}
