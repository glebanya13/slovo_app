// Firebase apps: Slovo (dev.davinchi.slovo) in project christian-ai-app.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => switch (defaultTargetPlatform) {
        TargetPlatform.android => android,
        _ => ios,
      };

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA1eYyy9OSN8qgkztHktS_gjV4hth25UNc',
    appId: '1:414144943487:android:c82a47f5fb742c3f88364a',
    messagingSenderId: '414144943487',
    projectId: 'christian-ai-app',
    storageBucket: 'christian-ai-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCAeLz6t_kDeR1i4HJdxtkNvUCEgwXH3PU',
    appId: '1:414144943487:ios:bb5eb480202eeac288364a',
    messagingSenderId: '414144943487',
    projectId: 'christian-ai-app',
    storageBucket: 'christian-ai-app.firebasestorage.app',
    iosBundleId: 'dev.davinchi.slovo',
    iosClientId: '414144943487-rqhkfs9js6c5gb4rfuu3hduh81thc1h3.apps.googleusercontent.com',
  );
}
