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
    apiKey: 'AIzaSyC-XkeXD8fYfGqLhj95FfgfSTCU18E7wb8',
    appId: '1:224160397591:web:07458b13606eddc32b5f52',
    messagingSenderId: '224160397591',
    projectId: 'flutter-backend-c5341',
    authDomain: 'flutter-backend-c5341.firebaseapp.com',
    storageBucket: 'flutter-backend-c5341.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD19sTqx-muJaIAm9429UwO5JcescIZEsM',
    appId: '1:224160397591:android:6efd762d29a54dc02b5f52',
    messagingSenderId: '224160397591',
    projectId: 'flutter-backend-c5341',
    storageBucket: 'flutter-backend-c5341.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDFq6rHNTbJVNU6ffVlWZHwwz-gNHNuPVo',
    appId: '1:224160397591:ios:ef58b0c063d869952b5f52',
    messagingSenderId: '224160397591',
    projectId: 'flutter-backend-c5341',
    storageBucket: 'flutter-backend-c5341.firebasestorage.app',
    iosBundleId: 'com.example.projectFlutter',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDFq6rHNTbJVNU6ffVlWZHwwz-gNHNuPVo',
    appId: '1:224160397591:ios:ef58b0c063d869952b5f52',
    messagingSenderId: '224160397591',
    projectId: 'flutter-backend-c5341',
    storageBucket: 'flutter-backend-c5341.firebasestorage.app',
    iosBundleId: 'com.example.projectFlutter',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyC-XkeXD8fYfGqLhj95FfgfSTCU18E7wb8',
    appId: '1:224160397591:web:01e8019f7cca86bd2b5f52',
    messagingSenderId: '224160397591',
    projectId: 'flutter-backend-c5341',
    authDomain: 'flutter-backend-c5341.firebaseapp.com',
    storageBucket: 'flutter-backend-c5341.firebasestorage.app',
  );
}
