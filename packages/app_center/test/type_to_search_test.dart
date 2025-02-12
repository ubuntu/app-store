import 'package:app_center/store/store_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gtk/gtk.dart';
import 'package:ubuntu_service/ubuntu_service.dart';

import 'test_utils.dart';

void main() {
  group('GNOME-style type-to-search feature in StoreApp', () {
    testWidgets('Search box gains focus when typing', (tester) async {
      registerMockService<GtkApplicationNotifier>(
        createMockGtkApplicationNotifier(),
      );
      registerMockSnapdService();
      await tester.pumpApp(
        (_) => const ProviderScope(
          child: StoreApp(),
        ),
      );

      final searchBoxFinder = find.byType(TextField);
      expect(
        searchBoxFinder,
        findsOneWidget,
        reason: 'Expected to find a search box in the app.',
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);

      await tester.pumpAndSettle();
      final searchBoxWidget = tester.widget<TextField>(searchBoxFinder);
      final focusNode = searchBoxWidget.focusNode;
      final result = focusNode != null && focusNode.hasFocus;

      expect(
        result,
        isTrue,
        reason: 'Expected the search box to gain focus when typing.',
      );
    });
  });
}
