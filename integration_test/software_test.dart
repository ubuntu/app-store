import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:software/main.dart' as app;
import 'package:ubuntu_service/ubuntu_service.dart';

import '../test/test_utils.dart';
import 'integration_test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(resetAllServices);

  group('Package Installer App', () {
    testWidgets('Install local deb', (tester) async {
      final localDeb =
          File('integration_test/assets/hello_2.10-2ubuntu4_amd64.deb');
      expect(localDeb.existsSync(), isTrue);

      final helloExe = File('/usr/bin/hello');
      expect(helloExe.existsSync(), isFalse);

      initCustomExpect();

      await app.main([localDeb.absolute.path]);
      await tester.pump();

      final installButton =
          find.widgetWithText(ElevatedButton, tester.lang.install);
      await tester.pumpUntil(installButton);
      expectSync(installButton, findsOneWidget);
      await tester.tap(installButton);

      final uninstallButton =
          find.widgetWithText(OutlinedButton, tester.lang.remove);
      await tester.pumpUntil(
        uninstallButton,
      );
      expectSync(uninstallButton, findsOneWidget);
      expectSync(installButton, findsNothing);

      expectSync(helloExe.existsSync(), isTrue);

      await tester.pumpUntil(
        uninstallButton,
      );
      await tester.tap(uninstallButton);

      await tester.pumpUntil(installButton);
      expect(installButton, findsOneWidget);
      expect(uninstallButton, findsNothing);

      expect(helloExe.existsSync(), isFalse);
    });
  });
}
