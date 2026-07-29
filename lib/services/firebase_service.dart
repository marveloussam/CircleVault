import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';

class FirebaseService {
  FirebaseService._();

  /// Call once in main() before runApp().
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
