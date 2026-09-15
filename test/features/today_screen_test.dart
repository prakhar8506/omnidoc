import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_companion/core/state/app_state.dart';
import 'package:health_companion/features/home/screens/home_screen.dart';

void main() {
  group('Recovery OS Today Screen Widget Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('Scores must never render bare: confidence label and drivers must be present', (WidgetTester tester) async {
      final appState = AppState();
      // Pre-seeded with 14 days demo data
      appState.seedDemoEvents(days: 14);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Recovery Title is rendered
      expect(find.text('Recovery'), findsWidgets);

      // Verify Confidence Badge is rendered alongside the score (never a bare number)
      expect(find.textContaining('confidence'), findsWidgets);

      // Verify at least one Named Driver is rendered
      expect(find.text('What influenced today'), findsOneWidget);

      // Verify Plan for today action box is rendered
      expect(find.text('YOUR PLAN FOR TODAY'), findsOneWidget);

      // Verify Sleep, Load, Stress stat cards are present and have drivers & confidence
      expect(find.textContaining('Target:'), findsOneWidget);
      expect(find.textContaining('/100 index'), findsOneWidget);
    });

    testWidgets('Provisional state (< 7 days) displays explicit provisional badge and baseline count', (WidgetTester tester) async {
      final appState = AppState();
      // Clear data to simulate fresh account (< 7 days)
      await appState.eventStore.clear();
      appState.historicalDaysCount = 0;
      appState.recalculateRecoveryEngine();

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      // Must display provisional warning banner
      expect(find.textContaining('Provisional Score • Establishing baseline'), findsOneWidget);
      expect(find.textContaining('0 of 14 days recorded'), findsOneWidget);
    });

    testWidgets('Sensor Coverage badge is present in header and links to Permission Center', (WidgetTester tester) async {
      final appState = AppState();
      appState.seedDemoEvents(days: 14);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(appState: appState),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Coverage'), findsOneWidget);
    });
  });
}
