// Firebase configuration for the "butula" project (project_id: butula-bcf9d).
// Values are taken from google-services.json (Android) and
// GoogleService-Info.plist (iOS). Cloud Firestore + Auth only.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web is not configured for this app. Use Android or iOS.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDOKbKH3_Krv54TocnKg2OSqOHdWg0l7Uc',
    appId: '1:565318897084:android:20854e8ee8f88a25f9afb9',
    messagingSenderId: '565318897084',
    projectId: 'butula-bcf9d',
    storageBucket: 'butula-bcf9d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAFQ_qOjNMSm78OlP1PSrG1CSTRB-SfDew',
    appId: '1:565318897084:ios:3753cb61cf2d4142f9afb9',
    messagingSenderId: '565318897084',
    projectId: 'butula-bcf9d',
    storageBucket: 'butula-bcf9d.firebasestorage.app',
    iosBundleId: 'com.yousef.butula',
  );
}
