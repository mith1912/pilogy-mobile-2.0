import 'package:flutter_test/flutter_test.dart';
import 'package:pilogy_app/services/firebase/firebase_bootstrap.dart';
import 'package:pilogy_app/services/notifications/push_notifications.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('messaging skips platforms and Firebase identities that are not ready',
      () async {
    // No Firebase/platform channel is installed: any accidental call fails.
    for (final status in FirebaseStartupStatus.values) {
      if (status == FirebaseStartupStatus.ready) continue;
      await expectLater(PushNotifications.initialize(status), completes);
    }
  });
}
