import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tcc_3/app.dart';
import 'package:tcc_3/firebase_options.dart';
import 'package:tcc_3/locator.dart';

class Utils {
  const Utils();

  /// Setup dependencies and returns [App] widget.
  /// Usually called in [setUp] method within main test.
  Future<Widget> createAppUnderTest() async {
    await locator.reset();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    setupDependencies();

    await locator.allReady();

    return const App();
  }

  Future<void> dragUntilVisible(
    WidgetTester tester, {
    required Finder target,
    required Finder scrollable,
  }) async {
    await tester.dragUntilVisible(
      target,
      scrollable,
      const Offset(0, -50),
    );
    await tester.pumpAndSettle();
  }
}