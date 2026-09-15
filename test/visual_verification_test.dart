import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health_companion/main.dart';
import 'package:health_companion/core/state/app_state.dart';
import 'package:health_companion/features/lab_reports/widgets/upload_report_modal.dart';
import 'package:health_companion/features/data_portability/screens/data_portability_screen.dart';
import 'package:health_companion/features/journal/screens/journal_feeling_screen.dart';
import 'package:health_companion/features/journal/widgets/journal_entry_sheet.dart';
import 'package:health_companion/features/womens_health/screens/womens_health_screen.dart';
import 'package:health_companion/features/womens_health/screens/pregnancy_dashboard_screen.dart';
import 'package:health_companion/features/fitness/widgets/todays_movement_panel.dart';
import 'package:health_companion/features/onboarding/screens/onboarding_baseline_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Capture visual verification of Part 1 bug fixes', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState();
    await appState.register(
      fullName: 'Jordan Lee',
      email: 'jordan.lee@gmail.com',
      password: 'pass1234',
    );

    final boundaryKey = GlobalKey();

    Future<void> saveScreenshot(String fileName) async {
      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final buffer = byteData!.buffer.asUint8List();
        final target = File('/Users/prakharjain/.gemini/antigravity-ide/brain/566ad6a4-2a3f-4c55-a7a0-c61230ae1b40/$fileName');
        target.writeAsBytesSync(buffer);
      });
    }

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF030712),
          ),
          home: HealthCompanionShell(appState: appState),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // 1. Initial Home Tab
    await saveScreenshot('tab_0_home.png');

    // 2. Switch Home -> Journal
    appState.setTabIndex(1);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await saveScreenshot('tab_switch_home_to_journal_mid.png');

    await tester.pump(const Duration(milliseconds: 250));
    await saveScreenshot('tab_1_journal.png');

    // 3. Switch Journal -> Fitness (tab 3)
    appState.setTabIndex(3);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await saveScreenshot('tab_switch_journal_to_fitness_mid.png');

    await tester.pump(const Duration(milliseconds: 250));
    await saveScreenshot('tab_2_fitness.png');

    // 4. Switch Fitness -> Biology / Labs (tab 4)
    appState.setTabIndex(4);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await saveScreenshot('tab_switch_fitness_to_labs_mid.png');

    await tester.pump(const Duration(milliseconds: 250));
    await saveScreenshot('tab_3_labs.png');
  });

  testWidgets('Capture visual verification of Lab Upload Camera & Export UI', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState();
    await appState.register(
      fullName: 'Jordan Lee',
      email: 'jordan.lee@gmail.com',
      password: 'pass1234',
    );

    final modalKey = GlobalKey();

    Future<void> saveScreenshot(GlobalKey key, String fileName) async {
      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final buffer = byteData!.buffer.asUint8List();
        final target = File('/Users/prakharjain/.gemini/antigravity-ide/brain/566ad6a4-2a3f-4c55-a7a0-c61230ae1b40/$fileName');
        target.writeAsBytesSync(buffer);
      });
    }

    // Capture Lab Upload Modal with Camera, Gallery, and Files options
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF030712),
        ),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: modalKey,
              child: SizedBox(
                width: 440,
                height: 560,
                child: UploadReportModal(appState: appState),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await saveScreenshot(modalKey, 'lab_upload_camera_modal.png');

    // Capture Data Portability Screen (Formatted Cards, no raw JSON)
    final exportKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF030712),
        ),
        home: RepaintBoundary(
          key: exportKey,
          child: DataPortabilityScreen(appState: appState),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await saveScreenshot(exportKey, 'data_export_clinical_summary.png');
  });

  testWidgets('Capture visual verification of New Feature Screens (Parts 2-7)', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppState();
    await appState.register(
      fullName: 'Jordan Lee',
      email: 'jordan.lee@gmail.com',
      password: 'pass1234',
    );

    Future<void> captureWidget(Widget widget, String fileName, {Size size = const Size(800, 1400)}) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF030712),
          ),
          home: Scaffold(
            backgroundColor: const Color(0xFF030712),
            body: Center(
              child: RepaintBoundary(
                key: key,
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: widget,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      await tester.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 1.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final buffer = byteData!.buffer.asUint8List();
        final target = File('/Users/prakharjain/.gemini/antigravity-ide/brain/566ad6a4-2a3f-4c55-a7a0-c61230ae1b40/$fileName');
        target.writeAsBytesSync(buffer);
      });
    }

    // 1. Journal Screen with Reflections Timeline & Correlations
    await captureWidget(
      JournalFeelingScreen(appState: appState),
      'screen_journal_timeline.png',
    );

    // 2. Journal Entry Modal (Prompt chips, Mood dial, Voice recording wave, Photo)
    await captureWidget(
      JournalEntrySheet(appState: appState),
      'screen_journal_entry_modal.png',
      size: const Size(500, 850),
    );

    // 3. Women's Health - Menstrual Cycle Tracking & Flow History
    await captureWidget(
      WomensHealthScreen(appState: appState),
      'screen_womens_health_cycle.png',
    );

    // 4. Women's Health - Pregnancy Mode Dashboard
    await captureWidget(
      PregnancyDashboardScreen(appState: appState),
      'screen_pregnancy_dashboard.png',
    );

    // 5. Today's Movement & Universal Recovery Engine
    await captureWidget(
      SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: TodaysMovementPanel(appState: appState),
        ),
      ),
      'screen_todays_movement.png',
      size: const Size(800, 1600),
    );

    // 6. Onboarding Baseline Screen
    await captureWidget(
      OnboardingBaselineScreen(appState: appState),
      'screen_onboarding_baseline.png',
    );
  });
}
